# Desenvolvimento de Plugins - ZENITH PANEL

O **ZENITH PANEL** possui uma arquitetura de plugins modular para que você possa criar novos scripts, comandos de monitoramento ou integrações de terceiros sem modificar os arquivos do núcleo (`core/` ou `modules/`).

---

## 🧩 Como Criar um Plugin

1. Crie um novo script na pasta `plugins/` do projeto ou em `~/.config/zenith/plugins/` (ex: `meu_plugin.sh`).
2. Defina o cabeçalho obrigatório com as variáveis de metadados do plugin:
   ```bash
   #!/usr/bin/env bash
   PLUGIN_NAME="Meu Plugin Customizado"
   PLUGIN_VERSION="1.0.0"
   PLUGIN_AUTHOR="Seu Nome"
   PLUGIN_DESCRIPTION="Descrição do que este plugin faz para o usuário"
   ```
3. Implemente a função principal de execução `plugin_run()`:
   ```bash
   plugin_run() {
       echo -e "\033[38;5;51m[+] Executando Meu Plugin Customizado...\033[0m"
       # Coloque seus comandos Bash aqui
       echo "Verificação personalizada realizada com sucesso!"
   }
   ```

---

## ⚡ Gerenciando no Painel (Módulo 20)
- **1. Listar Plugins**: O painel detecta automaticamente todos os scripts `.sh` nas pastas `plugins/` e lista metadados na tela.
- **2. Ativar / 3. Desativar**: Grava o nome do plugin ativado em `~/.config/zenith/plugins.state`.
- **6. Executar Plugin Ativo**: Carrega o arquivo na memória e invoca a função `plugin_run()`.

### Exemplos Inclusos no Projeto
- `plugins/exemplo.sh`: Plugin de demonstração com teste de carregamento.
- `plugins/sistema_extra.sh`: Plugin com rotina avançada de limpeza de diretórios `/tmp`.
- `plugins/monitor_extra.sh`: Leitura de consumo estendido por memória e conexões TCP ativas.
