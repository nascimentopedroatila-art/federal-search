"""Testes da deduplicação e consolidação de resultados."""

from __future__ import annotations

from core.deduplicator import deduplicate, summarize


def _result(result_type, value, source, confidence="MEDIUM"):
    return {
        "result_type": result_type,
        "data": {"value": value},
        "source": source,
        "confidence": confidence,
    }


def test_identical_results_are_grouped() -> None:
    results = [
        _result("dns", "10.0.0.1", "source-a"),
        _result("dns", "10.0.0.1", "source-b"),
        _result("dns", "10.0.0.1", "source-c"),
    ]
    merged = deduplicate(results)
    assert len(merged) == 1
    assert merged[0]["source_count"] == 3
    assert set(merged[0]["sources"]) == {"source-a", "source-b", "source-c"}


def test_distinct_results_are_kept() -> None:
    results = [
        _result("dns", "10.0.0.1", "source-a"),
        _result("dns", "10.0.0.2", "source-b"),
    ]
    merged = deduplicate(results)
    assert len(merged) == 2


def test_confidence_aggregation_confirmed_wins() -> None:
    results = [
        _result("dns", "x", "s1", confidence="LOW"),
        _result("dns", "x", "s2", confidence="CONFIRMED"),
    ]
    merged = deduplicate(results)
    assert merged[0]["confidence"] == "CONFIRMED"


def test_confidence_aggregation_max_wins() -> None:
    results = [
        _result("dns", "x", "s1", confidence="LOW"),
        _result("dns", "x", "s2", confidence="HIGH"),
    ]
    merged = deduplicate(results)
    assert merged[0]["confidence"] == "HIGH"


def test_same_source_not_duplicated_in_sources() -> None:
    results = [
        _result("presence", "github", "GitHub"),
        _result("presence", "github", "GitHub"),
    ]
    merged = deduplicate(results)
    assert merged[0]["sources"] == ["GitHub"]
    assert merged[0]["source_count"] == 1


def test_summarize_counts() -> None:
    results = [
        _result("dns", "a", "s1"),
        _result("dns", "b", "s2"),
        _result("geo", "x", "s1"),
    ]
    summary = summarize(results)
    assert summary["total"] == 3
    assert summary["by_type"]["dns"] == 2
    assert summary["by_type"]["geo"] == 1
    assert summary["by_source"]["s1"] == 2
