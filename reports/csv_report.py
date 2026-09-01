"""Relatório CSV."""

from __future__ import annotations

from typing import Any

from reports.base import ReportGenerator, csv_dumps


class CsvReport(ReportGenerator):
    """Exporta os resultados do scan em CSV (uma linha por resultado)."""

    format_name = "csv"

    def render_text(self, scan: dict[str, Any]) -> str:
        rows: list[dict[str, Any]] = []
        for result in scan.get("results", []):
            rows.append(
                {
                    "scan_id": scan.get("scan_id"),
                    "target": scan.get("target"),
                    "target_type": scan.get("target_type"),
                    "plugin": result.get("plugin"),
                    "result_type": result.get("result_type"),
                    "data": result.get("data"),
                    "source": result.get("source"),
                    "confidence": result.get("confidence"),
                    "status": result.get("status"),
                    "duration": result.get("duration"),
                }
            )
        return csv_dumps(rows)
