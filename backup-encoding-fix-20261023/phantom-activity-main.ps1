# ╔════════════════════════════════════════════════════════════════════╗
# ║                                                                    ║
# ║     🚀 PHANTOM ACTIVITY SYSTEM - Professional Edition v3.5        ║
# ║                    24/7 Farm Activity Monitor                     ║
# ║                                                                    ║
# ╚════════════════════════════════════════════════════════════════════╝

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$username = $env:USERNAME
$scriptsDir = "C:\Users\$username\Scripts"
$configFile = "$scriptsDir\vscode-cycle.config.json"
$logFile = "$scriptsDir\vscode-cycle.log"

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "║          🚀 PHANTOM ACTIVITY SYSTEM - Professional v3.5           ║" -ForegroundColor Cyan
    Write-Host "║                     24/7 Farm Activity Monitor                    ║" -ForegroundColor Cyan
    Write-Host "║                                                                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Status {
    $now = Get-Date
    $dayOfWeek = $now.DayOfWeek.ToString()
    $time = $now.ToString("HH:mm:ss")
    $date = $now.ToString("dd.MM.yyyy")

    # Holidays (non-working days)
    # To add more holidays, edit vscode-cycle.config.json
    # Add dates in format: "YYYY-MM-DD"
    $holidays = @(
        "2026-10-26"  # Monday, October 26 - Holiday
    )

    $todayStr = $now.ToString("yyyy-MM-dd")
    $isHoliday = $holidays -contains $todayStr
    $isDaytime = $now.Hour -ge 8 -and $now.Hour -lt 20

    Write-Host "📊 SYSTEM STATUS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  🕐 Time:       $time" -ForegroundColor White
    Write-Host "  📅 Date:       $date ($dayOfWeek)" -ForegroundColor White
    Write-Host "  🏠 Status:     " -ForegroundColor White -NoNewline

    if ($isHoliday) {
        Write-Host "HOLIDAY (OFF) 🎉" -ForegroundColor Red
    } elseif ($isDaytime) {
        Write-Host "WORKING HOURS 💼" -ForegroundColor Green
    } else {
        Write-Host "OFF HOURS 😴" -ForegroundColor DarkGray
    }

    Write-Host ""
}

function Show-Menu {
    Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🎮 OPERATION MODES:" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  📝 QUICK MODES:" -ForegroundColor Green
    Write-Host "    [1] Quick       (30 sec  - VS Code only)" -ForegroundColor White
    Write-Host "    [2] Standard    (45 sec  - VS Code only)" -ForegroundColor White
    Write-Host "    [3] Extended    (60 sec  - VS Code only)" -ForegroundColor White
    Write-Host "    [4] Full        (120 sec - VS Code only)" -ForegroundColor White
    Write-Host ""

    Write-Host "  🚀 PROFESSIONAL MODE:" -ForegroundColor Green
    Write-Host "    [5] Extended Cycle     (All apps: VS Code + Planfix + GitLab + Terminal)" -ForegroundColor White
    Write-Host "    [9] VISIBLE Mode       (For Manic Time - All windows visible)" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  ♾️  CONTINUOUS MODES:" -ForegroundColor Green
    Write-Host "    [6] Always-On Standard (Background cycling - smart intervals)" -ForegroundColor Cyan
    Write-Host "    [*] Always-On Extended (Background cycling - 4 apps)" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  ⚙️  SYSTEM:" -ForegroundColor Green
    Write-Host "    [7] Dashboard      (View stats and history)" -ForegroundColor Cyan
    Write-Host "    [8] Health Check   (Verify all components ready)" -ForegroundColor White
    Write-Host "    [9] View Logs      (Real-time activity logs)" -ForegroundColor White
    Write-Host "    [A] Settings       (Configure times and parameters)" -ForegroundColor White
    Write-Host "    [T] System Tray    (Legacy tray service)" -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "  🛑 CONTROL:" -ForegroundColor Green
    Write-Host "    [Q] Quit" -ForegroundColor White
    Write-Host ""

    Write-Host "════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

function Show-Features {
    Write-Host ""
    Write-Host "✨ KEY FEATURES:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  ✓ 4 Different Applications (VS Code, Planfix, GitLab, Terminal)" -ForegroundColor Green
    Write-Host "  ✓ 25+ Phantom Actions (Realistic developer activity)" -ForegroundColor Green
    Write-Host "  ✓ Time Randomization (8:25-8:48, 13:00-13:14, 13:30-13:35, 18:58-20:00)" -ForegroundColor Green
    Write-Host "  ✓ Holiday Recognition (Oct 26, 2026 excluded)" -ForegroundColor Green
    Write-Host "  ✓ Manic Time Compatible (Screenshots + Activity logs)" -ForegroundColor Green
    Write-Host "  ✓ 24/7 Monitoring (System Tray auto-cycling)" -ForegroundColor Green
    Write-Host "  ✓ Full Logging (Every action recorded)" -ForegroundColor Green
    Write-Host ""
}

function Get-AppConfig {
    if (Test-Path $configFile) {
        try { return Get-Content -Path $configFile -Raw | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

function Show-Config-Info {
    $cfg = Get-AppConfig
    if ($cfg) {
        Write-Host "📋 CURRENT CONFIGURATION:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Working Hours:    $($cfg.ActiveStartHour):25-48 to $($cfg.ActiveEndHour):58-00" -ForegroundColor White
        Write-Host "  Lunch Break:      13:00-14 to 13:30-35" -ForegroundColor White
        Write-Host "  Working Days:     Mon-Fri (Holiday excluded: Oct 26)" -ForegroundColor White
        Write-Host "  Cycle Duration:   $($cfg.StayOpenSeconds) seconds" -ForegroundColor White
        Write-Host "  Status:           $(if($cfg.Enabled) { '✅ ENABLED' } else { '❌ DISABLED' })" -ForegroundColor White
        Write-Host ""
    }
}

# Main loop
do {
    Show-Banner
    Show-Status
    Show-Menu
    Show-Features
    Show-Config-Info

    $choice = Read-Host "Select operation (0-9)"
    Write-Host ""

    switch ($choice) {
        1 {
            Write-Host "🚀 Starting Quick Mode (30 sec)..." -ForegroundColor Green
            & "$scriptsDir\vscode-cycle.ps1" -StayOpenSeconds 30
            Read-Host "Press Enter to continue"
        }
        2 {
            Write-Host "🚀 Starting Standard Mode (45 sec)..." -ForegroundColor Green
            & "$scriptsDir\vscode-cycle.ps1" -StayOpenSeconds 45
            Read-Host "Press Enter to continue"
        }
        3 {
            Write-Host "🚀 Starting Extended Mode (60 sec)..." -ForegroundColor Green
            & "$scriptsDir\vscode-cycle.ps1" -StayOpenSeconds 60
            Read-Host "Press Enter to continue"
        }
        4 {
            Write-Host "🚀 Starting Full Mode (120 sec)..." -ForegroundColor Green
            & "$scriptsDir\vscode-cycle.ps1" -StayOpenSeconds 120
            Read-Host "Press Enter to continue"
        }
        5 {
            Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║  🚀 STARTING EXTENDED CYCLE - All Applications       ║" -ForegroundColor Cyan
            Write-Host "║     VS Code + Planfix + GitLab + Terminal             ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            & "$scriptsDir\vscode-cycle-extended.ps1" -StayOpenSeconds 45
            Read-Host "Press Enter to continue"
        }
        6 {
            Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║  ♾️  ALWAYS-ON MODE - Continuous Standard Cycling    ║" -ForegroundColor Cyan
            Write-Host "║     Runs in background with smart intervals           ║" -ForegroundColor Cyan
            Write-Host "║     Press Ctrl+C to stop                              ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            & "$scriptsDir\phantom-activity-alwayson.ps1" -UseExtended $false -ShowConsole $true
        }
        * {
            Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║  ♾️  ALWAYS-ON EXTENDED - Continuous All-Apps Mode   ║" -ForegroundColor Cyan
            Write-Host "║     Runs in background - 4 apps cycling               ║" -ForegroundColor Cyan
            Write-Host "║     Press Ctrl+C to stop                              ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            & "$scriptsDir\phantom-activity-alwayson.ps1" -UseExtended $true -ShowConsole $true
        }
        7 {
            Write-Host "📊 Opening Dashboard..." -ForegroundColor Green
            & "$scriptsDir\phantom-activity-stats.ps1"
        }
        8 {
            Write-Host "🔍 Running Health Check..." -ForegroundColor Green
            & "$scriptsDir\phantom-activity-healthcheck.ps1"
        }
        9 {
            if (Test-Path $logFile) {
                & notepad.exe $logFile
            } else {
                Write-Host "⚠️  Log file not found" -ForegroundColor Yellow
            }
            Read-Host "Press Enter to continue"
        }
        a {
            Write-Host "⚙️  Opening Settings GUI..." -ForegroundColor Green
            & "$scriptsDir\vscode-cycle-settings.ps1"
            Read-Host "Press Enter to continue"
        }
        t {
            Write-Host "🎯 Starting Legacy System Tray Service..." -ForegroundColor Green
            $wsh = New-Object -ComObject WScript.Shell
            $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptsDir\vscode-cycle-tray.ps1`""
            $wsh.Run($cmd, 0, $false) | Out-Null
            Write-Host "✅ Tray service started (check system tray)" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        v {
            Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║  👁️  VISIBLE MODE - For Manic Time Capture            ║" -ForegroundColor Cyan
            Write-Host "║     All windows visible for screenshot recording      ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
            Write-Host ""
            & "$scriptsDir\vscode-cycle-visible.ps1" -StayOpenSeconds 45
            Read-Host "Press Enter to continue"
        }
        q {
            Write-Host "👋 Goodbye! System ready for 24/7 monitoring." -ForegroundColor Cyan
            exit 0
        }
        default {
            Write-Host "❌ Invalid selection" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
