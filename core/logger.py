"""Logger central do NEXUS.

Gera 4 arquivos em ``logs/``:

- ``nexus.log``   -> tudo (DEBUG+)
- ``scans.log``   -> início/fim de scans (INFO+)
- ``plugins.log`` -> eventos de plugins (INFO+)
- ``errors.log``  -> somente erros (ERROR+)

Regra de segurança: **nunca** registrar secrets (API keys, tokens).
"""

from __future__ import annotations

import logging
import sys
from logging.handlers import RotatingFileHandler
from typing import Any

from core.constants import LOGS_DIR


def _redact(message: str) -> str:
    """Remove padrões de secrets de uma mensagem antes de logar."""
    import re

    patterns = [
        (r"(?i)(api[_-]?key|token|secret|password|passwd|authorization)\s*[=:]\s*\S+", r"\1=[REDACTED]"),
        (r"Bearer\s+\S+", "Bearer [REDACTED]"),
        (r"sk-[A-Za-z0-9_-]{8,}", "sk-[REDACTED]"),
    ]
    for pattern, replacement in patterns:
        message = re.sub(pattern, replacement, message)
    return message


class RedactingFormatter(logging.Formatter):
    """Formatter que redige secrets em todas as mensagens."""

    def format(self, record: logging.LogRecord) -> str:
        message = super().format(record)
        return _redact(message)


class NexusLogger:
    """Fachada de logging com múltiplos arquivos e redação de secrets."""

    _initialized = False

    def __init__(self, level: str = "INFO") -> None:
        if NexusLogger._initialized:
            return
        NexusLogger._initialized = True

        LOGS_DIR.mkdir(parents=True, exist_ok=True)
        numeric_level = getattr(logging, level.upper(), logging.INFO)
        fmt = RedactingFormatter("%(asctime)s | %(levelname)-8s | %(name)s | %(message)s")

        self._root = logging.getLogger("nexus")
        self._root.setLevel(logging.DEBUG)
        self._root.propagate = False

        # Console (sempre visível, INFO+)
        console = logging.StreamHandler(sys.stdout)
        console.setLevel(numeric_level)
        console.setFormatter(fmt)
        self._root.addHandler(console)

        handlers: dict[str, logging.Handler] = {}
        for name, filename, lvl in (
            ("nexus", LOGS_DIR / "nexus.log", logging.DEBUG),
            ("scans", LOGS_DIR / "scans.log", logging.INFO),
            ("plugins", LOGS_DIR / "plugins.log", logging.INFO),
            ("errors", LOGS_DIR / "errors.log", logging.ERROR),
        ):
            handler = RotatingFileHandler(
                filename, maxBytes=5 * 1024 * 1024, backupCount=5, encoding="utf-8"
            )
            handler.setLevel(lvl)
            handler.setFormatter(fmt)
            self._root.addHandler(handler)
            handlers[name] = handler

        # Loggers filho: nexus.scan, nexus.plugin.<nome>, ...
        self.scans = logging.getLogger("nexus.scan")
        self.plugins = logging.getLogger("nexus.plugin")
        self.errors = logging.getLogger("nexus.error")

    def get_logger(self, name: str) -> logging.Logger:
        """Retorna um logger filho de ``nexus``."""
        return logging.getLogger(f"nexus.{name}")


_LOGGER = NexusLogger()


def get_logger(name: str) -> logging.Logger:
    """Obtém um logger do NEXUS (redigido e com múltiplos arquivos)."""
    return _LOGGER.get_logger(name)


def configure(level: str = "INFO") -> None:
    """Reconfigura o nível do console (usado quando a config muda)."""
    set_console_level(level)


def set_console_level(level: str) -> None:
    """Altera o nível do handler de console (ex.: ERROR para saída JSON limpa)."""
    logger = logging.getLogger("nexus")
    handler = logger.handlers[0] if logger.handlers else None
    if handler:
        handler.setLevel(getattr(logging, level.upper(), logging.INFO))


def log(level: str, message: str, logger_name: str = "nexus", **kwargs: Any) -> None:
    """Helper de log com nível dinâmico."""
    get_logger(logger_name).log(getattr(logging, level.upper()), message, **kwargs)
