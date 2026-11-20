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

# Shared helpers: isolated teardown, memory valve, startup sweep, stop flag.
. "$PSScriptRoot\phantom-activity-common.ps1"

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

    $timeInMinutes = $now.Hour * 60 + $now.Minute

    $startHour = $cfg.ActiveStartHour
    $startMin = $cfg.ActiveStartMinuteMin
    $startTime = $startHour * 60 + $startMin

    # Same rule as the cycle scripts and the dashboard: work ends at
    # ActiveEndHour:ActiveEndMinuteMax, exclusive (a minute of 0 is on the hour).
    # Using a different field here made the loop start cycles that the cycle
    # script then refused as "after work end".
    $endTime = [int]$cfg.ActiveEndHour * 60 + [int]$cfg.ActiveEndMinuteMax

    # The day whose schedule applies. A window that ends before it starts runs
    # overnight (e.g. 21:00 to 13:58 next day); the part after midnight belongs
    # to the day the window began.
    $anchor = $now
    if ($endTime -gt $startTime) {
        if ($timeInMinutes -lt $startTime -or $timeInMinutes -ge $endTime) { return $false }
    } elseif ($timeInMinutes -ge $startTime) {
        # evening part: today
    } elseif ($timeInMinutes -lt $endTime) {
        $anchor = $now.AddDays(-1)
    } else {
        return $false
    }

    # Check if active day
    if ($cfg.ActiveDays -notcontains $anchor.DayOfWeek.ToString()) { return $false }

    # Check if holiday
    if ($cfg.Holidays -contains $anchor.ToString("yyyy-MM-dd")) { return $false }

    return $true
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
            & "$scriptsDir\vscode-cycle-extended-optimized.ps1"
        } else {
            Write-Log "[RUN] Running STANDARD cycle..." "Green"
            & "$scriptsDir\vscode-cycle-visible-optimized.ps1"
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
    Write-Log "Mode: $(if($UseExtended) { 'EXTENDED (4 apps)' } else { 'STANDARD (4 apps)' })" "White"
    Write-Log "=============================================" "Cyan"
}

Write-Log "[START] ALWAYS-ON MODE STARTED" "Green"

# Clear any leftover from a previous run and a stale stop flag before starting.
Invoke-StartupSweep
Remove-Item $PhantomStopFlag -Force -ErrorAction SilentlyContinue

Show-Status

$cycleCount = 0
$successCount = 0
$startTime = Get-Date

while ($true) {
    # Memory safety valve: if free RAM has fallen below the floor, do not start
    # another cycle. Tear down anything still open and stop the loop entirely so
    # the farm gets its memory back (this is what failed to happen before).
    if (Test-MemoryCritical) {
        Write-Log "[CRITICAL] Low memory ($(Get-MemFreeMB) MB free) - stopping always-on mode to protect the farm" "Red"
        Invoke-PhantomCleanup
        break
    }

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

        # A cycle that hit the memory floor drops this flag; honour it and stop.
        if (Test-Path $PhantomStopFlag) {
            Write-Log "[CRITICAL] Cycle aborted on low memory ($(Get-MemFreeMB) MB free) - stopping always-on mode" "Red"
            Remove-Item $PhantomStopFlag -Force -ErrorAction SilentlyContinue
            Invoke-PhantomCleanup
            break
        }

        # Record free RAM each cycle so the trend is visible in the log; warn as
        # it approaches the floor, before the hard stop has to trigger.
        $free = Get-MemFreeMB
        if ($null -ne $free) {
            $t = Get-MemThresholds
            if ($free -lt $t.WarnFree) {
                Write-Log "[MEM] Free RAM low: $free MB (warn <$($t.WarnFree), stop <$($t.StopFree))" "Yellow"
            }
        }
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
        # Wake immediately if memory has become critical, so the top-of-loop
        # check can stop the loop instead of waiting out the whole interval.
        if (Test-MemoryCritical) { break }
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

# Reached only when the loop stops (currently: the memory safety valve). Make a
# final sweep so nothing the phantom opened is left occupying memory.
Invoke-PhantomCleanup
Write-Log "[STOP] Always-on mode ended - all phantom windows/processes cleaned up" "Yellow"
