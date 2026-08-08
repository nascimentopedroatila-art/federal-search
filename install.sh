#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Instalador Oficial (install.sh)
# ==============================================================================
# Detecta Termux/Linux, verifica arquitetura, internet, instala dependências
# (quando autorizado/possível), estrutura os diretórios e instala o comando 'zenith'.
# ==============================================================================

set -e

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_PRIMARY="\033[38;5;51m"
C_SUCCESS="\033[38;5;46m"
C_WARN="\033[38;5;214m"
C_ERROR="\033[38;5;196m"
C_INFO="\033[38;5;39m"
C_BORDER="\033[38;5;51m"

echo -e "${C_PRIMARY}${C_BOLD}=====================================================${C_RESET}"
echo -e "${C_PRIMARY}${C_BOLD}     ⚡ INSTALADOR DO ZENITH PANEL v1.0.0 ⚡         ${C_RESET}"
echo -e "${C_PRIMARY}${C_BOLD}=====================================================${C_RESET}"
echo ""

# 1. Detectar ambiente de instalação
IS_TERMUX=false
if [[ -n "${PREFIX}" && "${PREFIX}" == *"com.termux"* ]] || [ -d "/data/data/com.termux" ]; then
    IS_TERMUX=true
    echo -e "${C_INFO}[•] Ambiente detectado: Termux (Android)${C_RESET}"
else
    echo -e "${C_INFO}[•] Ambiente detectado: Linux Genérico ($(uname -s))${C_RESET}"
fi

# 2. Detectar Arquitetura
ARCH=$(uname -m 2>/dev/null || echo "unknown")
echo -e "${C_INFO}[•] Arquitetura da CPU: ${ARCH}${C_RESET}"

# 3. Verificar Permissões e Diretório Atual
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
echo -e "${C_INFO}[•] Diretório do projeto: ${SCRIPT_DIR}${C_RESET}"

if [ ! -w "${SCRIPT_DIR}" ]; then
    echo -e "${C_ERROR}[×] Erro: Sem permissão de escrita em ${SCRIPT_DIR}.${C_RESET}"
    exit 1
fi

# 4. Verificar Conexão de Internet
echo -e "${C_INFO}[•] Verificando acesso à Internet...${C_RESET}"
if command -v curl >/dev/null 2>&1; then
    if curl -s --connect-timeout 3 "https://clients3.google.com/generate_204" >/dev/null 2>&1; then
        echo -e "${C_SUCCESS}[✓] Internet disponível.${C_RESET}"
    else
        echo -e "${C_WARN}[!] Sem conexão de Internet ativa. Instalação em modo offline...${C_RESET}"
    fi
else
    echo -e "${C_WARN}[!] O utilitário 'curl' não foi detectado.${C_RESET}"
fi

# 5. Instalação opcional de dependências operacionais
if [ "${IS_TERMUX}" = true ] && command -v pkg >/dev/null 2>&1; then
    echo -e "${C_INFO}[•] Verificando pacotes recomendados no Termux...${C_RESET}"
    for dep in curl wget git python; do
        if ! command -v "${dep}" >/dev/null 2>&1; then
            echo -e "${C_INFO}[>] Instalando dependência: ${dep}...${C_RESET}"
            pkg install -y "${dep}" 2>/dev/null || true
        fi
    done
fi

# 6. Criar diretórios de configuração persistente
echo -e "${C_INFO}[•] Estruturando diretórios em ~/.config/zenith/...${C_RESET}"
mkdir -p "${HOME}/.config/zenith/backups"
mkdir -p "${HOME}/.config/zenith/logs"
mkdir -p "${HOME}/.config/zenith/scripts"
mkdir -p "${HOME}/.config/zenith/plugins"

# 7. Garantir permissões de execução nos scripts do painel
chmod +x "${SCRIPT_DIR}/zenith.sh"
chmod +x "${SCRIPT_DIR}/install.sh"
chmod +x "${SCRIPT_DIR}/uninstall.sh"
for f in "${SCRIPT_DIR}"/plugins/*.sh; do
    [ -f "${f}" ] && chmod +x "${f}" 2>/dev/null || true
done

# 8. Criar symlinks / convenções de diretório (zenith-panel apontando para .)
if [ ! -e "${SCRIPT_DIR}/zenith-panel" ]; then
    ln -s "." "${SCRIPT_DIR}/zenith-panel" 2>/dev/null || true
fi

# 9. Criar o comando global "zenith" em um diretório do PATH
BIN_DEST=""
if [ "${IS_TERMUX}" = true ] && [ -n "${PREFIX}" ] && [ -d "${PREFIX}/bin" ] && [ -w "${PREFIX}/bin" ]; then
    BIN_DEST="${PREFIX}/bin/zenith"
elif [ "$(id -u 2>/dev/null)" -eq 0 ] && [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    BIN_DEST="/usr/local/bin/zenith"
elif [ -d "${HOME}/.local/bin" ] || mkdir -p "${HOME}/.local/bin" 2>/dev/null; then
    BIN_DEST="${HOME}/.local/bin/zenith"
    # Adiciona ao PATH se ainda não estiver
    if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
        export PATH="${HOME}/.local/bin:${PATH}"
        for rc in "${HOME}/.bashrc" "${HOME}/.profile"; do
            if [ -f "${rc}" ] && ! grep -q "\.local/bin" "${rc}" 2>/dev/null; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${rc}"
            fi
        done
    fi
else
    BIN_DEST="${SCRIPT_DIR}/zenith"
fi

echo -e "${C_INFO}[•] Instalando executável em: ${BIN_DEST}${C_RESET}"
cat << EOF > "${BIN_DEST}"
#!/usr/bin/env bash
# Wrapper executável do Zenith Panel gerado em $(date)
exec bash "${SCRIPT_DIR}/zenith.sh" "\$@"
EOF
chmod +x "${BIN_DEST}"

# Also make sure there's a symlink or binary accessible directly in /usr/local/bin or current PATH if possible
if [ "${BIN_DEST}" != "/usr/local/bin/zenith" ] && [ -w "/usr/local/bin" ] 2>/dev/null; then
    cp -f "${BIN_DEST}" "/usr/local/bin/zenith" 2>/dev/null || true
    chmod +x "/usr/local/bin/zenith" 2>/dev/null || true
fi

# 10. Testar instalação
if command -v zenith >/dev/null 2>&1 || [ -x "${BIN_DEST}" ]; "${BIN_DEST}" --version >/dev/null 2>&1; then
    echo -e "${C_SUCCESS}[✓] Teste de verificação de sintaxe: OK!${C_RESET}"
else
    echo -e "${C_WARN}[!] Aviso: Verifique se o diretório ${BIN_DEST} está no seu PATH.${C_RESET}"
fi

echo ""
echo -e "${C_BORDER}╔══════════════════════════════════════╗${C_RESET}"
echo -e "${C_BORDER}║${C_RESET}                                      ${C_BORDER}║${C_RESET}"
echo -e "${C_BORDER}║${C_SUCCESS}${C_BOLD}     ZENITH PANEL INSTALADO! 🚀      ${C_RESET}${C_BORDER}║${C_RESET}"
echo -e "${C_BORDER}║${C_RESET}                                      ${C_BORDER}║${C_RESET}"
echo -e "${C_BORDER}║${C_TEXT}     Digite: ${C_PRIMARY}${C_BOLD}zenith${C_RESET}                   ${C_BORDER}║${C_RESET}"
echo -e "${C_BORDER}║${C_RESET}                                      ${C_BORDER}║${C_RESET}"
echo -e "${C_BORDER}╚══════════════════════════════════════╝${C_RESET}"
echo ""
exit 0
