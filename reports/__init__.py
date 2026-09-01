"""Geradores de relatórios do NEXUS.

Formatos suportados: JSON, CSV, HTML e TXT.
"""

from __future__ import annotations

from reports.base import ReportGenerator, ReportRenderError

__all__ = ["ReportGenerator", "ReportRenderError"]
