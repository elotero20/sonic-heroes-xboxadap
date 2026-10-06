@echo off
rem Doble clic para desinstalar los mods. Ejecuta desinstalar.ps1 sin cambiar la politica de scripts de Windows.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0desinstalar.ps1" %*
echo.
pause
