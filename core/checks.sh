#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo de Verificação de Ambiente e Dependências (core/checks.sh)
# ==============================================================================
# Detecta arquitetura, Termux, Android, Root, ferramentas instaladas e internet.
# Não falha em sistemas Linux genéricos e não exige privilégios de root.
# ==============================================================================

# Variáveis globais de ambiente detectado
export ZENITH_IS_TERMUX=false
export ZENITH_IS_ANDROID=false
export ZENITH_IS_ROOT=false
export ZENITH_ARCH=""
export ZENITH_OS=""
export ZENITH_PKG_MGR=""

# Inicializa as detecções do sistema
checks_init() {
    # Detecta se está rodando em Termux
    if [[ -n "${PREFIX}" && "${PREFIX}" == *"com.termux"* ]] || [ -d "/data/data/com.termux" ]; then
        ZENITH_IS_TERMUX=true
        ZENITH_IS_ANDROID=true
    elif [ -f "/system/build.prop" ] || [[ "$(uname -o 2>/dev/null)" == *"Android"* ]]; then
        ZENITH_IS_ANDROID=true
    fi

    # Detecta arquitetura da CPU
    ZENITH_ARCH="$(uname -m 2>/dev/null || echo 'unknown')"

    # Detecta privilégios de Root
    if [ "$(id -u 2>/dev/null)" -eq 0 ]; then
        ZENITH_IS_ROOT=true
    else
        ZENITH_IS_ROOT=false
    fi

    # Detecta sistema operacional geral
    if [ "${ZENITH_IS_TERMUX}" = true ]; then
        ZENITH_OS="Termux (Android)"
    elif [ -f "/etc/os-release" ]; then
        ZENITH_OS="$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d '=' -f2 | tr -d '"')"
        [ -z "${ZENITH_OS}" ] && ZENITH_OS="$(uname -s)"
    else
        ZENITH_OS="$(uname -s 2>/dev/null || echo 'Linux')"
    fi

    # Detecta gerenciador de pacotes principal
    if command -v pkg >/dev/null 2>&1; then
        ZENITH_PKG_MGR="pkg"
    elif command -v apt-get >/dev/null 2>&1; then
        ZENITH_PKG_MGR="apt-get"
    elif command -v apt >/dev/null 2>&1; then
        ZENITH_PKG_MGR="apt"
    elif command -v pacman >/dev/null 2>&1; then
        ZENITH_PKG_MGR="pacman"
    elif command -v apk >/dev/null 2>&1; then
        ZENITH_PKG_MGR="apk"
    elif command -v dnf >/dev/null 2>&1; then
        ZENITH_PKG_MGR="dnf"
    else
        ZENITH_PKG_MGR="nenhum"
    fi
}

# Verifica se um comando existe no PATH (retorna 0 para sim, 1 para não)
check_command() {
    local cmd="$1"
    command -v "${cmd}" >/dev/null 2>&1
}

# Verifica status de conexão com a Internet
check_internet() {
    if check_command curl; then
        curl -s --connect-timeout 3 "https://clients3.google.com/generate_204" >/dev/null 2>&1 && return 0
    elif check_command wget; then
        wget -q --spider --timeout=3 "https://clients3.google.com/generate_204" >/dev/null 2>&1 && return 0
    elif check_command ping; then
        ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 && return 0
    fi
    return 1
}

# Verifica se a API do Termux está instalada e acessível
check_termux_api() {
    if [ "${ZENITH_IS_TERMUX}" = true ] && check_command termux-battery-status; then
        return 0
    fi
    return 1
}

# Verifica ferramentas individuais
check_git() {
    check_command git
}

check_python() {
    check_command python3 || check_command python
}

check_node() {
    check_command node
}

check_curl() {
    check_command curl
}

check_wget() {
    check_command wget
}

# Retorna um resumo legível do ambiente atual
check_environment_summary() {
    echo "OS: ${ZENITH_OS} | ARCH: ${ZENITH_ARCH} | TERMUX: ${ZENITH_IS_TERMUX} | PKG: ${ZENITH_PKG_MGR}"
}

# Executa init ao carregar
checks_init
