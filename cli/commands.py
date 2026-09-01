"""Implementação dos comandos da CLI."""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path
from typing import Any

from core.logger import get_logger
from core.plugin_manager import PluginManager

log = get_logger("cli")


def run_command(args: Any) -> int:
    """Despacha o comando solicitado no argparse."""
    from cli.main import run_async

    command = args.command
    if command == "scan":
        return _cmd_scan(args, run_async)
    if command == "menu":
        from cli.menu import run_menu

        return run_menu()
    if command == "plugins":
        return _cmd_plugins(args)
    if command == "apis":
        return _cmd_apis(args)
    if command == "history":
        return _cmd_history(args)
    if command == "export":
        return _cmd_export(args)
    if command == "keys":
        return _cmd_keys(args)
    if command == "config":
        return _cmd_config(args)
    if command == "diag":
        return _cmd_diag(args, run_async)
    if command == "selfcheck":
        return _cmd_selfcheck()
    print(f"[nexus] Comando desconhecido: {command}")
    return 2


# ---------------------------------------------------------------------------
# scan
# ---------------------------------------------------------------------------
def _cmd_scan(args: Any, run_async) -> int:
    from cli.output import banner, colorize, print_json, render_table, status_color
    from core.engine import Engine

    plugin_filter = [p.strip() for p in args.plugins.split(",") if p.strip()] if args.plugins else None

    engine = Engine(
        max_concurrent=args.max_concurrent,
        timeout=args.timeout,
    )
    context: dict[str, Any] = {"save_to_database": not args.no_db}

    from core.logger import set_console_level

    if args.json:
        set_console_level("ERROR")  # mantém a saída JSON limpa
    try:
        result = run_async(
            engine.run_scan(
                args.target,
                target_type=args.target_type,
                plugin_names=plugin_filter,
                context=context,
            )
        )
    finally:
        if args.json:
            set_console_level("INFO")

    if args.json:
        print_json(result.to_dict())
        return 0

    print(banner())
    print()
    print(f"Target       : {result.target}")
    print(f"Type         : {result.target_type}")
    print(f"Scan ID      : {result.scan_id}")
    print(f"Duration     : {result.duration}s")
    print(f"Status       : {result.status_summary()}")
    print()

    if result.plugin_status:
        print(colorize("Plugins", "bold"))
        print(render_table(
            ["Plugin", "Status"],
            [(name, colorize(status, status_color(status))) for name, status in sorted(result.plugin_status.items())],
        ))
        print()

    if result.plugin_results:
        print(colorize(f"Results ({len(result.plugin_results)})", "bold"))
        rows = []
        for item in result.plugin_results:
            data = item.get("data")
            if isinstance(data, dict):
                data = _compact_data(data)
            rows.append(
                (
                    item.get("plugin", ""),
                    str(item.get("result_type", "")).upper(),
                    str(data)[:80],
                    item.get("source"),
                    item.get("confidence", "LOW"),
                )
            )
        print(render_table(["Plugin", "Type", "Data", "Source", "Confidence"], rows, max_width=70))
        print()
    else:
        print(colorize("NO RESULTS", "yellow"))
        print()

    if result.errors:
        print(colorize(f"Errors ({len(result.errors)})", "red"))
        for error in result.errors:
            print(f"  [{error.get('plugin')}] {error.get('message')}")
        print()

    return 0


def _compact_data(data: dict[str, Any]) -> str:
    """Converte payloads em texto curto para a tabela."""
    parts = []
    for key in ("value", "name", "host", "record_type", "city", "asn", "org", "service", "url", "tech"):
        if key in data:
            parts.append(f"{key}={data[key]}")
    if not parts:
        parts = [f"{k}={v}" for k, v in list(data.items())[:3]]
    return ", ".join(parts)


# ---------------------------------------------------------------------------
# plugins
# ---------------------------------------------------------------------------
def _cmd_plugins(args: Any) -> int:
    from cli.output import colorize, render_table

    manager = PluginManager()
    manager.discover()
    plugins = manager.all()
    if args.target_type:
        value = args.target_type.strip().lower()
        plugins = [p for p in plugins if value in [t.lower() for t in p.target_types]]

    print(colorize(f"Plugins ({len(plugins)})", "bold"))
    rows = [
        (
            p.name,
            p.version,
            ", ".join(p.target_types),
            "sim" if p.requires_api_key else "não",
            p.description[:60],
        )
        for p in sorted(plugins, key=lambda p: p.name.lower())
    ]
    print(render_table(["Name", "Version", "Targets", "API Key", "Description"], rows))
    return 0


# ---------------------------------------------------------------------------
# apis (API Manager)
# ---------------------------------------------------------------------------
def _cmd_apis(args: Any) -> int:
    from cli.output import colorize, print_json, render_table, status_color
    from core.api_manager import get_api_registry

    registry = get_api_registry()
    rows = registry.status_all()

    if args.json:
        print_json(rows)
        return 0

    print(colorize("NEXUS API MANAGER", "bold"))
    print(render_table(["API", "STATUS"], [(r["name"], colorize(r["status"], status_color(r["status"]))) for r in rows]))
    print()
    print("APIs não listadas não existem no NEXUS. Nenhum endpoint é inventado;")
    print("cada integração usa somente a documentação oficial.")
    return 0


# ---------------------------------------------------------------------------
# history
# ---------------------------------------------------------------------------
def _cmd_history(args: Any) -> int:
    from cli.output import colorize, render_table
    from database.database import Database

    db = Database()
    history = db.history(args.limit)
    if not history:
        print("Histórico vazio. Execute: python nexus.py scan --target example.com")
        return 0

    print(colorize(f"Histórico de scans ({len(history)})", "bold"))
    rows = []
    for item in history:
        rows.append(
            (
                item["scan_id"],
                item["target"],
                item["target_type"],
                item["result_count"],
                item["error_count"],
                f"{item['duration']}s",
                _iso_time(item["started_at"]),
            )
        )
    print(render_table(["Scan ID", "Target", "Type", "Results", "Errors", "Duration", "Started"], rows))
    return 0


def _iso_time(timestamp: float) -> str:
    from datetime import datetime, timezone

    return datetime.fromtimestamp(timestamp, tz=timezone.utc).strftime("%Y-%m-%d %H:%M")


# ---------------------------------------------------------------------------
# export
# ---------------------------------------------------------------------------
def _cmd_export(args: Any) -> int:
    from cli.output import colorize
    from database.database import Database
    from reports.registry import get_generator

    db = Database()
    scan = db.get_scan(args.scan)
    if scan is None:
        print(f"[nexus] Scan não encontrado: {args.scan}")
        return 1

    from core.config import load_config

    fmt = args.format or load_config().output_format
    generator = get_generator(fmt)
    output = Path(args.output) if args.output else None
    path = generator.render(scan, output_path=output)
    print(colorize(f"Relatório gerado: {path}", "green"))
    return 0


# ---------------------------------------------------------------------------
# keys
# ---------------------------------------------------------------------------
def _cmd_keys(args: Any) -> int:
    from cli.output import colorize, render_table
    from core.errors import ApiKeyError
    from core.secret_store import get_secret_store

    store = get_secret_store()
    sub = args.keys_command

    if sub == "list":
        rows = [
            (r["name"], "CONFIGURED" if r["configured"] else "NOT CONFIGURED", r["source"] or "-")
            for r in store.list()
        ]
        print(render_table(["Key", "Status", "Source"], rows))
        print()
        print("Os valores nunca são exibidos.")
        return 0

    if sub == "set":
        value = args.value
        if value is None:
            value = _prompt_secret(f"Valor para {args.name}: ")
        try:
            store.set(args.name, value, backend=args.backend)
        except ApiKeyError as exc:
            print(f"[nexus] ERRO: {exc}")
            return 1
        print(colorize(f"Chave {args.name} armazenada com segurança.", "green"))
        return 0

    if sub == "delete":
        store.delete(args.name)
        print(f"Chave {args.name} removida.")
        return 0

    print("Uso: python nexus.py keys {set,list,delete} ...")
    return 2


def _prompt_secret(label: str) -> str:
    """Lê um secret do usuário sem ecoar no terminal (getpass)."""
    import getpass

    value = getpass.getpass(label)
    return value.strip()


# ---------------------------------------------------------------------------
# config
# ---------------------------------------------------------------------------
def _cmd_config(args: Any) -> int:
    import json as _json

    from cli.output import colorize, print_json, render_table
    from core.config import Config

    config = Config.instance()

    if args.preset:
        from core.constants import PERFORMANCE_PRESETS

        preset = args.preset.upper()
        if preset not in PERFORMANCE_PRESETS and preset != "CUSTOM":
            print(f"[nexus] Preset inválido: {preset}")
            return 1
        config.set("performance_preset", preset)
        if preset in PERFORMANCE_PRESETS:
            for key, value in PERFORMANCE_PRESETS[preset].items():
                config.set(key, value)
        config.save()
        print(colorize(f"Preset '{preset}' aplicado.", "green"))

    if args.set:
        key, value = args.set
        config.set(key, _coerce_config_value(value))
        config.save()
        print(f"config.{key} = {value}")

    if args.show or (not args.preset and not args.set):
        data = config.as_dict()
        if sys.stdout.isatty():
            print(render_table(["Key", "Value"], [(k, _json.dumps(v, ensure_ascii=False)) for k, v in data.items()]))
        else:
            print_json(data)
    return 0


def _coerce_config_value(value: str) -> Any:
    lowered = value.lower()
    if lowered in ("true", "false"):
        return lowered == "true"
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        pass
    return value


# ---------------------------------------------------------------------------
# diag
# ---------------------------------------------------------------------------
def _cmd_diag(args: Any, run_async) -> int:
    from cli.output import print_json
    from plugins.network.diagnostics import diagnose_local

    report = diagnose_local()
    if args.host:
        report["remote"] = run_async(_remote_checks(args.host))
    if args.json:
        print_json(report)
        return 0

    from cli.output import colorize, render_table

    print(colorize("System Diagnostics", "bold"))
    print(render_table(["Check", "Value"], [(k, str(v)[:80]) for k, v in report.items() if k != "remote"]))
    if "remote" in report:
        print()
        print(colorize("Remote Checks", "bold"))
        print(render_table(["Check", "Value"], [(k, str(v)[:80]) for k, v in report["remote"].items()]))
    return 0


async def _remote_checks(host: str) -> dict[str, Any]:
    """Testes de conectividade/latência/DNS contra um host (autorizado)."""
    import socket

    import httpx

    out: dict[str, Any] = {}
    try:
        socket.setdefaulttimeout(5)
        ip = socket.gethostbyname(host)
        out["resolved_ip"] = ip
    except OSError as exc:
        out["resolved_ip"] = f"ERROR: {exc}"

    try:
        import dns.resolver

        answers = dns.resolver.resolve(host, "A", lifetime=5)
        out["dns_a"] = [str(r) for r in answers][:5]
    except Exception as exc:  # noqa: BLE001
        out["dns_a"] = f"ERROR: {exc}"

    started = asyncio.get_event_loop().time()
    try:
        async with httpx.AsyncClient(timeout=10, verify=False) as client:
            resp = await client.get(f"http://{host}/", follow_redirects=False)
        latency = round((asyncio.get_event_loop().time() - started) * 1000, 1)
        out["http_status"] = resp.status_code
        out["latency_ms"] = latency
    except Exception as exc:  # noqa: BLE001
        out["http_status"] = f"ERROR: {exc}"
    return out


# ---------------------------------------------------------------------------
# selfcheck
# ---------------------------------------------------------------------------
def _cmd_selfcheck() -> int:
    from cli.output import colorize
    from core.constants import DATA_DIR, LOGS_DIR

    checks: list[tuple[str, bool, str]] = []
    if sys.version_info >= (3, 12):
        checks.append(("Python version", True, sys.version.split()[0]))
    elif sys.version_info >= (3, 11):
        checks.append(("Python version", True, sys.version.split()[0] + " (3.12+ recomendado)"))
    else:
        checks.append(("Python version", False, sys.version.split()[0]))

    for module in ("httpx", "dns", "phonenumbers", "psutil"):
        try:
            __import__(module)
            checks.append((f"Módulo {module}", True, "ok"))
        except ImportError:
            checks.append((f"Módulo {module}", False, "FALTANDO"))

    for directory in (DATA_DIR, LOGS_DIR):
        directory.mkdir(parents=True, exist_ok=True)
        checks.append((f"Diretório {directory}", directory.exists(), str(directory)))

    from core.cache import Cache
    from core.config import load_config

    config = load_config()
    checks.append(("Config carregada", True, f"preset={config.get('performance_preset')}"))

    cache = Cache(enabled=True)
    cache.set("selfcheck", "ok")
    ok = cache.get("selfcheck") == "ok"
    checks.append(("Cache funcionando", ok, f"{cache.size()} entradas"))

    try:
        from database.database import Database

        db = Database()
        checks.append(("Banco SQLite", True, str(db.path)))
    except Exception as exc:  # noqa: BLE001
        checks.append(("Banco SQLite", False, str(exc)))

    manager = PluginManager()
    plugins = manager.discover()
    checks.append(("Plugins descobertos", len(plugins) > 0, f"{len(plugins)} plugins"))

    print(colorize("NEXUS Self-Check", "bold"))
    for name, passed, detail in checks:
        mark = colorize("OK ", "green") if passed else colorize("FAIL", "red")
        print(f"  {mark}  {name:<28} {detail}")

    failed = [c for c in checks if not c[1]]
    print()
    if failed:
        print(colorize(f"{len(failed)} verificação(ns) falhou. Execute: pip install -r requirements.txt", "yellow"))
        return 1
    print(colorize("Tudo pronto.", "green"))
    return 0
