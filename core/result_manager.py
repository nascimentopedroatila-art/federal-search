"""Gerenciador de resultados (agregação e persistência em memória).

Umbrella de operações sobre a saída dos plugins: normalização,
deduplicação e acesso tipado para o CLI/relatórios.
"""

from __future__ import annotations

from typing import Any, Iterable

from core.deduplicator import deduplicate, summarize


class ResultManager:
    """Agrega e filtra resultados de um scan."""

    def __init__(self, results: Iterable[dict[str, Any]] | None = None) -> None:
        self._results: list[dict[str, Any]] = deduplicate(list(results or []))

    def add(self, result: dict[str, Any]) -> None:
        self._results.append(result)

    def all(self) -> list[dict[str, Any]]:
        return list(self._results)

    def deduplicated(self) -> list[dict[str, Any]]:
        return deduplicate(self._results)

    def by_type(self, result_type: str) -> list[dict[str, Any]]:
        return [r for r in self._results if r.get("result_type") == result_type]

    def by_source(self, source: str) -> list[dict[str, Any]]:
        sources = source.lower()
        return [
            r
            for r in self._results
            if any(s.lower() == sources for s in _as_list(r.get("source")))
        ]

    def by_confidence(self, confidence: str) -> list[dict[str, Any]]:
        return [r for r in self._results if str(r.get("confidence", "")).upper() == confidence.upper()]

    def sources(self) -> list[str]:
        unique: list[str] = []
        for r in self._results:
            for source in _as_list(r.get("source")):
                if source not in unique:
                    unique.append(source)
        return unique

    def summary(self) -> dict[str, Any]:
        return summarize(self._results)


def _as_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, (list, tuple, set)):
        return [str(v) for v in value]
    return [str(value)]
