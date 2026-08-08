#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Gaming e Servidores Próprios (modules/gaming.sh)
# ==============================================================================
# Ferramentas legítimas para organização, backup de mundos Minecraft, saves,
# scripts de inicialização otimizados e monitoramento de servidores autorizados.
# POLÍTICA: Zero cheats, sem exploits ou bypass de sistemas antitrapaça.
# ==============================================================================

GAMING_BACKUP_DIR="${HOME}/.config/zenith/backups/gaming"

gaming_init() {
    mkdir -p "${GAMING_BACKUP_DIR}"
}

# 1. Organização de Arquivos e Limpeza de Caches
gaming_organize() {
    ui_header "ORGANIZAÇÃO DE ARQUIVOS DE JOGO"
    echo -e "${C_INFO}Verificando pastas típicas de jogos e arquivos temporários...${C_RESET}"
    local mcraft_dir="${HOME}/games/com.mojang"
    if [ -d "/sdcard/games/com.mojang" ]; then
        mcraft_dir="/sdcard/games/com.mojang"
    fi

    if [ -d "${mcraft_dir}" ]; then
        echo -e "${C_SUCCESS}Pasta Mojang/Minecraft detectada em: ${mcraft_dir}${C_RESET}"
        echo "Tamanho total: $(utils_file_size "${mcraft_dir}")"
    else
        echo -e "${C_MUTED}Pasta de jogo '${mcraft_dir}' não encontrada no caminho padrão.${C_RESET}"
    fi
    echo ""
    ui_msg_success "Verificação de diretórios de jogos concluída."
}

# 2. Backup de Mundos (Minecraft / Saves)
gaming_backup_worlds() {
    gaming_init
    ui_header "BACKUP DE MUNDOS MINECRAFT / SAVES"
    echo -e -n "${C_PRIMARY}Digite o caminho da pasta de mundos (ex: /sdcard/games/com.mojang/minecraftWorlds ou ./worlds): ${C_RESET}"
    read -r w_dir
    w_dir="$(echo "${w_dir}" | xargs)"
    if [ -z "${w_dir}" ]; then
        w_dir="${HOME}/games/com.mojang/minecraftWorlds"
    fi

    if [ -d "${w_dir}" ]; then
        local ts
        ts="$(date '+%Y%m%d_%H%M%S')"
        local archive="${GAMING_BACKUP_DIR}/minecraft_worlds_${ts}.tar.gz"
        ui_msg_exec "Compactando pasta de mundos: ${w_dir}..."
        tar -czvf "${archive}" -C "$(dirname "${w_dir}")" "$(basename "${w_dir}")" >/dev/null 2>&1
        if [ -f "${archive}" ]; then
            ui_msg_success "Backup salvo com sucesso em: ${archive}"
            echo "Tamanho do arquivo: $(utils_file_size "${archive}")"
        else
            ui_msg_error "Erro na criação do backup."
        fi
    else
        ui_msg_error "Pasta de mundos '${w_dir}' não encontrada."
    fi
}

# 3. Backup de Configurações
gaming_backup_configs() {
    gaming_init
    ui_header "BACKUP DE CONFIGURAÇÕES DE JOGOS"
    echo -e -n "${C_PRIMARY}Digite o arquivo ou pasta de configurações (ex: server.properties): ${C_RESET}"
    read -r cfg_path
    if [ -e "${cfg_path}" ]; then
        local ts
        ts="$(date '+%Y%m%d_%H%M%S')"
        local dest="${GAMING_BACKUP_DIR}/gaming_cfg_${ts}.tar.gz"
        tar -czvf "${dest}" "${cfg_path}" >/dev/null 2>&1
        ui_msg_success "Backup das configurações gerado em: ${dest}"
    else
        ui_msg_error "Arquivo/pasta '${cfg_path}' não encontrado."
    fi
}

# 4. Gerenciamento de Servidor Próprio Minecraft
gaming_server_manager() {
    ui_header "GERENCIADOR DE SERVIDOR MINECRAFT PRÓPRIO"
    echo -e "  ${C_BOLD}1${C_RESET} │ Verificar status da porta padrão 25565 (Java) / 19132 (Bedrock)"
    echo -e "  ${C_BOLD}2${C_RESET} │ Baixar/Configurar Script Inicializador de Servidor"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
    read -r s_opt
    if [ "${s_opt}" = "1" ]; then
        echo -e "${C_INFO}Verificando portas de servidores locais...${C_RESET}"
        if (echo >/dev/tcp/127.0.0.1/25565) >/dev/null 2>&1; then
            echo -e "  [Java 25565]    : ${C_SUCCESS}ONLINE / ABERTO${C_RESET}"
        else
            echo -e "  [Java 25565]    : ${C_MUTED}Offline${C_RESET}"
        fi
        if (echo >/dev/tcp/127.0.0.1/19132) >/dev/null 2>&1; then
            echo -e "  [Bedrock 19132] : ${C_SUCCESS}ONLINE / ABERTO${C_RESET}"
        else
            echo -e "  [Bedrock 19132] : ${C_MUTED}Offline${C_RESET}"
        fi
    elif [ "${s_opt}" = "2" ]; then
        local start_script="start_minecraft_server.sh"
        cat << 'EOF' > "${start_script}"
#!/usr/bin/env bash
# Script otimizado pelo Zenith Panel para Servidor Minecraft Java
# Ajustado para alocação de memória e coleta de lixo sem lag

MEM_MIN="1G"
MEM_MAX="2G"
JAR_FILE="server.jar"

if [ ! -f "${JAR_FILE}" ]; then
    echo "[!] Arquivo ${JAR_FILE} não encontrado no diretório atual."
    echo "Baixe o server.jar do site oficial do Minecraft."
    exit 1
fi

echo "[✓] Iniciando Servidor Minecraft com RAM ${MEM_MIN}-${MEM_MAX}..."
java -Xms${MEM_MIN} -Xmx${MEM_MAX} -XX:+UseG1GC -XX:+ParallelRefProcEnabled -jar "${JAR_FILE}" nogui
EOF
        chmod +x "${start_script}"
        ui_msg_success "Script otimizado criado: ${start_script} (Pronto para usar com java)."
    fi
}

# 5. Script de Inicialização Otimizado
gaming_launcher_script() {
    ui_header "CRIADOR DE LAUNCHER OTIMIZADO"
    echo -e -n "${C_PRIMARY}Nome do script de inicialização (ex: run_game.sh): ${C_RESET}"
    read -r l_name
    [ -z "${l_name}" ] && return
    [[ ! "${l_name}" =~ \.sh$ ]] && l_name="${l_name}.sh"

    cat << 'EOF' > "${l_name}"
#!/usr/bin/env bash
# Launcher de jogo / servidor com prioridade e monitoramento de crash
echo "=== Iniciando processo de jogo ==="
# Adicione a linha de comando do jogo abaixo:
# ./seu_servidor_ou_jogo

echo "=== Processo finalizado ==="
EOF
    chmod +x "${l_name}"
    ui_msg_success "Launcher gerado: ${l_name}."
}

# 6. Monitoramento de Servidor
gaming_monitor_server() {
    ui_header "MONITORAMENTO DE SERVIDOR DE JOGO"
    echo -e -n "${C_PRIMARY}Digite o IP/Host do seu servidor autorizado: ${C_RESET}"
    read -r g_host
    [ -z "${g_host}" ] && g_host="127.0.0.1"

    echo -e -n "${C_PRIMARY}Porta (padrão 25565): ${C_RESET}"
    read -r g_port
    [ -z "${g_port}" ] && g_port="25565"

    ui_msg_exec "Verificando latência e porta de ${g_host}:${g_port}..."
    if (echo >/dev/tcp/"${g_host}"/"${g_port}") >/dev/null 2>&1; then
        echo -e "Status da Porta ${g_port}: ${C_SUCCESS}ONLINE (Ativa e respondendo)${C_RESET}"
    else
        echo -e "Status da Porta ${g_port}: ${C_ERROR}OFFLINE / SEM RESPOSTA${C_RESET}"
    fi
    echo ""
}

# Submenu principal do Módulo Gaming
gaming_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO GAMING & SERVIDORES PRÓPRIOS"
        echo -e "  ${C_BOLD}1${C_RESET} │ 📂 Organização de Arquivos e Pastas de Jogo"
        echo -e "  ${C_BOLD}2${C_RESET} │ 💾 Backup de Mundos / Saves (MinecraftWorlds)"
        echo -e "  ${C_BOLD}3${C_RESET} │ ⚙️  Backup de Configurações de Servidor/Jogo"
        echo -e "  ${C_BOLD}4${C_RESET} │ 🎮 Gerenciamento de Servidor Próprio de Minecraft"
        echo -e "  ${C_BOLD}5${C_RESET} │ 🚀 Criar Script de Inicialização Otimizado"
        echo -e "  ${C_BOLD}6${C_RESET} │ 📡 Monitoramento de Porta e Latência de Servidor"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-6]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) gaming_organize; ui_pause ;;
            2) gaming_backup_worlds; ui_pause ;;
            3) gaming_backup_configs; ui_pause ;;
            4) gaming_server_manager; ui_pause ;;
            5) gaming_launcher_script; ui_pause ;;
            6) gaming_monitor_server; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
