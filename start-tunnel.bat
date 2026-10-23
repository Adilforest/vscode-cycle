@echo off
setlocal enabledelayedexpansion

title Phantom Activity - Cloudflare Tunnel

color 0B

cls
echo.
echo ====================================================================
echo.
echo [TUNNEL] Phantom Activity - Cloudflare Tunnel v4.0
echo [TUNNEL] Secure Remote Access
echo.
echo ====================================================================
echo.

echo [INFO] Make sure web server is running in another PowerShell!
echo [INFO] If not, run: start-webserver.bat first
echo.
pause

REM Check if cloudflared is installed
cloudflared --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo.
    echo [ERROR] cloudflared not found!
    echo.
    echo Please install cloudflared from:
    echo https://github.com/cloudflare/cloudflared/releases
    echo.
    pause
    exit /b 1
)

color 0B

echo [OK] cloudflared found
echo.
echo [TUNNEL] Starting tunnel: phantom-farm
echo.

REM Run tunnel
cloudflared tunnel run phantom-farm

pause
