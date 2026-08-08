#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo de Monitoramento (modules/monitor.sh)
# ==============================================================================
# Monitora CPU, RAM, Armazenamento, Bateria, Temperatura, Processos e Rede.
# Suporta modo de verificação única e modo de Monitor em Tempo Real.
# ==============================================================================

# Coleta os dados de monitoramento do sistema
monitor_get_data() {
    # CPU Usage (%) - Cálculo de média aproximado
    local cpu_usage="[!] Informação indisponível neste dispositivo"
    if check_command top; then
        local top_out
        top_out=$(top -bn1 2>/dev/null | grep -i -E "Cpu|CPU" | head -n 1)
        if [ -n "${top_out}" ]; then
            cpu_usage="${top_out}"
        else
            cpu_usage="Uso de CPU Ativo (núcleos: $(utils_get_cpu_cores))"
        fi
    fi

    # RAM Usage
    local ram_usage
    ram_usage="$(utils_get_ram_info)"

    # Armazenamento
    local disk_usage="[!] Informação indisponível neste dispositivo"
    if check_command df; then
        disk_usage=$(df -h "${HOME}" 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
    fi

    # Bateria
    local battery_info="[!] Informação indisponível neste dispositivo"
    if check_termux_api; then
        local bat_json
        bat_json=$(termux-battery-status 2>/dev/null || echo "")
        if [ -n "${bat_json}" ]; then
            local bat_pct
            local bat_stat
            bat_pct=$(echo "${bat_json}" | grep -o -E '"percentage":[[:space:]]*[0-9]+' | grep -o '[0-9]+')
            bat_stat=$(echo "${bat_json}" | grep -o -E '"status":[[:space:]]*"[^"]+"' | cut -d'"' -f4)
            if [ -n "${bat_pct}" ]; then
                battery_info="${bat_pct}% (${bat_stat:-Status desconhecido})"
            fi
        fi
    elif [ -f "/sys/class/power_supply/battery/capacity" ]; then
        local cap
        cap=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
        battery_info="${cap}% (Bateria do Sistema)"
    fi

    # Temperatura
    local temp_info="[!] Informação indisponível neste dispositivo"
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        local raw_temp
        raw_temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0")
        if [ "${raw_temp}" -gt 0 ] 2>/dev/null; then
            local temp_c
            temp_c=$(awk -v t="${raw_temp}" 'BEGIN { if (t > 1000) print t/1000; else print t }')
            temp_info="${temp_c} °C"
        fi
    elif check_command sensors; then
        local sens
        sens=$(sensors 2>/dev/null | grep -E "temp1:|Core 0:" | head -n 1 | awk '{print $2}')
        [ -n "${sens}" ] && temp_info="${sens}"
    fi

    # Processos
    local proc_count="0"
    if check_command ps; then
        proc_count=$(ps -e 2>/dev/null | wc -l || ps 2>/dev/null | wc -l)
    fi

    # Rede
    local net_info="[!] Informação indisponível neste dispositivo"
    if check_command ip; then
        local ip_addr
        ip_addr="$(utils_get_ip_local)"
        net_info="IP: ${ip_addr} (Online: $(check_internet && echo 'SIM' || echo 'NÃO'))"
    elif check_command ifconfig; then
        local ip_addr
        ip_addr="$(utils_get_ip_local)"
        net_info="IP: ${ip_addr}"
    fi

    # Uptime
    local uptime_sec=0
    if [ -f "/proc/uptime" ]; then
        uptime_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo "0")
    fi
    local uptime_str
    uptime_str="$(utils_format_uptime "${uptime_sec}")"

    # Exibição
    echo -e "${C_PRIMARY}${C_BOLD}  DIAGNÓSTICO DE RECURSOS${C_RESET}"
    ui_separator
    printf "  %-22s: %s\n" "Uso de CPU" "${C_TEXT}${cpu_usage}${C_RESET}"
    printf "  %-22s: %s\n" "Memória RAM" "${C_TEXT}${ram_usage}${C_RESET}"
    printf "  %-22s: %s\n" "Armazenamento Home" "${C_TEXT}${disk_usage}${C_RESET}"
    printf "  %-22s: %s\n" "Bateria" "${C_TEXT}${battery_info}${C_RESET}"
    printf "  %-22s: %s\n" "Temperatura" "${C_TEXT}${temp_info}${C_RESET}"
    printf "  %-22s: %s\n" "Processos Rodando" "${C_TEXT}${proc_count}${C_RESET}"
    printf "  %-22s: %s\n" "Status de Rede" "${C_TEXT}${net_info}${C_RESET}"
    printf "  %-22s: %s\n" "Uptime" "${C_TEXT}${uptime_str}${C_RESET}"
    echo ""
}

# Exibe instantâneo único do monitor
monitor_snapshot() {
    ui_clear
    ui_header "MONITOR DE SISTEMA - INSTANTÂNEO"
    monitor_get_data
    ui_msg_success "Leitura de sensores e recursos concluída."
}

# Monitor em tempo real (atualização automática a cada 2 segundos)
monitor_realtime() {
    ui_clear
    local count=0
    while true; do
        ui_clear
        ui_header "MONITOR EM TEMPO REAL (Atualização automática)"
        echo -e "${C_MUTED}Pressione [q] ou [CTRL+C] para sair do modo tempo real.${C_RESET}"
        echo ""
        monitor_get_data
        echo -e "${C_SECONDARY}Última atualização: $(date '+%H:%M:%S') | Iteração #${count}${C_RESET}"

        count=$((count + 1))
        # Aguarda input ou tempo de atualização (2 segundos)
        read -t 2 -n 1 key 2>/dev/null
        if [[ "${key}" == "q" || "${key}" == "Q" ]]; then
            break
        fi
    done
}

# Submenu do Módulo 02
monitor_menu() {
    while true; do
        ui_clear
        ui_header "MONITORAMENTO DO DISPOSITIVO"
        echo -e "  ${C_BOLD}1${C_RESET} │ Exibir Instantâneo do Sistema"
        echo -e "  ${C_BOLD}2${C_RESET} │ Monitor em Tempo Real (Auto-Refresh)"
        echo -e "  ${C_BOLD}0${C_RESET} │ Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-2]: ${C_RESET}"
        read -r op
        case "${op}" in
            1)
                monitor_snapshot
                ui_pause
                ;;
            2)
                monitor_realtime
                ;;
            0)
                break
                ;;
            *)
                ui_msg_error "Opção inválida. Tente novamente."
                sleep 1
                ;;
        esac
    done
}
