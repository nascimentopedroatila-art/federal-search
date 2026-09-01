# ============================================================
#  NEXUS - Modular Intelligence Toolkit
#  install.ps1  (Windows 11, PowerShell 5.1+)
#
#  Uso:  .\scripts\install.ps1
# ============================================================
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  NEXUS - Modular Intelligence Toolkit" -ForegroundColor Cyan
Write-Host "  Instalacao para Windows 11" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# --- Python -------------------------------------------------
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
    Write-Error "Python nao encontrado. Instale o Python 3.12+ em https://www.python.org/downloads/ e marque 'Add Python to PATH'."
}

$pyVersion = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
Write-Host "[1/5] Python encontrado: $pyVersion" -ForegroundColor Green

$major = [int]($pyVersion.Split(".")[0])
$minor = [int]($pyVersion.Split(".")[1])
if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 12)) {
    Write-Warning "NEXUS requer Python 3.12+. Versao atual: $pyVersion"
    Write-Warning "Baixe em https://www.python.org/downloads/ e rode este script novamente."
    exit 1
}

# --- Virtualenv ---------------------------------------------
Write-Host "[2/5] Criando ambiente virtual..." -ForegroundColor Green
if (-not (Test-Path ".venv")) {
    & python -m venv .venv
    if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao criar venv." }
} else {
    Write-Host "      .venv ja existe." -ForegroundColor DarkGray
}

$venvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
& $venvPython -m pip install --upgrade pip --quiet
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao atualizar pip." }

# --- Dependencias -------------------------------------------
Write-Host "[3/5] Instalando dependencias..." -ForegroundColor Green
& $venvPython -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao instalar dependencias." }

# --- Configuracao inicial ------------------------------------
Write-Host "[4/5] Preparando configuracao..." -ForegroundColor Green
if (-not (Test-Path "config\config.json")) {
    Copy-Item "config\config.example.json" "config\config.json"
    Write-Host "      config\config.json criado." -ForegroundColor DarkGray
}

# --- Teste rapido --------------------------------------------
Write-Host "[5/5] Verificando instalacao..." -ForegroundColor Green
& $venvPython nexus.py selfcheck

Write-Host ""
Write-Host "Instalacao concluida!" -ForegroundColor Green
Write-Host "Inicie com:  .\scripts\start.ps1   (ou  NEXUS.bat)" -ForegroundColor Cyan
exit 0
