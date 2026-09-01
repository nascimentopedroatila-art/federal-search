"""Consultas DNS via dnspython (executadas em executor para não bloquear o loop).

Todas as funções retornam ``dict``/``list`` serializáveis ou ``None``
em caso de erro — nunca levantam exceções para fora.
"""

from __future__ import annotations

from typing import Any

import dns.resolver


def _resolve(record_type: str, name: str, lifetime: float = 5.0) -> list[str] | None:
    try:
        answers = dns.resolver.resolve(name, record_type, lifetime=lifetime)
        return [str(r) for r in answers]
    except Exception:  # noqa: BLE001 - NXDOMAIN, timeout, etc.
        return None


def resolve_a(domain: str) -> list[str] | None:
    return _resolve("A", domain)


def resolve_aaaa(domain: str) -> list[str] | None:
    return _resolve("AAAA", domain)


def resolve_mx(domain: str) -> list[str] | None:
    return _resolve("MX", domain)


def resolve_ns(domain: str) -> list[str] | None:
    return _resolve("NS", domain)


def resolve_txt(domain: str) -> list[str] | None:
    return _resolve("TXT", domain)


def resolve_caa(domain: str) -> list[str] | None:
    return _resolve("CAA", domain)


def resolve_cname(domain: str) -> list[str] | None:
    return _resolve("CNAME", domain)


def resolve_soa(domain: str) -> list[str] | None:
    return _resolve("SOA", domain)


def resolve_ptr(ip: str) -> list[str] | None:
    try:
        import dns.reversename

        name = dns.reversename.from_address(ip)
        answers = dns.resolver.resolve(name, "PTR", lifetime=5.0)
        return [str(r) for r in answers]
    except Exception:  # noqa: BLE001
        return None


def spf_record(txt_records: list[str] | None) -> str | None:
    """Extrai o registro SPF de uma lista de TXT (RFC 7208)."""
    if not txt_records:
        return None
    for record in txt_records:
        if record.startswith("v=spf1"):
            return record
    return None


def dmarc_record(domain: str) -> list[str] | None:
    """Consulta o registro TXT de _dmarc.<domain> (RFC 7489)."""
    try:
        answers = dns.resolver.resolve(f"_dmarc.{domain}", "TXT", lifetime=5.0)
        return [str(r) for r in answers]
    except Exception:  # noqa: BLE001
        return None


def summary(domain: str) -> dict[str, Any]:
    """Resumo DNS de um domínio (usado por múltiplos plugins)."""
    return {
        "A": resolve_a(domain),
        "AAAA": resolve_aaaa(domain),
        "MX": resolve_mx(domain),
        "NS": resolve_ns(domain),
        "TXT": resolve_txt(domain),
        "CAA": resolve_caa(domain),
        "CNAME": resolve_cname(domain),
        "SPF": spf_record(resolve_txt(domain)),
        "DMARC": dmarc_record(domain),
        "SOA": resolve_soa(domain),
    }
