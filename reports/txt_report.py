"""Relatório TXT (legível no terminal)."""

from __future__ import annotations

from typing import Any

from reports.base import ReportGenerator


class TxtReport(ReportGenerator):
    """Exporta o scan em texto plano formatado."""

    format_name = "txt"

    def render_text(self, scan: dict[str, Any]) -> str:
        lines: list[str] = []
        lines.append("=" * 64)
        lines.append("  NEXUS - Modular Intelligence Toolkit")
        lines.append("  Relatório de scan")
        lines.append("=" * 64)
        lines.append("")
        lines.append(f"Scan ID       : {scan.get('scan_id')}")
        lines.append(f"Target        : {scan.get('target')}")
        lines.append(f"Target Type   : {scan.get('target_type')}")
        lines.append(f"Duração       : {scan.get('duration')}s")
        lines.append(f"Status        : {scan.get('status', 'NO_RESULTS')}")
        lines.append("")

        plugin_status = scan.get("plugins") or scan.get("plugin_status") or {}
        if plugin_status:
            lines.append("--- Plugins ---")
            for name, status in plugin_status.items():
                lines.append(f"  {name:<32} {status}")
            lines.append("")

        results = scan.get("results", [])
        if results:
            lines.append(f"--- Resultados ({len(results)}) ---")
            for i, result in enumerate(results, 1):
                lines.append(f"  [{i}] {result.get('result_type', 'info').upper()}")
                lines.append(f"      plugin    : {result.get('plugin')}")
                lines.append(f"      source    : {result.get('source')}")
                lines.append(f"      confidence: {result.get('confidence')}")
                data = result.get("data")
                if isinstance(data, dict):
                    for key, value in data.items():
                        lines.append(f"      {key:<12}: {_fmt(value)}")
                else:
                    lines.append(f"      value     : {_fmt(data)}")
                lines.append("")
        else:
            lines.append("NO RESULTS")
            lines.append("")

        errors = scan.get("errors", [])
        if errors:
            lines.append(f"--- Erros ({len(errors)}) ---")
            for error in errors:
                lines.append(f"  {error.get('plugin')}: {error.get('message')}")
            lines.append("")

        lines.append("=" * 64)
        lines.append("  Gerado por NEXUS - Modular Intelligence Toolkit")
        lines.append("=" * 64)
        return "\n".join(lines)


def _fmt(value: Any) -> str:
    if isinstance(value, (dict, list)):
        import json

        return json.dumps(value, ensure_ascii=False, default=str)
    return str(value)
