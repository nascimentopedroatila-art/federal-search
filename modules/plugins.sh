#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Sistema de Plugins (modules/plugins.sh)
# ==============================================================================
# Detecta, ativa, desativa, lista, executa e inspeciona plugins na pasta plugins/.
# Cada plugin declara PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR, PLUGIN_DESCRIPTION.
# ==============================================================================

PLUGINS_STATE_FILE="${HOME}/.config/zenith/plugins.state"

plugins_init() {
    mkdir -p "plugins"
    mkdir -p "${HOME}/.config/zenith/plugins"
    if [ ! -f "${PLUGINS_STATE_FILE}" ]; then
        touch "${PLUGINS_STATE_FILE}"
    fi
}

# Retorna lista de caminhos de plugins válidos
plugins_get_all() {
    find "plugins" "${HOME}/.config/zenith/plugins" -maxdepth 1 -name "*.sh" 2>/dev/null | sort -u
}

# Verifica se um plugin está marcado como ativo (por nome de arquivo basename)
plugins_is_active() {
    local bname
    bname="$(basename "$1")"
    if grep -q -x "${bname}" "${PLUGINS_STATE_FILE}" 2>/dev/null; then
        return 0
    fi
    return 1
}

# 1. Listar Plugins
plugins_list() {
    plugins_init
    ui_header "PLUGINS INSTALADOS NO ZENITH"

    local idx=1
    local p_files
    p_files=$(plugins_get_all)

    if [ -z "${p_files}" ]; then
        ui_msg_warn "Nenhum plugin detectado nas pastas plugins/ ou ~/.config/zenith/plugins."
        return
    fi

    printf "  %-4s %-22s %-10s %-10s %-24s\n" "ID" "NOME DO PLUGIN" "VERSÃO" "STATUS" "AUTOR"
    ui_separator
    for f in ${p_files}; do
        local PLUGIN_NAME=""
        local PLUGIN_VERSION=""
        local PLUGIN_AUTHOR=""
        local PLUGIN_DESCRIPTION=""
        # Lê metadados com grep sem executar scripts maliciosos ao inspecionar
        PLUGIN_NAME=$(grep "^PLUGIN_NAME=" "${f}" | head -n 1 | cut -d'=' -f2- | tr -d '"'\''')
        PLUGIN_VERSION=$(grep "^PLUGIN_VERSION=" "${f}" | head -n 1 | cut -d'=' -f2- | tr -d '"'\''')
        PLUGIN_AUTHOR=$(grep "^PLUGIN_AUTHOR=" "${f}" | head -n 1 | cut -d'=' -f2- | tr -d '"'\''')
        [ -z "${PLUGIN_NAME}" ] && PLUGIN_NAME="$(basename "${f}")"

        local status_str
        if plugins_is_active "${f}"; then
            status_str="${C_SUCCESS}ATIVO${C_RESET}"
        else
            status_str="${C_MUTED}Desativado${C_RESET}"
        fi

        printf "  %-4s %-22s %-10s %-10b %-24s\n" "${idx}" "${PLUGIN_NAME:0:22}" "${PLUGIN_VERSION:-1.0}" "${status_str}" "${PLUGIN_AUTHOR:-Anônimo}"
        idx=$((idx + 1))
    done
    echo ""
}

# 2. Ativar Plugin
plugins_activate() {
    plugins_init
    ui_header "ATIVAR PLUGIN"
    local idx=1
    local p_files=()
    for f in $(plugins_get_all); do
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ $(basename "${f}")"
        p_files+=("${f}")
        idx=$((idx + 1))
    done
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o plugin para ATIVAR [1-$((idx - 1))]: ${C_RESET}"
    read -r p_sel
    if [[ "${p_sel}" =~ ^[0-9]+$ ]] && [ "${p_sel}" -gt 0 ] && [ "${p_sel}" -le "${#p_files[@]}" ]; then
        local bname
        bname="$(basename "${p_files[$((p_sel - 1))]}")"
        if ! grep -q -x "${bname}" "${PLUGINS_STATE_FILE}"; then
            echo "${bname}" >> "${PLUGINS_STATE_FILE}"
        fi
        ui_msg_success "Plugin '${bname}' ativado no sistema."
    fi
}

# 3. Desativar Plugin
plugins_deactivate() {
    plugins_init
    ui_header "DESATIVAR PLUGIN"
    local idx=1
    local p_files=()
    for f in $(plugins_get_all); do
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ $(basename "${f}")"
        p_files+=("${f}")
        idx=$((idx + 1))
    done
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o plugin para DESATIVAR [1-$((idx - 1))]: ${C_RESET}"
    read -r p_sel
    if [[ "${p_sel}" =~ ^[0-9]+$ ]] && [ "${p_sel}" -gt 0 ] && [ "${p_sel}" -le "${#p_files[@]}" ]; then
        local bname
        bname="$(basename "${p_files[$((p_sel - 1))]}")"
        sed -i "/^${bname}$/d" "${PLUGINS_STATE_FILE}" 2>/dev/null
        ui_msg_success "Plugin '${bname}' desativado."
    fi
}

# 4. Remover Plugin
plugins_remove() {
    plugins_init
    ui_header "REMOVER PLUGIN"
    local idx=1
    local p_files=()
    for f in $(plugins_get_all); do
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ $(basename "${f}")"
        p_files+=("${f}")
        idx=$((idx + 1))
    done
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o plugin para EXCLUIR [1-$((idx - 1))]: ${C_RESET}"
    read -r p_sel
    if [[ "${p_sel}" =~ ^[0-9]+$ ]] && [ "${p_sel}" -gt 0 ] && [ "${p_sel}" -le "${#p_files[@]}" ]; then
        local fpath="${p_files[$((p_sel - 1))]}"
        local bname
        bname="$(basename "${fpath}")"
        if utils_confirm "Confirmar a remoção permanente de '${bname}'?"; then
            rm -f "${fpath}"
            sed -i "/^${bname}$/d" "${PLUGINS_STATE_FILE}" 2>/dev/null
            ui_msg_success "Plugin removido do sistema."
        fi
    fi
}

# 5. Informações do Plugin
plugins_info() {
    plugins_init
    ui_header "INFORMAÇÕES DETALHADAS DE PLUGIN"
    local idx=1
    local p_files=()
    for f in $(plugins_get_all); do
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ $(basename "${f}")"
        p_files+=("${f}")
        idx=$((idx + 1))
    done
    echo ""
    echo -e -n "${C_PRIMARY}Escolha um plugin [1-$((idx - 1))]: ${C_RESET}"
    read -r p_sel
    if [[ "${p_sel}" =~ ^[0-9]+$ ]] && [ "${p_sel}" -gt 0 ] && [ "${p_sel}" -le "${#p_files[@]}" ]; then
        local fpath="${p_files[$((p_sel - 1))]}"
        local PLUGIN_NAME=""
        local PLUGIN_VERSION=""
        local PLUGIN_AUTHOR=""
        local PLUGIN_DESCRIPTION=""
        source "${fpath}" 2>/dev/null || true

        printf "  %-20s: %s\n" "Arquivo" "${fpath}"
        printf "  %-20s: %s\n" "Nome do Plugin" "${PLUGIN_NAME:-N/A}"
        printf "  %-20s: %s\n" "Versão" "${PLUGIN_VERSION:-1.0.0}"
        printf "  %-20s: %s\n" "Autor" "${PLUGIN_AUTHOR:-N/A}"
        printf "  %-20s: %s\n" "Descrição" "${PLUGIN_DESCRIPTION:-Sem descrição}"
        printf "  %-20s: %s\n" "Status" "$(plugins_is_active "${fpath}" && echo 'ATIVO' || echo 'Desativado')"
        echo ""
    fi
}

# 6. Executar Plugin Ativo
plugins_run() {
    plugins_init
    ui_header "EXECUTAR PLUGIN"
    local idx=1
    local p_files=()
    for f in $(plugins_get_all); do
        if plugins_is_active "${f}"; then
            echo -e "  ${C_BOLD}${idx}${C_RESET} │ ${C_SUCCESS}$(basename "${f}")${C_RESET} (ATIVO)"
            p_files+=("${f}")
            idx=$((idx + 1))
        fi
    done

    if [ ${#p_files[@]} -eq 0 ]; then
        ui_msg_warn "Nenhum plugin está ativado. Use a opção 2 para ativar primeiro."
        return
    fi
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o plugin para executar [1-$((idx - 1))]: ${C_RESET}"
    read -r p_sel
    if [[ "${p_sel}" =~ ^[0-9]+$ ]] && [ "${p_sel}" -gt 0 ] && [ "${p_sel}" -le "${#p_files[@]}" ]; then
        local fpath="${p_files[$((p_sel - 1))]}"
        ui_msg_exec "Executando plugin $(basename "${fpath}")..."
        ui_separator
        source "${fpath}" 2>/dev/null
        if command -v plugin_run >/dev/null 2>&1; then
            plugin_run
            unset -f plugin_run
        else
            bash "${fpath}"
        fi
        echo ""
        ui_msg_success "Execução de plugin finalizada."
    fi
}

# Submenu principal do Módulo Plugins
plugins_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO SISTEMA DE PLUGINS (20)"
        echo -e "  ${C_BOLD}1${C_RESET} │ 📋 Listar Plugins Detectados"
        echo -e "  ${C_BOLD}2${C_RESET} │ ⚡ Ativar Plugin"
        echo -e "  ${C_BOLD}3${C_RESET} │ ⏸️  Desativar Plugin"
        echo -e "  ${C_BOLD}4${C_RESET} │ 🗑️  Remover Plugin"
        echo -e "  ${C_BOLD}5${C_RESET} │ ℹ️  Informações Detalhadas do Plugin"
        echo -e "  ${C_BOLD}6${C_RESET} │ ▶️  Executar Plugin Ativo"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-6]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) plugins_list; ui_pause ;;
            2) plugins_activate; ui_pause ;;
            3) plugins_deactivate; ui_pause ;;
            4) plugins_remove; ui_pause ;;
            5) plugins_info; ui_pause ;;
            6) plugins_run; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
