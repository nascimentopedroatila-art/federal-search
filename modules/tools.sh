#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Ferramentas e Utilitários (modules/tools.sh)
# ==============================================================================
# Calculadora, relógio, cronômetro, UUID, hash, compressão e pesquisa.
# ==============================================================================

# 1. Calculadora simples
tools_calc() {
    ui_header "CALCULADORA DE TERMINAL"
    echo -e -n "${C_PRIMARY}Digite a expressão matemática (ex: 1024 * 768 / 12): ${C_RESET}"
    read -r expr
    [ -z "${expr}" ] && return
    if check_command bc; then
        local res
        res=$(echo "scale=4; ${expr}" | bc 2>/dev/null)
        echo -e "${C_SUCCESS}Resultado:${C_RESET} ${C_BOLD}${res}${C_RESET}"
    elif check_command python3; then
        local res
        res=$(python3 -c "print(${expr})" 2>/dev/null)
        echo -e "${C_SUCCESS}Resultado:${C_RESET} ${C_BOLD}${res}${C_RESET}"
    else
        echo $(( expr )) 2>/dev/null || ui_msg_error "Expressão inválida ou sem ferramenta bc/python."
    fi
}

# 2. Relógio / Cronômetro
tools_clock() {
    ui_header "RELÓGIO & CRONÔMETRO"
    echo -e "  ${C_BOLD}1${C_RESET} │ Ver Relógio e Data Mundial"
    echo -e "  ${C_BOLD}2${C_RESET} │ Iniciar Cronômetro Digital"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
    read -r opt
    if [ "${opt}" = "1" ]; then
        echo -e "${C_INFO}Hora Local (UTC/Sistema):${C_RESET} $(date '+%d/%m/%Y - %H:%M:%S %Z')"
        echo -e "${C_INFO}Timestamp UNIX          :${C_RESET} $(date '+%s')"
    elif [ "${opt}" = "2" ]; then
        echo -e "${C_INFO}Cronômetro em andamento. Pressione [q] ou [CTRL+C] para parar.${C_RESET}"
        local start_ts
        start_ts=$(date '+%s')
        while true; do
            local now_ts
            now_ts=$(date '+%s')
            local diff=$((now_ts - start_ts))
            local form
            form="$(utils_format_uptime "${diff}")"
            echo -e -n "\r\033[K${C_ACCENT}Tempo decorrido:${C_RESET} ${C_BOLD}${form}${C_RESET}"
            read -t 1 -n 1 key 2>/dev/null
            [[ "${key}" == "q" || "${key}" == "Q" ]] && break
        done
        echo ""
        ui_msg_success "Cronômetro parado."
    fi
}

# 3. Gerador de UUID v4
tools_uuid() {
    ui_header "GERADOR DE UUID (v4)"
    local uuid=""
    if check_command uuidgen; then
        uuid=$(uuidgen)
    elif [ -f "/proc/sys/kernel/random/uuid" ]; then
        uuid=$(cat /proc/sys/kernel/random/uuid)
    elif check_command python3; then
        uuid=$(python3 -c "import uuid; print(uuid.uuid4())")
    else
        uuid="00000000-0000-4000-8000-000000000000"
    fi
    echo -e "${C_BOLD}UUID Gerado:${C_RESET} ${C_SUCCESS}${uuid}${C_RESET}"
    if check_command termux-clipboard-set; then
        echo -n "${uuid}" | termux-clipboard-set 2>/dev/null && echo " (Copiado para o Clipboard)"
    fi
}

# 4. Hash de Arquivos e SHA-256 de texto
tools_hashes() {
    ui_header "GERADOR DE HASHES & SHA-256"
    echo -e "  ${C_BOLD}1${C_RESET} │ Hash SHA-256 de Texto / String"
    echo -e "  ${C_BOLD}2${C_RESET} │ Hashes (MD5 / SHA1 / SHA256) de um Arquivo"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
    read -r choice
    if [ "${choice}" = "1" ]; then
        echo -e -n "${C_PRIMARY}Digite o texto para gerar o SHA-256: ${C_RESET}"
        read -r text
        if check_command sha256sum; then
            echo -n "${text}" | sha256sum | awk '{print $1}'
        elif check_command shasum; then
            echo -n "${text}" | shasum -a 256 | awk '{print $1}'
        fi
    elif [ "${choice}" = "2" ]; then
        echo -e -n "${C_PRIMARY}Digite o caminho completo ou relativo do arquivo: ${C_RESET}"
        read -r filepath
        filepath="$(echo "${filepath}" | xargs)"
        if [ -f "${filepath}" ]; then
            echo -e "${C_INFO}MD5    :${C_RESET} $(md5sum "${filepath}" 2>/dev/null | awk '{print $1}' || echo 'N/A')"
            echo -e "${C_INFO}SHA1   :${C_RESET} $(sha1sum "${filepath}" 2>/dev/null | awk '{print $1}' || echo 'N/A')"
            echo -e "${C_INFO}SHA256 :${C_RESET} $(sha256sum "${filepath}" 2>/dev/null | awk '{print $1}' || shasum -a 256 "${filepath}" 2>/dev/null | awk '{print $1}' || echo 'N/A')"
        else
            ui_msg_error "Arquivo '${filepath}' não encontrado."
        fi
    fi
}

# 5. Informações e Metadados de Arquivo
tools_file_info() {
    ui_header "INFORMAÇÕES DE ARQUIVO"
    echo -e -n "${C_PRIMARY}Digite o caminho do arquivo: ${C_RESET}"
    read -r fpath
    fpath="$(echo "${fpath}" | xargs)"
    if [ -e "${fpath}" ]; then
        printf "  %-20s : %s\n" "Nome" "${fpath}"
        printf "  %-20s : %s\n" "Tipo MIME / Formato" "$(file -b "${fpath}" 2>/dev/null || echo 'N/A')"
        printf "  %-20s : %s\n" "Tamanho" "$(utils_file_size "${fpath}")"
        if check_command stat; then
            printf "  %-20s : %s\n" "Permissões Octais" "$(stat -c "%a (%A)" "${fpath}" 2>/dev/null || stat -f "%Lp" "${fpath}" 2>/dev/null)"
            printf "  %-20s : %s\n" "Proprietário/Grupo" "$(stat -c "%U:%G" "${fpath}" 2>/dev/null || echo 'N/A')"
            printf "  %-20s : %s\n" "Última Modificação" "$(stat -c "%y" "${fpath}" 2>/dev/null || echo 'N/A')"
        fi
    else
        ui_msg_error "Caminho não encontrado no sistema."
    fi
}

# 6. Compactação / Descompactação
tools_archive() {
    ui_header "COMPACTADOR & DESCOMPACTADOR"
    echo -e "  ${C_BOLD}1${C_RESET} │ Compactar arquivo/pasta (.tar.gz)"
    echo -e "  ${C_BOLD}2${C_RESET} │ Descompactar (.tar.gz, .zip)"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
    read -r choice
    if [ "${choice}" = "1" ]; then
        echo -e -n "${C_PRIMARY}Pasta ou arquivo de origem: ${C_RESET}"
        read -r src
        echo -e -n "${C_PRIMARY}Nome do arquivo de saída (ex: backup.tar.gz): ${C_RESET}"
        read -r out
        [ -z "${out}" ] && out="arquivo_compactado.tar.gz"
        if [ -e "${src}" ]; then
            tar -czvf "${out}" "${src}" >/dev/null 2>&1 && ui_msg_success "Criado arquivo ${out}" || ui_msg_error "Falha na compactação."
        else
            ui_msg_error "Origem não encontrada."
        fi
    elif [ "${choice}" = "2" ]; then
        echo -e -n "${C_PRIMARY}Arquivo compactado para extrair: ${C_RESET}"
        read -r arc
        if [ -f "${arc}" ]; then
            case "${arc}" in
                *.tar.gz|*.tgz) tar -xzvf "${arc}" >/dev/null 2>&1 ;;
                *.tar) tar -xvf "${arc}" >/dev/null 2>&1 ;;
                *.zip) unzip "${arc}" >/dev/null 2>&1 ;;
                *) ui_msg_error "Formato não suportado (.tar.gz, .tgz, .tar, .zip)."; return ;;
            esac
            ui_msg_success "Extração concluída no diretório atual."
        else
            ui_msg_error "Arquivo não encontrado."
        fi
    fi
}

# 7. Pesquisa de Arquivos
tools_search() {
    ui_header "PESQUISAR ARQUIVOS & PASTAS"
    echo -e -n "${C_PRIMARY}Digite o padrão de nome para buscar (ex: *.sh ou zenith): ${C_RESET}"
    read -r pattern
    [ -z "${pattern}" ] && return
    ui_msg_exec "Buscando por '${pattern}' a partir do diretório atual (${PWD})..."
    find . -maxdepth 4 -iname "*${pattern}*" 2>/dev/null | head -n 25
    echo ""
    ui_msg_success "Busca finalizada (limite de 25 resultados)."
}

# 8. Visualizador de Logs
tools_logs_viewer() {
    ui_header "VISUALIZADOR DE LOGS DO ZENITH"
    log_view 25
    echo ""
}

# Submenu principal do Módulo Ferramentas
tools_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO FERRAMENTAS & UTILITÁRIOS"
        echo -e "  ${C_BOLD}1${C_RESET} │ 🧮 Calculadora de Terminal"
        echo -e "  ${C_BOLD}2${C_RESET} │ ⏰ Relógio, UTC & Cronômetro Digital"
        echo -e "  ${C_BOLD}3${C_RESET} │ 🔑 Gerador de UUID (v4)"
        echo -e "  ${C_BOLD}4${C_RESET} │ 🔒 Hashes (MD5, SHA1, SHA-256)"
        echo -e "  ${C_BOLD}5${C_RESET} │ 📄 Informações e Metadados de Arquivo"
        echo -e "  ${C_BOLD}6${C_RESET} │ 📦 Compactador / Descompactador (.tar.gz / .zip)"
        echo -e "  ${C_BOLD}7${C_RESET} │ 🔍 Pesquisa Rápida de Arquivos (find)"
        echo -e "  ${C_BOLD}8${C_RESET} │ 📜 Visualizador de Logs e Registros"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-8]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) tools_calc; ui_pause ;;
            2) tools_clock; ui_pause ;;
            3) tools_uuid; ui_pause ;;
            4) tools_hashes; ui_pause ;;
            5) tools_file_info; ui_pause ;;
            6) tools_archive; ui_pause ;;
            7) tools_search; ui_pause ;;
            8) tools_logs_viewer; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
