#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Personalização (15) e Configurações (18)
# ==============================================================================
# Gerencia temas visuais, animações, banners, prompt, caminhos de backup,
# logs e idioma. Todas as alterações são salvas em ~/.config/zenith/zenith.conf.
# ==============================================================================

# 1. Trocar o Tema Visual Ativo
customization_change_theme() {
    ui_header "SELEÇÃO DE TEMA VISUAL DO ZENITH"
    echo -e "Tema Atual: ${C_SUCCESS}${ZENITH_THEME}${C_RESET}"
    echo ""
    echo -e "  ${C_BOLD}1${C_RESET} │ ZENITH  - Ciano Futurista (Oficial)"
    echo -e "  ${C_BOLD}2${C_RESET} │ CYBER   - Cyberpunk Neon Yellow & Magenta"
    echo -e "  ${C_BOLD}3${C_RESET} │ MATRIX  - Verde Hacker Clássico"
    echo -e "  ${C_BOLD}4${C_RESET} │ MINIMAL - Minimalista Branco/Cinza"
    echo -e "  ${C_BOLD}5${C_RESET} │ DARK    - Sombrio / Stealth Cinza Escuro"
    echo -e "  ${C_BOLD}6${C_RESET} │ BLUE    - Azul Profundo"
    echo -e "  ${C_BOLD}7${C_RESET} │ GREEN   - Esmeralda"
    echo -e "  ${C_BOLD}8${C_RESET} │ PURPLE  - Roxo Nebulosa"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o novo tema [1-8]: ${C_RESET}"
    read -r t_choice
    local new_t="ZENITH"
    case "${t_choice}" in
        1) new_t="ZENITH" ;;
        2) new_t="CYBER" ;;
        3) new_t="MATRIX" ;;
        4) new_t="MINIMAL" ;;
        5) new_t="DARK" ;;
        6) new_t="BLUE" ;;
        7) new_t="GREEN" ;;
        8) new_t="PURPLE" ;;
        *) ui_msg_error "Seleção inválida."; return ;;
    esac

    config_set "THEME" "${new_t}"
    ui_msg_success "Tema visual alterado e salvo: ${new_t}."
}

# 2. Configurar Nome de Usuário e Prompt
customization_set_user() {
    ui_header "CONFIGURAR NOME DE USUÁRIO"
    echo -e "Nome Atual: ${C_TEXT}${ZENITH_USER_NAME}${C_RESET}"
    echo -e -n "${C_PRIMARY}Digite o novo nome de usuário exibido: ${C_RESET}"
    read -r new_name
    if [ -n "${new_name}" ]; then
        config_set "USER_NAME" "${new_name}"
        ui_msg_success "Nome alterado para '${new_name}'."
    fi
}

# 3. Animações e Velocidade
customization_animations() {
    ui_header "CONTROLE DE ANIMAÇÕES"
    echo -e "Animações Ativas  : ${ZENITH_ANIMATIONS}"
    echo -e "Velocidade Atual  : ${ZENITH_ANIMATION_SPEED}s"
    echo ""
    echo -e "  ${C_BOLD}1${C_RESET} │ Ativar Animações (ON)"
    echo -e "  ${C_BOLD}2${C_RESET} │ Desativar Animações (OFF)"
    echo -e "  ${C_BOLD}3${C_RESET} │ Alterar Velocidade de Animação (ex: 0.02 ou 0.05)"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1-3]: ${C_RESET}"
    read -r opt
    case "${opt}" in
        1) config_set "ANIMATIONS" "true"; ui_msg_success "Animações ativadas." ;;
        2) config_set "ANIMATIONS" "false"; ui_msg_success "Animações desativadas." ;;
        3)
            echo -e -n "${C_PRIMARY}Digite o novo atraso em segundos (ex: 0.02): ${C_RESET}"
            read -r spd
            if [[ "${spd}" =~ ^[0-9.]+$ ]]; then
                config_set "ANIMATION_SPEED" "${spd}"
                ui_msg_success "Velocidade ajustada."
            else
                ui_msg_error "Valor numérico inválido."
            fi
            ;;
    esac
}

# 4. Modo Compacto (Exibir menos separadores)
customization_compact_mode() {
    ui_header "MODO COMPACTO DE EXIBIÇÃO"
    echo -e "Modo Compacto Atualmente: ${ZENITH_COMPACT_MODE}"
    echo -e "  ${C_BOLD}1${C_RESET} │ Ativar Modo Compacto (true)"
    echo -e "  ${C_BOLD}2${C_RESET} │ Desativar Modo Compacto (false)"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1-2]: ${C_RESET}"
    read -r choice
    if [ "${choice}" = "1" ]; then
        config_set "COMPACT_MODE" "true"
        ui_msg_success "Modo Compacto ATIVADO."
    elif [ "${choice}" = "2" ]; then
        config_set "COMPACT_MODE" "false"
        ui_msg_success "Modo Compacto DESATIVADO."
    fi
}

# Submenu do Módulo 15 — PERSONALIZAÇÃO
customization_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO PERSONALIZAÇÃO (15)"
        echo -e "  ${C_BOLD}1${C_RESET} │ 🎨 Alterar Tema de Cores (ZENITH/CYBER/MATRIX...)"
        echo -e "  ${C_BOLD}2${C_RESET} │ 👤 Mudar Nome do Usuário Exibido / Prompt"
        echo -e "  ${C_BOLD}3${C_RESET} │ ⚡ Ativar/Desativar Animações e Velocidade"
        echo -e "  ${C_BOLD}4${C_RESET} │ 📐 Modo Compacto de Interface"
        echo -e "  ${C_BOLD}5${C_RESET} │ 🏷️  Exibir Banner e Cores Atuais"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-5]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) customization_change_theme; ui_pause ;;
            2) customization_set_user; ui_pause ;;
            3) customization_animations; ui_pause ;;
            4) customization_compact_mode; ui_pause ;;
            5) ui_clear; ui_banner; echo -e "${C_SUCCESS}Teste do tema visual ${ZENITH_THEME}.${C_RESET}"; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}

# Submenu do Módulo 18 — CONFIGURAÇÕES
settings_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO GERAL DE CONFIGURAÇÕES (18)"
        echo -e "Arquivo persistente: ${C_INFO}${ZENITH_CONFIG_FILE}${C_RESET}"
        echo ""
        printf "  %-24s: %s\n" "1. Nome do Usuário" "${ZENITH_USER_NAME}"
        printf "  %-24s: %s\n" "2. Tema de Interface" "${ZENITH_THEME}"
        printf "  %-24s: %s\n" "3. Animações Ativas" "${ZENITH_ANIMATIONS} (vel: ${ZENITH_ANIMATION_SPEED}s)"
        printf "  %-24s: %s\n" "4. Diretório de Backup" "${ZENITH_BACKUP_DIR}"
        printf "  %-24s: %s\n" "5. Diretório de Logs" "${ZENITH_LOG_DIR}"
        printf "  %-24s: %s\n" "6. Modo Compacto" "${ZENITH_COMPACT_MODE}"
        printf "  %-24s: %s\n" "7. Idioma Padrão" "${ZENITH_LANGUAGE}"
        printf "  %-24s: %s\n" "8. Chaves da IA (ai.conf)" "Gerenciado no Módulo 06"
        echo ""
        ui_separator
        echo -e "  ${C_BOLD}1${C_RESET} │ Editar Nome do Usuário"
        echo -e "  ${C_BOLD}2${C_RESET} │ Editar Tema"
        echo -e "  ${C_BOLD}3${C_RESET} │ Editar Animações"
        echo -e "  ${C_BOLD}4${C_RESET} │ Alterar Diretório de Backup"
        echo -e "  ${C_BOLD}5${C_RESET} │ Alterar Diretório de Logs"
        echo -e "  ${C_BOLD}6${C_RESET} │ Alterar Idioma (pt-BR / en-US / es-ES)"
        echo -e "  ${C_BOLD}7${C_RESET} │ Visualizar Arquivo de Configuração Atual"
        echo -e "  ${C_BOLD}0${C_RESET} │ Voltar ao Menu Principal"
        echo ""
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-7]: ${C_RESET}"
        read -r s_opt
        case "${s_opt}" in
            1) customization_set_user; ui_pause ;;
            2) customization_change_theme; ui_pause ;;
            3) customization_animations; ui_pause ;;
            4)
                echo -e -n "${C_PRIMARY}Novo diretório de Backup: ${C_RESET}"
                read -r nb_dir
                [ -n "${nb_dir}" ] && { mkdir -p "${nb_dir}"; config_set "BACKUP_DIR" "${nb_dir}"; ui_msg_success "Diretório de backup salvo."; }
                ui_pause
                ;;
            5)
                echo -e -n "${C_PRIMARY}Novo diretório de Logs: ${C_RESET}"
                read -r nl_dir
                [ -n "${nl_dir}" ] && { mkdir -p "${nl_dir}"; config_set "LOG_DIR" "${nl_dir}"; ui_msg_success "Diretório de logs salvo."; }
                ui_pause
                ;;
            6)
                echo -e -n "${C_PRIMARY}Novo idioma (ex: pt-BR, en-US): ${C_RESET}"
                read -r nlang
                [ -n "${nlang}" ] && { config_set "LANGUAGE" "${nlang}"; ui_msg_success "Idioma salvo."; }
                ui_pause
                ;;
            7)
                ui_header "CONTEÚDO DE ${ZENITH_CONFIG_FILE}"
                cat "${ZENITH_CONFIG_FILE}" 2>/dev/null
                ui_pause
                ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
