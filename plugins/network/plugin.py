"""Plugin Network: diagnóstico de redes próprias ou autorizadas.

Quando executado via engine (``scan --target ...``), coleta o
diagnóstico local e, para alvos domain/ip, testa conectividade TCP
básica (porta 80/443) — apenas contra hosts que o usuário escolher.
"""

from __future__ import annotations

import asyncio
from typing import Any

from core.constants import Status
from core.plugin import NexusPlugin, PluginResult

from plugins.network.diagnostics import diagnose_local


class NetworkDiagnosticsPlugin(NexusPlugin):
    """Diagnóstico da rede local e conectividade básica."""

    name = "Network Diagnostics"
    version = "1.0"
    description = "Interfaces, gateway, DNS configurado, recursos do sistema e conectividade TCP básica."
    author = "NEXUS Project"
    target_types = ["domain", "ip", "url", "phone", "email", "username", "hash"]
    requires_api_key = None
    rate_limit = 5.0
    timeout = 20.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        results: list[PluginResult] = []
        local = diagnose_local()
        results.append(
            PluginResult(
                result_type="diagnostic",
                data={"check": "rede local", "detail": local},
                source="local (psutil)",
                confidence="CONFIRMED",
            )
        )

        # Conectividade básica (TCP) contra o alvo, se for host.
        if target and any(c in target for c in ".:"):
            host = target.split("/")[0]
            try:

                async def probe(port: int) -> dict[str, Any]:
                    loop = asyncio.get_event_loop()
                    try:
                        await loop.run_in_executor(None, _tcp_probe, host, port, 4.0)
                        return {"host": host, "port": port, "open": True}
                    except OSError:
                        return {"host": host, "port": port, "open": False}

                probes = await asyncio.gather(probe(80), probe(443))
                results.append(
                    PluginResult(
                        result_type="diagnostic",
                        data={"check": "conectividade TCP", "host": host, "ports": probes},
                        source="local (socket)",
                        confidence="CONFIRMED",
                    )
                )
            except Exception:  # noqa: BLE001
                results.append(
                    PluginResult(
                        result_type="diagnostic",
                        data={"check": "conectividade TCP", "host": host, "error": "falha no probe"},
                        source="local (socket)",
                        confidence="LOW",
                        status=Status.ERROR.value,
                    )
                )
        return results


def _tcp_probe(host: str, port: int, timeout: float) -> None:
    import socket

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect((host, port))
    finally:
        sock.close()
