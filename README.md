# ⚡ ZENITH PANEL

> **ULTIMATE TERMUX TOOLKIT & MEGA PAINEL MODULAR PARA ANDROID E LINUX**  
> *Versão 1.0.0 — Todos os módulos integrados sem necessidade de root*

---

## 🎯 Sobre o Projeto

O **ZENITH PANEL** é um painel modular, profissional e altamente expansível desenvolvido em Bash compatível com **Termux (Android)** e distribuições **Linux** (Debian, Ubuntu, Arch, Alpine, etc.). 

Em vez de ser apenas um script com menus de comandos `echo`, o **ZENITH PANEL** possui uma arquitetura de software modular genuína com 23 módulos independentes, sistema de plugins dinâmicos, IA multi-provedor, auditorias de segurança defensiva éticas, sistema de logs persistentes e proteção de dados com confirmação explícita em operações destrutivas.

```
╔══════════════════════════════════════════════╗
║                                              ║
║          Z E N I T H   P A N E L             ║
║                                              ║
║            ULTIMATE TERMUX TOOLKIT           ║
║                                              ║
╠══════════════════════════════════════════════╣
║ 01 │ 🖥️  SISTEMA                             ║
║ 02 │ 📊  MONITOR                             ║
║ 03 │ 📱  ANDROID                             ║
║ 04 │ 🌐  REDE                                ║
║ 05 │ 🐧  LINUX                               ║
║ 06 │ 🤖  INTELIGÊNCIA ARTIFICIAL             ║
║ 07 │ 🛠️  FERRAMENTAS                         ║
║ 08 │ 📦  GIT / GITHUB                        ║
║ 09 │ ⚙️  AUTOMAÇÃO                           ║
║ 10 │ 🗄️  SERVIDORES                          ║
║ 11 │ 🎮  GAMING                              ║
║ 12 │ 🔐  SEGURANÇA DEFENSIVA                 ║
║ 13 │ 🔎  CONSULTAS / APIs                    ║
║ 14 │ 📂  ARQUIVOS                            ║
║ 15 │ 🎨  PERSONALIZAÇÃO                      ║
║ 16 │ 📦  GERENCIADOR DE PACOTES              ║
║ 17 │ 💾  BACKUP                              ║
║ 18 │ 🔧  CONFIGURAÇÕES                       ║
║ 19 │ 📚  DOCUMENTAÇÃO                        ║
║ 20 │ 🧩  PLUGINS                             ║
║ 21 │ 🔄  ATUALIZAR                           ║
║ 22 │ 🩺  DIAGNÓSTICO                         ║
║ 23 │ ℹ️  SOBRE                               ║
║  0 │ 🚪  SAIR                                ║
╚══════════════════════════════════════════════╝
```

---

## 🚀 Instalação Rápida

O instalador automático detecta o seu ambiente, verifica as dependências necessárias, estrutura os diretórios de configuração em `~/.config/zenith/` e instala o comando global `zenith`:

```bash
# Permissão e execução do instalador
chmod +x install.sh
bash install.sh
```

Depois de instalado, para iniciar o painel de qualquer lugar do terminal, basta digitar:

```bash
zenith
```

Ou rodar via modo CLI com flags diretas:

```bash
zenith --version     # Ver versão
zenith --diagnostic  # Gerar relatório de diagnóstico automático
zenith --backup      # Criar backup imediato
zenith 01            # Abrir direto um módulo numérico
```

---

## 🧩 Arquitetura Modular

```
zenith-panel/
├── zenith.sh          # Ponto de entrada e menu principal interativo / CLI
├── install.sh         # Instalador automático com detecção do sistema
├── uninstall.sh       # Desinstalador seguro com confirmação explícita
│
├── core/              # Núcleo do sistema (Core)
│   ├── colors.sh      # Paletas ANSI e 8 temas visuais
│   ├── ui.sh          # Caixas ASCII, banners e mensagens semânticas
│   ├── checks.sh      # Detecção do Termux, Linux, root, CPU, pacotes e internet
│   ├── config.sh      # Persistência em ~/.config/zenith/
│   ├── logger.sh      # Sistema de logs com timestamps e níveis de gravidade
│   └── utils.sh       # Funções de conversão, confirmação e spinners
│
├── modules/           # Módulos funcionais numerados (01 a 23)
│   ├── system.sh      # 01 - Informações de hardware, Android, Linux, CPU e shell
│   ├── monitor.sh     # 02 - Monitor instantâneo e em Tempo Real (auto-refresh)
│   ├── android.sh     # 03 - Termux:API (bateria, toast, vibração, torch, TTS)
│   ├── network.sh     # 04 - Rede defensiva (IP, gateway, DNS, ping, portas)
│   ├── linux.sh       # 05 - Ambientes proot-distro, processos e serviços
│   ├── ai.sh          # 06 - Zenith AI (OpenAI, Anthropic, Gemini, Groq, Ollama)
│   ├── tools.sh       # 07 - Calculadora, cronômetro, UUID, hashes e tar/zip
│   ├── github.sh      # 08 - Git clone, pull, push, status e commits
│   ├── automation.sh  # 09 - Scripts de automação, rotinas e crontab
│   ├── servers.sh     # 10 - Gerenciador de servidores web/locais com PID e logs
│   ├── gaming.sh      # 11 - Backups de mundos Minecraft, saves e launchers
│   ├── security.sh    # 12 - Auditorias de permissão 777, processos e relatório
│   ├── api.sh         # 13 - Cliente REST/HTTP no terminal (GET, POST, JSON)
│   ├── files.sh       # 14 - Gerenciador de arquivos (exclusão por 'CONFIRMAR')
│   ├── customization.sh # 15 & 18 - Temas (ZENITH, CYBER...), usuário e idioma
│   ├── packages.sh    # 16 - Prioridade em 'pkg' / fallback apt, pacman, apk
│   ├── backup.sh      # 17 - Backup com visualização prévia da restauração
│   ├── docs.sh        # 19 - Leitor Markdown interativo dos manuais em docs/
│   ├── plugins.sh     # 20 - Gerenciador de scripts e extensões em plugins/
│   ├── update.sh      # 21 - Verificador Git, changelog e backup auto pré-update
│   ├── diagnostic.sh  # 22 - 12 testes automáticos -> zenith-diagnostic.txt
│   └── about.sh       # 23 - Informações do projeto e licença MIT
│
├── plugins/           # Diretório de plugins de extensão auto-detectáveis
│   ├── exemplo.sh
│   ├── sistema_extra.sh
│   └── monitor_extra.sh
│
├── config/            # Modelos de configuração padrão e prompts da IA
├── docs/              # Documentação técnica completa e especializada
└── tests/             # Suíte de testes automatizados unitários e funcionais
```

---

## 🛡️ Segurança e Ética (Conformidade Garantida)

O **ZENITH PANEL** adota os mais altos padrões éticos e defensivos:
- **Zero Exploração ou Malware**: Sem ferramentas para ataques DDoS, phishing, invasão de terceiros ou roubo de contas/credenciais.
- **Auditoria Própria**: Utilitários de rede (`04`) e segurança (`12`) visam puramente auditoria, *hardening* e diagnóstico do próprio dispositivo ou laboratório autorizado.
- **Exclusão Explícita**: Nenhuma exclusão de arquivos ou backups ocorre em silêncio. Para operações críticas, o usuário precisa digitar a palavra exata **`CONFIRMAR`** em maiúsculas.
- **Proteção de Chaves**: Chaves de API de Inteligência Artificial nunca são expostas na tela em formato completo e são mantidas no arquivo persistente protegido (`~/.config/zenith/ai.conf` com `chmod 600`).

---

## 📚 Documentação Adicional

Todos os detalhes técnicos, comandos e tutoriais estão disponíveis na pasta `docs/`:
- [`docs/INSTALL.md`](docs/INSTALL.md) — Guia detalhado de instalação e dependências.
- [`docs/USAGE.md`](docs/USAGE.md) — Manual do usuário e descrição visual da interface.
- [`docs/COMMANDS.md`](docs/COMMANDS.md) — Referência da linha de comando e atalhos.
- [`docs/CONFIG.md`](docs/CONFIG.md) — Diretórios persistentes em `~/.config/zenith/`.
- [`docs/PLUGINS.md`](docs/PLUGINS.md) — Como criar seus próprios plugins na arquitetura Zenith.
- [`docs/AI.md`](docs/AI.md) — Guia do Zenith AI e configuração de múltiplos provedores.
- [`docs/BACKUP.md`](docs/BACKUP.md) — Política de salvamento, inspeção e restauração segura.
- [`docs/SECURITY.md`](docs/SECURITY.md) — Módulo de segurança defensiva e relatórios.
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — Solução dos problemas mais comuns.
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) — Como contribuir e rodar testes.

---

## 🧪 Testes Automatizados

Para executar todos os testes unitários do sistema:

```bash
bash tests/run_all_tests.sh
```

---

## 📄 Licença

Distribuído sob a licença **MIT** — veja o arquivo [`LICENSE`](LICENSE) para mais detalhes.
