"""Testes dos plugins: metadados, descoberta e execução resiliente (offline)."""

from __future__ import annotations

import asyncio

import pytest
from core.plugin_manager import PluginManager


@pytest.fixture(scope="module")
def manager() -> PluginManager:
    m = PluginManager()
    m.discover()
    return m


def test_discovery_finds_all_core_plugins(manager: PluginManager) -> None:
    names = {p.name for p in manager.all()}
    expected = {
        "Phone Validator",
        "Email Analyzer",
        "Username Presence",
        "Domain Intelligence",
        "IP Intelligence",
        "DNS Records",
        "Hash Analyzer",
        "Network Diagnostics",
        # V2
        "Safe Browsing URL Check",
        "IPQualityScore URL Scan",
        "IPQualityScore IP",
        "VirusTotal IP",
        "VirusTotal Domain",
        "SecurityTrails Subdomains",
        "Hunter Domain Search",
        "EmailRep.io IP",
    }
    missing = expected - names
    assert not missing, f"plugins ausentes: {missing}"
    assert len(names) >= 16


def test_plugin_metadata_is_complete(manager: PluginManager) -> None:
    required = ("name", "version", "description", "author", "target_types")
    for plugin in manager.all():
        for field in required:
            assert getattr(plugin, field), f"{plugin.name} sem {field}"
        assert plugin.target_types, f"{plugin.name} sem target_types"
        assert isinstance(plugin.timeout, (int, float)) and plugin.timeout > 0


def test_all_target_types_covered(manager: PluginManager) -> None:
    covered = {t for p in manager.all() for t in p.target_types}
    assert {"phone", "email", "username", "domain", "ip", "hash"} <= covered


@pytest.mark.parametrize(
    ("plugin_name", "target"),
    [
        ("Phone Validator", "+5585999999999"),
        ("Email Analyzer", "user@example.com"),
        ("Username Presence", "example_username"),
        ("Domain Intelligence", "example.com"),
        ("IP Intelligence", "8.8.8.8"),
        ("DNS Records", "example.com"),
        ("Hash Analyzer", "d41d8cd98f00b204e9800998ecf8427e"),
        ("Network Diagnostics", "example.com"),
    ],
)
def test_execute_never_raises_offline(manager: PluginManager, plugin_name: str, target: str) -> None:
    """Sem rede, os plugins retornam resultados com status de erro — nunca explodem."""
    plugin = manager.get(plugin_name)
    assert plugin is not None

    async def _run() -> list:
        results = await plugin.execute(target, context={})
        assert isinstance(results, list)
        for result in results:
            assert result.result_type
            assert result.source
            assert result.confidence in {"LOW", "MEDIUM", "HIGH", "CONFIRMED"}
        return results

    results = asyncio.run(_run())
    assert results


def test_phone_plugin_works_fully_offline(manager: PluginManager) -> None:
    """O plugin de telefone é 100% offline (dados públicos da lib phonenumbers)."""
    plugin = manager.get("Phone Validator")
    assert plugin is not None

    async def _run():
        return await plugin.execute("+5585999999999", context={})

    results = asyncio.run(_run())
    validation = next(r for r in results if r.result_type == "validation")
    data = validation.data
    assert data["normalized"] == "+5585999999999"
    assert data["valid"] is True
    assert data["country_code"] == "+55"
    assert data["country"] == "BR"
    assert validation.status == "SUCCESS"


def test_phone_plugin_invalid_number(manager: PluginManager) -> None:
    plugin = manager.get("Phone Validator")
    assert plugin is not None

    async def _run():
        return await plugin.execute("+999", context={})

    results = asyncio.run(_run())
    assert any(r.status == "ERROR" for r in results)


def test_key_required_plugins_report_not_configured(manager: PluginManager) -> None:
    """Sem chaves disponíveis (store vazio), plugins com requires_api_key
    respondem NOT CONFIGURED — independente de env/credenciais da máquina."""

    class _EmptyStore:
        """Store determinístico que nunca possui chaves."""

        def has(self, key: str) -> bool:
            return False

    keyed = [p for p in manager.all() if p.requires_api_key]
    assert keyed, "deve haver plugins que exigem chave"
    for plugin in keyed:
        assert plugin.check_api_key({"secret_store": _EmptyStore()}) is False


@pytest.mark.parametrize(
    ("plugin_name", "target"),
    [
        ("Safe Browsing URL Check", "https://example.com"),
        ("IPQualityScore URL Scan", "https://example.com"),
        ("IPQualityScore IP", "8.8.8.8"),
        ("VirusTotal IP", "8.8.8.8"),
        ("VirusTotal Domain", "example.com"),
        ("SecurityTrails Subdomains", "example.com"),
        ("Hunter Domain Search", "example.com"),
        ("EmailRep.io IP", "8.8.8.8"),
    ],
)
def test_v2_keyed_plugins_return_not_configured_without_key(
    manager: PluginManager, plugin_name: str, target: str
) -> None:
    """Sem chave, os plugins V2 retornam PluginResult NOT_CONFIGURED (sem exceção)."""
    import os

    for env_key in list(os.environ):
        if env_key.endswith("_API_KEY") or env_key.endswith("_API_ID") or env_key.endswith("_API_SECRET"):
            os.environ.pop(env_key, None)

    plugin = manager.get(plugin_name)
    assert plugin is not None

    async def _run() -> list:
        return await plugin.execute(target, context={})

    results = asyncio.run(_run())
    assert results
    assert any(r.status == "NOT_CONFIGURED" for r in results)
