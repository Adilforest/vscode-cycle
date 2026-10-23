# Phantom Activity - Install Autostart
# Registers scheduled tasks so the web server and the tunnel start at logon.
#
# The web server must run elevated because the HTTP prefix http://+:5000/
# cannot be registered without administrator rights. A scheduled task with
# "highest privileges" does that without a UAC prompt at every logon.
#
# Run this script as administrator.

param(
    [int]$Port = 5000,
    [string]$ApiKey = "cfat_Akd9sK2lP9mX1Qw5rT8yU3vW6zB4cN7d"
)

$username = $env:USERNAME
$scriptsDir = "C:\Users\$username\Scripts"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] Run this script as administrator" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "[SETUP] Phantom Activity - Autostart Installation" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$tasks = @(
    @{
        Name      = "PhantomActivity-WebServer"
        Script    = "$scriptsDir\phantom-activity-webserver-fixed.ps1"
        Arguments = "-Port $Port -ApiKey $ApiKey"
        Delay     = "PT15S"
        Elevated  = $true
        Desc      = "Phantom Activity web server (REST API on port $Port)"
    }
    @{
        Name      = "PhantomActivity-Tunnel"
        Script    = "$scriptsDir\start-quick-tunnel.ps1"
        Arguments = "-Port $Port -ApiKey $ApiKey"
        Delay     = "PT45S"
        Elevated  = $false
        Desc      = "Phantom Activity Cloudflare quick tunnel"
    }
)

foreach ($t in $tasks) {
    Write-Host "[TASK] $($t.Name)" -ForegroundColor Yellow

    if (-not (Test-Path $t.Script)) {
        Write-Host "  [ERROR] Script not found: $($t.Script)" -ForegroundColor Red
        continue
    }

    # Remove an earlier registration so this script can be re-run safely
    $existing = Get-ScheduledTask -TaskName $t.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $t.Name -Confirm:$false
        Write-Host "  [INFO] Removed previous task" -ForegroundColor Gray
    }

    $psArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($t.Script)`" $($t.Arguments)"

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs

    # Delay the start so the network stack and the web server are ready first
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:COMPUTERNAME\$username"
    $trigger.Delay = $t.Delay

    $runLevel = if ($t.Elevated) { "Highest" } else { "Limited" }
    $principal = New-ScheduledTaskPrincipal -UserId "$env:COMPUTERNAME\$username" -LogonType Interactive -RunLevel $runLevel

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -ExecutionTimeLimit (New-TimeSpan -Days 0)

    Register-ScheduledTask -TaskName $t.Name -Action $action -Trigger $trigger `
        -Principal $principal -Settings $settings -Description $t.Desc | Out-Null

    Write-Host "  [OK] Registered (elevated=$($t.Elevated), delay=$($t.Delay))" -ForegroundColor Green
}

Write-Host ""
Write-Host "[OK] Autostart installed" -ForegroundColor Green
Write-Host ""
Write-Host "Tasks will run at every logon:" -ForegroundColor White
Write-Host "  PhantomActivity-WebServer  (after 15 seconds, elevated)" -ForegroundColor Gray
Write-Host "  PhantomActivity-Tunnel     (after 45 seconds)" -ForegroundColor Gray
Write-Host ""
Write-Host "Manage them with:" -ForegroundColor White
Write-Host "  Get-ScheduledTask -TaskName PhantomActivity-*" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName PhantomActivity-WebServer" -ForegroundColor Gray
Write-Host "  Unregister-ScheduledTask -TaskName PhantomActivity-WebServer" -ForegroundColor Gray
Write-Host ""
Write-Host "The remote URL is always written to:" -ForegroundColor White
Write-Host "  $scriptsDir\remote-url.txt" -ForegroundColor Gray
Write-Host ""
