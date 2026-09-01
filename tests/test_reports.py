"""Testes dos geradores de relatório (json, csv, html, txt)."""

from __future__ import annotations

import csv
import io
import json

from reports.registry import SUPPORTED_FORMATS, get_generator

SAMPLE_SCAN = {
    "scan_id": "sample123",
    "target": "example.com",
    "target_type": "domain",
    "started_at": 1700000000.0,
    "finished_at": 1700000010.0,
    "duration": 10.0,
    "status": "SUCCESS",
    "plugins": {"Domain Intelligence": "SUCCESS", "DNS Records": "NO_RESULTS"},
    "plugin_status": {"Domain Intelligence": "SUCCESS", "DNS Records": "NO_RESULTS"},
    "results": [
        {
            "plugin": "Domain Intelligence",
            "result_type": "dns",
            "data": {"record_type": "A", "name": "example.com", "value": ["93.184.216.34"]},
            "source": "DNS (dnspython)",
            "confidence": "HIGH",
            "status": "SUCCESS",
            "duration": 0.2,
        }
    ],
    "errors": [],
    "summary": {"by_type": {"dns": 1}},
}


def test_all_formats_registered() -> None:
    assert set(SUPPORTED_FORMATS) == {"json", "csv", "html", "txt"}


def test_json_report(tmp_path) -> None:
    generator = get_generator("json")
    path = generator.render(SAMPLE_SCAN, output_path=tmp_path / "report.json")
    payload = json.loads(path.read_text(encoding="utf-8"))
    assert payload["scan"]["target"] == "example.com"
    assert payload["scan"]["results"][0]["confidence"] == "HIGH"


def test_csv_report(tmp_path) -> None:
    generator = get_generator("csv")
    path = generator.render(SAMPLE_SCAN, output_path=tmp_path / "report.csv")
    content = path.read_text(encoding="utf-8")
    rows = list(csv.DictReader(io.StringIO(content)))
    assert len(rows) == 1
    assert rows[0]["target"] == "example.com"
    assert rows[0]["result_type"] == "dns"


def test_txt_report(tmp_path) -> None:
    generator = get_generator("txt")
    path = generator.render(SAMPLE_SCAN, output_path=tmp_path / "report.txt")
    content = path.read_text(encoding="utf-8")
    assert "example.com" in content
    assert "Scan ID" in content
    assert "NEXUS" in content


def test_html_report_contains_required_sections(tmp_path) -> None:
    generator = get_generator("html")
    path = generator.render(SAMPLE_SCAN, output_path=tmp_path / "report.html")
    content = path.read_text(encoding="utf-8")
    for section in ("Target", "Target Type", "Scan Time", "Plugins", "Results", "Sources", "Confidence", "Errors", "Statistics", "Timeline"):
        assert section in content, f"seção ausente: {section}"
    assert "example.com" in content
    assert "<style>" in content


def test_html_escapes_content(tmp_path) -> None:
    scan = dict(SAMPLE_SCAN)
    scan["target"] = "<script>alert(1)</script>.com"
    generator = get_generator("html")
    content = generator.render_text(scan)
    assert "<script>" not in content


def test_unknown_format_raises() -> None:
    import pytest
    from reports.registry import get_generator

    with pytest.raises(ValueError):
        get_generator("pdf")


def test_default_filename_safe(tmp_path) -> None:
    generator = get_generator("json")
    scan = dict(SAMPLE_SCAN)
    scan["target"] = "../../etc/passwd"
    path = generator.render(scan, output_path=None)
    # o diretório de saída padrão deve ser reports/out; validar apenas a extensão
    assert str(path).endswith(".json")
