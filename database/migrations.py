"""Migrações do banco SQLite do NEXUS.

V1: tabelas ``scans`` e ``scan_results`` + índices básicos.
Migrações futuras devem incrementar ``SCHEMA_VERSION`` e adicionar
passos idempotentes em ``_MIGRATIONS``.
"""

from __future__ import annotations

import sqlite3
from pathlib import Path

from core.constants import DATABASE_PATH
from core.logger import get_logger

from database.models import RESULTS_TABLE, SCANS_TABLE, SCHEMA_VERSION

log = get_logger("db")

_MIGRATIONS: list[tuple[int, list[str]]] = [
    (
        1,
        [
            SCANS_TABLE,
            RESULTS_TABLE,
            "CREATE INDEX IF NOT EXISTS idx_results_scan ON scan_results(scan_id)",
            "CREATE INDEX IF NOT EXISTS idx_results_type ON scan_results(result_type)",
            "CREATE INDEX IF NOT EXISTS idx_scans_target ON scans(target)",
        ],
    ),
]


def run_migrations(path: Path | str | None = None, version: int = SCHEMA_VERSION) -> int:
    """Aplica as migrações pendentes e retorna a versão final do schema."""
    db_path = Path(path) if path else DATABASE_PATH
    db_path.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(str(db_path), timeout=10) as conn:
        conn.execute("PRAGMA journal_mode=WAL;")
        conn.execute(
            "CREATE TABLE IF NOT EXISTS schema_version (version INTEGER NOT NULL)"
        )
        row = conn.execute("SELECT version FROM schema_version ORDER BY version DESC LIMIT 1").fetchone()
        current = int(row[0]) if row else 0

        for target_version, statements in _MIGRATIONS:
            if target_version <= current:
                continue
            for statement in statements:
                conn.execute(statement)
            conn.execute(
                "INSERT INTO schema_version (version) VALUES (?)", (target_version,)
            )
            log.info("Migração %d aplicada.", target_version)

    return version
