"""Plugin de análise de domínios.

Suporta: DNS (A, AAAA, MX, NS, TXT, SPF, DMARC, CAA), WHOIS via RDAP
(quando permitido), certificados públicos (crt.sh), tecnologias
publicamente identificáveis (inferência via DNS) e subdomínios via
fontes autorizadas (crt.sh).
"""

from __future__ import annotations

import re
from typing import Any

from core.constants import Status
from core.plugin import NexusPlugin, PluginResult

from plugins import dns_utils
from plugins.http import make_client, safe_get


class DomainPlugin(NexusPlugin):
    """Inteligência sobre domínios a partir de fontes públicas."""

    name = "Domain Intelligence"
    version = "1.0"
    description = "DNS completo, WHOIS (RDAP), certificados (crt.sh), tecnologias e subdomínios públicos."
    author = "NEXUS Project"
    target_types = ["domain"]
    requires_api_key = None
    rate_limit = 2.0
    timeout = 30.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        results: list[PluginResult] = []

        # --- DNS completo -------------------------------------------
        dns_data = dns_utils.summary(target)
        dns_data["domain"] = target
        results.append(
            PluginResult(
                result_type="dns",
                data=dns_data,
                source="DNS (dnspython)",
                confidence="HIGH",
            )
        )

        # --- WHOIS via RDAP -----------------------------------------
        rdap_result = await _rdap_lookup(target)
        if rdap_result is not None:
            results.append(rdap_result)
        else:
            results.append(
                PluginResult(
                    result_type="whois",
                    data={"domain": target, "error": "registro WHOIS não disponível via RDAP"},
                    source="RDAP (rdap.org)",
                    confidence="LOW",
                    status=Status.NO_RESULTS.value,
                )
            )

        # --- Certificados públicos (crt.sh) --------------------------
        async with make_client(timeout=25.0) as client:
            status_code, payload, error = await safe_get(
                client, "https://crt.sh/", params={"q": f"%25.{target}", "output": "json"}
            )
        if status_code == 200 and isinstance(payload, list):
            certs = _parse_crt(payload, target)
            if certs:
                results.append(
                    PluginResult(
                        result_type="certificate",
                        data={"domain": target, "certificates": certs, "count": len(certs)},
                        source="crt.sh",
                        confidence="HIGH",
                    )
                )
                subdomains = _subdomains_from_certs(certs, target)
                if subdomains:
                    results.append(
                        PluginResult(
                            result_type="subdomain",
                            data={"domain": target, "subdomains": subdomains, "count": len(subdomains)},
                            source="crt.sh",
                            confidence="HIGH",
                        )
                    )
            else:
                results.append(
                    PluginResult(
                        result_type="certificate",
                        data={"domain": target, "certificates": [], "note": "nenhum certificado público encontrado"},
                        source="crt.sh",
                        confidence="LOW",
                        status=Status.NO_RESULTS.value,
                    )
                )
        else:
            results.append(
                PluginResult(
                    result_type="certificate",
                    data={"error": error or f"HTTP {status_code}"},
                    source="crt.sh",
                    confidence="LOW",
                    status=Status.ERROR.value,
                )
            )

        # --- Tecnologias (inferência via DNS, fonte pública) ---------
        tech = _infer_technologies(dns_data)
        if tech:
            results.append(
                PluginResult(
                    result_type="technology",
                    data={"domain": target, "technologies": tech},
                    source="DNS inference",
                    confidence="MEDIUM",
                )
            )

        return results


async def _rdap_lookup(domain: str) -> PluginResult | None:
    """Consulta WHOIS via RDAP (bootstrap automático do rdap.org)."""
    from plugins.http import DEFAULT_HEADERS, make_client, safe_get

    headers = dict(DEFAULT_HEADERS)
    headers["Accept"] = "application/rdap+json"
    try:
        async with make_client(timeout=15.0) as client:
            status_code, payload, error = await safe_get(
                client, f"https://rdap.org/domain/{domain}", headers=headers
            )
        if status_code == 200 and isinstance(payload, dict):
            entities = payload.get("entities") or []
            registrant = _rdap_registrant(entities)
            return PluginResult(
                result_type="whois",
                data={
                    "domain": domain,
                    "handle": payload.get("handle"),
                    "ldhName": payload.get("ldhName"),
                    "registrar": _rdap_registrar(payload),
                    "status": payload.get("status"),
                    "events": _rdap_events(payload.get("events", [])),
                    "nameservers": _rdap_nameservers(payload),
                    "registrant": registrant,
                },
                source="RDAP (rdap.org)",
                confidence="HIGH",
            )
        return None
    except Exception:  # noqa: BLE001
        return None


def _rdap_registrar(payload: dict[str, Any]) -> str | None:
    for entity in payload.get("entities") or []:
        if entity.get("roles") and "registrar" in entity["roles"]:
            vcard = _vcard_name(entity.get("vcardArray") or [])
            return vcard
    return None


def _rdap_registrant(entities: list[dict[str, Any]]) -> dict[str, Any]:
    for entity in entities:
        roles = entity.get("roles") or []
        if "registrant" in roles:
            return {
                "name": _vcard_name(entity.get("vcardArray") or []),
                "country": _vcard_field(entity.get("vcardArray") or [], "ADR"),
            }
    return {}


def _vcard_name(vcard_array: list[Any]) -> str | None:
    if not vcard_array or len(vcard_array) < 2:
        return None
    for field in vcard_array[1]:
        if field and field[0] == "fn":
            return str(field[3])
    return None


def _vcard_field(vcard_array: list[Any], field_name: str) -> str | None:
    if not vcard_array or len(vcard_array) < 2:
        return None
    for field in vcard_array[1]:
        if field and field[0] == field_name and isinstance(field[3], dict):
            return str(field[3].get("country", ""))
    return None


def _rdap_events(events: list[dict[str, Any]]) -> list[dict[str, str]]:
    out = []
    for event in events:
        out.append({"action": event.get("eventAction"), "date": event.get("eventDate")})
    return out


def _rdap_nameservers(payload: dict[str, Any]) -> list[str]:
    ns = []
    for entry in payload.get("nameservers") or []:
        name = entry.get("ldhName") or entry.get("name")
        if name:
            ns.append(str(name))
    return ns


def _parse_crt(payload: list[dict[str, Any]], domain: str) -> list[dict[str, Any]]:
    """Extrai certificados do JSON do crt.sh, deduplicados."""
    seen: set[str] = set()
    certs = []
    for entry in payload:
        name_value = str(entry.get("name_value", ""))
        if not name_value or name_value in seen:
            continue
        seen.add(name_value)
        names = sorted({n.strip() for n in name_value.split("\n") if n.strip()})
        if not any(n.endswith(f".{domain}") or n == domain for n in names):
            continue
        certs.append(
            {
                "id": entry.get("id"),
                "issuer_name": entry.get("issuer_name"),
                "not_before": entry.get("not_before"),
                "not_after": entry.get("not_after"),
                "names": names,
            }
        )
        if len(certs) >= 20:  # limite de segurança
            break
    return certs


def _subdomains_from_certs(certs: list[dict[str, Any]], domain: str) -> list[str]:
    subdomains: set[str] = set()
    for cert in certs:
        for name in cert.get("names", []):
            name = name.strip().lower().lstrip("*.")
            if name == domain or not name.endswith(f".{domain}"):
                continue
            subdomains.add(name)
    return sorted(subdomains)


_TECH_PATTERNS = [
    (r"cloudfront\.net$", "AWS CloudFront (CDN)"),
    (r"cloudflare\.net$", "Cloudflare (CDN/WAF)"),
    (r"\.s3\.[a-z0-9-]+\.amazonaws\.com$", "Amazon S3"),
    (r"azureedge\.net$", "Microsoft Azure CDN"),
    (r"\.trafficmanager\.net$", "Azure Traffic Manager"),
    (r"\.cdn\.cloudflare\.net$", "Cloudflare CDN"),
    (r"\.ghost\.io$", "Ghost (blog platform)"),
    (r"\.github\.io$", "GitHub Pages"),
    (r"\.netlify\.app$", "Netlify"),
    (r"\.vercel\.app$", "Vercel"),
    (r"\.pages\.dev$", "Cloudflare Pages"),
    (r"\.firebaseapp\.com$", "Firebase Hosting"),
    (r"\.web\.app$", "Google App Engine"),
]


def _infer_technologies(dns_data: dict[str, Any]) -> list[dict[str, str]]:
    """Tecnologias publicamente identificáveis por padrões de DNS."""
    techs: list[dict[str, str]] = []
    cnames = dns_data.get("CNAME") or []
    mx = dns_data.get("MX") or []

    for record in cnames:
        host = str(record).rstrip(".").lower()
        for pattern, tech in _TECH_PATTERNS:
            if re.search(pattern, host):
                techs.append({"tech": tech, "evidence": host, "type": "CNAME"})

    google_mx = any("google" in str(r).lower() for r in mx)
    microsoft_mx = any("outlook" in str(r).lower() or "protection.outlook" in str(r).lower() for r in mx)
    zoho_mx = any("zoho" in str(r).lower() for r in mx)

    if google_mx:
        techs.append({"tech": "Google Workspace (inferido de MX)", "evidence": str(mx[0]), "type": "MX"})
    if microsoft_mx:
        techs.append({"tech": "Microsoft 365 (inferido de MX)", "evidence": str(mx[0]), "type": "MX"})
    if zoho_mx:
        techs.append({"tech": "Zoho Mail (inferido de MX)", "evidence": str(mx[0]), "type": "MX"})
    return techs
