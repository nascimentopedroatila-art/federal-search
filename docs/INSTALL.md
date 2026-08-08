# Guia de Instalação do ZENITH PANEL

O **ZENITH PANEL** foi projetado para funcionar nativamente no **Termux (Android)** e em sistemas **Linux padrão** (Debian, Ubuntu, Arch, Alpine, etc.) sem exigir privilégios de root.

---

## 🚀 Instalação Rápida

Para instalar e configurar o painel no seu dispositivo, clone o repositório ou acesse a pasta e execute o script instalador:

```bash
# Clone o projeto caso ainda não tenha clonado
git clone https://github.com/nascimentopedroatila-art/federal-search.git
cd federal-search

# Conceda permissão e execute o instalador
chmod +x install.sh
bash install.sh
```

### O que o instalador (`install.sh`) faz:
1. Detecta o ambiente operacional (Termux ou Linux Genérico).
2. Verifica dependências necessárias (`curl`, `wget`, `git`, `python`, `termux-api`).
3. Cria a estrutura de configuração em `~/.config/zenith/`.
4. Instala os arquivos e cria o comando global `zenith` acessível de qualquer diretório.
5. Testa a instalação e apresenta a caixa ASCII de sucesso.

---

## 🖥️ Executando o Painel

Após a instalação, basta digitar no seu terminal:

```bash
zenith
```

Ou executar com argumentos rápidos:

```bash
zenith --version     # Exibe a versão do Zenith Panel
zenith --diagnostic  # Gera relatório de diagnóstico do sistema
zenith --help        # Mostra opções da interface de linha de comando
```

---

## 📦 Dependências Suportadas

O **ZENITH PANEL** detecta e utiliza automaticamente as seguintes ferramentas operacionais opcionais ou recomendadas:
- `git`: Controle de versão e atualização (Módulo 08).
- `curl` / `wget`: Testes de rede, IA e requisições HTTP (Módulos 04, 06, 13).
- `python3` / `bc`: Calculadora e processamento JSON (Módulos 07, 13).
- `termux-api`: Integração com bateria, vibração, torch e toast no Android (Módulo 03).
- `proot-distro`: Gerenciamento de distribuições Linux dentro do Termux (Módulo 05).
