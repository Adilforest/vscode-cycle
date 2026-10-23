# 🚀 Phantom Activity System v4.1

**Professional 24/7 Farm Activity Monitor** - Имитирует реальную рабочую активность для систем мониторинга времени (Manic Time и др.)

## ✨ Возможности

- ✅ **VS Code** - автоматическая имитация типинга кода (25+ действий)
- ✅ **Planfix** - автоматическое открытие и навигация
- ✅ **GitLab** - просмотр репозитория и файлов
- ✅ **Terminal/PowerShell** - имитация Git команд
- ✅ **Web Dashboard** - удалённое управление через http://localhost:8080/
- ✅ **Cloudflare Tunnel** - доступ с любого устройства
- ✅ **Расписание** - настраиваемые рабочие часы
- ✅ **Логирование** - все действия отслеживаются
- ✅ **Manic Time Compatible** - убедительные скриншоты и логи

## 🎯 Режимы работы

### STANDARD (только VS Code)
```powershell
& 'vscode-cycle.ps1'
```
- Минимальная нагрузка
- Только VS Code активен
- 45 сек на цикл

### EXTENDED (все приложения)
```powershell
& 'vscode-cycle-extended.ps1'
```
- VS Code + Planfix + GitLab + Terminal
- Полная активность
- 120+ сек на цикл

### VISIBLE (для Manic Time скриншотов) ⭐ РЕКОМЕНДУЕТСЯ
```powershell
& 'vscode-cycle-visible.ps1'
```
- Окна видны на экране
- Максимально убедительно для скриншотов
- Идеально для Manic Time

### ALWAYS-ON (24/7 фоновый режим)
```powershell
& 'phantom-activity-alwayson.ps1' -UseExtended
```
- Автоматическое выполнение по расписанию
- Бесконечный цикл
- Уважает выходные и обеденные перерывы

## 🌐 Веб-Интерфейс

### Локальный доступ
```
http://localhost:8080/
```
- API Key загружается автоматически
- Кнопки START/STOP работают сразу
- Полная статистика и логи

### Удалённый доступ через Cloudflare
```
https://boys-celebs-beverages-transparency.trycloudflare.com/?key=cfat_Akd9sK2lP9mX1Qw5rT8yU3vW6zB4cN7d
```
- Запуск VISIBLE режима для скриншотов
- Удалённое управление со смартфона/планшета
- Безопасный доступ через Cloudflare туннель

### 📸 Кнопка VISIBLE Mode
Новая кнопка в веб-интерфейсе позволяет запустить режим VISIBLE удалённо:
- Нажмите кнопку "📸 START VISIBLE (для Manic Time)"
- Окна станут видны на экране
- Manic Time будет видеть реальные скриншоты
- Идеально для тестирования и демонстрации

## 📋 Конфигурация

Файл: `vscode-cycle.config.json`

```json
{
    "Enabled": true,
    "ActiveStartHour": 8,              // Начало работы
    "ActiveStartMinuteMin": 25,
    "ActiveStartMinuteMax": 48,
    "ActiveEndHour": 18,               // Конец работы
    "ActiveEndMinuteMin": 58,
    "ActiveEndMinuteMax": 0,
    "LunchStartHour": 13,              // Обед
    "LunchStartMinuteMin": 0,
    "LunchStartMinuteMax": 14,
    "LunchEndHour": 13,
    "LunchEndMinuteMin": 30,
    "LunchEndMinuteMax": 35,
    "ActiveDays": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    "StayOpenSeconds": 45,             // Длительность цикла
    "IntervalMinutes": 5,              // Интервал между циклами
    "Holidays": ["2026-10-26"],        // Выходные (YYYY-MM-DD)
    "Description": "Professional 24/7 Farm"
}
```

## 🚀 Быстрый старт

### 1. Требования
- Windows 10/11
- PowerShell 5.1+
- Administrator права (для веб-сервера)
- VS Code установлен
- Git установлен (для терминала)

### 2. Установка
```powershell
# Клонируйте репозиторий
git clone https://github.com/Adilforest/vscode-cycle.git

# Перейдите в папку
cd vscode-cycle

# Запустите от администратора
.\run-as-admin.bat
```

### 3. Запуск VISIBLE режима
**Локально:**
```powershell
& 'vscode-cycle-visible.ps1'
```

**Удалённо через Cloudflare:**
1. Откройте: https://boys-celebs-beverages-transparency.trycloudflare.com/?key=cfat_Akd9sK2lP9mX1Qw5rT8yU3vW6zB4cN7d
2. Нажмите: "📸 START VISIBLE (для Manic Time)"
3. Окна появятся на экране
4. Откройте Manic Time - начнёт делать скриншоты

## 📊 Логирование

Все действия записываются в: `vscode-cycle.log`

Примеры записей:
```
[2026-10-23 14:28:15] Starting isolated VS Code instance...
[2026-10-23 14:28:31] Starting realistic code typing simulation...
[2026-10-23 14:43:06] PHASE 2: Planfix Task Manager
[2026-10-23 14:43:13] PHASE 4: Terminal Git Operations
[2026-10-23 14:43:18] EXTENDED CYCLE COMPLETED SUCCESSFULLY
```

## 🔐 Безопасность

### API Key
- **Стандартный ключ:** `cfat_Akd9sK2lP9mX1Qw5rT8yU3vW6zB4cN7d`
- **Автоматическое использование** на localhost
- **Сохранение** в localStorage браузера
- **Удаление** кнопкой "Clear Key"

### Cloudflare Tunnel
- Защищённый доступ через Cloudflare
- Только авторизованные запросы
- HTTPS шифрование

## 🔗 API Endpoints

```
GET  /                          # Web Dashboard
GET  /api/status                # Текущий статус
GET  /api/health                # Health check
GET  /api/logs                  # Логи активности
GET  /api/config                # Конфигурация
POST /api/start?mode=STANDARD   # Запустить цикл
POST /api/start?mode=EXTENDED   # Запустить расширенный
POST /api/start?mode=visible    # Запустить VISIBLE режим ⭐
POST /api/stop                  # Остановить
```

Все POST запросы требуют API Key: `?key=YOUR_KEY`

## 📸 Интеграция с Manic Time

### Что видит Manic Time

1. **Скриншоты** - окна VS Code, браузера, терминала
2. **Логи активности** - все действия записаны
3. **Временные данные** - активность в рабочих часах
4. **Убедительность** - выглядит как реальная работа

### Настройка Manic Time

1. Скачайте Manic Time: https://www.manictime.com/
2. Установите на компьютер
3. Запустите VISIBLE режим:
   ```powershell
   & 'vscode-cycle-visible.ps1'
   ```
4. Откройте Manic Time
5. Наблюдайте "активность" в Timeline

## 📁 Структура проекта

```
vscode-cycle/
├── vscode-cycle.config.json              # Конфигурация
├── vscode-cycle.log                      # Логи активности
├── phantom-activity-status.json          # Статус системы
├── phantom-activity-web.html             # Web интерфейс
├── phantom-activity-webserver.ps1        # Web API сервер
├── vscode-cycle.ps1                      # Основной скрипт
├── vscode-cycle-extended.ps1             # Расширенный режим
├── vscode-cycle-visible.ps1              # VISIBLE режим
├── phantom-activity-alwayson.ps1         # Always-On режим
├── run-as-admin.bat                      # Быстрый запуск
├── README.md                             # Документация
└── MANIC_TIME_SETUP.txt                  # Гайд для Manic Time
```

## ❓ FAQ

**Q: Будет ли Manic Time видеть активность?**
A: ✅ Да, система имитирует реальную работу и делает скриншоты.

**Q: Работает ли на Windows 10?**
A: ✅ Да, требуется PowerShell 5.1+

**Q: Можно ли изменить рабочие часы?**
A: ✅ Да, отредактируйте `vscode-cycle.config.json` или используйте веб-интерфейс.

**Q: Безопасно ли?**
A: ✅ Локально на вашем компьютере, Cloudflare туннель защищён.

**Q: Какой режим лучше для Manic Time?**
A: ✅ VISIBLE режим - окна видны, скриншоты убедительны.

## 🛠️ Требуемые компоненты

- **VS Code** - для имитации кодирования
- **Git** - для Git команд в терминале
- **PowerShell 5.1+** - встроен в Windows 10+
- **Cloudflared** (опционально) - для удалённого доступа

## 📝 Лицензия

MIT License - Свободное использование

## 👨‍💻 Автор

**Adilforest** - https://github.com/Adilforest/vscode-cycle

## 🌟 Благодарности

Спасибо за использование **Phantom Activity System**!

---

**Версия:** 4.1 (Fixed & Tested)
**Статус:** ✅ Production Ready
**Последнее обновление:** 2026-10-23
