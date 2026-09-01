"""Renderização de saída no terminal (tabelas, banners, cores)."""

from __future__ import annotations

import json
import sys
from typing import Any, Iterable

_COLORS = {
    "reset": "\033[0m",
    "bold": "\033[1m",
    "cyan": "\033[96m",
    "blue": "\033[94m",
    "green": "\033[92m",
    "yellow": "\033[93m",
    "red": "\033[91m",
    "magenta": "\033[95m",
    "dim": "\033[2m",
}

_ENABLED = sys.stdout.isatty() and sys.platform != "win32" or sys.stdout.isatty()


def colorize(text: str, color: str = "reset") -> str:
    """Aplica cor ANSI se o terminal suportar."""
    if not _ENABLED or color not in _COLORS:
        return text
    return f"{_COLORS[color]}{text}{_COLORS['reset']}"


def banner() -> str:
    """Banner ASCII do NEXUS."""
    lines = [
        "╔══════════════════════════════════════════╗",
        "║              N E X U S                   ║",
        "║       Modular Intelligence Toolkit       ║",
        "╚══════════════════════════════════════════╝",
    ]
    return "\n".join(colorize(line, "cyan") for line in lines)


def render_table(headers: list[str], rows: Iterable[Iterable[Any]], max_width: int = 60) -> str:
    """Renderiza uma tabela simples em texto puro (sem curses)."""
    rows = [list(r) for r in rows]
    widths: list[int] = []
    all_rows = [headers] + rows
    for col in range(len(headers)):
        cells = [_shorten(str(r[col]) if col < len(r) else "", max_width) for r in all_rows]
        widths.append(max(len(c) for c in cells))

    def fmt_row(row: list[Any]) -> str:
        return "  ".join(
            _shorten(str(cell), max_width).ljust(widths[i]) if i < len(row) else " " * widths[i]
            for i, cell in enumerate(row)
        )

    separator = "  ".join("─" * w for w in widths)
    out = [fmt_row(headers), separator]
    out.extend(fmt_row(r) for r in rows)
    return "\n".join(out)


def _shorten(value: str, max_width: int) -> str:
    if len(value) <= max_width:
        return value
    return value[: max_width - 3] + "..."


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, ensure_ascii=False, default=str))


def status_color(status: str) -> str:
    palette = {
        "SUCCESS": "green",
        "CONFIRMED": "green",
        "HIGH": "green",
        "NO_RESULTS": "dim",
        "SKIPPED": "dim",
        "NOT_CONFIGURED": "yellow",
        "RATE_LIMITED": "yellow",
        "TIMEOUT": "red",
        "ERROR": "red",
        "MEDIUM": "cyan",
        "LOW": "yellow",
        "ENABLED": "green",
        "NOT CONFIGURED": "yellow",
        "DISABLED": "red",
    }
    return palette.get(status.upper(), "reset")
