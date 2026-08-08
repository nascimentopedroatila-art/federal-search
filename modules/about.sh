#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Sobre o Sistema (modules/about.sh)
# ==============================================================================
# Informações gerais sobre o projeto, licença, arquitetura modular e créditos.
# ==============================================================================

about_menu() {
    ui_clear
    ui_banner
    ui_header "SOBRE O ZENITH PANEL v1.0.0"

    echo -e "${C_PRIMARY}${C_BOLD}ULTIMATE TERMUX TOOLKIT & MEGA PAINEL MODULAR${C_RESET}"
    echo -e "O ZENITH PANEL é uma plataforma avançada para administração, monitoramento,"
    echo -e "automação, IA, segurança defensiva e personalização para Termux e Linux."
    echo ""
    echo -e "${C_BOLD}Destaques Arquiteturais:${C_RESET}"
    echo -e "  • ${C_SUCCESS}Modularidade Completa${C_RESET}: 23 módulos independentes e carregados de forma limpa."
    echo -e "  • ${C_SUCCESS}Sem Exigência de Root${C_RESET}: Operacional sem root no Termux Android e Linux."
    echo -e "  • ${C_SUCCESS}Multi-Provedor de IA${C_RESET}: Suporte a OpenAI, Anthropic, Gemini, Groq e Ollama."
    echo -e "  • ${C_SUCCESS}Sistema de Plugins${C_RESET}: Extensibilidade via scripts na pasta plugins/."
    echo -e "  • ${C_SUCCESS}Segurança Defensiva${C_RESET}: Zero malware, zero exploits, sem comandos destrutivos ocultos."
    echo ""
    echo -e "${C_BOLD}Informações de Licença:${C_RESET}"
    echo -e "  Licença : MIT License (Código Aberto)"
    echo -e "  Ano     : 2026"
    echo -e "  Versão  : 1.0.0 (Estável)"
    echo ""
    ui_separator
    echo -e "${C_MUTED}Pressione [ENTER] para retornar ao menu principal...${C_RESET}"
    read -r
}
