#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Testes Unitários de Plugins (tests/test_plugins.sh)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
export ZENITH_DIR="${SCRIPT_DIR}"

for mod in colors checks config logger utils ui; do
    source "${ZENITH_DIR}/core/${mod}.sh"
done
source "${ZENITH_DIR}/modules/plugins.sh"

echo ">>> [TEST 1] Inicializando diretório e listagem de plugins..."
plugins_init
all_p=$(plugins_get_all)
if [ -z "${all_p}" ]; then
    echo "Nenhum plugin listado. Verificando se ./plugins existe..."
    [ -d "${ZENITH_DIR}/plugins" ] || { echo "Pasta plugins ausente"; exit 1; }
fi
echo "✓ Carregamento de plugins validado."

echo ">>> [TEST 2] Verificando plugin exemplo.sh..."
[ -f "${ZENITH_DIR}/plugins/exemplo.sh" ] || { echo "exemplo.sh ausente"; exit 1; }
bash "${ZENITH_DIR}/plugins/exemplo.sh" > /dev/null
echo "✓ Execução do plugin exemplo.sh OK."

echo ">>> TEST_PLUGINS APROVADO COM SUCESSO!"
exit 0
