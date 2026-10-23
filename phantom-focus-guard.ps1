# Phantom Activity - focus guard
#
# Synthetic keystrokes (keybd_event, SendKeys) are delivered to whatever window
# is in the foreground, not to the window the script has in mind. Sent to the
# wrong window, Ctrl+C terminates console processes (the tunnel, the activity
# itself) and Ctrl+A, Delete or Enter can destroy work in any other program.
#
# These helpers let a cycle script send keys only while the expected window holds
# the foreground. Dot-source this file; if it is missing, callers must treat that
# as "do not type". Nothing in this file ever sends a key while focus is unproven.

# The scheduler loop is long-lived and keeps whatever type it loaded first, so a
# changed definition needs a new type name to take effect without a restart.
if (-not ('PhantomFocus.User32' -as [type])) {
    Add-Type -Namespace PhantomFocus -Name User32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int maxCount);
'@
}

# Process names that count as "the browser" for the browser-based phases
$script:PhantomBrowserNames = @("msedge", "chrome", "firefox", "opera", "brave", "browser", "vivaldi")

function Get-ForegroundProcessId {
    $hwnd = [PhantomFocus.User32]::GetForegroundWindow()
    if ($hwnd -eq [IntPtr]::Zero) { return 0 }
    $fgPid = [uint32]0
    [void][PhantomFocus.User32]::GetWindowThreadProcessId($hwnd, [ref]$fgPid)
    return [int]$fgPid
}

function Get-ForegroundWindowTitle {
    $hwnd = [PhantomFocus.User32]::GetForegroundWindow()
    if ($hwnd -eq [IntPtr]::Zero) { return "" }
    $sb = New-Object System.Text.StringBuilder 512
    [void][PhantomFocus.User32]::GetWindowText($hwnd, $sb, $sb.Capacity)
    return $sb.ToString()
}

function Test-ForegroundOwnedBy {
    param([int[]]$ProcessIds)
    if (-not $ProcessIds -or $ProcessIds.Count -eq 0) { return $false }
    return ($ProcessIds -contains (Get-ForegroundProcessId))
}

function Test-ForegroundBrowserTitle {
    # True only if the foreground window belongs to a browser AND its title (the
    # active tab) matches one of the patterns. A browser alone is not enough: it
    # may be the user's own window showing an unrelated page.
    param([string[]]$TitleLike)
    $fgPid = Get-ForegroundProcessId
    if ($fgPid -eq 0) { return $false }
    $proc = Get-Process -Id $fgPid -ErrorAction SilentlyContinue
    if (-not $proc -or $script:PhantomBrowserNames -notcontains $proc.ProcessName.ToLower()) { return $false }
    $title = Get-ForegroundWindowTitle
    foreach ($pattern in $TitleLike) {
        if ($title -like $pattern) { return $true }
    }
    return $false
}

function Get-IsolatedCodeProcessIds {
    param([string]$Marker = ".vscode-cycle-isolated")
    return @(Get-CimInstance Win32_Process -Filter "Name='Code.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*$Marker*" } |
        ForEach-Object { [int]$_.ProcessId })
}

function Get-ProcessMainWindow {
    param([int[]]$ProcessIds)
    foreach ($id in $ProcessIds) {
        $p = Get-Process -Id $id -ErrorAction SilentlyContinue
        if ($p -and $p.MainWindowHandle -ne [IntPtr]::Zero) { return $p.MainWindowHandle }
    }
    return [IntPtr]::Zero
}

function Wait-IsolatedCodeWindow {
    # Returns the isolated VS Code process ids once one of them has a window,
    # or an empty list if no window appears in time.
    param(
        [string]$Marker = ".vscode-cycle-isolated",
        [int]$TimeoutSeconds = 25
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $ids = Get-IsolatedCodeProcessIds -Marker $Marker
        if ($ids.Count -gt 0 -and (Get-ProcessMainWindow $ids) -ne [IntPtr]::Zero) { return $ids }
        Start-Sleep -Milliseconds 500
    }
    return @()
}

function Request-WindowFocus {
    # Asks Windows to bring the main window of one of the given processes to the
    # foreground. Returns $true only if one of them owns the foreground afterwards.
    #
    # No key is sent to win the focus. The usual trick (tap Alt first) would hit
    # the window that is in front right now, which is exactly the window we must
    # not type into. If Windows refuses, the caller simply skips its keys.
    param([int[]]$ProcessIds)

    if (Test-ForegroundOwnedBy $ProcessIds) { return $true }

    $hwnd = Get-ProcessMainWindow $ProcessIds
    if ($hwnd -eq [IntPtr]::Zero) { return $false }

    if ([PhantomFocus.User32]::IsIconic($hwnd)) {
        [void][PhantomFocus.User32]::ShowWindow($hwnd, 9)  # SW_RESTORE
    }
    [void][PhantomFocus.User32]::SetForegroundWindow($hwnd)

    Start-Sleep -Milliseconds 300
    return (Test-ForegroundOwnedBy $ProcessIds)
}

function Send-KeysToBrowser {
    # Sends SendKeys strings one at a time and re-checks before every one that a
    # matching browser tab is still in front. Stops and returns $false as soon as
    # it is not, so a focus change mid-way cannot redirect the remaining keys.
    param(
        [string[]]$Keys,
        [string[]]$TitleLike,
        [int]$DelayMs = 200
    )
    foreach ($k in $Keys) {
        if (-not (Test-ForegroundBrowserTitle -TitleLike $TitleLike)) { return $false }
        [System.Windows.Forms.SendKeys]::SendWait($k)
        Start-Sleep -Milliseconds $DelayMs
    }
    return $true
}
