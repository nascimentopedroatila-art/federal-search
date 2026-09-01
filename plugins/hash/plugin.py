"""Plugin de análise de hashes.

Identifica o algoritmo pelo tamanho (MD5/SHA1/SHA256/SHA512) e consulta
reputação pública via CIRCL hashlookup (sem chave) e VirusTotal
(com chave, se configurada).
"""

from __future__ import annotations

from typing import Any

from core.constants import Status
from core.plugin import NexusPlugin, PluginResult

from plugins.http import make_client, safe_get

ALGORITHMS = {
    32: "MD5",
    40: "SHA1",
    64: "SHA256",
    128: "SHA512",
}


class HashPlugin(NexusPlugin):
    """Identificação e reputação de hashes."""

    name = "Hash Analyzer"
    version = "1.0"
    description = "Identificação do algoritmo (MD5/SHA1/SHA256/SHA512) e reputação via CIRCL hashlookup + VirusTotal."
    author = "NEXUS Project"
    target_types = ["hash"]
    requires_api_key = "VIRUSTOTAL_API_KEY"
    rate_limit = 3.0
    timeout = 25.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        results: list[PluginResult] = []
        algorithm = ALGORITHMS.get(len(target), "DESCONHECIDO")

        results.append(
            PluginResult(
                result_type="validation",
                data={
                    "hash": target,
                    "algorithm": algorithm,
                    "length": len(target),
                    "looks_like_hex": all(c in "0123456789abcdef" for c in target),
                },
                source="regex (offline)",
                confidence="CONFIRMED",
            )
        )

        if algorithm == "DESCONHECIDO":
            results.append(
                PluginResult(
                    result_type="reputation",
                    data={"hash": target, "message": "comprimento não corresponde a MD5/SHA1/SHA256/SHA512"},
                    source="hashlookup.circl.lu",
                    confidence="LOW",
                    status=Status.NO_RESULTS.value,
                )
            )
            return results

        # --- CIRCL hashlookup (sem chave) ------------------------------
        async with make_client(timeout=15.0) as client:
            status_code, payload, error = await safe_get(
                client, f"https://hashlookup.circl.lu/lookup/{algorithm.lower()}/{target}"
            )
        if status_code == 200 and isinstance(payload, dict):
            results.append(
                PluginResult(
                    result_type="reputation",
                    data={
                        "hash": target,
                        "algorithm": algorithm,
                        "known": True,
                        "source_db": payload.get("SourceDB"),
                        "file_name": payload.get("FileName"),
                        "file_size": payload.get("FileSize"),
                        "known_malicious": str(payload.get("KnownMalicious", "")),
                        "hashlookup_source": payload.get("hashlookup:source"),
                    },
                    source="hashlookup.circl.lu",
                    confidence="HIGH",
                )
            )
        elif status_code == 404:
            results.append(
                PluginResult(
                    result_type="reputation",
                    data={
                        "hash": target,
                        "algorithm": algorithm,
                        "known": False,
                        "message": "hash não encontrado nas bases públicas do CIRCL",
                    },
                    source="hashlookup.circl.lu",
                    confidence="MEDIUM",
                )
            )
        else:
            results.append(
                PluginResult(
                    result_type="reputation",
                    data={"hash": target, "error": error or f"HTTP {status_code}"},
                    source="hashlookup.circl.lu",
                    confidence="LOW",
                    status=Status.ERROR.value,
                )
            )

        # --- VirusTotal (com chave) -------------------------------------
        store = (context or {}).get("secret_store")
        if store and store.has("VIRUSTOTAL_API_KEY"):
            api_key = store.get("VIRUSTOTAL_API_KEY")
            async with make_client(timeout=15.0) as client:
                status_code, payload, error = await safe_get(
                    client,
                    f"https://www.virustotal.com/api/v3/files/{target}",
                    headers={"x-apikey": api_key},
                )
            if status_code == 200 and isinstance(payload, dict):
                attributes = (payload.get("data") or {}).get("attributes") or {}
                stats = attributes.get("last_analysis_stats") or {}
                results.append(
                    PluginResult(
                        result_type="reputation",
                        data={
                            "hash": target,
                            "detection_ratio": f"{stats.get('malicious', 0)}/{sum(stats.values()) if stats else 0}",
                            "stats": stats,
                            "meaningful_name": attributes.get("meaningful_name"),
                            "magic": attributes.get("magic"),
                            "first_submission": attributes.get("first_submission_date"),
                        },
                        source="VirusTotal",
                        confidence="HIGH",
                    )
                )
            else:
                results.append(
                    PluginResult(
                        result_type="reputation",
                        data={"hash": target, "error": error or f"HTTP {status_code}"},
                        source="VirusTotal",
                        confidence="LOW",
                        status=Status.ERROR.value,
                    )
                )
        else:
            results.append(
                PluginResult(
                    result_type="reputation",
                    data={"message": "NOT CONFIGURED — defina VIRUSTOTAL_API_KEY para consulta no VirusTotal"},
                    source="VirusTotal",
                    confidence="LOW",
                    status=Status.NOT_CONFIGURED.value,
                )
            )
        return results
