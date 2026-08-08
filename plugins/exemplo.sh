#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Plugin Exemplo (plugins/exemplo.sh)
# ==============================================================================
PLUGIN_NAME="Exemplo Zenith Plugin"
PLUGIN_VERSION="1.0.0"
PLUGIN_AUTHOR="Pedro Atila"
PLUGIN_DESCRIPTION="Plugin demonstrativo para teste do carregador de plugins"
# ==============================================================================

plugin_run() {
    echo -e "\033[38;5;51m==============================================\033[0m"
    echo -e "🚀 EXECUTANDO PLUGIN EXEMPLO DO ZENITH PANEL"
    echo -e "\033[38;5;51m==============================================\033[0m"
    echo "Olá! Este é um plugin de exemplo carregado pela arquitetura do Zenith Panel."
    echo "Data da Execução : $(date)"
    echo "Diretório Ativo  : ${PWD}"
    echo -e "\033[38;5;46m[✓] Plugin exemplo finalizado com sucesso!\033[0m"
}
