# Arquivos de Configuração - ZENITH PANEL

O **ZENITH PANEL** mantém todas as preferências, logs, backups, chaves de IA e cadastros em diretórios persistentes fora do código-fonte, garantindo segurança e preservação de dados durante atualizações.

---

## 📂 Estrutura de Diretórios (`~/.config/zenith/`)

| Arquivo / Pasta | Finalidade |
| :--- | :--- |
| `~/.config/zenith/zenith.conf` | Arquivo principal de configurações visuais, nome do usuário, idioma e caminhos. |
| `~/.config/zenith/ai.conf` | Armazena de forma segura (`chmod 600`) o provedor, modelo e chaves de API da IA. |
| `~/.config/zenith/servers.conf` | Cadastros persistentes dos servidores locais exibidos no módulo 10. |
| `~/.config/zenith/api_endpoints.conf` | Cadastros de endpoints HTTP e REST usados no módulo 13. |
| `~/.config/zenith/tasks.conf` | Cadastros de tarefas de automação e comandos de rotina do módulo 09. |
| `~/.config/zenith/backups/` | Pasta onde são gerados os pacotes `.tar.gz` de backup do painel. |
| `~/.config/zenith/logs/` | Registros de logs do sistema (`zenith.log`), IA (`ai_history.log`) e automação. |
| `~/.config/zenith/scripts/` | Diretório dedicado onde ficam scripts de automação customizados pelo usuário. |
| `~/.config/zenith/plugins/` | Diretório secundário de plugins (além de `./plugins/` no projeto). |

---

## 🎨 Parâmetros em `zenith.conf`
- `USER_NAME="TermuxUser"`: Nome exibido no prompt e nas saídas do painel.
- `THEME="ZENITH"`: Tema de cor ativo (`ZENITH`, `CYBER`, `MATRIX`, `MINIMAL`, `DARK`, `BLUE`, `GREEN`, `PURPLE`).
- `ANIMATIONS="true"`: Liga ou desliga animações visuais de spinner.
- `ANIMATION_SPEED="0.02"`: Intervalo em segundos de cada quadro de animação.
- `COMPACT_MODE="false"`: Reduz linhas divisórias em telas menores.
- `LANGUAGE="pt-BR"`: Idioma do sistema.
