"""Diagnóstico local de rede e sistema (offline, sem privilégios).

Coleta informações da própria máquina: interfaces, gateway, DNS
configurado, conectividade básica e recursos do sistema. Não realiza
qualquer exploração de máquinas remotas.
"""

from __future__ import annotations

import platform
import socket
import sys
from typing import Any

try:
    import psutil
except ImportError:  # pragma: no cover - dependência opcional em runtime mínimo
    psutil = None


def diagnose_local() -> dict[str, Any]:
    """Retorna o diagnóstico completo da máquina local."""
    report: dict[str, Any] = {}
    report["hostname"] = socket.gethostname()
    report["platform"] = platform.platform()
    report["system"] = platform.system()
    report["python"] = sys.version.split()[0]
    report.update(_network_info())
    report.update(_system_info())
    return report


def _network_info() -> dict[str, Any]:
    info: dict[str, Any] = {"interfaces": [], "default_gateway": None, "dns_servers": None}
    if psutil is not None:
        try:
            addrs = psutil.net_if_addrs()
            stats = psutil.net_if_stats()
            for name, addresses in addrs.items():
                is_up = bool(stats.get(name) and stats[name].isup)
                entries = []
                for addr in addresses:
                    if addr.family == socket.AF_INET:
                        entries.append({"family": "IPv4", "address": addr.address, "netmask": addr.netmask})
                    elif addr.family == socket.AF_INET6:
                        entries.append({"family": "IPv6", "address": addr.address})
                if entries:
                    info["interfaces"].append({"name": name, "up": is_up, "addresses": entries})
        except Exception:  # noqa: BLE001
            pass

    info["default_gateway"] = _default_gateway()
    info["dns_servers"] = _configured_dns()
    return info


def _default_gateway() -> str | None:
    try:
        if platform.system() == "Linux":
            with open("/proc/net/route", encoding="utf-8") as fh:
                for line in fh.readlines()[1:]:
                    parts = line.split()
                    if len(parts) >= 3 and parts[1] == "00000000":
                        gateway_hex = parts[2]
                        return socket.inet_ntoa(bytes.fromhex(gateway_hex)[::-1])
        elif platform.system() == "Windows":
            output = _run("ipconfig")
            for line in output.splitlines():
                stripped = line.strip()
                if stripped.lower().startswith("default gateway"):
                    value = stripped.split(":", 1)[1].strip()
                    if value and value.lower() != "gateway padrão":
                        return value
        return None
    except Exception:  # noqa: BLE001
        return None


def _configured_dns() -> list[str] | None:
    servers: list[str] = []
    try:
        if platform.system() == "Linux":
            with open("/etc/resolv.conf", encoding="utf-8") as fh:
                for line in fh:
                    parts = line.split()
                    if len(parts) >= 2 and parts[0] == "nameserver":
                        servers.append(parts[1])
        elif platform.system() == "Windows":
            output = _run("ipconfig /all")
            for line in output.splitlines():
                stripped = line.strip()
                if stripped.lower().startswith("dns servers"):
                    value = stripped.split(":", 1)[1].strip()
                    if value:
                        servers.append(value)
                elif stripped and stripped[0].isdigit() and "." in stripped and servers:
                    servers.append(stripped)
        return servers[:5] or None
    except Exception:  # noqa: BLE001
        return None


def _system_info() -> dict[str, Any]:
    info: dict[str, Any] = {}
    if psutil is not None:
        try:
            vm = psutil.virtual_memory()
            info["memory_total_gb"] = round(vm.total / (1024**3), 2)
            info["memory_used_gb"] = round(vm.used / (1024**3), 2)
            info["memory_percent"] = vm.percent
            info["cpu_count"] = psutil.cpu_count()
            info["cpu_percent"] = psutil.cpu_percent(interval=0.2)
            info["uptime_hours"] = round(psutil.boot_time() and (__import__("time").time() - psutil.boot_time()) / 3600, 1)
        except Exception:  # noqa: BLE001
            pass
    return info


def _run(command: str) -> str:
    import subprocess

    try:
        result = subprocess.run(
            command, shell=True, capture_output=True, text=True, timeout=10, check=False
        )
        return result.stdout or result.stderr or ""
    except Exception:  # noqa: BLE001
        return ""
