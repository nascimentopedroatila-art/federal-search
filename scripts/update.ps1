# ============================================================
#  NEXUS - Modular Intelligence Toolkit
#  update.ps1  (Windows 11)
#
#  Atualiza o NEXUS: pull do git + dependencias + selfcheck.
#  Uso:  .\scripts\update.ps1
# ============================================================
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "[1/3] Atualizando codigo (git pull)..." -ForegroundColor Green
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Warning "git nao encontrado; pulando atualizacao do codigo."
} else {
    & git pull --ff-only
    if ($LASTEXITCODE -ne 0) { Write-Warning "git pull falhou (verifique conflitos ou conexao)." }
}

$venvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Warning ".venv nao encontrado. Execute .\scripts\install.ps1 primeiro."
    exit 1
}

Write-Host "[2/3] Atualizando dependencias..." -ForegroundColor Green
& $venvPython -m pip install --upgrade -r requirements.txt
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao atualizar dependencias." }

Write-Host "[3/3] Verificacao..." -ForegroundColor Green
& $venvPython nexus.py selfcheck

Write-Host "NEXUS atualizado!" -ForegroundColor Green
exit 0
