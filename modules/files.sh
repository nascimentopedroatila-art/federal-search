#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Gerenciador de Arquivos (modules/files.sh)
# ==============================================================================
# Gerenciamento de arquivos e diretórios no terminal (listar, buscar, copiar,
# mover, excluir, compactar, permissões). Confirmação explícita em exclusões.
# ==============================================================================

# Exibe aviso legal e de segurança para exclusão
files_warn_delete() {
    local f_path="$1"
    echo -e "${C_WARN}⚠️ ATENÇÃO${C_RESET}"
    echo -e "${C_WARN}Você está prestes a excluir:${C_RESET}"
    echo -e "  ${C_BOLD}${f_path}${C_RESET}"
    echo ""
}

# 1. Listar Arquivos e Permissões
files_list() {
    ui_header "LISTAR ARQUIVOS EM: ${PWD}"
    ls -lA --color=auto 2>/dev/null || ls -lA
    echo ""
}

# 2. Procurar Arquivos
files_search() {
    ui_header "PROCURAR ARQUIVO POR NOME"
    echo -e -n "${C_PRIMARY}Digite o nome ou padrão a procurar (ex: *.sh ou config): ${C_RESET}"
    read -r term
    [ -z "${term}" ] && return
    ui_msg_exec "Procurando por '${term}' no diretório atual..."
    find . -iname "*${term}*" 2>/dev/null | head -n 25
    echo ""
}

# 3. Copiar Arquivo ou Pasta
files_copy() {
    ui_header "COPIAR ARQUIVO OU DIRETÓRIO"
    echo -e -n "${C_PRIMARY}Caminho de origem: ${C_RESET}"
    read -r src
    [ -z "${src}" ] && return
    echo -e -n "${C_PRIMARY}Caminho de destino: ${C_RESET}"
    read -r dest
    [ -z "${dest}" ] && return

    if [ -e "${src}" ]; then
        cp -r "${src}" "${dest}" && ui_msg_success "Copiado ${src} para ${dest}" || ui_msg_error "Falha na cópia."
    else
        ui_msg_error "Arquivo de origem não existe."
    fi
}

# 4. Mover ou Renomear
files_move() {
    ui_header "MOVER / RENOMEAR ARQUIVO"
    echo -e -n "${C_PRIMARY}Caminho atual do arquivo: ${C_RESET}"
    read -r src
    [ -z "${src}" ] && return
    echo -e -n "${C_PRIMARY}Novo caminho / novo nome: ${C_RESET}"
    read -r dest
    [ -z "${dest}" ] && return

    if [ -e "${src}" ]; then
        mv "${src}" "${dest}" && ui_msg_success "Movido de ${src} para ${dest}" || ui_msg_error "Falha ao mover."
    else
        ui_msg_error "Origem não encontrada."
    fi
}

# 5. Criar Nova Pasta
files_mkdir() {
    ui_header "CRIAR NOVA PASTA"
    echo -e -n "${C_PRIMARY}Nome ou caminho da nova pasta: ${C_RESET}"
    read -r d_path
    [ -z "${d_path}" ] && return
    mkdir -p "${d_path}" && ui_msg_success "Pasta ${d_path} criada." || ui_msg_error "Falha ao criar pasta."
}

# 6. Excluir Arquivo/Pasta de Forma Segura
files_delete() {
    ui_header "EXCLUIR ARQUIVO OU DIRETÓRIO (SEGURO)"
    echo -e -n "${C_PRIMARY}Digite o caminho do arquivo/pasta a ser EXCLUÍDO: ${C_RESET}"
    read -r del_path
    [ -z "${del_path}" ] && return

    if [ ! -e "${del_path}" ]; then
        ui_msg_error "Arquivo ou diretório '${del_path}' não existe."
        return
    fi

    files_warn_delete "${del_path}"
    echo -e -n "${C_BOLD}Digite: ${C_ACCENT}CONFIRMAR${C_BOLD} para continuar: ${C_RESET}"
    read -r confirmation
    if [ "${confirmation}" = "CONFIRMAR" ]; then
        rm -rf "${del_path}" && ui_msg_success "O item foi excluído do sistema." || ui_msg_error "Erro ao excluir."
    else
        ui_msg_warn "Exclusão cancelada. Nenhum arquivo foi modificado."
    fi
}

# 7. Compactar Pasta em .tar.gz
files_compress() {
    ui_header "COMPACTAR ARQUIVO / DIRETÓRIO"
    echo -e -n "${C_PRIMARY}Item para compactar: ${C_RESET}"
    read -r target
    [ -z "${target}" ] && return
    echo -e -n "${C_PRIMARY}Nome do arquivo .tar.gz de saída: ${C_RESET}"
    read -r out_file
    [ -z "${out_file}" ] && out_file="compactado.tar.gz"

    if [ -e "${target}" ]; then
        tar -czvf "${out_file}" "${target}" >/dev/null 2>&1 && ui_msg_success "Arquivo compactado salvo: ${out_file}" || ui_msg_error "Falha na compactação."
    else
        ui_msg_error "Item de origem não encontrado."
    fi
}

# 8. Descompactar Arquivo
files_decompress() {
    ui_header "DESCOMPACTAR ARQUIVO"
    echo -e -n "${C_PRIMARY}Caminho do arquivo (.tar.gz, .zip, .tar): ${C_RESET}"
    read -r arc_path
    if [ -f "${arc_path}" ]; then
        case "${arc_path}" in
            *.tar.gz|*.tgz) tar -xzvf "${arc_path}" >/dev/null 2>&1 ;;
            *.tar) tar -xvf "${arc_path}" >/dev/null 2>&1 ;;
            *.zip) unzip "${arc_path}" >/dev/null 2>&1 ;;
            *) ui_msg_error "Formato de arquivo não suportado."; return ;;
        esac
        ui_msg_success "Arquivo descompactado na pasta atual."
    else
        ui_msg_error "Arquivo compactado não encontrado."
    fi
}

# 9. Mostrar Tamanho, Permissões e Proprietário
files_inspect() {
    ui_header "DETALHES DO ARQUIVO OU DIRETÓRIO"
    echo -e -n "${C_PRIMARY}Caminho para inspecionar: ${C_RESET}"
    read -r item
    if [ -e "${item}" ]; then
        printf "  %-20s : %s\n" "Tamanho no Disco" "$(utils_file_size "${item}")"
        if check_command stat; then
            printf "  %-20s : %s\n" "Permissões Octais" "$(stat -c "%a (%A)" "${item}" 2>/dev/null || stat -f "%Lp" "${item}" 2>/dev/null)"
            printf "  %-20s : %s\n" "Proprietário:Grupo" "$(stat -c "%U:%G" "${item}" 2>/dev/null || echo 'N/A')"
        fi
    else
        ui_msg_error "Item não existe."
    fi
}

# 10. Espaço Disponível no Sistema
files_disk_space() {
    ui_header "ESPAÇO EM DISCO DISPONÍVEL"
    if check_command df; then
        df -h "${HOME}" 2>/dev/null | awk 'NR==1 || NR==2'
    fi
    echo ""
}

# Submenu principal do Módulo Arquivos
files_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO ARQUIVOS (GERENCIADOR DE TERMINAL)"
        echo -e "  ${C_BOLD}1${C_RESET} │ 📋 Listar Arquivos no Diretório Atual (${PWD})"
        echo -e "  ${C_BOLD}2${C_RESET} │ 🔍 Procurar Arquivos por Nome"
        echo -e "  ${C_BOLD}3${C_RESET} │ 📥 Copiar Arquivo ou Pasta"
        echo -e "  ${C_BOLD}4${C_RESET} │ 🔄 Mover / Renomear"
        echo -e "  ${C_BOLD}5${C_RESET} │ 📁 Criar Nova Pasta (mkdir -p)"
        echo -e "  ${C_BOLD}6${C_RESET} │ 🗑️  Excluir Arquivo ou Pasta (Com Confirmação Explícita)"
        echo -e "  ${C_BOLD}7${C_RESET} │ 📦 Compactar Pasta (.tar.gz)"
        echo -e "  ${C_BOLD}8${C_RESET} │ 📂 Descompactar Arquivo (.tar.gz / .zip)"
        echo -e "  ${C_BOLD}9${C_RESET} │ ℹ️  Ver Tamanho, Permissões e Proprietário de Item"
        echo -e "  ${C_BOLD}10${C_RESET}│ 💾 Exibir Espaço em Disco Disponível"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-10]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) files_list; ui_pause ;;
            2) files_search; ui_pause ;;
            3) files_copy; ui_pause ;;
            4) files_move; ui_pause ;;
            5) files_mkdir; ui_pause ;;
            6) files_delete; ui_pause ;;
            7) files_compress; ui_pause ;;
            8) files_decompress; ui_pause ;;
            9) files_inspect; ui_pause ;;
            10) files_disk_space; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
