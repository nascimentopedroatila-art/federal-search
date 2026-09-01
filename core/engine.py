"""Engine de consulta assíncrona do NEXUS.

Coordena a execução de plugins para um alvo com:

- ``asyncio`` + semáforo (concorrência controlada)
- rate limiting global e por plugin
- timeouts por requisição e por plugin
- retry com exponential backoff
- cache de resultados
- isolamento de falhas (um plugin que falhar não interrompe o scan)
- limites de segurança (nº máximo de resultados e duração)
"""

from __future__ import annotations

import asyncio
import time
import uuid
from typing import Any

from core.constants import MAX_RESULTS_PER_PLUGIN, Status
from core.deduplicator import deduplicate
from core.dispatcher import Dispatcher
from core.logger import get_logger
from core.plugin import NexusPlugin, PluginResult
from core.plugin_manager import PluginManager
from core.rate_limiter import acquire

log = get_logger("engine")


class ScanResult:
    """Resultado completo de um scan."""

    def __init__(
        self,
        scan_id: str,
        target: str,
        target_type: str,
        started_at: float,
        finished_at: float,
        plugin_results: list[dict[str, Any]],
        plugin_status: dict[str, str],
        errors: list[dict[str, str]],
        raw_plugin_output: dict[str, Any] | None = None,
    ) -> None:
        self.scan_id = scan_id
        self.target = target
        self.target_type = target_type
        self.started_at = started_at
        self.finished_at = finished_at
        self.duration = round(finished_at - started_at, 3)
        self.plugin_results = plugin_results
        self.plugin_status = plugin_status
        self.errors = errors
        self.raw_plugin_output = raw_plugin_output or {}

    def to_dict(self) -> dict[str, Any]:
        return {
            "scan_id": self.scan_id,
            "target": self.target,
            "target_type": self.target_type,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "duration": self.duration,
            "status": self.status_summary(),
            "plugins": self.plugin_status,
            "results": self.plugin_results,
            "errors": self.errors,
        }

    def status_summary(self) -> str:
        if self.plugin_status and all(s == Status.ERROR.value for s in self.plugin_status.values()):
            return "FAILED"
        if self.plugin_results:
            return "SUCCESS"
        return "NO_RESULTS"


class Engine:
    """Motor principal de execução de scans."""

    def __init__(
        self,
        plugin_manager: PluginManager | None = None,
        max_concurrent: int | None = None,
        timeout: float | None = None,
        retry_count: int | None = None,
    ) -> None:
        # Dispatcher descobre os plugins automaticamente quando None.
        self.dispatcher = Dispatcher(plugin_manager=plugin_manager)
        self.max_concurrent = max_concurrent
        self.timeout = timeout
        self.retry_count = retry_count
        self._config_overrides: dict[str, Any] = {}

    # ------------------------------------------------------------------ #
    def _settings(self) -> dict[str, Any]:
        from core.config import load_config

        config = load_config()
        return {
            "max_concurrent": self.max_concurrent or int(config.max_concurrent_requests),
            "timeout": self.timeout or float(config.request_timeout),
            "retry_count": self.retry_count or int(config.retry_count),
        }

    # ------------------------------------------------------------------ #
    async def run_scan(
        self,
        target: str,
        target_type: str | None = None,
        plugin_names: list[str] | None = None,
        context: dict[str, Any] | None = None,
    ) -> ScanResult:
        """Executa um scan completo contra o alvo."""
        scan_id = uuid.uuid4().hex[:12]
        started = time.time()
        log.info("[scan:%s] Iniciando scan de %s (tipo=%s)", scan_id, target, target_type or "auto")

        normalized, resolved_type = self.dispatcher.resolve_target(target, target_type)
        settings = self._settings()
        ctx = self.dispatcher.build_context(**(context or {}))
        ctx["scan_id"] = scan_id

        plugins = self.dispatcher.select_plugins(resolved_type, plugin_names)
        if not plugins:
            log.warning("[scan:%s] Nenhum plugin compatível para tipo %s", scan_id, resolved_type)

        semaphore = asyncio.Semaphore(int(settings["max_concurrent"]))
        plugin_status: dict[str, str] = {}
        raw_outputs: dict[str, Any] = {}
        errors: list[dict[str, str]] = []

        async def run_one(plugin: NexusPlugin) -> None:
            name = plugin.name
            try:
                if plugin.requires_api_key and not plugin.check_api_key(ctx):
                    plugin_status[name] = Status.NOT_CONFIGURED.value
                    log.info("[scan:%s] Plugin '%s' sem API key (NOT CONFIGURED).", scan_id, name)
                    return
                if not plugin.target_types or resolved_type not in plugin.target_types:
                    plugin_status[name] = Status.SKIPPED.value
                    return

                async with semaphore:
                    await acquire(name, plugin.rate_limit)
                    result = await self._run_plugin_with_retries(
                        plugin, normalized, ctx, settings
                    )
                    raw_outputs[name] = result
                    plugin_status[name] = result["status"] if result else Status.ERROR.value
                    if plugin_status[name] == Status.ERROR.value:
                        errors.append(
                            {"plugin": name, "message": (result or {}).get("error", "erro desconhecido")}
                        )
            except asyncio.CancelledError:  # noqa: PERF203
                raise
            except Exception as exc:  # noqa: BLE001 - isolamento de falhas
                plugin_status[name] = Status.ERROR.value
                message = str(exc)[:300]
                errors.append({"plugin": name, "message": message})
                log.exception("[scan:%s] Plugin '%s' falhou: %s", scan_id, name, message)

        # setup
        for plugin in plugins:
            try:
                await plugin.setup()
            except Exception:  # noqa: BLE001
                log.exception("[scan:%s] setup do plugin '%s' falhou", scan_id, plugin.name)

        await asyncio.gather(*(run_one(p) for p in plugins))

        # teardown
        for plugin in plugins:
            try:
                await plugin.teardown()
            except Exception:  # noqa: BLE001
                log.exception("[scan:%s] teardown do plugin '%s' falhou", scan_id, plugin.name)

        all_results: list[dict[str, Any]] = []
        for name, output in raw_outputs.items():
            for item in output.get("results", []):
                item["plugin"] = name
                all_results.append(item)

        all_results = deduplicate(all_results)

        # Persistência no banco
        save_to_db = ctx.get(
            "save_to_database",
            ctx["config"].get("save_to_database", True) if ctx.get("config") else True,
        )
        if save_to_db:
            try:
                from database.database import Database

                db = Database()
                db.save_scan(
                    scan_id=scan_id,
                    target=normalized,
                    target_type=resolved_type,
                    started_at=started,
                    finished_at=time.time(),
                    plugin_status=plugin_status,
                    results=all_results,
                    errors=errors,
                )
            except Exception:  # noqa: BLE001 - banco não pode quebrar o scan
                log.exception("[scan:%s] Falha ao salvar scan no banco", scan_id)

        finished = time.time()
        log.info(
            "[scan:%s] Scan concluído em %.2fs | %d resultados | %d plugins",
            scan_id, finished - started, len(all_results), len(plugin_status),
        )
        return ScanResult(
            scan_id=scan_id,
            target=normalized,
            target_type=resolved_type,
            started_at=started,
            finished_at=finished,
            plugin_results=all_results,
            plugin_status=plugin_status,
            errors=errors,
            raw_plugin_output=raw_outputs,
        )

    # ------------------------------------------------------------------ #
    async def _run_plugin_with_retries(
        self,
        plugin: NexusPlugin,
        target: str,
        ctx: dict[str, Any],
        settings: dict[str, Any],
    ) -> dict[str, Any]:
        """Executa o plugin com cache, timeout e retry com backoff."""
        cache = ctx.get("cache")
        cache_ttl = int(getattr(plugin, "cache_ttl", 0) or 0)
        cache_key = None
        if cache and cache_ttl > 0:
            from core.cache import Cache

            cache_key = Cache.make_key("plugin", plugin.name, target)
            cached = cache.get(cache_key)
            if cached is not None:
                log.debug("Cache hit para plugin '%s' em %s", plugin.name, target)
                return cached

        last_error = ""
        for attempt in range(int(settings["retry_count"]) + 1):
            started = time.time()
            try:
                results = await asyncio.wait_for(
                    plugin.execute(target, context=ctx),
                    timeout=float(plugin.timeout or settings["timeout"]),
                )
                results = results or []
                results = results[: MAX_RESULTS_PER_PLUGIN]
                serialized = [r.to_dict() if isinstance(r, PluginResult) else r for r in results]
                # normaliza status
                statuses = {str(r.get("status", Status.SUCCESS.value)) for r in serialized}
                status = _pick_status(statuses)
                payload = {
                    "status": status,
                    "results": serialized,
                    "error": None,
                    "duration": round(time.time() - started, 3),
                }
                if cache_key and status not in (Status.ERROR.value,):
                    cache.set(cache_key, payload)
                return payload
            except asyncio.TimeoutError:
                last_error = f"timeout após {plugin.timeout or settings['timeout']}s"
                log.warning("Plugin '%s' deu timeout (tentativa %d)", plugin.name, attempt + 1)
            except Exception as exc:  # noqa: BLE001
                last_error = str(exc)[:300]
                log.warning(
                    "Plugin '%s' erro (tentativa %d/%d): %s",
                    plugin.name, attempt + 1, settings["retry_count"] + 1, last_error,
                )
            if attempt < int(settings["retry_count"]):
                await asyncio.sleep(min(2 ** attempt, 8))

        return {
            "status": Status.ERROR.value,
            "results": [],
            "error": last_error or "erro desconhecido",
            "duration": 0.0,
        }


def _pick_status(statuses: set[str]) -> str:
    """Prioridade: ERROR > RATE_LIMITED > TIMEOUT > NO_RESULTS > SUCCESS."""
    priority = [
        Status.ERROR.value,
        Status.RATE_LIMITED.value,
        Status.TIMEOUT.value,
        Status.NO_RESULTS.value,
        Status.SUCCESS.value,
    ]
    for candidate in priority:
        if candidate in statuses:
            return candidate
    return Status.SUCCESS.value


async def run_scan_async(
    target: str,
    target_type: str | None = None,
    plugin_names: list[str] | None = None,
    **kwargs: Any,
) -> ScanResult:
    """Helper assíncrono: executa um scan com a engine padrão."""
    engine = Engine()
    return await engine.run_scan(target, target_type, plugin_names, context=kwargs.get("context"))


async def run_multi_scan_async(
    targets: list[str],
    target_type: str | None = None,
    plugin_names: list[str] | None = None,
    max_concurrent: int = 4,
    engine: "Engine | None" = None,
    **kwargs: Any,
) -> list[ScanResult]:
    """Executa scans em paralelo para múltiplos alvos (limite de concorrência)."""
    semaphore = asyncio.Semaphore(max(int(max_concurrent), 1))
    engine = engine or Engine()

    async def _one(target: str) -> ScanResult:
        async with semaphore:
            return await engine.run_scan(
                target, target_type, plugin_names, context=kwargs.get("context")
            )

    return list(await asyncio.gather(*(_one(t) for t in targets)))


def run_scan(
    target: str,
    target_type: str | None = None,
    plugin_names: list[str] | None = None,
    **kwargs: Any,
) -> ScanResult:
    """Executa um scan (bloqueante) com o event loop padrão."""
    return asyncio.run(run_scan_async(target, target_type, plugin_names, **kwargs))


def run_multi_scan(
    targets: list[str],
    target_type: str | None = None,
    plugin_names: list[str] | None = None,
    max_concurrent: int = 4,
    engine: "Engine | None" = None,
    **kwargs: Any,
) -> list[ScanResult]:
    """Executa scans em paralelo para múltiplos alvos (bloqueante)."""
    return asyncio.run(
        run_multi_scan_async(
            targets, target_type, plugin_names, max_concurrent, engine=engine, **kwargs
        )
    )
