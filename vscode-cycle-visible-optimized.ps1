param(
    [int]$CycleDurationSeconds = 120
)

Add-Type -AssemblyName System.Windows.Forms

$username = $env:USERNAME
$codeExe = "C:\Users\$username\AppData\Local\Programs\Microsoft VS Code\Code.exe"
$logFile = "C:\Users\$username\Scripts\vscode-cycle.log"

$projectPath = "C:\Users\ГГГ\Desktop\situation-centre-arm-backend"
$planfixUrl = "https://robosoft.planfix.com/planner/706"
$gitlabUrl = "https://gitlab.robosoft.kz/robosoft/situation-centre-arm-backend"

function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
}

function Simulate-Action {
    try {
        # Random mouse movement
        $x = [System.Windows.Forms.Cursor]::Position.X
        $y = [System.Windows.Forms.Cursor]::Position.Y
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x + 3, $y + 3)
        Start-Sleep -Milliseconds 50
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)

        # Random key press
        [System.Windows.Forms.SendKeys]::SendWait("{F5}")
        Start-Sleep -Milliseconds 100
    } catch {
        Write-Log "Action skipped: $_"
    }
}

Write-Log ""
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log "🚀 OPTIMIZED VISIBLE CYCLE - 10s apps, 5s actions, 2min cleanup"
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log ""

$startTime = Get-Date
$endTime = $startTime.AddSeconds($CycleDurationSeconds)
$lastAppOpen = $null
$appIndex = 0
$apps = @(
    @{ Name = "VS Code"; Action = { Start-Process -FilePath $codeExe -ArgumentList $projectPath -WindowStyle Normal } },
    @{ Name = "Planfix"; Action = { Start-Process $planfixUrl } },
    @{ Name = "GitLab"; Action = { Start-Process $gitlabUrl } },
    @{ Name = "Terminal"; Action = { Start-Process "powershell.exe" -ArgumentList "-NoExit" -WindowStyle Normal } }
)

$lastActionTime = $startTime
$lastAppTime = $startTime

while ((Get-Date) -lt $endTime) {
    $now = Get-Date

    # Every 2-3 seconds: perform action (more frequent for Manic Time)
    if (($now - $lastActionTime).TotalSeconds -ge 2) {
        Write-Log "  Action: key press + mouse move"
        Simulate-Action
        $lastActionTime = $now
    }

    # Every 10 seconds: open next app
    if (($now - $lastAppTime).TotalSeconds -ge 10) {
        $app = $apps[$appIndex % $apps.Count]
        Write-Log "Opening: $($app.Name)"
        try {
            & $app.Action
            Write-Log "  ✅ $($app.Name) opened"
        } catch {
            Write-Log "  ❌ Error: $_"
        }
        $appIndex++
        $lastAppTime = $now
    }

    Start-Sleep -Milliseconds 500
}

# After 2 minutes: Close ALL applications
Write-Log ""
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log "🧹 CLEANUP: Closing all 4 applications after 2 minutes"
Write-Log "═════════════════════════════════════════════════════════════════"
Write-Log ""

# Close VS Code
Write-Log "Closing VS Code..."
Get-Process "Code" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Close Chrome/Edge
Write-Log "Closing browser (Planfix/GitLab)..."
Get-Process "chrome" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Close Terminal (PowerShell instances except current)
Write-Log "Closing Terminal..."
Get-Process "powershell" -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID } | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 1

Write-Log ""
Write-Log "✅ VISIBLE CYCLE COMPLETED - All applications closed"
Write-Log "Memory freed: All windows, tabs, and processes"
Write-Log ""
