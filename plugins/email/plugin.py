"""Plugin de análise de e-mails.

Permite: validação de formato, domínio, MX, registros DNS relacionados,
reputação quando disponível e fontes públicas. Nunca tenta obter
senhas ou dados privados.
"""

from __future__ import annotations

import re
from typing import Any

from core.constants import Status
from core.plugin import NexusPlugin, PluginResult

from plugins import dns_utils
from plugins.http import make_client, safe_get

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$", re.IGNORECASE)

DISPOSITION_HINTS = [
    ("gmail.com", "provedor de e-mail público (Gmail)"),
    ("outlook.com", "provedor de e-mail público (Outlook)"),
    ("hotmail.com", "provedor de e-mail público (Hotmail/Outlook)"),
    ("yahoo.com", "provedor de e-mail público (Yahoo)"),
    ("icloud.com", "provedor de e-mail público (iCloud)"),
    ("proton.me", "provedor de e-mail privado (ProtonMail)"),
    ("protonmail.com", "provedor de e-mail privado (ProtonMail)"),
]


class EmailPlugin(NexusPlugin):
    """Validação e inteligência pública sobre endereços de e-mail."""

    name = "Email Analyzer"
    version = "1.0"
    description = "Validação de formato, domínio, MX, DNS e reputação (emailrep.io se configurado)."
    author = "NEXUS Project"
    target_types = ["email"]
    requires_api_key = "EMAILREP_API_KEY"
    rate_limit = 1.0
    timeout = 20.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        results: list[PluginResult] = []

        # 1) Formato
        if not EMAIL_RE.match(target):
            results.append(
                PluginResult(
                    result_type="validation",
                    data={"valid": False, "reason": "formato inválido"},
                    source="regex (offline)",
                    confidence="CONFIRMED",
                    status=Status.ERROR.value,
                )
            )
            return results

        local_part, domain = target.rsplit("@", 1)
        results.append(
            PluginResult(
                result_type="validation",
                data={
                    "valid_format": True,
                    "local_part": local_part,
                    "domain": domain,
                    "length": len(target),
                    "disposition": _disposition_hint(domain),
                },
                source="regex (offline)",
                confidence="CONFIRMED",
            )
        )

        # 2) DNS do domínio (MX, A, NS, TXT, SPF, DMARC)
        dns_data = await _dns_for_domain(domain)
        if dns_data:
            results.append(
                PluginResult(
                    result_type="dns",
                    data=dns_data,
                    source="DNS (dnspython)",
                    confidence="HIGH",
                )
            )
        else:
            results.append(
                PluginResult(
                    result_type="dns",
                    data={"domain": domain, "error": "sem registros MX/A — domínio provavelmente não aceita e-mail"},
                    source="DNS (dnspython)",
                    confidence="MEDIUM",
                )
            )

        # 3) Reputação via emailrep.io (somente com chave; nunca afirmar sem fonte)
        store = (context or {}).get("secret_store")
        if store and store.has("EMAILREP_API_KEY"):
            api_key = store.get("EMAILREP_API_KEY")
            async with make_client(timeout=10.0) as client:
                status_code, payload, error = await safe_get(
                    client,
                    f"https://emailrep.io/{target}",
                    headers={"Key": api_key, "User-Agent": "nexus/1.0"},
                )
            if status_code == 200 and payload:
                results.append(
                    PluginResult(
                        result_type="reputation",
                        data={
                            "reputation": payload.get("reputation"),
                            "suspicious": payload.get("suspicious"),
                            "references": payload.get("references"),
                            "details": payload.get("details"),
                            "source_field": payload.get("source"),
                        },
                        source="emailrep.io",
                        confidence="MEDIUM",
                    )
                )
            else:
                results.append(
                    PluginResult(
                        result_type="reputation",
                        data={"error": error or f"HTTP {status_code}"},
                        source="emailrep.io",
                        confidence="LOW",
                        status=Status.ERROR.value,
                    )
                )
        else:
            results.append(
                PluginResult(
                    result_type="reputation",
                    data={"message": "NOT CONFIGURED — defina EMAILREP_API_KEY para reputação"},
                    source="emailrep.io",
                    confidence="LOW",
                    status=Status.NOT_CONFIGURED.value,
                )
            )

        return results


async def _dns_for_domain(domain: str) -> dict[str, Any]:
    mx = dns_utils.resolve_mx(domain)
    txt = dns_utils.resolve_txt(domain)
    return {
        "domain": domain,
        "MX": mx or [],
        "has_mx": bool(mx),
        "A": dns_utils.resolve_a(domain) or [],
        "NS": dns_utils.resolve_ns(domain) or [],
        "TXT": (txt or [])[:10],
        "SPF": dns_utils.spf_record(txt),
        "DMARC": dns_utils.dmarc_record(domain) or [],
    }


def _disposition_hint(domain: str) -> str:
    for hint_domain, hint in DISPOSITION_HINTS:
        if domain == hint_domain or domain.endswith(f".{hint_domain}"):
            return hint
    return "domínio próprio/corporativo"
