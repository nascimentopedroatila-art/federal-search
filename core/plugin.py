"""Classe base e metadados de plugins do NEXUS.

Qualquer módulo Python dentro de ``plugins/`` (ou registrado via
``PluginManager.register``) que exporte uma subclasse de
:class:`NexusPlugin` é descoberto automaticamente. Adicionar um novo
plugin **não** exige alterações no núcleo.
"""

from __future__ import annotations

import abc
from dataclasses import dataclass
from typing import Any, ClassVar

from core.constants import Status


@dataclass
class PluginResult:
    """Resultado normalizado emitido por um plugin."""

    result_type: str
    data: dict[str, Any] | list[dict[str, Any]]
    source: str
    confidence: str = "LOW"
    status: str = Status.SUCCESS.value
    raw: dict[str, Any] | None = None
    duration: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        return {
            "result_type": self.result_type,
            "data": self.data,
            "source": self.source,
            "confidence": self.confidence,
            "status": self.status,
            "raw": self.raw,
            "duration": self.duration,
        }


class NexusPlugin(abc.ABC):
    """Interface que todo plugin deve implementar."""

    # --- Metadados declarativos -------------------------------------
    name: ClassVar[str] = "Unnamed Plugin"
    version: ClassVar[str] = "0.1"
    description: ClassVar[str] = ""
    author: ClassVar[str] = "NEXUS Project"
    target_types: ClassVar[list[str]] = ["domain"]
    requires_api_key: ClassVar[str | None] = None  # None ou nome da chave
    rate_limit: ClassVar[float] = 5.0  # requisições por segundo
    timeout: ClassVar[float] = 15.0
    cache_ttl: ClassVar[int] = 86400  # segundos; 0 = não usar cache
    enabled: ClassVar[bool] = True

    # --- Estado por execução -----------------------------------------
    def __init__(self) -> None:
        self._session: Any = None

    # ------------------------------------------------------------------ #
    @abc.abstractmethod
    async def execute(self, target: str, context: dict[str, Any] | None = None) -> list[PluginResult]:
        """Executa o plugin contra o alvo e retorna resultados.

        Deve ser resiliente: em caso de erro, retornar um
        ``PluginResult`` com ``status=ERROR`` em vez de levantar
        exceção (a engine também captura exceções como segurança).
        """
        raise NotImplementedError

    # ------------------------------------------------------------------ #
    # Hooks opcionais
    # ------------------------------------------------------------------ #
    async def setup(self) -> None:
        """Hook opcional executado uma vez antes do scan (criar sessões, etc.)."""
        return None

    async def teardown(self) -> None:
        """Hook opcional executado ao final do scan (fechar recursos)."""
        return None

    # ------------------------------------------------------------------ #
    # Utilitários compartilhados
    # ------------------------------------------------------------------ #
    @property
    def requires_api_key_name(self) -> str | None:
        return self.requires_api_key

    def check_api_key(self, context: dict[str, Any] | None = None) -> bool:
        """True se o plugin pode operar (key presente ou não necessária)."""
        if not self.requires_api_key:
            return True
        store = (context or {}).get("secret_store")
        if store is None:
            from core.secret_store import get_secret_store

            store = get_secret_store()
        return store.has(self.requires_api_key)

    def new_result(
        self,
        result_type: str,
        data: Any,
        source: str,
        confidence: str = "LOW",
        raw: dict[str, Any] | None = None,
    ) -> PluginResult:
        return PluginResult(
            result_type=result_type,
            data=data,
            source=source,
            confidence=confidence,
            raw=raw,
        )

    def __repr__(self) -> str:  # pragma: no cover - trivial
        return f"<{self.__class__.__name__} name={self.name!r} v{self.version}>"
