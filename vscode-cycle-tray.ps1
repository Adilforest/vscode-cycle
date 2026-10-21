Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptsDir = "C:\Users\RoboSoft\Scripts"
$settingsScript = Join-Path $scriptsDir "vscode-cycle-settings.ps1"
$logFile = Join-Path $scriptsDir "vscode-cycle.log"
$configFile = Join-Path $scriptsDir "vscode-cycle.config.json"
$codeExe = "C:\Users\RoboSoft\AppData\Local\Programs\Microsoft VS Code\Code.exe"

# Prevent multiple tray instances.
$mutex = New-Object System.Threading.Mutex($false, "VSCodeCycleTray_SingleInstance")
if (-not $mutex.WaitOne(0)) {
    exit 0
}

function Open-Settings {
    # WScript.Shell.Run with window style 0 guarantees no console flash at all,
    # unlike Start-Process -WindowStyle Hidden which can still blip under some
    # default-terminal configurations.
    $wsh = New-Object -ComObject WScript.Shell
    $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$settingsScript`""
    $wsh.Run($cmd, 0, $false) | Out-Null
}

function Open-Log {
    if (Test-Path $logFile) {
        Start-Process -FilePath "notepad.exe" -ArgumentList "`"$logFile`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("Лог-файл пока пуст.", "VS Code Cycle", "OK", "Information") | Out-Null
    }
}

function Get-AppConfig {
    if (Test-Path $configFile) {
        try { return Get-Content -Path $configFile -Raw | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

function Set-AppEnabled([bool]$value) {
    $cfgObj = Get-AppConfig
    if ($null -eq $cfgObj) {
        $cfgObj = [PSCustomObject]@{}
    }
    if ($cfgObj.PSObject.Properties.Name -contains "Enabled") {
        $cfgObj.Enabled = $value
    } else {
        $cfgObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $value -Force
    }
    $cfgObj | ConvertTo-Json | Set-Content -Path $configFile -Encoding UTF8
}

function Get-AppEnabled {
    $cfgObj = Get-AppConfig
    if ($null -ne $cfgObj -and $cfgObj.PSObject.Properties.Name -contains "Enabled") {
        return [bool]$cfgObj.Enabled
    }
    return $true
}

# Make sure tray icons stay always visible instead of being collapsed into the
# overflow flyout (affects all tray icons, this is the only supported switch).
function Ensure-TrayIconsAlwaysVisible {
    $advKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    try {
        $current = (Get-ItemProperty -Path $advKey -Name "EnableAutoTray" -ErrorAction SilentlyContinue).EnableAutoTray
        if ($current -ne 0) {
            Set-ItemProperty -Path $advKey -Name "EnableAutoTray" -Value 0 -Type DWord
            Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
                Start-Process "explorer.exe"
            }
        }
    } catch {
        # Non-fatal: if this fails, the user can still pin the icon manually via
        # taskbar settings / dragging it out of the overflow area.
    }
}

Ensure-TrayIconsAlwaysVisible

$icon = $null
if (Test-Path $codeExe) {
    try { $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($codeExe) } catch { $icon = $null }
}
if (-not $icon) { $icon = [System.Drawing.SystemIcons]::Application }

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = $icon
$notifyIcon.Visible = $true

$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$itemToggle = New-Object System.Windows.Forms.ToolStripMenuItem

function Update-ToggleState {
    $enabled = Get-AppEnabled
    if ($enabled) {
        $itemToggle.Text = "Выключить"
        $notifyIcon.Text = "VS Code Cycle (включено)"
    } else {
        $itemToggle.Text = "Включить"
        $notifyIcon.Text = "VS Code Cycle (выключено)"
    }
}

$itemToggle.Add_Click({
    $newState = -not (Get-AppEnabled)
    Set-AppEnabled $newState
    Update-ToggleState
})
$contextMenu.Items.Add($itemToggle) | Out-Null

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$itemSettings = New-Object System.Windows.Forms.ToolStripMenuItem("Настройки...")
$itemSettings.Add_Click({ Open-Settings })
$contextMenu.Items.Add($itemSettings) | Out-Null

$itemLog = New-Object System.Windows.Forms.ToolStripMenuItem("Открыть лог")
$itemLog.Add_Click({ Open-Log })
$contextMenu.Items.Add($itemLog) | Out-Null

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$itemExit = New-Object System.Windows.Forms.ToolStripMenuItem("Выход")
$appContext = New-Object System.Windows.Forms.ApplicationContext
$itemExit.Add_Click({
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    $mutex.ReleaseMutex()
    $appContext.ExitThread()
})
$contextMenu.Items.Add($itemExit) | Out-Null

Update-ToggleState

# Функция для регистрации активности в Manic Time
# Использует P/Invoke для вызова Windows API эмуляции ввода
$pinvokeCode = @'
[DllImport("user32.dll", SetLastError = true)]
public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, IntPtr dwExtraInfo);

[DllImport("user32.dll", SetLastError = true)]
public static extern bool keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);

public const uint MOUSEEVENTF_MOVE = 0x0001;
public const uint MOUSEEVENTF_WHEEL = 0x0800;
public const uint KEYEVENTF_KEYUP = 2;
'@

try {
    Add-Type -MemberDefinition $pinvokeCode -Name "NativeMethods" -Namespace "Win32"
    $nativeMethodsExists = $true
} catch {
    $nativeMethodsExists = $false
}

function Register-Activity {
    if ($nativeMethodsExists) {
        try {
            # Случайный выбор типа активности для реалистичности
            $activityType = Get-Random -Minimum 0 -Maximum 3

            switch ($activityType) {
                0 {
                    # Микродвижение мыши в разные стороны
                    $moveX = Get-Random -Minimum -5 -Maximum 5
                    $moveY = Get-Random -Minimum -5 -Maximum 5
                    [Win32.NativeMethods]::mouse_event(1, $moveX, $moveY, 0, [IntPtr]::Zero)
                }
                1 {
                    # Имитация скролла колёсика мыши (вверх или вниз)
                    $scrollDir = if ((Get-Random -Minimum 0 -Maximum 2) -eq 0) { 1 } else { -1 }
                    [Win32.NativeMethods]::mouse_event(0x0800, 0, 0, 120 * $scrollDir, [IntPtr]::Zero)
                }
                2 {
                    # Нажатие нейтральной клавиши (Shift - самая безопасная)
                    [Win32.NativeMethods]::keybd_event(0x10, 0, 0, [IntPtr]::Zero) # Shift down
                    Start-Sleep -Milliseconds 10
                    [Win32.NativeMethods]::keybd_event(0x10, 0, 2, [IntPtr]::Zero) # Shift up
                }
            }
        } catch {
            # Fallback: нейтральное нажатие клавиши
            try {
                [System.Windows.Forms.SendKeys]::SendWait("{SHIFT}")
            } catch { }
        }
    }
}

# Таймер для постоянной регистрации активности (каждые 10 секунд - чаще для надежности Manic Time)
$activityTimer = New-Object System.Windows.Forms.Timer
$activityTimer.Interval = 10000 # 10 секунд (увеличено с 30 для более частой регистрации)
$activityTimer.Add_Tick({ Register-Activity })
$activityTimer.Start()

$notifyIcon.ContextMenuStrip = $contextMenu
$notifyIcon.Add_MouseDoubleClick({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Open-Settings }
})

[System.Windows.Forms.Application]::Run($appContext)
