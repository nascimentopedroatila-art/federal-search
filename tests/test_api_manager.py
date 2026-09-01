"""Testes do API Manager: somente APIs reais, sem invenções."""

from __future__ import annotations

import os

from core.api_manager import API_REGISTRY, ApiRegistry
from core.secret_store import SecretStore


def test_registry_contains_only_real_apis() -> None:
    names = [api.name for api in API_REGISTRY]
    # APIs reais e verificadas (documentação oficial). Nunca inventar.
    assert "AbuseIPDB" in names
    assert "ipwho.is" in names
    assert "crt.sh (Certificate Transparency)" in names
    assert "RDAP (rdap.org + IANA bootstrap)" in names
    assert "CIRCL hashlookup" in names
    assert "VirusTotal" in names
    assert "emailrep.io" in names


def test_registry_metadata_complete() -> None:
    required = ("name", "website", "documentation", "free_tier", "supported_targets")
    for api in API_REGISTRY:
        for field in required:
            assert getattr(api, field), f"{api.name} sem {field}"
        assert api.rate_limit > 0
        assert api.supported_targets


def test_keyed_apis_report_not_configured_without_keys(monkeypatch) -> None:
    for key in list(os.environ):
        if "API_KEY" in key or "API_ID" in key or "API_SECRET" in key:
            monkeypatch.delenv(key, raising=False)
    registry = ApiRegistry()
    statuses = {row["name"]: row["status"] for row in registry.status_all()}
    assert statuses["AbuseIPDB"] == "NOT CONFIGURED"
    assert statuses["VirusTotal"] == "NOT CONFIGURED"


def test_keyless_apis_are_enabled() -> None:
    registry = ApiRegistry()
    statuses = {row["name"]: row["status"] for row in registry.status_all()}
    assert statuses["ipwho.is"] == "ENABLED"
    assert statuses["crt.sh (Certificate Transparency)"] == "ENABLED"
    assert statuses["RDAP (rdap.org + IANA bootstrap)"] == "ENABLED"
    assert statuses["CIRCL hashlookup"] == "ENABLED"


def test_api_key_enables_status(monkeypatch, tmp_path) -> None:
    monkeypatch.setenv("ABUSEIPDB_API_KEY", "chave-de-teste")
    store = SecretStore(keys_path=tmp_path / "keys.json")
    registry = ApiRegistry()
    row = next(r for r in registry.status_all() if r["name"] == "AbuseIPDB")
    assert row["status"] == "ENABLED"
    assert store.has("ABUSEIPDB_API_KEY")


def test_for_target_filter() -> None:
    registry = ApiRegistry()
    ip_apis = {api.name for api in registry.for_target("ip")}
    assert "AbuseIPDB" in ip_apis
    assert "ipwho.is" in ip_apis
    hash_apis = {api.name for api in registry.for_target("hash")}
    assert "CIRCL hashlookup" in hash_apis


def test_status_payload_is_safe() -> None:
    registry = ApiRegistry()
    for row in registry.status_all():
        assert "api_key" not in row
        assert "secret" not in row
        assert row["website"].startswith("http")
        assert row["documentation"].startswith("http")
