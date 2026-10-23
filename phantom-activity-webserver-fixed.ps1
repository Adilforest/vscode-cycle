# Phantom Activity Web Server - FIXED VERSION
# Provides REST API for remote management via HTTP/HTTPS

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

function Set-StatusField {
    # The status object is a hashtable on a first run and a PSCustomObject once it
    # has been read back from disk; set a field the way each one needs.
    param([string]$Name, $Value)
    if ($script:statusObject -is [hashtable]) {
        $script:statusObject[$Name] = $Value
    } elseif ($script:statusObject.PSObject.Properties.Name -contains $Name) {
        $script:statusObject.$Name = $Value
    } else {
        $script:statusObject | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
    }
}

function Test-IsActivityProcess {
    # The status file outlives reboots and Windows reuses process ids. A live PID
    # only counts as our activity if it is PowerShell and started when recorded;
    # otherwise STOP would kill an unrelated process with administrator rights.
    param($Status)

    if (-not $Status -or -not $Status.ProcessId) { return $null }

    $proc = Get-Process -Id $Status.ProcessId -ErrorAction SilentlyContinue
    if (-not $proc -or $proc.ProcessName -ne "powershell") { return $null }

    if ($Status.PSObject.Properties.Name -contains "ProcessStartTime" -and $Status.ProcessStartTime) {
        try {
            $drift = [math]::Abs(($proc.StartTime - [datetime]$Status.ProcessStartTime).TotalSeconds)
            if ($drift -gt 5) { return $null }
        } catch {
            return $null
        }
    }
    return $proc
}

function Get-EffectiveSchedule {
    # The single definition of the schedule, shared with the scheduler loop and
    # the cycle scripts (all times are minutes after midnight):
    #   work starts at ActiveStartHour:ActiveStartMinuteMin
    #   work ends at   ActiveEndHour:ActiveEndMinuteMax       (exclusive)
    #   lunch is       LunchStartHour:LunchStartMinuteMin up to
    #                  LunchEndHour:LunchEndMinuteMax         (exclusive)
    # The Min/Max pairs come from the tray settings dialog; the dashboard writes
    # the same value into both halves.
    param($Cfg)
    return @{
        WorkStart  = [int]$Cfg.ActiveStartHour * 60 + [int]$Cfg.ActiveStartMinuteMin
        WorkEnd    = [int]$Cfg.ActiveEndHour * 60 + [int]$Cfg.ActiveEndMinuteMax
        LunchStart = [int]$Cfg.LunchStartHour * 60 + [int]$Cfg.LunchStartMinuteMin
        LunchEnd   = [int]$Cfg.LunchEndHour * 60 + [int]$Cfg.LunchEndMinuteMax
    }
}

function Test-ScheduleEnabled {
    # A config without the flag (as the tray settings dialog used to write) is on
    param($Cfg)
    return (-not ($Cfg.PSObject.Properties.Name -contains "Enabled")) -or [bool]$Cfg.Enabled
}

function Format-ClockMinutes {
    param([int]$Minutes)
    return ("{0:00}:{1:00}" -f [math]::Floor($Minutes / 60), ($Minutes % 60))
}

function Start-Activity {
    param(
        [string]$Mode = "standard",
        [bool]$Visible = $false
    )

    try {
        # Two loops would fight over the same isolated VS Code, and only the newer
        # PID would be recorded, leaving the older one running out of reach of STOP
        $current = Get-ActivityStatus
        if ($current.Status -eq "running" -and $current.ProcessId) {
            return @{ Success = $false; Error = "Activity is already running (PID $($current.ProcessId)). Stop it first." }
        }

        Write-Log "[START] Starting activity: Mode=$Mode"

        $psArgs = @(
            "-NoProfile"
            "-ExecutionPolicy", "Bypass"
            "-File", "`"$scriptsDir\phantom-activity-alwayson.ps1`""
        )

        # -UseExtended is a [switch]: present means true, absent means false.
        # Passing a separate "$false" token would bind to the positional
        # [int]$QuickCheckMinutes and kill the child on parameter binding.
        if ($Mode -eq "extended") {
            $psArgs += "-UseExtended"
        }

        $childErr = "$scriptsDir\phantom-child-error.log"
        $childOut = "$scriptsDir\phantom-child-output.log"

        # Hidden, not Minimized: a minimized console can still become the active
        # window, and the typing simulation would then deliver Ctrl+C into it and
        # kill the activity. A hidden window can never receive keyboard focus.
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -PassThru -WindowStyle Hidden -RedirectStandardError $childErr -RedirectStandardOutput $childOut

        # Confirm the child survived startup instead of reporting a PID that is already gone
        Start-Sleep -Milliseconds 1500
        $process.Refresh()
        if ($process.HasExited) {
            $reason = "child exited immediately (code $($process.ExitCode))"
            if (Test-Path $childErr) {
                $errText = (Get-Content $childErr -Raw).Trim()
                if ($errText) { $reason = ($errText -split "`r?`n")[0] }
            }
            Write-Log "[ERROR] Activity failed to stay alive: $reason"
            $script:statusObject.Status = "stopped"
            $script:statusObject.ProcessId = $null
            Save-Status
            return @{ Success = $false; Error = $reason }
        }

        Write-Log "[OK] Activity running PID=$($process.Id) Mode=$Mode"

        $script:statusObject.Status = "running"
        $script:statusObject.Mode = $Mode
        $script:statusObject.ProcessId = $process.Id
        $script:statusObject.StartTime = (Get-Date -Format "o")
        $procStart = $null
        try { $procStart = $process.StartTime.ToString("o") } catch { }
        Set-StatusField -Name "ProcessStartTime" -Value $procStart
        Save-Status

        return @{ Success = $true; ProcessId = $process.Id }
    } catch {
        Write-Log "[ERROR] Failed to start: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Stop-Activity {
    try {
        $status = Load-Status
        $proc = Test-IsActivityProcess $status
        if ($proc) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            Write-Log "[STOP] Stopped activity PID=$($proc.Id)"
        } elseif ($status.ProcessId) {
            Write-Log "[STOP] PID $($status.ProcessId) is no longer the activity - left untouched"
        }

        # A cycle may have been mid-way; close its isolated VS Code as the cycle would
        Get-CimInstance Win32_Process -Filter "Name='Code.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -like "*.vscode-cycle-isolated*" } |
            ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

        $script:statusObject.Status = "stopped"
        $script:statusObject.Mode = "none"
        $script:statusObject.ProcessId = $null
        Save-Status

        return @{ Success = $true }
    } catch {
        Write-Log "[ERROR] Failed to stop: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Get-ActivityStatus {
    $status = Load-Status

    if ($status.ProcessId) {
        $proc = Test-IsActivityProcess $status
        if ($proc) {
            $uptime = (Get-Date) - [datetime]::Parse($status.StartTime)
            $uptimeText = "{0}h {1}m" -f [int][math]::Floor($uptime.TotalHours), $uptime.Minutes
            $status | Add-Member -NotePropertyName "Uptime" -NotePropertyValue $uptimeText -Force
        } else {
            # Gone, or the PID now belongs to something else - persist the correction
            $status.Status = "stopped"
            $status.ProcessId = $null
            $script:statusObject.Status = "stopped"
            $script:statusObject.ProcessId = $null
            $script:statusObject.Mode = "none"
            Save-Status
        }
    }

    return $status
}

function Get-RecentLogs {
    param([int]$Lines = 20)

    if (-not (Test-Path $logFile)) { return @() }

    # The server and scheduler write "[yyyy-MM-dd HH:mm:ss] msg", the cycle scripts
    # "yyyy-MM-dd HH:mm:ss  msg". Lines without a timestamp (wrapped error text) are
    # dropped before the limit is applied, so they cannot crowd out real entries.
    $pattern = '^\[?(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})\]?\s+(.+)$'
    $logs = New-Object System.Collections.Generic.List[object]
    Get-Content -Path $logFile -Tail ($Lines * 4) | ForEach-Object {
        if ($_ -match $pattern) {
            # ISO form so every browser, Safari included, can parse it
            $logs.Add(@{ Time = "$($matches[1])T$($matches[2])"; Message = $matches[3] })
        }
    }
    $first = [math]::Max(0, $logs.Count - $Lines)
    # The leading comma keeps a one-item result a list instead of unrolling it
    return ,@($logs.GetRange($first, $logs.Count - $first))
}

function Save-AppConfig {
    param([string]$JsonBody)

    $validDays = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

    try {
        $incoming = $JsonBody | ConvertFrom-Json
    } catch {
        return @{ Success = $false; Error = "Invalid JSON payload" }
    }

    if (-not (Test-Path $configFile)) {
        return @{ Success = $false; Error = "Config file not found" }
    }

    try {
        $cfg = Get-Content -Path $configFile -Raw | ConvertFrom-Json
    } catch {
        return @{ Success = $false; Error = "Current config is unreadable" }
    }

    # Every numeric field, with the range it is allowed to take
    $numericFields = @(
        @{ Name = "ActiveStartHour";      Min = 0; Max = 23 }
        @{ Name = "ActiveStartMinuteMin"; Min = 0; Max = 59 }
        @{ Name = "ActiveStartMinuteMax"; Min = 0; Max = 59 }
        @{ Name = "ActiveEndHour";        Min = 0; Max = 23 }
        @{ Name = "ActiveEndMinuteMin";   Min = 0; Max = 59 }
        @{ Name = "ActiveEndMinuteMax";   Min = 0; Max = 59 }
        @{ Name = "LunchStartHour";       Min = 0; Max = 23 }
        @{ Name = "LunchStartMinuteMin";  Min = 0; Max = 59 }
        @{ Name = "LunchStartMinuteMax";  Min = 0; Max = 59 }
        @{ Name = "LunchEndHour";         Min = 0; Max = 23 }
        @{ Name = "LunchEndMinuteMin";    Min = 0; Max = 59 }
        @{ Name = "LunchEndMinuteMax";    Min = 0; Max = 59 }
        @{ Name = "StayOpenSeconds";      Min = 5; Max = 600 }
        @{ Name = "IntervalMinutes";      Min = 1; Max = 120 }
    )

    $errors = @()
    $applied = @{}

    foreach ($f in $numericFields) {
        $name = $f.Name
        if ($null -eq $incoming.$name) { continue }

        $parsed = 0
        if (-not [int]::TryParse([string]$incoming.$name, [ref]$parsed)) {
            $errors += "$name must be a whole number"
            continue
        }
        if ($parsed -lt $f.Min -or $parsed -gt $f.Max) {
            $errors += "$name must be between $($f.Min) and $($f.Max)"
            continue
        }
        $applied[$name] = $parsed
    }

    if ($null -ne $incoming.Enabled) {
        $applied["Enabled"] = [bool]$incoming.Enabled
    }

    if ($null -ne $incoming.ActiveDays) {
        $days = @($incoming.ActiveDays)
        $badDays = $days | Where-Object { $validDays -notcontains $_ }
        if ($badDays) {
            $errors += "Unknown day name: $($badDays -join ', ')"
        } else {
            # Keep the canonical Monday-to-Sunday order regardless of input order
            $applied["ActiveDays"] = @($validDays | Where-Object { $days -contains $_ })
        }
    }

    if ($null -ne $incoming.Holidays) {
        $holidays = @($incoming.Holidays) | Where-Object { "$_".Trim() -ne "" } | ForEach-Object { "$_".Trim() }
        $badDates = @()
        foreach ($h in $holidays) {
            $d = [datetime]::MinValue
            if (-not [datetime]::TryParseExact($h, "yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$d)) {
                $badDates += $h
            }
        }
        if ($badDates) {
            $errors += "Holidays must use YYYY-MM-DD: $($badDates -join ', ')"
        } else {
            $applied["Holidays"] = @($holidays | Sort-Object -Unique)
        }
    }

    if ($errors.Count -gt 0) {
        return @{ Success = $false; Error = ($errors -join "; ") }
    }

    # Merge the accepted values over the current config
    foreach ($k in $applied.Keys) {
        if ($cfg.PSObject.Properties.Name -contains $k) {
            $cfg.$k = $applied[$k]
        } else {
            $cfg | Add-Member -NotePropertyName $k -NotePropertyValue $applied[$k] -Force
        }
    }

    # Reject a schedule that cannot run, judged by the same rule the scripts use
    $win = Get-EffectiveSchedule $cfg
    if ($win.WorkEnd -le $win.WorkStart) {
        return @{ Success = $false; Error = "Work end time must be later than work start time" }
    }
    if ($win.LunchEnd -le $win.LunchStart) {
        return @{ Success = $false; Error = "Lunch end time must be later than lunch start time" }
    }
    if (@($cfg.ActiveDays).Count -eq 0) {
        return @{ Success = $false; Error = "At least one working day must be selected" }
    }

    # Write a temp file, then swap it in with File.Replace: unlike Move-Item -Force
    # it never leaves a moment with no config, which the scheduler would read as
    # "off hours". A reader holding the file briefly makes Replace fail, so retry.
    $tmp = "$configFile.tmp"
    try {
        $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $tmp -Encoding UTF8 -ErrorAction Stop
    } catch {
        return @{ Success = $false; Error = "Failed to write config: $($_.Exception.Message)" }
    }

    $replaced = $false
    $lastError = ""
    for ($i = 0; $i -lt 5 -and -not $replaced; $i++) {
        try {
            [System.IO.File]::Replace($tmp, $configFile, [NullString]::Value)
            $replaced = $true
        } catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Milliseconds 150
        }
    }
    if (-not $replaced) {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        return @{ Success = $false; Error = "Failed to write config: $lastError" }
    }

    $changed = ($applied.Keys | Sort-Object) -join ', '
    Write-Log "[CONFIG] Updated: $changed"

    return @{ Success = $true; Changed = @($applied.Keys | Sort-Object); Config = $cfg }
}

function Write-Log {
    param([string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"

    # The activity script writes to the same file, so the write can collide.
    # Retry briefly instead of dropping the line or throwing.
    for ($i = 0; $i -lt 5; $i++) {
        try {
            Add-Content -Path $logFile -Value $line -ErrorAction Stop
            break
        } catch {
            Start-Sleep -Milliseconds 120
        }
    }

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
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "[OK] PHANTOM ACTIVITY WEB SERVER v4.0" -ForegroundColor Cyan
Write-Host "[OK] Starting on port $Port" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()

Write-Log "[OK] Web Server STARTED on port $Port"
Write-Host "[OK] Server running on http://localhost:$Port/" -ForegroundColor Green
Write-Host "[OK] API Key: $ApiKey" -ForegroundColor Green
Write-Host "[OK] Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

$script:statusObject = Load-Status

$consecutiveErrors = 0

while ($true) {
    $response = $null
    try {
        $context = $listener.GetContext()
        $consecutiveErrors = 0
        $request = $context.Request
        $response = $context.Response
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        $path = $request.Url.LocalPath
        $method = $request.HttpMethod

        # Answer CORS preflight before the API key check, which it cannot carry
        if ($method -eq "OPTIONS") {
            $response.StatusCode = 204
            $response.OutputStream.Close()
            continue
        }

        # Check API key for protected routes
        $key = $request.QueryString["key"]
        if (-not $key -or $key -cne $ApiKey) {
            if ($path -notlike "/" -and $path -notlike "/index.html" -and $path -notlike "/api/status") {
                Invoke-HttpResponse -Response $response -Data @{ Error = "Unauthorized" } -StatusCode 401
                continue
            }
        }

        # The dashboard polls these every few seconds. Logging each one floods the
        # shared activity log and locks out the activity script's own writes.
        $pollingRoutes = @("/", "/index.html", "/api/status", "/api/logs", "/api/health", "/api/schedule")
        if ($pollingRoutes -notcontains $path -and -not ($path -eq "/api/config" -and $method -eq "GET")) {
            Write-Log "[API] $method $path"
        }

        # Routes
        switch -Wildcard ($path) {
            "/" {
                $response.ContentType = "text/html; charset=utf-8"
                $response.StatusCode = 200

                $html = Get-Content "$scriptsDir\phantom-activity-web-fixed.html" -Raw
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
                $mode = if ($request.QueryString["mode"]) { $request.QueryString["mode"] } else { "standard" }
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
                if ($method -eq "POST") {
                    $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                    $body = $reader.ReadToEnd()
                    $reader.Close()

                    $saved = Save-AppConfig -JsonBody $body

                    if ($saved.Success) {
                        Invoke-HttpResponse -Response $response -Data @{
                            Success = $true
                            Message = "Settings saved"
                            Changed = $saved.Changed
                            Config  = $saved.Config
                        }
                    } else {
                        Write-Log "[CONFIG] Rejected: $($saved.Error)"
                        Invoke-HttpResponse -Response $response -Data @{ Success = $false; Error = $saved.Error } -StatusCode 400
                    }
                } elseif (Test-Path $configFile) {
                    $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
                    Invoke-HttpResponse -Response $response -Data $config
                } else {
                    Invoke-HttpResponse -Response $response -Data @{ Error = "Config not found" } -StatusCode 404
                }
            }
            "/api/schedule" {
                # What the schedule means right now, so the dashboard can show
                # whether the farm is inside working hours, at lunch or off duty
                if (-not (Test-Path $configFile)) {
                    Invoke-HttpResponse -Response $response -Data @{ Error = "Config not found" } -StatusCode 404
                } else {
                    $cfg = Get-Content -Path $configFile -Raw | ConvertFrom-Json
                    $now = Get-Date
                    $nowMin = $now.Hour * 60 + $now.Minute

                    $isActiveDay = @($cfg.ActiveDays) -contains $now.DayOfWeek.ToString()
                    $isHoliday = @($cfg.Holidays) -contains $now.ToString("yyyy-MM-dd")
                    $enabled = Test-ScheduleEnabled $cfg

                    $win = Get-EffectiveSchedule $cfg
                    $inWork = ($nowMin -ge $win.WorkStart -and $nowMin -lt $win.WorkEnd)
                    $inLunch = ($nowMin -ge $win.LunchStart -and $nowMin -lt $win.LunchEnd)

                    $phase = "off-hours"
                    if (-not $enabled) { $phase = "disabled" }
                    elseif (-not $isActiveDay) { $phase = "non-working-day" }
                    elseif ($isHoliday) { $phase = "holiday" }
                    elseif ($inLunch) { $phase = "lunch-break" }
                    elseif ($inWork) { $phase = "working" }

                    Invoke-HttpResponse -Response $response -Data @{
                        Phase       = $phase
                        ServerTime  = $now.ToString("HH:mm:ss")
                        DayOfWeek   = $now.DayOfWeek.ToString()
                        IsActiveDay = $isActiveDay
                        IsHoliday   = $isHoliday
                        Enabled     = $enabled
                        WorkWindow  = "$(Format-ClockMinutes $win.WorkStart) - $(Format-ClockMinutes $win.WorkEnd)"
                        LunchWindow = "$(Format-ClockMinutes $win.LunchStart) - $(Format-ClockMinutes $win.LunchEnd)"
                    }
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
            default {
                Invoke-HttpResponse -Response $response -Data @{ Error = "Not found" } -StatusCode 404
            }
        }
    } catch [System.ObjectDisposedException] {
        # Listener was disposed (server shut down) - exit instead of flooding the log
        Write-Log "[STOP] Listener disposed, shutting down request loop"
        break
    } catch {
        $ex = $_.Exception
        if ($ex -is [System.ObjectDisposedException] -or $ex.InnerException -is [System.ObjectDisposedException]) {
            Write-Log "[STOP] Listener disposed, shutting down request loop"
            break
        }

        if ($response) {
            # A route failed after the request was accepted. Answer it: an unanswered
            # request stays open, and the browser stalls every later one behind it.
            Write-Log "[ERROR] $($request.HttpMethod) $($request.Url.LocalPath): $($ex.Message)"
            try {
                $buf = [System.Text.Encoding]::UTF8.GetBytes((@{ Error = "Internal error: $($ex.Message)" } | ConvertTo-Json))
                $response.StatusCode = 500
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buf.Length
                $response.OutputStream.Write($buf, 0, $buf.Length)
            } catch { }
            try { $response.OutputStream.Close() } catch { }
            continue
        }

        # Guard against an unbounded error flood from a dead listener
        $consecutiveErrors++
        if ($consecutiveErrors -le 5) {
            Write-Log "[ERROR] $($ex.Message)"
        }
        if ($consecutiveErrors -ge 10) {
            Write-Log "[STOP] $consecutiveErrors consecutive listener errors, shutting down request loop"
            break
        }
        Start-Sleep -Milliseconds 500
    }
}

Write-Log "[STOP] Web Server stopped"
if ($listener.IsListening) { $listener.Stop() }
$listener.Close()
