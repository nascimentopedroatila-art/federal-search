"""Plugin de análise de endereços IP.

Suporta: geolocalização aproximada (ipwho.is), ASN/organização,
DNS reverso, registros RDAP e reputação (AbuseIPDB se configurado).

**Nunca** executa ataques contra o IP — apenas consultas passivas a
fontes públicas.
"""

from __future__ import annotations

from typing import Any

from core.constants import Status
from core.plugin import NexusPlugin, PluginResult

from plugins import dns_utils
from plugins.http import make_client, safe_get


class IpPlugin(NexusPlugin):
    """Inteligência sobre IPs a partir de fontes públicas passivas."""

    name = "IP Intelligence"
    version = "1.0"
    description = "Geolocalização (ipwho.is), ASN, DNS reverso, RDAP e reputação (AbuseIPDB)."
    author = "NEXUS Project"
    target_types = ["ip"]
    requires_api_key = "ABUSEIPDB_API_KEY"
    rate_limit = 2.0
    timeout = 25.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        results: list[PluginResult] = []
        ip = target

        # --- DNS reverso ---------------------------------------------
        ptr = dns_utils.resolve_ptr(ip)
        results.append(
            PluginResult(
                result_type="dns",
                data={"ip": ip, "PTR": ptr or []},
                source="DNS (dnspython)",
                confidence="HIGH",
            )
        )

        # --- Geolocalização + ASN (ipwho.is) --------------------------
        async with make_client(timeout=12.0) as client:
            status_code, payload, error = await safe_get(client, f"https://ipwho.is/{ip}")
        if status_code == 200 and isinstance(payload, dict) and payload.get("success"):
            connection = payload.get("connection") or {}
            security = payload.get("security") or {}
            results.append(
                PluginResult(
                    result_type="geo",
                    data={
                        "ip": ip,
                        "country": payload.get("country"),
                        "country_code": payload.get("country_code"),
                        "region": payload.get("region"),
                        "city": payload.get("city"),
                        "latitude": payload.get("latitude"),
                        "longitude": payload.get("longitude"),
                        "timezone": (payload.get("timezone") or {}).get("id"),
                        "isp": connection.get("isp"),
                        "domain": connection.get("domain"),
                        "proxy": security.get("proxy"),
                        "vpn": security.get("vpn"),
                        "tor": security.get("tor"),
                    },
                    source="ipwho.is",
                    confidence="HIGH",
                )
            )
            if connection.get("asn"):
                results.append(
                    PluginResult(
                        result_type="asn",
                        data={
                            "ip": ip,
                            "asn": connection.get("asn"),
                            "org": connection.get("org"),
                            "isp": connection.get("isp"),
                        },
                        source="ipwho.is",
                        confidence="HIGH",
                    )
                )
        else:
            results.append(
                PluginResult(
                    result_type="geo",
                    data={"ip": ip, "error": error or f"HTTP {status_code}"},
                    source="ipwho.is",
                    confidence="LOW",
                    status=Status.ERROR.value,
                )
            )

        # --- RDAP (WHOIS de rede) --------------------------------------
        rdap = await _rdap_ip(ip)
        if rdap:
            results.append(rdap)

        # --- Reputação (AbuseIPDB, somente com chave) -------------------
        store = (context or {}).get("secret_store")
        if store and store.has("ABUSEIPDB_API_KEY"):
            api_key = store.get("ABUSEIPDB_API_KEY")
            async with make_client(timeout=12.0) as client:
                status_code, payload, error = await safe_get(
                    client,
                    "https://api.abuseipdb.com/api/v2/check",
                    params={"ipAddress": ip, "maxAgeInDays": "90"},
                    headers={"Key": api_key, "Accept": "application/json"},
                )
            if status_code == 200 and isinstance(payload, dict):
                data = payload.get("data") or {}
                results.append(
                    PluginResult(
                        result_type="reputation",
                        data={
                            "ip": ip,
                            "abuse_confidence_score": data.get("abuseConfidenceScore"),
                            "total_reports": data.get("totalReports"),
                            "num_distinct_users": data.get("numDistinctUsers"),
                            "last_reported_at": data.get("lastReportedAt"),
                            "is_whitelisted": data.get("isWhitelisted"),
                            "is_tor": data.get("isTor"),
                            "usage_type": data.get("usageType"),
                            "country_code": data.get("countryCode"),
                        },
                        source="AbuseIPDB",
                        confidence="HIGH",
                    )
                )
            else:
                results.append(
                    PluginResult(
                        result_type="reputation",
                        data={"ip": ip, "error": error or f"HTTP {status_code}"},
                        source="AbuseIPDB",
                        confidence="LOW",
                        status=Status.ERROR.value,
                    )
                )
        else:
            results.append(
                PluginResult(
                    result_type="reputation",
                    data={
                        "ip": ip,
                        "message": "NOT CONFIGURED — defina ABUSEIPDB_API_KEY para reputação de IP",
                    },
                    source="AbuseIPDB",
                    confidence="LOW",
                    status=Status.NOT_CONFIGURED.value,
                )
            )
        return results


async def _rdap_ip(ip: str) -> PluginResult | None:
    from plugins.http import DEFAULT_HEADERS, make_client, safe_get

    headers = dict(DEFAULT_HEADERS)
    headers["Accept"] = "application/rdap+json"
    try:
        async with make_client(timeout=12.0) as client:
            status_code, payload, error = await safe_get(
                client, f"https://rdap.org/ip/{ip}", headers=headers
            )
        if status_code == 200 and isinstance(payload, dict):
            return PluginResult(
                result_type="asn",
                data={
                    "ip": ip,
                    "handle": payload.get("handle"),
                    "start_address": (payload.get("startAddress") or ""),
                    "end_address": (payload.get("endAddress") or ""),
                    "name": payload.get("name"),
                    "country": payload.get("country"),
                    "org": _rdap_org(payload),
                    "events": [
                        {"action": e.get("eventAction"), "date": e.get("eventDate")}
                        for e in (payload.get("events") or [])
                    ],
                },
                source="RDAP (rdap.org)",
                confidence="HIGH",
            )
        return None
    except Exception:  # noqa: BLE001
        return None


def _rdap_org(payload: dict[str, Any]) -> str | None:
    for entity in payload.get("entities") or []:
        if "registrant" in (entity.get("roles") or []):
            vcard = entity.get("vcardArray") or []
            if vcard and len(vcard) > 1:
                for field in vcard[1]:
                    if field and field[0] == "fn":
                        return str(field[3])
    return None


class VirusTotalIpPlugin(NexusPlugin):
    """Reputação de IP via VirusTotal v3 (API oficial, requer chave)."""

    name = "VirusTotal IP"
    version = "2.0"
    description = "Detecções e dados públicos de um IP via VirusTotal v3."
    author = "NEXUS Project"
    target_types = ["ip"]
    requires_api_key = "VIRUSTOTAL_API_KEY"
    rate_limit = 4.0
    timeout = 15.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        store = (context or {}).get("secret_store")
        api_key = store.get("VIRUSTOTAL_API_KEY") if store else None
        if not api_key:
            return [
                PluginResult(
                    result_type="reputation",
                    data={
                        "ip": target,
                        "message": "NOT CONFIGURED — defina VIRUSTOTAL_API_KEY",
                    },
                    source="VirusTotal",
                    confidence="LOW",
                    status=Status.NOT_CONFIGURED.value,
                )
            ]

        headers = {"x-apikey": api_key}
        async with make_client(timeout=15.0) as client:
            status_code, payload, error = await safe_get(
                client, f"https://www.virustotal.com/api/v3/ip_addresses/{target}", headers=headers
            )

        if status_code != 200 or not isinstance(payload, dict):
            return [
                PluginResult(
                    result_type="reputation",
                    data={"ip": target, "error": error or f"HTTP {status_code}"},
                    source="VirusTotal",
                    confidence="LOW",
                    status=Status.ERROR.value,
                )
            ]

        attributes = (payload.get("data") or {}).get("attributes") or {}
        stats = attributes.get("last_analysis_stats") or {}
        return [
            PluginResult(
                result_type="reputation",
                data={
                    "ip": target,
                    "detection_ratio": f"{stats.get('malicious', 0)}/{sum(stats.values()) if stats else 0}",
                    "stats": stats,
                    "country": attributes.get("country"),
                    "asn": attributes.get("asn"),
                    "as_owner": attributes.get("as_owner"),
                    "regional_internet_registry": attributes.get("regional_internet_registry"),
                    "network": attributes.get("network"),
                },
                source="VirusTotal",
                confidence="HIGH",
            )
        ]


class IpQualityScoreIpPlugin(NexusPlugin):
    """Análise de risco/fraude de um IP via IPQualityScore."""

    name = "IPQualityScore IP"
    version = "2.0"
    description = "Fraud score, proxy/VPN/TOR, ISP e geolocalização de IP via IPQualityScore."
    author = "NEXUS Project"
    target_types = ["ip"]
    requires_api_key = "IPQUALITYSCORE_API_KEY"
    rate_limit = 2.0
    timeout = 15.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        store = (context or {}).get("secret_store")
        api_key = store.get("IPQUALITYSCORE_API_KEY") if store else None
        if not api_key:
            return [
                PluginResult(
                    result_type="reputation",
                    data={
                        "ip": target,
                        "message": "NOT CONFIGURED — defina IPQUALITYSCORE_API_KEY",
                    },
                    source="IPQualityScore",
                    confidence="LOW",
                    status=Status.NOT_CONFIGURED.value,
                )
            ]

        async with make_client(timeout=12.0) as client:
            status_code, payload, error = await safe_get(
                client,
                "https://ipqualityscore.com/api/json/ip/",
                params={"key": api_key, "ip": target},
            )

        if status_code != 200 or not isinstance(payload, dict) or not payload.get("success"):
            return [
                PluginResult(
                    result_type="reputation",
                    data={"ip": target, "error": error or f"HTTP {status_code}"},
                    source="IPQualityScore",
                    confidence="LOW",
                    status=Status.ERROR.value,
                )
            ]

        return [
            PluginResult(
                result_type="reputation",
                data={
                    "ip": target,
                    "fraud_score": payload.get("fraud_score"),
                    "proxy": payload.get("proxy"),
                    "vpn": payload.get("vpn"),
                    "tor": payload.get("tor"),
                    "active_vpn": payload.get("active_vpn"),
                    "active_tor": payload.get("active_tor"),
                    "recent_abuse": payload.get("recent_abuse"),
                    "bot_status": payload.get("bot_status"),
                    "isp": payload.get("ISP"),
                    "organization": payload.get("organization"),
                    "asn": payload.get("ASN"),
                    "country": payload.get("country_code"),
                    "city": payload.get("city"),
                    "timezone": payload.get("timezone"),
                },
                source="IPQualityScore",
                confidence="HIGH",
            )
        ]
