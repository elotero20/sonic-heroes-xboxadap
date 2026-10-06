@echo off
rem Doble clic para instalar. Ejecuta instalar.ps1 sin cambiar la politica de scripts de Windows.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0instalar.ps1" %*
echo.
pause
