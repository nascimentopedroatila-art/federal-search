"""Relatório JSON."""

from __future__ import annotations

from typing import Any

from reports.base import ReportGenerator, json_dumps


class JsonReport(ReportGenerator):
    """Exporta o scan completo em JSON estruturado."""

    format_name = "json"

    def render_text(self, scan: dict[str, Any]) -> str:
        payload = {
            "nexus_version": "1.0.0",
            "report_format": "json",
            "scan": scan,
        }
        return json_dumps(payload)
