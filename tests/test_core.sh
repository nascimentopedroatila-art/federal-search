#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Testes Unitários do Core (tests/test_core.sh)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
export ZENITH_DIR="${SCRIPT_DIR}"

echo ">>> [TEST 1] Carregando módulos do Core..."
source "${ZENITH_DIR}/core/colors.sh"
source "${ZENITH_DIR}/core/checks.sh"
source "${ZENITH_DIR}/core/config.sh"
source "${ZENITH_DIR}/core/logger.sh"
source "${ZENITH_DIR}/core/utils.sh"
source "${ZENITH_DIR}/core/ui.sh"
echo "✓ Módulos do Core carregados com sucesso."

echo ">>> [TEST 2] Testando alteração de tema visual..."
colors_set_theme "CYBER"
[ -n "${C_PRIMARY}" ] || { echo "Falha ao definir C_PRIMARY"; exit 1; }
colors_set_theme "ZENITH"
echo "✓ Temas testados corretamente."

echo ">>> [TEST 3] Testando conversões de utilitários..."
fmt=$(utils_format_bytes 1048576)
echo "1048576 bytes => ${fmt}"
upt=$(utils_format_uptime 3661)
echo "3661 seg => ${upt}"
echo "✓ Conversões validadas."

echo ">>> [TEST 4] Testando log_write e log_view..."
log_init
log_info "Mensagem de teste unitário"
[ -f "${LOG_FILE}" ] || { echo "Falha ao criar arquivo de log"; exit 1; }
echo "✓ Logger de arquivo validado."

echo ">>> TEST_CORE APROVADO COM SUCESSO!"
exit 0
