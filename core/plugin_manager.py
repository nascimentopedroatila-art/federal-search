"""Gerenciador de plugins: descoberta automática, registro e filtragem."""

from __future__ import annotations

import importlib
import importlib.util
import inspect
import pkgutil
from pathlib import Path
from typing import Any

from core.constants import PLUGINS_DIR, TargetType
from core.errors import PluginRegistrationError
from core.logger import get_logger
from core.plugin import NexusPlugin

log = get_logger("plugins")


class PluginManager:
    """Descobre e gerencia plugins.

    A descoberta percorre ``plugins/`` (subpacotes e módulos únicos) e
    coleta toda subclasse concreta de :class:`NexusPlugin`. Também é
    possível registrar plugins programaticamente via :meth:`register`.
    """

    def __init__(self, plugins_dir: Path | str | None = None) -> None:
        self.plugins_dir = Path(plugins_dir) if plugins_dir else PLUGINS_DIR
        self._plugins: dict[str, type[NexusPlugin]] = {}
        self._instances: dict[str, NexusPlugin] = {}

    # ------------------------------------------------------------------ #
    # Descoberta
    # ------------------------------------------------------------------ #
    def discover(self) -> list[NexusPlugin]:
        """Carrega todos os plugins do diretório padrão."""
        import sys

        self._plugins.clear()
        self._instances.clear()
        if not self.plugins_dir.exists():
            log.warning("Diretório de plugins não encontrado: %s", self.plugins_dir)
            return []

        if str(self.plugins_dir.parent) not in sys.path:
            sys.path.insert(0, str(self.plugins_dir.parent))

        for module_info in pkgutil.iter_modules([str(self.plugins_dir)]):
            if module_info.ispkg:
                self._load_package(module_info.name)
            else:
                self._load_module(module_info.name)

        instances = [cls() for cls in self._plugins.values()]
        log.info("Plugins descobertos: %d", len(instances))
        return instances

    def _load_package(self, package_name: str) -> None:
        """Carrega um pacote de plugin (ex.: plugins/phone/)."""
        module = importlib.import_module(f"plugins.{package_name}")
        # Plugin em plugin/<nome>/plugin.py
        if hasattr(module, "__path__"):
            for sub in pkgutil.iter_modules(module.__path__):
                if sub.name == "plugin":
                    submodule = importlib.import_module(f"plugins.{package_name}.plugin")
                    self._collect(submodule)
                else:
                    self._load_module(f"{package_name}.{sub.name}")
        self._collect(module)

    def _load_module(self, module_name: str) -> None:
        try:
            module = importlib.import_module(f"plugins.{module_name}")
            self._collect(module)
        except Exception:  # noqa: BLE001 - plugin defeituoso não derruba o NEXUS
            log.exception("Falha ao carregar plugin: plugins.%s", module_name)

    def _collect(self, module: Any) -> None:
        for _, cls in inspect.getmembers(module, inspect.isclass):
            if (
                issubclass(cls, NexusPlugin)
                and cls is not NexusPlugin
                and not inspect.isabstract(cls)
                and getattr(cls, "__module__", "").startswith("plugins")
            ):
                self.register(cls)

    # ------------------------------------------------------------------ #
    # Registro
    # ------------------------------------------------------------------ #
    def register(self, plugin_cls: type[NexusPlugin]) -> None:
        """Registra uma classe de plugin."""
        name = getattr(plugin_cls, "name", plugin_cls.__name__)
        if name in self._plugins:
            raise PluginRegistrationError(f"Plugin '{name}' já registrado.")
        if not getattr(plugin_cls, "enabled", True):
            log.debug("Plugin '%s' desabilitado; ignorado.", name)
            return
        self._plugins[name] = plugin_cls
        log.debug("Plugin registrado: %s v%s", name, getattr(plugin_cls, "version", "?"))

    def unregister(self, name: str) -> None:
        self._plugins.pop(name, None)
        self._instances.pop(name, None)

    # ------------------------------------------------------------------ #
    # Acesso
    # ------------------------------------------------------------------ #
    def all(self) -> list[NexusPlugin]:
        """Retorna instâncias de todos os plugins registrados."""
        if not self._instances:
            for name, cls in self._plugins.items():
                self._instances[name] = cls()
        return list(self._instances.values())

    def get(self, name: str) -> NexusPlugin | None:
        for plugin in self.all():
            if plugin.name.lower() == name.lower():
                return plugin
        return None

    def for_target_type(self, target_type: str | TargetType) -> list[NexusPlugin]:
        """Plugins que aceitam o tipo de alvo informado."""
        value = target_type.value if isinstance(target_type, TargetType) else target_type
        return [p for p in self.all() if value in [t.lower() for t in p.target_types]]

    def count(self) -> int:
        return len(self._plugins)

    def reset(self) -> None:
        self._plugins.clear()
        self._instances.clear()
