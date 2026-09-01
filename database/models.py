"""Modelos de dados do banco (definições de tabelas)."""

from __future__ import annotations

SCHEMA_VERSION = 1

SCANS_TABLE = """
CREATE TABLE IF NOT EXISTS scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scan_id TEXT UNIQUE NOT NULL,
    target TEXT NOT NULL,
    target_type TEXT NOT NULL,
    started_at REAL NOT NULL,
    finished_at REAL NOT NULL,
    duration REAL NOT NULL DEFAULT 0,
    plugin_status TEXT NOT NULL DEFAULT '{}',
    error_count INTEGER NOT NULL DEFAULT 0,
    result_count INTEGER NOT NULL DEFAULT 0,
    summary TEXT NOT NULL DEFAULT '{}',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
)
"""

RESULTS_TABLE = """
CREATE TABLE IF NOT EXISTS scan_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scan_id TEXT NOT NULL,
    plugin TEXT NOT NULL,
    result_type TEXT NOT NULL,
    data TEXT NOT NULL,
    source TEXT NOT NULL,
    confidence TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'SUCCESS',
    error TEXT,
    duration REAL NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
)
"""


class ScanModel:
    """Estrutura de um registro de scan (conveniência tipada)."""

    __slots__ = (
        "scan_id",
        "target",
        "target_type",
        "started_at",
        "finished_at",
        "duration",
        "plugin_status",
        "error_count",
        "result_count",
        "summary",
    )

    def __init__(
        self,
        scan_id: str,
        target: str,
        target_type: str,
        started_at: float,
        finished_at: float,
        duration: float,
        plugin_status: dict,
        error_count: int,
        result_count: int,
        summary: dict,
    ) -> None:
        self.scan_id = scan_id
        self.target = target
        self.target_type = target_type
        self.started_at = started_at
        self.finished_at = finished_at
        self.duration = duration
        self.plugin_status = plugin_status
        self.error_count = error_count
        self.result_count = result_count
        self.summary = summary

    def to_dict(self) -> dict:
        return {
            "scan_id": self.scan_id,
            "target": self.target,
            "target_type": self.target_type,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "duration": self.duration,
            "plugin_status": self.plugin_status,
            "error_count": self.error_count,
            "result_count": self.result_count,
            "summary": self.summary,
        }
