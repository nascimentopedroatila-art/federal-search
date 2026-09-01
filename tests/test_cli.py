"""Testes de integração da CLI."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))


def run_cli(argv: list[str]) -> int:
    from cli.main import main

    return main(argv)


def test_version() -> None:
    with pytest.raises(SystemExit) as exc:
        run_cli(["--version"])
    assert exc.value.code == 0


def test_help() -> None:
    with pytest.raises(SystemExit) as exc:
        run_cli(["--help"])
    assert exc.value.code == 0


def test_scan_phone_offline(capsys) -> None:
    """Scan de telefone funciona 100% offline e não grava no banco (--no-db)."""
    code = run_cli(["scan", "--target", "+5585999999999", "--no-db"])
    output = capsys.readouterr().out
    assert code == 0
    assert "Scan ID" in output
    assert "+5585999999999" in output
    assert "Phone Validator" in output


def test_scan_forced_type() -> None:
    code = run_cli(["scan", "--target", "example_username", "--type", "username", "--no-db"])
    assert code == 0


def test_scan_unknown_target_fails_gracefully() -> None:
    code = run_cli(["scan", "--target", "!!!", "--no-db"])
    assert code == 1


def test_scan_json_output(capsys) -> None:
    import json

    code = run_cli(["scan", "--target", "+5585999999999", "--json", "--no-db"])
    output = capsys.readouterr().out
    assert code == 0
    payload = json.loads(output)
    assert payload["target_type"] == "phone"
    assert payload["scan_id"]


def test_plugins_listing(capsys) -> None:
    code = run_cli(["plugins"])
    output = capsys.readouterr().out
    assert code == 0
    assert "Phone Validator" in output
    assert "API Key" in output


def test_apis_listing(capsys) -> None:
    code = run_cli(["apis"])
    output = capsys.readouterr().out
    assert code == 0
    assert "NEXUS API MANAGER" in output
    assert "AbuseIPDB" in output


def test_history_empty(capsys) -> None:
    code = run_cli(["history", "--limit", "5"])
    output = capsys.readouterr().out
    assert code == 0
    assert "Histórico" in output


def test_selfcheck(capsys) -> None:
    code = run_cli(["selfcheck"])
    output = capsys.readouterr().out
    assert code == 0
    assert "NEXUS Self-Check" in output


def test_config_show(capsys) -> None:
    code = run_cli(["config", "--show"])
    output = capsys.readouterr().out
    assert code == 0
    assert "performance_preset" in output


def test_keys_list_safe(capsys) -> None:
    code = run_cli(["keys", "list"])
    output = capsys.readouterr().out
    assert code == 0
    assert "ABUSEIPDB_API_KEY" in output


def test_export_flow(tmp_path, capsys) -> None:
    """Scan -> banco -> export json/txt/html/csv."""
    code = run_cli(["scan", "--target", "+5585999999999"])
    assert code == 0
    capsys.readouterr()  # limpa

    from database.database import Database

    db = Database(path=ROOT / "data" / "nexus.db")
    history = db.history(limit=1)
    assert history
    scan_id = history[0]["scan_id"]

    for fmt in ("json", "csv", "txt", "html"):
        code = run_cli(["export", "--scan", scan_id, "--format", fmt, "--output", str(tmp_path / f"out.{fmt}")])
        assert code == 0, f"export {fmt} falhou"
        assert (tmp_path / f"out.{fmt}").exists()

    # limpa para não poluir a próxima execução
    db.delete_scan(scan_id)


def test_export_unknown_scan() -> None:
    code = run_cli(["export", "--scan", "nao-existe", "--format", "json"])
    assert code == 1


def test_keys_set_delete_flow(tmp_path, capsys, monkeypatch) -> None:
    from core.secret_store import SecretStore

    store = SecretStore(keys_path=tmp_path / "keys.json")
    # Substitui o singleton global para não tocar em config/api_keys.json real.
    monkeypatch.setattr("core.secret_store._SECRET_STORE", store)
    code = run_cli(["keys", "set", "ABUSEIPDB_API_KEY", "--value", "chave-teste"])
    assert code == 0
    assert store.get("ABUSEIPDB_API_KEY") == "chave-teste"
    code = run_cli(["keys", "delete", "ABUSEIPDB_API_KEY"])
    assert code == 0
    assert store.get("ABUSEIPDB_API_KEY") is None
