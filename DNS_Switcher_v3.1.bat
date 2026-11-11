@echo off
setlocal
title DNS Switcher v3.1
if not exist "%~dp0DNS-Switcher.ps1" (
    echo DNS-Switcher.ps1 was not found next to this file.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DNS-Switcher.ps1"
if errorlevel 1 (
    echo.
    echo DNS Switcher closed with an error.
    pause
)
endlocal
