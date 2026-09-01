"""Testes do banco SQLite."""

from __future__ import annotations

from database.database import Database
from database.migrations import run_migrations


def test_migrations_are_idempotent(tmp_path) -> None:
    path = tmp_path / "mig.db"
    run_migrations(path)
    run_migrations(path)  # segunda execução não deve falhar
    assert path.exists()


def test_save_and_get_scan(tmp_db: Database) -> None:
    results = [
        {
            "plugin": "Phone Validator",
            "result_type": "validation",
            "data": {"normalized": "+5585999999999"},
            "source": "phonenumbers (offline)",
            "confidence": "CONFIRMED",
            "status": "SUCCESS",
            "duration": 0.1,
        }
    ]
    tmp_db.save_scan(
        scan_id="abc123",
        target="+5585999999999",
        target_type="phone",
        started_at=1000.0,
        finished_at=1001.5,
        plugin_status={"Phone Validator": "SUCCESS"},
        results=results,
        errors=[],
    )
    scan = tmp_db.get_scan("abc")
    assert scan is not None
    assert scan["scan_id"] == "abc123"
    assert scan["target"] == "+5585999999999"
    assert scan["target_type"] == "phone"
    assert scan["duration"] == 1.5
    assert len(scan["results"]) == 1
    assert scan["results"][0]["data"]["normalized"] == "+5585999999999"


def test_history_orders_by_newest(tmp_db: Database) -> None:
    for i in range(3):
        tmp_db.save_scan(
            scan_id=f"scan-{i}",
            target=f"target-{i}",
            target_type="domain",
            started_at=float(i),
            finished_at=float(i) + 1,
            plugin_status={},
            results=[],
            errors=[],
        )
    history = tmp_db.history(limit=10)
    assert len(history) == 3
    assert history[0]["scan_id"] == "scan-2"


def test_history_limit(tmp_db: Database) -> None:
    for i in range(5):
        tmp_db.save_scan(
            scan_id=f"h-{i}", target=f"t-{i}", target_type="ip",
            started_at=0.0, finished_at=1.0,
            plugin_status={}, results=[], errors=[],
        )
    assert len(tmp_db.history(limit=2)) == 2


def test_delete_scan(tmp_db: Database) -> None:
    tmp_db.save_scan(
        scan_id="del-me", target="x", target_type="ip",
        started_at=0.0, finished_at=1.0, plugin_status={}, results=[], errors=[],
    )
    assert tmp_db.get_scan("del-me") is not None
    assert tmp_db.delete_scan("del-me") is True
    assert tmp_db.get_scan("del-me") is None


def test_stats(tmp_db: Database) -> None:
    tmp_db.save_scan(
        scan_id="s1", target="example.com", target_type="domain",
        started_at=0.0, finished_at=1.0,
        plugin_status={"P1": "SUCCESS"},
        results=[{"plugin": "P1", "result_type": "dns", "data": {"x": 1},
                  "source": "s", "confidence": "HIGH", "status": "SUCCESS", "duration": 0.1}],
        errors=[],
    )
    stats = tmp_db.stats()
    assert stats["scans"] == 1
    assert stats["results"] == 1
    assert stats["by_result_type"]["dns"] == 1


def test_errors_recorded(tmp_db: Database) -> None:
    tmp_db.save_scan(
        scan_id="e1", target="x", target_type="ip",
        started_at=0.0, finished_at=1.0, plugin_status={"P": "ERROR"},
        results=[], errors=[{"plugin": "P", "message": "boom"}],
    )
    scan = tmp_db.get_scan("e1")
    assert scan["error_count"] == 1
    assert scan["plugin_status"] == {"P": "ERROR"}
