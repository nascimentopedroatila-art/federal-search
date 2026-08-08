#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo de Cores e Temas (core/colors.sh)
# ==============================================================================
# Gerencia paletas de cores ANSI e temas visuais do ZENITH PANEL.
# Compatível com Termux e terminais Linux padrão sem necessidade de root.
# ==============================================================================

# Cores ANSI básicas (imutáveis)
export C_RESET="\033[0m"
export C_BOLD="\033[1m"
export C_DIM="\033[2m"
export C_UNDERLINE="\033[4m"
export C_BLINK="\033[5m"
export C_REVERSE="\033[7m"

export C_RED="\033[38;5;196m"
export C_GREEN="\033[38;5;46m"
export C_YELLOW="\033[38;5;226m"
export C_BLUE="\033[38;5;33m"
export C_MAGENTA="\033[38;5;201m"
export C_CYAN="\033[38;5;51m"
export C_WHITE="\033[38;5;231m"
export C_GRAY="\033[38;5;242m"
export C_DARK_GRAY="\033[38;5;238m"

# Cores Semânticas do Sistema (sucesso, aviso, erro, informação)
export C_SUCCESS="\033[38;5;46m"
export C_WARN="\033[38;5;214m"
export C_ERROR="\033[38;5;196m"
export C_INFO="\033[38;5;39m"

# Paleta ativa do tema (valores padrão - Tema ZENITH)
export C_PRIMARY="${C_CYAN}"
export C_SECONDARY="${C_BLUE}"
export C_ACCENT="${C_MAGENTA}"
export C_TEXT="${C_WHITE}"
export C_BORDER="${C_CYAN}"
export C_MUTED="${C_GRAY}"

# Função para aplicar um tema de cores específico
colors_set_theme() {
    local theme_name="${1:-ZENITH}"
    theme_name=$(echo "${theme_name}" | tr '[:lower:]' '[:upper:]')

    case "${theme_name}" in
        "ZENITH")
            # Ciano Futurista (Tema Oficial Zenith)
            C_PRIMARY="\033[38;5;51m"
            C_SECONDARY="\033[38;5;39m"
            C_ACCENT="\033[38;5;201m"
            C_TEXT="\033[38;5;231m"
            C_BORDER="\033[38;5;51m"
            C_MUTED="\033[38;5;244m"
            ;;
        "CYBER")
            # Cyberpunk - Magenta e Neon Yellow
            C_PRIMARY="\033[38;5;201m"
            C_SECONDARY="\033[38;5;51m"
            C_ACCENT="\033[38;5;226m"
            C_TEXT="\033[38;5;231m"
            C_BORDER="\033[38;5;201m"
            C_MUTED="\033[38;5;242m"
            ;;
        "MATRIX")
            # Verde Hacker Matrix
            C_PRIMARY="\033[38;5;46m"
            C_SECONDARY="\033[38;5;28m"
            C_ACCENT="\033[38;5;154m"
            C_TEXT="\033[38;5;231m"
            C_BORDER="\033[38;5;46m"
            C_MUTED="\033[38;5;240m"
            ;;
        "MINIMAL")
            # Minimalista - Branco e Cinza
            C_PRIMARY="\033[38;5;231m"
            C_SECONDARY="\033[38;5;250m"
            C_ACCENT="\033[38;5;255m"
            C_TEXT="\033[38;5;231m"
            C_BORDER="\033[38;5;245m"
            C_MUTED="\033[38;5;240m"
            ;;
        "DARK")
            # Sombrio / Stealth
            C_PRIMARY="\033[38;5;248m"
            C_SECONDARY="\033[38;5;242m"
            C_ACCENT="\033[38;5;160m"
            C_TEXT="\033[38;5;252m"
            C_BORDER="\033[38;5;240m"
            C_MUTED="\033[38;5;238m"
            ;;
        "BLUE")
            # Azul Profundo
            C_PRIMARY="\033[38;5;33m"
            C_SECONDARY="\033[38;5;27m"
            C_ACCENT="\033[38;5;81m"
            C_TEXT="\033[38;5;231m"
            C_BORDER="\033[38;5;33m"
            C_MUTED="\033[38;5;242m"
            ;;
        "GREEN")
            # Esmeralda
            C_PRIMARY="\033[38;5;42m"
            C_SECONDARY="\033[38;5;36m"
            C_ACCENT="\033[38;5;84m"
            C_TEXT="\033[38;5;231m"
            C_BORDER="\033[38;5;42m"
            C_MUTED="\033[38;5;242m"
            ;;
        "PURPLE")
            # Roxo Nebulosa
            C_PRIMARY="\033[38;5;141m"
            C_SECONDARY="\033[38;5;99m"
            C_ACCENT="\033[38;5;213m"
            C_TEXT="\033[38;5;231m"
            C_BORDER="\033[38;5;141m"
            C_MUTED="\033[38;5;242m"
            ;;
        *)
            # Padrão fallback - ZENITH
            C_PRIMARY="\033[38;5;51m"
            C_SECONDARY="\033[38;5;39m"
            C_ACCENT="\033[38;5;201m"
            C_TEXT="\033[38;5;231m"
            C_BORDER="\033[38;5;51m"
            C_MUTED="\033[38;5;244m"
            ;;
    esac

    export C_PRIMARY C_SECONDARY C_ACCENT C_TEXT C_BORDER C_MUTED
}

# Remove códigos de formatação ANSI para cálculos de comprimento de string
colors_strip_ansi() {
    echo -e "$1" | sed -E 's/\x1B\[[0-9;]*[mK]//g'
}
