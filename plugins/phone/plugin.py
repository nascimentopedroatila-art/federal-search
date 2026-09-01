"""Plugin de análise de números de telefone.

Usa apenas fontes públicas e dados offline (biblioteca ``phonenumbers``
— dados oficiais de numeração por país). Não afirma nomes de
proprietários: nenhuma fonte pública legítima fornece isso sem contrato.
"""

from __future__ import annotations

from typing import Any

import phonenumbers
from core.constants import Status
from core.plugin import NexusPlugin, PluginResult
from phonenumbers import carrier, geocoder, timezone

UNSUPPORTED = "NOT AVAILABLE"

# Mapeamento estável dos tipos de linha do phonenumbers (enum não construtível).
_LINE_TYPES: dict[int, str] = {
    getattr(phonenumbers.PhoneNumberType, attr): attr
    for attr in dir(phonenumbers.PhoneNumberType)
    if attr.isupper()
}


def _validate_phone(raw: str) -> tuple[str | None, str | None]:
    """Retorna (número_normalizado, erro)."""
    try:
        number = phonenumbers.parse(raw, None)
    except phonenumbers.NumberParseException as exc:
        return None, f"número inválido: {exc}"
    if not phonenumbers.is_possible_number(number):
        return None, "número impossível (contagem de dígitos inconsistente)"
    return phonenumbers.format_number(number, phonenumbers.PhoneNumberFormat.E164), None


class PhonePlugin(NexusPlugin):
    """Análise offline e pública de números de telefone."""

    name = "Phone Validator"
    version = "1.0"
    description = "Validação, país, região, operadora e tipo de linha de números telefônicos (fontes públicas/offline)."
    author = "NEXUS Project"
    target_types = ["phone"]
    requires_api_key = None
    rate_limit = 5.0
    timeout = 10.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        results: list[PluginResult] = []
        number, error = _validate_phone(target)
        if error:
            results.append(
                PluginResult(
                    result_type="validation",
                    data={"valid": False, "error": error},
                    source="phonenumbers (offline)",
                    confidence="CONFIRMED",
                    status=Status.ERROR.value,
                )
            )
            return results

        parsed = phonenumbers.parse(number, None)
        country_code = parsed.country_code
        country_name = phonenumbers.region_code_for_number(parsed) or ""
        national = phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.NATIONAL)
        international = phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.INTERNATIONAL)

        data: dict[str, Any] = {
            "normalized": number,
            "national_format": national,
            "international_format": international,
            "valid": True,
            "possible": phonenumbers.is_possible_number(parsed),
            "country_code": f"+{country_code}",
            "country": country_name,
        }

        region = geocoder.description_for_number(parsed, "pt")
        data["region"] = region if region else UNSUPPORTED

        line_type = phonenumbers.number_type(parsed)
        data["line_type"] = _LINE_TYPES.get(int(line_type), UNSUPPORTED) if line_type is not None else UNSUPPORTED

        op = carrier.name_for_number(parsed, "pt")
        data["carrier"] = op if op else UNSUPPORTED

        tz_list = timezone.time_zones_for_number(parsed)
        data["timezones"] = list(tz_list) if tz_list else []

        # Reputação/fraude: não há fonte pública legítima sem contrato.
        data["reputation"] = UNSUPPORTED
        data["fraud_indicators"] = []
        data["public_references"] = []

        results.append(
            PluginResult(
                result_type="validation",
                data=data,
                source="phonenumbers (dados públicos offline)",
                confidence="CONFIRMED",
            )
        )
        return results
