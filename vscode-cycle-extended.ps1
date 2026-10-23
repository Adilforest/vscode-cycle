param(
    [int]$StayOpenSeconds = 45
)

Add-Type -AssemblyName System.Windows.Forms

# Focus guard: keys are only ever sent to a window owned by the expected program
$focusGuard = Join-Path $PSScriptRoot "phantom-focus-guard.ps1"
if (Test-Path $focusGuard) { . $focusGuard }

$username = $env:USERNAME
$codeExe = "C:\Users\$username\AppData\Local\Programs\Microsoft VS Code\Code.exe"
$logFile = "C:\Users\$username\Scripts\vscode-cycle.log"
$configFile = "C:\Users\$username\Scripts\vscode-cycle.config.json"

# Project settings
$projectPath = "C:\Users\$username\Desktop\situation-centre-arm-backend"
$fileToOpen = "$projectPath\manage.py"

# URLs for applications
$planfixUrl = "https://robosoft.planfix.com/planner/706"
$gitlabUrl = "https://gitlab.robosoft.kz/robosoft/situation-centre-arm-backend"

# Planfix API settings
$planfixApiUrl = "https://robosoft.planfix.com/rest/"
$planfixToken = "f2ee5c562c5cfb52676f72bad7e8c0af"

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

    try {
        Add-Type -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true)]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);

public const uint KEYEVENTF_KEYUP = 2;
public const uint KEYEVENTF_EXTENDEDKEY = 1;
'@ -Name "KeyboardSimulator" -Namespace "Win32" -ErrorAction Stop

        Write-Log "Starting code editing simulation..."

        $editSequences = @(
            @{
                Description = "Navigate file (Ctrl+Home)"
                Actions = @(@{ Type = "hotkey"; Keys = @(0x11, 0x24) })
                Delay = 200
            },
            @{
                Description = "Scroll down with arrow keys"
                Actions = @(@{ Type = "key"; Value = 0x28 }, @{ Type = "key"; Value = 0x28 })
                Delay = 150
            },
            @{
                Description = "Find in file (Ctrl+F)"
                Actions = @(@{ Type = "hotkey"; Keys = @(0x11, 0x46) })
                Delay = 200
            },
            @{
                Description = "Type search term"
                Actions = @(@{ Type = "text"; Value = "views" })
                Delay = 100
            },
            @{
                Description = "Close find (Escape)"
                Actions = @(@{ Type = "key"; Value = 0x1B })
                Delay = 150
            },
            @{
                Description = "Select all (Ctrl+A)"
                Actions = @(@{ Type = "hotkey"; Keys = @(0x11, 0x41) })
                Delay = 150
            },
            @{
                Description = "Copy (Ctrl+C)"
                Actions = @(@{ Type = "hotkey"; Keys = @(0x11, 0x43) })
                Delay = 150
            },
            @{
                Description = "Go to end of file (Ctrl+End)"
                Actions = @(@{ Type = "hotkey"; Keys = @(0x11, 0x23) })
                Delay = 200
            },
            @{
                Description = "Save file (Ctrl+S)"
                Actions = @(@{ Type = "hotkey"; Keys = @(0x11, 0x53) })
                Delay = 300
            }
        )

        # Keys are only sent while our isolated VS Code owns the foreground window;
        # otherwise they would land in whatever window is active.
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

            Write-Log "  Action: $($sequence.Description)"
            $typedCount++

            foreach ($action in $sequence.Actions) {
                if (-not (Test-ForegroundOwnedBy $TargetProcessIds)) {
                    Write-Log "  Focus left VS Code - remaining keys of this action dropped"
                    break
                }

                switch ($action.Type) {
                    "text" {
                        foreach ($char in $action.Value.ToCharArray()) {
                            if (-not (Test-ForegroundOwnedBy $TargetProcessIds)) { break }
                            [System.Windows.Forms.SendKeys]::SendWait($char)
                            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 100)
                        }
                    }
                    "key" {
                        [Win32.KeyboardSimulator]::keybd_event($action.Value, 0, 0, [IntPtr]::Zero)
                        Start-Sleep -Milliseconds 30
                        [Win32.KeyboardSimulator]::keybd_event($action.Value, 0, 2, [IntPtr]::Zero)
                    }
                    "hotkey" {
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
            Start-Sleep -Milliseconds $sequence.Delay
        }

        if ($typedCount -eq 0) {
            Write-Log "Typing skipped - VS Code was never the foreground window"
        } elseif ($skippedCount -gt 0) {
            Write-Log "Code editing simulation completed ($typedCount actions, $skippedCount skipped while VS Code lacked focus)"
        } else {
            Write-Log "Code editing simulation completed"
        }
    } catch {
        Write-Log "WARNING: Code simulation failed: $_"
    }
}

function Open-Planfix {
    try {
        Write-Log "Opening Planfix (Kanban board)..."
        Start-Process $planfixUrl
        Start-Sleep -Seconds 3

        Write-Log "Simulating Planfix actions..."
        # Scroll the board and jump back. Each key is sent only while a browser tab
        # titled Planfix is in front, so a focus change cannot redirect the rest.
        $done = Send-KeysToBrowser -Keys @("{PGDN}", "{PGDN}", "^{HOME}") -TitleLike @("*planfix*", "*планфикс*")
        if (-not $done) {
            Write-Log "Planfix actions skipped - its browser tab is not in the foreground"
            return
        }

        Write-Log "Planfix phantom actions completed"

        # Close Planfix tab after viewing
        Write-Log "Closing Planfix tab..."
        [System.Windows.Forms.SendKeys]::SendWait("^w")
        Start-Sleep -Milliseconds 500
    } catch {
        Write-Log "WARNING: Planfix simulation failed: $_"
    }
}

function Open-GitLab {
    try {
        Write-Log "Opening GitLab repository..."
        Start-Process $gitlabUrl
        Start-Sleep -Seconds 3

        Write-Log "Simulating GitLab actions (browsing code)..."
        # Scroll through the code, then search for "models" and close the find bar.
        # The close key is {ESC}: "{Escape}" is not a SendKeys keyword and threw.
        $keys = @("{PGDN}", "{PGDN}", "^f") + @("models".ToCharArray() | ForEach-Object { "$_" }) + @("{ESC}")
        $done = Send-KeysToBrowser -Keys $keys -TitleLike @("*gitlab*")
        if (-not $done) {
            Write-Log "GitLab actions skipped - its browser tab is not in the foreground"
            return
        }

        Write-Log "GitLab phantom actions completed"

        # Close GitLab tab after viewing
        Write-Log "Closing GitLab tab..."
        [System.Windows.Forms.SendKeys]::SendWait("^w")
        Start-Sleep -Milliseconds 500
    } catch {
        Write-Log "WARNING: GitLab simulation failed: $_"
    }
}

function Open-Terminal {
    try {
        Write-Log "Opening PowerShell Terminal..."
        $terminalProcess = Start-Process -FilePath "pwsh.exe" -PassThru -NoNewWindow -WindowStyle Normal
        Start-Sleep -Seconds 2

        Write-Log "Simulating Git operations in terminal..."

        # Simulate git commands
        $commands = @(
            "git status",
            "git log --oneline -5",
            "cd apps/building_tracker",
            "ls -la",
            "git branch -a",
            "exit"
        )

        # These lines end in Enter, so sent to the wrong window they would run as
        # commands there. Type only into the terminal this function opened.
        if (-not $terminalProcess -or -not (Request-WindowFocus @($terminalProcess.Id))) {
            Write-Log "Terminal simulation skipped - its window is not in the foreground"
            return
        }

        foreach ($cmd in $commands) {
            if (-not (Test-ForegroundOwnedBy @($terminalProcess.Id))) {
                Write-Log "Terminal lost focus - remaining commands skipped"
                break
            }
            Write-Log "  Terminal: $cmd"
            [System.Windows.Forms.SendKeys]::SendWait($cmd)
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 1500)
        }

        Write-Log "Terminal simulation completed"
    } catch {
        Write-Log "WARNING: Terminal simulation failed: $_"
    }
}

function Get-PlanfixTasks {
    try {
        Write-Log "Fetching Planfix tasks via API..."

        $headers = @{
            "Authorization" = "Bearer $planfixToken"
            "Content-Type" = "application/json"
        }

        # Get tasks list
        $uri = "${planfixApiUrl}api/v3/tasks?limit=10"
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction SilentlyContinue

        if ($response) {
            Write-Log "Retrieved tasks: $($response.Count) items"
        } else {
            Write-Log "WARNING: Could not fetch tasks from Planfix API"
        }
    } catch {
        Write-Log "WARNING: Planfix API call failed: $_"
    }
}

# Load configuration
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
    Write-Log "App disabled - skipping cycle."
    exit 0
}

# Check time constraints
$now = Get-Date
$isActiveDay = $cfg.ActiveDays -contains $now.DayOfWeek.ToString()

$dayStart = $now.Date.AddHours($cfg.ActiveStartHour).AddMinutes($cfg.ActiveStartMinuteMin)
$dayEnd = $now.Date.AddHours($cfg.ActiveEndHour).AddMinutes($cfg.ActiveEndMinuteMax)
if ($cfg.ActiveEndMinuteMax -eq 0) {
    $dayEnd = $now.Date.AddHours($cfg.ActiveEndHour)
}

$lunchStartMin = $now.Date.AddHours($cfg.LunchStartHour).AddMinutes($cfg.LunchStartMinuteMin)
$lunchStartMax = $now.Date.AddHours($cfg.LunchStartHour).AddMinutes($cfg.LunchStartMinuteMax)
$lunchEndMin = $now.Date.AddHours($cfg.LunchEndHour).AddMinutes($cfg.LunchEndMinuteMin)
$lunchEndMax = $now.Date.AddHours($cfg.LunchEndHour).AddMinutes($cfg.LunchEndMinuteMax)

$inLunchBreak = ($now -ge $lunchStartMin -and $now -lt $lunchEndMax)
$beforeWorkStart = ($now -lt $dayStart)
$afterWorkEnd = ($now -ge $dayEnd)

if (-not $isActiveDay -or $beforeWorkStart -or $afterWorkEnd -or $inLunchBreak) {
    Write-Log "Outside working hours - skipping cycle."
    exit 0
}

Write-Log ""
Write-Log "================================================================="
Write-Log " EXTENDED PHANTOM ACTIVITY CYCLE STARTED"
Write-Log "================================================================="
Write-Log ""

# 1. VS Code
Write-Log "PHASE 1: VS Code Development"
Write-Log "Opening isolated VS Code instance with project..."
Start-Process -FilePath $codeExe -ArgumentList @(
    $projectPath,
    $fileToOpen,
    "--user-data-dir", "C:\Users\$username\Scripts\.vscode-cycle-isolated\user-data",
    "--extensions-dir", "C:\Users\$username\Scripts\.vscode-cycle-isolated\extensions"
) -WindowStyle Hidden

# A hidden window can never hold keyboard focus, so the guarded typing below
# sends nothing while VS Code is hidden. Do not switch to Normal without first
# pointing the cycle at a scratch copy: the sequence ends with Ctrl+S on the
# real project file.
$isolatedPids = @()
if (Get-Command Wait-IsolatedCodeWindow -ErrorAction SilentlyContinue) {
    $isolatedPids = Wait-IsolatedCodeWindow -Marker ".vscode-cycle-isolated" -TimeoutSeconds 15
}
if ($isolatedPids.Count -eq 0) {
    Write-Log "VS Code window is hidden - keys are not sent (they would reach another window)"
}
Simulate-CodeTyping -TargetProcessIds $isolatedPids
Start-Sleep -Seconds 3

# 2. Planfix
Write-Log ""
Write-Log "PHASE 2: Planfix Kanban Board"
Open-Planfix
Start-Sleep -Seconds 4
Get-PlanfixTasks
Start-Sleep -Seconds 3

# 3. GitLab
Write-Log ""
Write-Log "PHASE 3: GitLab Repository"
Open-GitLab
Start-Sleep -Seconds 4

# 4. Terminal
Write-Log ""
Write-Log "PHASE 4: Terminal Git Operations"
Open-Terminal
Start-Sleep -Seconds 3

# Cleanup
Write-Log ""
Write-Log "Closing VS Code instance..."
Get-CimInstance Win32_Process -Filter "Name='Code.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*vscode-cycle-isolated*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Write-Log ""
Write-Log "================================================================="
Write-Log " EXTENDED CYCLE COMPLETED SUCCESSFULLY"
Write-Log "================================================================="
Write-Log ""

# Smart cleanup: Only close browser if memory usage is high
Write-Log ""
Write-Log "MEMORY CHECK: Monitoring browser memory usage..."
Write-Log ""

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
