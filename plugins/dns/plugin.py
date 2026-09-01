"""Plugin DNS dedicado: consulta detalhada de registros de um domínio."""

from __future__ import annotations

from typing import Any

from core.plugin import NexusPlugin, PluginResult

from plugins import dns_utils

RECORD_TYPES = ["A", "AAAA", "MX", "NS", "TXT", "CNAME", "SOA", "CAA"]


class DnsPlugin(NexusPlugin):
    """Consulta detalhada de registros DNS de um domínio."""

    name = "DNS Records"
    version = "1.0"
    description = "Consulta A, AAAA, MX, NS, TXT, CNAME, SOA e CAA via resolvedor do sistema."
    author = "NEXUS Project"
    target_types = ["domain"]
    requires_api_key = None
    rate_limit = 5.0
    timeout = 20.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        results: list[PluginResult] = []
        for record_type in RECORD_TYPES:
            values = _query(record_type, target)
            if values:
                results.append(
                    PluginResult(
                        result_type="dns",
                        data={
                            "record_type": record_type,
                            "name": target,
                            "value": values,
                            "count": len(values),
                        },
                        source="DNS (dnspython)",
                        confidence="HIGH",
                    )
                )
        if not results:
            results.append(
                PluginResult(
                    result_type="dns",
                    data={"name": target, "message": "nenhum registro encontrado (NXDOMAIN ou bloqueado)"},
                    source="DNS (dnspython)",
                    confidence="LOW",
                )
            )
        return results


def _query(record_type: str, domain: str) -> list[str] | None:
    if record_type == "A":
        return dns_utils.resolve_a(domain)
    if record_type == "AAAA":
        return dns_utils.resolve_aaaa(domain)
    if record_type == "MX":
        return dns_utils.resolve_mx(domain)
    if record_type == "NS":
        return dns_utils.resolve_ns(domain)
    if record_type == "TXT":
        return dns_utils.resolve_txt(domain)
    if record_type == "CNAME":
        return dns_utils.resolve_cname(domain)
    if record_type == "SOA":
        return dns_utils.resolve_soa(domain)
    if record_type == "CAA":
        return dns_utils.resolve_caa(domain)
    return None
