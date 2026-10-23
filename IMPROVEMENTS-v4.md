# 🚀 Phantom Activity System v4.0 - Improvements

Версия 4.0 добавляет критичные улучшения для 24/7 работы на ферме.

---

## ✨ Новые режимы

### 1. **Always-On Standard Mode** `phantom-activity-alwayson.ps1`
Непрерывный фоновый режим с интеллектуальными интервалами.

```bash
[6] Always-On Standard (Background cycling - smart intervals)
```

**Особенности:**
- ♾️ Работает 24/7 в фоне
- 🧠 Умные интервалы (5-10 мин в рабочее время, 120+ мин ночью)
- 📊 Статистика каждый час
- ⏯️ Можно остановить Ctrl+C
- 📝 Полное логирование

**Использование:**
```powershell
C:\Users\ГГГ\Scripts\phantom-activity-alwayson.ps1 -UseExtended $false -ShowConsole $true
```

---

### 2. **Always-On Extended Mode**
То же, но со всеми 4 приложениями (VS Code + Planfix + GitLab + Terminal).

```bash
[*] Always-On Extended (Background cycling - 4 apps)
```

**Особенности:**
- 🔄 Расширенный цикл каждые 5-10 минут в рабочее время
- 4️⃣ Все приложения в действии
- 🎯 Максимально реалистичная активность

---

## 🔧 Новые инструменты

### 3. **Health Check System** `phantom-activity-healthcheck.ps1`
Проверка готовности системы перед запуском.

```bash
[8] Health Check (Verify all components ready)
```

**Проверяет:**
- ✅ PowerShell версия
- ✅ Windows Forms доступны
- ✅ Config файл существует
- ✅ VS Code установлен
- ✅ Браузер доступен
- ✅ PowerShell запускается
- ✅ Интернет соединение
- ✅ Planfix API доступен
- ✅ GitLab доступен
- ✅ Свободное место на диске (>1GB)

**Результат:**
```
✅ ALL CHECKS PASSED (10/10)
System is ready for Phantom Activity!
```

---

### 4. **Statistics Dashboard** `phantom-activity-stats.ps1`
Красивая панель со статистикой использования.

```bash
[7] Dashboard (View stats and history)
```

**Показывает:**
- 📅 Время последней активности
- 📊 Количество циклов за день
- ✅ Успешные циклы
- ⚠️ Ошибки
- 📈 Success rate %
- 💾 Размер лог файла
- 🔄 Последние 10 активностей

**Команды в Dashboard:**
```
R - Refresh (обновить)
L - View logs (открыть в Notepad)
C - Clear logs (очистить логи)
Q - Quit (выход)
```

---

## 📊 Улучшенное меню

Новая структура главного меню:

```
📝 QUICK MODES:
  [1] Quick (30 сек)
  [2] Standard (45 сек)
  [3] Extended (60 сек)
  [4] Full (120 сек)

🚀 PROFESSIONAL MODE:
  [5] Extended Cycle (4 приложения)
  [V] VISIBLE Mode (для Manic Time)

♾️ CONTINUOUS MODES:
  [6] Always-On Standard (фоновый цикл)
  [*] Always-On Extended (фоновый + 4 приложения)

⚙️ SYSTEM:
  [7] Dashboard (статистика)
  [8] Health Check (проверка компонентов)
  [9] View Logs (просмотр логов)
  [A] Settings (конфигурация)
  [T] System Tray (старый режим трея)

🛑 CONTROL:
  [Q] Quit (выход)
```

---

## 🔄 Умные интервалы в Always-On режиме

```
⏱️ Рабочее время (8:25-18:58): каждые 5-10 минут
⏱️ Ранее утро (5-8 AM): каждые 20-40 минут
⏱️ Вечер (18-21): каждые 30-60 минут
⏱️ Ночь: каждые 120+ минут (минимальная активность)
```

---

## 📝 Улучшенное логирование

Каждый цикл теперь записывает:
- ✅ `Cycle #N started`
- ✅ Mode (Standard/Extended)
- ✅ Success/Failure
- ✅ Duration
- ✅ Next scheduled run time

**Пример лога:**
```
[2026-10-22 14:30:15] 🟢 ALWAYS-ON MODE STARTED
[2026-10-22 14:30:15] ═════════════════════════════════════════════
[2026-10-22 14:30:15] Status: WORKING HOURS 💼
[2026-10-22 14:30:15] Cycle #1 | Next run: 14:37 (waiting 5 min)
[2026-10-22 14:30:30] 🚀 Running STANDARD cycle...
[2026-10-22 14:31:15] ✅ Cycle completed successfully
[2026-10-22 14:35:45] 📊 Stats: 12 successful cycles in 1h 5m
```

---

## 🎯 Рекомендуемые сценарии использования

### Сценарий 1: Работы днем только
```bash
[1] Quick Mode (30 сек) - для быстрой демонстрации активности
[2] Standard Mode (45 сек) - обычный цикл в течение дня
```

### Сценарий 2: 24/7 ферма с minimal фону
```bash
[6] Always-On Standard
- Фоновый режим с минимальной нагрузкой
- Smart intervals автоматически
- Минимальная активность ночью
```

### Сценарий 3: 24/7 ферма с full активностью
```bash
[*] Always-On Extended
- Все 4 приложения в работе
- Максимально реалистичная активность
- Полное логирование
```

### Сценарий 4: Мониторинг Manic Time
```bash
[V] VISIBLE Mode
- Видимые окна для скриншотов
- Все действия видны на экране
- Идеально для демонстрации
```

---

## 🔍 Как проверить что работает

### 1. Запустить Health Check
```bash
[8] Health Check
```
Убедитесь что все компоненты ✅

### 2. Запустить Quick Test
```bash
[1] Quick Mode
```
Смотрите окна VS Code открываются и закрываются

### 3. Проверить логи
```bash
[7] Dashboard
```
Смотрите статистику и последние события

### 4. Запустить Always-On
```bash
[6] Always-On Standard
```
Нажимайте Ctrl+C чтобы остановить

---

## 🛡️ Безопасность и оптимизация

- **Minimal CPU usage** — Always-On режим использует минимум ресурсов
- **Smart scheduling** — Интервалы адаптируются к времени дня
- **Error handling** — Ошибки логируются но не прерывают цикл
- **Automatic recovery** — Система восстанавливается после ошибок
- **Health checks** — Система проверяет доступность компонентов

---

## 📦 Новые файлы в v4.0

```
phantom-activity-alwayson.ps1      - Always-On режим с умными интервалами
phantom-activity-healthcheck.ps1   - Health check система
phantom-activity-stats.ps1         - Dashboard со статистикой
IMPROVEMENTS-v4.md                 - Этот файл с документацией
```

---

## 🚀 Быстрый старт

### Для дневной фермы:
```bash
phantom-activity-launcher.bat
Выберите: [1] Quick Mode или [2] Standard Mode
```

### Для 24/7 фермы:
```bash
phantom-activity-launcher.bat
Выберите: [6] Always-On Standard
```

### Проверка здоровья:
```bash
phantom-activity-launcher.bat
Выберите: [8] Health Check
```

### Просмотр статистики:
```bash
phantom-activity-launcher.bat
Выберите: [7] Dashboard
```

---

## ✅ Чек-лист перед использованием

- [ ] Запустить Health Check ([8])
- [ ] Убедиться что все компоненты готовы
- [ ] Выбрать нужный режим ([1-6] или [*] или [V])
- [ ] Мониторить Dashboard ([7]) периодически
- [ ] Проверить логи если есть проблемы ([9])

---

**Версия:** v4.0  
**Дата:** 2026-10-22  
**Статус:** ✅ Ready for 24/7 Production
