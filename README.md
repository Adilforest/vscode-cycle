# VS Code Cycle — Автоматизированный цикл открытия/закрытия VS Code

Программа автоматически открывает и закрывает изолированный экземпляр VS Code по расписанию, с отслеживанием активности в Manic Time.

## Функционал

- ✅ Автоматический цикл открытия/закрытия VS Code по расписанию
- ✅ Проверка рабочих часов, обеденного перерыва, дней недели
- ✅ Трей-иконка с быстрым управлением (включить/выключить)
- ✅ Логирование всех операций
- ✅ Интеграция с Manic Time (регулярная регистрация активности)
- ✅ Настраиваемые параметры через GUI
- ✅ Изолированный профиль VS Code (не влияет на основной)

## Требования

- Windows 10/11
- PowerShell 5.0+
- VS Code (установлен в `C:\Users\<YourUsername>\AppData\Local\Programs\Microsoft VS Code\Code.exe`)
- Manic Time (опционально, но рекомендуется)

## Установка

### 1. Клонируй репозиторий

```bash
git clone https://github.com/<YOUR_USERNAME>/vscode-cycle.git
cd vscode-cycle
```

### 2. Обнови пути в скриптах

Все пути жестко закодированы под пользователя `RoboSoft`. Замени их на свои:

**Файл `vscode-cycle-tray.ps1`:**
```powershell
# Строка 4: Измени путь на свой
$scriptsDir = "C:\Users\<YourUsername>\Scripts\vscode-cycle"

# Строка 8: Проверь путь к VS Code (может отличаться)
$codeExe = "C:\Users\<YourUsername>\AppData\Local\Programs\Microsoft VS Code\Code.exe"
```

**Файл `vscode-cycle.ps1` (основной цикл):**
- Замени все `C:\Users\RoboSoft` на `C:\Users\<YourUsername>`

### 3. Скопируй файлы на свой компьютер

```bash
# Скопируй все файлы в папку Scripts
Copy-Item -Path ".\*" -Destination "C:\Users\<YourUsername>\Scripts\vscode-cycle" -Recurse
```

### 4. Разреши выполнение скриптов PowerShell (если потребуется)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Использование

### Запуск вручную (для теста)

1. Открой PowerShell (администратор не требуется)
2. Выполни:
```powershell
C:\Users\<YourUsername>\Scripts\vscode-cycle\vscode-cycle-tray-launcher.vbs
```

Должна появиться иконка VS Code в трее.

### Автозапуск при старте Windows

#### Способ 1: Автозапуск (рекомендуется)

1. Нажми `Win + R`, введи `shell:startup`
2. Создай ярлык (`Создать ярлык...` или скопируй готовый):
   - **Целевой объект:** `wscript.exe "C:\Users\<YourUsername>\Scripts\vscode-cycle\vscode-cycle-tray-launcher.vbs"`
   - **Имя:** `VSCodeCycleTray`

#### Способ 2: Task Scheduler (опциональный цикл)

Если нужно чтобы цикл запускался по расписанию (например, каждые 15 минут):

1. Открой `Task Scheduler` (Планировщик задач)
2. `Создать задачу` → введи имя `VSCodeCycle`
3. **Триггер:** `Повторять каждые 15 минут` (или нужный интервал)
4. **Действие:** `Запустить программу`
   - **Программа:** `powershell.exe`
   - **Аргументы:** `-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\<YourUsername>\Scripts\vscode-cycle\vscode-cycle.ps1"`

### Настройки

1. Щелкни правой кнопкой на иконке в трее → **Настройки...**
2. Или дважды щелкни на иконке
3. Установи:
   - **Рабочие часы** (например, 09:00 — 18:00)
   - **Обеденный перерыв** (например, 12:30 — 13:30)
   - **Рабочие дни** (ПН-ПТ)
   - **Интервал цикла** (в минутах)
   - **Включено/Выключено**

Настройки сохраняются в `vscode-cycle.config.json`.

## Файлы

| Файл | Назначение |
|------|-----------|
| `vscode-cycle-tray.ps1` | Главный трей-апп (иконка, меню, таймеры) |
| `vscode-cycle-tray-launcher.vbs` | Невидимый лаунчер (запускает трей без консоли) |
| `vscode-cycle.ps1` | Скрипт цикла (открывает/закрывает VS Code) |
| `vscode-cycle-settings.ps1` | GUI окно настроек |
| `vscode-cycle.config.json` | Файл конфигурации |
| `vscode-cycle.log` | Лог всех операций |
| `.vscode-cycle-isolated/` | Папка с изолированным профилем VS Code |

## Логирование

Все операции записываются в `vscode-cycle.log`:
```
2026-10-20 09:15:23 - Открытие VS Code
2026-10-20 09:16:45 - Закрытие VS Code
```

Чтобы просмотреть лог, щелкни на трее → **Открыть лог**.

## Интеграция с Manic Time

Программа автоматически регистрирует активность каждые 30 секунд, чтобы Manic Time не считал тебя неактивным во время выполнения скрипта.

**Это происходит автоматически** — не нужно ничего настраивать.

## Решение проблем

### Иконка не появилась в трее

1. Проверь, запущена ли PowerShell (ищи процесс `powershell.exe` в Диспетчере задач)
2. Откройте PowerShell и выполнить:
   ```powershell
   & "C:\Users\<YourUsername>\Scripts\vscode-cycle\vscode-cycle-tray.ps1"
   ```
   Это покажет ошибки (если они есть)

### VS Code не открывается

1. Проверь путь к `Code.exe` в `vscode-cycle-tray.ps1` (строка 8)
2. Убедись, что VS Code установлен

### Скрипт не выполняется

1. Убедись, что PowerShell разрешает выполнение скриптов:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## Для коллег

Просто следуй инструкции в разделе **Установка** и замени пути на свои. Всё остальное работает автоматически.

## Лицензия

MIT

## Автор

Adil Ormanov (adil.ormanov@robosoft.kz)
