# phantom-activity-common.ps1
# Shared helpers for the phantom-activity cycle scripts and the always-on loop.
#
# Everything a cycle opens runs in ISOLATED Chrome / VS Code data directories, so
# it is a separate process tree from the account farm. That lets us close exactly
# what we opened - by window handle while a cycle runs, and by killing the whole
# isolated tree as a guarantee at the end - without any chance of touching a farm
# profile (the farm uses the default Chrome user-data-dir, which never matches our
# isolated path).

$PhantomUser      = $env:USERNAME
$PhantomScriptDir = "C:\Users\$PhantomUser\Scripts"
$PhantomLogFile   = "$PhantomScriptDir\vscode-cycle.log"
$PhantomCfgFile   = "$PhantomScriptDir\vscode-cycle.config.json"
$PhantomIsoRoot   = "$PhantomScriptDir\.vscode-cycle-isolated"
$PhantomChromeUDD = "$PhantomIsoRoot\chrome-user-data"
$PhantomCodeUDD   = "$PhantomIsoRoot\user-data"
$PhantomCodeExt   = "$PhantomIsoRoot\extensions"
$PhantomStateFile = "$PhantomScriptDir\phantom-owned.json"
$PhantomStopFlag  = "$PhantomScriptDir\phantom-STOP.flag"

$PhantomCodeExe   = "C:\Users\$PhantomUser\AppData\Local\Programs\Microsoft VS Code\Code.exe"
$PhantomChromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# In-memory list of what THIS run opened. Each item: @{ Kind='window'|'process'; Id; Opened }
$PhantomOwned = New-Object System.Collections.Generic.List[object]

# Win32 helpers for enumerating and gracefully closing top-level windows.
# Guarded so repeated dot-sourcing in one PowerShell process does not re-add it.
if (-not ('CycleWin' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
public class CycleWin {
    delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    // Visible top-level windows of the given class, as "hwnd,pid". No title filter:
    // a just-opened browser window is briefly untitled, and we identify ours by the
    // owning process id instead, so an untitled window must not be skipped.
    public static List<string> TopLevel(string cls) {
        var res = new List<string>();
        EnumWindows((h, l) => {
            if (!IsWindowVisible(h)) return true;
            var sb = new StringBuilder(256);
            GetClassName(h, sb, 256);
            if (sb.ToString() != cls) return true;
            uint pid; GetWindowThreadProcessId(h, out pid);
            res.Add(h.ToInt64() + "," + pid);
            return true;
        }, IntPtr.Zero);
        return res;
    }
}
"@
}

function Write-CycleLog {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    for ($i = 0; $i -lt 5; $i++) {
        try { Add-Content -Path $PhantomLogFile -Value $line -ErrorAction Stop; break }
        catch { Start-Sleep -Milliseconds 120 }
    }
}

# ---------------------------------------------------------------------------
# Memory safety valve
# ---------------------------------------------------------------------------

function Get-MemFreeMB {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if (-not $os) { return $null }
    return [int][math]::Round($os.FreePhysicalMemory / 1024, 0)
}

function Get-MemThresholds {
    # Hard stop and warning levels in MB of free physical RAM. Tunable from the
    # config file (MemoryStopFreeMB / MemoryWarnFreeMB); sensible defaults otherwise.
    $stopFree = 1200
    $warnFree = 2000
    if (Test-Path $PhantomCfgFile) {
        try {
            $cfg = Get-Content -Path $PhantomCfgFile -Raw | ConvertFrom-Json
            if ($cfg.PSObject.Properties.Name -contains 'MemoryStopFreeMB' -and [int]$cfg.MemoryStopFreeMB -gt 0) { $stopFree = [int]$cfg.MemoryStopFreeMB }
            if ($cfg.PSObject.Properties.Name -contains 'MemoryWarnFreeMB' -and [int]$cfg.MemoryWarnFreeMB -gt 0) { $warnFree = [int]$cfg.MemoryWarnFreeMB }
        } catch { }
    }
    return @{ StopFree = $stopFree; WarnFree = $warnFree }
}

function Test-MemoryCritical {
    $free = Get-MemFreeMB
    if ($null -eq $free) { return $false }
    return ($free -lt (Get-MemThresholds).StopFree)
}

# ---------------------------------------------------------------------------
# Isolated process-tree discovery and teardown (farm-safe by construction)
# ---------------------------------------------------------------------------

function Get-TrackedTreePids {
    # All PIDs of $ProcName that belong to the isolated tree whose root command
    # line contains $Needle. Roots are the processes carrying the isolated path
    # and no --type= (the master); their descendants are gathered by parent id,
    # so helper processes that do not repeat the flag are still included. Farm
    # processes live under a different root and are never reached.
    param([string]$ProcName, [string]$Needle)
    $procs = Get-CimInstance Win32_Process -Filter "Name='$ProcName'" -ErrorAction SilentlyContinue
    if (-not $procs) { return @() }

    $roots = @($procs | Where-Object { $_.CommandLine -like "*$Needle*" -and $_.CommandLine -notlike "*--type=*" })
    if (-not $roots) { $roots = @($procs | Where-Object { $_.CommandLine -like "*$Needle*" }) }
    if (-not $roots) { return @() }

    $set = @{}
    foreach ($r in $roots) { $set[[int]$r.ProcessId] = $true }
    for ($pass = 0; $pass -lt 8; $pass++) {
        $added = $false
        foreach ($p in $procs) {
            if (-not $set.ContainsKey([int]$p.ProcessId) -and $set.ContainsKey([int]$p.ParentProcessId)) {
                $set[[int]$p.ProcessId] = $true
                $added = $true
            }
        }
        if (-not $added) { break }
    }
    return @($set.Keys)
}

function Stop-TrackedTree {
    param([string]$ProcName, [string]$Needle)
    $treePids = Get-TrackedTreePids -ProcName $ProcName -Needle $Needle
    foreach ($procId in $treePids) { Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue }
    return @($treePids).Count
}

function Get-TreeWindows {
    # Handles of visible top-level windows owned by the given isolated tree.
    param([string]$ProcName, [string]$Needle)
    $treePids = @{}
    foreach ($procId in (Get-TrackedTreePids -ProcName $ProcName -Needle $Needle)) { $treePids[[uint32]$procId] = $true }
    $res = @()
    foreach ($entry in [CycleWin]::TopLevel("Chrome_WidgetWin_1")) {
        $parts = $entry -split ','
        if ($treePids.ContainsKey([uint32]$parts[1])) { $res += [long]$parts[0] }
    }
    # Return a typed array: empty stays empty, one element does not collapse to a
    # scalar at the call sites (which all wrap the result in @(...)).
    return [long[]]$res
}

# ---------------------------------------------------------------------------
# Owned-item bookkeeping (persisted so a crashed run can still be cleaned up)
# ---------------------------------------------------------------------------

function Save-Owned {
    try {
        $snap = @($PhantomOwned | ForEach-Object { @{ Kind = $_.Kind; Id = [string]$_.Id; Opened = $_.Opened.ToString('o') } })
        ,$snap | ConvertTo-Json -Depth 5 | Set-Content -Path $PhantomStateFile -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch { }
}

function Add-Owned {
    param([string]$Kind, $Id)
    $PhantomOwned.Add([pscustomobject]@{ Kind = $Kind; Id = $Id; Opened = (Get-Date) })
    Save-Owned
}

function Close-Owned {
    # Close tracked items older than $OlderThanSeconds (0 = all). Windows get a
    # graceful WM_CLOSE; terminals are stopped by their real PID.
    param([int]$OlderThanSeconds)
    $keep = New-Object System.Collections.Generic.List[object]
    foreach ($o in $PhantomOwned) {
        if (((Get-Date) - $o.Opened).TotalSeconds -lt $OlderThanSeconds) { $keep.Add($o); continue }
        if ($o.Kind -eq 'window') {
            $h = [long]$o.Id
            if ([CycleWin]::IsWindow([IntPtr]$h)) {
                [void][CycleWin]::PostMessage([IntPtr]$h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
            }
        } else {
            Stop-Process -Id ([int]$o.Id) -Force -ErrorAction SilentlyContinue
        }
    }
    $PhantomOwned.Clear()
    foreach ($k in $keep) { $PhantomOwned.Add($k) }
    Save-Owned
}

function Invoke-PhantomCleanup {
    # End-of-cycle teardown: close exactly the tracked items (terminals by PID,
    # windows by WM_CLOSE), then guarantee the isolated Chrome and VS Code trees
    # are gone (safe - these are never the farm). Close-Owned 0 empties the list.
    Close-Owned 0
    Start-Sleep -Milliseconds 500
    [void](Stop-TrackedTree -ProcName 'chrome.exe' -Needle $PhantomChromeUDD)
    [void](Stop-TrackedTree -ProcName 'Code.exe'   -Needle $PhantomCodeUDD)
    Save-Owned
}

function Invoke-StartupSweep {
    # Close anything a previous (possibly crashed) run left behind, before a new
    # run starts, so leftovers can never accumulate from one run to the next.
    if (Test-Path $PhantomStateFile) {
        try {
            $prev = Get-Content -Path $PhantomStateFile -Raw | ConvertFrom-Json
            foreach ($o in @($prev)) {
                if ($o.Kind -eq 'window') {
                    $h = 0L
                    if ([long]::TryParse([string]$o.Id, [ref]$h) -and [CycleWin]::IsWindow([IntPtr]$h)) {
                        [void][CycleWin]::PostMessage([IntPtr]$h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
                    }
                } elseif ($o.Kind -eq 'process') {
                    Stop-Process -Id ([int]$o.Id) -Force -ErrorAction SilentlyContinue
                }
            }
        } catch { }
    }
    [void](Stop-TrackedTree -ProcName 'chrome.exe' -Needle $PhantomChromeUDD)
    [void](Stop-TrackedTree -ProcName 'Code.exe'   -Needle $PhantomCodeUDD)
    $PhantomOwned.Clear()
    Save-Owned
}

# ---------------------------------------------------------------------------
# Launchers - everything lands in the isolated profiles
# ---------------------------------------------------------------------------

function Open-PhantomUrl {
    param([string]$Url)
    if (-not (Test-Path $PhantomChromeExe)) {
        Write-CycleLog "  (Chrome not found at $PhantomChromeExe - skipped)"
        return
    }
    $before = @(Get-TreeWindows -ProcName 'chrome.exe' -Needle $PhantomChromeUDD)
    Start-Process -FilePath $PhantomChromeExe -ArgumentList @(
        "--user-data-dir=`"$PhantomChromeUDD`"",
        "--no-first-run", "--no-default-browser-check",
        "--disable-session-crashed-bubble", "--disable-background-networking",
        "--new-window", $Url
    ) | Out-Null

    $new = @()
    for ($i = 0; $i -lt 30 -and -not $new; $i++) {   # wait up to ~15s for the window
        Start-Sleep -Milliseconds 500
        $new = @(Get-TreeWindows -ProcName 'chrome.exe' -Needle $PhantomChromeUDD | Where-Object { $before -notcontains $_ })
    }
    foreach ($h in $new) { Add-Owned -Kind 'window' -Id ([long]$h) }
    if (-not $new) { Write-CycleLog "  (phantom chrome window not detected in 15s - the end-of-cycle tree kill will still close it)" }
}

function Open-PhantomVsCode {
    param([string]$ProjectPath)
    if (-not (Test-Path $PhantomCodeExe)) {
        Write-CycleLog "  (VS Code not found at $PhantomCodeExe - skipped)"
        return
    }
    $before = @(Get-TreeWindows -ProcName 'Code.exe' -Needle $PhantomCodeUDD)
    Start-Process -FilePath $PhantomCodeExe -ArgumentList @(
        "--user-data-dir=`"$PhantomCodeUDD`"",
        "--extensions-dir=`"$PhantomCodeExt`"",
        "--new-window", $ProjectPath
    ) -WindowStyle Normal | Out-Null

    $new = @()
    for ($i = 0; $i -lt 30 -and -not $new; $i++) {
        Start-Sleep -Milliseconds 500
        $new = @(Get-TreeWindows -ProcName 'Code.exe' -Needle $PhantomCodeUDD | Where-Object { $before -notcontains $_ })
    }
    foreach ($h in $new) { Add-Owned -Kind 'window' -Id ([long]$h) }
}

function Open-PhantomTerminal {
    # A real, trackable process: Start-Process returns its PID directly, so this
    # one is always closed by id regardless of window detection.
    $p = Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoExit", "-Command", "`$Host.UI.RawUI.WindowTitle = 'PhantomTerm'"
    ) -WindowStyle Normal -PassThru
    Add-Owned -Kind 'process' -Id ([int]$p.Id)
}

function Invoke-SimulatedAction {
    try {
        $x = [System.Windows.Forms.Cursor]::Position.X
        $y = [System.Windows.Forms.Cursor]::Position.Y
        [System.Windows.Forms.Cursor]::Position = [System.Drawing.Point]::new($x + 3, $y + 3)
        Start-Sleep -Milliseconds 50
        [System.Windows.Forms.Cursor]::Position = [System.Drawing.Point]::new($x, $y)
        [System.Windows.Forms.SendKeys]::SendWait("{F5}")
        Start-Sleep -Milliseconds 100
    } catch {
        Write-CycleLog "Action skipped: $_"
    }
}
