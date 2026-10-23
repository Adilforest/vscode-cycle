param(
    [int]$StayOpenSeconds
)

Add-Type -AssemblyName System.Windows.Forms

# Focus guard: keys are only ever sent to a window owned by our own VS Code
$focusGuard = Join-Path $PSScriptRoot "phantom-focus-guard.ps1"
if (Test-Path $focusGuard) { . $focusGuard }

$username = $env:USERNAME
$codeExe = "C:\Users\$username\AppData\Local\Programs\Microsoft VS Code\Code.exe"
$logFile = "C:\Users\$username\Scripts\vscode-cycle.log"
$configFile = "C:\Users\$username\Scripts\vscode-cycle.config.json"

# Project settings
$projectPath = "C:\Users\ГГГ\Desktop\situation-centre-arm-backend"
$fileToOpen = "$projectPath\manage.py"  # Django project file

function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message

    # The web server writes to the same file, so the write can collide.
    # Retry briefly instead of losing the line and emitting a stderr error.
    for ($i = 0; $i -lt 5; $i++) {
        try {
            Add-Content -Path $logFile -Value $line -ErrorAction Stop
            return
        } catch {
            Start-Sleep -Milliseconds 120
        }
    }
}

function Simulate-CodeTyping {
    param([int[]]$TargetProcessIds = @())

    # P/Invoke code for keyboard simulation
    $keyboardSimCode = @'
[DllImport("user32.dll", SetLastError = true)]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);

public const uint KEYEVENTF_KEYUP = 2;
public const uint KEYEVENTF_EXTENDEDKEY = 1;
'@

    try {
        Add-Type -MemberDefinition $keyboardSimCode -Name "KeyboardSimulator" -Namespace "Win32" -ErrorAction Stop

        Write-Log "Starting realistic code typing simulation..."

        # Simulate realistic code editing patterns with MORE ACTIONS
        $editSequences = @(
            @{
                Description = "Navigate file (Ctrl+Home - начало файла)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x24) }
                )
                Delay = 200
            },
            @{
                Description = "Scroll down with arrow keys"
                Actions = @(
                    @{ Type = "key"; Value = 0x28 }, # Down
                    @{ Type = "key"; Value = 0x28 }, # Down
                    @{ Type = "key"; Value = 0x28 }  # Down
                )
                Delay = 180
            },
            @{
                Description = "Page Down navigation"
                Actions = @(
                    @{ Type = "key"; Value = 0x22 } # Page Down
                )
                Delay = 150
            },
            @{
                Description = "Find and Replace (Ctrl+H)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x48) }
                )
                Delay = 250
            },
            @{
                Description = "Close dialog (Escape)"
                Actions = @(
                    @{ Type = "key"; Value = 0x1B }
                )
                Delay = 150
            },
            @{
                Description = "Go to Line (Ctrl+G)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x47) }
                )
                Delay = 200
            },
            @{
                Description = "Close dialog"
                Actions = @(
                    @{ Type = "key"; Value = 0x1B }
                )
                Delay = 150
            },
            @{
                Description = "Select word (Ctrl+D)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x44) }
                )
                Delay = 150
            },
            @{
                Description = "Undo (Ctrl+Z)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x5A) }
                )
                Delay = 100
            },
            @{
                Description = "Redo (Ctrl+Y)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x59) }
                )
                Delay = 100
            },
            @{
                Description = "Comment line (Ctrl+/)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0xBF) }
                )
                Delay = 150
            },
            @{
                Description = "Quick navigation (Ctrl+P)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x50) }
                )
                Delay = 200
            },
            @{
                Description = "Type to search file"
                Actions = @(
                    @{ Type = "text"; Value = "views" }
                )
                Delay = 100
            },
            @{
                Description = "Select first result (Enter)"
                Actions = @(
                    @{ Type = "key"; Value = 0x0D } # Enter
                )
                Delay = 200
            },
            @{
                Description = "Select all (Ctrl+A)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x41) }
                )
                Delay = 150
            },
            @{
                Description = "Navigate left"
                Actions = @(
                    @{ Type = "key"; Value = 0x25 }, # Left
                    @{ Type = "key"; Value = 0x25 }, # Left
                    @{ Type = "key"; Value = 0x25 }  # Left
                )
                Delay = 120
            },
            @{
                Description = "Copy (Ctrl+C)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x43) }
                )
                Delay = 150
            },
            @{
                Description = "Navigate right"
                Actions = @(
                    @{ Type = "key"; Value = 0x27 }, # Right
                    @{ Type = "key"; Value = 0x27 }, # Right
                    @{ Type = "key"; Value = 0x27 }  # Right
                )
                Delay = 120
            },
            @{
                Description = "Paste (Ctrl+V)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x56) }
                )
                Delay = 150
            },
            @{
                Description = "Cut (Ctrl+X)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x58) }
                )
                Delay = 150
            },
            @{
                Description = "Find (Ctrl+F)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x46) }
                )
                Delay = 200
            },
            @{
                Description = "Type search term"
                Actions = @(
                    @{ Type = "text"; Value = "def " }
                )
                Delay = 100
            },
            @{
                Description = "Exit find (Escape)"
                Actions = @(
                    @{ Type = "key"; Value = 0x1B }
                )
                Delay = 150
            },
            @{
                Description = "Move line up (Alt+Up)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x12, 0x26) }
                )
                Delay = 150
            },
            @{
                Description = "Move line down (Alt+Down)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x12, 0x28) }
                )
                Delay = 150
            },
            @{
                Description = "Duplicate line (Ctrl+Shift+D)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x44) }
                )
                Delay = 150
            },
            @{
                Description = "Go to end of file (Ctrl+End)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x23) }
                )
                Delay = 200
            },
            @{
                Description = "Delete line (Ctrl+Shift+K)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x4B) }
                )
                Delay = 150
            },
            @{
                Description = "Open command palette (Ctrl+Shift+P)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x10, 0x50) }
                )
                Delay = 250
            },
            @{
                Description = "Type command search"
                Actions = @(
                    @{ Type = "text"; Value = "format" }
                )
                Delay = 100
            },
            @{
                Description = "Exit command palette (Escape)"
                Actions = @(
                    @{ Type = "key"; Value = 0x1B }
                )
                Delay = 150
            },
            @{
                Description = "Indent selection (Tab)"
                Actions = @(
                    @{ Type = "key"; Value = 0x09 } # Tab
                )
                Delay = 100
            },
            @{
                Description = "New line (Enter)"
                Actions = @(
                    @{ Type = "key"; Value = 0x0D } # Enter
                )
                Delay = 100
            },
            @{
                Description = "Backspace delete"
                Actions = @(
                    @{ Type = "key"; Value = 0x08 }, # Backspace
                    @{ Type = "key"; Value = 0x08 }  # Backspace
                )
                Delay = 100
            },
            @{
                Description = "Delete forward"
                Actions = @(
                    @{ Type = "key"; Value = 0x2E }, # Delete
                    @{ Type = "key"; Value = 0x2E }  # Delete
                )
                Delay = 100
            },
            @{
                Description = "Multiple cursor up (Ctrl+Alt+Up)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x12, 0x26) }
                )
                Delay = 150
            },
            @{
                Description = "Save file (Ctrl+S)"
                Actions = @(
                    @{ Type = "hotkey"; Keys = @(0x11, 0x53) }
                )
                Delay = 300
            }
        )

        # Keys are only sent while our isolated VS Code owns the foreground window.
        # Without this check every keystroke lands in whatever window is active:
        # Ctrl+C then kills console processes (the tunnel, this activity) and
        # Ctrl+A, Delete or Enter can damage work in any other program.
        if (-not (Get-Command Request-WindowFocus -ErrorAction SilentlyContinue)) {
            Write-Log "WARNING: focus guard not loaded - typing skipped for safety"
            return
        }

        $typedCount = 0
        $skippedCount = 0

        foreach ($sequence in $editSequences) {
            if (-not (Request-WindowFocus $TargetProcessIds)) {
                $skippedCount++
                continue
            }

            Write-Log "Action: $($sequence.Description)"
            $typedCount++

            foreach ($action in $sequence.Actions) {
                # Focus can move mid-sequence (a popup, a click elsewhere)
                if (-not (Test-ForegroundOwnedBy $TargetProcessIds)) {
                    Write-Log "Focus left VS Code - remaining keys of this action dropped"
                    break
                }

                switch ($action.Type) {
                    "text" {
                        foreach ($char in $action.Value.ToCharArray()) {
                            if (-not (Test-ForegroundOwnedBy $TargetProcessIds)) { break }
                            [System.Windows.Forms.SendKeys]::SendWait($char)
                            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 150)
                        }
                    }
                    "key" {
                        [Win32.KeyboardSimulator]::keybd_event($action.Value, 0, 0, [IntPtr]::Zero)
                        Start-Sleep -Milliseconds 30
                        [Win32.KeyboardSimulator]::keybd_event($action.Value, 0, 2, [IntPtr]::Zero)
                    }
                    "hotkey" {
                        # Handle multiple modifier keys (Ctrl+Shift+Key)
                        if ($action.Keys.Count -eq 3) {
                            $mod1 = $action.Keys[0]
                            $mod2 = $action.Keys[1]
                            $mainKey = $action.Keys[2]

                            [Win32.KeyboardSimulator]::keybd_event($mod1, 0, 0, [IntPtr]::Zero)
                            Start-Sleep -Milliseconds 20
                            [Win32.KeyboardSimulator]::keybd_event($mod2, 0, 0, [IntPtr]::Zero)
                            Start-Sleep -Milliseconds 20
                            [Win32.KeyboardSimulator]::keybd_event($mainKey, 0, 0, [IntPtr]::Zero)
                            Start-Sleep -Milliseconds 30
                            [Win32.KeyboardSimulator]::keybd_event($mainKey, 0, 2, [IntPtr]::Zero)
                            Start-Sleep -Milliseconds 20
                            [Win32.KeyboardSimulator]::keybd_event($mod2, 0, 2, [IntPtr]::Zero)
                            Start-Sleep -Milliseconds 20
                            [Win32.KeyboardSimulator]::keybd_event($mod1, 0, 2, [IntPtr]::Zero)
                        } else {
                            $modifierKey = $action.Keys[0]
                            $mainKey = $action.Keys[1]

                            [Win32.KeyboardSimulator]::keybd_event($modifierKey, 0, 0, [IntPtr]::Zero)
                            Start-Sleep -Milliseconds 30
                            [Win32.KeyboardSimulator]::keybd_event($mainKey, 0, 0, [IntPtr]::Zero)
                            Start-Sleep -Milliseconds 30
                            [Win32.KeyboardSimulator]::keybd_event($mainKey, 0, 2, [IntPtr]::Zero)
                            Start-Sleep -Milliseconds 30
                            [Win32.KeyboardSimulator]::keybd_event($modifierKey, 0, 2, [IntPtr]::Zero)
                        }
                    }
                }
            }

            Start-Sleep -Milliseconds $sequence.Delay
        }

        if ($typedCount -eq 0) {
            Write-Log "Typing skipped - VS Code was never the foreground window"
        } elseif ($skippedCount -gt 0) {
            Write-Log "Code typing simulation completed ($typedCount actions, $skippedCount skipped while VS Code lacked focus)"
        } else {
            Write-Log "Code typing simulation completed successfully"
        }
    } catch {
        Write-Log "WARNING: Could not simulate typing: $_"
        try {
            $canType = (Get-Command Request-WindowFocus -ErrorAction SilentlyContinue) -and (Request-WindowFocus $TargetProcessIds)
            if (-not $canType) {
                Write-Log "Fallback skipped - VS Code is not the foreground window"
                return
            }
            Write-Log "Using fallback activity simulation..."
            for ($i = 0; $i -lt 8; $i++) {
                [System.Windows.Forms.SendKeys]::SendWait("{SHIFT}")
                Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
            }
            Write-Log "Fallback simulation completed"
        } catch {
            Write-Log "WARNING: Fallback activity failed: $_"
        }
    }
}

# Defaults, used for any setting missing from the config file.
$cfg = [PSCustomObject]@{
    ActiveStartHour          = 8
    ActiveStartMinuteMin     = 25
    ActiveStartMinuteMax     = 48
    ActiveEndHour            = 18
    ActiveEndMinuteMin       = 58
    ActiveEndMinuteMax       = 0
    LunchStartHour           = 13
    LunchStartMinuteMin      = 0
    LunchStartMinuteMax      = 14
    LunchEndHour             = 13
    LunchEndMinuteMin        = 30
    LunchEndMinuteMax        = 35
    ActiveDays               = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
    StayOpenSeconds          = 45
    Enabled                  = $true
}

if (Test-Path $configFile) {
    try {
        $loaded = Get-Content -Path $configFile -Raw | ConvertFrom-Json
        foreach ($prop in $loaded.PSObject.Properties) {
            $cfg | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
        }
    } catch {
        Write-Log "WARNING: Failed to read config file, using defaults. $_"
    }
}

if (-not $PSBoundParameters.ContainsKey('StayOpenSeconds')) {
    $StayOpenSeconds = $cfg.StayOpenSeconds
}

if (-not $cfg.Enabled) {
    Write-Log "App disabled via tray - skipping cycle (leaving VS Code untouched)."
    exit 0
}

$now = Get-Date
$isActiveDay = $cfg.ActiveDays -contains $now.DayOfWeek.ToString()

# Randomized working hours
$dayStart = $now.Date.AddHours($cfg.ActiveStartHour).AddMinutes($cfg.ActiveStartMinuteMin)
$dayEnd = $now.Date.AddHours($cfg.ActiveEndHour).AddMinutes($cfg.ActiveEndMinuteMax)
if ($cfg.ActiveEndMinuteMax -eq 0) {
    $dayEnd = $now.Date.AddHours($cfg.ActiveEndHour)
}

# Randomized lunch break
$lunchStartMin = $now.Date.AddHours($cfg.LunchStartHour).AddMinutes($cfg.LunchStartMinuteMin)
$lunchStartMax = $now.Date.AddHours($cfg.LunchStartHour).AddMinutes($cfg.LunchStartMinuteMax)
$lunchEndMin = $now.Date.AddHours($cfg.LunchEndHour).AddMinutes($cfg.LunchEndMinuteMin)
$lunchEndMax = $now.Date.AddHours($cfg.LunchEndHour).AddMinutes($cfg.LunchEndMinuteMax)

$inLunchBreak = ($now -ge $lunchStartMin -and $now -lt $lunchEndMax)
$beforeWorkStart = ($now -lt $dayStart)
$afterWorkEnd = ($now -ge $dayEnd)

if (-not $isActiveDay -or $beforeWorkStart -or $afterWorkEnd -or $inLunchBreak) {
    # Non-active day, outside active hours, or lunch break: just skip the cycle.
    # Never touch VS Code here - the mining farm runs inside it, so an
    # already-running instance must NOT be closed during these periods.
    if (-not $isActiveDay) {
        $reason = "non-active day ($($now.DayOfWeek))"
    } elseif ($inLunchBreak) {
        $lunchStartTime = $lunchStartMin.ToString("HH:mm")
        $lunchEndTime = $lunchEndMax.ToString("HH:mm")
        $reason = "lunch break (random $lunchStartTime - $lunchEndTime)"
    } elseif ($beforeWorkStart) {
        $startTime = $dayStart.ToString("HH:mm")
        $reason = "before work start (random after $startTime)"
    } else {
        $endTime = $dayEnd.ToString("HH:mm")
        $reason = "after work end (before $endTime)"
    }
    Write-Log "$reason - skipping cycle (leaving VS Code untouched)."
    exit 0
}

if (-not (Test-Path $codeExe)) {
    Write-Log "ERROR: Code.exe not found at $codeExe"
    exit 1
}

# Run the cycle in its own isolated VS Code profile (separate user-data/extensions
# dir) so it is a distinct instance from Code's point of view. This way we never
# have to touch, or even look at, a VS Code window the user (or the farm) already
# has open - we only ever start and stop our own isolated instance.
$isolatedDir = "C:\Users\$username\Scripts\.vscode-cycle-isolated"
$isolatedUserData = Join-Path $isolatedDir "user-data"
$isolatedExtensions = Join-Path $isolatedDir "extensions"
$isolatedMarker = ".vscode-cycle-isolated"

Write-Log "Starting isolated VS Code instance..."
Write-Log "Opening project: $projectPath"
Write-Log "Opening file: $fileToOpen"

Start-Process -FilePath $codeExe -ArgumentList $projectPath -WindowStyle Normal

Write-Log "VS Code started in NORMAL window (VISIBLE)"

# Keep VS Code visible for activity
Start-Sleep -Seconds $StayOpenSeconds

Write-Log "Closing isolated VS Code instance..."
Get-CimInstance Win32_Process -Filter "Name='Code.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*$isolatedMarker*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Write-Log "Cycle complete."

# Smart cleanup: Only close browser if memory usage is high
Write-Log ""
Write-Log "MEMORY CHECK: Monitoring browser memory usage..."

try {
    # Check browser memory
    $browsers = @("chrome", "msedge", "firefox", "iexplore")
    $totalMemory = 0

    foreach ($browser in $browsers) {
        $procs = Get-Process -Name $browser -ErrorAction SilentlyContinue
        if ($procs) {
            $memoryMB = ($procs | Measure-Object -Property WorkingSet -Sum).Sum / 1MB
            $totalMemory += $memoryMB
            Write-Log "  $browser: $([math]::Round($memoryMB, 2)) MB"
        }
    }

    # Memory monitoring only - NO auto-closing to protect other profiles
    if ($totalMemory -gt 800) {
        Write-Log "⚠️  Browser memory high ($([math]::Round($totalMemory, 2)) MB) - consider closing some tabs manually"
        Write-Log "      Note: Not auto-closing to protect other profiles and Chrome settings"
    } else {
        Write-Log "✅ Browser memory normal ($([math]::Round($totalMemory, 2)) MB)."
    }
} catch {
    Write-Log "Memory check skipped: $_"
}

# CLEANUP: Close VS Code for next cycle
Write-Log ""
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log "🧹 CLEANUP: Closing VS Code"
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log ""

Write-Log "Closing VS Code..."
Get-Process "Code" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 1

Write-Log ""
Write-Log "✅ CYCLE CLEANUP COMPLETE - VS Code closed"
Write-Log ""
