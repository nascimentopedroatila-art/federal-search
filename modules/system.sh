#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Sistema (modules/system.sh)
# ==============================================================================
# Coleta e exibe informações detalhadas do hardware e ambiente do sistema.
# ==============================================================================

# Executa e formata a exibição de informações do sistema
system_info_display() {
    ui_header "INFORMAÇÕES DO SISTEMA"

    # Coleta Informações do Dispositivo
    local model="Desconhecido"
    local manufacturer="Desconhecido"
    local android_ver="N/A"

    if [ "${ZENITH_IS_ANDROID}" = true ]; then
        if check_command getprop; then
            model=$(getprop ro.product.model 2>/dev/null || echo "Desconhecido")
            manufacturer=$(getprop ro.product.manufacturer 2>/dev/null || echo "Desconhecido")
            android_ver=$(getprop ro.build.version.release 2>/dev/null || echo "N/A")
        elif [ -f "/system/build.prop" ]; grep -q "ro.product.model=" "/system/build.prop" 2>/dev/null; then
            model=$(grep "^ro.product.model=" /system/build.prop 2>/dev/null | cut -d'=' -f2)
            manufacturer=$(grep "^ro.product.manufacturer=" /system/build.prop 2>/dev/null | cut -d'=' -f2)
            android_ver=$(grep "^ro.build.version.release=" /system/build.prop 2>/dev/null | cut -d'=' -f2)
        fi
    else
        if [ -f "/sys/devices/virtual/dmi/id/product_name" ]; then
            model=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "PC / Workstation")
            manufacturer=$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null || echo "Genérico")
        else
            model="Host Linux Genérico"
            manufacturer="N/A"
        fi
    fi

    local kernel
    kernel="$(uname -r 2>/dev/null || echo 'N/A')"
    local arch="${ZENITH_ARCH}"

    # Informações de CPU
    local cpu_model="Desconhecido"
    local cpu_cores
    cpu_cores="$(utils_get_cpu_cores)"
    local cpu_freq="Indisponível"

    if [ -f "/proc/cpuinfo" ]; grep -i "model name" "/proc/cpuinfo" >/dev/null 2>&1; then
        cpu_model=$(grep -m 1 -i "model name" /proc/cpuinfo | cut -d':' -f2 | xargs)
    elif [ -f "/proc/cpuinfo" ]; grep -i "Hardware" "/proc/cpuinfo" >/dev/null 2>&1; then
        cpu_model=$(grep -m 1 -i "Hardware" /proc/cpuinfo | cut -d':' -f2 | xargs)
    elif check_command lscpu; then
        cpu_model=$(lscpu | grep "Model name" | head -n 1 | cut -d':' -f2 | xargs)
    fi
    [ -z "${cpu_model}" ] && cpu_model="Processador ${arch}"

    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq" ]; then
        local freq_khz
        freq_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo "0")
        if [ "${freq_khz}" -gt 0 ]; then
            cpu_freq=$(awk -v khz="${freq_khz}" 'BEGIN { printf "%.2f GHz", khz / 1000000 }')
        fi
    fi

    # Informações de Memória RAM e Armazenamento
    local ram_info
    ram_info="$(utils_get_ram_info)"

    local storage_info="Indisponível"
    local disk_free="Indisponível"
    if check_command df; then
        storage_info=$(df -h "${HOME}" 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 " ocupado)"}')
        disk_free=$(df -h "${HOME}" 2>/dev/null | awk 'NR==2 {print $4 " livres"}')
    fi

    # Uptime e Shell
    local uptime_sec=0
    if [ -f "/proc/uptime" ]; then
        uptime_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo "0")
    fi
    local uptime_str
    uptime_str="$(utils_format_uptime "${uptime_sec}")"

    local shell_name="${SHELL}"
    local bash_ver="${BASH_VERSION}"
    local termux_ver="N/A"
    if [ "${ZENITH_IS_TERMUX}" = true ]; then
        termux_ver="${TERMUX_VERSION:-1.0.0}"
    fi

    # Processos ativos no sistema
    local proc_count="0"
    if check_command ps; then
        proc_count=$(ps -e 2>/dev/null | wc -l || ps 2>/dev/null | wc -l)
    fi

    # Exibe informações organizadas em tabela
    echo -e "${C_PRIMARY}${C_BOLD}  HARDWARE & DISPOSITIVO${C_RESET}"
    ui_separator
    printf "  %-22s: %s\n" "Modelo" "${C_TEXT}${model}${C_RESET}"
    printf "  %-22s: %s\n" "Fabricante" "${C_TEXT}${manufacturer}${C_RESET}"
    printf "  %-22s: %s\n" "Versão Android" "${C_TEXT}${android_ver}${C_RESET}"
    printf "  %-22s: %s\n" "Kernel Linux" "${C_TEXT}${kernel}${C_RESET}"
    printf "  %-22s: %s\n" "Arquitetura CPU" "${C_TEXT}${arch}${C_RESET}"
    printf "  %-22s: %s\n" "Modelo CPU" "${C_TEXT}${cpu_model}${C_RESET}"
    printf "  %-22s: %s\n" "Núcleos CPU" "${C_TEXT}${cpu_cores}${C_RESET}"
    printf "  %-22s: %s\n" "Frequência CPU" "${C_TEXT}${cpu_freq}${C_RESET}"
    printf "  %-22s: %s\n" "Uptime" "${C_TEXT}${uptime_str}${C_RESET}"
    echo ""

    echo -e "${C_PRIMARY}${C_BOLD}  MEMÓRIA & ARMAZENAMENTO${C_RESET}"
    ui_separator
    printf "  %-22s: %s\n" "RAM (Uso/Total)" "${C_TEXT}${ram_info}${C_RESET}"
    printf "  %-22s: %s\n" "Armazenamento Home" "${C_TEXT}${storage_info}${C_RESET}"
    printf "  %-22s: %s\n" "Espaço Livre" "${C_TEXT}${disk_free}${C_RESET}"
    echo ""

    echo -e "${C_PRIMARY}${C_BOLD}  AMBIENTE & SHELL${C_RESET}"
    ui_separator
    printf "  %-22s: %s\n" "Termux" "${C_TEXT}${ZENITH_IS_TERMUX} (Versão: ${termux_ver})${C_RESET}"
    printf "  %-22s: %s\n" "Shell Atual" "${C_TEXT}${shell_name}${C_RESET}"
    printf "  %-22s: %s\n" "Versão Bash" "${C_TEXT}${bash_ver}${C_RESET}"
    printf "  %-22s: %s\n" "Processos Rodando" "${C_TEXT}${proc_count}${C_RESET}"
    printf "  %-22s: %s\n" "Diretório Atual" "${C_TEXT}${PWD}${C_RESET}"
    printf "  %-22s: %s\n" "Home Directory" "${C_TEXT}${HOME}${C_RESET}"
    echo ""

    echo -e "${C_PRIMARY}${C_BOLD}  VARIÁVEIS IMPORTANTES${C_RESET}"
    ui_separator
    printf "  %-22s: %s\n" "USER" "${C_TEXT}${USER:-N/A}${C_RESET}"
    printf "  %-22s: %s\n" "PREFIX" "${C_TEXT}${PREFIX:-N/A}${C_RESET}"
    printf "  %-22s: %s\n" "TMPDIR" "${C_TEXT}${TMPDIR:-/tmp}${C_RESET}"
    printf "  %-22s: %s\n" "LANG" "${C_TEXT}${LANG:-N/A}${C_RESET}"
    echo ""

    ui_msg_success "Informações do sistema processadas e exibidas."
}

# Submenu principal da opção 01
system_menu() {
    ui_clear
    system_info_display
    ui_pause
}
