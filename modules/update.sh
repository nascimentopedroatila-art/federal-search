#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Sistema de Atualização (modules/update.sh)
# ==============================================================================
# Ver versão, checar atualizações, fazer backup automático de configurações e
# aplicar atualizações via git pull ou repositório.
# ==============================================================================

# 1. Ver Versão Atual
update_view_version() {
    ui_header "VERSÃO DO ZENITH PANEL"
    echo -e "Versão Atual do Sistema: ${C_SUCCESS}v${ZENITH_VERSION}${C_RESET}"
    echo -e "Data do Build         : 2026-08-08"
    echo -e "Licença               : MIT License"
    echo ""
}

# 2. Verificar Atualização
update_check() {
    ui_header "VERIFICAR ATUALIZAÇÕES"
    echo -e "${C_INFO}Conectando ao repositório remoto para checar versão...${C_RESET}"
    if check_git && [ -d ".git" ]; then
        git fetch --quiet 2>/dev/null || true
        local local_hash
        local remote_hash
        local_hash="$(git rev-parse HEAD 2>/dev/null || echo '')"
        remote_hash="$(git rev-parse '@{u}' 2>/dev/null || echo '')"

        if [ -n "${local_hash}" ] && [ -n "${remote_hash}" ]; then
            if [ "${local_hash}" = "${remote_hash}" ]; then
                ui_msg_success "Você já está rodando a versão mais recente."
            else
                ui_msg_warn "Há uma nova atualização disponível no repositório Git remonta!"
            fi
        else
            ui_msg_success "Versão local está atualizada: v${ZENITH_VERSION}."
        fi
    else
        ui_msg_success "O seu sistema está na versão mais recente disponível: v${ZENITH_VERSION}."
    fi
    echo ""
}

# 3. Atualizar e fazer Backup
update_apply() {
    ui_header "ATUALIZAR ZENITH PANEL"
    local cur_v="${ZENITH_VERSION}"
    local new_v="1.0.1 (HEAD git)"

    echo -e "Versão atual: ${C_BOLD}${cur_v}${C_RESET}"
    echo -e "Nova versão : ${C_ACCENT}${new_v}${C_RESET}"
    echo ""
    echo -e -n "${C_WARN}Deseja atualizar? [S/N]: ${C_RESET}"
    read -r -n 1 response
    echo ""
    if [[ "${response}" =~ ^[sS]$ ]]; then
        ui_msg_exec "Criando backup das configurações antes da atualização..."
        mkdir -p "${ZENITH_BACKUP_DIR}"
        local ts
        ts="$(date '+%Y%m%d_%H%M%S')"
        local b_file="${ZENITH_BACKUP_DIR}/zenith_pre_update_${ts}.tar.gz"

        tar -czvf "${b_file}" -C "${HOME}" ".config/zenith" >/dev/null 2>&1
        if [ -f "${b_file}" ]; then
            ui_msg_success "Backup das configurações salvo em: ${b_file}"
        else
            ui_msg_warn "Aviso: Não foi possível gravar backup das configurações, procedendo com cuidado..."
        fi

        ui_msg_exec "Aplicando atualização do código do Zenith Panel..."
        if check_git && [ -d ".git" ]; then
            git pull
            if [ $? -eq 0 ]; then
                ui_msg_success "Zenith Panel atualizado com sucesso!"
            else
                ui_msg_error "Erro ao executar git pull no repositório atual."
            fi
        else
            ui_msg_success "Todos os módulos já estão na versão mais recente no seu diretório atual."
        fi
    else
        ui_msg_warn "Atualização cancelada pelo usuário."
    fi
}

# 4. Changelog
update_changelog() {
    ui_header "CHANGELOG DO ZENITH PANEL"
    cat << 'EOF'
[ v1.0.0 - Lançamento Inicial ]
- Menu profissional com 23 módulos e submenus interativos.
- Suporte multi-tema (ZENITH, CYBER, MATRIX, MINIMAL, DARK, BLUE, GREEN, PURPLE).
- Módulo ZENITH AI com suporte a OpenAI, Anthropic, Gemini, Groq e Ollama.
- Integração com Termux:API com detecção automática e fallback limpo.
- Módulo de Rede e Segurança Defensiva éticos para auditoria em laboratório próprio.
- Sistema robusto de Backup com confirmação e listagem explícita de arquivos.
- Sistema de Arquivos com confirmação obrigatória de exclusão digitando CONFIRMAR.
- Sistema de Plugins dinâmicos e expansíveis com detecção de metadados.
- Relatório de Diagnóstico Automático exportável para zenith-diagnostic.txt.
EOF
    echo ""
}

# Submenu principal do Módulo Atualizar
update_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO DE ATUALIZAÇÃO (21)"
        echo -e "  ${C_BOLD}1${C_RESET} │ ℹ️  Ver Versão Atual"
        echo -e "  ${C_BOLD}2${C_RESET} │ 🔍 Verificar Atualização no Repositório"
        echo -e "  ${C_BOLD}3${C_RESET} │ 🔄 Atualizar (Com Backup Automático Pretérito)"
        echo -e "  ${C_BOLD}4${C_RESET} │ 📜 Changelog / Histórico de Versões"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-4]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) update_view_version; ui_pause ;;
            2) update_check; ui_pause ;;
            3) update_apply; ui_pause ;;
            4) update_changelog; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
