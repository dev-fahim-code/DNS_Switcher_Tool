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

:: -- One-time adapter selection at startup --
call :EnumerateAdapters
call :ClassifyAdapters
call :AdapterMenu

:Menu
cls
echo ==========================================================
echo                  Dev-Fahim-Code DNS Tool
:: Print the GitHub link in Blue using PowerShell
powershell -NoProfile -Command "Write-Host '             https://github.com/dev-fahim-code' -ForegroundColor Blue"
echo ==========================================================
echo.
echo Active Network Adapter: [%adapter%]
echo.
call :ShowCurrentDNS
echo 1. Cloudflare DNS (Best for Gaming ^& Speed)
echo 2. Google Public DNS (Best for General Stability ^& Routing)
echo 3. AdGuard DNS (Best for Blocking Ads ^& Trackers)
echo 4. Quad9 DNS (Best for Security ^& Threat Prevention)
echo 5. Ping Test All DNS Servers
echo 6. Change Network Adapter
echo 7. Reset DNS to Automatic (DHCP)
echo 8. Exit
echo.
set /p choice="Select an option (1-8): "

if "%choice%"=="1" goto CF
if "%choice%"=="2" goto Google
if "%choice%"=="3" goto AdGuard
if "%choice%"=="4" goto Quad9
if "%choice%"=="5" goto PingAll
if "%choice%"=="6" goto ChangeAdapter
if "%choice%"=="7" goto Reset
if "%choice%"=="8" exit /b
goto Menu

:CF
echo.
echo Applying Cloudflare DNS...
netsh interface ipv4 set dnsservers name="%adapter%" static 1.1.1.1 primary validate=no >nul 2>&1
netsh interface ipv4 add dnsservers name="%adapter%" 1.0.0.1 index=2 validate=no >nul 2>&1
netsh interface ipv6 set dnsservers name="%adapter%" static 2606:4700:4700::1111 >nul 2>&1
netsh interface ipv6 add dnsservers name="%adapter%" 2606:4700:4700::1001 index=2 >nul 2>&1
echo DNS successfully changed to Cloudflare!
echo.
call :ShowCurrentDNS
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
echo.
call :ShowCurrentDNS
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
echo.
call :ShowCurrentDNS
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
echo.
call :ShowCurrentDNS
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
echo.
call :ShowCurrentDNS
pause
goto Menu

:ChangeAdapter
call :EnumerateAdapters
call :ClassifyAdapters
call :AdapterMenu
goto Menu

:: ==========================================================
::  Shows the DNS servers currently active on the selected
::  adapter (static or DHCP-assigned) - both IPv4 and IPv6
:: ==========================================================
:ShowCurrentDNS
echo ----------------------------------------------------------
echo  Currently Active DNS on [%adapter%]
echo ----------------------------------------------------------
echo  IPv4:
netsh interface ipv4 show dnsservers name="%adapter%" | findstr /V /C:"Register"
echo.
echo  IPv6:
netsh interface ipv6 show dnsservers name="%adapter%" | findstr /V /C:"Register"
echo ----------------------------------------------------------
echo.
goto :eof

:: ==========================================================
::  Clears any adapter arrays left over from a previous run
:: ==========================================================
:ClearAdapterVars
for /f "delims== tokens=1" %%v in ('set adapterName_ 2^>nul') do set "%%v="
for /f "delims== tokens=1" %%v in ('set ethName_ 2^>nul') do set "%%v="
for /f "delims== tokens=1" %%v in ('set wifiName_ 2^>nul') do set "%%v="
for /f "delims== tokens=1" %%v in ('set otherName_ 2^>nul') do set "%%v="
for /f "delims== tokens=1" %%v in ('set opt_ 2^>nul') do set "%%v="
goto :eof

:: ==========================================================
::  Finds every "Connected" interface reported by netsh
:: ==========================================================
:EnumerateAdapters
call :ClearAdapterVars
set "adapterCount=0"
for /f "tokens=* delims=" %%L in ('netsh interface show interface ^| findstr /C:"Connected"') do (
    for /f "tokens=* delims= " %%A in ("%%L") do (
        for /f "tokens=1-3* delims= " %%a in ("%%A") do (
            if not "%%d"=="" (
                set /a adapterCount+=1
                set "adapterName_!adapterCount!=%%d"
            )
        )
    )
)
goto :eof

:: ==========================================================
::  Splits detected adapters into Ethernet / Wi-Fi / Other
::  based on their interface name
:: ==========================================================
:ClassifyAdapters
set "ethCount=0"
set "wifiCount=0"
set "otherCount=0"
if %adapterCount% GTR 0 (
    for /l %%i in (1,1,%adapterCount%) do (
        set "curName=!adapterName_%%i!"
        echo !curName! | findstr /I /C:"Wi-Fi" /C:"Wireless" /C:"WLAN" >nul
        if !errorlevel! equ 0 (
            set /a wifiCount+=1
            set "wifiName_!wifiCount!=!curName!"
        ) else (
            echo !curName! | findstr /I /C:"Ethernet" /C:"LAN" >nul
            if !errorlevel! equ 0 (
                set /a ethCount+=1
                set "ethName_!ethCount!=!curName!"
            ) else (
                set /a otherCount+=1
                set "otherName_!otherCount!=!curName!"
            )
        )
    )
)
goto :eof

:: ==========================================================
::  Lets the user pick Ethernet or Wi-Fi (or another adapter)
::  from the connected adapters found above
:: ==========================================================
:AdapterMenu
cls
echo ==========================================================
echo              Select Network Adapter
echo ==========================================================
echo.
set "idx=0"
if %ethCount% GTR 0 (
    for /l %%i in (1,1,%ethCount%) do (
        set /a idx+=1
        echo !idx!. [Ethernet]  !ethName_%%i!
        set "opt_!idx!=!ethName_%%i!"
    )
)
if %wifiCount% GTR 0 (
    for /l %%i in (1,1,%wifiCount%) do (
        set /a idx+=1
        echo !idx!. [Wi-Fi]     !wifiName_%%i!
        set "opt_!idx!=!wifiName_%%i!"
    )
)
if %otherCount% GTR 0 (
    for /l %%i in (1,1,%otherCount%) do (
        set /a idx+=1
        echo !idx!. [Other]     !otherName_%%i!
        set "opt_!idx!=!otherName_%%i!"
    )
)
echo.
if %idx%==0 (
    echo No connected adapters detected. Falling back to "Wi-Fi".
    set "adapter=Wi-Fi"
    pause
    goto :eof
)
set /p adapterChoice="Select adapter (1-%idx%): "
if not defined opt_%adapterChoice% (
    echo Invalid selection.
    pause
    goto AdapterMenu
)
set "adapter=!opt_%adapterChoice%!"
goto :eof
