#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Testes Unitários de Diagnóstico (tests/test_diagnostic.sh)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
export ZENITH_DIR="${SCRIPT_DIR}"

for mod in colors checks config logger utils ui; do
    source "${ZENITH_DIR}/core/${mod}.sh"
done
source "${ZENITH_DIR}/modules/diagnostic.sh"

echo ">>> [TEST 1] Executando rotina de diagnóstico automática..."
diagnostic_run > /dev/null
if [ ! -f "zenith-diagnostic.txt" ]; then
    echo "Falha ao gerar arquivo de relatório zenith-diagnostic.txt"
    exit 1
fi
echo "✓ Relatório gerado com sucesso em: zenith-diagnostic.txt"

echo ">>> TEST_DIAGNOSTIC APROVADO COM SUCESSO!"
exit 0
