#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo de Interface do Usuário (core/ui.sh)
# ==============================================================================
# Responsável por banners, menus, caixas ASCII, mensagens e navegação do terminal.
# ==============================================================================

# Limpa a tela do terminal
ui_clear() {
    clear 2>/dev/null || echo -e "\033c"
}

# Exibe o Banner ASCII principal
ui_banner() {
    echo -e "${C_PRIMARY}"
    cat << 'EOF'
     ██████████  ████████  █████  ███  ███████  █████████  ███   ███
     █       ██  ███       █████  ███    ███    ███    ██  ███   ███
          ████   ████████  ███ ██ ███    ███    █████████  █████████
        ████     ███       ███  █████    ███    ███    ██  ███   ███
      █████████  ████████  ███   ████  ███████  ███    ██  ███   ███
EOF
    echo -e "${C_SECONDARY}                 ⚡ ULTIMATE TERMUX TOOLKIT v${ZENITH_VERSION} ⚡${C_RESET}"
    echo ""
}

# Exibe o Menu Principal completo com a caixa ASCII profissional
ui_main_menu() {
    echo -e "${C_BORDER}╔══════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}                                              ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_PRIMARY}${C_BOLD}          Z E N I T H   P A N E L             ${C_RESET}${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}                                              ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_SECONDARY}            ULTIMATE TERMUX TOOLKIT           ${C_RESET}${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}                                              ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╠══════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}01${C_RESET} │ 🖥️  SISTEMA                             ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}02${C_RESET} │ 📊  MONITOR                             ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}03${C_RESET} │ 📱  ANDROID                             ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}04${C_RESET} │ 🌐  REDE                                ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}05${C_RESET} │ 🐧  LINUX                               ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}06${C_RESET} │ 🤖  INTELIGÊNCIA ARTIFICIAL             ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}07${C_RESET} │ 🛠️  FERRAMENTAS                         ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}08${C_RESET} │ 📦  GIT / GITHUB                        ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}09${C_RESET} │ ⚙️  AUTOMAÇÃO                           ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}10${C_RESET} │ 🗄️  SERVIDORES                          ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}11${C_RESET} │ 🎮  GAMING                              ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}12${C_RESET} │ 🔐  SEGURANÇA DEFENSIVA                 ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}13${C_RESET} │ 🔎  CONSULTAS / APIs                    ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}14${C_RESET} │ 📂  ARQUIVOS                            ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}15${C_RESET} │ 🎨  PERSONALIZAÇÃO                      ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}16${C_RESET} │ 📦  GERENCIADOR DE PACOTES              ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}17${C_RESET} │ 💾  BACKUP                              ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}18${C_RESET} │ 🔧  CONFIGURAÇÕES                       ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}19${C_RESET} │ 📚  DOCUMENTAÇÃO                        ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}20${C_RESET} │ 🧩  PLUGINS                             ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}21${C_RESET} │ 🔄  ATUALIZAR                           ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}22${C_RESET} │ 🩺  DIAGNÓSTICO                         ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}23${C_RESET} │ ℹ️  SOBRE                               ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}║${C_RESET}  ${C_BOLD}0${C_RESET} │ 🚪  SAIR                                ${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╚══════════════════════════════════════════════╝${C_RESET}"
}

# Exibe um cabeçalho formatado em caixa ASCII para submenus
ui_header() {
    local title="$1"
    local len=${#title}
    local pad_len=$(( (42 - len) / 2 ))
    local pad_left=""
    local pad_right=""

    for ((i=0; i<pad_len; i++)); do
        pad_left="${pad_left} "
    done
    pad_right="${pad_left}"
    if [ $(( (len + (pad_len * 2)) )) -lt 42 ]; then
        pad_right="${pad_right} "
    fi

    echo -e "${C_BORDER}╔══════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BORDER}║${C_PRIMARY}${C_BOLD}  ${pad_left}${title}${pad_right}  ${C_RESET}${C_BORDER}║${C_RESET}"
    echo -e "${C_BORDER}╚══════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

# Separador visual
ui_separator() {
    echo -e "${C_MUTED}──────────────────────────────────────────────${C_RESET}"
}

# Mensagens padronizadas do sistema
ui_msg_success() {
    echo -e "${C_SUCCESS}[✓] Operação concluída: ${1}${C_RESET}"
}

ui_msg_warn() {
    echo -e "${C_WARN}[!] Aviso: ${1}${C_RESET}"
}

ui_msg_error() {
    echo -e "${C_ERROR}[×] Erro: ${1}${C_RESET}"
}

ui_msg_info() {
    echo -e "${C_INFO}[•] Informação: ${1}${C_RESET}"
}

ui_msg_exec() {
    echo -e "${C_PRIMARY}[>] Executando: ${1}${C_RESET}"
}

# Pausa a execução aguardando ENTER para voltar ao menu
ui_pause() {
    echo ""
    echo -e -n "${C_MUTED}Pressione [ENTER] para continuar...${C_RESET}"
    read -r
}

# Exibe prompt padronizado de comando
ui_prompt() {
    echo -e -n "${C_PRIMARY}${ZENITH_USER_NAME}@zenith${C_RESET}:${C_SECONDARY}~# ${C_RESET}"
}
