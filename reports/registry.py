"""Registro de geradores de relatório por formato."""

from __future__ import annotations

from typing import Type

from reports.base import ReportGenerator
from reports.csv_report import CsvReport
from reports.html_report import HtmlReport
from reports.json_report import JsonReport
from reports.txt_report import TxtReport

GENERATORS: dict[str, Type[ReportGenerator]] = {
    "json": JsonReport,
    "csv": CsvReport,
    "html": HtmlReport,
    "txt": TxtReport,
}

SUPPORTED_FORMATS = sorted(GENERATORS.keys())


def get_generator(format_name: str, output_dir=None) -> ReportGenerator:
    """Retorna o gerador para o formato informado."""
    key = format_name.strip().lower()
    if key not in GENERATORS:
        raise ValueError(
            f"Formato desconhecido: '{format_name}'. Válidos: {', '.join(SUPPORTED_FORMATS)}"
        )
    return GENERATORS[key](output_dir=output_dir)
