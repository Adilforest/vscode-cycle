# Health Check System
# Verifies all required components are available before running

Add-Type -AssemblyName System.Windows.Forms

$username = $env:USERNAME
$scriptsDir = "C:\Users\$username\Scripts"
$logFile = "$scriptsDir\vscode-cycle.log"

function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line
}

function Check-Component {
    param(
        [string]$Name,
        [string]$Path = "",
        [string]$Process = "",
        [scriptblock]$CustomCheck = $null
    )

    if ($CustomCheck) {
        $result = & $CustomCheck
        if ($result) {
            Write-Host "  ✅ $Name" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ❌ $Name" -ForegroundColor Red
            return $false
        }
    }

    if ($Path) {
        if (Test-Path $Path) {
            Write-Host "  ✅ $Name" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ❌ $Name (not found: $Path)" -ForegroundColor Red
            return $false
        }
    }

    if ($Process) {
        if (Get-Command $Process -ErrorAction SilentlyContinue) {
            Write-Host "  ✅ $Name" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ❌ $Name (not found)" -ForegroundColor Red
            return $false
        }
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         🔍 PHANTOM ACTIVITY - SYSTEM HEALTH CHECK          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$results = @()

# Check core components
Write-Host "📋 CORE COMPONENTS:" -ForegroundColor Yellow
$results += Check-Component "PowerShell 5.0+" -CustomCheck { $PSVersionTable.PSVersion.Major -ge 5 }
$results += Check-Component "Windows Forms" -CustomCheck { [System.Windows.Forms.Cursor] -ne $null }
$results += Check-Component "Config file" -Path "$scriptsDir\vscode-cycle.config.json"
$results += Check-Component "Log file writable" -CustomCheck {
    try {
        Add-Content -Path $logFile -Value "health_check_$(Get-Date -Format 'HH:mm:ss')"
        $true
    } catch {
        $false
    }
}

# Check applications
Write-Host ""
Write-Host "🚀 REQUIRED APPLICATIONS:" -ForegroundColor Yellow
$vscodePath = "C:\Users\$username\AppData\Local\Programs\Microsoft VS Code\Code.exe"
$results += Check-Component "VS Code" -Path $vscodePath
$results += Check-Component "PowerShell" -Process "pwsh"
$results += Check-Component "Browser (Chrome/Edge)" -CustomCheck {
    (Get-Command chrome -ErrorAction SilentlyContinue) -or
    (Get-Command msedge -ErrorAction SilentlyContinue) -or
    (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") -or
    (Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe")
}

# Check network
Write-Host ""
Write-Host "🌐 NETWORK CONNECTIVITY:" -ForegroundColor Yellow
$results += Check-Component "Internet connectivity" -CustomCheck {
    try {
        $null = [System.Net.Http.HttpClient]::new().GetAsync("https://google.com").Result
        $true
    } catch {
        $false
    }
}
$results += Check-Component "Planfix API" -CustomCheck {
    try {
        $url = "https://robosoft.planfix.com/rest/api/v3/tasks"
        $headers = @{ "Authorization" = "Bearer f2ee5c562c5cfb52676f72bad7e8c0af" }
        $response = Invoke-WebRequest -Uri $url -Headers $headers -TimeoutSec 5 -ErrorAction Stop
        $response.StatusCode -eq 200
    } catch {
        $false
    }
}
$results += Check-Component "GitLab accessibility" -CustomCheck {
    try {
        $response = Invoke-WebRequest -Uri "https://gitlab.robosoft.kz" -TimeoutSec 5 -ErrorAction Stop
        $response.StatusCode -eq 200
    } catch {
        $false
    }
}

# Check disk space
Write-Host ""
Write-Host "💾 DISK SPACE:" -ForegroundColor Yellow
$drive = Get-PSDrive $scriptsDir[0]
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$results += Check-Component "Free disk space (>1GB)" -CustomCheck { $drive.Free -gt 1GB }
Write-Host "  📊 Free: $freeGB GB" -ForegroundColor White

# Summary
Write-Host ""
$passed = ($results | Where-Object { $_ -eq $true }).Count
$total = $results.Count
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($passed -eq $total) {
    Write-Host "✅ ALL CHECKS PASSED ($passed/$total)" -ForegroundColor Green
    Write-Host "System is ready for Phantom Activity!" -ForegroundColor Green
    Write-Log "Health Check: PASSED ($passed/$total components)"
} else {
    Write-Host "⚠️  SOME CHECKS FAILED ($passed/$total)" -ForegroundColor Yellow
    Write-Host "Fix the issues above before running Phantom Activity." -ForegroundColor Yellow
    Write-Log "Health Check: FAILED ($passed/$total components) - Review issues above"
}

Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
