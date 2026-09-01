#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""NEXUS - Modular Intelligence Toolkit.

Ponto de entrada único da ferramenta:

    python nexus.py scan --target example.com
    python nexus.py menu
    python nexus.py --help
"""

from __future__ import annotations

import sys
from pathlib import Path

# Garante que o projeto seja importável independentemente do diretório atual.
_ROOT = Path(__file__).resolve().parent
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))


def main() -> int:
    """Delega para o CLI principal."""
    from cli.output import ensure_utf8_stdout

    ensure_utf8_stdout()  # evita UnicodeEncodeError no Windows (cp1252/cp437)
    from cli.main import main as cli_main

    return cli_main()


if __name__ == "__main__":
    raise SystemExit(main())
