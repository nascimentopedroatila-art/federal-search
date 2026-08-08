#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo de Utilitários e Funções Auxiliares (core/utils.sh)
# ==============================================================================
# Funções reutilizáveis para conversão de bytes, uptime, animações e validações.
# ==============================================================================

# Converte bytes para um formato legível para humanos (KB, MB, GB, TB)
utils_format_bytes() {
    local bytes="${1:-0}"
    if [[ ! "${bytes}" =~ ^[0-9]+$ ]]; then
        echo "N/A"
        return
    fi

    if [ "${bytes}" -lt 1024 ]; then
        echo "${bytes} B"
    elif [ "${bytes}" -lt 1048576 ]; then
        awk -v b="${bytes}" 'BEGIN { printf "%.2f KB", b / 1024 }'
    elif [ "${bytes}" -lt 1073741824 ]; then
        awk -v b="${bytes}" 'BEGIN { printf "%.2f MB", b / 1048576 }'
    elif [ "${bytes}" -lt 1099511627776 ]; then
        awk -v b="${bytes}" 'BEGIN { printf "%.2f GB", b / 1073741824 }'
    else
        awk -v b="${bytes}" 'BEGIN { printf "%.2f TB", b / 1099511627776 }'
    fi
}

# Converte segundos para dias, horas, minutos e segundos
utils_format_uptime() {
    local seconds="${1:-0}"
    if [[ ! "${seconds}" =~ ^[0-9]+$ ]]; then
        echo "0s"
        return
    fi

    local days=$((seconds / 86400))
    local hours=$(( (seconds % 86400) / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$((seconds % 60))

    local result=""
    [ "${days}" -gt 0 ] && result="${days}d "
    [ "${hours}" -gt 0 ] && result="${result}${hours}h "
    [ "${minutes}" -gt 0 ] && result="${result}${minutes}m "
    result="${result}${secs}s"

    echo "${result}"
}

# Sanitiza string removendo caracteres potencialmente perigosos para comandos
utils_sanitize_string() {
    echo "$1" | tr -d ';&|`$<>\\"' | xargs
}

# Retorna o tamanho de um arquivo em formato legível
utils_file_size() {
    local filepath="$1"
    if [ -f "${filepath}" ]; then
        if check_command du; then
            du -h "${filepath}" 2>/dev/null | cut -f1 | xargs
        else
            echo "N/A"
        fi
    else
        echo "0 B"
    fi
}

# Solicita confirmação [S/N] do usuário
utils_confirm() {
    local message="$1"
    local response
    echo -e -n "${C_WARN}? ${message} [S/N]: ${C_RESET}"
    read -r -n 1 response
    echo ""
    if [[ "${response}" =~ ^[sS]$ ]]; then
        return 0
    fi
    return 1
}

# Solicita confirmação explícita digitando uma palavra-chave (ex: CONFIRMAR)
utils_confirm_explicit() {
    local message="$1"
    local expected="${2:-CONFIRMAR}"
    local response
    echo -e "${C_WARN}${message}${C_RESET}"
    echo -e -n "${C_BOLD}Digite ${C_ACCENT}${expected}${C_BOLD} para continuar: ${C_RESET}"
    read -r response
    if [ "${response}" = "${expected}" ]; then
        return 0
    fi
    return 1
}

# Animação de spinner durante execução em segundo plano
utils_spinner() {
    local pid="$1"
    local message="${2:-Executando...}"
    local spin_chars="/ - \\ |"

    if [ "${ZENITH_ANIMATIONS}" != "true" ]; then
        echo -e "${C_INFO}[>] ${message}${C_RESET}"
        while kill -0 "${pid}" 2>/dev/null; do
            sleep 0.5
        done
        return
    fi

    echo -e -n "${C_INFO}[>] ${message} ${C_RESET}"
    while kill -0 "${pid}" 2>/dev/null; do
        for char in ${spin_chars}; do
            echo -e -n "\b${C_PRIMARY}${char}${C_RESET}"
            sleep "${ZENITH_ANIMATION_SPEED:-0.08}"
        done
    done
    echo -e "\b${C_SUCCESS}✓${C_RESET}"
}

# Obtém IP local da máquina
utils_get_ip_local() {
    if check_command hostname && hostname -I >/dev/null 2>&1; then
        hostname -I | awk '{print $1}'
    elif check_command ip; then
        ip route get 1.1.1.1 2>/dev/null | awk '{print $7}'
    elif check_command ifconfig; then
        ifconfig 2>/dev/null | awk '/inet / && !/127.0.0.1/ {print $2; exit}'
    else
        echo "127.0.0.1"
    fi
}

# Obtém número de núcleos de CPU
utils_get_cpu_cores() {
    if check_command nproc; then
        nproc
    elif [ -f "/proc/cpuinfo" ]; then
        grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1"
    else
        echo "1"
    fi
}

# Retorna uso de RAM formatado
utils_get_ram_info() {
    if check_command free; then
        free -m | awk '/^Mem:/ {printf "%s MB / %s MB (%.0f%%)", $3, $2, ($3/$2)*100}'
    elif [ -f "/proc/meminfo" ]; then
        local mem_total
        local mem_free
        local mem_avail
        mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
        mem_free=$(awk '/^MemFree:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
        mem_avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo "${mem_free}")

        if [ "${mem_total}" -gt 0 ]; then
            local used=$(( (mem_total - mem_avail) / 1024 ))
            local total=$(( mem_total / 1024 ))
            local pct=$(( (used * 100) / total ))
            echo "${used} MB / ${total} MB (${pct}%)"
        else
            echo "Indisponível"
        fi
    else
        echo "Indisponível"
    fi
}
