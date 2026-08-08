#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Completo de Backups (modules/backup.sh)
# ==============================================================================
# Criação, inspeção, restauração e exclusão de backups com proteção de dados.
# REGRAS: Nunca excluir backups de forma automática; antes de restaurar,
# exibir exatamente quais arquivos serão substituídos e pedir confirmação.
# ==============================================================================

backup_init() {
    mkdir -p "${ZENITH_BACKUP_DIR}"
}

# Exibe a caixa de menu exigida
backup_menu_box() {
    echo -e "${C_BORDER}╔══════════════════════════════╗${C_RESET}"
    echo -e "${C_BORDER}║       ZENITH BACKUP          ║${C_RESET}"
    echo -e "${C_BORDER}╠══════════════════════════════╣${C_RESET}"
    echo -e "${C_BORDER}║ 1 │ Criar backup             ║${C_RESET}"
    echo -e "${C_BORDER}║ 2 │ Restaurar                ║${C_RESET}"
    echo -e "${C_BORDER}║ 3 │ Listar backups           ║${C_RESET}"
    echo -e "${C_BORDER}║ 4 │ Ver tamanho              ║${C_RESET}"
    echo -e "${C_BORDER}║ 5 │ Excluir backup           ║${C_RESET}"
    echo -e "${C_BORDER}║ 6 │ Configurar diretório     ║${C_RESET}"
    echo -e "${C_BORDER}║ 0 │ Voltar                   ║${C_RESET}"
    echo -e "${C_BORDER}╚══════════════════════════════╝${C_RESET}"
    echo ""
}

# 1. Criar backup
backup_create() {
    backup_init
    ui_header "CRIAR NOVO BACKUP DO ZENITH"
    local timestamp
    timestamp="$(date '+%Y%m%d_%H%M%S')"
    local b_name="zenith_backup_${timestamp}.tar.gz"
    local full_path="${ZENITH_BACKUP_DIR}/${b_name}"

    ui_msg_exec "Compactando ~/.config/zenith para ${full_path}..."
    # Cria archive ignorando a própria pasta de backups para não gerar recursão infinita
    tar --exclude="${ZENITH_BACKUP_DIR}" -czvf "${full_path}" -C "${HOME}" ".config/zenith" >/dev/null 2>&1
    if [ -f "${full_path}" ]; then
        ui_msg_success "Backup gerado com sucesso: ${b_name}"
        echo "Tamanho do arquivo: $(utils_file_size "${full_path}")"
        log_info "Backup criado: ${full_path}"
    else
        ui_msg_error "Falha ao gerar o arquivo de backup."
    fi
}

# 2. Restaurar backup
backup_restore() {
    backup_init
    ui_header "RESTAURAR BACKUP"
    local b_files=()
    local idx=1
    while IFS= read -r -d '' file; do
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ $(basename "${file}") ($(utils_file_size "${file}"))"
        b_files+=("${file}")
        idx=$((idx + 1))
    done < <(find "${ZENITH_BACKUP_DIR}" -maxdepth 1 -name "*.tar*" -print0 2>/dev/null)

    if [ ${#b_files[@]} -eq 0 ]; then
        ui_msg_warn "Nenhum arquivo de backup encontrado em ${ZENITH_BACKUP_DIR}."
        return
    fi
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o backup que deseja restaurar [1-$((idx - 1))]: ${C_RESET}"
    read -r b_sel
    if [[ "${b_sel}" =~ ^[0-9]+$ ]] && [ "${b_sel}" -gt 0 ] && [ "${b_sel}" -le "${#b_files[@]}" ]; then
        ui_separator
        tar -tf "${archive}" 2>/dev/null | head -n 30
        echo ""
        echo -e "${C_MUTED}(Exibindo até os 30 primeiros arquivos listados no archive)${C_RESET}"
        echo ""
        if utils_confirm "Confirma a restauração e sobrescrita dos arquivos acima?"; then
            ui_msg_exec "Restaurando de $(basename "${archive}")..."
            tar -xzvf "${archive}" -C "${HOME}" >/dev/null 2>&1 && {
                ui_msg_success "Restauração concluída. Configurações recarregadas."
                config_load
            } || ui_msg_error "Erro ao restaurar arquivo de backup."
        else
            ui_msg_warn "Restauração cancelada. Nenhuma alteração foi efetuada."
        fi
    fi
}

# 3. Listar backups
backup_list() {
    backup_init
    ui_header "BACKUPS CADASTRADOS EM ${ZENITH_BACKUP_DIR}"
    local count=0
    while IFS= read -r -d '' file; do
        printf "  %-35s : %s\n" "$(basename "${file}")" "$(utils_file_size "${file}") - Modificado: $(stat -c "%y" "${file}" 2>/dev/null | cut -d'.' -f1 || echo 'N/A')"
        count=$((count + 1))
    done < <(find "${ZENITH_BACKUP_DIR}" -maxdepth 1 -name "*.tar*" -print0 2>/dev/null)

    if [ "${count}" -eq 0 ]; then
        echo -e "${C_MUTED}Nenhum backup disponível.${C_RESET}"
    else
        echo ""
        echo "Total de backups armazenados: ${count}"
    fi
}

# 4. Ver tamanho
backup_view_size() {
    backup_init
    ui_header "TAMANHO DO DIRETÓRIO DE BACKUPS"
    if [ -d "${ZENITH_BACKUP_DIR}" ]; then
        echo -e "Diretório Atual : ${C_TEXT}${ZENITH_BACKUP_DIR}${C_RESET}"
        echo -e "Tamanho Total   : ${C_SUCCESS}$(du -sh "${ZENITH_BACKUP_DIR}" 2>/dev/null | awk '{print $1}')${C_RESET}"
        echo ""
        echo "Detalhamento por arquivo:"
        ls -lh "${ZENITH_BACKUP_DIR}" 2>/dev/null | awk 'NR>1 {print "  - " $9 " : " $5}'
    else
        echo "Diretório não encontrado."
    fi
}

# 5. Excluir backup
backup_delete() {
    backup_init
    ui_header "EXCLUIR ARQUIVO DE BACKUP"
    local b_files=()
    local idx=1
    while IFS= read -r -d '' file; do
        echo -e "  ${C_BOLD}${idx}${C_RESET} │ $(basename "${file}") ($(utils_file_size "${file}"))"
        b_files+=("${file}")
        idx=$((idx + 1))
    done < <(find "${ZENITH_BACKUP_DIR}" -maxdepth 1 -name "*.tar*" -print0 2>/dev/null)

    if [ ${#b_files[@]} -eq 0 ]; then
        ui_msg_warn "Sem backups para excluir."
        return
    fi
    echo ""
    echo -e -n "${C_PRIMARY}Escolha o número do backup para EXCLUIR [1-$((idx - 1))]: ${C_RESET}"
    read -r b_sel
    if [[ "${b_sel}" =~ ^[0-9]+$ ]] && [ "${b_sel}" -gt 0 ] && [ "${b_sel}" -le "${#b_files[@]}" ]; then
        echo -e "${C_WARN}Você está prestes a excluir o backup:${C_RESET}"
        echo -e "  ${C_BOLD}${archive}${C_RESET}"
        echo ""
        echo -e -n "${C_BOLD}Digite ${C_ACCENT}CONFIRMAR${C_BOLD} para continuar: ${C_RESET}"
        read -r conf
        if [ "${conf}" = "CONFIRMAR" ]; then
            rm -f "${archive}" && ui_msg_success "Backup removido permanentemente." || ui_msg_error "Erro ao excluir."
        else
            ui_msg_warn "Exclusão cancelada."
        fi
    fi
}

# 6. Configurar diretório
backup_set_directory() {
    ui_header "CONFIGURAR DIRETÓRIO DE BACKUP"
    echo -e "Diretório Atual: ${C_INFO}${ZENITH_BACKUP_DIR}${C_RESET}"
    echo -e -n "${C_PRIMARY}Digite o novo caminho de armazenamento de backups: ${C_RESET}"
    read -r new_dir
    if [ -n "${new_dir}" ]; then
        mkdir -p "${new_dir}" 2>/dev/null || { ui_msg_error "Não foi possível criar ${new_dir}."; return; }
        config_set "BACKUP_DIR" "${new_dir}"
        export ZENITH_BACKUP_DIR="${new_dir}"
        ui_msg_success "Diretório de backups alterado para ${new_dir}."
    fi
}

# Submenu principal do Módulo Backup
backup_menu() {
    while true; do
        ui_clear
        backup_menu_box
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-6]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) backup_create; ui_pause ;;
            2) backup_restore; ui_pause ;;
            3) backup_list; ui_pause ;;
            4) backup_view_size; ui_pause ;;
            5) backup_delete; ui_pause ;;
            6) backup_set_directory; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
