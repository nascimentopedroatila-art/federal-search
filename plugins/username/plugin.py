"""Plugin de presença pública de usernames.

Consulta apenas páginas públicas de perfil via HTTP. **Não** faz login,
**não** tenta descobrir senhas e **não** contorna CAPTCHA.
"""

from __future__ import annotations

from typing import Any

from core.constants import Status
from core.plugin import NexusPlugin, PluginResult

from plugins.http import make_client

# Serviços públicos com URL de perfil determinística.
SERVICES: list[dict[str, Any]] = [
    {"service": "GitHub", "url": "https://github.com/{u}"},
    {"service": "GitLab", "url": "https://gitlab.com/{u}"},
    {"service": "X/Twitter", "url": "https://x.com/{u}"},
    {"service": "Reddit", "url": "https://www.reddit.com/user/{u}"},
    {"service": "Instagram", "url": "https://www.instagram.com/{u}/"},
    {"service": "Telegram", "url": "https://t.me/{u}"},
    {"service": "Mastodon.social", "url": "https://mastodon.social/@{u}"},
]

# Serviços que respondem 200 para qualquer usuário (ou bloqueiam bots)
# — resultados desses são marcados como LOW.
UNRELIABLE = {"Instagram"}


class UsernamePlugin(NexusPlugin):
    """Verifica presença pública de um username em serviços suportados."""

    name = "Username Presence"
    version = "1.0"
    description = "Presença pública de usernames em GitHub, GitLab, X, Reddit, Instagram, Telegram e Mastodon."
    author = "NEXUS Project"
    target_types = ["username"]
    requires_api_key = None
    rate_limit = 2.0
    timeout = 25.0

    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        results: list[PluginResult] = []
        async with make_client(timeout=8.0) as client:
            for service in SERVICES:
                url = service["url"].format(u=target)
                try:
                    response = await client.get(url)
                    status = response.status_code
                except Exception:  # noqa: BLE001
                    results.append(
                        PluginResult(
                            result_type="presence",
                            data={
                                "service": service["service"],
                                "username": target,
                                "url": url,
                                "status": "ERROR",
                                "present": None,
                            },
                            source=service["service"],
                            confidence="LOW",
                            status=Status.ERROR.value,
                        )
                    )
                    continue

                if status == 200:
                    present, confidence, note = True, "HIGH", "perfil público encontrado"
                elif status in (301, 302, 303, 307, 308):
                    location = response.headers.get("location", "")
                    present = bool(location and location != url)
                    confidence = "MEDIUM" if present else "LOW"
                    note = f"redirect: {location[:80]}" if location else "redirect sem destino"
                elif status == 404:
                    present, confidence, note = False, "HIGH", "perfil não encontrado (404)"
                elif status == 429:
                    present, confidence, note = None, "LOW", "RATE_LIMITED"
                else:
                    present, confidence, note = None, "LOW", f"HTTP {status}"

                if service["service"] in UNRELIABLE:
                    confidence = "LOW"
                    note += " (serviço pode responder 200 para perfis inexistentes)"

                results.append(
                    PluginResult(
                        result_type="presence",
                        data={
                            "service": service["service"],
                            "username": target,
                            "url": url,
                            "status": "present" if present else "absent" if present is False else note,
                            "present": present,
                            "note": note,
                        },
                        source=service["service"],
                        confidence=confidence,
                        status=Status.SUCCESS.value if present is not None else Status.NO_RESULTS.value,
                    )
                )
        return results
