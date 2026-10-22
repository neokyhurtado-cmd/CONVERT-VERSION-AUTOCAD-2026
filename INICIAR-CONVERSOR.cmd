@echo off
setlocal
title TraficLabPro - Conversor local de versiones DWG
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Convertir-DWG.ps1"
if errorlevel 1 (
 echo.
 echo No se pudo iniciar el conversor. Verifica que tengas AutoCAD instalado.
 pause
)
endlocal
