#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Suíte Completa de Testes (tests/run_all_tests.sh)
# ==============================================================================
# Executa todos os testes unitários e de integração do projeto.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
export ZENITH_DIR="${SCRIPT_DIR}"

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_PRIMARY="\033[38;5;51m"
C_SUCCESS="\033[38;5;46m"
C_ERROR="\033[38;5;196m"

echo -e "${C_PRIMARY}${C_BOLD}=====================================================${C_RESET}"
echo -e "${C_PRIMARY}${C_BOLD}     🧪 ZENITH PANEL - TEST RUNNER SUITE 🚀          ${C_RESET}"
echo -e "${C_PRIMARY}${C_BOLD}=====================================================${C_RESET}"
echo ""

tests=(
    "tests/test_core.sh"
    "tests/test_system.sh"
    "tests/test_plugins.sh"
    "tests/test_config.sh"
    "tests/test_diagnostic.sh"
)

failed=0

for t in "${tests[@]}"; do
    echo -e "${C_BOLD}-----------------------------------------------------${C_RESET}"
    echo -e "${C_PRIMARY}▶ Executando: ${t}${C_RESET}"
    if bash "${ZENITH_DIR}/${t}"; then
        echo -e "${C_SUCCESS}✓ Teste '${t}' APROVADO.${C_RESET}"
    else
        echo -e "${C_ERROR}× Falha no Teste '${t}'.${C_RESET}"
        failed=$((failed + 1))
    fi
done

echo -e "${C_BOLD}=====================================================${C_RESET}"
if [ "${failed}" -eq 0 ]; then
    echo -e "${C_SUCCESS}${C_BOLD}[✓] TODOS OS TESTES FORAM APROVADOS COM SUCESSO! 🚀${C_RESET}"
    echo -e "${C_BOLD}=====================================================${C_RESET}"
    exit 0
else
    echo -e "${C_ERROR}${C_BOLD}[×] ${failed} teste(s) falharam. Verifique os logs acima.${C_RESET}"
    echo -e "${C_BOLD}=====================================================${C_RESET}"
    exit 1
fi
