"""Relatório HTML autossuficiente (CSS inline, sem dependências externas)."""

from __future__ import annotations

import html
from datetime import datetime, timezone
from typing import Any

from reports.base import ReportGenerator

_PAGE_CSS = """
:root { --bg:#0f172a; --panel:#1e293b; --border:#334155; --text:#e2e8f0;
        --muted:#94a3b8; --accent:#38bdf8; --good:#4ade80; --warn:#fbbf24;
        --bad:#f87171; }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--text);
       font-family:'Segoe UI', system-ui, sans-serif; }
header { background:linear-gradient(135deg,#0ea5e9,#6366f1); padding:28px 32px; }
header h1 { margin:0; font-size:26px; letter-spacing:3px; }
header p { margin:4px 0 0; opacity:.85; font-size:14px; }
main { max-width:1100px; margin:24px auto; padding:0 20px; }
.grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr));
        gap:14px; margin:18px 0; }
.card { background:var(--panel); border:1px solid var(--border);
        border-radius:10px; padding:16px; }
.card h3 { margin:0 0 8px; font-size:12px; text-transform:uppercase;
           letter-spacing:1px; color:var(--muted); }
.card .value { font-size:18px; font-weight:600; word-break:break-all; }
.section { background:var(--panel); border:1px solid var(--border);
           border-radius:10px; padding:18px; margin:18px 0; }
.section h2 { margin:0 0 14px; font-size:16px; border-bottom:1px solid var(--border);
              padding-bottom:10px; }
table { width:100%; border-collapse:collapse; font-size:14px; }
th, td { text-align:left; padding:8px 10px; border-bottom:1px solid var(--border);
         vertical-align:top; word-break:break-word; }
th { color:var(--muted); font-size:12px; text-transform:uppercase; letter-spacing:.5px; }
.badge { display:inline-block; padding:2px 10px; border-radius:999px;
         font-size:12px; font-weight:600; }
.ok { background:rgba(74,222,128,.15); color:var(--good); }
.warn { background:rgba(251,191,36,.15); color:var(--warn); }
.err { background:rgba(248,113,113,.15); color:var(--bad); }
.info { background:rgba(56,189,248,.15); color:var(--accent); }
.conf-low { color:var(--warn); } .conf-medium { color:var(--accent); }
.conf-high { color:var(--good); } .conf-confirmed { color:#c084fc; }
.src { font-size:12px; color:var(--muted); }
footer { text-align:center; color:var(--muted); font-size:12px;
         padding:24px 0 40px; }
.bar { height:10px; border-radius:5px; background:var(--border); overflow:hidden;
       margin-top:6px; }
.bar > span { display:block; height:100%; background:var(--accent); }
"""

_BADGE_BY_STATUS = {
    "SUCCESS": "ok",
    "NO_RESULTS": "info",
    "SKIPPED": "info",
    "NOT_CONFIGURED": "warn",
    "RATE_LIMITED": "warn",
    "TIMEOUT": "err",
    "ERROR": "err",
}

_CONFIDENCE_CLASS = {
    "LOW": "conf-low",
    "MEDIUM": "conf-medium",
    "HIGH": "conf-high",
    "CONFIRMED": "conf-confirmed",
}


class HtmlReport(ReportGenerator):
    """Exporta o scan em HTML visualmente organizado."""

    format_name = "html"

    def render_text(self, scan: dict[str, Any]) -> str:
        scan_time = _format_time(scan.get("started_at"))
        plugin_status = scan.get("plugins") or scan.get("plugin_status") or {}
        results = scan.get("results", [])
        errors = scan.get("errors", [])
        summary = scan.get("summary") or _build_summary(results)

        sections = [
            _header(scan, scan_time),
            _overview_cards(scan, plugin_status, scan_time),
            _plugins_section(plugin_status),
            _results_section(results),
            _sources_section(results),
            _confidence_section(results),
            _errors_section(errors),
            _statistics_section(summary, plugin_status),
            _timeline_section(scan),
            _footer(),
        ]
        return (
            "<!DOCTYPE html>\n<html lang='pt-BR'><head><meta charset='utf-8'>"
            "<meta name='viewport' content='width=device-width, initial-scale=1'>"
            f"<title>NEXUS Report - {html.escape(str(scan.get('target', '')))}</title>"
            f"<style>{_PAGE_CSS}</style></head><body>"
            + "\n".join(sections)
            + "</body></html>"
        )


def _header(scan: dict[str, Any], scan_time: str) -> str:
    target = html.escape(str(scan.get("target", "")))
    return (
        "<header><h1>NEXUS</h1>"
        "<p>Modular Intelligence Toolkit &mdash; Relatório de scan</p></header>"
        "<main>"
        f"<div class='card'><h3>Target</h3><div class='value'>{target}</div>"
        f"<p class='src'>Scan ID: {html.escape(str(scan.get('scan_id', '')))} &middot; "
        f"Gerado: {scan_time}</p></div>"
    )


def _overview_cards(scan: dict[str, Any], plugin_status: dict, scan_time: str) -> str:
    status = str(scan.get("status", "NO_RESULTS"))
    badge = _BADGE_BY_STATUS.get(status, "info")
    cards = [
        ("Target Type", str(scan.get("target_type", "-"))),
        ("Scan Time", scan_time),
        ("Duration", f"{scan.get('duration', 0)}s"),
        ("Plugins", str(len(plugin_status))),
        ("Results", str(len(scan.get("results", [])))),
        ("Errors", str(len(scan.get("errors", [])))),
    ]
    body = "".join(f"<div class='card'><h3>{k}</h3><div class='value'>{html.escape(v)}</div></div>" for k, v in cards)
    return (
        f"<div class='grid'>{body}</div>"
        f"<div class='card'><h3>Status</h3>"
        f"<span class='badge {badge}'>{html.escape(status)}</span></div>"
    )


def _plugins_section(plugin_status: dict) -> str:
    if not plugin_status:
        return "<div class='section'><h2>Plugins</h2><p class='src'>Nenhum plugin executado.</p></div>"
    rows = []
    for name, status in sorted(plugin_status.items()):
        badge = _BADGE_BY_STATUS.get(str(status).upper(), "info")
        rows.append(
            f"<tr><td>{html.escape(name)}</td>"
            f"<td><span class='badge {badge}'>{html.escape(str(status))}</span></td></tr>"
        )
    return "<div class='section'><h2>Plugins</h2><table><tr><th>Plugin</th><th>Status</th></tr>" + "".join(rows) + "</table></div>"


def _results_section(results: list[dict[str, Any]]) -> str:
    if not results:
        return "<div class='section'><h2>Results</h2><p class='src'>NO RESULTS</p></div>"
    rows = []
    for i, result in enumerate(results, 1):
        data = result.get("data")
        data_cell = _render_data(data)
        sources = result.get("source")
        if isinstance(sources, list):
            sources = ", ".join(str(s) for s in sources)
        rows.append(
            f"<tr><td>{i}</td>"
            f"<td>{html.escape(str(result.get('plugin', '')))}</td>"
            f"<td>{html.escape(str(result.get('result_type', ''))).upper()}</td>"
            f"<td>{data_cell}</td>"
            f"<td>{html.escape(str(sources or ''))}</td>"
            f"<td>{html.escape(str(result.get('confidence', 'LOW'))).upper()}</td></tr>"
        )
    return (
        "<div class='section'><h2>Results</h2><table>"
        "<tr><th>#</th><th>Plugin</th><th>Type</th><th>Data</th><th>Source</th><th>Confidence</th></tr>"
        + "".join(rows) + "</table></div>"
    )


def _render_data(data: Any) -> str:
    if isinstance(data, dict):
        items = []
        for key, value in data.items():
            if isinstance(value, (dict, list)):
                import json

                value = json.dumps(value, ensure_ascii=False, default=str)
            items.append(f"<b>{html.escape(str(key))}:</b> {html.escape(str(value))}")
        return "<br>".join(items)
    return html.escape(str(data))


def _sources_section(results: list[dict[str, Any]]) -> str:
    counts: dict[str, int] = {}
    for result in results:
        sources = result.get("source")
        if isinstance(sources, str):
            sources = [sources]
        for source in sources or []:
            counts[str(source)] = counts.get(str(source), 0) + 1
    if not counts:
        return ""
    rows = "".join(
        f"<tr><td>{html.escape(source)}</td><td>{count}</td></tr>"
        for source, count in sorted(counts.items(), key=lambda kv: -kv[1])
    )
    return "<div class='section'><h2>Sources</h2><table><tr><th>Source</th><th>Results</th></tr>" + rows + "</table></div>"


def _confidence_section(results: list[dict[str, Any]]) -> str:
    if not results:
        return ""
    counts: dict[str, int] = {"LOW": 0, "MEDIUM": 0, "HIGH": 0, "CONFIRMED": 0}
    for result in results:
        key = str(result.get("confidence", "LOW")).upper()
        counts[key] = counts.get(key, 0) + 1
    total = sum(counts.values()) or 1
    rows = []
    for level in ("LOW", "MEDIUM", "HIGH", "CONFIRMED"):
        count = counts.get(level, 0)
        pct = round(count * 100 / total)
        rows.append(
            f"<tr><td class='{_CONFIDENCE_CLASS[level]}'><b>{level}</b></td>"
            f"<td>{count}</td><td style='width:40%'><div class='bar'>"
            f"<span style='width:{pct}%'></span></div></td></tr>"
        )
    return "<div class='section'><h2>Confidence</h2><table><tr><th>Level</th><th>Results</th><th>Distribution</th></tr>" + "".join(rows) + "</table></div>"


def _errors_section(errors: list[dict[str, Any]]) -> str:
    if not errors:
        return "<div class='section'><h2>Errors</h2><p class='src'>Nenhum erro registrado.</p></div>"
    rows = "".join(
        f"<tr><td>{html.escape(str(e.get('plugin', '')))}</td>"
        f"<td>{html.escape(str(e.get('message', '')))}</td></tr>"
        for e in errors
    )
    return "<div class='section'><h2>Errors</h2><table><tr><th>Plugin</th><th>Message</th></tr>" + rows + "</table></div>"


def _statistics_section(summary: dict, plugin_status: dict) -> str:
    by_type = summary.get("by_type", {})
    rows = []
    for result_type, count in sorted(by_type.items()):
        rows.append(f"<tr><td>{html.escape(str(result_type))}</td><td>{count}</td></tr>")
    if not rows:
        rows = ["<tr><td colspan='2' class='src'>Sem dados.</td></tr>"]
    table = "<table><tr><th>Result type</th><th>Count</th></tr>" + "".join(rows) + "</table>"
    return "<div class='section'><h2>Statistics</h2>" + table + "</div>"


def _timeline_section(scan: dict[str, Any]) -> str:
    started = _format_time(scan.get("started_at"))
    finished = _format_time(scan.get("finished_at"))
    duration = f"{scan.get('duration', 0)}s"
    rows = [
        ("Início", started),
        ("Término", finished),
        ("Duração", duration),
        ("Registro no banco", "sim" if scan.get("scan_id") else "não"),
    ]
    body = "".join(
        f"<tr><td>{html.escape(label)}</td><td>{html.escape(value)}</td></tr>"
        for label, value in rows
    )
    return "<div class='section'><h2>Timeline</h2><table>" + body + "</table></div>"


def _footer() -> str:
    return (
        "</main><footer>Gerado por NEXUS - Modular Intelligence Toolkit v2.0.0 "
        "&middot; Use somente para fins legítimos e autorizados.</footer>"
    )


def _build_summary(results: list[dict[str, Any]]) -> dict[str, Any]:
    by_type: dict[str, int] = {}
    for result in results:
        key = str(result.get("result_type", "info"))
        by_type[key] = by_type.get(key, 0) + 1
    return {"by_type": by_type}


def _format_time(value: Any) -> str:
    try:
        ts = float(value)
        return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    except (TypeError, ValueError):
        return str(value or "-")
