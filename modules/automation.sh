#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Automação e Tarefas (modules/automation.sh)
# ==============================================================================
# Gerencia scripts de automação, tarefas agendadas, rotinas e backups automáticos.
# REGRAS: Aviso claro antes de operações com impacto destrutivo ou de escrita.
# ==============================================================================

AUTOMATION_DIR="${HOME}/.config/zenith/scripts"
AUTOMATION_LOG="${HOME}/.config/zenith/logs/automation.log"
AUTOMATION_TASKS="${HOME}/.config/zenith/tasks.conf"

automation_init() {
    mkdir -p "${AUTOMATION_DIR}"
    if [ ! -f "${AUTOMATION_LOG}" ]; then
        touch "${AUTOMATION_LOG}"
    fi
    if [ ! -f "${AUTOMATION_TASKS}" ]; then
        cat << 'EOF' > "${AUTOMATION_TASKS}"
# Zenith Panel - Tarefas e Rotinas Cadastradas
# Formato: NOME|COMANDO|DESCRIÇÃO
BackupDiario|zenith-backup-auto|Rotina de backup automático do painel
LimpezaTmp|rm -rf /tmp/zenith_tmp_* 2>/dev/null|Limpa arquivos temporários do painel
AuditoriaSeguranca|zenith-security-check|Verifica permissões de arquivos críticos
EOF
    fi
}

# 1. Executar Script Local
automation_run_script() {
    automation_init
    ui_header "EXECUTAR SCRIPT DE AUTOMAÇÃO"

    local scripts=()
    while IFS= read -r -d '' file; do
        scripts+=("${file}")
    done < <(find "${AUTOMATION_DIR}" -maxdepth 1 -name "*.sh" -print0 2>/dev/null)

    if [ ${#scripts[@]} -eq 0 ]; then
        ui_msg_warn "Nenhum script de automação encontrado em ${AUTOMATION_DIR}."
        return
    fi

    echo -e "${C_PRIMARY}Scripts na pasta de automação:${C_RESET}"
    local i=1
    for s in "${scripts[@]}"; do
        echo -e "  ${C_BOLD}${i}${C_RESET} │ $(basename "${s}")"
        i=$((i + 1))
    done
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o número do script para executar (0 para cancelar): ${C_RESET}"
    read -r s_idx
    if [[ "${s_idx}" =~ ^[0-9]+$ ]] && [ "${s_idx}" -gt 0 ] && [ "${s_idx}" -le "${#scripts[@]}" ]; then
        local target="${scripts[$((s_idx - 1))]}"
        echo -e "${C_WARN}⚠️  ATENÇÃO: Você está prestes a executar o script:${C_RESET}"
        echo -e "  Arquivo: ${C_BOLD}${target}${C_RESET}"
        echo -e "  Conteúdo inicial:"
        head -n 5 "${target}" | sed 's/^/    /'
        echo ""
        if utils_confirm "Confirmar execução de $(basename "${target}")?"; then
            ui_msg_exec "Rodando $(basename "${target}")..."
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Executando script: ${target}" >> "${AUTOMATION_LOG}"
            bash "${target}"
            echo ""
            ui_msg_success "Execução do script concluída."
        else
            ui_msg_warn "Execução cancelada."
        fi
    fi
}

# 2. Criar Novo Script de Automação
automation_create_script() {
    automation_init
    ui_header "CRIAR SCRIPT DE AUTOMAÇÃO"
    echo -e -n "${C_PRIMARY}Nome do arquivo do novo script (sem extensões ou com .sh): ${C_RESET}"
    read -r s_name
    [ -z "${s_name}" ] && return
    [[ ! "${s_name}" =~ \.sh$ ]] && s_name="${s_name}.sh"

    local f_path="${AUTOMATION_DIR}/${s_name}"
    if [ -f "${f_path}" ]; then
        if ! utils_confirm "O arquivo ${s_name} já existe. Sobrescrever?"; then
            return
        fi
    fi

    cat << 'EOF' > "${f_path}"
#!/usr/bin/env bash
# Script gerado automaticamente pelo Zenith Panel
# Data: $(date)

echo "=== Executando rotina de automação ==="
# Adicione seus comandos personalizados aqui
echo "=== Rotina concluída com sucesso ==="
EOF
    chmod +x "${f_path}"
    ui_msg_success "Script '${s_name}' criado em ${f_path} com permissão +x."
}

# 3. Listar Scripts Disponíveis
automation_list_scripts() {
    automation_init
    ui_header "SCRIPTS DISPONÍVEIS (${AUTOMATION_DIR})"
    if [ -d "${AUTOMATION_DIR}" ] && [ "$(ls -A "${AUTOMATION_DIR}" 2>/dev/null)" ]; then
        ls -lh "${AUTOMATION_DIR}" | awk 'NR>1 {print "  - " $9 " (" $5 ", Modificado: " $6 " " $7 ")"}'
    else
        echo -e "${C_MUTED}Nenhum script na pasta.${C_RESET}"
    fi
    echo ""
}

# 4. Executar Tarefa / Rotina Cadastrada
automation_run_task() {
    automation_init
    ui_header "EXECUTAR TAREFAS CADASTRADAS"
    echo -e "${C_PRIMARY}Tarefas e Rotinas Disponíveis:${C_RESET}"
    local idx=1
    local t_names=()
    local t_cmds=()
    local t_descs=()

    while IFS='|' read -r tname tcmd tdesc; do
        [[ "${tname}" =~ ^# ]] && continue
        [ -z "${tname}" ] && continue
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ ${C_TEXT}${tname}${C_RESET} - ${C_MUTED}${tdesc}${C_RESET}"
        t_names+=("${tname}")
        t_cmds+=("${tcmd}")
        t_descs+=("${tdesc}")
        idx=$((idx + 1))
    done < "${AUTOMATION_TASKS}"
    echo ""

    echo -e -n "${C_PRIMARY}Escolha a tarefa para executar [1-$((idx - 1))]: ${C_RESET}"
    read -r t_sel
    if [[ "${t_sel}" =~ ^[0-9]+$ ]] && [ "${t_sel}" -gt 0 ] && [ "${t_sel}" -le "${#t_names[@]}" ]; then
        local chosen_cmd="${t_cmds[$((t_sel - 1))]}"
        local chosen_name="${t_names[$((t_sel - 1))]}"

        echo -e "${C_WARN}⚠️  Você executará a tarefa: ${chosen_name}${C_RESET}"
        echo -e "  Comando: ${chosen_cmd}"
        if utils_confirm "Confirmar execução desta tarefa?"; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tarefa rodada: ${chosen_name} -> ${chosen_cmd}" >> "${AUTOMATION_LOG}"
            eval "${chosen_cmd}" 2>&1
            echo ""
            ui_msg_success "Tarefa ${chosen_name} concluída."
        fi
    fi
}

# 5. Agendar Nova Tarefa
automation_schedule_task() {
    automation_init
    ui_header "AGENDAMENTO DE TAREFAS (CRON)"
    if ! check_command crontab; then
        ui_msg_warn "O utilitário 'crontab' / cron não está instalado neste ambiente."
        echo "Dica: Em sistemas Debian/Termux você pode instalar 'cronie' ou gerenciar agendamentos no Termux:JobScheduler."
        return
    fi

    echo -e "Crontab atual do usuário:"
    crontab -l 2>/dev/null | grep -v "^#" || echo "Nenhuma tarefa cron agendada."
    echo ""
    echo -e -n "${C_PRIMARY}Digite a expressão cron (ex: '0 3 * * * /caminho/para/script.sh'): ${C_RESET}"
    read -r cron_expr
    if [ -n "${cron_expr}" ]; then
        (crontab -l 2>/dev/null; echo "${cron_expr}") | crontab - && ui_msg_success "Agendamento cron adicionado!" || ui_msg_error "Erro ao adicionar agendamento."
    fi
}

# 6. Remover Tarefa Cadastrada
automation_remove_task() {
    automation_init
    ui_header "REMOVER TAREFA CADASTRADA"
    echo -e "${C_PRIMARY}Selecione uma tarefa para remover de ${AUTOMATION_TASKS}:${C_RESET}"
    cat -n "${AUTOMATION_TASKS}" | grep -v "^\s*[0-9]*\s*#"
    echo ""
    echo -e -n "${C_PRIMARY}Digite o nome exato da tarefa para apagar: ${C_RESET}"
    read -r del_name
    [ -z "${del_name}" ] && return

    if grep -q "^${del_name}|" "${AUTOMATION_TASKS}"; then
        if utils_confirm "Confirmar remoção da tarefa '${del_name}'?"; then
            sed -i "/^${del_name}|/d" "${AUTOMATION_TASKS}"
            ui_msg_success "Tarefa removida com sucesso."
        fi
    else
        ui_msg_error "Tarefa '${del_name}' não encontrada."
    fi
}

# 7. Visualizar Logs de Automação
automation_logs() {
    automation_init
    ui_header "LOGS DE AUTOMAÇÃO E ROTINAS"
    if [ -f "${AUTOMATION_LOG}" ]; then
        tail -n 25 "${AUTOMATION_LOG}"
    else
        echo -e "${C_MUTED}Arquivo de log de automação está vazio.${C_RESET}"
    fi
    echo ""
}

# 8. Rotina de Backup Automático
automation_auto_backup() {
    automation_init
    ui_header "ROTINA DE BACKUP AUTOMÁTICO"
    ui_msg_exec "Executando backup das configurações do Zenith Panel..."
    mkdir -p "${ZENITH_BACKUP_DIR}"
    local timestamp
    timestamp="$(date '+%Y%m%d_%H%M%S')"
    local b_file="${ZENITH_BACKUP_DIR}/zenith_autobackup_${timestamp}.tar.gz"

    tar -czvf "${b_file}" -C "${HOME}" ".config/zenith" >/dev/null 2>&1
    if [ -f "${b_file}" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup automático criado: ${b_file}" >> "${AUTOMATION_LOG}"
        ui_msg_success "Backup automático gerado com sucesso: $(basename "${b_file}")"
        echo "Tamanho do arquivo: $(utils_file_size "${b_file}")"
    else
        ui_msg_error "Falha ao gerar o arquivo de backup."
    fi
}

# Submenu principal do Módulo Automação
automation_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO AUTOMAÇÃO & ROTINAS"
        echo -e "  ${C_BOLD}1${C_RESET} │ ⚡ Executar Script Local (${AUTOMATION_DIR})"
        echo -e "  ${C_BOLD}2${C_RESET} │ 📝 Criar Novo Script de Automação (.sh)"
        echo -e "  ${C_BOLD}3${C_RESET} │ 📂 Listar Scripts Disponíveis"
        echo -e "  ${C_BOLD}4${C_RESET} │ 🚀 Executar Tarefa / Rotina Cadastrada"
        echo -e "  ${C_BOLD}5${C_RESET} │ ⏰ Agendar Tarefa no Sistema (Crontab)"
        echo -e "  ${C_BOLD}6${C_RESET} │ 🗑️  Remover Tarefa Cadastrada"
        echo -e "  ${C_BOLD}7${C_RESET} │ 📜 Visualizar Logs de Automação"
        echo -e "  ${C_BOLD}8${C_RESET} │ 💾 Executar Rotina de Backup Automático Agora"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-8]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) automation_run_script; ui_pause ;;
            2) automation_create_script; ui_pause ;;
            3) automation_list_scripts; ui_pause ;;
            4) automation_run_task; ui_pause ;;
            5) automation_schedule_task; ui_pause ;;
            6) automation_remove_task; ui_pause ;;
            7) automation_logs; ui_pause ;;
            8) automation_auto_backup; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
