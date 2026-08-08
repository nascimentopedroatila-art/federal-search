#!/usr/bin/env bash
# ==============================================================================
# ⚡ ZENITH PANEL - ULTIMATE TERMUX TOOLKIT & MEGA PAINEL MODULAR (zenith.sh)
# ==============================================================================
# Autor   : Desenvolvedor Especialista Zenith Panel
# Versão  : 1.0.0
# Data    : 2026-08-08
# Licença : MIT License
# ==============================================================================
# Mega painel interativo e modular para Termux Android e Linux.
# Reúne ferramentas de sistema, monitoramento, IA, rede, Linux, Git/GitHub,
# automação, servidores, gaming, segurança defensiva, APIs, arquivos,
# personalização, pacotes, backups, plugins e documentação.
# ==============================================================================

# Tratamento de erros e interrupções (CTRL+C / SIGINT)
trap 'echo -e "\n\033[38;5;196m[!] Sinal de interrupção recebido. Retornando ao menu ou encerrando...\033[0m"; sleep 0.5' SIGINT

# 1. Resolve o diretório real de instalação do Zenith Panel com suporte a symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do
    DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "${SOURCE}")"
    [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" >/dev/null 2>&1 && pwd )"
export ZENITH_DIR="${SCRIPT_DIR}"

# 2. Carrega todos os módulos do núcleo (Core)
for core_file in colors checks config logger utils ui; do
    core_path="${ZENITH_DIR}/core/${core_file}.sh"
    if [ -f "${core_path}" ]; then
        source "${core_path}"
    else
        echo -e "\033[38;5;196m[×] Erro crítico: Arquivo essencial não encontrado: ${core_path}\033[0m" >&2
        exit 1
    fi
done

# 3. Carrega todos os módulos funcionais (Modules)
for mod_file in system monitor android network linux ai tools github automation servers gaming security api files customization packages backup docs plugins update diagnostic about; do
    mod_path="${ZENITH_DIR}/modules/${mod_file}.sh"
    if [ -f "${mod_path}" ]; then
        source "${mod_path}"
    else
        log_error "Módulo ausente ou inacessível: ${mod_path}"
        echo -e "${C_WARN}[!] Aviso: Módulo '${mod_file}' não carregado.${C_RESET}"
    fi
done

# 4. Inicialização de configurações, temas e diretórios persistentes
config_init
log_init
log_info "Sessão iniciada - ZENITH PANEL v${ZENITH_VERSION}"

# 5. Modo CLI via argumentos de linha de comando
if [ $# -gt 0 ]; then
    case "$1" in
        --help|-h)
            echo -e "${C_PRIMARY}${C_BOLD}ZENITH PANEL v${ZENITH_VERSION} - Uso de Linha de Comando:${C_RESET}"
            echo -e "  zenith               : Inicia o painel interativo completo"
            echo -e "  zenith --version|-v  : Exibe a versão do Zenith Panel"
            echo -e "  zenith --diagnostic  : Executa o diagnóstico automático (zenith-diagnostic.txt)"
            echo -e "  zenith --backup      : Executa um backup imediato das configurações"
            echo -e "  zenith <01..23>      : Abre direto o módulo correspondente"
            exit 0
            ;;
        --version|-v)
            echo "ZENITH PANEL v${ZENITH_VERSION} (Build 2026-08-08)"
            exit 0
            ;;
        --diagnostic)
            diagnostic_run
            exit 0
            ;;
        --backup)
            backup_create
            exit 0
            ;;
        01|1) system_menu; exit 0 ;;
        02|2) monitor_menu; exit 0 ;;
        03|3) android_menu; exit 0 ;;
        04|4) network_menu; exit 0 ;;
        05|5) linux_menu; exit 0 ;;
        06|6) ai_menu; exit 0 ;;
        07|7) tools_menu; exit 0 ;;
        08|8) github_menu; exit 0 ;;
        09|9) automation_menu; exit 0 ;;
        10) servers_menu; exit 0 ;;
        11) gaming_menu; exit 0 ;;
        12) security_menu; exit 0 ;;
        13) api_menu; exit 0 ;;
        14) files_menu; exit 0 ;;
        15) customization_menu; exit 0 ;;
        16) packages_menu; exit 0 ;;
        17) backup_menu; exit 0 ;;
        18) settings_menu; exit 0 ;;
        19) docs_menu; exit 0 ;;
        20) plugins_menu; exit 0 ;;
        21) update_menu; exit 0 ;;
        22) diagnostic_menu; exit 0 ;;
        23) about_menu; exit 0 ;;
        *)
            echo -e "${C_ERROR}Argumento desconhecido '$1'. Use 'zenith --help' para ver os comandos.${C_RESET}"
            exit 1
            ;;
    esac
fi

# 6. Loop principal interativo do ZENITH PANEL
while true; do
    ui_clear
    ui_banner
    ui_main_menu
    echo ""
    ui_prompt
    read -r option

    # Normaliza a entrada removendo zeros à esquerda se for numérico
    case "${option}" in
        01|1) system_menu ;;
        02|2) monitor_menu ;;
        03|3) android_menu ;;
        04|4) network_menu ;;
        05|5) linux_menu ;;
        06|6) ai_menu ;;
        07|7) tools_menu ;;
        08|8) github_menu ;;
        09|9) automation_menu ;;
        10) servers_menu ;;
        11) gaming_menu ;;
        12) security_menu ;;
        13) api_menu ;;
        14) files_menu ;;
        15) customization_menu ;;
        16) packages_menu ;;
        17) backup_menu ;;
        18) settings_menu ;;
        19) docs_menu ;;
        20) plugins_menu ;;
        21) update_menu ;;
        22) diagnostic_menu ;;
        23) about_menu ;;
        0|q|Q|exit|sair)
            log_info "Sessão encerrada com sucesso pelo usuário."
            echo ""
            echo -e "${C_SUCCESS}╔══════════════════════════════════════════════╗${C_RESET}"
            echo -e "${C_SUCCESS}║       Obrigado por usar o ZENITH PANEL       ║${C_RESET}"
            echo -e "${C_SUCCESS}║          ULTIMATE TERMUX TOOLKIT 🚀          ║${C_RESET}"
            echo -e "${C_SUCCESS}╚══════════════════════════════════════════════╝${C_RESET}"
            echo ""
            exit 0
            ;;
        *)
            ui_msg_error "Opção inválida ('${option}'). Escolha um número entre 0 e 23."
            sleep 1.2
            ;;
    esac
done
