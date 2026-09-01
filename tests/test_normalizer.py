"""Testes do normalizador."""

from __future__ import annotations

import pytest
from core.constants import TargetType
from core.errors import TargetError
from core.normalizer import normalize


def test_normalize_phone_e164() -> None:
    assert normalize("(85) 99999-9999", TargetType.PHONE) == "+5585999999999"


def test_normalize_phone_keeps_plus() -> None:
    assert normalize("+1 202-555-0143", TargetType.PHONE) == "+12025550143"


def test_normalize_email_lowercase() -> None:
    assert normalize("User@Example.COM", TargetType.EMAIL) == "user@example.com"


def test_normalize_email_invalid() -> None:
    with pytest.raises(TargetError):
        normalize("sem-arroba", TargetType.EMAIL)


def test_normalize_domain() -> None:
    assert normalize("EXAMPLE.com.", TargetType.DOMAIN) == "example.com"


def test_normalize_domain_invalid() -> None:
    with pytest.raises(TargetError):
        normalize("não é domínio", TargetType.DOMAIN)


def test_normalize_ip() -> None:
    assert normalize(" 8.8.8.8 ", TargetType.IP) == "8.8.8.8"


def test_normalize_hash_lower() -> None:
    assert normalize("D41D8CD98F00B204E9800998ECF8427E", TargetType.HASH) == (
        "d41d8cd98f00b204e9800998ecf8427e"
    )


def test_normalize_hash_invalid() -> None:
    with pytest.raises(TargetError):
        normalize("zzzz", TargetType.HASH)


def test_normalize_username_strips_at() -> None:
    assert normalize("@nexus_user", TargetType.USERNAME) == "nexus_user"
