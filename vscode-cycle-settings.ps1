Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$username = $env:USERNAME
$configFile = "C:\Users\$username\Scripts\vscode-cycle.config.json"

$defaults = [PSCustomObject]@{
    ActiveStartHour          = 8
    ActiveStartMinuteMin     = 25
    ActiveStartMinuteMax     = 48
    ActiveEndHour            = 18
    ActiveEndMinuteMin       = 58
    ActiveEndMinuteMax       = 0
    LunchStartHour           = 13
    LunchStartMinuteMin      = 0
    LunchStartMinuteMax      = 14
    LunchEndHour             = 13
    LunchEndMinuteMin        = 30
    LunchEndMinuteMax        = 35
    ActiveDays               = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
    StayOpenSeconds          = 45
    IntervalMinutes          = 2
}

$cfg = $defaults
if (Test-Path $configFile) {
    try {
        $loaded = Get-Content -Path $configFile -Raw | ConvertFrom-Json
        foreach ($prop in $defaults.PSObject.Properties) {
            if ($null -ne $loaded.$($prop.Name)) {
                $cfg | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $loaded.$($prop.Name) -Force
            }
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Не удалось прочитать конфиг, загружены значения по умолчанию.`n$_", "Внимание", "OK", "Warning") | Out-Null
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "VS Code Cycle - Настройки"
$form.Size = New-Object System.Drawing.Size(500, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

function New-Label($text, $x, $y, $w = 160) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $text
    $lbl.Location = New-Object System.Drawing.Point($x, $y)
    $lbl.Size = New-Object System.Drawing.Size($w, 20)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    return $lbl
}

function New-Numeric($min, $max, $value, $x, $y, $w = 50) {
    $num = New-Object System.Windows.Forms.NumericUpDown
    $num.Minimum = $min
    $num.Maximum = $max
    $num.Value = $value
    $num.Location = New-Object System.Drawing.Point($x, $y)
    $num.Size = New-Object System.Drawing.Size($w, 20)
    return $num
}

$y = 15

# --- НАЧАЛО РАБОЧЕГО ДНЯ (РАНДОМИЗИРОВАНО) ---
$form.Controls.Add((New-Label "📅 НАЧАЛО РАБОЧЕГО ДНЯ:" 15 $y 300))
$y += 25

$form.Controls.Add((New-Label "Час:" 25 $y 40))
$numWorkStartHour = New-Numeric 0 23 $cfg.ActiveStartHour 70 ($y - 2)
$form.Controls.Add($numWorkStartHour)

$form.Controls.Add((New-Label "Минут от:" 180 $y 60))
$numWorkStartMinMin = New-Numeric 0 59 $cfg.ActiveStartMinuteMin 245 ($y - 2)
$form.Controls.Add($numWorkStartMinMin)

$form.Controls.Add((New-Label "до:" 325 $y 30))
$numWorkStartMinMax = New-Numeric 0 59 $cfg.ActiveStartMinuteMax 365 ($y - 2)
$form.Controls.Add($numWorkStartMinMax)
$form.Controls.Add((New-Label "(рандомно)" 425 $y 60))

$y += 35

# --- КОНЕЦ РАБОЧЕГО ДНЯ (РАНДОМИЗИРОВАНО) ---
$form.Controls.Add((New-Label "🌆 КОНЕЦ РАБОЧЕГО ДНЯ:" 15 $y 300))
$y += 25

$form.Controls.Add((New-Label "Час:" 25 $y 40))
$numWorkEndHour = New-Numeric 0 23 $cfg.ActiveEndHour 70 ($y - 2)
$form.Controls.Add($numWorkEndHour)

$form.Controls.Add((New-Label "Минут от:" 180 $y 60))
$numWorkEndMinMin = New-Numeric 0 59 $cfg.ActiveEndMinuteMin 245 ($y - 2)
$form.Controls.Add($numWorkEndMinMin)

$form.Controls.Add((New-Label "до:" 325 $y 30))
$numWorkEndMinMax = New-Numeric 0 59 $cfg.ActiveEndMinuteMax 365 ($y - 2)
$form.Controls.Add($numWorkEndMinMax)
$form.Controls.Add((New-Label "(рандомно)" 425 $y 60))

$y += 35

# --- НАЧАЛО ОБЕДА (РАНДОМИЗИРОВАНО) ---
$form.Controls.Add((New-Label "🍽️  НАЧАЛО ОБЕДА:" 15 $y 300))
$y += 25

$form.Controls.Add((New-Label "Час:" 25 $y 40))
$numLunchStartHour = New-Numeric 0 23 $cfg.LunchStartHour 70 ($y - 2)
$form.Controls.Add($numLunchStartHour)

$form.Controls.Add((New-Label "Минут от:" 180 $y 60))
$numLunchStartMinMin = New-Numeric 0 59 $cfg.LunchStartMinuteMin 245 ($y - 2)
$form.Controls.Add($numLunchStartMinMin)

$form.Controls.Add((New-Label "до:" 325 $y 30))
$numLunchStartMinMax = New-Numeric 0 59 $cfg.LunchStartMinuteMax 365 ($y - 2)
$form.Controls.Add($numLunchStartMinMax)
$form.Controls.Add((New-Label "(рандомно)" 425 $y 60))

$y += 35

# --- КОНЕЦ ОБЕДА (РАНДОМИЗИРОВАНО) ---
$form.Controls.Add((New-Label "⏰ КОНЕЦ ОБЕДА:" 15 $y 300))
$y += 25

$form.Controls.Add((New-Label "Час:" 25 $y 40))
$numLunchEndHour = New-Numeric 0 23 $cfg.LunchEndHour 70 ($y - 2)
$form.Controls.Add($numLunchEndHour)

$form.Controls.Add((New-Label "Минут от:" 180 $y 60))
$numLunchEndMinMin = New-Numeric 0 59 $cfg.LunchEndMinuteMin 245 ($y - 2)
$form.Controls.Add($numLunchEndMinMin)

$form.Controls.Add((New-Label "до:" 325 $y 30))
$numLunchEndMinMax = New-Numeric 0 59 $cfg.LunchEndMinuteMax 365 ($y - 2)
$form.Controls.Add($numLunchEndMinMax)
$form.Controls.Add((New-Label "(рандомно)" 425 $y 60))

$y += 35

# --- Дни недели ---
$form.Controls.Add((New-Label "📆 Активные дни недели:" 15 $y 200))
$dayNames = @(
    @{ Key = "Monday"; Label = "Понедельник" },
    @{ Key = "Tuesday"; Label = "Вторник" },
    @{ Key = "Wednesday"; Label = "Среда" },
    @{ Key = "Thursday"; Label = "Четверг" },
    @{ Key = "Friday"; Label = "Пятница" },
    @{ Key = "Saturday"; Label = "Суббота" },
    @{ Key = "Sunday"; Label = "Воскресенье" }
)
$dayChecks = @{}
$y += 25
foreach ($d in $dayNames) {
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = $d.Label
    $chk.Location = New-Object System.Drawing.Point(35, $y)
    $chk.Size = New-Object System.Drawing.Size(150, 20)
    $chk.Checked = $cfg.ActiveDays -contains $d.Key
    $form.Controls.Add($chk)
    $dayChecks[$d.Key] = $chk
    $y += 22
}

$y += 5

# --- Длительность открытого окна ---
$form.Controls.Add((New-Label "⏱️  Держать VS Code открытым (сек):" 15 $y 250))
$numStayOpen = New-Numeric 5 600 $cfg.StayOpenSeconds 280 ($y - 2) 60
$form.Controls.Add($numStayOpen)

$y += 35

# --- Периодичность ---
$form.Controls.Add((New-Label "🔄 Открывать VS Code каждые (мин):" 15 $y 250))
$numInterval = New-Numeric 1 120 $cfg.IntervalMinutes 280 ($y - 2) 60
$form.Controls.Add($numInterval)

$y += 50

# --- Кнопки ---
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Сохранить"
$btnSave.Location = New-Object System.Drawing.Point(180, $y)
$btnSave.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($btnSave)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Отмена"
$btnCancel.Location = New-Object System.Drawing.Point(290, $y)
$btnCancel.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($btnCancel)

$form.Height = $y + 90

$btnCancel.Add_Click({ $form.Close() })

$btnSave.Add_Click({
    if ($numWorkStartHour.Value -ge $numWorkEndHour.Value) {
        [System.Windows.Forms.MessageBox]::Show("Час начала должен быть раньше часа окончания.", "Ошибка", "OK", "Error") | Out-Null
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
        ActiveStartHour          = [int]$numWorkStartHour.Value
        ActiveStartMinuteMin     = [int]$numWorkStartMinMin.Value
        ActiveStartMinuteMax     = [int]$numWorkStartMinMax.Value
        ActiveEndHour            = [int]$numWorkEndHour.Value
        ActiveEndMinuteMin       = [int]$numWorkEndMinMin.Value
        ActiveEndMinuteMax       = [int]$numWorkEndMinMax.Value
        LunchStartHour           = [int]$numLunchStartHour.Value
        LunchStartMinuteMin      = [int]$numLunchStartMinMin.Value
        LunchStartMinuteMax      = [int]$numLunchStartMinMax.Value
        LunchEndHour             = [int]$numLunchEndHour.Value
        LunchEndMinuteMin        = [int]$numLunchEndMinMin.Value
        LunchEndMinuteMax        = [int]$numLunchEndMinMax.Value
        ActiveDays               = $selectedDays
        StayOpenSeconds          = [int]$numStayOpen.Value
        IntervalMinutes          = [int]$numInterval.Value
    }

    # Merge into the existing file instead of replacing it: this dialog does not
    # edit Enabled, Holidays or Description, and overwriting dropped them (a
    # missing Enabled even read as "off" in the scheduler loop).
    $merged = $null
    if (Test-Path $configFile) {
        try { $merged = Get-Content -Path $configFile -Raw | ConvertFrom-Json } catch { $merged = $null }
    }
    if ($merged) {
        foreach ($p in $newCfg.PSObject.Properties) {
            if ($merged.PSObject.Properties.Name -contains $p.Name) {
                $merged.($p.Name) = $p.Value
            } else {
                $merged | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
            }
        }
    } else {
        $merged = $newCfg
    }
    $merged | ConvertTo-Json | Set-Content -Path $configFile -Encoding UTF8

    [System.Windows.Forms.MessageBox]::Show("Настройки сохранены.`n`nНовые рандомизированные интервалы:
- Начало дня: $([int]$numWorkStartHour.Value):$([int]$numWorkStartMinMin.Value)-$([int]$numWorkStartMinMax.Value)
- Конец дня: $([int]$numWorkEndHour.Value):$([int]$numWorkEndMinMin.Value)-$([int]$numWorkEndMinMax.Value)
- Обед: $([int]$numLunchStartHour.Value):$([int]$numLunchStartMinMin.Value)-$([int]$numLunchStartMinMax.Value) ~ $([int]$numLunchEndHour.Value):$([int]$numLunchEndMinMin.Value)-$([int]$numLunchEndMinMax.Value)", "Готово", "OK", "Information") | Out-Null
    $form.Close()
})

[void]$form.ShowDialog()
