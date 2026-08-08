#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Testes Unitários de Configuração (tests/test_config.sh)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
export ZENITH_DIR="${SCRIPT_DIR}"

for mod in colors checks config logger utils ui; do
    source "${ZENITH_DIR}/core/${mod}.sh"
done

echo ">>> [TEST 1] Inicializando configurações..."
config_init
[ -f "${ZENITH_CONFIG_FILE}" ] || { echo "zenith.conf não criado"; exit 1; }
[ -f "${ZENITH_AI_FILE}" ] || { echo "ai.conf não criado"; exit 1; }
echo "✓ Arquivos de configuração inicializados."

echo ">>> [TEST 2] Testando salvamento e leitura de chaves..."
config_set "USER_NAME" "TestUser_123"
val=$(config_get "USER_NAME" "Default")
if [ "${val}" != "TestUser_123" ]; then
    echo "Falha ao persistir USER_NAME. Lido: ${val}"
    exit 1
fi
echo "✓ Leitura/escrita em config verificada."

echo ">>> TEST_CONFIG APROVADO COM SUCESSO!"
exit 0
