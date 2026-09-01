"""Utilitários HTTP compartilhados pelos plugins.

Regras:
- sempre definir timeout e User-Agent;
- nunca enviar API keys em logs;
- falhas de rede viram resultados com status ERROR, nunca exceções.
"""

from __future__ import annotations

from typing import Any

import httpx

USER_AGENT = (
    "Mozilla/5.0 (compatible; NEXUS/2.0 Modular Intelligence Toolkit; "
    "+https://github.com/nascimentopedroatila-art/federal-search)"
)

DEFAULT_HEADERS = {
    "User-Agent": USER_AGENT,
    "Accept": "application/json",
}


def make_client(timeout: float = 15.0, **kwargs: Any) -> httpx.AsyncClient:
    """Cria um AsyncClient com as configurações padrão do NEXUS."""
    return httpx.AsyncClient(
        timeout=timeout,
        follow_redirects=kwargs.pop("follow_redirects", True),
        headers=kwargs.pop("headers", DEFAULT_HEADERS),
        limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
        **kwargs,
    )


async def safe_get(
    client: httpx.AsyncClient,
    url: str,
    params: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
) -> tuple[int | None, Any, str | None]:
    """GET com tratamento de erro. Retorna (status, payload_json, erro)."""
    try:
        response = await client.get(url, params=params, headers=headers)
        if response.status_code == 404:
            return 404, None, None
        if response.status_code >= 400:
            return response.status_code, None, f"HTTP {response.status_code}"
        try:
            return response.status_code, response.json(), None
        except ValueError:
            return response.status_code, {"text": response.text[:500]}, None
    except httpx.TimeoutException:
        return None, None, "timeout"
    except httpx.HTTPError as exc:
        return None, None, str(exc)
    except Exception as exc:  # noqa: BLE001
        return None, None, str(exc)
