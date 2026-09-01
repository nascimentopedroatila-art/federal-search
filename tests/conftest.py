"""Fixtures compartilhadas dos testes."""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest

# Garante imports estáveis a partir da raiz do projeto
ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


@pytest.fixture(autouse=True)
def _clean_singletons(monkeypatch):
    """Zera singletons e remove chaves de ambiente entre testes."""
    from core.cache import Cache
    from core.config import Config

    Config.reset()
    Cache._instances = {} if hasattr(Cache, "_instances") else None
    for key in list(os.environ.keys()):
        if key.endswith("_API_KEY") or key.endswith("_API_ID") or key.endswith("_API_SECRET"):
            monkeypatch.delenv(key, raising=False)
    monkeypatch.setenv("NEXUS_DATA_DIR", str(ROOT / "data"))
    # Remove artefatos de runtime para testes isolados e sem poluição do repo.
    from core.constants import API_KEYS_PATH, DATABASE_PATH, DEFAULT_CACHE_PATH

    for path in (DATABASE_PATH, DEFAULT_CACHE_PATH, API_KEYS_PATH):
        try:
            path.unlink(missing_ok=True)
        except OSError:
            pass
    yield
    Config.reset()


@pytest.fixture
def tmp_db(tmp_path):
    """Banco SQLite temporário."""
    from database.database import Database

    return Database(path=tmp_path / "test.db")


@pytest.fixture
def offline_context(tmp_path):
    """Contexto de engine com cache em diretório temporário e sem persistir DB."""
    from core.config import Config

    config = Config(data={"save_to_database": False, "cache_enabled": True})
    return {"config": config, "save_to_database": False}


def run(coro):
    """Roda uma coroutine (helper para testes síncronos)."""
    import asyncio

    return asyncio.run(coro)
