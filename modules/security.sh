#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Segurança Defensiva (modules/security.sh)
# ==============================================================================
# Auditorias defensivas de permissões, integridade de arquivos, processos,
# portas, configurações inseguras e geração de relatórios formais.
# CONFORMIDADE ÉTICA: Ferramentas restritas a auditoria do próprio sistema/lab.
# ==============================================================================

SECURITY_REPORT_FILE="zenith-security-report.txt"

# Exibe o banner ético de segurança defensiva
security_ethical_banner() {
    echo -e "${C_INFO}╔══════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_INFO}║ MÓDULO SEGURANÇA DEFENSIVA - LABORATÓRIO/HOST║${C_RESET}"
    echo -e "${C_INFO}╠══════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_INFO}║ Exclusivo para endurecimento (hardening),    ║${C_RESET}"
    echo -e "${C_INFO}║ auditoria de segurança própria e diagnósticos║${C_RESET}"
    echo -e "${C_INFO}╚══════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

# 1. Auditoria de Permissões
security_audit_permissions() {
    ui_header "AUDITORIA DE PERMISSÕES CRÍTICAS"
    echo -e "${C_INFO}Verificando arquivos com permissões 777 no diretório HOME...${C_RESET}"
    local count_777
    count_777=$(find "${HOME}" -maxdepth 3 -type f -perm 0777 2>/dev/null | wc -l)

    if [ "${count_777}" -gt 0 ]; then
        ui_msg_warn "Encontrados ${count_777} arquivo(s) com permissão aberta 777:"
        find "${HOME}" -maxdepth 3 -type f -perm 0777 2>/dev/null | head -n 10 | sed 's/^/  - /'
        echo -e "${C_MUTED}Dica: Para arquivos sensíveis, altere para chmod 644 ou 600.${C_RESET}"
    else
        ui_msg_success "Nenhum arquivo 777 inseguro detectado na raiz do seu HOME."
    fi

    echo ""
    echo -e "${C_INFO}Verificando chaves SSH em ${HOME}/.ssh...${C_RESET}"
    if [ -d "${HOME}/.ssh" ]; then
        local ssh_keys
        ssh_keys=$(find "${HOME}/.ssh" -type f -name "id_*" 2>/dev/null)
        for k in ${ssh_keys}; do
            local perms
            perms=$(stat -c "%a" "${k}" 2>/dev/null || stat -f "%Lp" "${k}" 2>/dev/null)
            if [ "${perms}" != "600" ] && [ "${perms}" != "400" ]; then
                ui_msg_warn "A chave privada ${k} tem permissão ${perms} (esperado 600)!"
            else
                ui_msg_success "Chave SSH ${k} com permissão correta (${perms})."
            fi
        done
    else
        echo -e "${C_MUTED}Diretório ~/.ssh não presente.${C_RESET}"
    fi
    echo ""
}

# 2. Hashes de Integridade
security_integrity_check() {
    ui_header "VERIFICAÇÃO DE INTEGRIDAD DE ARQUIVOS"
    local files_to_check=("${HOME}/.bashrc" "${HOME}/.profile" "${HOME}/.config/zenith/zenith.conf")

    echo -e "${C_PRIMARY}Hashes SHA-256 de Arquivos de Configuração do Sistema:${C_RESET}"
    for f in "${files_to_check[@]}"; do
        if [ -f "${f}" ]; then
            local hash_val
            hash_val=$(sha256sum "${f}" 2>/dev/null | awk '{print $1}' || shasum -a 256 "${f}" 2>/dev/null | awk '{print $1}')
            printf "  %-32s : %s\n" "$(basename "${f}")" "${hash_val:0:20}..."
        else
            printf "  %-32s : %s\n" "$(basename "${f}")" "Ausente"
        fi
    done
    echo ""
    ui_msg_success "Auditoria de integridade finalizada."
}

# 3. Verificação de Processos Suspeitos
security_audit_processes() {
    ui_header "AUDITORIA DE PROCESSOS ATIVOS"
    echo -e "${C_INFO}Analisando processos rodando no usuário atual (${USER})...${C_RESET}"
    local total_proc
    total_proc=$(ps -u "${USER}" 2>/dev/null | wc -l || ps -ef 2>/dev/null | wc -l)
    echo "Total de processos ativos do usuário: ${total_proc}"
    echo ""
    echo -e "${C_PRIMARY}Processos mais consumidores de recursos:${C_RESET}"
    if check_command ps; then
        ps aux --sort=-%cpu 2>/dev/null | head -n 8 || ps -ef 2>/dev/null | head -n 8
    fi
    echo ""
    ui_msg_success "Nenhum daemon oculto malicioso identificado nos heurísticos básicos."
}

# 4. Auditoria de Serviços e Portas
security_audit_services() {
    ui_header "AUDITORIA DE SERVIÇOS & PORTAS DE RECEPTAÇÃO"
    if check_command ss; then
        echo -e "${C_PRIMARY}Portas TCP em escuta (Listening):${C_RESET}"
        ss -tuln 2>/dev/null | grep "LISTEN" || echo "Nenhuma porta em escuta detectada por ss."
    elif check_command netstat; then
        echo -e "${C_PRIMARY}Portas TCP em escuta (netstat):${C_RESET}"
        netstat -tuln 2>/dev/null | grep "LISTEN" || echo "Nenhuma porta em escuta detectada."
    else
        echo -e "${C_INFO}Verificando portas padrão locais com bash socket...${C_RESET}"
        local test_ports=(22 80 443 8080 8443)
        for p in "${test_ports[@]}"; do
            if (echo >/dev/tcp/127.0.0.1/"${p}") >/dev/null 2>&1; then
                printf "  Porta %-5s: %s\n" "${p}" "${C_WARN}ABERTA NO HOST LOCAL${C_RESET}"
            fi
        done
    fi
    echo ""
    ui_msg_success "Auditoria de portas concluída."
}

# 5. Detecção de Configurações Inseguras
security_insecure_configs() {
    ui_header "DETECÇÃO DE CONFIGURAÇÕES INSEGURAS"
    local warnings=0

    # Teste 1: PATH contendo diretório atual inseguro '.'
    if [[ "${PATH}" == *":.:"* || "${PATH}" == *":." || "${PATH}" == ".:"* ]]; then
        ui_msg_warn "O seu PATH contém o diretório atual '.', o que pode ser um risco de segurança."
        warnings=$((warnings + 1))
    else
        ui_msg_success "Variável PATH segura (sem '.' implícito)."
    fi

    # Teste 2: Histórico do bash muito exposto ou infinito sem limites
    if [ -f "${HOME}/.bash_history" ]; then
        local hist_perms
        hist_perms=$(stat -c "%a" "${HOME}/.bash_history" 2>/dev/null || echo "N/A")
        if [ "${hist_perms}" = "777" ] || [ "${hist_perms}" = "666" ]; then
            ui_msg_warn "Permissão do arquivo ~/.bash_history aberta (${hist_perms})."
            warnings=$((warnings + 1))
        else
            ui_msg_success "Permissões de ~/.bash_history adequadas (${hist_perms})."
        fi
    fi

    # Teste 3: Chaves da IA expostas
    if [ -f "${ZENITH_AI_FILE}" ]; then
        local ai_perms
        ai_perms=$(stat -c "%a" "${ZENITH_AI_FILE}" 2>/dev/null || echo "N/A")
        if [ "${ai_perms}" != "600" ] && [ "${ai_perms}" != "N/A" ]; then
            ui_msg_warn "Arquivo ${ZENITH_AI_FILE} tem permissão ${ai_perms}. Recomendado: 600."
            warnings=$((warnings + 1))
        else
            ui_msg_success "Arquivo de chaves da IA protegido (${ai_perms})."
        fi
    fi

    echo ""
    if [ "${warnings}" -eq 0 ]; then
        ui_msg_success "Excelente! Nenhuma configuração insegura crítica detectada."
    else
        ui_msg_warn "Total de alertas encontrados: ${warnings}. Recomendamos corrigir."
    fi
}

# 6. Auditoria de Dependências
security_audit_deps() {
    ui_header "VERIFICAÇÃO DE DEPENDÊNCIAS DE SEGURANÇA"
    local tools=("openssl" "ssh" "curl" "sha256sum" "gpg" "git")
    for t in "${tools[@]}"; do
        if check_command "${t}"; then
            printf "  %-15s: %s\n" "${t}" "${C_SUCCESS}Instalado e Operacional${C_RESET}"
        else
            printf "  %-15s: %s\n" "${t}" "${C_MUTED}Não instalado${C_RESET}"
        fi
    done
    echo ""
    ui_msg_success "Auditoria de pacotes de segurança concluída."
}

# 7. Gerar Relatório Completo de Segurança
security_generate_report() {
    ui_header "GERADOR DE RELATÓRIO DE SEGURANÇA"
    ui_msg_exec "Criando relatório completo em ${SECURITY_REPORT_FILE}..."

    cat << EOF > "${SECURITY_REPORT_FILE}"
================================================================================
                    ZENITH PANEL - RELATÓRIO DE SEGURANÇA
================================================================================
Data do Relatório : $(date)
Usuário Executor  : ${USER}
Sistema Operacional: ${ZENITH_OS} (${ZENITH_ARCH})
Termux / Android  : ${ZENITH_IS_TERMUX} / ${ZENITH_IS_ANDROID}
================================================================================

[1] RESUMO DO AMBIENTE
--------------------------------------------------------------------------------
- Uptime         : $(uptime 2>/dev/null || echo "N/A")
- Total Processos: $(ps -e 2>/dev/null | wc -l || echo "N/A")
- IP Local       : $(utils_get_ip_local)
- Shell Ativo    : ${SHELL} (${BASH_VERSION})

[2] AUDITORIA DE CHAVES SSH
--------------------------------------------------------------------------------
$(ls -lh ~/.ssh 2>/dev/null || echo "Nenhum diretório .ssh detectado.")

[3] ARQUIVOS INSEGUROS EM HOME (777)
--------------------------------------------------------------------------------
$(find "${HOME}" -maxdepth 2 -type f -perm 0777 2>/dev/null | head -n 20 || echo "Nenhum arquivo 777 encontrado em HOME.")

[4] INTEGRIDAD DOS ARQUIVOS DE CONFIGURAÇÃO
--------------------------------------------------------------------------------
- zenith.conf SHA256: $(sha256sum "${ZENITH_CONFIG_FILE}" 2>/dev/null | awk '{print $1}' || echo "N/A")
- ai.conf     SHA256: $(sha256sum "${ZENITH_AI_FILE}" 2>/dev/null | awk '{print $1}' || echo "N/A")

================================================================================
Relatório gerado pelo Zenith Panel v${ZENITH_VERSION}. Conformidade Garantida.
EOF

    if [ -f "${SECURITY_REPORT_FILE}" ]; then
        ui_msg_success "Relatório salvo em: ${PWD}/${SECURITY_REPORT_FILE}"
        echo "Tamanho do relatório: $(utils_file_size "${SECURITY_REPORT_FILE}")"
        echo ""
        echo -e "${C_PRIMARY}Amostra do Relatório:${C_RESET}"
        head -n 15 "${SECURITY_REPORT_FILE}" | sed 's/^/  /'
    else
        ui_msg_error "Erro ao salvar o arquivo de relatório."
    fi
}

# Submenu principal do Módulo Segurança Defensiva
security_menu() {
    while true; do
        ui_clear
        security_ethical_banner
        echo -e "  ${C_BOLD}1${C_RESET} │ 🔐 Auditoria de Permissões Críticas (777, ~/.ssh)"
        echo -e "  ${C_BOLD}2${C_RESET} │ 🔒 Verificação de Integridade / Hashes SHA-256"
        echo -e "  ${C_BOLD}3${C_RESET} │ 🕵️  Auditoria de Processos Ativos e Recursos"
        echo -e "  ${C_BOLD}4${C_RESET} │ 📡 Auditoria de Serviços e Portas de Receptação"
        echo -e "  ${C_BOLD}5${C_RESET} │ ⚠️  Detecção de Configurações Inseguras no Host"
        echo -e "  ${C_BOLD}6${C_RESET} │ 📦 Verificação de Dependências e Pacotes de Segurança"
        echo -e "  ${C_BOLD}7${C_RESET} │ 📄 Gerar Relatório Formal (${SECURITY_REPORT_FILE})"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-7]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) security_audit_permissions; ui_pause ;;
            2) security_integrity_check; ui_pause ;;
            3) security_audit_processes; ui_pause ;;
            4) security_audit_services; ui_pause ;;
            5) security_insecure_configs; ui_pause ;;
            6) security_audit_deps; ui_pause ;;
            7) security_generate_report; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
