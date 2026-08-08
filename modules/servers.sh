#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Gerenciador de Servidores (modules/servers.sh)
# ==============================================================================
# Cadastra e gerencia servidores locais com persistência de PID e logs.
# Campos: Nome | Comando | Diretório | Porta | Descrição
# ==============================================================================

SERVERS_CONF="${HOME}/.config/zenith/servers.conf"
SERVERS_LOG_DIR="${HOME}/.config/zenith/logs/servers"

servers_init() {
    mkdir -p "${SERVERS_LOG_DIR}"
    if [ ! -f "${SERVERS_CONF}" ]; then
        cat << 'EOF' > "${SERVERS_CONF}"
# Zenith Panel - Servidores Locais Cadastrados
# Formato: NOME|COMANDO|DIRETÓRIO|PORTA|DESCRIÇÃO
Servidor Python Web|python3 -m http.server 8080|.|8080|Servidor HTTP estático nativo do Python
Servidor PHP Dev|php -S 127.0.0.1:8000|.|8000|Servidor de desenvolvimento PHP local
EOF
    fi
}

# Converte nome de servidor em slug seguro para arquivo de PID/Log
servers_slug() {
    echo "$1" | tr '[:upper:] ' '[:lower:]_' | tr -cd 'a-z0-9_'
}

# Retorna PID ativo do servidor ou vazio se inativo
servers_get_pid() {
    local name="$1"
    local slug
    slug="$(servers_slug "${name}")"
    local pidfile="${SERVERS_LOG_DIR}/${slug}.pid"
    if [ -f "${pidfile}" ]; then
        local pid
        pid=$(cat "${pidfile}" 2>/dev/null)
        if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
            echo "${pid}"
            return
        else
            rm -f "${pidfile}" 2>/dev/null
        fi
    fi
    echo ""
}

# 1. Status Geral dos Servidores
servers_status() {
    servers_init
    ui_header "STATUS DOS SERVIDORES LOCAIS"

    printf "  %-4s %-20s %-8s %-12s %-20s\n" "ID" "NOME" "PORTA" "STATUS/PID" "DESCRIÇÃO"
    ui_separator
    local idx=1
    while IFS='|' read -r sname scmd sdir sport sdesc; do
        [[ "${sname}" =~ ^# ]] && continue
        [ -z "${sname}" ] && continue
        local pid
        pid="$(servers_get_pid "${sname}")"
        local stat_str
        if [ -n "${pid}" ]; then
            stat_str="${C_SUCCESS}ONLINE (${pid})${C_RESET}"
        else
            stat_str="${C_MUTED}OFFLINE${C_RESET}"
        fi
        printf "  %-4s %-20s %-8s %-12b %-20s\n" "${idx}" "${sname}" "${sport}" "${stat_str}" "${sdesc}"
        idx=$((idx + 1))
    done < "${SERVERS_CONF}"
    echo ""
}

# 2. Iniciar um Servidor
servers_start() {
    servers_init
    ui_header "INICIAR SERVIDOR LOCAL"
    local s_names=()
    local s_cmds=()
    local s_dirs=()
    local s_ports=()
    local idx=1

    while IFS='|' read -r sname scmd sdir sport sdesc; do
        [[ "${sname}" =~ ^# ]] && continue
        [ -z "${sname}" ] && continue
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ ${C_TEXT}${sname}${C_RESET} (Porta: ${sport})"
        s_names+=("${sname}")
        s_cmds+=("${scmd}")
        s_dirs+=("${sdir}")
        s_ports+=("${sport}")
        idx=$((idx + 1))
    done < "${SERVERS_CONF}"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o servidor para iniciar [1-$((idx - 1))]: ${C_RESET}"
    read -r s_sel

    if [[ "${s_sel}" =~ ^[0-9]+$ ]] && [ "${s_sel}" -gt 0 ] && [ "${s_sel}" -le "${#s_names[@]}" ]; then
        local name="${s_names[$((s_sel - 1))]}"
        local cmd="${s_cmds[$((s_sel - 1))]}"
        local dir="${s_dirs[$((s_sel - 1))]}"
        local slug
        slug="$(servers_slug "${name}")"
        local pidfile="${SERVERS_LOG_DIR}/${slug}.pid"
        local logfile="${SERVERS_LOG_DIR}/${slug}.log"

        local cur_pid
        cur_pid="$(servers_get_pid "${name}")"
        if [ -n "${cur_pid}" ]; then
            ui_msg_warn "O servidor '${name}' já está em execução no PID ${cur_pid}."
            return
        fi

        [ -z "${dir}" ] || [ "${dir}" = "." ] && dir="${PWD}"
        mkdir -p "${dir}" 2>/dev/null || true

        ui_msg_exec "Iniciando '${name}' no diretório '${dir}'..."
        (
            cd "${dir}" || exit 1
            nohup ${cmd} > "${logfile}" 2>&1 &
            echo $! > "${pidfile}"
        )

        sleep 1
        local new_pid
        new_pid="$(servers_get_pid "${name}")"
        if [ -n "${new_pid}" ]; then
            ui_msg_success "Servidor '${name}' INICIADO no PID ${new_pid} (Log: ${logfile})."
        else
            ui_msg_error "Falha ao iniciar servidor. Verifique o log: ${logfile}"
            cat "${logfile}" 2>/dev/null | head -n 5
        fi
    fi
}

# 3. Parar um Servidor
servers_stop() {
    servers_init
    ui_header "PARAR SERVIDOR LOCAL"
    local idx=1
    local s_names=()
    while IFS='|' read -r sname scmd sdir sport sdesc; do
        [[ "${sname}" =~ ^# ]] && continue
        [ -z "${sname}" ] && continue
        local pid
        pid="$(servers_get_pid "${sname}")"
        if [ -n "${pid}" ]; then
            echo -e "  ${C_BOLD}${idx}${C_RESET} │ ${C_SUCCESS}${sname}${C_RESET} (PID ativo: ${pid})"
        else
            echo -e "  ${C_BOLD}${idx}${C_RESET} │ ${C_MUTED}${sname}${C_RESET} (Offline)"
        fi
        s_names+=("${sname}")
        idx=$((idx + 1))
    done < "${SERVERS_CONF}"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o servidor para PARAR [1-$((idx - 1))]: ${C_RESET}"
    read -r sel
    if [[ "${sel}" =~ ^[0-9]+$ ]] && [ "${sel}" -gt 0 ] && [ "${sel}" -le "${#s_names[@]}" ]; then
        local name="${s_names[$((sel - 1))]}"
        local pid
        pid="$(servers_get_pid "${name}")"
        if [ -n "${pid}" ]; then
            kill "${pid}" 2>/dev/null || kill -9 "${pid}" 2>/dev/null
            local slug
            slug="$(servers_slug "${name}")"
            rm -f "${SERVERS_LOG_DIR}/${slug}.pid" 2>/dev/null
            ui_msg_success "Servidor '${name}' (PID ${pid}) encerrado com sucesso."
        else
            ui_msg_warn "O servidor '${name}' já está Offline."
        fi
    fi
}

# 4. Reiniciar Servidor
servers_restart() {
    servers_init
    ui_header "REINICIAR SERVIDOR"
    ui_msg_info "Selecione o servidor para parar e ligar em seguida:"
    servers_stop
    sleep 1
    servers_start
}

# 5. Visualizar Logs do Servidor
servers_view_logs() {
    servers_init
    ui_header "LOGS DO SERVIDOR"
    local idx=1
    local s_names=()
    while IFS='|' read -r sname scmd sdir sport sdesc; do
        [[ "${sname}" =~ ^# ]] && continue
        [ -z "${sname}" ] && continue
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ ${sname}"
        s_names+=("${sname}")
        idx=$((idx + 1))
    done < "${SERVERS_CONF}"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o servidor [1-$((idx - 1))]: ${C_RESET}"
    read -r sel
    if [[ "${sel}" =~ ^[0-9]+$ ]] && [ "${sel}" -gt 0 ] && [ "${sel}" -le "${#s_names[@]}" ]; then
        local name="${s_names[$((sel - 1))]}"
        local slug
        slug="$(servers_slug "${name}")"
        local logfile="${SERVERS_LOG_DIR}/${slug}.log"
        if [ -f "${logfile}" ]; then
            echo -e "${C_INFO}Exibindo logs de ${name} (${logfile}):${C_RESET}"
            ui_separator
            tail -n 25 "${logfile}"
        else
            echo -e "${C_MUTED}Nenhum log encontrado para ${name}.${C_RESET}"
        fi
    fi
    echo ""
}

# 6. Cadastrar Novo Servidor
servers_add() {
    servers_init
    ui_header "CADASTRAR NOVO SERVIDOR LOCAL"
    echo -e -n "${C_PRIMARY}Nome do servidor (ex: Servidor Web Node): ${C_RESET}"
    read -r name
    [ -z "${name}" ] && return

    echo -e -n "${C_PRIMARY}Comando para execução (ex: python3 -m http.server 3000): ${C_RESET}"
    read -r cmd
    [ -z "${cmd}" ] && return

    echo -e -n "${C_PRIMARY}Diretório do servidor (padrão '.' para atual): ${C_RESET}"
    read -r dir
    [ -z "${dir}" ] && dir="."

    echo -e -n "${C_PRIMARY}Porta TCP utilizada (ex: 3000): ${C_RESET}"
    read -r port
    [ -z "${port}" ] && port="80"

    echo -e -n "${C_PRIMARY}Descrição curta: ${C_RESET}"
    read -r desc
    [ -z "${desc}" ] && desc="Servidor cadastrado pelo usuário"

    echo "${name}|${cmd}|${dir}|${port}|${desc}" >> "${SERVERS_CONF}"
    ui_msg_success "Servidor '${name}' cadastrado em ${SERVERS_CONF}."
}

# 7. Remover Servidor Cadastrado
servers_remove() {
    servers_init
    ui_header "REMOVER SERVIDOR CADASTRADO"
    servers_status
    echo -e -n "${C_PRIMARY}Digite o NOME EXATO do servidor para remover: ${C_RESET}"
    read -r del_name
    [ -z "${del_name}" ] && return

    if grep -q "^${del_name}|" "${SERVERS_CONF}"; then
        if utils_confirm "Tem certeza que deseja remover '${del_name}' do cadastro?"; then
            sed -i "/^${del_name}|/d" "${SERVERS_CONF}"
            ui_msg_success "Servidor '${del_name}' removido do arquivo de configuração."
        fi
    else
        ui_msg_error "Servidor não encontrado."
    fi
}

# Submenu principal do Módulo Servidores
servers_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO SERVIDORES LOCAIS"
        echo -e "  ${C_BOLD}1${C_RESET} │ 📊 Ver Status, PID e Porta dos Servidores"
        echo -e "  ${C_BOLD}2${C_RESET} │ ▶️  Iniciar um Servidor"
        echo -e "  ${C_BOLD}3${C_RESET} │ ⏹️  Parar um Servidor"
        echo -e "  ${C_BOLD}4${C_RESET} │ 🔄 Reiniciar um Servidor"
        echo -e "  ${C_BOLD}5${C_RESET} │ 📜 Visualizar Logs do Servidor"
        echo -e "  ${C_BOLD}6${C_RESET} │ ➕ Cadastrar Novo Servidor"
        echo -e "  ${C_BOLD}7${C_RESET} │ 🗑️  Remover Servidor Cadastrado"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-7]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) servers_status; ui_pause ;;
            2) servers_start; ui_pause ;;
            3) servers_stop; ui_pause ;;
            4) servers_restart; ui_pause ;;
            5) servers_view_logs; ui_pause ;;
            6) servers_add; ui_pause ;;
            7) servers_remove; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
