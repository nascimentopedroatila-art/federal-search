"""Detector automático de tipos de alvo.

Prioridade de detecção: URL -> HASH -> EMAIL -> PHONE -> IP -> DOMAIN
-> USERNAME -> UNKNOWN.

Exemplos:

    +5585999999999      -> PHONE
    user@example.com    -> EMAIL
    example.com         -> DOMAIN
    8.8.8.8             -> IP
    https://example.com -> URL
    example_username    -> USERNAME
    d41d8cd98f00b204e9800998ecf8427e -> HASH
"""

from __future__ import annotations

import ipaddress
import re

from core.constants import TargetType
from core.errors import TargetError
from core.normalizer import (
    DOMAIN_RE,
    EMAIL_RE,
    HASH_RE,
    PHONE_RE,
    URL_RE,
    USERNAME_RE,
    normalize,
)

_KNOWN_TYPES = {t.value for t in TargetType}


def detect_type(target: str) -> TargetType:
    """Detecta o tipo do alvo fornecido."""
    raw = (target or "").strip()
    if not raw:
        raise TargetError("Alvo vazio.")

    if URL_RE.match(raw):
        return TargetType.URL
    if HASH_RE.match(raw):
        return TargetType.HASH
    if EMAIL_RE.match(raw):
        return TargetType.EMAIL
    if PHONE_RE.match(raw) and _looks_like_phone(raw):
        return TargetType.PHONE
    if _is_ip(raw):
        return TargetType.IP
    if DOMAIN_RE.match(raw):
        return TargetType.DOMAIN
    if USERNAME_RE.match(raw):
        return TargetType.USERNAME
    return TargetType.UNKNOWN


def _looks_like_phone(raw: str) -> bool:
    """Refina a detecção de telefone (exige dígitos suficientes)."""
    digits = re.sub(r"[^0-9]", "", raw)
    return 7 <= len(digits) <= 15


def _is_ip(raw: str) -> bool:
    try:
        ipaddress.ip_address(raw)
        return True
    except ValueError:
        return False


def resolve(target: str, target_type: str | None = None) -> tuple[str, TargetType]:
    """Normaliza o alvo e resolve o tipo final.

    Se ``target_type`` for informado, ele é respeitado (regra do
    ``--type`` da CLI). Caso contrário, o tipo é detectado.
    """
    ttype: TargetType
    if target_type:
        value = target_type.strip().lower()
        if value not in _KNOWN_TYPES:
            raise TargetError(
                f"Tipo desconhecido: '{target_type}'. "
                f"Válidos: {', '.join(sorted(_KNOWN_TYPES))}"
            )
        ttype = TargetType(value)
    else:
        # Remove FQDN trailing dot antes da detecção (ex.: "example.com.")
        raw = target.strip().rstrip(".") if target.strip().endswith(".") else target
        ttype = detect_type(raw)
        if ttype == TargetType.UNKNOWN:
            raise TargetError(
                "Não foi possível detectar o tipo do alvo. Use --type "
                "(phone, email, username, domain, ip, url, hash)."
            )
    return normalize(target, ttype), ttype
