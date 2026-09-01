"""Deduplicação de resultados.

Resultados iguais vindos de fontes diferentes são agrupados em um
único resultado consolidado, mantendo a lista de fontes individuais
e calculando a confiança agregada.

Critério de igualdade: (plugin_type, result_type, chave canônica
extraída do payload) — o payload não é comparado byte a byte.
"""

from __future__ import annotations

from collections import Counter
from typing import Any, Iterable

from core.constants import Confidence

_FIELD_PRIORITY: dict[str, tuple[str, ...]] = {
    "dns": ("record_type", "name", "value"),
    "geo": ("city", "country"),
    "asn": ("asn", "org"),
    "whois": ("registrar", "created"),
    "certificate": ("name_value",),
    "technology": ("tech",),
    "reputation": ("indicator",),
    "presence": ("service",),
    "validation": ("field",),
    "subdomain": ("subdomain",),
    "reference": ("url",),
    "diagnostic": ("check",),
    "info": ("key",),
    "fraud": ("indicator",),
    "error": ("message",),
}


def _dedup_key(result: dict[str, Any]) -> str:
    result_type = str(result.get("result_type", "info"))
    payload = result.get("data") or {}
    if not isinstance(payload, dict):
        payload = {"value": payload}
    fields = _FIELD_PRIORITY.get(result_type, ("value",))
    parts: list[str] = []
    for field in fields:
        value = payload.get(field)
        if isinstance(value, (list, tuple)):
            value = ",".join(sorted(str(v) for v in value))
        if value is not None:
            parts.append(f"{field}={str(value).lower().strip()}")
    return "|".join(parts)


def deduplicate(results: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    """Agrupa resultados duplicados e consolida fontes/confiança."""
    grouped: dict[str, dict[str, Any]] = {}
    order: list[str] = []

    for result in results:
        if not result:
            continue
        key = _dedup_key(result)
        if key not in grouped:
            grouped[key] = dict(result)
            grouped[key]["sources"] = _as_list(result.get("source"))
            grouped[key]["source"] = _as_list(result.get("source"))[0] if _as_list(result.get("source")) else "unknown"
            grouped[key]["source_count"] = 1
            grouped[key]["confidence"] = _aggregate_confidence([result])
            order.append(key)
        else:
            merged = grouped[key]
            merged["sources"] = _merge_sources(merged.get("sources", []), result.get("source"))
            merged["source_count"] = len(merged["sources"])
            merged["confidence"] = _aggregate_confidence(
                [_as_source_item(r) for r in [merged, result]]
            )

    return [grouped[key] for key in order]


def _as_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, (list, tuple, set)):
        return [str(v) for v in value]
    return [str(value)]


def _merge_sources(existing: list[str], new: Any) -> list[str]:
    merged = list(existing)
    for source in _as_list(new):
        if source not in merged:
            merged.append(source)
    return merged


def _as_source_item(result: dict[str, Any]) -> dict[str, Any]:
    """Converte um resultado consolidado de volta em item com fonte única."""
    return {"source": _as_list(result.get("source"))[0] if _as_list(result.get("source")) else "unknown",
            "confidence": result.get("confidence")}


def _aggregate_confidence(items: list[dict[str, Any]]) -> str:
    """Confiança agregada: CONFIRMED > HIGH > MEDIUM > LOW.

    Regra: se qualquer fonte for CONFIRMED -> CONFIRMED;
    senão, a confiança máxima entre as fontes prevalece.
    """
    confidences = [str(i.get("confidence", "LOW")).upper() for i in items]
    if not confidences:
        return Confidence.LOW.value
    rank = {
        Confidence.LOW.value: 0,
        Confidence.MEDIUM.value: 1,
        Confidence.HIGH.value: 2,
        Confidence.CONFIRMED.value: 3,
    }
    best = max(confidences, key=lambda c: rank.get(c, 0))
    if best == Confidence.CONFIRMED.value:
        return Confidence.CONFIRMED.value
    if best == Confidence.HIGH.value:
        return Confidence.HIGH.value
    if best == Confidence.MEDIUM.value:
        return Confidence.MEDIUM.value
    return Confidence.LOW.value


def summarize(results: Iterable[dict[str, Any]]) -> dict[str, Any]:
    """Estatísticas úteis para relatórios (agrupamentos por tipo/fonte)."""
    results = list(results)
    by_type: Counter[str] = Counter(str(r.get("result_type", "info")) for r in results)
    by_source: Counter[str] = Counter(
        src for r in results for src in _as_list(r.get("source"))
    )
    by_confidence: Counter[str] = Counter(str(r.get("confidence", "LOW")) for r in results)
    return {
        "total": len(results),
        "by_type": dict(by_type),
        "by_source": dict(by_source),
        "by_confidence": dict(by_confidence),
    }
