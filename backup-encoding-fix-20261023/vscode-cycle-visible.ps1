param(
    [int]$StayOpenSeconds = 45
)

Add-Type -AssemblyName System.Windows.Forms

$username = $env:USERNAME
$codeExe = "C:\Users\$username\AppData\Local\Programs\Microsoft VS Code\Code.exe"
$logFile = "C:\Users\$username\Scripts\vscode-cycle.log"
$configFile = "C:\Users\$username\Scripts\vscode-cycle.config.json"

# Project settings
$projectPath = "C:\Users\ГГГ\Desktop\situation-centre-arm-backend"
$fileToOpen = "$projectPath\manage.py"

# URLs for applications
$planfixUrl = "https://robosoft.planfix.com/planner/706"
$gitlabUrl = "https://gitlab.robosoft.kz/robosoft/situation-centre-arm-backend"

function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line
}

function Simulate-MouseMovement {
    # Simulates mouse movement to show activity
    $x = [System.Windows.Forms.Cursor]::Position.X
    $y = [System.Windows.Forms.Cursor]::Position.Y

    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x + 5, $y + 5)
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
}

function Simulate-CodeTyping {
    try {
        Add-Type -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true)]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);

public const uint KEYEVENTF_KEYUP = 2;
'@ -Name "KeyboardSimulator" -Namespace "Win32" -ErrorAction Stop

        Write-Log "Starting code editing simulation (VISIBLE)..."

        # Simulate code editing with visible actions
        $actions = @(
            @{ Desc = "Ctrl+Home (beginning)"; Keys = @(0x11, 0x24) },
            @{ Desc = "Page Down"; Keys = @(0x22) },
            @{ Desc = "Ctrl+F (find)"; Keys = @(0x11, 0x46) },
            @{ Desc = "Type: views"; Text = "views" },
            @{ Desc = "Escape"; Keys = @(0x1B) },
            @{ Desc = "Ctrl+End (end)"; Keys = @(0x11, 0x23) },
            @{ Desc = "Ctrl+S (save)"; Keys = @(0x11, 0x53) }
        )

        foreach ($action in $actions) {
            Write-Log "  Action: $($action.Desc)"
            Simulate-MouseMovement

            if ($action.Text) {
                foreach ($char in $action.Text.ToCharArray()) {
                    [System.Windows.Forms.SendKeys]::SendWait($char)
                    Start-Sleep -Milliseconds (Get-Random -Minimum 80 -Maximum 150)
                }
            } else {
                # Handle hotkey
                if ($action.Keys.Count -eq 2) {
                    $mod = $action.Keys[0]
                    $key = $action.Keys[1]
                    [Win32.KeyboardSimulator]::keybd_event($mod, 0, 0, [IntPtr]::Zero)
                    Start-Sleep -Milliseconds 30
                    [Win32.KeyboardSimulator]::keybd_event($key, 0, 0, [IntPtr]::Zero)
                    Start-Sleep -Milliseconds 30
                    [Win32.KeyboardSimulator]::keybd_event($key, 0, 2, [IntPtr]::Zero)
                    Start-Sleep -Milliseconds 30
                    [Win32.KeyboardSimulator]::keybd_event($mod, 0, 2, [IntPtr]::Zero)
                } else {
                    [Win32.KeyboardSimulator]::keybd_event($action.Keys[0], 0, 0, [IntPtr]::Zero)
                    Start-Sleep -Milliseconds 30
                    [Win32.KeyboardSimulator]::keybd_event($action.Keys[0], 0, 2, [IntPtr]::Zero)
                }
            }
            Start-Sleep -Milliseconds (Get-Random -Minimum 300 -Maximum 600)
        }

        Write-Log "Code editing completed"
    } catch {
        Write-Log "WARNING: Code simulation failed: $_"
    }
}

function Open-Planfix-Visible {
    try {
        Write-Log "Opening Planfix (VISIBLE for Manic Time)..."
        Start-Process $planfixUrl
        Start-Sleep -Seconds 4

        Write-Log "Simulating Planfix browsing..."

        # Scroll and navigate visibly
        for ($i = 0; $i -lt 3; $i++) {
            [System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
            Start-Sleep -Milliseconds (Get-Random -Minimum 400 -Maximum 800)
            Simulate-MouseMovement
        }

        [System.Windows.Forms.SendKeys]::SendWait("^{Home}")
        Start-Sleep -Milliseconds 300

        Write-Log "Planfix browsing completed"
    } catch {
        Write-Log "WARNING: Planfix failed: $_"
    }
}

function Open-GitLab-Visible {
    try {
        Write-Log "Opening GitLab (VISIBLE for Manic Time)..."
        Start-Process $gitlabUrl
        Start-Sleep -Seconds 4

        Write-Log "Simulating GitLab code review..."

        # Simulate code browsing
        for ($i = 0; $i -lt 2; $i++) {
            [System.Windows.Forms.SendKeys]::SendWait("{PGDN}")
            Start-Sleep -Milliseconds (Get-Random -Minimum 400 -Maximum 800)
            Simulate-MouseMovement
        }

        # Search in code
        [System.Windows.Forms.SendKeys]::SendWait("^f")
        Start-Sleep -Milliseconds 300

        foreach ($char in "models.py".ToCharArray()) {
            [System.Windows.Forms.SendKeys]::SendWait($char)
            Start-Sleep -Milliseconds (Get-Random -Minimum 60 -Maximum 120)
        }

        Start-Sleep -Milliseconds 500
        [System.Windows.Forms.SendKeys]::SendWait("{Escape}")

        Write-Log "GitLab browsing completed"
    } catch {
        Write-Log "WARNING: GitLab failed: $_"
    }
}

function Open-Terminal-Visible {
    try {
        Write-Log "Opening PowerShell Terminal (VISIBLE)..."

        # Open terminal VISIBLE
        Start-Process -FilePath "pwsh.exe" -ArgumentList "-NoExit" -WindowStyle Normal

        Start-Sleep -Seconds 3

        Write-Log "Simulating Git commands (visible typing)..."

        # Git commands with visible typing
        $commands = @(
            @{ Cmd = "cd situation-centre-arm-backend"; Wait = 1500 },
            @{ Cmd = "git status"; Wait = 2000 },
            @{ Cmd = "git log --oneline -10"; Wait = 2000 },
            @{ Cmd = "cd apps/building_tracker"; Wait = 1500 },
            @{ Cmd = "dir /s"; Wait = 2000 },
            @{ Cmd = "git branch -a"; Wait = 1500 }
        )

        foreach ($item in $commands) {
            Write-Log "  Terminal: $($item.Cmd)"
            Simulate-MouseMovement

            # Type command slowly (visible)
            foreach ($char in $item.Cmd.ToCharArray()) {
                [System.Windows.Forms.SendKeys]::SendWait($char)
                Start-Sleep -Milliseconds (Get-Random -Minimum 30 -Maximum 80)
            }

            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            Start-Sleep -Milliseconds $item.Wait
        }

        Write-Log "Terminal commands completed"
    } catch {
        Write-Log "WARNING: Terminal failed: $_"
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
        Write-Log "WARNING: Failed to read config file, using defaults."
    }
}

# Check if enabled and time constraints
$now = Get-Date
$isActiveDay = $cfg.ActiveDays -contains $now.DayOfWeek.ToString()

if (-not $isActiveDay) {
    Write-Log "Non-active day - skipping cycle."
    exit 0
}

if (-not $cfg.Enabled) {
    Write-Log "App disabled - skipping cycle."
    exit 0
}

Write-Log ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✨ VISIBLE PHANTOM ACTIVITY - For Manic Time Capture    ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log "🚀 VISIBLE PHANTOM ACTIVITY CYCLE STARTED"
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log ""

# Phase 1: VS Code (VISIBLE)
Write-Log "PHASE 1: VS Code Development (VISIBLE)"
Write-Host ""
Write-Host "Opening VS Code with project..." -ForegroundColor Yellow

Start-Process -FilePath $codeExe -ArgumentList @(
    $projectPath,
    $fileToOpen
) -WindowStyle Normal

Start-Sleep -Seconds 4
Simulate-CodeTyping
Start-Sleep -Seconds 3

# Phase 2: Planfix (VISIBLE)
Write-Log ""
Write-Log "PHASE 2: Planfix Kanban (VISIBLE)"
Write-Host ""
Write-Host "Opening Planfix in browser..." -ForegroundColor Yellow

Open-Planfix-Visible
Start-Sleep -Seconds 2

# Phase 3: GitLab (VISIBLE)
Write-Log ""
Write-Log "PHASE 3: GitLab Repository (VISIBLE)"
Write-Host ""
Write-Host "Opening GitLab in browser..." -ForegroundColor Yellow

Open-GitLab-Visible
Start-Sleep -Seconds 2

# Phase 4: Terminal (VISIBLE)
Write-Log ""
Write-Log "PHASE 4: PowerShell Terminal (VISIBLE)"
Write-Host ""
Write-Host "Opening Terminal..." -ForegroundColor Yellow

Open-Terminal-Visible
Start-Sleep -Seconds 2

Write-Log ""
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log "✅ VISIBLE CYCLE COMPLETED SUCCESSFULLY"
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log ""

Write-Host ""
Write-Host "✅ Cycle completed! Manic Time should have captured all windows." -ForegroundColor Green
Write-Host ""
