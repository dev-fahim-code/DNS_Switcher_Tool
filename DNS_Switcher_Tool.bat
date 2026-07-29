@echo off
:: ==========================================
:: DNS Switcher Tool
:: Author: Dev-Fahim-Code
:: GitHub: https://github.com/dev-fahim-code
:: ==========================================

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

color 0C
title DNS Switcher - by Dev-Fahim-Code

:: Detect the actual console width so centering matches this window
for /f "tokens=2 delims=:" %%A in ('mode con ^| findstr /C:"Columns"') do set "CONSOLE_WIDTH=%%A"
set "CONSOLE_WIDTH=%CONSOLE_WIDTH: =%"
if "%CONSOLE_WIDTH%"=="" set "CONSOLE_WIDTH=80"

:: Default network adapter name. Change here if yours differs,
:: or just type the correct name when prompted below.
set "INTERFACE=Ethernet"

:setup
cls
call :center "=========================================="
call :center "            DNS SWITCHER TOOL"
call :center "=========================================="
call :center "        Dev-Fahim-Code"
call :center "  https://github.com/dev-fahim-code"
call :center "=========================================="
echo.
echo   Target network adapter is currently set to: "%INTERFACE%"
echo   (Run "ncpa.cpl" or check Settings ^> Network to confirm your
echo    adapter's exact name if it's not "Ethernet", e.g. "Wi-Fi")
echo.
set /p "newif=  Press ENTER to keep it, or type the correct adapter name: "
if not "%newif%"=="" set "INTERFACE=%newif%"

:menu
cls
call :center "=========================================="
call :center "      DNS SWITCHER  (Adapter: %INTERFACE%)"
call :center "=========================================="
call :center " 1. Google DNS (8.8.8.8 / 8.8.4.4)"
call :center " 2. Quad9 DNS (9.9.9.9 / 149.112.112.112)"
call :center " 3. Cloudflare DNS (1.1.1.1 / 1.0.0.1)"
call :center " 4. Reset to Automatic (DHCP)"
call :center " 5. TEST ALL (Ping Latency Test)"
call :center " 6. Change Adapter Name"
call :center " 7. Exit"
call :center "=========================================="
echo.
set /p choice="Select an option (1-7): "
if "%choice%"=="1" goto google
if "%choice%"=="2" goto quad9
if "%choice%"=="3" goto cloudflare
if "%choice%"=="4" goto dhcp
if "%choice%"=="5" goto testpings
if "%choice%"=="6" goto setup
if "%choice%"=="7" goto exit
goto menu

:google
echo Setting Google DNS on "%INTERFACE%"...
netsh interface ipv4 set dns name="%INTERFACE%" static 8.8.8.8 primary
netsh interface ipv4 add dns name="%INTERFACE%" 8.8.4.4 index=2
goto success

:quad9
echo Setting Quad9 DNS on "%INTERFACE%"...
netsh interface ipv4 set dns name="%INTERFACE%" static 9.9.9.9 primary
netsh interface ipv4 add dns name="%INTERFACE%" 149.112.112.112 index=2
goto success

:cloudflare
echo Setting Cloudflare DNS on "%INTERFACE%"...
netsh interface ipv4 set dns name="%INTERFACE%" static 1.1.1.1 primary
netsh interface ipv4 add dns name="%INTERFACE%" 1.0.0.1 index=2
goto success

:dhcp
echo Resetting DNS to automatic (DHCP) on "%INTERFACE%"...
netsh interface ipv4 set dns name="%INTERFACE%" source=dhcp
goto success

:testpings
cls
call :center "=========================================="
call :center "         RUNNING DNS LATENCY TEST"
call :center "=========================================="
echo.
echo [1/3] Pinging Google DNS (8.8.8.8)...
ping 8.8.8.8 -n 4
echo ------------------------------------------
echo [2/3] Pinging Quad9 DNS (9.9.9.9)...
ping 9.9.9.9 -n 4
echo ------------------------------------------
echo [3/3] Pinging Cloudflare DNS (1.1.1.1)...
ping 1.1.1.1 -n 4
echo ==========================================
echo Test Complete. Look at the "Average" times above.
echo Lower ms = Faster gaming and browsing response.
echo.
pause
goto menu

:success
if %errorLevel% neq 0 (
    echo.
    echo   [WARNING] netsh reported an error. Check that "%INTERFACE%"
    echo   is the exact, correct name of your network adapter.
) else (
    echo.
    echo   DNS updated successfully!
)
echo   Flushing DNS cache...
ipconfig /flushdns
echo.
pause
goto menu

:center
:: Roughly centers a line of text on an 80-column console
setlocal enabledelayedexpansion
set "str=%~1"
set "len=0"
:strlen_loop
if defined str (
    set "str=!str:~1!"
    set /a len+=1
    goto strlen_loop
)
set /a pad=(!CONSOLE_WIDTH!-len)/2
if !pad! lss 0 set pad=0
set "spaces="
for /l %%i in (1,1,!pad!) do set "spaces=!spaces! "
echo(!spaces!%~1
endlocal
goto :eof

:exit
exit
