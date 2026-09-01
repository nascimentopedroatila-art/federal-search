"""Exceções do NEXUS.

Todas as exceções do projeto herdam de :class:`NexusError`, o que
permite ao CLI e à engine tratarem erros de forma uniforme.
"""

from __future__ import annotations


class NexusError(Exception):
    """Erro base de todo o NEXUS."""


class ConfigurationError(NexusError):
    """Erro de configuração (arquivo inválido, campo ausente, ...)."""


class PluginError(NexusError):
    """Erro no carregamento ou execução de um plugin."""


class PluginNotFoundError(PluginError):
    """Plugin solicitado não existe."""


class PluginRegistrationError(PluginError):
    """Falha ao registrar um plugin no gerenciador."""


class TargetError(NexusError):
    """Alvo inválido ou tipo não suportado."""


class ApiKeyError(NexusError):
    """Chave de API ausente, inválida ou com armazenamento com erro."""


class HttpError(NexusError):
    """Falha em requisições HTTP da engine."""


class ReportError(NexusError):
    """Falha na geração de relatórios."""


class DatabaseError(NexusError):
    """Falha de banco de dados."""


class RateLimitError(NexusError):
    """Limite de requisições atingido (respeitado internamente)."""
