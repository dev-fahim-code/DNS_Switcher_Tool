@echo off
setlocal EnableDelayedExpansion

:: -- Request Administrative Privileges (elevates and exits if not admin) --
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrative Privileges to change DNS settings...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:AdminGranted
:: Set overall color: Background Black (0), Text Light Red (C)
color 0C

:Menu
cls
echo ==========================================================
echo                  Dev-Fahim-Code DNS Tool
:: Print the GitHub link in Blue using PowerShell
powershell -NoProfile -Command "Write-Host '             https://github.com/dev-fahim-code' -ForegroundColor Blue"
echo ==========================================================
echo.

:: -- Find the first active (Connected) network adapter using netsh --
set "adapter="
for /f "tokens=* delims=" %%L in ('netsh interface show interface ^| findstr /R /C:"Connected"') do (
    :: Trim leading spaces
    for /f "tokens=* delims= " %%A in ("%%L") do (
        :: tokens=1-3* -> %%a=AdminState %%b=State %%c=Type %%d=InterfaceName(rest)
        for /f "tokens=1-3* delims= " %%a in ("%%A") do (
            if not "%%d"=="" (
                set "adapter=%%d"
                goto :AdapterFound
            )
        )
    )
)
:AdapterFound
if "%adapter%"=="" (
    echo No connected adapter found via netsh. Falling back to Wi-Fi.
    set "adapter=Wi-Fi"
)

:: Verify adapter exists
netsh interface show interface name="%adapter%" >nul 2>&1
if errorlevel 1 (
    echo Adapter "%adapter%" not found. Falling back to first listed interface.
    for /f "skip=3 tokens=* delims=" %%I in ('netsh interface show interface') do (
        for /f "tokens=* delims= " %%J in ("%%I") do (
            for /f "tokens=1-3* delims= " %%a in ("%%J") do (
                if not "%%d"=="" (
                    set "adapter=%%d"
                    goto :AdapterVerified
                )
            )
        )
    )
)
:AdapterVerified

echo Active Network Adapter Detected: [%adapter%]
echo.
echo 1. Cloudflare DNS (Best for Gaming ^& Speed)
echo 2. Google Public DNS (Best for General Stability ^& Routing)
echo 3. AdGuard DNS (Best for Blocking Ads ^& Trackers)
echo 4. Quad9 DNS (Best for Security ^& Threat Prevention)
echo 5. Ping Test All DNS Servers
echo 6. Reset DNS to Automatic (DHCP)
echo 7. Exit
echo.
set /p choice="Select an option (1-7): "

if "%choice%"=="1" goto CF
if "%choice%"=="2" goto Google
if "%choice%"=="3" goto AdGuard
if "%choice%"=="4" goto Quad9
if "%choice%"=="5" goto PingAll
if "%choice%"=="6" goto Reset
if "%choice%"=="7" exit /b
goto Menu

:CF
echo.
echo Applying Cloudflare DNS...
netsh interface ipv4 set dnsservers name="%adapter%" static 1.1.1.1 primary validate=no >nul 2>&1
netsh interface ipv4 add dnsservers name="%adapter%" 1.0.0.1 index=2 validate=no >nul 2>&1
:: IPv6: use the simpler static/add forms
netsh interface ipv6 set dnsservers name="%adapter%" static 2606:4700:4700::1111 >nul 2>&1
netsh interface ipv6 add dnsservers name="%adapter%" 2606:4700:4700::1001 index=2 >nul 2>&1
echo DNS successfully changed to Cloudflare!
pause
goto Menu

:Google
echo.
echo Applying Google Public DNS...
netsh interface ipv4 set dnsservers name="%adapter%" static 8.8.8.8 primary validate=no >nul 2>&1
netsh interface ipv4 add dnsservers name="%adapter%" 8.8.4.4 index=2 validate=no >nul 2>&1
netsh interface ipv6 set dnsservers name="%adapter%" static 2001:4860:4860::8888 >nul 2>&1
netsh interface ipv6 add dnsservers name="%adapter%" 2001:4860:4860::8844 index=2 >nul 2>&1
echo DNS successfully changed to Google!
pause
goto Menu

:AdGuard
echo.
echo Applying AdGuard DNS...
netsh interface ipv4 set dnsservers name="%adapter%" static 94.140.14.14 primary validate=no >nul 2>&1
netsh interface ipv4 add dnsservers name="%adapter%" 94.140.15.15 index=2 validate=no >nul 2>&1
netsh interface ipv6 set dnsservers name="%adapter%" static 2a10:50c0::ad1:ff >nul 2>&1
netsh interface ipv6 add dnsservers name="%adapter%" 2a10:50c0::ad2:ff index=2 >nul 2>&1
echo DNS successfully changed to AdGuard!
pause
goto Menu

:Quad9
echo.
echo Applying Quad9 DNS...
netsh interface ipv4 set dnsservers name="%adapter%" static 9.9.9.9 primary validate=no >nul 2>&1
netsh interface ipv4 add dnsservers name="%adapter%" 149.112.112.112 index=2 validate=no >nul 2>&1
netsh interface ipv6 set dnsservers name="%adapter%" static 2620:fe::fe >nul 2>&1
netsh interface ipv6 add dnsservers name="%adapter%" 2620:fe::9 index=2 >nul 2>&1
echo DNS successfully changed to Quad9!
pause
goto Menu

:PingAll
cls
echo ==========================================================
echo                  Running Ping Tests
echo ==========================================================
echo.

call :DoPing "Cloudflare" 1.1.1.1
call :DoPing "Google" 8.8.8.8
call :DoPing "AdGuard" 94.140.14.14
call :DoPing "Quad9" 9.9.9.9

echo ==========================================================
echo Ping test complete. Lower average time is better.
pause
goto Menu

:DoPing
setlocal
set "pname=%~1"
set "ip=%~2"
echo Pinging %pname% (%ip%)...
set "avg="
for /f "tokens=4 delims==" %%A in ('ping -n 4 %ip% ^| findstr /C:"Average"') do set "avg=%%A"
if not defined avg (
    echo     Request timed out or host unreachable
) else (
    echo     Average =%avg%
)
echo.
endlocal
goto :eof

:Reset
echo.
echo Resetting DNS to Automatic (DHCP)...
netsh interface ipv4 set dnsservers name="%adapter%" dhcp >nul 2>&1
netsh interface ipv6 set dnsservers name="%adapter%" dhcp >nul 2>&1
echo DNS successfully reset to Automatic!
pause
goto Menu
