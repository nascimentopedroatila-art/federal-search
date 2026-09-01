"""Dispatcher: seleção e ordenação dos plugins para um alvo.

- Aplica o detector de alvos (ou o tipo informado pelo usuário).
- Filtra plugins pelo tipo de alvo.
- Ordena por ``priority`` e ``name``.
- Monta o contexto de execução (config, cache, secret store, client).
"""

from __future__ import annotations

from typing import Any

from core.plugin import NexusPlugin
from core.plugin_manager import PluginManager
from core.target_detector import resolve

# Prioridade padrão: 100 = normal, menor = primeiro.
DEFAULT_PRIORITY = 100


def priority_of(plugin: NexusPlugin) -> int:
    return int(getattr(plugin, "priority", DEFAULT_PRIORITY))


class Dispatcher:
    """Decide quais plugins executar para um alvo."""

    def __init__(self, plugin_manager: PluginManager | None = None) -> None:
        if plugin_manager is None:
            plugin_manager = PluginManager()
            plugin_manager.discover()
        self.manager = plugin_manager

    def resolve_target(self, target: str, target_type: str | None = None) -> tuple[str, str]:
        normalized, ttype = resolve(target, target_type)
        return normalized, ttype.value

    def select_plugins(self, target_type: str, plugin_names: list[str] | None = None) -> list[NexusPlugin]:
        """Seleciona plugins compatíveis, opcionalmente filtrados por nome."""
        candidates = self.manager.for_target_type(target_type)
        if plugin_names:
            wanted = {name.strip().lower() for name in plugin_names}
            candidates = [
                p for p in candidates if p.name.lower() in wanted
            ]
        return sorted(candidates, key=lambda p: (priority_of(p), p.name.lower()))

    def build_context(self, **overrides: Any) -> dict[str, Any]:
        """Contexto compartilhado passado aos plugins na execução."""
        from core.cache import Cache
        from core.config import load_config
        from core.secret_store import get_secret_store

        config = load_config()
        context: dict[str, Any] = {
            "config": config,
            "cache": Cache(
                enabled=config.cache_enabled,
                ttl=config.cache_ttl,
                max_size=config.max_cache_size,
            ),
            "secret_store": get_secret_store(),
            "session": None,
            "max_results": int(config.max_results_per_plugin),
        }
        context.update(overrides)
        return context

    def describe(self, target_type: str) -> list[dict[str, Any]]:
        """Metadados dos plugins disponíveis para um tipo de alvo."""
        return [
            {
                "name": p.name,
                "version": p.version,
                "description": p.description,
                "author": p.author,
                "requires_api_key": p.requires_api_key,
                "rate_limit": p.rate_limit,
                "timeout": p.timeout,
            }
            for p in self.select_plugins(target_type)
        ]
