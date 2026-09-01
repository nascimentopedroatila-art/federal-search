"""Normalizador de alvos.

Converte o input do usuário em uma forma canônica antes de qualquer
processamento: números de telefone, e-mails, domínios, IPs, URLs e
hashes recebem tratamento específico e determinístico.
"""

from __future__ import annotations

import ipaddress
import re
from urllib.parse import urlparse

from core.constants import TargetType
from core.errors import TargetError

PHONE_RE = re.compile(r"^\+?[0-9\s().-]{7,20}$")
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$", re.IGNORECASE)
DOMAIN_RE = re.compile(
    r"^(?=.{1,253}$)(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+"
    r"[a-zA-Z]{2,63}$"
)
URL_RE = re.compile(r"^https?://", re.IGNORECASE)
HASH_RE = re.compile(
    r"^(?:[0-9a-fA-F]{32}|[0-9a-fA-F]{40}|[0-9a-fA-F]{64}|[0-9a-fA-F]{128})$"
)
USERNAME_RE = re.compile(r"^[a-zA-Z0-9_.-]{3,32}$")
HAS_AT = re.compile(r"@")


def _normalize_phone(raw: str) -> str:
    digits = re.sub(r"[^0-9+]", "", raw)
    if digits.startswith("+"):
        return "+" + digits[1:]
    if len(digits) == 10 or len(digits) == 11:
        return "+55" + digits  # padrão brasileiro quando não há código do país
    return "+" + digits


def _normalize_domain(raw: str) -> str:
    return raw.rstrip(".").lower()


def _normalize_ip(raw: str) -> str:
    try:
        ip = ipaddress.ip_address(raw.strip())
    except ValueError as exc:
        raise TargetError(f"Endereço IP inválido: {raw}") from exc
    return str(ip)


def _normalize_hash(raw: str) -> str:
    return raw.strip().lower()


def normalize(target: str, target_type: TargetType | str | None = None) -> str:
    """Normaliza um alvo de acordo com o tipo (detectado ou informado)."""
    if not target or not target.strip():
        raise TargetError("Alvo vazio.")

    raw = target.strip()
    ttype = TargetType(target_type) if target_type else None

    if ttype == TargetType.PHONE:
        return _normalize_phone(raw)
    if ttype == TargetType.EMAIL:
        email = raw.lower()
        if not EMAIL_RE.match(email):
            raise TargetError(f"E-mail inválido: {raw}")
        return email
    if ttype == TargetType.DOMAIN:
        domain = _normalize_domain(raw)
        if not DOMAIN_RE.match(domain):
            raise TargetError(f"Domínio inválido: {raw}")
        return domain
    if ttype == TargetType.IP:
        return _normalize_ip(raw)
    if ttype == TargetType.URL:
        parsed = urlparse(raw)
        if parsed.scheme not in ("http", "https") or not parsed.netloc:
            raise TargetError(f"URL inválida: {raw}")
        return raw
    if ttype == TargetType.HASH:
        value = _normalize_hash(raw)
        if not HASH_RE.match(value):
            raise TargetError(f"Hash inválido: {raw}")
        return value
    if ttype == TargetType.USERNAME:
        username = raw.lstrip("@")
        if not USERNAME_RE.match(username):
            raise TargetError(f"Username inválido: {raw}")
        return username

    raise TargetError(f"Tipo de alvo não suportado: {target_type}")
