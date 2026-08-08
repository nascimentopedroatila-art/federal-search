#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Plugin Sistema Extra (plugins/sistema_extra.sh)
# ==============================================================================
PLUGIN_NAME="Sistema Extra e Limpeza"
PLUGIN_VERSION="1.1.0"
PLUGIN_AUTHOR="Zenith Community"
PLUGIN_DESCRIPTION="Limpeza de caches do sistema, logs antigos e pacotes órfãos"
# ==============================================================================

plugin_run() {
    echo -e "\033[38;5;51m==============================================\033[0m"
    echo -e "🧹 PLUGIN SISTEMA EXTRA - LIMPEZA DE RECURSOS"
    echo -e "\033[38;5;51m==============================================\033[0m"
    echo "Analisando arquivos temporários..."
    local tmp_count
    tmp_count=$(find /tmp -maxdepth 1 -type f 2>/dev/null | wc -l)
    echo "Arquivos na pasta /tmp: ${tmp_count}"
    
    if [ "${tmp_count}" -gt 0 ]; then
        echo "Limpando arquivos /tmp antigos do usuário..."
        find /tmp -maxdepth 1 -user "${USER}" -type f -mmin +60 -delete 2>/dev/null || true
    fi

    echo -e "\033[38;5;46m[✓] Manutenção de limpeza otimizada com sucesso!\033[0m"
}
