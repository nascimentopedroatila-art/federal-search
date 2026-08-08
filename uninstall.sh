#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Desinstalador Oficial (uninstall.sh)
# ==============================================================================
# Remove o comando 'zenith' e opcionalmente limpa configurações e backups,
# exigindo confirmação explícita do usuário antes de realizar alterações.
# ==============================================================================

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_WARN="\033[38;5;214m"
C_ERROR="\033[38;5;196m"
C_SUCCESS="\033[38;5;46m"

echo -e "${C_WARN}⚠️ O ZENITH PANEL será removido.${C_RESET}"
echo -e "${C_WARN}Configurações e backups podem existir.${C_RESET}"
echo ""
echo -e -n "${C_BOLD}Deseja continuar? [S/N]: ${C_RESET}"
read -r -n 1 response
echo ""

if [[ ! "${response}" =~ ^[sS]$ ]]; then
    echo -e "${C_SUCCESS}Desinstalação cancelada pelo usuário.${C_RESET}"
    exit 0
fi

echo "Removendo executáveis 'zenith' do sistema..."
for bin_path in "/usr/local/bin/zenith" "${HOME}/.local/bin/zenith" "${PREFIX}/bin/zenith"; do
    if [ -f "${bin_path}" ] || [ -L "${bin_path}" ]; then
        rm -f "${bin_path}" 2>/dev/null || sudo rm -f "${bin_path}" 2>/dev/null || true
        echo "  - Removido: ${bin_path}"
    fi
done

echo ""
echo -e -n "${C_WARN}Deseja também excluir as configurações e backups em ~/.config/zenith/? [S/N]: ${C_RESET}"
read -r -n 1 remove_cfg
echo ""
if [[ "${remove_cfg}" =~ ^[sS]$ ]]; then
    rm -rf "${HOME}/.config/zenith" 2>/dev/null || true
    echo -e "${C_SUCCESS}[✓] Configurações e backups em ~/.config/zenith/ excluídos.${C_RESET}"
else
    echo -e "${C_SUCCESS}[✓] Configurações e backups preservados em ~/.config/zenith/.${C_RESET}"
fi

echo -e "${C_SUCCESS}[✓] O ZENITH PANEL foi desinstalado do seu terminal.${C_RESET}"
exit 0
