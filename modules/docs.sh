#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo de Documentação Integrada (modules/docs.sh)
# ==============================================================================
# Leitor de documentação Markdown interativo no terminal. Permite consultar
# INSTALL, USAGE, COMMANDS, CONFIG, PLUGINS, AI, BACKUP, SECURITY e README.md.
# ==============================================================================

# Exibe arquivo Markdown usando paginador ou cat
docs_view_file() {
    local filepath="$1"
    local title="$2"
    ui_header "${title}"
    if [ -f "${filepath}" ]; then
        cat "${filepath}"
    else
        ui_msg_error "Arquivo de documentação não encontrado: ${filepath}"
    fi
    echo ""
}

docs_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO DOCUMENTAÇÃO INTEGRADA (19)"
        echo -e "  ${C_BOLD}1${C_RESET} │ 📥 Instalação (INSTALL.md)"
        echo -e "  ${C_BOLD}2${C_RESET} │ 🚀 Guia de Uso Geral (USAGE.md)"
        echo -e "  ${C_BOLD}3${C_RESET} │ ⌨️  Comandos do Sistema (COMMANDS.md)"
        echo -e "  ${C_BOLD}4${C_RESET} │ ⚙️  Configuração Persistente (CONFIG.md)"
        echo -e "  ${C_BOLD}5${C_RESET} │ 🧩 Sistema de Plugins (PLUGINS.md)"
        echo -e "  ${C_BOLD}6${C_RESET} │ 🤖 Inteligência Artificial - Zenith AI (AI.md)"
        echo -e "  ${C_BOLD}7${C_RESET} │ 💾 Sistema de Backup e Restauração (BACKUP.md)"
        echo -e "  ${C_BOLD}8${C_RESET} │ 🔐 Segurança Defensiva e Hardening (SECURITY.md)"
        echo -e "  ${C_BOLD}9${C_RESET} │ 🩺 Solução de Problemas (TROUBLESHOOTING.md)"
        echo -e "  ${C_BOLD}10${C_RESET}│ 🤝 Como Contribuir (CONTRIBUTING.md)"
        echo -e "  ${C_BOLD}11${C_RESET}│ 📖 Ver README.md Principal"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-11]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) docs_view_file "docs/INSTALL.md" "GUIA DE INSTALAÇÃO"; ui_pause ;;
            2) docs_view_file "docs/USAGE.md" "GUIA DE USO DO ZENITH"; ui_pause ;;
            3) docs_view_file "docs/COMMANDS.md" "REFERÊNCIA DE COMANDOS"; ui_pause ;;
            4) docs_view_file "docs/CONFIG.md" "ARQUIVOS DE CONFIGURAÇÃO"; ui_pause ;;
            5) docs_view_file "docs/PLUGINS.md" "DESENVOLVIMENTO DE PLUGINS"; ui_pause ;;
            6) docs_view_file "docs/AI.md" "DOCUMENTAÇÃO ZENITH AI"; ui_pause ;;
            7) docs_view_file "docs/BACKUP.md" "POLÍTICA DE BACKUP"; ui_pause ;;
            8) docs_view_file "docs/SECURITY.md" "POLÍTICA E USO DE SEGURANÇA"; ui_pause ;;
            9) docs_view_file "docs/TROUBLESHOOTING.md" "SOLUÇÃO DE PROBLEMAS"; ui_pause ;;
            10) docs_view_file "docs/CONTRIBUTING.md" "GUIA DE CONTRIBUIÇÃO"; ui_pause ;;
            11) docs_view_file "README.md" "README DO PROJETO"; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
