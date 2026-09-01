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


def test_scan_multi_targets(capsys) -> None:
    """V2: scan múltiplo com --targets executa todos os alvos."""
    code = run_cli(["scan", "--targets", "+5585999999999,8.8.8.8", "--no-db"])
    output = capsys.readouterr().out
    assert code == 0
    assert "Scan múltiplo" in output
    assert "+5585999999999" in output
    assert "8.8.8.8" in output


def test_scan_requires_target_or_targets() -> None:
    code = run_cli(["scan", "--no-db"])
    assert code == 2


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


def test_menu_exit_option(capsys, monkeypatch) -> None:
    """Menu interativo: opção 0 encerra limpo."""
    monkeypatch.setattr("builtins.input", lambda _prompt="": "0")
    from cli.menu import run_menu

    assert run_menu() == 0


def test_menu_osint_phone_scan(capsys, monkeypatch) -> None:
    """Menu interativo: OSINT + telefone executa um scan offline."""
    answers = iter(["1", "+5585999999999", "0"])
    monkeypatch.setattr("builtins.input", lambda _prompt="": next(answers))
    from cli.menu import run_menu

    assert run_menu() == 0
    output = capsys.readouterr().out
    assert "Phone Validator" in output
    assert "Scan ID" in output


def test_ensure_utf8_stdout_prevents_unicode_crash(monkeypatch) -> None:
    """Windows (cp1252) não pode imprimir ╔═╗ — ensure_utf8_stdout deve evitar o crash."""
    import io
    import sys

    from cli.output import banner, ensure_utf8_stdout

    fake = io.TextIOWrapper(io.BytesIO(), encoding="cp1252", errors="strict")
    monkeypatch.setattr(sys, "stdout", fake)
    ensure_utf8_stdout()
    # Imprimir o banner não pode levantar UnicodeEncodeError
    print(banner())
    assert fake.encoding.lower() == "utf-8"


def test_cli_scan_works_with_cp1252_stdout(monkeypatch) -> None:
    """Caminho real do CLI (cli.main.main) não pode quebrar com stdout cp1252."""
    import io
    import sys

    fake = io.TextIOWrapper(io.BytesIO(), encoding="cp1252", errors="strict")
    monkeypatch.setattr(sys, "stdout", fake)
    code = run_cli(["scan", "--target", "+5585999999999", "--no-db"])
    assert code == 0
    fake.flush()
    output = fake.buffer.getvalue().decode("utf-8", errors="replace")
    assert "Scan ID" in output
    assert "Phone Validator" in output


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
