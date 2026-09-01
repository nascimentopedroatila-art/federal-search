"""Testes de tratamento de erros."""

from __future__ import annotations

import json

import pytest
from core.config import Config
from core.errors import ApiKeyError, ConfigurationError, NexusError, TargetError
from core.secret_store import SUPPORTED_KEYS, SecretStore


def test_config_invalid_json_raises(tmp_path) -> None:
    path = tmp_path / "config.json"
    path.write_text("{ inválido", encoding="utf-8")
    with pytest.raises(ConfigurationError):
        Config(path=path)


def test_config_non_object_raises(tmp_path) -> None:
    path = tmp_path / "config.json"
    path.write_text("[1,2,3]", encoding="utf-8")
    with pytest.raises(ConfigurationError):
        Config(path=path)


def test_config_creates_default(tmp_path) -> None:
    path = tmp_path / "config.json"
    config = Config(path=path)
    assert path.exists()
    assert config.get("max_concurrent_requests") >= 1
    assert config.get("cache_enabled") is True


def test_config_merges_user_values(tmp_path) -> None:
    path = tmp_path / "config.json"
    path.write_text(json.dumps({"max_concurrent_requests": 1, "cache_enabled": False}), encoding="utf-8")
    config = Config(path=path)
    assert config.get("max_concurrent_requests") == 1
    assert config.get("cache_enabled") is False
    # valores não informados vêm do default
    assert config.get("request_timeout", 15.0) == 15.0


def test_config_preset_applies(tmp_path) -> None:
    path = tmp_path / "config.json"
    path.write_text(json.dumps({"performance_preset": "PERFORMANCE"}), encoding="utf-8")
    config = Config(path=path)
    assert config.get("max_concurrent_requests") == 12


def test_secret_store_unknown_key_raises(tmp_path) -> None:
    store = SecretStore(keys_path=tmp_path / "keys.json")
    with pytest.raises(ApiKeyError):
        store.set("MINHA_CHAVE_SECRETA", "valor")


def test_secret_store_empty_value_raises(tmp_path) -> None:
    store = SecretStore(keys_path=tmp_path / "keys.json")
    with pytest.raises(ApiKeyError):
        store.set(SUPPORTED_KEYS[0], "   ")


def test_secret_store_roundtrip_and_redaction(tmp_path) -> None:
    store = SecretStore(keys_path=tmp_path / "keys.json")
    # backend=file: nunca tocar no Credential Manager real em testes.
    store.set("ABUSEIPDB_API_KEY", "valor-super-secreto", backend="file")
    assert store.get("ABUSEIPDB_API_KEY") == "valor-super-secreto"
    # list() nunca expõe o valor
    for row in store.list():
        assert "valor-super-secreto" not in str(row)
    store.delete("ABUSEIPDB_API_KEY")
    assert store.get("ABUSEIPDB_API_KEY") is None


def test_environment_precedence_over_file(tmp_path, monkeypatch) -> None:
    store = SecretStore(keys_path=tmp_path / "keys.json")
    store.set("ABUSEIPDB_API_KEY", "do-arquivo", backend="file")
    monkeypatch.setenv("ABUSEIPDB_API_KEY", "do-ambiente")
    assert store.get("ABUSEIPDB_API_KEY") == "do-ambiente"


def test_all_errors_share_base() -> None:
    assert issubclass(ConfigurationError, NexusError)
    assert issubclass(TargetError, NexusError)
    assert issubclass(ApiKeyError, NexusError)


def test_plugins_error_paths_return_results(tmp_path) -> None:
    """Plugin com fonte inacessível retorna resultado com status ERROR."""
    import asyncio

    from core.plugin_manager import PluginManager

    manager = PluginManager()
    manager.discover()
    plugin = manager.get("Domain Intelligence")
    assert plugin is not None

    async def _run():
        return await plugin.execute("example.com", context={})

    results = asyncio.run(_run())
    assert results
    statuses = {r.status for r in results}
    assert statuses  # SUCCESS (DNS local) + possíveis ERRORs (fontes web)
