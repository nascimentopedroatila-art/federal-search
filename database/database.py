"""Acesso a dados do NEXUS (SQLite, stdlib, sem ORM pesado).

Registra: scan_id, target, target_type, plugin, timestamp,
result_type, result, source, confidence, status, error, duration.
"""

from __future__ import annotations

import json
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable

from core.constants import DATABASE_PATH, Status
from core.deduplicator import summarize
from core.logger import get_logger

from database.migrations import run_migrations

log = get_logger("db")


def _now() -> str:
    return datetime.now().isoformat(timespec="seconds")


class Database:
    """Persistência SQLite do NEXUS."""

    def __init__(self, path: Path | str | None = None) -> None:
        self.path = Path(path) if path else DATABASE_PATH
        run_migrations(self.path)

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.path), timeout=10)
        conn.row_factory = sqlite3.Row
        return conn

    # ------------------------------------------------------------------ #
    # Scans
    # ------------------------------------------------------------------ #
    def save_scan(
        self,
        scan_id: str,
        target: str,
        target_type: str,
        started_at: float,
        finished_at: float,
        plugin_status: dict[str, str],
        results: Iterable[dict[str, Any]],
        errors: list[dict[str, str]],
    ) -> None:
        """Persiste um scan completo (cabeçalho + resultados)."""
        results = list(results)
        summary = summarize(results)
        duration = round(max(finished_at - started_at, 0.0), 3)

        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO scans
                    (scan_id, target, target_type, started_at, finished_at,
                     duration, plugin_status, error_count, result_count, summary)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    scan_id,
                    target,
                    target_type,
                    started_at,
                    finished_at,
                    duration,
                    json.dumps(plugin_status, ensure_ascii=False),
                    len(errors),
                    len(results),
                    json.dumps(summary, ensure_ascii=False),
                ),
            )
            for result in results:
                conn.execute(
                    """
                    INSERT INTO scan_results
                        (scan_id, plugin, result_type, data, source,
                         confidence, status, error, duration)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        scan_id,
                        str(result.get("plugin", "unknown")),
                        str(result.get("result_type", "info")),
                        json.dumps(result.get("data", {}), ensure_ascii=False, default=str),
                        json.dumps(result.get("source"), ensure_ascii=False),
                        str(result.get("confidence", "LOW")),
                        str(result.get("status", Status.SUCCESS.value)),
                        None,
                        float(result.get("duration", 0.0)),
                    ),
                )
        log.info("Scan %s salvo (%d resultados).", scan_id, len(results))

    def history(self, limit: int = 50) -> list[dict[str, Any]]:
        """Histórico recente de scans."""
        with self._connect() as conn:
            rows = conn.execute(
                "SELECT * FROM scans ORDER BY id DESC LIMIT ?", (int(limit),)
            ).fetchall()
        return [self._row_to_dict(row) for row in rows]

    def get_scan(self, scan_id: str) -> dict[str, Any] | None:
        """Retorna um scan pelo ID (ou início do ID)."""
        with self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM scans WHERE scan_id = ? OR scan_id LIKE ? ORDER BY id DESC LIMIT 1",
                (scan_id, f"{scan_id}%"),
            ).fetchone()
            if row is None:
                return None
            scan = self._row_to_dict(row)
            result_rows = conn.execute(
                "SELECT * FROM scan_results WHERE scan_id = ? ORDER BY id", (scan["scan_id"],)
            ).fetchall()
        scan["results"] = [self._result_row_to_dict(r) for r in result_rows]
        return scan

    def delete_scan(self, scan_id: str) -> bool:
        """Remove um scan e seus resultados."""
        with self._connect() as conn:
            cur = conn.execute("DELETE FROM scans WHERE scan_id = ?", (scan_id,))
            conn.execute("DELETE FROM scan_results WHERE scan_id = ?", (scan_id,))
        return cur.rowcount > 0

    def stats(self) -> dict[str, Any]:
        """Estatísticas globais do banco."""
        with self._connect() as conn:
            scans = conn.execute("SELECT COUNT(*) FROM scans").fetchone()[0]
            results = conn.execute("SELECT COUNT(*) FROM scan_results").fetchone()[0]
            by_type = dict(
                conn.execute(
                    "SELECT result_type, COUNT(*) FROM scan_results GROUP BY result_type"
                ).fetchall()
            )
            by_status = dict(
                conn.execute(
                    "SELECT status, COUNT(*) FROM scan_results GROUP BY status"
                ).fetchall()
            )
        return {
            "scans": scans,
            "results": results,
            "by_result_type": by_type,
            "by_status": by_status,
            "updated_at": _now(),
        }

    # ------------------------------------------------------------------ #
    @staticmethod
    def _row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
        data = dict(row)
        for field in ("plugin_status", "summary"):
            if field in data and data[field]:
                try:
                    data[field] = json.loads(data[field])
                except json.JSONDecodeError:
                    data[field] = {}
        return data

    @staticmethod
    def _result_row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
        data = dict(row)
        for field in ("data", "source"):
            if data.get(field):
                try:
                    data[field] = json.loads(data[field])
                except json.JSONDecodeError:
                    pass
        return data
