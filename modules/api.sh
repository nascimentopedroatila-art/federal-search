#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Consultas e APIs Genéricas (modules/api.sh)
# ==============================================================================
# Cliente HTTP / REST no terminal para teste, diagnóstico e automação de APIs.
# REGRAS: Exclusivamente para APIs públicas, autorizadas e testes legítimos.
# ==============================================================================

API_ENDPOINTS_CONF="${HOME}/.config/zenith/api_endpoints.conf"
API_HISTORY_FILE="${HOME}/.config/zenith/logs/api_history.log"
API_LAST_RESPONSE="${HOME}/.config/zenith/logs/last_api_response.json"

api_init() {
    mkdir -p "$(dirname "${API_ENDPOINTS_CONF}")"
    mkdir -p "$(dirname "${API_HISTORY_FILE}")"
    if [ ! -f "${API_ENDPOINTS_CONF}" ]; then
        cat << 'EOF' > "${API_ENDPOINTS_CONF}"
# Zenith Panel - Endpoints de API Cadastrados
# Formato: NOME|URL|MÉTODO|CABEÇALHOS|DESCRIÇÃO
GitHub Octocat|https://api.github.com/users/octocat|GET|-H "User-Agent: ZenithPanel"|API pública do GitHub
JSONPlaceholder Todo|https://jsonplaceholder.typicode.com/todos/1|GET|-H "Accept: application/json"|API REST pública de teste
HTTPBin IP|https://httpbin.org/ip|GET|-H "Accept: application/json"|Retorna IP via serviço HTTPBin
EOF
    fi
}

# 1. Selecionar e Visualizar Endpoints Cadastrados
api_list_endpoints() {
    api_init
    ui_header "ENDPOINTS DE API CADASTRADOS"
    printf "  %-4s %-20s %-8s %-32s\n" "ID" "NOME" "MÉTODO" "URL"
    ui_separator
    local idx=1
    while IFS='|' read -r ename eurl emeth ehead edesc; do
        [[ "${ename}" =~ ^# ]] && continue
        [ -z "${ename}" ] && continue
        printf "  %-4s %-20s %-8s %-32s\n" "${idx}" "${ename:0:20}" "${emeth}" "${eurl:0:32}..."
        idx=$((idx + 1))
    done < "${API_ENDPOINTS_CONF}"
    echo ""
}

# 2. Testar Conexão Rápida com um Endpoint
api_test_endpoint() {
    api_init
    ui_header "TESTE DE CONECTIVIDADE COM ENDPOINT"
    local idx=1
    local e_names=()
    local e_urls=()
    local e_meths=()

    while IFS='|' read -r ename eurl emeth ehead edesc; do
        [[ "${ename}" =~ ^# ]] && continue
        [ -z "${ename}" ] && continue
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ ${C_TEXT}${ename}${C_RESET} (${emeth} -> ${eurl})"
        e_names+=("${ename}")
        e_urls+=("${eurl}")
        e_meths+=("${emeth}")
        idx=$((idx + 1))
    done < "${API_ENDPOINTS_CONF}"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o endpoint para testar [1-$((idx - 1))]: ${C_RESET}"
    read -r sel
    if [[ "${sel}" =~ ^[0-9]+$ ]] && [ "${sel}" -gt 0 ] && [ "${sel}" -le "${#e_names[@]}" ]; then
        local url="${e_urls[$((sel - 1))]}"
        local name="${e_names[$((sel - 1))]}"
        ui_msg_exec "Testando requisição HTTP em: ${url}..."

        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "${url}" 2>/dev/null)
        if [ "${http_code}" -ge 200 ] && [ "${http_code}" -lt 400 ] 2>/dev/null; then
            echo -e "${C_SUCCESS}[✓] Teste BEM SUCEDIDO: Status HTTP ${http_code} (${name})${C_RESET}"
        else
            echo -e "${C_ERROR}[×] Falha ou Erro: Status HTTP ${http_code:-Sem resposta}${C_RESET}"
        fi
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] TEST_ENDPOINT: ${name} (${url}) -> HTTP ${http_code}" >> "${API_HISTORY_FILE}"
    fi
}

# 3. Fazer Requisição Personalizada
api_request() {
    api_init
    ui_header "FAZER REQUISIÇÃO REST / HTTP"
    echo -e -n "${C_PRIMARY}URL de Destino (ex: https://api.github.com): ${C_RESET}"
    read -r url
    [ -z "${url}" ] && return

    echo -e -n "${C_PRIMARY}Método [GET/POST/PUT/DELETE] (padrão GET): ${C_RESET}"
    read -r method
    method=$(echo "${method}" | tr '[:lower:]' '[:upper:]')
    [ -z "${method}" ] && method="GET"

    echo -e -n "${C_PRIMARY}Cabeçalho de Authorization / Bearer token opcional: ${C_RESET}"
    read -r -s token
    echo ""

    local data_payload=""
    if [[ "${method}" == "POST" || "${method}" == "PUT" ]]; then
        echo -e -n "${C_PRIMARY}Conteúdo JSON do Body (ou deixe vazio): ${C_RESET}"
        read -r data_payload
    fi

    ui_msg_exec "Disparando ${method} em ${url}..."
    local curl_cmd="curl -s -X ${method} --connect-timeout 10"
    if [ -n "${token}" ]; then
        curl_cmd="${curl_cmd} -H \"Authorization: Bearer ${token}\""
    fi
    if [ -n "${data_payload}" ]; then
        curl_cmd="${curl_cmd} -H \"Content-Type: application/json\" -d '${data_payload}'"
    fi
    curl_cmd="${curl_cmd} \"${url}\""

    local response
    response=$(eval "${curl_cmd}" 2>/dev/null)
    echo "${response}" > "${API_LAST_RESPONSE}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] REQ: ${method} ${url} (Tamanho res: ${#response} bytes)" >> "${API_HISTORY_FILE}"

    echo ""
    echo -e "${C_PRIMARY}Resposta da API (salvo em ${API_LAST_RESPONSE}):${C_RESET}"
    ui_separator
    if check_command jq; then
        echo "${response}" | jq . 2>/dev/null || echo "${response}" | head -c 1000
    elif check_command python3; then
        echo "${response}" | python3 -m json.tool 2>/dev/null || echo "${response}" | head -c 1000
    else
        echo "${response}" | head -c 1000
    fi
    echo ""
    echo -e "${C_MUTED}(Exibição limitada a 1000 caracteres se não formatado. Resposta inteira gravada em log)${C_RESET}"
}

# 4. Visualizar Última Resposta e Salvar
api_view_last_response() {
    ui_header "ÚLTIMA RESPOSTA DA API"
    if [ -f "${API_LAST_RESPONSE}" ]; then
        if check_command jq; then
            jq . "${API_LAST_RESPONSE}" 2>/dev/null | head -n 30 || head -n 30 "${API_LAST_RESPONSE}"
        elif check_command python3; then
            python3 -m json.tool "${API_LAST_RESPONSE}" 2>/dev/null | head -n 30 || head -n 30 "${API_LAST_RESPONSE}"
        else
            head -n 30 "${API_LAST_RESPONSE}"
        fi
        echo ""
        echo -e -n "${C_PRIMARY}Deseja copiar para outro arquivo? Digite o nome ou deixe em branco: ${C_RESET}"
        read -r save_path
        if [ -n "${save_path}" ]; then
            cp "${API_LAST_RESPONSE}" "${save_path}" && ui_msg_success "Salvo em ${save_path}"
        fi
    else
        ui_msg_warn "Nenhuma resposta de API registrada nesta sessão."
    fi
}

# 5. Histórico de Requisições
api_history() {
    ui_header "HISTÓRICO DE REQUISIÇÕES E CONSULTAS"
    if [ -f "${API_HISTORY_FILE}" ]; then
        tail -n 20 "${API_HISTORY_FILE}"
    else
        echo -e "${C_MUTED}Nenhum histórico registrado ainda.${C_RESET}"
    fi
    echo ""
}

# 6. Gerenciar Endpoints Cadastrados
api_manage_endpoints() {
    api_init
    ui_header "GERENCIAR ENDPOINTS CADASTRADOS"
    echo -e "  ${C_BOLD}1${C_RESET} │ Cadastrar novo Endpoint"
    echo -e "  ${C_BOLD}2${C_RESET} │ Remover um Endpoint cadastrado"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
    read -r sel
    if [ "${sel}" = "1" ]; then
        echo -e -n "${C_PRIMARY}Nome do endpoint (ex: GitHub Repo Info): ${C_RESET}"
        read -r ename
        [ -z "${ename}" ] && return
        echo -e -n "${C_PRIMARY}URL (ex: https://api.github.com/repos/user/repo): ${C_RESET}"
        read -r eurl
        [ -z "${eurl}" ] && return
        echo -e -n "${C_PRIMARY}Método HTTP [GET/POST]: ${C_RESET}"
        read -r emeth
        [ -z "${emeth}" ] && emeth="GET"
        echo -e -n "${C_PRIMARY}Descrição curta: ${C_RESET}"
        read -r edesc

        echo "${ename}|${eurl}|${emeth}||${edesc:-API cadastrada pelo usuário}" >> "${API_ENDPOINTS_CONF}"
        ui_msg_success "Endpoint '${ename}' cadastrado com sucesso!"
    elif [ "${sel}" = "2" ]; then
        api_list_endpoints
        echo -e -n "${C_PRIMARY}Digite o NOME exato do endpoint para excluir: ${C_RESET}"
        read -r del_name
        if grep -q "^${del_name}|" "${API_ENDPOINTS_CONF}"; then
            sed -i "/^${del_name}|/d" "${API_ENDPOINTS_CONF}"
            ui_msg_success "Endpoint removido."
        else
            ui_msg_error "Endpoint não encontrado."
        fi
    fi
}

# Submenu principal do Módulo APIs
api_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO CONSULTAS & APIs"
        echo -e "  ${C_BOLD}1${C_RESET} │ 📋 Listar Endpoints de API Cadastrados"
        echo -e "  ${C_BOLD}2${C_RESET} │ ⚡ Testar Conectividade Rápida com Endpoint"
        echo -e "  ${C_BOLD}3${C_RESET} │ 🚀 Fazer Requisição REST / HTTP Personalizada"
        echo -e "  ${C_BOLD}4${C_RESET} │ 📄 Visualizar / Exportar Última Resposta JSON"
        echo -e "  ${C_BOLD}5${C_RESET} │ 📜 Histórico de Requisições da Sessão"
        echo -e "  ${C_BOLD}6${C_RESET} │ ⚙️  Gerenciar Endpoints (Adicionar / Excluir)"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-6]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) api_list_endpoints; ui_pause ;;
            2) api_test_endpoint; ui_pause ;;
            3) api_request; ui_pause ;;
            4) api_view_last_response; ui_pause ;;
            5) api_history; ui_pause ;;
            6) api_manage_endpoints; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
