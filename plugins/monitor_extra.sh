#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Plugin Monitor Extra (plugins/monitor_extra.sh)
# ==============================================================================
PLUGIN_NAME="Monitor Avançado de Carga"
PLUGIN_VERSION="1.0.2"
PLUGIN_AUTHOR="Zenith Community"
PLUGIN_DESCRIPTION="Métricas adicionais de I/O de disco e conexões TCP ativas"
# ==============================================================================

plugin_run() {
    echo -e "\033[38;5;51m==============================================\033[0m"
    echo -e "📊 PLUGIN MONITOR EXTRA - CARGA & REDE"
    echo -e "\033[38;5;51m==============================================\033[0m"
    echo "Top 5 Processos em Uso de Memória:"
    if command -v ps >/dev/null 2>&1; then
        ps aux --sort=-%mem 2>/dev/null | head -n 6 || ps -ef 2>/dev/null | head -n 6
    fi
    echo ""
    echo "Conexões TCP Estabelecidas:"
    if command -v ss >/dev/null 2>&1; then
        ss -tn state established 2>/dev/null | head -n 10
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tn 2>/dev/null | grep ESTABLISHED | head -n 10
    else
        echo "Ferramenta ss/netstat indisponível."
    fi
    echo -e "\033[38;5;46m[✓] Leitura de monitor avançado concluída!\033[0m"
}
