"""Cache do NEXUS (SQLite, thread-safe).

Evita consultas repetidas desnecessárias. Configurações:

- ``CACHE_ENABLED`` (bool)
- ``CACHE_TTL``     (segundos)
- ``MAX_CACHE_SIZE``(número máximo de entradas; remoção LRU)
"""

from __future__ import annotations

import hashlib
import json
import sqlite3
import threading
import time
from pathlib import Path
from typing import Any

from core.constants import DEFAULT_CACHE_PATH
from core.logger import get_logger

log = get_logger("cache")


class Cache:
    """Cache persistente baseado em SQLite com expiração por TTL e LRU."""

    def __init__(
        self,
        path: Path | str | None = None,
        enabled: bool = True,
        ttl: int = 86400,
        max_size: int = 10000,
    ) -> None:
        self.path = Path(path) if path else DEFAULT_CACHE_PATH
        self.enabled = enabled
        self.ttl = int(ttl)
        self.max_size = int(max_size)
        self._lock = threading.Lock()
        if self.enabled:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            self._init_db()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.path), timeout=10)
        conn.execute("PRAGMA journal_mode=WAL;")
        return conn

    def _init_db(self) -> None:
        with self._lock, self._connect() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS cache (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    expires_at REAL NOT NULL,
                    last_access REAL NOT NULL
                )
                """
            )

    # ------------------------------------------------------------------ #
    @staticmethod
    def make_key(namespace: str, *parts: Any) -> str:
        """Gera uma chave determinística a partir de partes serializáveis."""
        raw = json.dumps([namespace, *parts], sort_keys=True, default=str)
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    def get(self, key: str) -> Any | None:
        """Retorna o valor cached ou ``None``."""
        if not self.enabled:
            return None
        now = time.time()
        try:
            with self._lock, self._connect() as conn:
                row = conn.execute(
                    "SELECT value, expires_at FROM cache WHERE key = ?", (key,)
                ).fetchone()
                if row is None:
                    return None
                value, expires_at = row
                if expires_at < now:
                    conn.execute("DELETE FROM cache WHERE key = ?", (key,))
                    return None
                conn.execute(
                    "UPDATE cache SET last_access = ? WHERE key = ?", (now, key)
                )
            return json.loads(value)
        except (sqlite3.Error, json.JSONDecodeError):
            log.exception("Falha ao ler cache para %s", key)
            return None

    def set(self, key: str, value: Any) -> None:
        """Armazena um valor com TTL configurado."""
        if not self.enabled:
            return
        now = time.time()
        try:
            payload = json.dumps(value, default=str)
            with self._lock, self._connect() as conn:
                conn.execute(
                    """
                    INSERT INTO cache (key, value, created_at, expires_at, last_access)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT(key) DO UPDATE SET
                        value = excluded.value,
                        expires_at = excluded.expires_at,
                        last_access = excluded.last_access
                    """,
                    (key, payload, now, now + self.ttl, now),
                )
                self._trim(conn)
        except sqlite3.Error:
            log.exception("Falha ao gravar cache para %s", key)

    def _trim(self, conn: sqlite3.Connection) -> None:
        try:
            count = conn.execute("SELECT COUNT(*) FROM cache").fetchone()[0]
            if count > self.max_size:
                conn.execute(
                    "DELETE FROM cache WHERE key IN ("
                    " SELECT key FROM cache ORDER BY last_access ASC LIMIT ?"
                    ")",
                    (count - self.max_size,),
                )
        except sqlite3.Error:
            log.exception("Falha ao podar cache")

    def delete(self, key: str) -> None:
        if not self.enabled:
            return
        try:
            with self._lock, self._connect() as conn:
                conn.execute("DELETE FROM cache WHERE key = ?", (key,))
        except sqlite3.Error:
            log.exception("Falha ao deletar cache %s", key)

    def clear(self) -> None:
        if not self.enabled:
            return
        try:
            with self._lock, self._connect() as conn:
                conn.execute("DELETE FROM cache")
        except sqlite3.Error:
            log.exception("Falha ao limpar cache")

    def size(self) -> int:
        if not self.enabled:
            return 0
        try:
            with self._lock, self._connect() as conn:
                return int(conn.execute("SELECT COUNT(*) FROM cache").fetchone()[0])
        except sqlite3.Error:
            return 0
