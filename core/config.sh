#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo de Configuração Persistente (core/config.sh)
# ==============================================================================
# Gerencia a persistência de configurações do usuário em ~/.config/zenith/.
# ==============================================================================

# Diretórios padrão do Zenith Panel
export ZENITH_CONFIG_DIR="${HOME}/.config/zenith"
export ZENITH_CONFIG_FILE="${ZENITH_CONFIG_DIR}/zenith.conf"
export ZENITH_AI_FILE="${ZENITH_CONFIG_DIR}/ai.conf"
export ZENITH_SERVERS_FILE="${ZENITH_CONFIG_DIR}/servers.json"
export ZENITH_BACKUP_DIR="${ZENITH_CONFIG_DIR}/backups"
export ZENITH_LOG_DIR="${ZENITH_CONFIG_DIR}/logs"

# Variáveis globais de configuração do Zenith Panel
export ZENITH_USER_NAME="${USER:-TermuxUser}"
export ZENITH_THEME="ZENITH"
export ZENITH_ANIMATIONS="true"
export ZENITH_ANIMATION_SPEED="0.02"
export ZENITH_COMPACT_MODE="false"
export ZENITH_LANGUAGE="pt-BR"
export ZENITH_VERSION="1.0.0"

# Inicializa a estrutura de diretórios e arquivos de configuração
config_init() {
    mkdir -p "${ZENITH_CONFIG_DIR}"
    mkdir -p "${ZENITH_BACKUP_DIR}"
    mkdir -p "${ZENITH_LOG_DIR}"

    if [ ! -f "${ZENITH_CONFIG_FILE}" ]; then
        config_create_default
    fi

    if [ ! -f "${ZENITH_AI_FILE}" ]; then
        cat << 'EOF' > "${ZENITH_AI_FILE}"
# ZENITH AI - Arquivo de Configuração de Chaves de API
# AVISO: Mantenha este arquivo seguro e protegido (chmod 600)
AI_PROVIDER="openai"
AI_MODEL="gpt-4o-mini"
OPENAI_API_KEY=""
ANTHROPIC_API_KEY=""
GEMINI_API_KEY=""
GROQ_API_KEY=""
OLLAMA_HOST="http://127.0.0.1:11434"
EOF
        chmod 600 "${ZENITH_AI_FILE}" 2>/dev/null || true
    fi

    if [ ! -f "${ZENITH_SERVERS_FILE}" ]; then
        cat << 'EOF' > "${ZENITH_SERVERS_FILE}"
[
  {
    "name": "Servidor Web Teste",
    "command": "python3 -m http.server 8080",
    "directory": ".",
    "port": "8080",
    "description": "Servidor estático Python"
  }
]
EOF
    fi

    config_load
}

# Cria arquivo de configuração padrão se não existir
config_create_default() {
    cat << EOF > "${ZENITH_CONFIG_FILE}"
# ==============================================================================
# ZENITH PANEL - Arquivo de Configuração
# ==============================================================================

USER_NAME="${ZENITH_USER_NAME}"
THEME="${ZENITH_THEME}"
ANIMATIONS="${ZENITH_ANIMATIONS}"
ANIMATION_SPEED="${ZENITH_ANIMATION_SPEED}"
BACKUP_DIR="${ZENITH_BACKUP_DIR}"
LOG_DIR="${ZENITH_LOG_DIR}"
COMPACT_MODE="${ZENITH_COMPACT_MODE}"
LANGUAGE="${ZENITH_LANGUAGE}"
EOF
}

# Carrega as configurações do arquivo zenith.conf
config_load() {
    if [ -f "${ZENITH_CONFIG_FILE}" ]; then
        # Lê apenas chaves autorizadas em formato KEY=VALUE sem executar código arbitrário
        while IFS='=' read -r key val; do
            # Ignora comentários e linhas em branco
            [[ "${key}" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${key}" ]] && continue

            # Remove aspas do valor
            val=$(echo "${val}" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")

            case "${key}" in
                USER_NAME)       ZENITH_USER_NAME="${val}" ;;
                THEME)           ZENITH_THEME="${val}" ;;
                ANIMATIONS)      ZENITH_ANIMATIONS="${val}" ;;
                ANIMATION_SPEED) ZENITH_ANIMATION_SPEED="${val}" ;;
                BACKUP_DIR)      ZENITH_BACKUP_DIR="${val}" ;;
                LOG_DIR)         ZENITH_LOG_DIR="${val}" ;;
                COMPACT_MODE)    ZENITH_COMPACT_MODE="${val}" ;;
                LANGUAGE)        ZENITH_LANGUAGE="${val}" ;;
            esac
        done < "${ZENITH_CONFIG_FILE}"
    fi

    # Aplica o tema de cores carregado
    if command -v colors_set_theme >/dev/null 2>&1; then
        colors_set_theme "${ZENITH_THEME}"
    fi
}

# Salva as configurações atuais de volta ao zenith.conf
config_save() {
    cat << EOF > "${ZENITH_CONFIG_FILE}"
# ==============================================================================
# ZENITH PANEL - Arquivo de Configuração
# ==============================================================================

USER_NAME="${ZENITH_USER_NAME}"
THEME="${ZENITH_THEME}"
ANIMATIONS="${ZENITH_ANIMATIONS}"
ANIMATION_SPEED="${ZENITH_ANIMATION_SPEED}"
BACKUP_DIR="${ZENITH_BACKUP_DIR}"
LOG_DIR="${ZENITH_LOG_DIR}"
COMPACT_MODE="${ZENITH_COMPACT_MODE}"
LANGUAGE="${ZENITH_LANGUAGE}"
EOF
}

# Define uma variável de configuração e salva
config_set() {
    local key="$1"
    local val="$2"

    case "${key}" in
        USER_NAME)       ZENITH_USER_NAME="${val}" ;;
        THEME)           ZENITH_THEME="${val}" ;;
        ANIMATIONS)      ZENITH_ANIMATIONS="${val}" ;;
        ANIMATION_SPEED) ZENITH_ANIMATION_SPEED="${val}" ;;
        BACKUP_DIR)      ZENITH_BACKUP_DIR="${val}" ;;
        LOG_DIR)         ZENITH_LOG_DIR="${val}" ;;
        COMPACT_MODE)    ZENITH_COMPACT_MODE="${val}" ;;
        LANGUAGE)        ZENITH_LANGUAGE="${val}" ;;
        *)               return 1 ;;
    esac

    config_save
    if [ "${key}" = "THEME" ] && command -v colors_set_theme >/dev/null 2>&1; then
        colors_set_theme "${ZENITH_THEME}"
    fi
}

# Retorna uma chave de configuração
config_get() {
    local key="$1"
    local default_val="$2"

    case "${key}" in
        USER_NAME)       echo "${ZENITH_USER_NAME:-$default_val}" ;;
        THEME)           echo "${ZENITH_THEME:-$default_val}" ;;
        ANIMATIONS)      echo "${ZENITH_ANIMATIONS:-$default_val}" ;;
        ANIMATION_SPEED) echo "${ZENITH_ANIMATION_SPEED:-$default_val}" ;;
        BACKUP_DIR)      echo "${ZENITH_BACKUP_DIR:-$default_val}" ;;
        LOG_DIR)         echo "${ZENITH_LOG_DIR:-$default_val}" ;;
        COMPACT_MODE)    echo "${ZENITH_COMPACT_MODE:-$default_val}" ;;
        LANGUAGE)        echo "${ZENITH_LANGUAGE:-$default_val}" ;;
        *)               echo "${default_val}" ;;
    esac
}
