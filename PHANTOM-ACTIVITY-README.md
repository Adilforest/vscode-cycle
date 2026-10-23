# VS Code Phantom Activity — Улучшенная версия

## ✨ Что нового?

Программа теперь:
✅ **Открывает реальный проект** — `situation-centre-arm-backend`  
✅ **Открывает файл** — `manage.py` (Django главный файл)  
✅ **Имитирует работу с кодом** — навигация, поиск, сохранение файлов  
✅ **Работает для любого пользователя** — динамические пути (не привязано к RoboSoft)  
✅ **Логирует все действия** — для отладки и проверки

## 🚀 Быстрый старт

### 1. Простой запуск (интерактивное меню)

```powershell
C:\Users\<YourUsername>\Scripts\phantom-activity.bat
```

Или через PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\<YourUsername>\Scripts\run-phantom-activity.ps1"
```

### 2. Прямой запуск цикла

**30 секунд:**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\<YourUsername>\Scripts\vscode-cycle.ps1" -StayOpenSeconds 30
```

**45 секунд:**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\<YourUsername>\Scripts\vscode-cycle.ps1" -StayOpenSeconds 45
```

**60 секунд:**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\<YourUsername>\Scripts\vscode-cycle.ps1" -StayOpenSeconds 60
```

### 3. Трей-приложение (автоматический цикл)

```powershell
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\<YourUsername>\Scripts\vscode-cycle-tray-launcher.vbs"
```

Или просто:
```powershell
C:\Users\<YourUsername>\Scripts\vscode-cycle-tray-launcher.vbs
```

## 📋 Функции

### Основной цикл (`vscode-cycle.ps1`)

Открывает VS Code с:
- Проект: `C:\Users\ГГГ\Desktop\situation-centre-arm-backend`
- Файл: `manage.py`
- Время открытия: Настраиваемое (по умолчанию 45 сек)

**Имитирует:**
- Навигацию по файлу (стрелки вверх/вниз)
- Открытие диалога поиска (Ctrl+F)
- Закрытие диалога (Escape)
- Сохранение файла (Ctrl+S)
- Различные движения курсора

### Трей-приложение (`vscode-cycle-tray.ps1`)

Работает в фоновом режиме и:
- Показывает иконку VS Code в трее
- Включить/выключить циклы кликом
- Открыть настройки
- Просмотреть логи
- Регистрирует активность каждые 10 секунд (для Manic Time)

## 📝 Логирование

Все события записываются в лог-файл:

```
C:\Users\<YourUsername>\Scripts\vscode-cycle.log
```

**Примеры записей:**
```
2026-10-22 15:42:08 - Starting isolated VS Code instance (hidden)...
2026-10-22 15:42:08 - Opening project: C:\Users\ГГГ\Desktop\situation-centre-arm-backend
2026-10-22 15:42:10 - Starting realistic code typing simulation...
2026-10-22 15:42:10 - Action: Navigate and select
2026-10-22 15:42:11 - Code typing simulation completed successfully
```

## ⚙️ Конфигурация

Файл конфига: `C:\Users\<YourUsername>\Scripts\vscode-cycle.config.json`

```json
{
  "Enabled": true,
  "ActiveStartHour": 8,
  "ActiveEndHour": 20,
  "LunchStartHour": 13,
  "LunchStartMinute": 0,
  "LunchEndHour": 13,
  "LunchEndMinute": 30,
  "ActiveDays": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
  "StayOpenSeconds": 45,
  "IntervalMinutes": 2
}
```

**Параметры:**
- `Enabled` — включено/выключено
- `ActiveStartHour` — начало рабочего дня (0-23)
- `ActiveEndHour` — конец рабочего дня (0-23)
- `LunchStartHour/Minute` — начало обеда
- `LunchEndHour/Minute` — конец обеда
- `ActiveDays` — дни недели для запуска
- `StayOpenSeconds` — сколько секунд держать VS Code открытым
- `IntervalMinutes` — интервал между циклами (для трея)

## 🔧 Автозапуск при старте Windows

### Способ 1: Через папку Автозагрузки

1. Нажми `Win + R`, введи: `shell:startup`
2. Создай ярлык в этой папке:
   ```
   Объект: powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\<YourUsername>\Scripts\vscode-cycle-tray-launcher.vbs"
   ```

### Способ 2: Task Scheduler (требует администратора)

1. Открой `Task Scheduler` (Планировщик задач)
2. `Create Task...` (Создать задачу)
3. **Общие:**
   - Имя: `VSCodePhantomActivity`
   - Галка: "Run with highest privileges"

4. **Триггеры:**
   - Add trigger: `At startup` (При запуске)

5. **Действия:**
   - Program: `powershell.exe`
   - Arguments: `-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\<YourUsername>\Scripts\vscode-cycle.ps1" -StayOpenSeconds 45`

## 🐛 Решение проблем

### VS Code не открывается
- Проверь путь к Code.exe в `vscode-cycle.ps1`
- VS Code должен быть установлен в стандартном месте

### Циклы не запускаются
- Проверь конфиг `vscode-cycle.config.json`
- Убедись, что это рабочий день и время в пределах `ActiveStartHour` — `ActiveEndHour`

### Скрипты не выполняются
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Трей-иконка не видна
- Проверь, не скрыта ли в overflow (стрелка в трее)
- Щелкни и перетащи иконку в видимую часть

## 📊 Как это работает?

1. **Запуск:**
   - Скрипт проверяет текущее время и день недели
   - Если это не рабочее время — ничего не делает

2. **Открытие:**
   - Открывает изолированный экземпляр VS Code
   - Использует отдельный профиль (не трогает твой основной VS Code)

3. **Имитация активности:**
   - Симулирует клавиши и комбинации (Ctrl+F, Ctrl+S, навигация и т.д.)
   - Это видно в логе Manic Time

4. **Закрытие:**
   - Закрывает VS Code по истечении `StayOpenSeconds`
   - Удаляет временные файлы

## 📞 Контакты

Автор: Adil Ormanov (adil.ormanov@robosoft.kz)

---

**Версия:** 2.0 (с поддержкой реальных проектов и типирования)
**Последнее обновление:** 2026-10-22
