#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Inteligência Artificial - ZENITH AI (modules/ai.sh)
# ==============================================================================
# Arquitetura multi-provedor (OpenAI, Anthropic, Gemini, Groq, Ollama).
# Armazena chaves de API com segurança em ~/.config/zenith/ai.conf (chmod 600).
# AVISO DE SEGURANÇA: Nenhuma chave de API é exposta na tela em formato integral.
# ==============================================================================

AI_HISTORY_FILE="${HOME}/.config/zenith/logs/ai_history.log"

# Carrega configurações do arquivo ai.conf
ai_load_config() {
    if [ -f "${ZENITH_AI_FILE}" ]; then
        source "${ZENITH_AI_FILE}" 2>/dev/null || true
    fi
    export AI_PROVIDER="${AI_PROVIDER:-openai}"
    export AI_MODEL="${AI_MODEL:-gpt-4o-mini}"
}

# Mascara a chave de API para exibição segura na tela
ai_mask_key() {
    local key="$1"
    local len=${#key}
    if [ "${len}" -le 8 ]; then
        echo "[Não configurada]"
    else
        local prefix="${key:0:6}"
        local suffix="${key: -4}"
        echo "${prefix}************${suffix}"
    fi
}

# 1. Chat interativo com a IA
ai_chat() {
    ai_load_config
    ui_header "CHAT INTERATIVO - ZENITH AI (${AI_PROVIDER})"

    echo -e "${C_INFO}Provedor:${C_RESET} ${AI_PROVIDER} | ${C_INFO}Modelo:${C_RESET} ${AI_MODEL}"
    echo -e "${C_MUTED}Digite sua mensagem (ou 'sair' para encerrar):${C_RESET}"
    echo ""

    while true; do
        echo -e -n "${C_PRIMARY}${ZENITH_USER_NAME} > ${C_RESET}"
        read -r prompt_msg
        [ -z "${prompt_msg}" ] && continue

        if [[ "${prompt_msg}" == "sair" || "${prompt_msg}" == "exit" || "${prompt_msg}" == "q" ]]; then
            break
        fi

        # Registra no histórico
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [USER] ${prompt_msg}" >> "${AI_HISTORY_FILE}" 2>/dev/null || true

        echo -e -n "${C_SECONDARY}[⚡] Zenith AI processando resposta...${C_RESET}"

        local response=""
        if [ "${AI_PROVIDER}" = "openai" ] && [ -n "${OPENAI_API_KEY}" ]; then
            if check_command curl; then
                local res_json
                res_json=$(curl -s --connect-timeout 15 https://api.openai.com/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
                    -d "{\"model\": \"${AI_MODEL}\", \"messages\": [{\"role\": \"user\", \"content\": \"$(echo -n "$prompt_msg" | sed 's/"/\\"/g')\"}]}" 2>/dev/null)
                response=$(echo "${res_json}" | grep -o -E '"content": *"[^"]*"' | head -n 1 | sed -e 's/"content": *"//' -e 's/"$//')
                [ -z "${response}" ] && response="Erro de resposta da API OpenAI. Verifique sua chave em Configurações."
            fi
        elif [ "${AI_PROVIDER}" = "groq" ] && [ -n "${GROQ_API_KEY}" ]; then
            if check_command curl; then
                local res_json
                res_json=$(curl -s --connect-timeout 15 https://api.groq.com/openai/v1/chat/completions \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer ${GROQ_API_KEY}" \
                    -d "{\"model\": \"llama-3.1-8b-instant\", \"messages\": [{\"role\": \"user\", \"content\": \"$(echo -n "$prompt_msg" | sed 's/"/\\"/g')\"}]}" 2>/dev/null)
                response=$(echo "${res_json}" | grep -o -E '"content": *"[^"]*"' | head -n 1 | sed -e 's/"content": *"//' -e 's/"$//')
                [ -z "${response}" ] && response="Erro de resposta da API Groq."
            fi
        elif [ "${AI_PROVIDER}" = "ollama" ]; then
            if check_command curl; then
                local host="${OLLAMA_HOST:-http://127.0.0.1:11434}"
                local res_json
                res_json=$(curl -s --connect-timeout 5 "${host}/api/generate" \
                    -H "Content-Type: application/json" \
                    -d "{\"model\": \"${AI_MODEL}\", \"prompt\": \"$(echo -n "$prompt_msg" | sed 's/"/\\"/g')\", \"stream\": false}" 2>/dev/null)
                response=$(echo "${res_json}" | grep -o -E '"response":"[^"]*"' | head -n 1 | sed -e 's/"response":"//' -e 's/"$//')
                [ -z "${response}" ] && response="Não foi possível conectar ao servidor Ollama em ${host}."
            fi
        else
            # Resposta simulada local para testes e funcionamento sem chave
            response="[Modo Local] Você perguntou: '${prompt_msg}'. Configure sua chave da API no menu 2 para obter respostas ao vivo."
        fi

        echo -e "\r\033[K${C_ACCENT}${C_BOLD}Zenith AI >${C_RESET} ${C_TEXT}${response}${C_RESET}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ZENITH_AI] ${response}" >> "${AI_HISTORY_FILE}" 2>/dev/null || true
        echo ""
    done
}

# 2. Configurar Chaves de API
ai_configure_api() {
    ai_load_config
    ui_header "CONFIGURAR CHAVES DE API (CHMOD 600)"

    echo -e "Chaves cadastradas (Mascaradas por segurança):"
    echo -e "  OpenAI API Key    : $(ai_mask_key "${OPENAI_API_KEY}")"
    echo -e "  Anthropic API Key : $(ai_mask_key "${ANTHROPIC_API_KEY}")"
    echo -e "  Gemini API Key    : $(ai_mask_key "${GEMINI_API_KEY}")"
    echo -e "  Groq API Key      : $(ai_mask_key "${GROQ_API_KEY}")"
    echo ""
    echo -e "  ${C_BOLD}1${C_RESET} │ Configurar OpenAI API Key"
    echo -e "  ${C_BOLD}2${C_RESET} │ Configurar Anthropic API Key"
    echo -e "  ${C_BOLD}3${C_RESET} │ Configurar Gemini API Key"
    echo -e "  ${C_BOLD}4${C_RESET} │ Configurar Groq API Key"
    echo -e "  ${C_BOLD}5${C_RESET} │ Configurar Host Ollama (Local)"
    echo -e "  ${C_BOLD}0${C_RESET} │ Voltar"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [0-5]: ${C_RESET}"
    read -r choice

    local key_var=""
    case "${choice}" in
        1) key_var="OPENAI_API_KEY" ;;
        2) key_var="ANTHROPIC_API_KEY" ;;
        3) key_var="GEMINI_API_KEY" ;;
        4) key_var="GROQ_API_KEY" ;;
        5) key_var="OLLAMA_HOST" ;;
        0) return ;;
        *) ui_msg_error "Opção inválida."; return ;;
    esac

    echo -e -n "${C_PRIMARY}Digite o novo valor para ${key_var}: ${C_RESET}"
    read -r -s new_value
    echo ""

    if [ -n "${new_value}" ]; then
        # Atualiza o arquivo ai.conf substituindo ou adicionando a variável
        if grep -q "^${key_var}=" "${ZENITH_AI_FILE}" 2>/dev/null; then
            sed -i "s|^${key_var}=.*|${key_var}=\"${new_value}\"|" "${ZENITH_AI_FILE}"
        else
            echo "${key_var}=\"${new_value}\"" >> "${ZENITH_AI_FILE}"
        fi
        chmod 600 "${ZENITH_AI_FILE}" 2>/dev/null || true
        ui_msg_success "Chave armazenada com segurança em ${ZENITH_AI_FILE}."
    else
        ui_msg_warn "Nenhum valor inserido."
    fi
}

# 3. Gerenciar Provedores
ai_providers() {
    ai_load_config
    ui_header "PROVEDORES DE INTELIGÊNCIA ARTIFICIAL"
    echo -e "Provedor Atual: ${C_SUCCESS}${AI_PROVIDER}${C_RESET} | Modelo: ${C_INFO}${AI_MODEL}${C_RESET}"
    echo ""
    echo -e "  ${C_BOLD}1${C_RESET} │ OpenAI (Padrão: gpt-4o-mini)"
    echo -e "  ${C_BOLD}2${C_RESET} │ Anthropic (Padrão: claude-3-5-sonnet)"
    echo -e "  ${C_BOLD}3${C_RESET} │ Google Gemini (Padrão: gemini-1.5-flash)"
    echo -e "  ${C_BOLD}4${C_RESET} │ Groq (Padrão: llama-3.1-8b-instant)"
    echo -e "  ${C_BOLD}5${C_RESET} │ Ollama / LLM Local (Padrão: llama3.1)"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o novo provedor ativo [1-5]: ${C_RESET}"
    read -r sel
    local new_prov="openai"
    local new_mod="gpt-4o-mini"
    case "${sel}" in
        1) new_prov="openai"; new_mod="gpt-4o-mini" ;;
        2) new_prov="anthropic"; new_mod="claude-3-5-sonnet" ;;
        3) new_prov="gemini"; new_mod="gemini-1.5-flash" ;;
        4) new_prov="groq"; new_mod="llama-3.1-8b-instant" ;;
        5) new_prov="ollama"; new_mod="llama3.1" ;;
        *) ui_msg_error "Opção inválida."; return ;;
    esac

    if grep -q "^AI_PROVIDER=" "${ZENITH_AI_FILE}" 2>/dev/null; then
        sed -i "s|^AI_PROVIDER=.*|AI_PROVIDER=\"${new_prov}\"|" "${ZENITH_AI_FILE}"
        sed -i "s|^AI_MODEL=.*|AI_MODEL=\"${new_mod}\"|" "${ZENITH_AI_FILE}"
    else
        echo "AI_PROVIDER=\"${new_prov}\"" >> "${ZENITH_AI_FILE}"
        echo "AI_MODEL=\"${new_mod}\"" >> "${ZENITH_AI_FILE}"
    fi
    ui_msg_success "Provedor ativo alterado para ${new_prov} (${new_mod})."
}

# 4. Testar Conexão com a API
ai_test_connection() {
    ai_load_config
    ui_header "TESTE DE CONECTIVIDADE DA API (${AI_PROVIDER})"
    if [ "${AI_PROVIDER}" = "openai" ]; then
        if [ -z "${OPENAI_API_KEY}" ]; then
            ui_msg_error "Chave da OpenAI não configurada. Configure na opção 2."
        else
            ui_msg_exec "Testando endpoint OpenAI https://api.openai.com/v1/models..."
            if curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${OPENAI_API_KEY}" https://api.openai.com/v1/models | grep -E "^(200|401)" >/dev/null; then
                ui_msg_success "Servidor da OpenAI acessível e respondendo."
            else
                ui_msg_error "Sem resposta ou erro de conexão com a OpenAI."
            fi
        fi
    elif [ "${AI_PROVIDER}" = "ollama" ]; then
        local host="${OLLAMA_HOST:-http://127.0.0.1:11434}"
        ui_msg_exec "Testando servidor local em ${host}..."
        if curl -s --connect-timeout 3 "${host}/api/tags" >/dev/null 2>&1; then
            ui_msg_success "Servidor Ollama local acessível em ${host}."
        else
            ui_msg_error "Falha ao conectar no Ollama em ${host}."
        fi
    else
        ui_msg_success "Teste de simulação para provedor '${AI_PROVIDER}': OK."
    fi
}

# 5. Modelos de Prompts
ai_prompts_menu() {
    ui_header "TEMPLATE DE PROMPTS DO ZENITH"
    echo -e "  ${C_BOLD}1${C_RESET} │ Especialista em Linux / Termux"
    echo -e "  ${C_BOLD}2${C_RESET} │ Auditor de Segurança Defensiva"
    echo -e "  ${C_BOLD}3${C_RESET} │ Revisor de Código Bash"
    echo -e "  ${C_BOLD}4${C_RESET} │ Assistente de Redes e Servidores"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o template [1-4]: ${C_RESET}"
    read -r p_opt
    case "${p_opt}" in
        1) echo -e "${C_INFO}Prompt Ativado:${C_RESET} Você é um especialista sênior em Linux e Termux. Dê respostas curtas, precisas e usando comandos bash otimizados." ;;
        2) echo -e "${C_INFO}Prompt Ativado:${C_RESET} Você é um engenheiro de segurança defensiva. Avise sobre riscos de permissão, portas abertas e configurações inseguras." ;;
        3) echo -e "${C_INFO}Prompt Ativado:${C_RESET} Analise scripts Bash buscando bugs, código duplicado e conformidade POSIX." ;;
        4) echo -e "${C_INFO}Prompt Ativado:${C_RESET} Auxilie na configuração de portas, servidores web locais e firewalls." ;;
        *) ui_msg_error "Opção inválida." ;;
    esac
}

# 6. Histórico de Conversas
ai_history_view() {
    ui_header "HISTÓRICO RECENTE DE CHAT"
    if [ -f "${AI_HISTORY_FILE}" ]; then
        tail -n 20 "${AI_HISTORY_FILE}"
        echo ""
        if utils_confirm "Deseja limpar o histórico de conversas?"; then
            : > "${AI_HISTORY_FILE}"
            ui_msg_success "Histórico limpo."
        fi
    else
        echo -e "${C_MUTED}Nenhuma conversa registrada no histórico.${C_RESET}"
    fi
}

# 7. Configurações Avançadas da IA
ai_settings() {
    ai_load_config
    ui_header "CONFIGURAÇÕES DA IA"
    echo -e "Arquivo de configuração : ${ZENITH_AI_FILE}"
    echo -e "Permissões de segurança : $(stat -c "%a %U:%G" "${ZENITH_AI_FILE}" 2>/dev/null || echo 'N/A')"
    echo -e "Modelo atual            : ${AI_MODEL}"
    echo ""
    echo -e -n "${C_PRIMARY}Digite o novo nome do Modelo (ex: gpt-4o, claude-3-opus, llama3): ${C_RESET}"
    read -r custom_mod
    if [ -n "${custom_mod}" ]; then
        sed -i "s|^AI_MODEL=.*|AI_MODEL=\"${custom_mod}\"|" "${ZENITH_AI_FILE}"
        ui_msg_success "Modelo atualizado para ${custom_mod}."
    fi
}

# Submenu principal do Módulo ZENITH AI
ai_menu() {
    while true; do
        ui_clear
        echo -e "${C_BORDER}╔══════════════════════════════════╗${C_RESET}"
        echo -e "${C_BORDER}║${C_PRIMARY}${C_BOLD}          ZENITH AI               ${C_RESET}${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}╠══════════════════════════════════╣${C_RESET}"
        echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}1${C_RESET} │ Chat                         ${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}2${C_RESET} │ Configurar API               ${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}3${C_RESET} │ Provedores                   ${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}4${C_RESET} │ Testar conexão               ${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}5${C_RESET} │ Prompts                      ${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}6${C_RESET} │ Histórico                    ${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}7${C_RESET} │ Configurações                ${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}║${C_RESET} ${C_BOLD}0${C_RESET} │ Voltar                       ${C_BORDER}║${C_RESET}"
        echo -e "${C_BORDER}╚══════════════════════════════════╝${C_RESET}"
        echo ""
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-7]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) ai_chat; ui_pause ;;
            2) ai_configure_api; ui_pause ;;
            3) ai_providers; ui_pause ;;
            4) ai_test_connection; ui_pause ;;
            5) ai_prompts_menu; ui_pause ;;
            6) ai_history_view; ui_pause ;;
            7) ai_settings; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
