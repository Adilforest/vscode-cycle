# Phantom Activity Web Server - Fixed Edition
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
$script:statusObject = @{
    Status = "stopped"
    Mode = "none"
    ProcessId = $null
    StartTime = $null
    LastUpdate = (Get-Date -Format "o")
    CycleCount = 0
}

function Save-Status {
    try {
        $script:statusObject.LastUpdate = (Get-Date -Format "o")
        $script:statusObject | ConvertTo-Json | Set-Content -Path $statusFile -ErrorAction Stop
    } catch {
        Write-Error "Failed to save status: $_"
    }
}

function Load-Status {
    if (Test-Path $statusFile) {
        try {
            return Get-Content -Path $statusFile | ConvertFrom-Json
        } catch {
            return $script:statusObject
        }
    }
    return $script:statusObject
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
    try {
        Get-Content -Path $logFile -ErrorAction Stop | Select-Object -Last $Lines | ForEach-Object {
            if ($_ -match '\[(.+?)\]\s+(.+)') {
                $logs += @{
                    Time = $matches[1]
                    Message = $matches[2]
                }
            } else {
                $logs += @{
                    Time = ""
                    Message = $_
                }
            }
        }
    } catch {
        # File might be locked, return empty
    }
    return $logs
}

function Write-Log {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"

    # Retry logic for file lock
    for ($i = 0; $i -lt 3; $i++) {
        try {
            Add-Content -Path $logFile -Value $line -ErrorAction Stop
            Write-Host $line -ForegroundColor Cyan
            return
        } catch {
            if ($i -lt 2) {
                Start-Sleep -Milliseconds 50
            }
        }
    }
}

function Invoke-HttpResponse {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [object]$Data = $null,
        [int]$StatusCode = 200,
        [string]$ContentType = "application/json"
    )

    try {
        $Response.StatusCode = $StatusCode
        $Response.ContentType = $ContentType

        if ($Data) {
            $json = $Data | ConvertTo-Json -Depth 10 -ErrorAction Stop
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $Response.ContentLength64 = $buffer.Length
            $Response.OutputStream.Write($buffer, 0, $buffer.Length)
        }

        $Response.OutputStream.Close()
    } catch {
        Write-Log "ERROR in Invoke-HttpResponse: $_"
        try { $Response.OutputStream.Close() } catch { }
    }
}

# Start HTTP server
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       🌐 PHANTOM ACTIVITY - WEB SERVER v4.1 (FIXED)       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

try {
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
            # Use async pattern to avoid blocking on GetContext
            $async = $listener.BeginGetContext($null, $null)

            # Wait for either context or termination signal (5 second timeout)
            if (-not $async.AsyncWaitHandle.WaitOne(5000)) {
                continue
            }

            $context = $listener.EndGetContext($async)
            $request = $context.Request
            $response = $context.Response

            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

            $path = $request.Url.LocalPath
            $method = $request.HttpMethod

            # Check API key for protected endpoints
            $key = $request.QueryString["key"]
            $isAuthorized = ($key -eq $ApiKey)

            # Routes
            switch -Wildcard ($path) {
                "/" {
                    $response.ContentType = "text/html; charset=utf-8"
                    $response.StatusCode = 200

                    $webPagePath = "$scriptsDir\phantom-activity-web.html"
                    if (Test-Path $webPagePath) {
                        try {
                            $html = Get-Content $webPagePath -Raw -ErrorAction Stop
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        } catch {
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes("<h1>Web UI not available</h1>")
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        }
                    } else {
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes("<h1>Phantom Activity Server - OK</h1>")
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    }
                    $response.OutputStream.Close()
                }
                "/api/status" {
                    $status = Get-ActivityStatus
                    Invoke-HttpResponse -Response $response -Data $status
                }
                "/api/start" {
                    if (-not $isAuthorized) {
                        Invoke-HttpResponse -Response $response -Data @{ Error = "Unauthorized" } -StatusCode 401
                    } else {
                        $mode = if ($request.QueryString["mode"]) { $request.QueryString["mode"] } else { "standard" }

                        # Handle VISIBLE mode (for Manic Time screenshots)
                        if ($mode -eq "visible") {
                            try {
                                Write-Log "[VISIBLE MODE] Starting VISIBLE cycle with windows visible"
                                $psArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptsDir\vscode-cycle-visible.ps1`"")
                                $process = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -PassThru

                                $script:statusObject.Status = "running"
                                $script:statusObject.Mode = "visible"
                                $script:statusObject.ProcessId = $process.Id
                                $script:statusObject.StartTime = (Get-Date -Format "o")
                                Save-Status

                                Invoke-HttpResponse -Response $response -Data @{ Success = $true; Message = "VISIBLE mode started"; ProcessId = $process.Id }
                            } catch {
                                Write-Log "ERROR: Failed to start VISIBLE mode: $_"
                                Invoke-HttpResponse -Response $response -Data @{ Success = $false; Error = $_.Message } -StatusCode 400
                            }
                        } else {
                            $result = Start-Activity -Mode $mode

                            if ($result.Success) {
                                Invoke-HttpResponse -Response $response -Data @{ Success = $true; Message = "Activity started"; ProcessId = $result.ProcessId }
                            } else {
                                Invoke-HttpResponse -Response $response -Data @{ Success = $false; Error = $result.Error } -StatusCode 400
                            }
                        }
                    }
                }
                "/api/stop" {
                    if (-not $isAuthorized) {
                        Invoke-HttpResponse -Response $response -Data @{ Error = "Unauthorized" } -StatusCode 401
                    } else {
                        $result = Stop-Activity

                        if ($result.Success) {
                            Invoke-HttpResponse -Response $response -Data @{ Success = $true; Message = "Activity stopped" }
                        } else {
                            Invoke-HttpResponse -Response $response -Data @{ Success = $false; Error = $result.Error } -StatusCode 400
                        }
                    }
                }
                "/api/logs" {
                    $logs = Get-RecentLogs -Lines 50
                    Invoke-HttpResponse -Response $response -Data @{ Logs = $logs }
                }
                "/api/config" {
                    if (Test-Path $configFile) {
                        try {
                            $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
                            Invoke-HttpResponse -Response $response -Data $config
                        } catch {
                            Invoke-HttpResponse -Response $response -Data @{ Error = "Failed to load config" } -StatusCode 500
                        }
                    } else {
                        Invoke-HttpResponse -Response $response -Data @{ Error = "Config not found" } -StatusCode 404
                    }
                }
                "/api/health" {
                    $health = @{
                        Status = "online"
                        Timestamp = (Get-Date -Format "o")
                        PowerShell = $PSVersionTable.PSVersion.ToString()
                        DiskFree = try { [math]::Round(((Get-PSDrive C).Free / 1GB), 2) } catch { "N/A" }
                    }
                    Invoke-HttpResponse -Response $response -Data $health
                }
                default {
                    Invoke-HttpResponse -Response $response -Data @{ Error = "Not found" } -StatusCode 404
                }
            }
        } catch {
            Write-Log "ERROR in request handler: $($_.Exception.Message)"
            try { $response.OutputStream.Close() } catch { }
        }
    }
} catch {
    Write-Host "ERROR: Failed to start HTTP listener: $_" -ForegroundColor Red
    Write-Log "FATAL ERROR: Failed to start HTTP listener: $_"

    # Check if it's a port access issue
    if ($_.Exception.Message -like "*denied*" -or $_.Exception.Message -like "*address*") {
        Write-Host "This may require administrator privileges or the port may be in use." -ForegroundColor Yellow
        Write-Host "Try: netstat -ano | findstr :$Port" -ForegroundColor Yellow
    }

    exit 1
} finally {
    try {
        if ($listener) { $listener.Stop() }
    } catch { }
}
