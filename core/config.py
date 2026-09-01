"""Gerenciamento de configuração do NEXUS.

Fontes de configuração (em ordem de prioridade):

1. Variáveis de ambiente (``NEXUS_*``)
2. ``config/config.json`` (gerado a partir do exemplo na 1ª execução)
3. Presets embutidos (LOW / BALANCED / PERFORMANCE)

Nunca armazenar API keys aqui — ver ``core/secret_store``.
"""

from __future__ import annotations

import json
import os
from copy import deepcopy
from pathlib import Path
from typing import Any

from core.constants import CONFIG_DIR, CONFIG_PATH, PERFORMANCE_PRESETS
from core.errors import ConfigurationError

DEFAULT_CONFIG: dict[str, Any] = {
    "version": "2.0.0",
    "performance_preset": "BALANCED",
    "max_concurrent_requests": 5,
    "request_timeout": 15.0,
    "retry_count": 2,
    "cache_enabled": True,
    "cache_ttl": 86400,
    "max_cache_size": 10000,
    "output_format": "json",
    "logging_level": "INFO",
    "save_to_database": True,
    "show_sources": True,
    "max_results_per_plugin": 250,
    "default_scan_timeout_seconds": 300,
}


def _merge_dicts(base: dict, override: dict) -> dict:
    result = deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = _merge_dicts(result[key], value)
        else:
            result[key] = value
    return result


class Config:
    """Configuração tipada, carregada uma única vez e acessível globalmente."""

    _instance: "Config | None" = None

    def __init__(self, path: Path | None = None, data: dict | None = None) -> None:
        self.path = Path(path) if path else CONFIG_PATH
        self._data: dict[str, Any] = deepcopy(DEFAULT_CONFIG)
        if data is not None:
            self._data = _merge_dicts(self._data, data)
        else:
            self._load()

    @classmethod
    def instance(cls) -> "Config":
        """Singleton da configuração."""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    @classmethod
    def reset(cls) -> None:
        """Zera o singleton (útil em testes)."""
        cls._instance = None

    # ------------------------------------------------------------------ #
    # Carregamento / persistência
    # ------------------------------------------------------------------ #
    def _load(self) -> None:
        if not self.path.exists():
            self._create_default()
            return
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
            if not isinstance(raw, dict):
                raise ConfigurationError(f"{self.path} deve conter um objeto JSON.")
            self._data = _merge_dicts(DEFAULT_CONFIG, raw)
            self._apply_preset_if_needed(explicit_keys=set(raw.keys()))
        except json.JSONDecodeError as exc:
            raise ConfigurationError(f"JSON inválido em {self.path}: {exc}") from exc

    def _apply_preset_if_needed(self, explicit_keys: set[str] | None = None) -> None:
        explicit_keys = explicit_keys or set()
        preset = str(self._data.get("performance_preset", "")).upper()
        if preset in PERFORMANCE_PRESETS and preset != "CUSTOM":
            # O preset preenche apenas valores não definidos explicitamente
            # pelo usuário (valores do arquivo sempre vencem).
            for key, value in PERFORMANCE_PRESETS[preset].items():
                if key not in explicit_keys:
                    self._data[key] = value
            self._data["performance_preset"] = preset
        elif preset == "CUSTOM":
            pass  # mantém valores explícitos do arquivo
        else:
            self._data["performance_preset"] = "BALANCED"

    def _create_default(self) -> None:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self._data["performance_preset"] = "BALANCED"
            self._data = _merge_dicts(self._data, PERFORMANCE_PRESETS["BALANCED"])
            self.save()
            print(f"[config] Arquivo padrão criado: {self.path}")

    def save(self) -> None:
        """Persiste a configuração atual em JSON."""
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(
            json.dumps(self._data, indent=4, ensure_ascii=False), encoding="utf-8"
        )

    # ------------------------------------------------------------------ #
    # Acesso tipado
    # ------------------------------------------------------------------ #
    def get(self, key: str, default: Any = None) -> Any:
        value = self._data.get(key, default)
        env_value = os.environ.get(f"NEXUS_{key.upper()}")
        if env_value is not None:
            return _coerce(env_value, value)
        return value

    def set(self, key: str, value: Any) -> None:
        self._data[key] = value

    def as_dict(self) -> dict[str, Any]:
        return deepcopy(self._data)

    # ------------------------------------------------------------------ #
    # Atalhos frequentes
    # ------------------------------------------------------------------ #
    @property
    def cache_enabled(self) -> bool:
        return bool(self.get("cache_enabled", True))

    @property
    def cache_ttl(self) -> int:
        return int(self.get("cache_ttl", 86400))

    @property
    def max_cache_size(self) -> int:
        return int(self.get("max_cache_size", 10000))

    @property
    def max_concurrent_requests(self) -> int:
        return int(self.get("max_concurrent_requests", 5))

    @property
    def request_timeout(self) -> float:
        return float(self.get("request_timeout", 15.0))

    @property
    def retry_count(self) -> int:
        return int(self.get("retry_count", 2))

    @property
    def logging_level(self) -> str:
        return str(self.get("logging_level", "INFO")).upper()

    @property
    def output_format(self) -> str:
        return str(self.get("output_format", "json")).lower()

    @property
    def max_results_per_plugin(self) -> int:
        return int(self.get("max_results_per_plugin", 250))


def _coerce(value: str, reference: Any) -> Any:
    """Converte um valor de ambiente para o tipo do valor de referência."""
    if isinstance(reference, bool):
        return value.strip().lower() in ("1", "true", "yes", "on")
    if isinstance(reference, int):
        try:
            return int(value)
        except ValueError:
            return reference
    if isinstance(reference, float):
        try:
            return float(value)
        except ValueError:
            return reference
    return value


def load_config(path: Path | None = None) -> Config:
    """Carrega (e cachead) a configuração do NEXUS."""
    if path is not None:
        return Config(path=path)
    return Config.instance()
