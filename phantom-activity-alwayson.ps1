# Always-On Phantom Activity Mode
# Runs indefinitely with smart intervals and automatic cycle selection

param(
    [int]$QuickCheckMinutes = 5,
    [switch]$UseExtended = $false,
    [switch]$ShowConsole = $false
)

Add-Type -AssemblyName System.Windows.Forms

$username = $env:USERNAME
$scriptsDir = "C:\Users\$username\Scripts"
$configFile = "$scriptsDir\vscode-cycle.config.json"
$logFile = "$scriptsDir\vscode-cycle.log"

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    # The server, the tunnel script and the cycle scripts write to the same file
    for ($i = 0; $i -lt 5; $i++) {
        try {
            Add-Content -Path $logFile -Value $line -ErrorAction Stop
            break
        } catch {
            Start-Sleep -Milliseconds 120
        }
    }
    if ($ShowConsole) {
        Write-Host $line -ForegroundColor $Color
    }
}

function Get-ConfigStamp {
    # Changes whenever the settings file is saved, from any writer
    if (Test-Path $configFile) { return (Get-Item $configFile).LastWriteTimeUtc.Ticks }
    return 0
}

function Get-AppConfig {
    if (Test-Path $configFile) {
        try { return Get-Content -Path $configFile -Raw | ConvertFrom-Json }
        catch { return $null }
    }
    return $null
}

function Is-WorkingHours {
    $cfg = Get-AppConfig
    if (!$cfg) { return $false }

    # Master switch from the dashboard: when the schedule is off, nothing runs.
    # A config without the flag counts as on, as it does for the cycle scripts.
    if (($cfg.PSObject.Properties.Name -contains "Enabled") -and -not $cfg.Enabled) { return $false }

    $now = Get-Date
    $dayOfWeek = $now.DayOfWeek.ToString()

    # Check if active day
    if ($cfg.ActiveDays -notcontains $dayOfWeek) { return $false }

    # Check if holiday
    $todayStr = $now.ToString("yyyy-MM-dd")
    if ($cfg.Holidays -contains $todayStr) { return $false }

    # Check if working hours
    $hour = $now.Hour
    $minute = $now.Minute
    $timeInMinutes = $hour * 60 + $minute

    $startHour = $cfg.ActiveStartHour
    $startMin = $cfg.ActiveStartMinuteMin
    $startTime = $startHour * 60 + $startMin

    # Same rule as the cycle scripts and the dashboard: work ends at
    # ActiveEndHour:ActiveEndMinuteMax, exclusive (a minute of 0 is on the hour).
    # Using a different field here made the loop start cycles that the cycle
    # script then refused as "after work end".
    $endTime = [int]$cfg.ActiveEndHour * 60 + [int]$cfg.ActiveEndMinuteMax

    return ($timeInMinutes -ge $startTime -and $timeInMinutes -lt $endTime)
}

function Is-LunchBreak {
    $cfg = Get-AppConfig
    if (!$cfg) { return $false }

    $now = Get-Date
    $timeInMinutes = $now.Hour * 60 + $now.Minute

    # Lunch starts at the earliest start minute and ends at the latest end
    # minute, so the whole randomised window counts as a break.
    $lunchStart = [int]$cfg.LunchStartHour * 60 + [int]$cfg.LunchStartMinuteMin
    $lunchEnd = [int]$cfg.LunchEndHour * 60 + [int]$cfg.LunchEndMinuteMax

    if ($lunchEnd -le $lunchStart) { return $false }

    return ($timeInMinutes -ge $lunchStart -and $timeInMinutes -lt $lunchEnd)
}

function Run-PhantomCycle {
    try {
        if ($UseExtended) {
            Write-Log "[RUN] Running EXTENDED cycle..." "Green"
            & "$scriptsDir\vscode-cycle-extended.ps1"
        } else {
            Write-Log "[RUN] Running STANDARD cycle..." "Green"
            & "$scriptsDir\vscode-cycle.ps1"
        }
        Write-Log "[OK] Cycle completed successfully" "Green"
        return $true
    } catch {
        Write-Log "[ERROR] Cycle failed: $_" "Red"
        return $false
    }
}

function Get-SmartInterval {
    $now = Get-Date
    $hour = $now.Hour

    # During working hours: a random pause of IntervalMinutes up to twice that
    if (Is-WorkingHours) {
        $base = 5
        $cfg = Get-AppConfig
        if ($cfg -and [int]$cfg.IntervalMinutes -ge 1) { $base = [int]$cfg.IntervalMinutes }
        return (Get-Random -Minimum $base -Maximum ($base * 2))
    }

    # Early morning (5-8 AM): longer interval
    if ($hour -ge 5 -and $hour -lt 8) { return (Get-Random -Minimum 20 -Maximum 40) }

    # Evening (18-21): longer interval
    if ($hour -ge 18 -and $hour -lt 21) { return (Get-Random -Minimum 30 -Maximum 60) }

    # Night: minimal activity
    return 120
}

function Show-Status {
    $cfg = Get-AppConfig
    if (!$cfg) { return }

    $now = Get-Date
    $isWorking = Is-WorkingHours
    $status = if (Is-LunchBreak) { "LUNCH BREAK" } elseif ($isWorking) { "WORKING HOURS" } else { "OFF HOURS" }

    Write-Log "=============================================" "Cyan"
    Write-Log "Status: $status" "Yellow"
    Write-Log "Time: $($now.ToString('HH:mm:ss')) | Day: $($now.DayOfWeek)" "White"
    Write-Log "Mode: $(if($UseExtended) { 'EXTENDED (4 apps)' } else { 'STANDARD (VS Code)' })" "White"
    Write-Log "=============================================" "Cyan"
}

Write-Log "[START] ALWAYS-ON MODE STARTED" "Green"
Show-Status

$cycleCount = 0
$successCount = 0
$startTime = Get-Date

while ($true) {
    $interval = Get-SmartInterval
    $nextRun = (Get-Date).AddMinutes($interval)

    $cycleCount++
    Write-Log "Cycle #$cycleCount | Next run: $($nextRun.ToString('HH:mm')) (waiting $interval min)" "Cyan"

    # Run cycle only when the schedule allows it. Lunch is checked first so
    # VS Code is not launched during the break just to exit again inside the
    # cycle script.
    if (Is-LunchBreak) {
        Write-Log "[SKIP] Skipping cycle - lunch break" "DarkGray"
    } elseif (Is-WorkingHours) {
        $success = Run-PhantomCycle
        if ($success) { $successCount++ }
    } else {
        Write-Log "[SKIP] Skipping cycle - off hours" "DarkGray"
    }

    # Show stats every hour
    if ($cycleCount % 12 -eq 0) {
        $elapsed = (Get-Date) - $startTime
        Write-Log "[STATS] Stats: $successCount successful cycles in $($elapsed.Hours)h $($elapsed.Minutes)m" "Yellow"
    }

    # Sleep in short steps. Off-hours pauses run up to two hours, so one long
    # sleep could start the morning hours late and would ignore a setting saved
    # from the dashboard until it ended. Wake early when the settings file
    # changes or when a working window opens (work starts, lunch ends).
    $wasRunnable = (Is-WorkingHours) -and -not (Is-LunchBreak)
    $configStamp = Get-ConfigStamp
    $wakeAt = (Get-Date).AddMinutes($interval)
    while ((Get-Date) -lt $wakeAt) {
        Start-Sleep -Seconds 30
        if ((Get-ConfigStamp) -ne $configStamp) {
            Write-Log "[CONFIG] Settings changed - re-checking the schedule" "Cyan"
            break
        }
        $isRunnable = (Is-WorkingHours) -and -not (Is-LunchBreak)
        if ($isRunnable -and -not $wasRunnable) {
            Write-Log "Working window opened - starting the next cycle now" "Cyan"
            break
        }
    }
}
