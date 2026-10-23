# 🚀 Расширенный цикл фантомной активности (Extended Cycle)

## 📋 Общая информация

**Extended Cycle** — это расширенная версия программы, которая одновременно открывает и имитирует работу с **4 различными приложениями/сервисами**:

1. **VS Code** — разработка кода
2. **Planfix** — управление задачами (Kanban доска)
3. **GitLab** — контроль версий и репозитории
4. **Terminal** — командная строка (git операции)

---

## 🎯 Что делает Extended Cycle?

### Phase 1: VS Code Development (8-10 сек)

```
✓ Открывает изолированный VS Code
✓ Открывает проект: situation-centre-arm-backend
✓ Открывает файл: manage.py
✓ Выполняет 9 фантомных действий с кодом:
  - Ctrl+Home (начало файла)
  - Arrow Down (скролл вниз)
  - Ctrl+F (поиск)
  - Типирование поиска
  - Escape (закрытие)
  - Ctrl+A (выделить всё)
  - Ctrl+C (копирование)
  - Ctrl+End (конец файла)
  - Ctrl+S (сохранение)
✓ Логирует все операции
```

### Phase 2: Planfix Kanban Board (7-8 сек)

```
✓ Открывает Planfix в браузере
URL: https://robosoft.planfix.com/planner/706

✓ Выполняет фантомные действия:
  - Page Down (прокрутка)
  - Page Down (ещё прокрутка)
  - Ctrl+Home (возврат в начало)

✓ Делает API запрос к Planfix:
  - Получает список задач
  - Использует токен: f2ee5c562c5cfb52676f72bad7e8c0af
  - API: https://robosoft.planfix.com/rest/api/v3/tasks
```

### Phase 3: GitLab Repository (7-8 сек)

```
✓ Открывает GitLab репозиторий в браузере
URL: https://gitlab.robosoft.kz/robosoft/situation-centre-arm-backend

✓ Выполняет фантомные действия:
  - Page Down (прокрутка)
  - Page Down (ещё прокрутка)
  - Ctrl+F (поиск в коде)
  - Типирование поискового запроса
```

### Phase 4: PowerShell Terminal (10-12 сек)

```
✓ Открывает PowerShell терминал
✓ Выполняет реальные Git команды:
  - git status
  - git log --oneline -5
  - cd apps/building_tracker
  - ls -la
  - git branch -a
  - exit
```

---

## ⏱️ Временная шкала

```
Вход                       :  0 сек
├─ Phase 1 (VS Code)      :  3-5 сек
│  └─ Завершение          :  8-10 сек
│
├─ Phase 2 (Planfix)      : 10-11 сек
│  └─ Завершение          : 17-18 сек
│
├─ Phase 3 (GitLab)       : 18-19 сек
│  └─ Завершение          : 25-27 сек
│
├─ Phase 4 (Terminal)     : 27-28 сек
│  └─ Завершение          : 37-39 сек
│
└─ Cleanup + Exit         : 40-42 сек

ВСЕГО: ~32-38 секунд активности
```

---

## 🔐 Безопасность и токены

### Planfix API Token

**Токен:** `f2ee5c562c5cfb52676f72bad7e8c0af`

**Расположение в коде:**
```powershell
$planfixToken = "f2ee5c562c5cfb52676f72bad7e8c0af"
```

**Разрешения (Scopes):**
- `comment_add` — добавление комментариев
- `comment_delete` — удаление комментариев
- `task_readonly` — чтение задач
- `task_update` — обновление задач
- И другие операции

**API Endpoint:**
```
https://robosoft.planfix.com/rest/api/v3/tasks
```

### Безопасное хранение

⚠️ **Важно:** Токен хранится в скрипте. Если нужна повышенная безопасность:
1. Сохрани токен в отдельном файл (с ограниченными правами доступа)
2. Загружай его из файла при запуске
3. Или используй переменные окружения

---

## 🎬 Как использовать?

### Способ 1: Через меню (рекомендуется)

```bash
1. Двойной клик на рабочем столе → phantom-activity.bat
2. Выбери опцию [5]: Extended Cycle (все приложения)
3. Смотри логи в real-time
```

### Способ 2: Прямой запуск

```powershell
C:\Users\ГГГ\Scripts\vscode-cycle-extended.ps1 -StayOpenSeconds 45
```

### Способ 3: Через PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\ГГГ\Scripts\vscode-cycle-extended.ps1"
```

---

## 📊 Логирование

Все события записываются в:
```
C:\Users\ГГГ\Scripts\vscode-cycle.log
```

**Пример логов:**

```
16:30:15 - ═════════════════════════════════════════════════════════════════
16:30:15 - 🚀 EXTENDED PHANTOM ACTIVITY CYCLE STARTED
16:30:15 - ═════════════════════════════════════════════════════════════════
16:30:15 - 
16:30:15 - PHASE 1: VS Code Development
16:30:15 - Opening isolated VS Code instance with project...
16:30:18 - Starting code editing simulation...
16:30:18 -   Action: Navigate file (Ctrl+Home)
16:30:18 -   Action: Scroll down with arrow keys
16:30:19 -   Action: Find in file (Ctrl+F)
16:30:19 -   Action: Type search term
16:30:19 -   Action: Close find (Escape)
16:30:20 -   Action: Select all (Ctrl+A)
16:30:20 -   Action: Copy (Ctrl+C)
16:30:20 -   Action: Go to end of file (Ctrl+End)
16:30:21 -   Action: Save file (Ctrl+S)
16:30:21 - Code editing simulation completed
16:30:25 - 
16:30:25 - PHASE 2: Planfix Kanban Board
16:30:25 - Opening Planfix (Kanban board)...
16:30:28 - Simulating Planfix actions...
16:30:29 - Planfix phantom actions completed
16:30:32 - Fetching Planfix tasks via API...
16:30:32 - Retrieved tasks: 10 items
16:30:35 - 
16:30:35 - PHASE 3: GitLab Repository
16:30:35 - Opening GitLab repository...
16:30:38 - Simulating GitLab actions (browsing code)...
16:30:42 - GitLab phantom actions completed
16:30:45 - 
16:30:45 - PHASE 4: Terminal Git Operations
16:30:45 - Opening PowerShell Terminal...
16:30:47 - Simulating Git operations in terminal...
16:30:47 -   Terminal: git status
16:30:49 -   Terminal: git log --oneline -5
16:30:50 -   Terminal: cd apps/building_tracker
16:30:52 -   Terminal: ls -la
16:30:53 -   Terminal: git branch -a
16:30:55 -   Terminal: exit
16:30:56 - Terminal simulation completed
16:31:00 - 
16:31:00 - Closing VS Code instance...
16:31:00 - 
16:31:00 - ═════════════════════════════════════════════════════════════════
16:31:00 - ✅ EXTENDED CYCLE COMPLETED SUCCESSFULLY
16:31:00 - ═════════════════════════════════════════════════════════════════
```

---

## 🔧 Настройка

### Изменение параметров

Отредактируй `vscode-cycle-extended.ps1`:

```powershell
# Project settings
$projectPath = "C:\Users\ГГГ\Desktop\situation-centre-arm-backend"
$fileToOpen = "$projectPath\manage.py"

# URLs
$planfixUrl = "https://robosoft.planfix.com/planner/706"
$gitlabUrl = "https://gitlab.robosoft.kz/robosoft/situation-centre-arm-backend"

# Planfix API
$planfixToken = "f2ee5c562c5cfb52676f72bad7e8c0af"
```

### Добавление новых фаз

Добавь новую функцию и вызови её в основном скрипте:

```powershell
function Open-MyApp {
    try {
        Write-Log "Opening My App..."
        # Your code here
    } catch {
        Write-Log "WARNING: My App failed: $_"
    }
}

# In main cycle:
Write-Log "PHASE 5: My Custom Phase"
Open-MyApp
```

---

## ✅ Чек-лист перед использованием

- [ ] VS Code установлен
- [ ] Проект существует: `C:\Users\ГГГ\Desktop\situation-centre-arm-backend`
- [ ] Браузер работает (для Planfix и GitLab)
- [ ] PowerShell доступен
- [ ] Токен Planfix актуален
- [ ] Логи пишутся в правильное место
- [ ] Рандомизация времён включена
- [ ] Программа работает в рабочее время

---

## 🐛 Решение проблем

### Planfix API не работает

```
WARNING: Planfix API call failed
```

**Решение:**
- Проверь интернет подключение
- Убедись, что токен актуален
- Проверь разрешения токена

### Terminal не открывается

```
WARNING: Terminal simulation failed
```

**Решение:**
- Убедись, что PowerShell установлен
- Проверь права доступа
- Попробуй запустить как администратор

### GitLab/Planfix не открывается

```
WARNING: GitLab simulation failed
```

**Решение:**
- Убедись, что браузер по умолчанию установлен
- Проверь интернет соединение
- Убедись, что URLs доступны

---

## 📈 Расширения

### Возможные добавления:

1. **Slack интеграция** — отправка сообщений в Slack
2. **Jira интеграция** — работа с JIRA задачами
3. **Email** — чтение/отправка писем
4. **Database** — работа с БД
5. **Docker** — запуск контейнеров
6. **Kubernetes** — работа с K8s

---

## 📞 Контакты

**Автор:** Adil Ormanov  
**Email:** adil.ormanov@robosoft.kz  
**Версия:** 3.0 (с поддержкой Extended Cycle)  
**Последнее обновление:** 2026-10-22

---

## 📝 История изменений

### v3.0 (Extended Cycle)
- ✅ Добавлена поддержка Planfix
- ✅ Добавлена поддержка GitLab
- ✅ Добавлена поддержка Terminal
- ✅ API интеграция с Planfix
- ✅ 4 фазы работы

### v2.2 (Phantom Actions)
- ✅ 37 фантомных действий
- ✅ Полное документирование

### v2.1 (Randomization)
- ✅ Рандомизация времён
- ✅ Естественное расписание

### v2.0 (Initial)
- ✅ VS Code + Project
- ✅ Phantom typing

---

**Готово к использованию!** 🚀
