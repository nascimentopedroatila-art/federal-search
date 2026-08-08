#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Gerenciador de Pacotes (modules/packages.sh)
# ==============================================================================
# Prioriza o gerenciador oficial do Termux ('pkg') e oferece fallback limpo
# para sistemas Debian/Ubuntu/Arch/Alpine (apt, pacman, apk).
# ==============================================================================

packages_detect_manager() {
    if [ "${ZENITH_IS_TERMUX}" = true ] && check_command pkg; then
        echo "pkg"
    elif check_command apt-get; then
        echo "apt-get"
    elif check_command apt; then
        echo "apt"
    elif check_command pacman; then
        echo "pacman"
    elif check_command apk; then
        echo "apk"
    else
        echo "none"
    fi
}

# 1. Atualizar lista e pacotes do sistema
packages_update() {
    ui_header "ATUALIZAR PACOTES DO SISTEMA"
    local mgr
    mgr="$(packages_detect_manager)"
    ui_msg_exec "Executando atualização usando '${mgr}'..."

    case "${mgr}" in
        pkg)
            pkg update -y && pkg upgrade -y
            ;;
        apt-get|apt)
            sudo apt-get update && sudo apt-get upgrade -y 2>/dev/null || apt-get update
            ;;
        pacman)
            sudo pacman -Syu --noconfirm 2>/dev/null || pacman -Syu
            ;;
        apk)
            apk update && apk upgrade
            ;;
        *)
            ui_msg_error "Nenhum gerenciador de pacotes compatível detectado."
            return
            ;;
    esac
    echo ""
    ui_msg_success "Processo de atualização finalizado."
}

# 2. Procurar Pacote
packages_search() {
    ui_header "PROCURAR PACOTE NO REPOSITÓRIO"
    local mgr
    mgr="$(packages_detect_manager)"
    echo -e -n "${C_PRIMARY}Digite o nome ou palavra-chave (ex: python, git, node): ${C_RESET}"
    read -r query
    [ -z "${query}" ] && return

    ui_msg_exec "Procurando por '${query}' via ${mgr}..."
    case "${mgr}" in
        pkg) pkg search "${query}" 2>/dev/null | head -n 30 ;;
        apt-get|apt) apt-cache search "${query}" 2>/dev/null | head -n 30 ;;
        pacman) pacman -Ss "${query}" 2>/dev/null | head -n 30 ;;
        apk) apk search "${query}" 2>/dev/null | head -n 30 ;;
        *) ui_msg_error "Gerenciador indisponível." ;;
    esac
    echo ""
    ui_msg_success "Pesquisa de pacotes concluída."
}

# 3. Instalar Pacote
packages_install() {
    ui_header "INSTALAR NOVO PACOTE"
    local mgr
    mgr="$(packages_detect_manager)"
    echo -e -n "${C_PRIMARY}Nome exato do pacote a instalar (ex: htop, nmap, tigervnc): ${C_RESET}"
    read -r pkg_name
    [ -z "${pkg_name}" ] && return

    ui_msg_exec "Instalando '${pkg_name}' via ${mgr}..."
    case "${mgr}" in
        pkg) pkg install -y "${pkg_name}" ;;
        apt-get|apt) sudo apt-get install -y "${pkg_name}" 2>/dev/null || apt-get install -y "${pkg_name}" ;;
        pacman) sudo pacman -S --noconfirm "${pkg_name}" 2>/dev/null || pacman -S "${pkg_name}" ;;
        apk) apk add "${pkg_name}" ;;
        *) ui_msg_error "Gerenciador indisponível." ;;
    esac
    echo ""
    if check_command "${pkg_name}"; then
        ui_msg_success "Pacote '${pkg_name}' instalado e operacional no PATH."
    else
        ui_msg_info "Comando finalizado."
    fi
}

# 4. Remover Pacote
packages_remove() {
    ui_header "REMOVER PACOTE INSTALADO"
    local mgr
    mgr="$(packages_detect_manager)"
    echo -e -n "${C_PRIMARY}Nome do pacote para remover: ${C_RESET}"
    read -r pkg_name
    [ -z "${pkg_name}" ] && return

    if utils_confirm "Confirma a remoção do pacote '${pkg_name}'?"; then
        ui_msg_exec "Removendo '${pkg_name}'..."
        case "${mgr}" in
            pkg) pkg uninstall -y "${pkg_name}" ;;
            apt-get|apt) sudo apt-get remove -y "${pkg_name}" 2>/dev/null || apt-get remove -y "${pkg_name}" ;;
            pacman) sudo pacman -R --noconfirm "${pkg_name}" 2>/dev/null || pacman -R "${pkg_name}" ;;
            apk) apk del "${pkg_name}" ;;
            *) ui_msg_error "Gerenciador indisponível." ;;
        esac
        ui_msg_success "Processo de desinstalação finalizado."
    fi
}

# 5. Reinstalar Pacote
packages_reinstall() {
    ui_header "REINSTALAR PACOTE"
    local mgr
    mgr="$(packages_detect_manager)"
    echo -e -n "${C_PRIMARY}Nome do pacote a reinstalar: ${C_RESET}"
    read -r pkg_name
    [ -z "${pkg_name}" ] && return

    ui_msg_exec "Reinstalando '${pkg_name}' via ${mgr}..."
    case "${mgr}" in
        pkg) pkg reinstall -y "${pkg_name}" ;;
        apt-get|apt) sudo apt-get install --reinstall -y "${pkg_name}" 2>/dev/null || apt-get install --reinstall -y "${pkg_name}" ;;
        pacman) sudo pacman -S --noconfirm "${pkg_name}" 2>/dev/null || pacman -S "${pkg_name}" ;;
        apk) apk fix "${pkg_name}" ;;
        *) ui_msg_error "Gerenciador indisponível." ;;
    esac
    ui_msg_success "Reinstalação de '${pkg_name}' concluída."
}

# 6. Listar Pacotes Instalados
packages_list_installed() {
    ui_header "PACOTES INSTALADOS NO SISTEMA"
    local mgr
    mgr="$(packages_detect_manager)"
    case "${mgr}" in
        pkg) pkg list-installed 2>/dev/null | head -n 35 ;;
        apt-get|apt) dpkg -l 2>/dev/null | grep "^ii" | head -n 35 ;;
        pacman) pacman -Q 2>/dev/null | head -n 35 ;;
        apk) apk info 2>/dev/null | head -n 35 ;;
        *) echo "Desconhecido." ;;
    esac
    echo ""
    ui_msg_info "Mostrando os 35 primeiros resultados."
}

# 7. Ver Informações do Pacote
packages_show_info() {
    ui_header "INFORMAÇÕES DE PACOTE"
    local mgr
    mgr="$(packages_detect_manager)"
    echo -e -n "${C_PRIMARY}Nome do pacote: ${C_RESET}"
    read -r p_name
    [ -z "${p_name}" ] && return

    case "${mgr}" in
        pkg) pkg show "${p_name}" 2>/dev/null || pkg info "${p_name}" 2>/dev/null ;;
        apt-get|apt) apt-cache show "${p_name}" 2>/dev/null | head -n 25 ;;
        pacman) pacman -Qi "${p_name}" 2>/dev/null || pacman -Si "${p_name}" 2>/dev/null ;;
        apk) apk info -d "${p_name}" 2>/dev/null ;;
        *) ui_msg_error "Gerenciador indisponível." ;;
    esac
    echo ""
}

# Submenu principal do Módulo Pacotes
packages_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO GERENCIADOR DE PACOTES"
        local cur_mgr
        cur_mgr="$(packages_detect_manager)"
        echo -e "Gerenciador oficial prioritário: ${C_SUCCESS}${cur_mgr}${C_RESET}"
        echo ""
        echo -e "  ${C_BOLD}1${C_RESET} │ 🔄 Atualizar Lista e Repositórios (Update & Upgrade)"
        echo -e "  ${C_BOLD}2${C_RESET} │ 🔍 Procurar Pacote no Repositório"
        echo -e "  ${C_BOLD}3${C_RESET} │ 📥 Instalar Novo Pacote"
        echo -e "  ${C_BOLD}4${C_RESET} │ 🗑️  Remover / Desinstalar Pacote"
        echo -e "  ${C_BOLD}5${C_RESET} │ ⚙️  Reinstalar Pacote"
        echo -e "  ${C_BOLD}6${C_RESET} │ 📋 Listar Pacotes Instalados no Sistema"
        echo -e "  ${C_BOLD}7${C_RESET} │ ℹ️  Ver Informações e Dependências do Pacote"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-7]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) packages_update; ui_pause ;;
            2) packages_search; ui_pause ;;
            3) packages_install; ui_pause ;;
            4) packages_remove; ui_pause ;;
            5) packages_reinstall; ui_pause ;;
            6) packages_list_installed; ui_pause ;;
            7) packages_show_info; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
