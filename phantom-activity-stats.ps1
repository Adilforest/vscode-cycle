# Phantom Activity Statistics Dashboard
# Shows usage statistics, cycle counts, and performance metrics

Add-Type -AssemblyName System.Windows.Forms

$username = $env:USERNAME
$scriptsDir = "C:\Users\$username\Scripts"
$logFile = "$scriptsDir\vscode-cycle.log"

function Parse-Logs {
    if (-not (Test-Path $logFile)) { return $null }

    $logs = @()
    $content = Get-Content -Path $logFile | Select-Object -Last 1000

    foreach ($line in $content) {
        if ($line -match '\[(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2})\]') {
            $logs += @{
                Timestamp = [datetime]::ParseExact(
                    "$($matches[1]) $($matches[2])",
                    "yyyy-MM-dd HH:mm:ss",
                    [System.Globalization.CultureInfo]::InvariantCulture
                )
                Message = $line
            }
        }
    }

    return $logs
}

function Get-Statistics {
    $logs = Parse-Logs
    if (-not $logs) { return $null }

    $stats = @{
        TotalLines = (Get-Content $logFile | Measure-Object -Line).Lines
        LastRun = $logs[-1].Timestamp
        CycleCount = ($logs | Where-Object { $_.Message -like "*CYCLE*" }).Count
        SuccessCount = ($logs | Where-Object { $_.Message -like "*completed*" }).Count
        ErrorCount = ($logs | Where-Object { $_.Message -like "*WARNING*" -or $_.Message -like "*failed*" }).Count
        Today = (Get-Content $logFile | Select-String (Get-Date -Format "yyyy-MM-dd") | Measure-Object).Count
    }

    return $stats
}

function Show-Dashboard {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       📊 PHANTOM ACTIVITY - STATISTICS DASHBOARD           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $stats = Get-Statistics

    if (-not $stats) {
        Write-Host "❌ No log data found. Run some cycles first!" -ForegroundColor Yellow
        return
    }

    # Time period
    $now = Get-Date
    Write-Host "📅 TIME PERIOD" -ForegroundColor Yellow
    Write-Host "  Current: $($now.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host "  Last activity: $($stats.LastRun.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    $timeSinceLastRun = ($now - $stats.LastRun).TotalMinutes
    Write-Host "  Last run: $([math]::Round($timeSinceLastRun, 1)) minutes ago" -ForegroundColor White
    Write-Host ""

    # Today's statistics
    Write-Host "📊 TODAY'S ACTIVITY" -ForegroundColor Yellow
    Write-Host "  Total log entries: $($stats.Today)" -ForegroundColor White
    Write-Host "  Total cycles run: $($stats.CycleCount)" -ForegroundColor Green
    Write-Host "  Successful cycles: $($stats.SuccessCount)" -ForegroundColor Green
    Write-Host "  Errors encountered: $($stats.ErrorCount)" -ForegroundColor $(if ($stats.ErrorCount -gt 0) { "Red" } else { "Green" })

    if ($stats.CycleCount -gt 0) {
        $successRate = [math]::Round(($stats.SuccessCount / $stats.CycleCount) * 100, 1)
        Write-Host "  Success rate: $successRate%" -ForegroundColor $(if ($successRate -ge 95) { "Green" } else { "Yellow" })
    }
    Write-Host ""

    # Performance metrics
    Write-Host "⚡ PERFORMANCE" -ForegroundColor Yellow
    $logSize = (Get-Item $logFile).Length / 1MB
    Write-Host "  Log file size: $([math]::Round($logSize, 2)) MB" -ForegroundColor White
    if ($logSize -gt 50) {
        Write-Host "  ⚠️  Recommend archiving logs (>50MB)" -ForegroundColor Yellow
    }

    $cpuTest = Get-Process | Where-Object { $_.Name -like "*Code*" -or $_.Name -like "*chrome*" -or $_.Name -like "*powershell*" } | Measure-Object -Property CPU -Sum
    if ($cpuTest.Count -gt 0) {
        Write-Host "  Running processes: $($cpuTest.Count)" -ForegroundColor White
    }
    Write-Host ""

    # Recent activity
    Write-Host "🔄 RECENT ACTIVITY (Last 10)" -ForegroundColor Yellow
    $logs = Parse-Logs
    if ($logs) {
        $logs | Select-Object -Last 10 | ForEach-Object {
            $msg = $_.Message -replace ".*\]\s+", ""
            $color = if ($msg -like "*completed*") { "Green" } elseif ($msg -like "*WARNING*") { "Yellow" } else { "White" }
            Write-Host "  $($_.Timestamp.ToString('HH:mm:ss')) - $msg" -ForegroundColor $color
        }
    }
    Write-Host ""

    Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🔄 Press R to refresh, L to view full logs, C to clear, Q to quit" -ForegroundColor Green
    Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# Main loop
while ($true) {
    Show-Dashboard
    $choice = Read-Host "Action"

    switch ($choice.ToUpper()) {
        "R" {
            # Refresh (loop continues)
            continue
        }
        "L" {
            & notepad.exe $logFile
        }
        "C" {
            $confirm = Read-Host "Clear all logs? (y/n)"
            if ($confirm -eq "y") {
                Clear-Content -Path $logFile
                Write-Host "✅ Logs cleared" -ForegroundColor Green
                Start-Sleep -Seconds 2
            }
        }
        "Q" {
            Write-Host "Goodbye!" -ForegroundColor Cyan
            exit 0
        }
        default {
            continue
        }
    }
}
