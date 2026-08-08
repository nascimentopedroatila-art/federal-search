#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Testes Unitários de Sistema e Monitor (tests/test_system.sh)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
export ZENITH_DIR="${SCRIPT_DIR}"

for mod in colors checks config logger utils ui; do
    source "${ZENITH_DIR}/core/${mod}.sh"
done
source "${ZENITH_DIR}/modules/system.sh"
source "${ZENITH_DIR}/modules/monitor.sh"

echo ">>> [TEST 1] Executando coleta de informações do sistema (sem tela interativa)..."
cpu_cores="$(utils_get_cpu_cores)"
ram_info="$(utils_get_ram_info)"
echo "Núcleos detectados: ${cpu_cores} | RAM: ${ram_info}"

echo ">>> [TEST 2] Verificando se monitor_get_data executa sem falhas..."
monitor_get_data > /dev/null
echo "✓ Módulos system e monitor validados com sucesso."

echo ">>> TEST_SYSTEM APROVADO COM SUCESSO!"
exit 0
