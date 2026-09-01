# Instalação

## Windows 11 (prioridade)

Pré-requisito: **Python 3.12+** instalado de https://www.python.org/downloads/
(marque **"Add Python to PATH"** durante a instalação).

### Opção A — via git

```powershell
git clone https://github.com/nascimentopedroatila-art/federal-search.git
cd federal-search
.\scripts\install.ps1
```

O `install.ps1`:

1. verifica a versão do Python;
2. cria o ambiente virtual `.venv`;
3. instala as dependências (`requirements.txt`);
4. cria `config\config.json` a partir do exemplo;
5. executa `python nexus.py selfcheck`.

### Opção B — sem git (ZIP)

1. Baixe o ZIP do repositório e extraia.
2. Abra o PowerShell dentro da pasta extraída.
3. Execute `.\scripts\install.ps1`.

### Iniciar

```powershell
.\scripts\start.ps1            # menu interativo
.\scripts\start.ps1 scan --target example.com
```

ou o atalho:

```bat
NEXUS.bat
NEXUS.bat scan --target 8.8.8.8
```

> Se a execução de scripts do PowerShell estiver bloqueada, execute uma vez:
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

## Linux / macOS

```bash
git clone https://github.com/nascimentopedroatila-art/federal-search.git
cd federal-search
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python nexus.py selfcheck
```

## Termux (Android)

```bash
pkg install python git
git clone https://github.com/nascimentopedroatila-art/federal-search.git
cd federal-search
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python nexus.py selfcheck
```

> Em Termux, os comandos de diagnóstico de rede dependem de permissões do
> Android; o restante funciona normalmente.

## Atualização

```powershell
.\scripts\update.ps1    # Windows
```

ou manualmente:

```bash
git pull
pip install -r requirements.txt
```

## Verificação

```bash
python nexus.py selfcheck
python nexus.py plugins
python nexus.py --version
```
