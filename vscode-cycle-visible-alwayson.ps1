# Phantom Activity - VISIBLE Mode Always-On
# Runs continuously in VISIBLE mode (all windows visible for Manic Time)

param(
    [int]$IntervalMinutes = 5
)

$scriptsDir = "C:\Users\√√√\Scripts"
$visibleScript = "$scriptsDir\vscode-cycle-visible.ps1"
$logFile = "$scriptsDir\vscode-cycle.log"
$cycleCount = 0

Write-Host "„============================================================¨" -ForegroundColor Green
Write-Host "¶  ?? PHANTOM ACTIVITY - VISIBLE MODE ALWAYS-ON             ¶" -ForegroundColor Green
Write-Host "¶  All windows visible for Manic Time screenshots           ¶" -ForegroundColor Green
Write-Host "L============================================================-" -ForegroundColor Green
Write-Host ""

# Add to log
Add-Content -Path $logFile -Value "" -ErrorAction SilentlyContinue
Add-Content -Path $logFile -Value "[2026-10-23 15:37:05] ?? VISIBLE MODE ALWAYS-ON STARTED" -ErrorAction SilentlyContinue
Add-Content -Path $logFile -Value "[2026-10-23 15:37:05] Interval: $IntervalMinutes minutes between cycles" -ErrorAction SilentlyContinue

while ($true) {
    $cycleCount++
    $nextRun = (Get-Date).AddMinutes($IntervalMinutes)
    
    Write-Host ""
    Write-Host "??????????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host "CYCLE #$cycleCount | Next: $($nextRun.ToString('HH:mm:ss')) | Interval: $IntervalMinutes min" -ForegroundColor Cyan
    Write-Host "??????????????????????????????????????????????????????????" -ForegroundColor Cyan
    Write-Host ""
    
    # Run VISIBLE cycle
    & $visibleScript
    
    # Wait for next cycle
    Write-Host ""
    Write-Host "? Waiting $IntervalMinutes minutes until next cycle..." -ForegroundColor Yellow
    Write-Host "Next run: $($nextRun.ToString('HH:mm:ss'))" -ForegroundColor Yellow
    Write-Host ""
    
    Start-Sleep -Seconds ($IntervalMinutes * 60)
}
