"""Testes do cache."""

from __future__ import annotations

import time

from core.cache import Cache


def test_set_get_roundtrip(tmp_path) -> None:
    cache = Cache(path=tmp_path / "cache.db", enabled=True, ttl=3600)
    cache.set("key-1", {"answer": 42})
    assert cache.get("key-1") == {"answer": 42}


def test_missing_key_returns_none(tmp_path) -> None:
    cache = Cache(path=tmp_path / "cache.db", enabled=True, ttl=3600)
    assert cache.get("não-existe") is None


def test_ttl_expiry(tmp_path) -> None:
    cache = Cache(path=tmp_path / "cache.db", enabled=True, ttl=1)
    cache.set("k", "v")
    assert cache.get("k") == "v"
    time.sleep(1.2)
    assert cache.get("k") is None


def test_disabled_cache_does_nothing(tmp_path) -> None:
    cache = Cache(path=tmp_path / "cache.db", enabled=False)
    cache.set("k", "v")
    assert cache.get("k") is None
    assert cache.size() == 0


def test_max_size_trims_lru(tmp_path) -> None:
    cache = Cache(path=tmp_path / "cache.db", enabled=True, ttl=3600, max_size=3)
    for i in range(5):
        cache.set(f"key-{i}", i)
    assert cache.size() <= 3
    assert cache.get("key-0") is None  # LRU removido
    assert cache.get("key-4") == 4


def test_clear(tmp_path) -> None:
    cache = Cache(path=tmp_path / "cache.db", enabled=True, ttl=3600)
    cache.set("k", "v")
    cache.clear()
    assert cache.size() == 0


def test_make_key_deterministic_and_scoped() -> None:
    a = Cache.make_key("plugin", "example.com", "A")
    b = Cache.make_key("plugin", "example.com", "A")
    c = Cache.make_key("plugin", "example.com", "B")
    assert a == b
    assert a != c
    assert len(a) == 64


def test_delete(tmp_path) -> None:
    cache = Cache(path=tmp_path / "cache.db", enabled=True, ttl=3600)
    cache.set("k", "v")
    cache.delete("k")
    assert cache.get("k") is None
