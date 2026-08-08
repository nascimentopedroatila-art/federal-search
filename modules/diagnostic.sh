#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Diagnóstico do Sistema (modules/diagnostic.sh)
# ==============================================================================
# Executa checagem completa de saúde do ambiente, dependências e diretórios
# e gera um relatório formal na raiz: zenith-diagnostic.txt.
# ==============================================================================

DIAGNOSTIC_FILE="zenith-diagnostic.txt"

# Executa teste individual e imprime com cor
diag_item() {
    local label="$1"
    local status="$2"
    local detail="$3"
    if [ "${status}" = "OK" ]; then
        printf "  %-26s: %b %s\n" "${label}" "${C_SUCCESS}✓${C_RESET}" "${detail}"
    elif [ "${status}" = "WARN" ]; then
        printf "  %-26s: %b %s\n" "${label}" "${C_WARN}!${C_RESET}" "${detail}"
    else
        printf "  %-26s: %b %s\n" "${label}" "${C_ERROR}×${C_RESET}" "${detail}"
    fi
}

# 1. Rodar Diagnóstico Automático Completo
diagnostic_run() {
    ui_header "DIAGNÓSTICO AUTOMÁTICO DO SISTEMA"

    local t_termux="WARN"
    local d_termux="Ambiente Linux genérico (${ZENITH_OS})"
    if [ "${ZENITH_IS_TERMUX}" = true ]; then
        t_termux="OK"
        d_termux="Termux Android ativo (${PREFIX})"
    fi

    local t_bash="OK"
    local d_bash="${BASH_VERSION}"

    local t_storage="OK"
    local d_storage
    d_storage="$(df -h "${HOME}" 2>/dev/null | awk 'NR==2 {print $4 " livres"}')"
    [ -z "${d_storage}" ] && { t_storage="WARN"; d_storage="Indisponível"; }

    local t_perms="OK"
    local d_perms="Permissões graváveis em HOME e ~/.config/zenith"
    if [ ! -w "${HOME}" ] || [ ! -w "${ZENITH_CONFIG_DIR}" ]; then
        t_perms="ERROR"
        d_perms="Sem permissão de escrita"
    fi

    local t_net="OK"
    local d_net="Conectado à Internet"
    if ! check_internet; then
        t_net="WARN"
        d_net="Sem acesso ao exterior / Offline"
    fi

    local t_git="OK"
    local d_git
    d_git="$(git --version 2>/dev/null || echo '')"
    [ -z "${d_git}" ] && { t_git="WARN"; d_git="Não instalado"; }

    local t_py="OK"
    local d_py
    d_py="$(python3 --version 2>/dev/null || python --version 2>/dev/null || echo '')"
    [ -z "${d_py}" ] && { t_py="WARN"; d_py="Não instalado"; }

    local t_curl="OK"
    local d_curl
    d_curl="$(curl --version 2>/dev/null | head -n 1 | awk '{print $1 " " $2}' || echo '')"
    [ -z "${d_curl}" ] && { t_curl="WARN"; d_curl="Não instalado"; }

    local t_wget="OK"
    local d_wget
    d_wget="$(wget --version 2>/dev/null | head -n 1 | awk '{print $1 " " $2}' || echo '')"
    [ -z "${d_wget}" ] && { t_wget="WARN"; d_wget="Não instalado"; }

    local t_api="OK"
    local d_api="Termux:API instalada"
    if ! check_termux_api; then
        t_api="WARN"
        d_api="Não encontrada (alguns recursos ficarão indisponíveis)"
    fi

    local t_linux="OK"
    local d_linux="Host ${ZENITH_OS}"
    if check_command proot-distro; then
        d_linux="proot-distro ativo e disponível"
    fi

    local t_dirs="OK"
    local d_dirs="Estrutura do Zenith funcional"
    for d in "${ZENITH_CONFIG_DIR}" "${ZENITH_BACKUP_DIR}" "${ZENITH_LOG_DIR}" "plugins"; do
        if [ ! -d "${d}" ]; then
            t_dirs="WARN"
            d_dirs="Diretório ${d} ausente (será recriado no init)"
            mkdir -p "${d}" 2>/dev/null || true
        fi
    done

    # Exibe na tela
    diag_item "Termux" "${t_termux}" "${d_termux}"
    diag_item "Bash" "${t_bash}" "${d_bash}"
    diag_item "armazenamento" "${t_storage}" "${d_storage}"
    diag_item "permissões" "${t_perms}" "${d_perms}"
    diag_item "internet" "${t_net}" "${d_net}"
    diag_item "Git" "${t_git}" "${d_git}"
    diag_item "Python" "${t_py}" "${d_py}"
    diag_item "curl" "${t_curl}" "${d_curl}"
    diag_item "wget" "${t_wget}" "${d_wget}"
    diag_item "Termux:API" "${t_api}" "${d_api}"
    diag_item "ambientes Linux" "${t_linux}" "${d_linux}"
    diag_item "diretórios do Zenith" "${t_dirs}" "${d_dirs}"

    # Gera relatório zenith-diagnostic.txt
    cat << EOF > "${DIAGNOSTIC_FILE}"
================================================================================
                    ZENITH PANEL - RELATÓRIO DE DIAGNÓSTICO
================================================================================
Data da Execução   : $(date)
Versão do Zenith   : ${ZENITH_VERSION}
Usuário Ativo      : ${USER}
Diretório de Trabalho : ${PWD}
================================================================================

[✓/!/×] RESULTADOS DOS TESTES DE DIAGNÓSTICO:
--------------------------------------------------------------------------------
[${t_termux}] Termux            : ${d_termux}
[${t_bash}] Bash              : ${d_bash}
[${t_storage}] armazenamento     : ${d_storage}
[${t_perms}] permissões        : ${d_perms}
[${t_net}] internet          : ${d_net}
[${t_git}] Git               : ${d_git}
[${t_py}] Python            : ${d_py}
[${t_curl}] curl              : ${d_curl}
[${t_wget}] wget              : ${d_wget}
[${t_api}] Termux:API        : ${d_api}
[${t_linux}] ambientes Linux   : ${d_linux}
[${t_dirs}] diretórios Zenith : ${d_dirs}

================================================================================
Relatório salvo automaticamente pelo Zenith Panel.
EOF

    echo ""
    ui_msg_success "Relatório detalhado gerado e salvo em: ${PWD}/${DIAGNOSTIC_FILE}"
    echo "Tamanho do relatório: $(utils_file_size "${DIAGNOSTIC_FILE}")"
}

# Submenu do Módulo Diagnóstico
diagnostic_menu() {
    ui_clear
    diagnostic_run
    ui_pause
}
