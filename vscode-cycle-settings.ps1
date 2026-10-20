Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$configFile = "C:\Users\RoboSoft\Scripts\vscode-cycle.config.json"

$defaults = [PSCustomObject]@{
    ActiveStartHour  = 8
    ActiveEndHour    = 20
    LunchStartHour   = 13
    LunchStartMinute = 0
    LunchEndHour     = 13
    LunchEndMinute   = 30
    ActiveDays       = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
    StayOpenSeconds  = 45
    IntervalMinutes  = 2
}

$cfg = $defaults
if (Test-Path $configFile) {
    try {
        $loaded = Get-Content -Path $configFile -Raw | ConvertFrom-Json
        $cfg = [PSCustomObject]@{
            ActiveStartHour  = if ($null -ne $loaded.ActiveStartHour) { $loaded.ActiveStartHour } else { $defaults.ActiveStartHour }
            ActiveEndHour    = if ($null -ne $loaded.ActiveEndHour) { $loaded.ActiveEndHour } else { $defaults.ActiveEndHour }
            LunchStartHour   = if ($null -ne $loaded.LunchStartHour) { $loaded.LunchStartHour } else { $defaults.LunchStartHour }
            LunchStartMinute = if ($null -ne $loaded.LunchStartMinute) { $loaded.LunchStartMinute } else { $defaults.LunchStartMinute }
            LunchEndHour     = if ($null -ne $loaded.LunchEndHour) { $loaded.LunchEndHour } else { $defaults.LunchEndHour }
            LunchEndMinute   = if ($null -ne $loaded.LunchEndMinute) { $loaded.LunchEndMinute } else { $defaults.LunchEndMinute }
            ActiveDays       = if ($null -ne $loaded.ActiveDays) { @($loaded.ActiveDays) } else { $defaults.ActiveDays }
            StayOpenSeconds  = if ($null -ne $loaded.StayOpenSeconds) { $loaded.StayOpenSeconds } else { $defaults.StayOpenSeconds }
            IntervalMinutes  = if ($null -ne $loaded.IntervalMinutes) { $loaded.IntervalMinutes } else { $defaults.IntervalMinutes }
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Не удалось прочитать конфиг, загружены значения по умолчанию.`n$_", "Внимание", "OK", "Warning") | Out-Null
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "VS Code Cycle - Настройки"
$form.Size = New-Object System.Drawing.Size(380, 460)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

function New-Label($text, $x, $y, $w = 160) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $text
    $lbl.Location = New-Object System.Drawing.Point($x, $y)
    $lbl.Size = New-Object System.Drawing.Size($w, 20)
    return $lbl
}

function New-Numeric($min, $max, $value, $x, $y, $w = 60) {
    $num = New-Object System.Windows.Forms.NumericUpDown
    $num.Minimum = $min
    $num.Maximum = $max
    $num.Value = $value
    $num.Location = New-Object System.Drawing.Point($x, $y)
    $num.Size = New-Object System.Drawing.Size($w, 20)
    return $num
}

# --- Рабочие часы ---
$form.Controls.Add((New-Label "Рабочие часы, с:" 15 20 100))
$numStartHour = New-Numeric 0 23 $cfg.ActiveStartHour 120 18
$form.Controls.Add($numStartHour)
$form.Controls.Add((New-Label "до:" 190 20 30))
$numEndHour = New-Numeric 0 23 $cfg.ActiveEndHour 220 18
$form.Controls.Add($numEndHour)
$form.Controls.Add((New-Label "(часы, 0-23)" 290 20 80))

# --- Обед ---
$form.Controls.Add((New-Label "Обед, с:" 15 55 100))
$numLunchStartH = New-Numeric 0 23 $cfg.LunchStartHour 120 53 40
$form.Controls.Add($numLunchStartH)
$form.Controls.Add((New-Label ":" 163 55 10))
$numLunchStartM = New-Numeric 0 59 $cfg.LunchStartMinute 175 53 40
$form.Controls.Add($numLunchStartM)

$form.Controls.Add((New-Label "до:" 15 85 100))
$numLunchEndH = New-Numeric 0 23 $cfg.LunchEndHour 120 83 40
$form.Controls.Add($numLunchEndH)
$form.Controls.Add((New-Label ":" 163 85 10))
$numLunchEndM = New-Numeric 0 59 $cfg.LunchEndMinute 175 83 40
$form.Controls.Add($numLunchEndM)

# --- Дни недели ---
$form.Controls.Add((New-Label "Активные дни недели:" 15 125 200))
$dayNames = @(
    @{ Key = "Monday"; Label = "Понедельник" },
    @{ Key = "Tuesday"; Label = "Вторник" },
    @{ Key = "Wednesday"; Label = "Среда" },
    @{ Key = "Thursday"; Label = "Четверг" },
    @{ Key = "Friday"; Label = "Пятница" },
    @{ Key = "Saturday"; Label = "Субота" },
    @{ Key = "Sunday"; Label = "Воскресенье" }
)
$dayChecks = @{}
$y = 150
foreach ($d in $dayNames) {
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = $d.Label
    $chk.Location = New-Object System.Drawing.Point(25, $y)
    $chk.Size = New-Object System.Drawing.Size(180, 20)
    $chk.Checked = $cfg.ActiveDays -contains $d.Key
    $form.Controls.Add($chk)
    $dayChecks[$d.Key] = $chk
    $y += 24
}

# --- Длительность открытого окна ---
$form.Controls.Add((New-Label "Держать VS Code открытым (сек):" 15 ($y + 10) 230))
$numStayOpen = New-Numeric 5 600 $cfg.StayOpenSeconds 250 ($y + 8) 60
$form.Controls.Add($numStayOpen)

# --- Периодичность открытий ---
$form.Controls.Add((New-Label "Открывать VS Code каждые (мин):" 15 ($y + 40) 230))
$numInterval = New-Numeric 1 120 $cfg.IntervalMinutes 250 ($y + 38) 60
$form.Controls.Add($numInterval)

# --- Кнопки ---
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Сохранить"
$btnSave.Location = New-Object System.Drawing.Point(140, ($y + 80))
$btnSave.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($btnSave)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Отмена"
$btnCancel.Location = New-Object System.Drawing.Point(250, ($y + 80))
$btnCancel.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($btnCancel)

$form.Height = $y + 160

$btnCancel.Add_Click({ $form.Close() })

$btnSave.Add_Click({
    if ($numStartHour.Value -ge $numEndHour.Value) {
        [System.Windows.Forms.MessageBox]::Show("Час начала должен быть меньше часа окончания.", "Ошибка", "OK", "Error") | Out-Null
        return
    }

    $selectedDays = @()
    foreach ($key in $dayChecks.Keys) {
        if ($dayChecks[$key].Checked) { $selectedDays += $key }
    }
    if ($selectedDays.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Выберите хотя бы один рабочий день.", "Ошибка", "OK", "Error") | Out-Null
        return
    }

    $newCfg = [PSCustomObject]@{
        ActiveStartHour  = [int]$numStartHour.Value
        ActiveEndHour    = [int]$numEndHour.Value
        LunchStartHour   = [int]$numLunchStartH.Value
        LunchStartMinute = [int]$numLunchStartM.Value
        LunchEndHour     = [int]$numLunchEndH.Value
        LunchEndMinute   = [int]$numLunchEndM.Value
        ActiveDays       = $selectedDays
        StayOpenSeconds  = [int]$numStayOpen.Value
        IntervalMinutes  = [int]$numInterval.Value
    }

    $newCfg | ConvertTo-Json | Set-Content -Path $configFile -Encoding UTF8

    $taskWarning = $null
    try {
        $startHour = [int]$numStartHour.Value
        $durationHours = [int]$numEndHour.Value - $startHour
        $trigger = New-ScheduledTaskTrigger -Daily -At ("{0:00}:00" -f $startHour)
        $repetition = New-CimInstance -ClassName MSFT_TaskRepetitionPattern -Namespace "Root/Microsoft/Windows/TaskScheduler" -ClientOnly -Property @{
            Interval          = "PT$($newCfg.IntervalMinutes)M"
            Duration          = "PT${durationHours}H"
            StopAtDurationEnd = $true
        }
        $trigger.Repetition = $repetition
        Set-ScheduledTask -TaskName "VSCodeCycle" -Trigger $trigger | Out-Null
    } catch {
        $taskWarning = $_.Exception.Message
    }

    if ($taskWarning) {
        [System.Windows.Forms.MessageBox]::Show("Настройки сохранены, но не удалось обновить задачу планировщика:`n$taskWarning", "Готово (с предупреждением)", "OK", "Warning") | Out-Null
    } else {
        [System.Windows.Forms.MessageBox]::Show("Настройки сохранены.", "Готово", "OK", "Information") | Out-Null
    }
    $form.Close()
})

[void]$form.ShowDialog()
