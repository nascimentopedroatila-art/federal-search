"""API Manager do NEXUS.

Registro central de integrações. **Regra absoluta:** nenhuma API ou
endpoint é inventado — cada entrada abaixo corresponde a um serviço
real, com documentação oficial e tier gratuito verificado.

O núcleo do NEXUS não depende de nenhuma destas APIs: se uma API não
estiver configurada, o status é ``NOT CONFIGURED`` e o plugin
correspondente é pulado sem quebrar o scan.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class ApiDefinition:
    """Definição imutável de uma API integrada ao NEXUS."""

    name: str
    website: str
    documentation: str
    api_key_required: bool
    free_tier: str
    rate_limit: float
    supported_targets: list[str]
    api_key_name: str | None = None
    enabled: bool = True
    category: str = "intelligence"


@dataclass
class ApiStatus:
    """Status calculado de uma API."""

    name: str
    status: str  # ENABLED | NOT CONFIGURED | DISABLED
    configured: bool
    api_key_required: bool
    website: str
    documentation: str
    free_tier: str
    supported_targets: list[str]

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "status": self.status,
            "configured": self.configured,
            "api_key_required": self.api_key_required,
            "website": self.website,
            "documentation": self.documentation,
            "free_tier": self.free_tier,
            "supported_targets": self.supported_targets,
        }


# ---------------------------------------------------------------------------
# Registro canônico (somente APIs reais e documentadas)
# ---------------------------------------------------------------------------
API_REGISTRY: list[ApiDefinition] = [
    ApiDefinition(
        name="AbuseIPDB",
        website="https://www.abuseipdb.com/",
        documentation="https://docs.abuseipdb.com/",
        api_key_required=True,
        api_key_name="ABUSEIPDB_API_KEY",
        free_tier="1.000 requisições/dia",
        rate_limit=2.0,
        supported_targets=["ip"],
        category="reputation",
    ),
    ApiDefinition(
        name="ipwho.is",
        website="https://ipwho.is/",
        documentation="https://ipwho.is/",
        api_key_required=False,
        free_tier="Sem chave, sem cadastro",
        rate_limit=5.0,
        supported_targets=["ip"],
        category="geo",
    ),
    ApiDefinition(
        name="crt.sh (Certificate Transparency)",
        website="https://crt.sh/",
        documentation="https://crt.sh/",
        api_key_required=False,
        free_tier="Aberto",
        rate_limit=1.0,
        supported_targets=["domain"],
        category="certificates",
    ),
    ApiDefinition(
        name="RDAP (rdap.org + IANA bootstrap)",
        website="https://rdap.org/",
        documentation="https://rdap.org/",
        api_key_required=False,
        free_tier="Aberto (bootstrap IANA)",
        rate_limit=3.0,
        supported_targets=["domain", "ip"],
        category="whois",
    ),
    ApiDefinition(
        name="CIRCL hashlookup",
        website="https://hashlookup.circl.lu/",
        documentation="https://www.circl.lu/services/hashlookup/",
        api_key_required=False,
        free_tier="Aberto",
        rate_limit=5.0,
        supported_targets=["hash"],
        category="reputation",
    ),
    ApiDefinition(
        name="VirusTotal",
        website="https://www.virustotal.com/",
        documentation="https://developers.virustotal.com/reference",
        api_key_required=True,
        api_key_name="VIRUSTOTAL_API_KEY",
        free_tier="500 requisições/dia",
        rate_limit=4.0,
        supported_targets=["domain", "ip", "hash", "url"],
        category="reputation",
    ),
    ApiDefinition(
        name="emailrep.io",
        website="https://emailrep.io/",
        documentation="https://docs.emailrep.io/",
        api_key_required=True,
        api_key_name="EMAILREP_API_KEY",
        free_tier="Plano gratuito com limite diário",
        rate_limit=1.0,
        supported_targets=["email"],
        category="reputation",
    ),
    ApiDefinition(
        name="IPQualityScore",
        website="https://www.ipqualityscore.com/",
        documentation="https://www.ipqualityscore.com/documentation/",
        api_key_required=True,
        api_key_name="IPQUALITYSCORE_API_KEY",
        free_tier="5.000 requisições/mês",
        rate_limit=2.0,
        supported_targets=["ip", "email", "url"],
        category="reputation",
    ),
    ApiDefinition(
        name="SecurityTrails",
        website="https://securitytrails.com/",
        documentation="https://docs.securitytrails.com/",
        api_key_required=True,
        api_key_name="SECURITYTRAILS_API_KEY",
        free_tier="50 requisições/mês",
        rate_limit=1.0,
        supported_targets=["domain", "ip"],
        category="intelligence",
    ),
    ApiDefinition(
        name="Hunter.io",
        website="https://hunter.io/",
        documentation="https://hunter.io/api-documentation",
        api_key_required=True,
        api_key_name="HUNTER_API_KEY",
        free_tier="25 requisições/mês",
        rate_limit=1.0,
        supported_targets=["domain", "email"],
        category="email",
    ),
    ApiDefinition(
        name="Shodan",
        website="https://www.shodan.io/",
        documentation="https://developer.shodan.io/api",
        api_key_required=True,
        api_key_name="SHODAN_API_KEY",
        free_tier="Plano gratuito com limite mensal",
        rate_limit=1.0,
        supported_targets=["ip", "domain"],
        category="intelligence",
    ),
    ApiDefinition(
        name="Censys",
        website="https://search.censys.io/",
        documentation="https://search.censys.io/api",
        api_key_required=True,
        api_key_name="CENSYS_API_ID",
        free_tier="Plano gratuito com créditos mensais",
        rate_limit=1.0,
        supported_targets=["ip", "domain", "hash"],
        category="intelligence",
    ),
    ApiDefinition(
        name="WHOIS XML API",
        website="https://whoisxmlapi.com/",
        documentation="https://whois.whoisxmlapi.com/documentation/making-requests",
        api_key_required=True,
        api_key_name="WHOISXML_API_KEY",
        free_tier="500 consultas/mês",
        rate_limit=2.0,
        supported_targets=["domain", "ip"],
        category="whois",
    ),
    ApiDefinition(
        name="ipinfo.io",
        website="https://ipinfo.io/",
        documentation="https://ipinfo.io/developers",
        api_key_required=True,
        api_key_name="IPINFO_API_KEY",
        free_tier="50.000 requisições/mês",
        rate_limit=2.0,
        supported_targets=["ip", "domain"],
        category="geo",
    ),
    ApiDefinition(
        name="Google Safe Browsing",
        website="https://developers.google.com/safe-browsing",
        documentation="https://developers.google.com/safe-browsing/v4",
        api_key_required=True,
        api_key_name="GOOGLE_SAFE_BROWSING_API_KEY",
        free_tier="10.000 requisições/dia",
        rate_limit=2.0,
        supported_targets=["url", "domain", "ip"],
        category="reputation",
    ),
]


class ApiRegistry:
    """Registro consultável de APIs."""

    def __init__(self, definitions: list[ApiDefinition] | None = None) -> None:
        self._definitions = {d.name: d for d in (definitions or API_REGISTRY)}

    def all(self) -> list[ApiDefinition]:
        return list(self._definitions.values())

    def get(self, name: str) -> ApiDefinition | None:
        return self._definitions.get(name)

    def for_target(self, target_type: str) -> list[ApiDefinition]:
        return [d for d in self.all() if target_type in d.supported_targets]

    # ------------------------------------------------------------------ #
    def status_all(self) -> list[dict[str, Any]]:
        """Calcula o status de todas as APIs (ENABLED/NOT CONFIGURED/DISABLED)."""
        from core.secret_store import get_secret_store

        store = get_secret_store()
        rows: list[dict[str, Any]] = []
        for definition in self.all():
            rows.append(self._status(definition, store).to_dict())
        rows.sort(key=lambda r: (r["status"] != "ENABLED", r["name"].lower()))
        return rows

    def _status(self, definition: ApiDefinition, store) -> ApiStatus:
        if not definition.enabled:
            status = "DISABLED"
        elif not definition.api_key_required:
            status = "ENABLED"
        elif definition.api_key_name and store.has(definition.api_key_name):
            status = "ENABLED"
        else:
            status = "NOT CONFIGURED"
        return ApiStatus(
            name=definition.name,
            status=status,
            configured=status == "ENABLED",
            api_key_required=definition.api_key_required,
            website=definition.website,
            documentation=definition.documentation,
            free_tier=definition.free_tier,
            supported_targets=definition.supported_targets,
        )


_API_REGISTRY = ApiRegistry()


def get_api_registry() -> ApiRegistry:
    """Retorna o registro global de APIs."""
    return _API_REGISTRY
