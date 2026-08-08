#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Rede e Diagnóstico (modules/network.sh)
# ==============================================================================
# Ferramentas legítimas de diagnóstico e administração para redes autorizadas.
# CONFORMIDADE ÉTICA: Exclusivamente para inspeção e auditoria defensiva.
# ==============================================================================

# Exibe aviso legal e ético
network_ethical_banner() {
    echo -e "${C_INFO}╔══════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_INFO}║ MÓDULO DE REDE - AVISO DE CONFORMIDADE ÉTICA ║${C_RESET}"
    echo -e "${C_INFO}╠══════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_INFO}║ Ferramentas destinadas a redes próprias e    ║${C_RESET}"
    echo -e "${C_INFO}║ sistemas com autorização explícita de teste. ║${C_RESET}"
    echo -e "${C_INFO}╚══════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

# 1. Status Geral da Conexão
network_status() {
    ui_header "STATUS GERAL DA CONEXÃO"
    local ip_local
    ip_local="$(utils_get_ip_local)"

    local gateway="Desconhecido"
    if check_command ip; then
        gateway=$(ip route 2>/dev/null | grep default | awk '{print $3}' | head -n 1)
    elif check_command netstat; then
        gateway=$(netstat -rn 2>/dev/null | grep "^0.0.0.0" | awk '{print $2}' | head -n 1)
    fi
    [ -z "${gateway}" ] && gateway="Indisponível"

    local dns_servers=""
    if [ -f "/etc/resolv.conf" ]; then
        dns_servers=$(grep "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ' | xargs)
    fi
    [ -z "${dns_servers}" ] && dns_servers="Sistema / DHCP"

    local internet_status
    if check_internet; then
        internet_status="${C_SUCCESS}ONLINE (Conectado)${C_RESET}"
    else
        internet_status="${C_ERROR}OFFLINE (Sem acesso ao exterior)${C_RESET}"
    fi

    printf "  %-22s: %s\n" "IP Local" "${C_TEXT}${ip_local}${C_RESET}"
    printf "  %-22s: %s\n" "Gateway Padrão" "${C_TEXT}${gateway}${C_RESET}"
    printf "  %-22s: %s\n" "Servidores DNS" "${C_TEXT}${dns_servers}${C_RESET}"
    printf "  %-22s: %s\n" "Status da Internet" "${internet_status}"
    echo ""
    ui_msg_success "Verificação de conectividade concluída."
}

# 2. Listar Interfaces de Rede
network_interfaces() {
    ui_header "INTERFACES DE REDE"
    if check_command ip; then
        ip -br a 2>/dev/null || ip a 2>/dev/null
    elif check_command ifconfig; then
        ifconfig -a 2>/dev/null
    else
        echo "Nenhuma ferramenta de interface encontrada (ip/ifconfig)."
    fi
    echo ""
    ui_msg_success "Interfaces listadas."
}

# 3. Ping Diagnóstico
network_ping() {
    ui_header "PING DIAGNÓSTICO EM HOST"
    local host
    echo -e -n "${C_PRIMARY}Digite o host ou IP autorizado (ex: 8.8.8.8): ${C_RESET}"
    read -r host
    host="$(utils_sanitize_string "${host}")"
    if [ -z "${host}" ]; then
        host="8.8.8.8"
    fi

    ui_msg_exec "Executando ping para ${host} (4 pacotes)..."
    ping -c 4 -W 2 "${host}" 2>&1
    echo ""
}

# 4. Traceroute
network_traceroute() {
    ui_header "TRACEROUTE (ROTA ATÉ O HOST)"
    local host
    echo -e -n "${C_PRIMARY}Digite o host ou IP (ex: 1.1.1.1): ${C_RESET}"
    read -r host
    host="$(utils_sanitize_string "${host}")"
    [ -z "${host}" ] && host="1.1.1.1"

    if check_command traceroute; then
        traceroute -m 15 "${host}"
    elif check_command tracepath; then
        tracepath -m 15 "${host}"
    else
        ui_msg_warn "Ferramenta traceroute/tracepath não instalada no sistema."
        echo "Dica: Você pode instalar com o gerenciador de pacotes (pkg install traceroute)."
    fi
    echo ""
}

# 5. Informações de Wi-Fi
network_wifi() {
    ui_header "INFORMAÇÕES DE WI-FI"
    if check_command termux-wifi-connectioninfo; then
        termux-wifi-connectioninfo 2>/dev/null || echo "Desconectado ou permissão pendente."
    elif check_command iwconfig; then
        iwconfig 2>/dev/null
    elif check_command nmcli; then
        nmcli dev wifi 2>/dev/null | head -n 10
    else
        echo -e "${C_MUTED}[!] Informação indisponível neste dispositivo.${C_RESET}"
    fi
    echo ""
}

# 6. Teste Rápido de Conectividade
network_conn_test() {
    ui_header "TESTE RÁPIDO DE CONECTIVIDADE"
    local hosts=("1.1.1.1" "8.8.8.8" "google.com" "github.com")

    for h in "${hosts[@]}"; do
        if check_command ping; then
            if ping -c 1 -W 2 "${h}" >/dev/null 2>&1; then
                printf "  %-18s : %s\n" "${h}" "${C_SUCCESS}✓ Online${C_RESET}"
            else
                printf "  %-18s : %s\n" "${h}" "${C_ERROR}× Falha${C_RESET}"
            fi
        elif check_command curl; then
            if curl -s --connect-timeout 2 "https://${h}" >/dev/null 2>&1; then
                printf "  %-18s : %s\n" "${h}" "${C_SUCCESS}✓ Online (HTTP)${C_RESET}"
            else
                printf "  %-18s : %s\n" "${h}" "${C_ERROR}× Falha (HTTP)${C_RESET}"
            fi
        fi
    done
    echo ""
    ui_msg_success "Teste de conectividade por amostra finalizado."
}

# 7. Consulta DNS
network_dns_lookup() {
    ui_header "CONSULTA DNS / RESOLUÇÃO DE DOMÍNIO"
    local domain
    echo -e -n "${C_PRIMARY}Digite o domínio para consulta (ex: github.com): ${C_RESET}"
    read -r domain
    domain="$(utils_sanitize_string "${domain}")"
    [ -z "${domain}" ] && domain="github.com"

    if check_command dig; then
        dig +short "${domain}"
    elif check_command nslookup; then
        nslookup "${domain}" 2>/dev/null | grep -E "Address:|Name:" | tail -n +2
    elif check_command host; then
        host "${domain}"
    elif check_command python3; then
        python3 -c "import socket; print(f'${domain} => ' + socket.gethostbyname('${domain}'))" 2>/dev/null || echo "Falha de resolução DNS via Python."
    else
        ui_msg_warn "Nenhuma ferramenta DNS instalada (dig/nslookup/host/python3)."
    fi
    echo ""
}

# 8. Verificação de Portas em Host Autorizado
network_port_check() {
    ui_header "VERIFICAÇÃO DE PORTAS (HOST AUTORIZADO)"
    local target
    echo -e -n "${C_PRIMARY}Digite o host local ou autorizado (ex: 127.0.0.1): ${C_RESET}"
    read -r target
    target="$(utils_sanitize_string "${target}")"
    [ -z "${target}" ] && target="127.0.0.1"

    local ports=(21 22 80 443 3306 8080 8443)
    echo -e "${C_INFO}Verificando portas padrão em ${target}...${C_RESET}"
    echo ""

    for port in "${ports[@]}"; do
        if check_command nc; then
            if nc -z -w 1 "${target}" "${port}" 2>/dev/null; then
                printf "  Porta %-5s: %s\n" "${port}" "${C_SUCCESS}ABERTA${C_RESET}"
            else
                printf "  Porta %-5s: %s\n" "${port}" "${C_MUTED}Fechada / Sem resposta${C_RESET}"
            fi
        else
            # Fallback usando /dev/tcp nativo do Bash
            if (echo >/dev/tcp/"${target}"/"${port}") >/dev/null 2>&1; then
                printf "  Porta %-5s: %s\n" "${port}" "${C_SUCCESS}ABERTA${C_RESET}"
            else
                printf "  Porta %-5s: %s\n" "${port}" "${C_MUTED}Fechada / Sem resposta${C_RESET}"
            fi
        fi
    done
    echo ""
    ui_msg_success "Verificação de portas concluída."
}

# Submenu principal de Rede
network_menu() {
    while true; do
        ui_clear
        network_ethical_banner
        echo -e "  ${C_BOLD}1${C_RESET} │ 🌐 Status Geral da Conexão"
        echo -e "  ${C_BOLD}2${C_RESET} │ 🔌 Listar Interfaces de Rede"
        echo -e "  ${C_BOLD}3${C_RESET} │ 📡 Ping Diagnóstico em Host"
        echo -e "  ${C_BOLD}4${C_RESET} │ 🗺️  Traceroute (Rota até o Host)"
        echo -e "  ${C_BOLD}5${C_RESET} │ 📶 Informações de Wi-Fi"
        echo -e "  ${C_BOLD}6${C_RESET} │ ⚡ Teste Rápido de Conectividade"
        echo -e "  ${C_BOLD}7${C_RESET} │ 🔍 Consulta DNS / Resolução"
        echo -e "  ${C_BOLD}8${C_RESET} │ 🛡️  Verificação de Portas (Host Autorizado)"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-8]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) network_status; ui_pause ;;
            2) network_interfaces; ui_pause ;;
            3) network_ping; ui_pause ;;
            4) network_traceroute; ui_pause ;;
            5) network_wifi; ui_pause ;;
            6) network_conn_test; ui_pause ;;
            7) network_dns_lookup; ui_pause ;;
            8) network_port_check; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
