"""Constantes globais do NEXUS."""

from __future__ import annotations

from enum import Enum
from pathlib import Path

# ---------------------------------------------------------------------------
# Versão
# ---------------------------------------------------------------------------
VERSION = "1.0.0"
PROJECT_NAME = "NEXUS - Modular Intelligence Toolkit"

# ---------------------------------------------------------------------------
# Diretórios (relativos à raiz do projeto)
# ---------------------------------------------------------------------------
ROOT_DIR = Path(__file__).resolve().parent.parent
CORE_DIR = ROOT_DIR / "core"
CLI_DIR = ROOT_DIR / "cli"
PLUGINS_DIR = ROOT_DIR / "plugins"
DATABASE_DIR = ROOT_DIR / "database"
REPORTS_DIR = ROOT_DIR / "reports"
CONFIG_DIR = ROOT_DIR / "config"
LOGS_DIR = ROOT_DIR / "logs"
DATA_DIR = ROOT_DIR / "data"
TESTS_DIR = ROOT_DIR / "tests"

DATABASE_PATH = DATA_DIR / "nexus.db"
CONFIG_PATH = CONFIG_DIR / "config.json"
API_KEYS_PATH = CONFIG_DIR / "api_keys.json"
DEFAULT_CACHE_PATH = DATA_DIR / "cache.db"

# ---------------------------------------------------------------------------
# Presets de performance
# ---------------------------------------------------------------------------
PERFORMANCE_PRESETS: dict[str, dict] = {
    "LOW": {
        "max_concurrent_requests": 2,
        "request_timeout": 10.0,
        "retry_count": 1,
        "rate_limit_per_second": 2.0,
    },
    "BALANCED": {
        "max_concurrent_requests": 5,
        "request_timeout": 15.0,
        "retry_count": 2,
        "rate_limit_per_second": 5.0,
    },
    "PERFORMANCE": {
        "max_concurrent_requests": 12,
        "request_timeout": 20.0,
        "retry_count": 3,
        "rate_limit_per_second": 10.0,
    },
}

# ---------------------------------------------------------------------------
# Limites de segurança (nunca infinitos)
# ---------------------------------------------------------------------------
MAX_TARGET_LENGTH = 4096
MAX_HTTP_RESPONSE_BYTES = 5 * 1024 * 1024  # 5 MB
MAX_RESULTS_PER_PLUGIN = 500
MAX_SCAN_DURATION_SECONDS = 600  # 10 minutos no modo interativo


class Status(str, Enum):
    """Status possíveis de um resultado/plugin durante um scan."""

    SUCCESS = "SUCCESS"
    NO_RESULTS = "NO_RESULTS"
    SKIPPED = "SKIPPED"
    RATE_LIMITED = "RATE_LIMITED"
    TIMEOUT = "TIMEOUT"
    ERROR = "ERROR"
    NOT_CONFIGURED = "NOT_CONFIGURED"

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.value


class Confidence(str, Enum):
    """Níveis de confiança dos resultados."""

    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CONFIRMED = "CONFIRMED"

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.value


class TargetType(str, Enum):
    """Tipos de alvo suportados pelo Target Detector."""

    PHONE = "phone"
    EMAIL = "email"
    USERNAME = "username"
    DOMAIN = "domain"
    IP = "ip"
    URL = "url"
    HASH = "hash"
    UNKNOWN = "unknown"

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.value


class ResultType(str, Enum):
    """Tipos de resultado emitidos pelos plugins.

    Permite correlação futura (V3) e agrupamento por categoria.
    """

    INFO = "info"
    DNS = "dns"
    GEO = "geo"
    ASN = "asn"
    WHOIS = "whois"
    CERTIFICATE = "certificate"
    TECHNOLOGY = "technology"
    REPUTATION = "reputation"
    FRAUD = "fraud"
    PRESENCE = "presence"
    VALIDATION = "validation"
    SUBDOMAIN = "subdomain"
    REFERENCE = "reference"
    DIAGNOSTIC = "diagnostic"
    ERROR = "error"

    def __str__(self) -> str:  # pragma: no cover - trivial
        return self.value
