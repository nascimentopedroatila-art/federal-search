#!/usr/bin/env bash
# ==============================================================================
# ZENITH PANEL - Módulo Android / Termux:API (modules/android.sh)
# ==============================================================================
# Integração com os recursos de hardware do Android utilizando Termux:API.
# Detecta ausência da API sem gerar falhas no fluxo principal.
# ==============================================================================

# Exibe a caixa de aviso caso a Termux:API não esteja disponível
android_warn_no_api() {
    echo -e "${C_WARN}╔══════════════════════════════╗${C_RESET}"
    echo -e "${C_WARN}║ TERMUX:API NÃO ENCONTRADA    ║${C_RESET}"
    echo -e "${C_WARN}╠══════════════════════════════╣${C_RESET}"
    echo -e "${C_WARN}║ Algumas funções ficarão      ║${C_RESET}"
    echo -e "${C_WARN}║ indisponíveis.               ║${C_RESET}"
    echo -e "${C_WARN}╚══════════════════════════════╝${C_RESET}"
    echo ""
}

# 1. Informações e Status da Bateria
android_battery() {
    ui_header "STATUS DA BATERIA ANDROID"
    if check_command termux-battery-status; then
        local bat_json
        bat_json=$(termux-battery-status 2>/dev/null)
        if [ -n "${bat_json}" ]; then
            echo -e "${C_TEXT}${bat_json}${C_RESET}"
            ui_msg_success "Dados de bateria recuperados via Termux:API."
        else
            ui_msg_error "Não foi possível obter resposta do serviço de bateria."
        fi
    else
        android_warn_no_api
        ui_msg_info "Verifique se os pacotes 'termux-api' e o aplicativo Termux:API estão instalados."
    fi
}

# 2. Enviar Notificação
android_notification() {
    ui_header "ENVIAR NOTIFICAÇÃO ANDROID"
    if check_command termux-notification; then
        local title
        local content
        echo -e -n "${C_PRIMARY}Digite o título da notificação: ${C_RESET}"
        read -r title
        echo -e -n "${C_PRIMARY}Digite o conteúdo da notificação: ${C_RESET}"
        read -r content
        termux-notification -t "${title:-Zenith Panel}" -c "${content:-Notificação de teste}"
        ui_msg_success "Notificação enviada com sucesso para a bandeja do Android."
    else
        android_warn_no_api
    fi
}

# 3. Enviar Toast
android_toast() {
    ui_header "ENVIAR TOAST ANDROID"
    if check_command termux-toast; then
        local msg
        echo -e -n "${C_PRIMARY}Digite a mensagem do Toast: ${C_RESET}"
        read -r msg
        termux-toast "${msg:-Olá do Zenith Panel!}"
        ui_msg_success "Toast exibido no dispositivo."
    else
        android_warn_no_api
    fi
}

# 4. Vibrar Dispositivo
android_vibrate() {
    ui_header "VIBRAR DISPOSITIVO"
    if check_command termux-vibrate; then
        local duration
        echo -e -n "${C_PRIMARY}Duração da vibração em ms (padrão 500): ${C_RESET}"
        read -r duration
        termux-vibrate -d "${duration:-500}"
        ui_msg_success "Comando de vibração enviado."
    else
        android_warn_no_api
    fi
}

# 5. Gerenciar Área de Transferência (Clipboard)
android_clipboard() {
    ui_header "ÁREA DE TRANSFERÊNCIA (CLIPBOARD)"
    if check_command termux-clipboard-get; then
        echo -e "  ${C_BOLD}1${C_RESET} │ Ler conteúdo do Clipboard"
        echo -e "  ${C_BOLD}2${C_RESET} │ Enviar texto para o Clipboard"
        echo ""
        echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
        read -r opc
        if [ "${opc}" = "1" ]; then
            local clip_text
            clip_text=$(termux-clipboard-get 2>/dev/null)
            echo -e "${C_BOLD}Conteúdo Atual:${C_RESET} ${C_TEXT}${clip_text:-[Vazio]}${C_RESET}"
            ui_msg_success "Leitura do Clipboard finalizada."
        elif [ "${opc}" = "2" ]; then
            echo -e -n "${C_PRIMARY}Digite o texto para copiar: ${C_RESET}"
            read -r new_text
            echo -n "${new_text}" | termux-clipboard-set
            ui_msg_success "Texto salvo no Clipboard do Android."
        else
            ui_msg_error "Opção inválida."
        fi
    else
        android_warn_no_api
    fi
}

# 6. Informações de Dispositivo (Telefonia / Rede)
android_device_info() {
    ui_header "INFORMAÇÕES TELEFONIA & REDE"
    if check_command termux-telephony-deviceinfo; then
        echo -e "${C_PRIMARY}Dados de Telefonia:${C_RESET}"
        termux-telephony-deviceinfo 2>/dev/null || echo "Não autorizado ou indisponível."
        echo ""
        if check_command termux-wifi-connectioninfo; then
            echo -e "${C_PRIMARY}Dados de Conexão Wi-Fi:${C_RESET}"
            termux-wifi-connectioninfo 2>/dev/null || echo "Indisponível."
        fi
        ui_msg_success "Consulta de informações de conectividade concluída."
    else
        android_warn_no_api
    fi
}

# 7. Lanterna (Flashlight)
android_torch() {
    ui_header "CONTROLE DA LANTERNA (TORCH)"
    if check_command termux-torch; then
        echo -e "  ${C_BOLD}1${C_RESET} │ Ligar Lanterna (ON)"
        echo -e "  ${C_BOLD}2${C_RESET} │ Desligar Lanterna (OFF)"
        echo ""
        echo -e -n "${C_PRIMARY}Escolha [1/2]: ${C_RESET}"
        read -r opt
        if [ "${opt}" = "1" ]; then
            termux-torch on
            ui_msg_success "Lanterna ligada."
        else
            termux-torch off
            ui_msg_success "Lanterna desligada."
        fi
    else
        android_warn_no_api
    fi
}

# 8. Síntese de Voz (TTS)
android_tts() {
    ui_header "TEXTO PARA VOZ (TTS)"
    if check_command termux-tts-speak; then
        local text
        echo -e -n "${C_PRIMARY}Digite o texto que o Android deve falar: ${C_RESET}"
        read -r text
        termux-tts-speak "${text:-Zenith Panel ativo. Todos os sistemas operacionais.}"
        ui_msg_success "Texto enviado ao mecanismo de voz."
    else
        android_warn_no_api
    fi
}

# Submenu principal do Módulo Android
android_menu() {
    while true; do
        ui_clear
        ui_header "MÓDULO ANDROID (TERMUX:API)"

        # Verifica e exibe alerta visual caso API não esteja disponível
        if ! check_termux_api; then
            android_warn_no_api
        else
            echo -e "${C_SUCCESS}[✓] Termux:API detectada e operacional.${C_RESET}"
            echo ""
        fi

        echo -e "  ${C_BOLD}1${C_RESET} │ 🔋 Informações e Status da Bateria"
        echo -e "  ${C_BOLD}2${C_RESET} │ 🔔 Enviar Notificação"
        echo -e "  ${C_BOLD}3${C_RESET} │ 💬 Enviar Toast"
        echo -e "  ${C_BOLD}4${C_RESET} │ 📳 Vibrar Dispositivo"
        echo -e "  ${C_BOLD}5${C_RESET} │ 📋 Área de Transferência (Clipboard)"
        echo -e "  ${C_BOLD}6${C_RESET} │ 📱 Informações do Dispositivo & Wi-Fi"
        echo -e "  ${C_BOLD}7${C_RESET} │ 🔦 Lanterna (Torch)"
        echo -e "  ${C_BOLD}8${C_RESET} │ 🗣️  Falar por Voz (TTS)"
        echo -e "  ${C_BOLD}0${C_RESET} │ 🚪 Voltar ao Menu Principal"
        echo ""
        ui_separator
        echo -e -n "${C_PRIMARY}Escolha uma opção [0-8]: ${C_RESET}"
        read -r choice
        case "${choice}" in
            1) android_battery; ui_pause ;;
            2) android_notification; ui_pause ;;
            3) android_toast; ui_pause ;;
            4) android_vibrate; ui_pause ;;
            5) android_clipboard; ui_pause ;;
            6) android_device_info; ui_pause ;;
            7) android_torch; ui_pause ;;
            8) android_tts; ui_pause ;;
            0) break ;;
            *) ui_msg_error "Opção inválida."; sleep 1 ;;
        esac
    done
}
