"""Armazenamento seguro de API keys.

Prioridade de armazenamento:

1. **Windows Credential Manager** (via DPAPI) — preferencial no Windows 11.
2. **Variáveis de ambiente** — portátil (Linux/macOS/Termux/CI).
3. **``config/api_keys.json``** — apenas desenvolvimento local
   (arquivo ignorado pelo Git; permissões restritas).

Nunca imprimir secrets nos logs e nunca commitá-los.
"""

from __future__ import annotations

import json
import os
import stat
import sys
from pathlib import Path
from typing import Any

from core.constants import API_KEYS_PATH
from core.errors import ApiKeyError
from core.logger import get_logger

log = get_logger("secrets")

# Nomes canônicos de chaves suportadas (sempre UPPER_SNAKE).
SUPPORTED_KEYS: tuple[str, ...] = (
    "ABUSEIPDB_API_KEY",
    "VIRUSTOTAL_API_KEY",
    "SECURITYTRAILS_API_KEY",
    "HUNTER_API_KEY",
    "EMAILREP_API_KEY",
    "IPQUALITYSCORE_API_KEY",
    "SHODAN_API_KEY",
    "CENSYS_API_ID",
    "CENSYS_API_SECRET",
    "WHOISXML_API_KEY",
    "IPINFO_API_KEY",
    "GOOGLE_SAFE_BROWSING_API_KEY",
)

REDACTED = "[REDACTED]"


def _redact(value: str) -> str:
    return REDACTED if value else ""


def is_windows() -> bool:
    return sys.platform.startswith("win")


class SecretStore:
    """Gerencia leitura/escrita de secrets de forma segura."""

    def __init__(self, keys_path: Path | None = None) -> None:
        self.keys_path = Path(keys_path) if keys_path else API_KEYS_PATH
        self._cache: dict[str, str] | None = None

    # ------------------------------------------------------------------ #
    # Windows Credential Manager (DPAPI)
    # ------------------------------------------------------------------ #
    def _win_get(self, key: str) -> str | None:
        try:
            import ctypes

            class CREDENTIAL(ctypes.Structure):
                _fields_ = [
                    ("Flags", ctypes.c_ulong),
                    ("Type", ctypes.c_ulong),
                    ("TargetName", ctypes.c_wchar_p),
                    ("Comment", ctypes.c_wchar_p),
                    ("LastWritten", ctypes.c_longlong),
                    ("CredentialBlobSize", ctypes.c_ulong),
                    ("CredentialBlob", ctypes.POINTER(ctypes.c_ubyte)),
                    ("Persist", ctypes.c_ulong),
                    ("AttributeCount", ctypes.c_ulong),
                    ("Attributes", ctypes.c_void_p),
                    ("TargetAlias", ctypes.c_wchar_p),
                    ("UserName", ctypes.c_wchar_p),
                ]

            target = f"NEXUS:{key}"
            cred = ctypes.POINTER(CREDENTIAL)()
            advapi32 = ctypes.windll.advapi32
            ok = advapi32.CredReadW(target, 1, 0, ctypes.byref(cred))
            if ok:
                try:
                    blob = ctypes.string_at(cred.contents.CredentialBlob, cred.contents.CredentialBlobSize)
                    return blob.decode("utf-16-le") if blob else None
                finally:
                    advapi32.CredFree(cred)
            return None
        except Exception:  # noqa: BLE001 - fallback silencioso
            return None

    def _win_set(self, key: str, value: str) -> None:
        import ctypes

        target = f"NEXUS:{key}"
        blob = value.encode("utf-16-le")

        class CREDENTIAL(ctypes.Structure):
            _fields_ = [
                ("Flags", ctypes.c_ulong),
                ("Type", ctypes.c_ulong),
                ("TargetName", ctypes.c_wchar_p),
                ("Comment", ctypes.c_wchar_p),
                ("LastWritten", ctypes.c_longlong),
                ("CredentialBlobSize", ctypes.c_ulong),
                ("CredentialBlob", ctypes.POINTER(ctypes.c_ubyte)),
                ("Persist", ctypes.c_ulong),
                ("AttributeCount", ctypes.c_ulong),
                ("Attributes", ctypes.c_void_p),
                ("TargetAlias", ctypes.c_wchar_p),
                ("UserName", ctypes.c_wchar_p),
            ]

        buf = ctypes.create_string_buffer(blob)
        cred = CREDENTIAL(
            0,
            1,  # CRED_TYPE_GENERIC
            target,
            None,
            0,
            len(blob),
            ctypes.cast(buf, ctypes.POINTER(ctypes.c_ubyte)),
            2,  # CRED_PERSIST_LOCAL_MACHINE
            0,
            None,
            None,
            None,
        )
        advapi32 = ctypes.windll.advapi32
        if not advapi32.CredWriteW(ctypes.byref(cred), 0):
            raise ApiKeyError(f"Não foi possível gravar {key} no Credential Manager")

    def _win_delete(self, key: str) -> None:
        try:
            import ctypes

            ctypes.windll.advapi32.CredDeleteW(f"NEXUS:{key}", 1, 0)
        except Exception:  # noqa: BLE001
            pass

    # ------------------------------------------------------------------ #
    # Arquivo local (apenas desenvolvimento)
    # ------------------------------------------------------------------ #
    def _file_read(self) -> dict[str, Any]:
        if self._cache is not None:
            return self._cache
        if not self.keys_path.exists():
            self._cache = {}
            return self._cache
        try:
            data = json.loads(self.keys_path.read_text(encoding="utf-8"))
            self._cache = data if isinstance(data, dict) else {}
        except (json.JSONDecodeError, OSError):
            log.exception("Falha ao ler %s", self.keys_path)
            self._cache = {}
        return self._cache

    def _file_write(self, data: dict[str, Any]) -> None:
        self.keys_path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.keys_path.with_suffix(".tmp")
        tmp.write_text(json.dumps(data, indent=4), encoding="utf-8")
        # Permissões restritas (somente dono) — Unix.
        try:
            tmp.chmod(stat.S_IRUSR | stat.S_IWUSR)
        except OSError:
            pass
        tmp.replace(self.keys_path)
        self._cache = data

    # ------------------------------------------------------------------ #
    # API pública
    # ------------------------------------------------------------------ #
    def get(self, key: str) -> str | None:
        """Retorna o valor da chave ou ``None``.

        Ordem: ambiente -> Credential Manager (Windows) -> arquivo local.
        """
        key = key.strip().upper()
        env_value = os.environ.get(key)
        if env_value:
            return env_value
        if is_windows():
            win_value = self._win_get(key)
            if win_value:
                return win_value
        return self._file_read().get(key)

    def has(self, key: str) -> bool:
        return bool(self.get(key))

    def set(self, key: str, value: str, backend: str | None = None) -> None:
        """Grava uma chave. ``backend``: auto | env | file | credential_manager."""
        key = key.strip().upper()
        if key not in SUPPORTED_KEYS:
            raise ApiKeyError(
                f"Chave '{key}' não suportada. Use uma de: {', '.join(SUPPORTED_KEYS)}"
            )
        value = value.strip()
        if not value:
            raise ApiKeyError("Valor da chave não pode ser vazio.")
        backend = (backend or "auto").lower()
        if backend in ("auto", "credential_manager", "cm") and is_windows():
            self._win_set(key, value)
            log.info("API key %s armazenada no Windows Credential Manager.", key)
        elif backend in ("auto", "file") :
            data = self._file_read()
            data[key] = value
            self._file_write(data)
            log.warning(
                "API key %s armazenada em %s (apenas desenvolvimento).", key, self.keys_path
            )
        elif backend in ("env",):
            raise ApiKeyError(
                "Não é possível gravar em variável de ambiente de forma persistente; "
                "defina manualmente no SO."
            )
        else:
            raise ApiKeyError(f"Backend desconhecido: {backend}")

    def delete(self, key: str) -> None:
        key = key.strip().upper()
        if is_windows():
            self._win_delete(key)
        data = self._file_read()
        if key in data:
            data.pop(key)
            self._file_write(data)
        log.info("API key %s removida.", key)

    def list(self) -> list[dict[str, Any]]:
        """Lista chaves conhecidas, mostrando apenas metadados (nunca valores)."""
        file_data = self._file_read()
        rows: list[dict[str, Any]] = []
        for key in SUPPORTED_KEYS:
            rows.append(
                {
                    "name": key,
                    "configured": self.get(key) is not None,
                    "source": (
                        "environment"
                        if os.environ.get(key)
                        else "credential_manager"
                        if is_windows() and self._win_get(key)
                        else "file"
                        if file_data.get(key)
                        else None
                    ),
                }
            )
        return rows


_SECRET_STORE = SecretStore()


def get_secret_store() -> SecretStore:
    """Retorna o store global de secrets."""
    return _SECRET_STORE
