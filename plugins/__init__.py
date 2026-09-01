"""Plugins do NEXUS.

Cada subpacote (``phone/``, ``email/``, ``username/``, ``domain/``,
``ip/``, ``dns/``, ``hash/``, ``network/``) contém um módulo
``plugin.py`` com uma subclasse de ``NexusPlugin``. O Plugin Manager
descobre tudo automaticamente — nenhuma alteração no núcleo é
necessária para adicionar integrações.
"""

from __future__ import annotations
