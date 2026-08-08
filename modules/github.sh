#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Git e GitHub (modules/github.sh)
# ==============================================================================
# Integração completa para controle de versão, clone, commits, pull, push
# e gerenciamento de projetos locais. Tokens nunca são armazenados no código.
# ==============================================================================

# 1. Verificar Git no Sistema
github_check_git() {
    ui_header "VERIFICAÇÃO DO GIT"
    if check_git; then
        local ver
        ver=$(git --version)
        ui_msg_success "Git detectado com sucesso: ${ver}"
        echo -e "Configuração Global Atual:"
        echo -e "  Nome  : $(git config --global user.name 2>/dev/null || echo 'Não configurado')"
        echo -e "  E-mail: $(git config --global user.email 2>/dev/null || echo 'Não configurado')"
    else
        ui_msg_error "O Git não está instalado ou não foi encontrado no PATH."
        echo "Dica: Para instalar use 'pkg install git' ou 'apt install git'."
    fi
}

# 2. Configurar Nome e E-mail Global no Git
github_config_user() {
    ui_header "CONFIGURAÇÃO DE IDENTIDADE GIT"
    if ! check_git; then
        ui_msg_error "Git indisponível."; return
    fi

    echo -e -n "${C_PRIMARY}Digite seu Nome para o Git (ex: Pedro Atila): ${C_RESET}"
    read -r g_name
    echo -e -n "${C_PRIMARY}Digite seu E-mail para o Git (ex: user@example.com): ${C_RESET}"
    read -r g_email

    if [ -n "${g_name}" ]; then
        git config --global user.name "${g_name}"
    fi
    if [ -n "${g_email}" ]; then
        git config --global user.email "${g_email}"
    fi
    ui_msg_success "Identidade global atualizada no Git."
}

# 3. Clone de Repositório
github_clone() {
    ui_header "CLONAR REPOSITÓRIO GIT"
    if ! check_git; then
        ui_msg_error "Git indisponível."; return
    fi

    echo -e -n "${C_PRIMARY}Digite a URL do repositório (HTTPS ou SSH): ${C_RESET}"
    read -r repo_url
    [ -z "${repo_url}" ] && return

    echo -e -n "${C_PRIMARY}Pasta de destino opcional (deixe em branco para padrão): ${C_RESET}"
    read -r dest_dir

    ui_msg_exec "Clonando ${repo_url}..."
    if [ -n "${dest_dir}" ]; then
        git clone "${repo_url}" "${dest_dir}"
    else
        git clone "${repo_url}"
    fi

    if [ $? -eq 0 ]; then
        ui_msg_success "Clone finalizado com sucesso no diretório atual."
    else
        ui_msg_error "Falha ao clonar o repositório."
    fi
}

# 4. Status, Logs e Branches
github_status_logs() {
    ui_header "STATUS DO REPOSITÓRIO ATUAL (${PWD})"
    if ! check_git; then
        ui_msg_error "Git indisponível."; return
    fi

    if [ ! -d ".git" ]; then
        ui_msg_warn "O diretório atual (${PWD}) não parece ser um repositório Git (.git ausente)."
        return
    fi

    echo -e "${C_PRIMARY}${C_BOLD}Git Status:${C_RESET}"
    git status -s 2>/dev/null || git status
    echo ""
    echo -e "${C_PRIMARY}${C_BOLD}Branches Locais/Remotas:${C_RESET}"
    git branch -a 2>/dev/null | head -n 10
    echo ""
    echo -e "${C_PRIMARY}${C_BOLD}Últimos 5 Commits:${C_RESET}"
    git log -n 5 --oneline --graph --decorate 2>/dev/null || echo "Sem histórico de commits."
}

# 5. Git Pull (Atualizar Repositório Atual)
github_pull() {
    ui_header "ATUALIZAR REPOSITÓRIO (GIT PULL)"
    if ! check_git || [ ! -d ".git" ]; then
        ui_msg_error "Não é um repositório Git válido no diretório atual."; return
    fi

    ui_msg_exec "Executando 'git pull'..."
    git pull
    if [ $? -eq 0 ]; then
        ui_msg_success "Repositório atualizado com sucesso."
    else
        ui_msg_error "Falha ao puxar alterações do remoto."
    fi
}

# 6. Commit & Push
github_commit_push() {
    ui_header "GIT COMMIT & PUSH"
    if ! check_git || [ ! -d ".git" ]; then
        ui_msg_error "Não é um repositório Git válido."; return
    fi

    echo -e "${C_PRIMARY}Arquivos com alterações não salvas:${C_RESET}"
    git status -s
    echo ""
    echo -e -n "${C_PRIMARY}Deseja adicionar todas as alterações (git add .)? [S/N]: ${C_RESET}"
    read -r -n 1 do_add
    echo ""
    if [[ "${do_add}" =~ ^[sS]$ ]]; then
        git add .
        ui_msg_success "Arquivos adicionados para commit."
    fi

    echo -e -n "${C_PRIMARY}Digite a mensagem do commit: ${C_RESET}"
    read -r commit_msg
    if [ -n "${commit_msg}" ]; then
        git commit -m "${commit_msg}"
        ui_msg_success "Commit registrado."

        echo -e -n "${C_PRIMARY}Deseja fazer 'git push' agora? [S/N]: ${C_RESET}"
        read -r -n 1 do_push
        echo ""
        if [[ "${do_push}" =~ ^[sS]$ ]]; then
            ui_msg_exec "Enviando alterações..."
            git push
            [ $? -eq 0 ] && ui_msg_success "Push realizado com sucesso!" || ui_msg_error "Falha no git push."
        fi
    else
        ui_msg_warn "Mensagem de commit vazia, commit cancelado."
    fi
}

# 7. Remotes do Projeto
github_remotes() {
    ui_header "GERENCIAR REMOTES GIT"
    if ! check_git || [ ! -d ".git" ]; then
        ui_msg_error "Não é um repositório Git válido."; return
    fi

    echo -e "${C_PRIMARY}Remotes Configurados:${C_RESET}"
    git remote -v
    echo ""
    echo -e "  ${C_BOLD}1${C_RESET} │ Adicionar novo remote"
    echo -e "  ${C_BOLD}0${C_RESET} │ Voltar"
    echo -e -n "${C_PRIMARY}Escolha [0/1]: ${C_RESET}"
    read -r sel
    if [ "${sel}" = "1" ]; then
        echo -e -n "${C_PRIMARY}Nome do remote (ex: origin, upstream): ${C_RESET}"
        read -r rem_name
        echo -e -n "${C_PRIMARY}URL do remote (ex: https://github.com/...): ${C_RESET}"
        read -r rem_url
        if [ -n "${rem_name}" ] && [ -n "${rem_url}" ]; then
            git remote add "${rem_name}" "${rem_url}" && ui_msg_success "Remote ${rem_name} adicionado." || ui_msg_error "Falha ao adicionar remote."
        fi
    fi
}

# 8. Criar Projeto Local (git init)
github_init_project() {
    ui_header "CRIAR PROJETO LOCAL (GIT INIT)"
    echo -e -n "${C_PRIMARY}Digite o nome da nova pasta do projeto (ou '.' para atual): ${C_RESET}"
    read -r p_dir
    p_dir="$(echo "${p_dir}" | xargs)"
    [ -z "${p_dir}" ] && p_dir="novo_projeto"

    mkdir -p "${p_dir}"
    cd "${p_dir}" || return
    git init
    cat << 'EOF' > README.md
# Novo Projeto
Criado via Zenith Panel v1.0.0.
EOF
    echo -e "${C_SUCCESS}Projeto inicializado em: $(pwd)${C_RESET}"
}

# 9. Navegar para Diretório do Projeto
github_change_dir() {
    ui_header "ABRIR DIRETÓRIO DE TRABALHO"
    echo -e "${C_INFO}Diretório de trabalho atual: ${PWD}${C_RESET}"
    echo -e -n "${C_PRIMARY}Digite o caminho para onde deseja mudar: ${C_RESET}"
    read -r target_path
    if [ -d "${target_path}" ]; then
        cd "${target_path}" || return
        ui_msg_success "Novo diretório de trabalho: ${PWD}"
    else
        ui_msg_error "Diretório inexistente."
    fi
}

# Submenu principal do Módulo Git / GitHub
github_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO GIT / GITHUB"
        echo -e "  ${C_BOLD}1${C_RESET} │ 📦 Verificar Git e Identidade Configurada"
        echo -e "  ${C_BOLD}2${C_RESET} │ 👤 Configurar Usuário (Name/Email Global)"
        echo -e "  ${C_BOLD}3${C_RESET} │ 📥 Clonar Repositório (HTTPS/SSH)"
        echo -e "  ${C_BOLD}4${C_RESET} │ 📊 Status, Log e Branches do Repositório Atual"
        echo -e "  ${C_BOLD}5${C_RESET} │ 🔄 Atualizar Repositório Local (Git Pull)"
        echo -e "  ${C_BOLD}6${C_RESET} │ 🚀 Commit & Push de Alterações"
        echo -e "  ${C_BOLD}7${C_RESET} │ 🌐 Visualizar / Adicionar Remotes"
        echo -e "  ${C_BOLD}8${C_RESET} │ 🏗️  Criar Projeto Local (git init)"
        echo -e "  ${C_BOLD}9${C_RESET} │ 📂 Abrir / Navegar para outro Diretório"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-9]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) github_check_git; ui_pause ;;
            2) github_config_user; ui_pause ;;
            3) github_clone; ui_pause ;;
            4) github_status_logs; ui_pause ;;
            5) github_pull; ui_pause ;;
            6) github_commit_push; ui_pause ;;
            7) github_remotes; ui_pause ;;
            8) github_init_project; ui_pause ;;
            9) github_change_dir; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
