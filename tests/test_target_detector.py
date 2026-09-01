"""Testes do Target Detector e do resolvedor de alvos."""

from __future__ import annotations

import pytest
from core.constants import TargetType
from core.errors import TargetError
from core.target_detector import detect_type, resolve


@pytest.mark.parametrize(
    ("target", "expected"),
    [
        ("+5585999999999", TargetType.PHONE),
        ("(85) 99999-9999", TargetType.PHONE),
        ("5585999999999", TargetType.PHONE),
        ("user@example.com", TargetType.EMAIL),
        ("User.Name+tag@sub.example.org", TargetType.EMAIL),
        ("example.com", TargetType.DOMAIN),
        ("sub.domain.example.br", TargetType.DOMAIN),
        ("8.8.8.8", TargetType.IP),
        ("2001:4860:4860::8888", TargetType.IP),
        ("https://example.com", TargetType.URL),
        ("http://example.com/path?q=1", TargetType.URL),
        ("example_username", TargetType.USERNAME),
        ("d41d8cd98f00b204e9800998ecf8427e", TargetType.HASH),
        ("da39a3ee5e6b4b0d3255bfef95601890afd80709", TargetType.HASH),
        ("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", TargetType.HASH),
        ("not a target at all!!", TargetType.UNKNOWN),
    ],
)
def test_detect_type(target: str, expected: TargetType) -> None:
    assert detect_type(target) == expected


def test_resolve_without_type_normalizes_domain() -> None:
    normalized, ttype = resolve("Example.COM.")
    assert normalized == "example.com"
    assert ttype == TargetType.DOMAIN


def test_resolve_forced_type_is_respected() -> None:
    # O usuário informou o tipo manualmente: deve ser respeitado.
    normalized, ttype = resolve("example_username", target_type="username")
    assert ttype == TargetType.USERNAME
    assert normalized == "example_username"


def test_resolve_phone_with_forced_type() -> None:
    normalized, ttype = resolve("(85) 99999-9999", target_type="phone")
    assert ttype == TargetType.PHONE
    assert normalized.startswith("+55")


def test_resolve_unknown_type_raises() -> None:
    with pytest.raises(TargetError):
        resolve("exemplo sem tipo")


def test_resolve_invalid_type_name_raises() -> None:
    with pytest.raises(TargetError):
        resolve("example.com", target_type="carrier_pigeon")


def test_resolve_invalid_email_raises() -> None:
    with pytest.raises(TargetError):
        resolve("não-é-email", target_type="email")


def test_resolve_invalid_ip_raises() -> None:
    with pytest.raises(TargetError):
        resolve("999.999.999.999", target_type="ip")


def test_resolve_empty_target_raises() -> None:
    with pytest.raises(TargetError):
        resolve("   ")


def test_resolve_hash_normalizes_to_lowercase() -> None:
    normalized, ttype = resolve("D41D8CD98F00B204E9800998ECF8427E")
    assert normalized == "d41d8cd98f00b204e9800998ecf8427e"
    assert ttype == TargetType.HASH
