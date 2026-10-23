# Phantom Activity Web Server
# Provides REST API for remote management via HTTP/HTTPS
# Designed to work with Cloudflare Tunnel for secure access

param(
    [int]$Port = 5000,
    [string]$ApiKey = "phantom-secret-key-change-me"
)

Add-Type -AssemblyName System.Net.Sockets
Add-Type -AssemblyName System.Net.Http

$username = $env:USERNAME
$scriptsDir = "C:\Users\$username\Scripts"
$configFile = "$scriptsDir\vscode-cycle.config.json"
$logFile = "$scriptsDir\vscode-cycle.log"
$statusFile = "$scriptsDir\phantom-activity-status.json"

# Initialize status file
$statusObject = @{
    Status = "stopped"
    Mode = "none"
    ProcessId = $null
    StartTime = $null
    LastUpdate = (Get-Date -Format "o")
    CycleCount = 0
}

function Save-Status {
    $statusObject.LastUpdate = (Get-Date -Format "o")
    $statusObject | ConvertTo-Json | Set-Content -Path $statusFile
}

function Load-Status {
    if (Test-Path $statusFile) {
        try { return Get-Content -Path $statusFile | ConvertFrom-Json }
        catch { return $statusObject }
    }
    return $statusObject
}

function Start-Activity {
    param(
        [string]$Mode = "standard",
        [bool]$Visible = $false
    )

    try {
        Write-Log "[START] Starting activity: Mode=$Mode, Visible=$Visible"

        $psArgs = @(
            "-NoProfile"
            "-ExecutionPolicy", "Bypass"
            "-File", "`"$scriptsDir\phantom-activity-alwayson.ps1`""
        )

        if ($Mode -eq "extended") {
            $psArgs += "-UseExtended", "`$true"
        } else {
            $psArgs += "-UseExtended", "`$false"
        }

        if ($Visible) {
            $psArgs += "-ShowConsole", "`$true"
        }

        # Start process
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -PassThru -WindowStyle Minimized

        $script:statusObject.Status = "running"
        $script:statusObject.Mode = $Mode
        $script:statusObject.ProcessId = $process.Id
        $script:statusObject.StartTime = (Get-Date -Format "o")
        Save-Status

        return @{ Success = $true; ProcessId = $process.Id }
    } catch {
        Write-Log "ERROR: Failed to start activity: $_"
        return @{ Success = $false; Error = $_.Message }
    }
}

function Stop-Activity {
    try {
        if ($script:statusObject.ProcessId) {
            Stop-Process -Id $script:statusObject.ProcessId -Force -ErrorAction SilentlyContinue
            Write-Log "Stopped activity (PID: $($script:statusObject.ProcessId))"
        }

        $script:statusObject.Status = "stopped"
        $script:statusObject.Mode = "none"
        $script:statusObject.ProcessId = $null
        Save-Status

        return @{ Success = $true }
    } catch {
        Write-Log "ERROR: Failed to stop activity: $_"
        return @{ Success = $false; Error = $_.Message }
    }
}

function Get-ActivityStatus {
    $status = Load-Status

    # Check if process still running
    if ($status.ProcessId) {
        try {
            $proc = Get-Process -Id $status.ProcessId -ErrorAction Stop
            $uptime = (Get-Date) - [datetime]::Parse($status.StartTime)
            $status.Uptime = "$($uptime.Hours)h $($uptime.Minutes)m"
        } catch {
            $status.Status = "stopped"
            $status.ProcessId = $null
        }
    }

    return $status
}

function Get-RecentLogs {
    param([int]$Lines = 20)

    if (-not (Test-Path $logFile)) { return @() }

    $logs = @()
    Get-Content -Path $logFile | Select-Object -Last $Lines | ForEach-Object {
        if ($_ -match '\[(.+?)\]\s+(.+)') {
            $logs += @{
                Time = $matches[1]
                Message = $matches[2]
            }
        }
    }
    return $logs
}

function Write-Log {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Add-Content -Path $logFile -Value $line
    Write-Host $line -ForegroundColor Cyan
}

function Invoke-HttpResponse {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [object]$Data = $null,
        [int]$StatusCode = 200,
        [string]$ContentType = "application/json"
    )

    $Response.StatusCode = $StatusCode
    $Response.ContentType = $ContentType

    if ($Data) {
        $json = $Data | ConvertTo-Json -Depth 10
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
        $Response.ContentLength64 = $buffer.Length
        $Response.OutputStream.Write($buffer, 0, $buffer.Length)
    }

    $Response.OutputStream.Close()
}

# Start HTTP server
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       🌐 PHANTOM ACTIVITY - WEB SERVER v4.0               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()

Write-Log "[OK] Web Server STARTED on port $Port"
Write-Host "[OK] API Server running on http://localhost:$Port/" -ForegroundColor Green
Write-Host "[INFO] Use Cloudflare Tunnel for remote access" -ForegroundColor Yellow
Write-Host "[KEY] API Key: $ApiKey" -ForegroundColor Yellow
Write-Host ""

$script:statusObject = Load-Status

while ($true) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

        $path = $request.Url.LocalPath
        $method = $request.HttpMethod

        # Check API key
        $key = $request.QueryString["key"]
        if (-not $key -or $key -ne $ApiKey) {
            if ($path -ne "/" -and $path -ne "/index.html" -and $path -ne "/api/status") {
                Invoke-HttpResponse -Response $response -Data @{ Error = "Unauthorized" } -StatusCode 401
                continue
            }
        }

        Write-Log "API Request: $method $path"

        # Routes
        switch -Wildcard ($path) {
            "/" {
                $response.ContentType = "text/html; charset=utf-8"
                $response.StatusCode = 200

                $html = Get-Content "$scriptsDir\phantom-activity-web.html" -Raw
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.OutputStream.Close()
            }
            "/api/status" {
                $status = Get-ActivityStatus
                Invoke-HttpResponse -Response $response -Data $status
            }
            "/api/start" {
                $mode = $request.QueryString["mode"] ?? "standard"
                $result = Start-Activity -Mode $mode

                if ($result.Success) {
                    Invoke-HttpResponse -Response $response -Data @{ Success = $true; Message = "Activity started"; ProcessId = $result.ProcessId }
                } else {
                    Invoke-HttpResponse -Response $response -Data @{ Success = $false; Error = $result.Error } -StatusCode 400
                }
            }
            "/api/stop" {
                $result = Stop-Activity

                if ($result.Success) {
                    Invoke-HttpResponse -Response $response -Data @{ Success = $true; Message = "Activity stopped" }
                } else {
                    Invoke-HttpResponse -Response $response -Data @{ Success = $false; Error = $result.Error } -StatusCode 400
                }
            }
            "/api/logs" {
                $logs = Get-RecentLogs -Lines 50
                Invoke-HttpResponse -Response $response -Data @{ Logs = $logs }
            }
            "/api/config" {
                if (Test-Path $configFile) {
                    $config = Get-Content -Path $configFile | ConvertFrom-Json
                    Invoke-HttpResponse -Response $response -Data $config
                } else {
                    Invoke-HttpResponse -Response $response -Data @{ Error = "Config not found" } -StatusCode 404
                }
            }
            "/api/health" {
                $health = @{
                    Status = "online"
                    Timestamp = (Get-Date -Format "o")
                    PowerShell = $PSVersionTable.PSVersion.ToString()
                    DiskFree = [math]::Round(((Get-PSDrive C).Free / 1GB), 2)
                }
                Invoke-HttpResponse -Response $response -Data $health
            }
            "*" {
                Invoke-HttpResponse -Response $response -Data @{ Error = "Not found" } -StatusCode 404
            }
        }
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
    }
}

$listener.Stop()
