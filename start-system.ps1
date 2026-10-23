# ╔════════════════════════════════════════════════════════════════════╗
# ║  Phantom Activity System - Startup Script v4.1 (Fixed)             ║
# ║  Initializes and starts all system components                      ║
# ╚════════════════════════════════════════════════════════════════════╝

param(
    [switch]$WebServerOnly = $false,
    [switch]$MainMenuOnly = $false,
    [int]$Port = 5000,
    [string]$ApiKey = "phantom-secret-key-change-me"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$username = $env:USERNAME
$scriptsDir = "C:\Users\$username\Scripts"
$configFile = "$scriptsDir\vscode-cycle.config.json"
$logFile = "$scriptsDir\vscode-cycle.log"
$statusFile = "$scriptsDir\phantom-activity-status.json"

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "║          🚀 PHANTOM ACTIVITY SYSTEM - Professional v4.1           ║" -ForegroundColor Cyan
    Write-Host "║                  24/7 Farm Activity Monitor (FIXED)               ║" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Start-WebServer {
    Write-Host "🌐 Starting Web Server on port $Port..." -ForegroundColor Green

    # Start web server in background
    $psArgs = @(
        "-NoProfile"
        "-ExecutionPolicy", "Bypass"
        "-File", "`"$scriptsDir\phantom-activity-webserver.ps1`""
        "-Port", $Port
        "-ApiKey", $ApiKey
    )

    Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -WindowStyle Minimized

    Start-Sleep -Seconds 2

    Write-Host "✅ Web Server started" -ForegroundColor Green
    Write-Host "📍 Access at http://localhost:$Port/" -ForegroundColor Cyan
    Write-Host "🔑 API Key: $ApiKey" -ForegroundColor Yellow
    Write-Host ""
}

function Start-MainMenu {
    Write-Host "📋 Starting Main Menu..." -ForegroundColor Green
    & "$scriptsDir\phantom-activity-main.ps1"
}

function Start-TrayIcon {
    Write-Host "📌 Starting System Tray..." -ForegroundColor Green

    $psArgs = @(
        "-NoProfile"
        "-ExecutionPolicy", "Bypass"
        "-File", "`"$scriptsDir\vscode-cycle-tray.ps1`""
    )

    Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -WindowStyle Hidden

    Write-Host "✅ Tray icon started" -ForegroundColor Green
    Write-Host ""
}

# Show banner
Show-Banner

# Initialize system
Write-Host "⚙️  Initializing Phantom Activity System..." -ForegroundColor Yellow

# Check configuration
if (-not (Test-Path $configFile)) {
    Write-Host "⚠️  Configuration file not found, using defaults" -ForegroundColor Yellow
} else {
    Write-Host "✅ Configuration loaded" -ForegroundColor Green
}

# Check log file
if (-not (Test-Path $logFile)) {
    Write-Host "📝 Creating log file..." -ForegroundColor Cyan
    New-Item -Path $logFile -ItemType File -Force | Out-Null
}

Write-Host ""

# Main startup flow
if ($WebServerOnly) {
    Start-WebServer
    Write-Host "🔄 Web Server running in foreground. Press Ctrl+C to stop." -ForegroundColor Yellow
    Wait-Process -Id (Get-Process | Where-Object { $_.ProcessName -eq "powershell" -and $_.Id -gt 1000 }).Id -ErrorAction SilentlyContinue
} elseif ($MainMenuOnly) {
    Start-MainMenu
} else {
    # Start complete system
    Write-Host "🚀 Starting complete system..." -ForegroundColor Green
    Write-Host ""

    Start-WebServer
    Start-Sleep -Milliseconds 500

    Start-TrayIcon
    Start-Sleep -Milliseconds 500

    Start-MainMenu
}
