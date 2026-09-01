"""CLI do NEXUS (argparse + modo interativo)."""

from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path
from typing import Any

from core.constants import PROJECT_NAME, VERSION

_ROOT = Path(__file__).resolve().parent.parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))


def build_parser() -> argparse.ArgumentParser:
    """Constrói o parser principal da CLI."""
    parser = argparse.ArgumentParser(
        prog="nexus",
        description=f"{PROJECT_NAME} — OSINT legítimo, análise de infraestrutura pública e diagnóstico de rede.",
        epilog="Exemplos:\n"
        "  python nexus.py scan --target example.com\n"
        "  python nexus.py scan --target user@example.com --type email\n"
        "  python nexus.py menu\n"
        "  python nexus.py history\n"
        "  python nexus.py export --scan <ID> --format html\n",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--version", action="version", version=f"NEXUS {VERSION}")

    sub = parser.add_subparsers(dest="command", metavar="{scan,menu,plugins,apis,history,export,keys,config,diag,selfcheck}")

    # scan
    p_scan = sub.add_parser("scan", help="Executa um scan contra um alvo")
    p_scan.add_argument("--target", "-t", required=True, help="Alvo (domínio, IP, e-mail, telefone, username, URL, hash)")
    p_scan.add_argument("--type", dest="target_type", default=None, help="Tipo do alvo (phone, email, username, domain, ip, url, hash)")
    p_scan.add_argument("--plugins", default=None, help="Lista de plugins separada por vírgula (filtro)")
    p_scan.add_argument("--json", action="store_true", help="Saída em JSON puro (sem tabela)")
    p_scan.add_argument("--no-db", action="store_true", help="Não salva o scan no banco")
    p_scan.add_argument("--max-concurrent", type=int, default=None, help="Override do nº de requisições concorrentes")
    p_scan.add_argument("--timeout", type=float, default=None, help="Override do timeout de requisição (s)")

    # menu
    sub.add_parser("menu", help="Abre o menu interativo")

    # plugins
    p_plugins = sub.add_parser("plugins", help="Lista os plugins disponíveis")
    p_plugins.add_argument("--type", dest="target_type", default=None, help="Filtra por tipo de alvo")

    # apis
    p_apis = sub.add_parser("apis", help="Mostra o API Manager")
    p_apis.add_argument("--json", action="store_true", help="Saída JSON")

    # history
    p_history = sub.add_parser("history", help="Histórico de scans")
    p_history.add_argument("--limit", type=int, default=20, help="Número de scans (padrão: 20)")

    # export
    p_export = sub.add_parser("export", help="Exporta um scan para relatório")
    p_export.add_argument("--scan", required=True, help="ID do scan (aceita prefixo)")
    p_export.add_argument("--format", choices=["json", "csv", "html", "txt"], default=None, help="Formato (padrão: config)")
    p_export.add_argument("--output", "-o", default=None, help="Caminho de saída")

    # keys
    p_keys = sub.add_parser("keys", help="Gerencia API keys com segurança")
    keys_sub = p_keys.add_subparsers(dest="keys_command", metavar="{set,list,delete}")
    p_keys_set = keys_sub.add_parser("set", help="Armazena uma chave (Credential Manager no Windows)")
    p_keys_set.add_argument("name", help="Nome da chave (ex.: ABUSEIPDB_API_KEY)")
    p_keys_set.add_argument("--value", default=None, help="Valor da chave (se omitido, lê de stdin/prompt)")
    p_keys_set.add_argument("--backend", choices=["auto", "file", "credential_manager", "env"], default="auto")
    keys_sub.add_parser("list", help="Lista chaves (sem revelar valores)")
    p_keys_del = keys_sub.add_parser("delete", help="Remove uma chave")
    p_keys_del.add_argument("name", help="Nome da chave")

    # config
    p_config = sub.add_parser("config", help="Exibe/edita a configuração")
    p_config.add_argument("--show", action="store_true", help="Mostra a configuração atual")
    p_config.add_argument("--set", nargs=2, metavar=("KEY", "VALUE"), default=None, help="Altera um valor")
    p_config.add_argument("--preset", choices=["LOW", "BALANCED", "PERFORMANCE", "CUSTOM"], default=None, help="Aplica um preset")

    # diag
    p_diag = sub.add_parser("diag", help="Diagnóstico de sistema/rede (próprios)")
    p_diag.add_argument("--host", default=None, help="Host para teste de latência/conectividade (ex.: 1.1.1.1)")
    p_diag.add_argument("--json", action="store_true", help="Saída JSON")

    # selfcheck
    sub.add_parser("selfcheck", help="Verifica instalação, dependências e rede")

    return parser


def main(argv: list[str] | None = None) -> int:
    """Ponto de entrada do CLI."""
    from cli.commands import run_command

    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command is None:
        parser.print_help()
        return 0

    try:
        return run_command(args)
    except KeyboardInterrupt:
        print("\n[nexus] Interrompido pelo usuário.")
        return 130
    except Exception as exc:  # noqa: BLE001 - erro de CLI amigável
        from core.logger import get_logger

        get_logger("cli").exception("Falha na execução do comando: %s", exc)
        print(f"[nexus] ERRO: {exc}")
        return 1


def run_async(coro) -> Any:
    """Executa uma coroutine em um novo event loop."""
    return asyncio.run(coro)
