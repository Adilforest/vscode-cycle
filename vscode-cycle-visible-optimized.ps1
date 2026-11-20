param(
    [int]$CycleDurationSeconds = 120,
    [int]$CloseAfterSeconds = 6
)

# Shared helpers: isolated launchers, owned-item tracking, memory valve, sweep.
Add-Type -AssemblyName System.Windows.Forms
. "$PSScriptRoot\phantom-activity-common.ps1"

$username = $env:USERNAME
$projectPath = "C:\Users\$username\Desktop\situation-centre-arm-backend"
$planfixUrl  = "https://robosoft.planfix.com/planner/706"
$gitlabUrl   = "https://gitlab.robosoft.kz/robosoft/situation-centre-arm-backend"

Write-CycleLog ""
Write-CycleLog "================================================================="
Write-CycleLog "OPTIMIZED VISIBLE CYCLE (isolated profiles) - 10s apps, 2s actions"
Write-CycleLog "================================================================="

# Clear any orphan the previous (possibly crashed) run may have left behind.
Invoke-StartupSweep

$apps = @(
    @{ Name = "VS Code";  Action = { Open-PhantomVsCode $projectPath } },
    @{ Name = "Planfix";  Action = { Open-PhantomUrl $planfixUrl } },
    @{ Name = "GitLab";   Action = { Open-PhantomUrl $gitlabUrl } },
    @{ Name = "Terminal"; Action = { Open-PhantomTerminal } }
)

$startTime = Get-Date
$endTime   = $startTime.AddSeconds($CycleDurationSeconds)
$appIndex  = 0
$lastActionTime = $startTime
$lastAppTime    = $startTime
$aborted = $false

try {
    while ((Get-Date) -lt $endTime) {
        $now = Get-Date

        # Every 2s: a keystroke + mouse nudge so Manic Time counts activity.
        if (($now - $lastActionTime).TotalSeconds -ge 2) {
            Invoke-SimulatedAction
            $lastActionTime = $now
        }

        # Every 10s: open the next app in the rotation.
        if (($now - $lastAppTime).TotalSeconds -ge 10) {
            $app = $apps[$appIndex % $apps.Count]
            Write-CycleLog "Opening: $($app.Name)"
            try { & $app.Action; Write-CycleLog "  OK $($app.Name)" }
            catch { Write-CycleLog "  ERR $($app.Name): $_" }
            $appIndex++
            $lastAppTime = $now
        }

        # A detection miss must never snowball: if too many items are tracked,
        # force-close the lot now instead of waiting for StayOpen to elapse.
        if ($PhantomOwned.Count -gt 8) { Close-Owned 0 }

        # Routine close of items that have been open long enough.
        Close-Owned $CloseAfterSeconds

        # Memory safety valve: below the floor, stop opening anything, tear down
        # and signal the always-on loop to stop as well.
        if (Test-MemoryCritical) {
            Write-CycleLog "[CRITICAL] Low memory ($(Get-MemFreeMB) MB free) - aborting cycle and stopping"
            New-Item -ItemType File -Path $PhantomStopFlag -Force | Out-Null
            $aborted = $true
            break
        }

        Start-Sleep -Milliseconds 500
    }
}
finally {
    # Runs even on error: close exactly what this cycle opened and guarantee the
    # isolated trees are gone so nothing is left occupying memory.
    Invoke-PhantomCleanup
    Write-CycleLog ("VISIBLE CYCLE DONE - cleaned up" + $(if ($aborted) { " (memory abort)" } else { "" }))
    Write-CycleLog ""
}
