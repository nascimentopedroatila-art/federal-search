# ============================================================
#  NEXUS - Modular Intelligence Toolkit
#  start.ps1  (Windows 11)
#
#  Uso:  .\scripts\start.ps1            -> menu interativo
#        .\scripts\start.ps1 scan --target example.com
# ============================================================
[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$python = "python"
if (Test-Path ".venv\Scripts\python.exe") {
    $python = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
}

if ($Args.Count -gt 0) {
    & $python nexus.py @Args
} else {
    & $python nexus.py menu
}
exit $LASTEXITCODE
