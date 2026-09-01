"""Testes do rate limiter."""

from __future__ import annotations

import asyncio
import time

from core.rate_limiter import AsyncRateLimiter, RateLimiterRegistry, TokenBucket


def test_token_bucket_grants_token() -> None:
    bucket = TokenBucket(rate=100.0)
    start = time.monotonic()
    bucket.acquire()
    assert time.monotonic() - start < 1.0


def test_token_bucket_respects_rate() -> None:
    bucket = TokenBucket(rate=1.0, burst=1)
    bucket.acquire()  # consome o token inicial
    start = time.monotonic()
    bucket.acquire()  # deve esperar ~1s para o próximo token
    elapsed = time.monotonic() - start
    assert elapsed >= 0.9


def test_async_rate_limiter_high_rate_fast() -> None:
    limiter = AsyncRateLimiter(rate_per_second=200.0)

    async def main() -> None:
        start = time.monotonic()
        for _ in range(5):
            await limiter.acquire()
        assert time.monotonic() - start < 1.0

    asyncio.run(main())


def test_async_rate_limiter_low_rate_slow() -> None:
    limiter = AsyncRateLimiter(rate_per_second=1.0, burst=1)

    async def main() -> None:
        await limiter.acquire()  # token inicial
        start = time.monotonic()
        await limiter.acquire()
        assert time.monotonic() - start >= 0.8

    asyncio.run(main())


def test_registry_shares_limiters() -> None:
    registry = RateLimiterRegistry()
    a = registry.get("plugin-x")
    b = registry.get("plugin-x")
    assert a is b
    c = registry.get("plugin-y")
    assert c is not a


def test_registry_acquire_does_not_raise() -> None:
    registry = RateLimiterRegistry()

    async def main() -> None:
        await registry.acquire("plugin-x", rate_per_second=200.0)

    asyncio.run(main())
