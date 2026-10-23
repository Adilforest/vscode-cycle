@echo off
setlocal enabledelayedexpansion

title Phantom Activity - Web Server

REM ╔════════════════════════════════════════════════════════════════════╗
REM ║                                                                    ║
REM ║     🌐 PHANTOM ACTIVITY WEB SERVER                               ║
REM ║        Remote Control via Cloudflare Tunnel                      ║
REM ║                                                                    ║
REM ╚════════════════════════════════════════════════════════════════════╝

color 0B

cls
echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║                                                                    ║
echo ║     🌐 PHANTOM ACTIVITY WEB SERVER v4.0                          ║
echo ║        Remote Control Interface                                  ║
echo ║                                                                    ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

REM Default API key (user should change it!)
set API_KEY=cfat_Akd9sK2lP9mX1Qw5rT8yU3vW6zB4cN7d
set PORT=5000

echo 📋 CONFIGURATION:
echo   Port: %PORT%
echo   API Key: %API_KEY%
echo.
echo ⚠️  IMPORTANT:
echo   1. Change the API key above for security!
echo   2. This should not be exposed to public internet
echo   3. Use Cloudflare Tunnel for remote access
echo.
pause

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell OK'" >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ❌ ERROR: PowerShell not found!
    echo Please install PowerShell or use the PowerShell console directly.
    pause
    exit /b 1
)

REM Start web server
echo.
echo [OK] Starting Web Server...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0phantom-activity-webserver-fixed.ps1" -Port %PORT% -ApiKey "%API_KEY%"

if errorlevel 1 (
    color 0C
    echo.
    echo ❌ ERROR: Web server failed to start
    pause
    exit /b 1
)

pause
