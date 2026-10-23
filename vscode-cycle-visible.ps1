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
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
}

function Simulate-MouseMovement {
    try {
        $x = [System.Windows.Forms.Cursor]::Position.X
        $y = [System.Windows.Forms.Cursor]::Position.Y
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x + 5, $y + 5)
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    } catch {
        Write-Log "Mouse movement skipped: $_"
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
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log "🚀 VISIBLE PHANTOM ACTIVITY CYCLE STARTED"
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✨ VISIBLE PHANTOM ACTIVITY - For Manic Time Capture    ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

# Phase 1: VS Code (VISIBLE)
Write-Log "PHASE 1: VS Code Development (VISIBLE)"
Write-Host ""
Write-Host "1. Opening VS Code..." -ForegroundColor Yellow
Write-Log "Code.exe path: $codeExe"
Write-Log "Code.exe exists: $(Test-Path $codeExe)"

if (Test-Path $codeExe) {
    try {
        Start-Process -FilePath $codeExe -ArgumentList $projectPath -WindowStyle Normal
        Write-Log "✅ VS Code launched successfully"
        Write-Host "   ✅ VS Code launching..." -ForegroundColor Green
    } catch {
        Write-Log "❌ Error launching VS Code: $_"
        Write-Host "   ❌ Error launching VS Code: $_" -ForegroundColor Red
    }
} else {
    Write-Log "❌ Code.exe not found at $codeExe"
    Write-Host "   ❌ Code.exe not found" -ForegroundColor Red
}

Start-Sleep -Seconds 5

# Phase 2: Planfix (VISIBLE in browser)
Write-Log ""
Write-Log "PHASE 2: Planfix Kanban (VISIBLE)"
Write-Host ""
Write-Host "2. Opening Planfix..." -ForegroundColor Yellow

try {
    Start-Process $planfixUrl
    Write-Log "✅ Planfix opened in browser"
    Write-Host "   ✅ Planfix opening..." -ForegroundColor Green
} catch {
    Write-Log "❌ Error opening Planfix: $_"
    Write-Host "   ❌ Error opening Planfix" -ForegroundColor Red
}

Start-Sleep -Seconds 4

# Note: Planfix tab kept open - farm profiles 1-11 protected
Write-Log "✅ Planfix tab kept open (farm profiles protected)"

# Phase 3: GitLab (VISIBLE in browser)
Write-Log ""
Write-Log "PHASE 3: GitLab Repository (VISIBLE)"
Write-Host ""
Write-Host "3. Opening GitLab..." -ForegroundColor Yellow

try {
    Start-Process $gitlabUrl
    Write-Log "✅ GitLab opened in browser"
    Write-Host "   ✅ GitLab opening..." -ForegroundColor Green
} catch {
    Write-Log "❌ Error opening GitLab: $_"
    Write-Host "   ❌ Error opening GitLab" -ForegroundColor Red
}

Start-Sleep -Seconds 4

# Note: GitLab tab kept open - farm profiles 1-11 protected
Write-Log "✅ GitLab tab kept open (farm profiles protected)"

# Phase 4: Terminal (VISIBLE)
Write-Log ""
Write-Log "PHASE 4: PowerShell Terminal (VISIBLE)"
Write-Host ""
Write-Host "4. Opening Terminal..." -ForegroundColor Yellow

try {
    # Start PowerShell with a command that keeps it open
    $terminalCmd = @"
Set-Location 'C:\Users\ГГГ\Desktop\situation-centre-arm-backend'
Write-Host '✅ Terminal Ready - Active working directory' -ForegroundColor Green
git status
Write-Host 'Ready for commands...' -ForegroundColor Cyan
"@

    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", $terminalCmd -WindowStyle Normal
    Write-Log "✅ Terminal opened successfully"
    Write-Host "   ✅ Terminal launching..." -ForegroundColor Green
} catch {
    Write-Log "❌ Error opening Terminal: $_"
    Write-Host "   ❌ Error opening Terminal" -ForegroundColor Red
}

Start-Sleep -Seconds 5

Write-Log ""
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log "✅ VISIBLE CYCLE COMPLETED SUCCESSFULLY"
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log ""

Write-Host ""
Write-Host "✅ Cycle completed!" -ForegroundColor Green
Write-Host "   All windows are now VISIBLE:" -ForegroundColor Green
Write-Host "   ✓ VS Code" -ForegroundColor Cyan
Write-Host "   ✓ Planfix (Browser)" -ForegroundColor Cyan
Write-Host "   ✓ GitLab (Browser)" -ForegroundColor Cyan
Write-Host "   ✓ Terminal (PowerShell)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Manic Time is now capturing screenshots of all active windows!" -ForegroundColor Yellow
Write-Host ""

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
