"""Base para geradores de relatório."""

from __future__ import annotations

import csv
import io
import json
from abc import ABC, abstractmethod
from datetime import datetime
from pathlib import Path
from typing import Any

from core.constants import REPORTS_DIR
from core.errors import ReportError

DEFAULT_OUTPUT_DIR = REPORTS_DIR / "out"


def _safe_filename(value: str) -> str:
    keep = "".join(c if (c.isalnum() or c in "._-") else "_" for c in value)
    return keep.strip("._") or "scan"


def _timestamp() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S")


class ReportRenderError(ReportError):
    """Erro de renderização de relatório."""


class ReportGenerator(ABC):
    """Interface comum dos relatórios."""

    format_name = "base"

    def __init__(self, output_dir: Path | str | None = None) -> None:
        self.output_dir = Path(output_dir) if output_dir else DEFAULT_OUTPUT_DIR
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def render(self, scan: dict[str, Any], output_path: Path | str | None = None) -> Path:
        """Gera o relatório e retorna o caminho do arquivo."""
        content = self.render_text(scan)
        if output_path is None:
            output_path = self.output_dir / _default_filename(scan, self.format_name)
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(content, encoding="utf-8")
        return output_path

    @abstractmethod
    def render_text(self, scan: dict[str, Any]) -> str:
        """Renderiza o relatório como string."""


def _default_filename(scan: dict[str, Any], fmt: str) -> str:
    target = _safe_filename(str(scan.get("target", "scan")))
    scan_id = str(scan.get("scan_id", "unknown"))[:8]
    return f"nexus_{target}_{scan_id}_{_timestamp()}.{fmt}"


# --------------------------------------------------------------------------
# Helpers de serialização
# --------------------------------------------------------------------------
def json_dumps(data: Any) -> str:
    return json.dumps(data, indent=2, ensure_ascii=False, default=str)


def csv_dumps(rows: list[dict[str, Any]]) -> str:
    if not rows:
        return ""
    buffer = io.StringIO()
    writer = csv.DictWriter(buffer, fieldnames=list(rows[0].keys()))
    writer.writeheader()
    for row in rows:
        writer.writerow({k: _csv_cell(v) for k, v in row.items()})
    return buffer.getvalue()


def _csv_cell(value: Any) -> str:
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, default=str)
    return "" if value is None else str(value)
