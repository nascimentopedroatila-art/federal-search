@echo off
rem ============================================================
rem  NEXUS - Modular Intelligence Toolkit
rem  Iniciador para Windows (usa o venv se existir)
rem  Uso:  NEXUS.bat            -> menu interativo
rem        NEXUS.bat scan --target example.com
rem ============================================================
setlocal
cd /d "%~dp0"

if exist ".venv\Scripts\python.exe" (
    ".venv\Scripts\python.exe" nexus.py %*
) else (
    python nexus.py %*
)

exit /b %ERRORLEVEL%
