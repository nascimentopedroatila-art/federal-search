"""Testes da engine: execução, isolamento de falhas, dedup e status."""

from __future__ import annotations

import asyncio

from core.constants import Confidence, Status
from core.engine import Engine
from core.plugin import NexusPlugin, PluginResult
from core.plugin_manager import PluginManager


class OkPlugin(NexusPlugin):
    name = "Test Ok Plugin"
    target_types = ["domain"]

    async def execute(self, target: str, context=None) -> list[PluginResult]:
        return [
            PluginResult(
                result_type="info",
                data={"key": "shared_value"},
                source="test-a",
                confidence=Confidence.HIGH.value,
            ),
            PluginResult(
                result_type="info",
                data={"key": "unique"},
                source="test-a",
                confidence=Confidence.MEDIUM.value,
            ),
        ]


class DuplicatePlugin(NexusPlugin):
    name = "Test Duplicate Plugin"
    target_types = ["domain"]

    async def execute(self, target: str, context=None) -> list[PluginResult]:
        return [
            PluginResult(
                result_type="info",
                data={"key": "shared_value"},
                source="test-b",
                confidence=Confidence.CONFIRMED.value,
            )
        ]


class BrokenPlugin(NexusPlugin):
    name = "Test Broken Plugin"
    target_types = ["domain"]

    async def execute(self, target: str, context=None) -> list[PluginResult]:
        raise RuntimeError("boom interno")


class KeyedPlugin(NexusPlugin):
    name = "Test Keyed Plugin"
    target_types = ["domain"]
    requires_api_key = "ABUSEIPDB_API_KEY"

    async def execute(self, target: str, context=None) -> list[PluginResult]:
        return [PluginResult(result_type="info", data={"key": "k"}, source="keyed", confidence="LOW")]


def _make_engine(plugins: list[type[NexusPlugin]]) -> Engine:
    manager = PluginManager()
    for cls in plugins:
        manager.register(cls)
    return Engine(plugin_manager=manager)


def test_scan_returns_scan_result() -> None:
    engine = _make_engine([OkPlugin])
    result = asyncio.run(engine.run_scan("example.com", context={"save_to_database": False}))
    assert result.target == "example.com"
    assert result.target_type == "domain"
    assert result.scan_id
    assert result.duration >= 0


def test_deduplication_across_plugins() -> None:
    engine = _make_engine([OkPlugin, DuplicatePlugin])
    result = asyncio.run(engine.run_scan("example.com", context={"save_to_database": False}))
    # shared_value (2 fontes, CONFIRMED) + unique (1 fonte) = 2 resultados
    assert len(result.plugin_results) == 2
    shared = next(r for r in result.plugin_results if r["data"]["key"] == "shared_value")
    assert shared["source_count"] == 2
    assert shared["confidence"] == Confidence.CONFIRMED.value
    assert set(shared["sources"]) == {"test-a", "test-b"}  # ordem = concorrência, não garantida


def test_broken_plugin_does_not_stop_scan() -> None:
    engine = _make_engine([OkPlugin, BrokenPlugin])
    result = asyncio.run(engine.run_scan("example.com", context={"save_to_database": False}))
    assert result.plugin_status["Test Ok Plugin"] == Status.SUCCESS.value
    assert result.plugin_status["Test Broken Plugin"] == Status.ERROR.value
    assert len(result.plugin_results) >= 1
    assert any(e["plugin"] == "Test Broken Plugin" for e in result.errors)


def test_missing_api_key_marks_not_configured() -> None:
    import os

    os.environ.pop("ABUSEIPDB_API_KEY", None)
    engine = _make_engine([KeyedPlugin])
    result = asyncio.run(engine.run_scan("example.com", context={"save_to_database": False}))
    assert result.plugin_status["Test Keyed Plugin"] == Status.NOT_CONFIGURED.value


def test_forced_target_type_is_respected() -> None:
    engine = _make_engine([OkPlugin])
    result = asyncio.run(
        engine.run_scan("example.com", target_type="domain", context={"save_to_database": False})
    )
    assert result.target_type == "domain"
    assert result.target == "example.com"


def test_unknown_target_type_raises() -> None:
    engine = _make_engine([OkPlugin])
    import pytest
    from core.errors import TargetError

    with pytest.raises(TargetError):
        asyncio.run(engine.run_scan("sem tipo", context={"save_to_database": False}))


def test_plugin_filter_selects_only_named() -> None:
    engine = _make_engine([OkPlugin, DuplicatePlugin])
    result = asyncio.run(
        engine.run_scan("example.com", plugin_names=["Test Ok Plugin"], context={"save_to_database": False})
    )
    assert set(result.plugin_status.keys()) == {"Test Ok Plugin"}


def test_scan_result_to_dict_is_serializable() -> None:
    engine = _make_engine([OkPlugin])
    result = asyncio.run(engine.run_scan("example.com", context={"save_to_database": False}))
    payload = result.to_dict()
    assert payload["scan_id"] == result.scan_id
    assert isinstance(payload["results"], list)
    assert "plugins" in payload
