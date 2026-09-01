"""Rate limiter global e por plugin.

Garante que o NEXUS respeite limites de requisições por segundo
(próprios e das fontes consultadas), evitando bloqueios e abusos.
"""

from __future__ import annotations

import asyncio
import threading
import time

from core.logger import get_logger

log = get_logger("ratelimit")


class TokenBucket:
    """Algoritmo token bucket simples (thread-safe)."""

    def __init__(self, rate: float, burst: int | None = None) -> None:
        self.rate = max(rate, 0.1)  # tokens por segundo
        self.capacity = float(burst if burst and burst > 0 else max(int(rate), 1))
        self._tokens = self.capacity
        self._updated = time.monotonic()
        self._lock = threading.Lock()

    def _refill(self) -> None:
        now = time.monotonic()
        elapsed = now - self._updated
        self._tokens = min(self.capacity, self._tokens + elapsed * self.rate)
        self._updated = now

    def acquire(self) -> float:
        """Bloqueia até ter 1 token disponível; retorna o tempo esperado."""
        while True:
            with self._lock:
                self._refill()
                if self._tokens >= 1.0:
                    self._tokens -= 1.0
                    return 0.0
                wait = (1.0 - self._tokens) / self.rate
            time.sleep(max(wait, 0.001))


class AsyncRateLimiter:
    """Rate limiter assíncrono (semaphore + token bucket)."""

    def __init__(self, rate_per_second: float, burst: int | None = None) -> None:
        self._bucket = TokenBucket(rate_per_second, burst)
        self._lock = asyncio.Lock()

    async def acquire(self) -> None:
        """Espera até a requisição poder ser feita."""
        while True:
            async with self._lock:
                now = time.monotonic()
                # refill manual dentro do lock do asyncio
                elapsed = now - self._bucket._updated
                self._bucket._tokens = min(
                    self._bucket.capacity,
                    self._bucket._tokens + elapsed * self._bucket.rate,
                )
                self._bucket._updated = now
                if self._bucket._tokens >= 1.0:
                    self._bucket._tokens -= 1.0
                    return
                wait = (1.0 - self._bucket._tokens) / self._bucket.rate
            await asyncio.sleep(max(wait, 0.01))


class RateLimiterRegistry:
    """Registro de limiters por chave (global e por plugin)."""

    def __init__(self) -> None:
        self._limiters: dict[str, AsyncRateLimiter] = {}
        self._lock = threading.Lock()

    def get(self, key: str, rate_per_second: float = 5.0) -> AsyncRateLimiter:
        with self._lock:
            limiter = self._limiters.get(key)
            if limiter is None:
                limiter = AsyncRateLimiter(rate_per_second)
                self._limiters[key] = limiter
            return limiter

    async def acquire(self, key: str, rate_per_second: float = 5.0) -> None:
        await self.get(key, rate_per_second).acquire()

    def reset(self) -> None:
        with self._lock:
            self._limiters.clear()


_RATE_LIMITER_REGISTRY = RateLimiterRegistry()


def get_registry() -> RateLimiterRegistry:
    """Retorna o registro global de rate limiters."""
    return _RATE_LIMITER_REGISTRY


async def acquire(plugin_name: str, rate_per_second: float | None = None) -> None:
    """Helper: adquire um token para o plugin informado.

    Se ``rate_per_second`` for None, usa o limite global da configuração.
    """
    from core.config import load_config

    rate = rate_per_second
    if rate is None:
        rate = float(load_config().get("rate_limit_per_second", 5.0))
    registry = get_registry()
    await registry.acquire(plugin_name, rate)
    # Garante também o limite global (soma de todos os plugins).
    await registry.acquire("__global__", max(float(load_config().get("rate_limit_per_second", 5.0)), rate))
