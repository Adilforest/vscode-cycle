# Quick launcher for phantom activity with custom settings

$username = $env:USERNAME
$scriptsDir = "C:\Users\$username\Scripts"

# Menu
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   VS Code Phantom Activity Launcher (EXTENDED)        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Проект: situation-centre-arm-backend" -ForegroundColor Green
Write-Host "Приложения: VS Code + Planfix + GitLab + Terminal" -ForegroundColor Green
Write-Host ""
Write-Host "Выбери опцию:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  📝 VS CODE ONLY:" -ForegroundColor Cyan
Write-Host "  [1] Быстро (30 сек)" -ForegroundColor White
Write-Host "  [2] Обычно (45 сек)" -ForegroundColor White
Write-Host "  [3] Долго (60 сек)" -ForegroundColor White
Write-Host "  [4] Очень долго (120 сек)" -ForegroundColor White
Write-Host ""
Write-Host "  🚀 РАСШИРЕННЫЙ (все приложения):" -ForegroundColor Cyan
Write-Host "  [5] Extended Cycle (VS Code + Planfix + GitLab + Terminal)" -ForegroundColor White
Write-Host ""
Write-Host "  ⚙️  УПРАВЛЕНИЕ:" -ForegroundColor Cyan
Write-Host "  [6] Трей-приложение" -ForegroundColor White
Write-Host "  [7] Открыть логи" -ForegroundColor White
Write-Host "  [8] Выход" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Введи номер"

switch ($choice) {
    1 {
        Write-Host "Запуск VS Code цикла на 30 секунд..." -ForegroundColor Green
        & "$scriptsDir\vscode-cycle.ps1" -StayOpenSeconds 30
    }
    2 {
        Write-Host "Запуск VS Code цикла на 45 секунд..." -ForegroundColor Green
        & "$scriptsDir\vscode-cycle.ps1" -StayOpenSeconds 45
    }
    3 {
        Write-Host "Запуск VS Code цикла на 60 секунд..." -ForegroundColor Green
        & "$scriptsDir\vscode-cycle.ps1" -StayOpenSeconds 60
    }
    4 {
        Write-Host "Запуск VS Code цикла на 120 секунд..." -ForegroundColor Green
        & "$scriptsDir\vscode-cycle.ps1" -StayOpenSeconds 120
    }
    5 {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║   🚀 РАСШИРЕННЫЙ ЦИКЛ (все приложения)               ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Запускаю:" -ForegroundColor Yellow
        Write-Host "  1. VS Code с проектом" -ForegroundColor White
        Write-Host "  2. Planfix Kanban board" -ForegroundColor White
        Write-Host "  3. GitLab репозиторий" -ForegroundColor White
        Write-Host "  4. Terminal с Git командами" -ForegroundColor White
        Write-Host ""
        & "$scriptsDir\vscode-cycle-extended.ps1" -StayOpenSeconds 45
        Write-Host ""
        Write-Host "✅ Расширенный цикл завершён!" -ForegroundColor Green
    }
    6 {
        Write-Host "Запуск трей-приложения..." -ForegroundColor Green
        $wsh = New-Object -ComObject WScript.Shell
        $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptsDir\vscode-cycle-tray.ps1`""
        $wsh.Run($cmd, 0, $false) | Out-Null
        Write-Host "Трей-приложение запущено" -ForegroundColor Green
    }
    7 {
        $logFile = "$scriptsDir\vscode-cycle.log"
        if (Test-Path $logFile) {
            & notepad.exe $logFile
        } else {
            Write-Host "Лог-файл не найден" -ForegroundColor Red
        }
    }
    8 {
        Write-Host "До свидания!" -ForegroundColor Cyan
        exit 0
    }
    default {
        Write-Host "Неверный выбор" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Готово!" -ForegroundColor Green
