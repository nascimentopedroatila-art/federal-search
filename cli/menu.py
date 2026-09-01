"""Menu interativo do NEXUS (modo conversacional)."""

from __future__ import annotations

from core.constants import PROJECT_NAME, VERSION


def run_menu() -> int:
    """Executa o loop do menu principal."""
    from cli.output import banner, colorize

    print(banner())
    print(colorize(PROJECT_NAME, "cyan"))
    print(colorize(f"v{VERSION}  •  use 'python nexus.py --help' para ver todos os comandos", "dim"))
    print()

    while True:
        _print_main_menu()
        choice = input(colorize("Opção: ", "bold")).strip().lower()

        if choice in ("0", "sair", "exit", "quit"):
            print("Até logo!")
            return 0
        if choice == "1":
            _menu_osint()
        elif choice == "2":
            _menu_network()
        elif choice == "3":
            _menu_dns()
        elif choice == "4":
            _menu_hash()
        elif choice == "5":
            _menu_api_manager()
        elif choice == "6":
            _menu_reports()
        elif choice == "7":
            _menu_plugins()
        elif choice == "8":
            _menu_config()
        elif choice == "9":
            _menu_diagnostics()
        else:
            print(colorize("Opção inválida.", "red"))


def _print_main_menu() -> None:
    from cli.output import colorize

    menu = [
        "╔══════════════════════════════════════════╗",
        "║             M E N U   P R I N C I P A L  ║",
        "╠══════════════════════════════════════════╣",
        "║  1. OSINT                                ║",
        "║  2. Network                              ║",
        "║  3. DNS                                  ║",
        "║  4. Hash Analysis                        ║",
        "║  5. API Manager                          ║",
        "║  6. Reports                              ║",
        "║  7. Plugins                              ║",
        "║  8. Configuration                        ║",
        "║  9. System Diagnostics                   ║",
        "║  0. Exit                                 ║",
        "╚══════════════════════════════════════════╝",
    ]
    print("\n".join(colorize(line, "cyan") for line in menu))


# ---------------------------------------------------------------------------
def _ask_target() -> str | None:
    from core.target_detector import detect_type

    target = input("Target: ").strip()
    if not target:
        return None
    try:
        detected = detect_type(target)
        print(f"  Tipo detectado: {detected.value.upper()}")
    except Exception:  # noqa: BLE001
        print("  Tipo não detectado — use o formato completo (ex.: +55..., user@dom, dominio.com, 8.8.8.8)")
    return target


def _run_scan_interactive(target_value: str, forced_type: str | None = None) -> None:
    from cli.commands import _cmd_scan

    class _Args:
        target = target_value
        targets = None
        target_type = forced_type
        plugins = None
        json = False
        no_db = False
        max_concurrent = None
        timeout = None

    from cli.main import run_async

    _cmd_scan(_Args(), run_async)


def _menu_osint() -> None:
    from cli.output import colorize

    print()
    print(colorize("OSINT", "bold"))
    print("  Alvos suportados: telefone, e-mail, username, domínio, IP, URL, hash")
    target = _ask_target()
    if not target:
        return
    _run_scan_interactive(target)
    print()


def _menu_network() -> None:
    from cli.output import colorize

    print()
    print(colorize("Network", "bold"))
    print("  1. Diagnóstico da rede local")
    print("  2. Testar conectividade com host externo (ex.: 1.1.1.1)")
    choice = input("Opção: ").strip()
    if choice == "2":
        host_value = input("Host: ").strip() or "1.1.1.1"
        from cli.commands import _cmd_diag

        class _Args:
            host = host_value
            json = False

        from cli.main import run_async

        _cmd_diag(_Args(), run_async)
    else:
        from cli.commands import _cmd_diag

        class _Args:
            host = None
            json = False

        from cli.main import run_async

        _cmd_diag(_Args(), run_async)
    print()


def _menu_dns() -> None:
    from cli.output import colorize

    print()
    print(colorize("DNS", "bold"))
    print("  Execute: python nexus.py scan --target <dominio> --type domain")
    print("  Os plugins de domínio cobrem A, AAAA, MX, NS, TXT, SPF, DMARC, CAA e WHOIS.")
    print()


def _menu_hash() -> None:
    from cli.output import colorize

    print()
    print(colorize("Hash Analysis", "bold"))
    target = input("Hash (MD5/SHA1/SHA256/SHA512): ").strip()
    if target:
        _run_scan_interactive(target, forced_type="hash")
    print()


def _menu_api_manager() -> None:
    from cli.commands import _cmd_apis

    class _Args:
        json = False

    _cmd_apis(_Args())
    print()


def _menu_reports() -> None:
    from cli.output import colorize

    print()
    print(colorize("Reports", "bold"))
    print("  1. Histórico de scans")
    print("  2. Exportar scan (json/csv/html/txt)")
    choice = input("Opção: ").strip()
    if choice == "1":
        from cli.commands import _cmd_history

        class _Args:
            limit = 20

        _cmd_history(_Args())
    elif choice == "2":
        from cli.commands import _cmd_export

        scan_id = input("Scan ID: ").strip()
        fmt = input("Formato (json/csv/html/txt): ").strip() or "json"

        class _Args:
            scan = scan_id
            format = fmt
            output = None

        _cmd_export(_Args())
    print()


def _menu_plugins() -> None:
    from cli.commands import _cmd_plugins

    class _Args:
        target_type = None

    _cmd_plugins(_Args())
    print()


def _menu_config() -> None:
    from cli.commands import _cmd_config

    class _Args:
        show = True
        set = None
        preset = None

    _cmd_config(_Args())
    print()


def _menu_diagnostics() -> None:
    from cli.commands import _cmd_selfcheck

    _cmd_selfcheck()
    print()
