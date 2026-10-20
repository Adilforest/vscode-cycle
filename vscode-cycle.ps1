param(
    [int]$StayOpenSeconds
)

$codeExe = "C:\Users\RoboSoft\AppData\Local\Programs\Microsoft VS Code\Code.exe"
$logFile = "C:\Users\RoboSoft\Scripts\vscode-cycle.log"
$configFile = "C:\Users\RoboSoft\Scripts\vscode-cycle.config.json"

function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line
}

# Defaults, used for any setting missing from the config file.
$cfg = [PSCustomObject]@{
    ActiveStartHour  = 8
    ActiveEndHour    = 20
    LunchStartHour   = 13
    LunchStartMinute = 0
    LunchEndHour     = 13
    LunchEndMinute   = 30
    ActiveDays       = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
    StayOpenSeconds  = 45
    Enabled          = $true
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
$currentHour = $now.Hour
$isActiveDay = $cfg.ActiveDays -contains $now.DayOfWeek.ToString()
$lunchStart = $now.Date.AddHours($cfg.LunchStartHour).AddMinutes($cfg.LunchStartMinute)
$lunchEnd = $now.Date.AddHours($cfg.LunchEndHour).AddMinutes($cfg.LunchEndMinute)
$inLunchBreak = ($now -ge $lunchStart -and $now -lt $lunchEnd)

if (-not $isActiveDay -or $currentHour -lt $cfg.ActiveStartHour -or $currentHour -ge $cfg.ActiveEndHour -or $inLunchBreak) {
    # Non-active day, outside active hours, or lunch break: just skip the cycle.
    # Never touch VS Code here - the mining farm runs inside it, so an
    # already-running instance must NOT be closed during these periods.
    $reason = if (-not $isActiveDay) { "non-active day ($($now.DayOfWeek))" } elseif ($inLunchBreak) { "lunch break ($($cfg.LunchStartHour):$($cfg.LunchStartMinute.ToString('00'))-$($cfg.LunchEndHour):$($cfg.LunchEndMinute.ToString('00')))" } else { "outside active hours ($($cfg.ActiveStartHour):00-$($cfg.ActiveEndHour):00)" }
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
$isolatedDir = "C:\Users\RoboSoft\Scripts\.vscode-cycle-isolated"
$isolatedUserData = Join-Path $isolatedDir "user-data"
$isolatedExtensions = Join-Path $isolatedDir "extensions"
$isolatedMarker = ".vscode-cycle-isolated"

Write-Log "Starting isolated VS Code instance (hidden)..."
Start-Process -FilePath $codeExe -ArgumentList @(
    "--new-window",
    "--user-data-dir", $isolatedUserData,
    "--extensions-dir", $isolatedExtensions
) -WindowStyle Hidden

Start-Sleep -Seconds $StayOpenSeconds

Write-Log "Closing isolated VS Code instance..."
Get-CimInstance Win32_Process -Filter "Name='Code.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*$isolatedMarker*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Write-Log "Cycle complete."
