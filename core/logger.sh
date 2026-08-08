#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo de Registro de Logs (core/logger.sh)
# ==============================================================================
# Gerencia a escrita e consulta de logs em arquivo persistente.
# ==============================================================================

# Arquivo principal de logs do Zenith Panel
LOG_FILE="${HOME}/.config/zenith/logs/zenith.log"

# Inicializa o diretório e arquivo de log
log_init() {
    local log_dir
    log_dir="$(dirname "${LOG_FILE}")"
    mkdir -p "${log_dir}"
    if [ ! -f "${LOG_FILE}" ]; then
        touch "${LOG_FILE}"
        chmod 644 "${LOG_FILE}" 2>/dev/null || true
    fi
}

# Função genérica de escrita de log com carimbo de tempo
log_write() {
    local level="${1:-INFO}"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

log_info() {
    log_write "INFO" "$1"
}

log_warn() {
    log_write "WARN" "$1"
}

log_error() {
    log_write "ERROR" "$1"
}

log_debug() {
    log_write "DEBUG" "$1"
}

log_exec() {
    log_write "EXEC" "Comando executado: $1"
}

# Visualiza as últimas N linhas de log
log_view() {
    local lines="${1:-20}"
    if [ -f "${LOG_FILE}" ]; then
        tail -n "${lines}" "${LOG_FILE}"
    else
        echo "Arquivo de log não encontrado."
    fi
}

# Limpa o arquivo de logs
log_clear() {
    if [ -f "${LOG_FILE}" ]; then
        : > "${LOG_FILE}"
        log_info "Arquivo de log limpo com sucesso."
    fi
}
