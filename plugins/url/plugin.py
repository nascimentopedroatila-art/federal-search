"""Plugins de reputação de URLs.

Fontes reais e documentadas:

- **Google Safe Browsing v4** — https://developers.google.com/safe-browsing/v4
  (POST threatMatches:find, exige chave, tier gratuito 10.000/dia).
- **IPQualityScore URL Scanner** — https://www.ipqualityscore.com/documentation/url-scoring-api
  (GET /api/json/url/{key}/{url}, exige chave, tier gratuito 5.000/mês).

Nenhuma varredura ativa é feita — apenas consultas passivas às APIs.
"""

from __future__ import annotations

from typing import Any

from core.constants import Status
from core.plugin import NexusPlugin, PluginResult

from plugins.http import make_client, safe_get


def _host_of(url: str) -> str:
    from urllib.parse import urlparse

    return urlparse(url).netloc or url


class SafeBrowsingUrlPlugin(NexusPlugin):
    """Verifica uma URL nas listas de ameaças do Google Safe Browsing."""

    name = "Safe Browsing URL Check"
    version = "2.0"
    description = "Reputação de URL via Google Safe Browsing v4 (threatMatches)."
    author = "NEXUS Project"
    target_types = ["url"]
    requires_api_key = "GOOGLE_SAFE_BROWSING_API_KEY"
    rate_limit = 2.0
    timeout = 15.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        store = (context or {}).get("secret_store")
        api_key = store.get("GOOGLE_SAFE_BROWSING_API_KEY") if store else None
        if not api_key:
            return [
                PluginResult(
                    result_type="reputation",
                    data={
                        "url": target,
                        "message": "NOT CONFIGURED — defina GOOGLE_SAFE_BROWSING_API_KEY",
                    },
                    source="Google Safe Browsing",
                    confidence="LOW",
                    status=Status.NOT_CONFIGURED.value,
                )
            ]

        body = {
            "client": {"clientId": "nexus", "clientVersion": "2.0.0"},
            "threatInfo": {
                "threatTypes": [
                    "MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE",
                    "POTENTIALLY_HARMFUL_APPLICATION", "THREAT_TYPE_UNSPECIFIED",
                ],
                "platformTypes": ["ANY_PLATFORM"],
                "threatEntryTypes": ["URL"],
                "threatEntries": [{"url": target}],
            },
        }
        async with make_client(timeout=12.0) as client:
            try:
                response = await client.post(
                    "https://safebrowsing.googleapis.com/v4/threatMatches:find",
                    params={"key": api_key},
                    json=body,
                )
                if response.status_code == 200:
                    payload = response.json()
                else:
                    payload = None
                    error = f"HTTP {response.status_code}"
            except Exception as exc:  # noqa: BLE001
                payload, error = None, str(exc)

        if payload is None:
            return [
                PluginResult(
                    result_type="reputation",
                    data={"url": target, "error": error},
                    source="Google Safe Browsing",
                    confidence="LOW",
                    status=Status.ERROR.value,
                )
            ]

        matches = payload.get("matches") or []
        if not matches:
            return [
                PluginResult(
                    result_type="reputation",
                    data={"url": target, "safe": True, "matches": []},
                    source="Google Safe Browsing",
                    confidence="HIGH",
                )
            ]

        return [
            PluginResult(
                result_type="reputation",
                data={
                    "url": target,
                    "safe": False,
                    "matches": [
                        {
                            "threat_type": m.get("threatType"),
                            "platform_type": m.get("platformType"),
                            "threat_entry": (m.get("threat", {}) or {}).get("url"),
                            "cache_duration": m.get("cacheDuration"),
                        }
                        for m in matches
                    ],
                },
                source="Google Safe Browsing",
                confidence="HIGH",
            )
        ]


class IpQualityScoreUrlPlugin(NexusPlugin):
    """Análise de risco de uma URL via IPQualityScore."""

    name = "IPQualityScore URL Scan"
    version = "2.0"
    description = "Risk score, phishing, malware e fraude de URL via IPQualityScore."
    author = "NEXUS Project"
    target_types = ["url"]
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
                        "url": target,
                        "message": "NOT CONFIGURED — defina IPQUALITYSCORE_API_KEY",
                    },
                    source="IPQualityScore",
                    confidence="LOW",
                    status=Status.NOT_CONFIGURED.value,
                )
            ]

        endpoint = f"https://ipqualityscore.com/api/json/url/{api_key}/{target}"
        async with make_client(timeout=12.0) as client:
            status_code, payload, error = await safe_get(client, endpoint)

        if status_code != 200 or not isinstance(payload, dict):
            return [
                PluginResult(
                    result_type="reputation",
                    data={"url": target, "error": error or f"HTTP {status_code}"},
                    source="IPQualityScore",
                    confidence="LOW",
                    status=Status.ERROR.value,
                )
            ]

        return [
            PluginResult(
                result_type="reputation",
                data={
                    "url": target,
                    "host": _host_of(target),
                    "risk_score": payload.get("risk_score"),
                    "unsafe": payload.get("unsafe"),
                    "phishing": payload.get("phishing"),
                    "malware": payload.get("malware"),
                    "suspicious": payload.get("suspicious"),
                    "spamming": payload.get("spamming"),
                    "domain_age_days": payload.get("domain_age"),
                    "server": payload.get("server"),
                    "country": payload.get("country_code"),
                    "message": payload.get("message"),
                },
                source="IPQualityScore",
                confidence="HIGH",
            )
        ]
