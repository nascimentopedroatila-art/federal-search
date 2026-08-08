#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Linux (modules/linux.sh)
# ==============================================================================
# Gerencia ambientes Linux no Termux (proot-distro) e hosts Linux nativos.
# Permite listar, entrar, monitorar processos, serviços e interface gráfica.
# POLÍTICA DE SEGURANÇA: Nunca exclui ambientes de forma automática.
# ==============================================================================

# 1. Listar Ambientes Linux Detectados
linux_list_envs() {
    ui_header "AMBIENTES LINUX DETECTADOS"
    echo -e "${C_PRIMARY}${C_BOLD}Ambiente Host Atual:${C_RESET}"
    if [ -f "/etc/os-release" ]; then
        grep -E '^(NAME|VERSION)=' /etc/os-release | sed 's/=/ : /g' | tr -d '"'
    else
        echo "Host: ${ZENITH_OS} (${ZENITH_ARCH})"
    fi
    echo ""

    if check_command proot-distro; then
        echo -e "${C_PRIMARY}${C_BOLD}Distribuições proot-distro (Termux):${C_RESET}"
        proot-distro list 2>/dev/null
    else
        echo -e "${C_MUTED}[•] 'proot-distro' não instalado (recurso exclusivo do Termux para gerenciar distros).${C_RESET}"
    fi
    echo ""
    ui_msg_success "Consulta de ambientes finalizada."
}

# 2. Entrar no Ambiente Linux
linux_enter_env() {
    ui_header "ENTRAR EM AMBIENTE LINUX"
    if check_command proot-distro; then
        local distros
        distros=$(proot-distro list 2>/dev/null | grep -E "installed.*yes" | awk '{print $1}')
        if [ -z "${distros}" ]; then
            ui_msg_warn "Nenhum ambiente proot-distro foi instalado ainda."
            echo "Para instalar no Termux, use: proot-distro install ubuntu (ou debian/alpine/archlinux)."
            return
        fi

        echo -e "${C_PRIMARY}Distribuições instaladas disponíveis:${C_RESET}"
        echo "${distros}" | nl
        echo ""
        echo -e -n "${C_PRIMARY}Digite o nome da distribuição (ex: ubuntu, debian, alpine): ${C_RESET}"
        read -r choice_distro
        choice_distro=$(echo "${choice_distro}" | xargs)
        if [ -n "${choice_distro}" ]; then
            ui_msg_exec "Iniciando sessão em '${choice_distro}'... Digite 'exit' para retornar."
            proot-distro login "${choice_distro}"
        fi
    else
        ui_msg_info "Você já está rodando em um ambiente Linux nativo (${ZENITH_OS})."
        echo -e "Deseja abrir um sub-shell interativo limpo? [S/N]"
        read -r -n 1 resp
        echo ""
        if [[ "${resp}" =~ ^[sS]$ ]]; then
            "${SHELL:-/bin/bash}"
        fi
    fi
}

# 3. Ver Status de Ambientes e Serviços
linux_status() {
    ui_header "STATUS DO SISTEMA LINUX"
    echo -e "${C_PRIMARY}Uptime e Carga de CPU:${C_RESET}"
    uptime 2>/dev/null || echo "N/A"
    echo ""
    echo -e "${C_PRIMARY}Uso de Disco nas Raízes de Ambientes:${C_RESET}"
    if [ -d "/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs" ]; then
        du -sh /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/* 2>/dev/null || echo "Sem distros instaladas."
    else
        df -h / 2>/dev/null | awk 'NR==1 || NR==2'
    fi
    echo ""
    ui_msg_success "Status consultado com sucesso."
}

# 4. Gerenciar Processos Linux
linux_manage_processes() {
    ui_header "GERENCIAMENTO DE PROCESSOS"
    echo -e "  ${C_BOLD}1${C_RESET} │ Listar os 10 processos com maior consumo de CPU/MEM"
    echo -e "  ${C_BOLD}2${C_RESET} │ Encerrar processo por PID (kill)"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
    read -r op
    if [ "${op}" = "1" ]; then
        if check_command ps; then
            ps aux --sort=-%cpu 2>/dev/null | head -n 11 || ps -ef 2>/dev/null | head -n 11
        fi
    elif [ "${op}" = "2" ]; then
        local target_pid
        echo -e -n "${C_PRIMARY}Digite o número do PID para encerrar: ${C_RESET}"
        read -r target_pid
        if [[ "${target_pid}" =~ ^[0-9]+$ ]]; then
            if utils_confirm "Tem certeza que deseja encerrar o PID ${target_pid}?"; then
                kill "${target_pid}" 2>/dev/null && ui_msg_success "PID ${target_pid} encerrado." || ui_msg_error "Falha ao encerrar PID ${target_pid}."
            fi
        else
            ui_msg_error "PID inválido."
        fi
    fi
}

# 5. Gerenciar Serviços Linux
linux_manage_services() {
    ui_header "GERENCIAMENTO DE SERVIÇOS"
    if check_command systemctl && [ -d "/run/systemd/system" ]; then
        echo -e "${C_PRIMARY}Serviços ativos no systemd (Top 10):${C_RESET}"
        systemctl list-units --type=service --state=running 2>/dev/null | head -n 15
    elif check_command service; then
        echo -e "${C_PRIMARY}Status de serviços conhecidos:${C_RESET}"
        service --status-all 2>/dev/null | head -n 15 || echo "Sem serviço 'service' disponível."
    else
        echo -e "${C_INFO}Neste ambiente (${ZENITH_OS}), os serviços são gerenciados via processos manuais ou runit.${C_RESET}"
        if [ -d "${PREFIX}/var/service" ]; then
            echo -e "${C_PRIMARY}Serviços Termux-services:${C_RESET}"
            ls -1 "${PREFIX}/var/service" 2>/dev/null
        fi
    fi
    echo ""
    ui_msg_success "Verificação de serviços concluída."
}

# 6. Ambiente Gráfico (VNC / X11)
linux_gui_env() {
    ui_header "AMBIENTE GRÁFICO (VNC / X11)"
    echo -e "  ${C_BOLD}1${C_RESET} │ Verificar e Iniciar VNC Server (vncserver)"
    echo -e "  ${C_BOLD}2${C_RESET} │ Verificar suporte Termux-X11"
    echo ""
    echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
    read -r op
    if [ "${op}" = "1" ]; then
        if check_command vncserver; then
            echo -e "${C_INFO}Verificando sessões VNC ativas...${C_RESET}"
            vncserver -list 2>/dev/null || echo "Nenhuma sessão ativa detectada."
            if utils_confirm "Deseja iniciar uma nova sessão VNC (display :1)?"; then
                vncserver :1 -geometry 1280x720 -depth 24 && ui_msg_success "VNC Server iniciado na porta 5901." || ui_msg_error "Falha ao iniciar VNC."
            fi
        else
            ui_msg_warn "'vncserver' (tigervnc) não está instalado."
            echo "Dica: Você pode instalar usando pkg install tigervnc."
        fi
    elif [ "${op}" = "2" ]; then
        if check_command termux-x11; then
            ui_msg_success "Suporte a Termux-X11 instalado no sistema."
        else
            ui_msg_warn "'termux-x11' não detectado no PATH atual."
        fi
    fi
}

# Submenu principal do Módulo Linux
linux_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO LINUX & AMBIENTES"
        echo -e "  ${C_BOLD}1${C_RESET} │ 🐧 Listar Ambientes Linux (Host / proot-distro)"
        echo -e "  ${C_BOLD}2${C_RESET} │ 🚀 Entrar em um Ambiente Linux"
        echo -e "  ${C_BOLD}3${C_RESET} │ 📊 Ver Status de Carga e Uso de Disco"
        echo -e "  ${C_BOLD}4${C_RESET} │ ⚙️  Gerenciar Processos Linux"
        echo -e "  ${C_BOLD}5${C_RESET} │ 🛠️  Gerenciar Serviços"
        echo -e "  ${C_BOLD}6${C_RESET} │ 🖥️  Ambiente Gráfico (VNC / X11)"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-6]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) linux_list_envs; ui_pause ;;
            2) linux_enter_env; ui_pause ;;
            3) linux_status; ui_pause ;;
            4) linux_manage_processes; ui_pause ;;
            5) linux_manage_services; ui_pause ;;
            6) linux_gui_env; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
