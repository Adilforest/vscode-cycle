# 🎯 Полный список фантомных действий

## 📋 Общая информация

Программа имитирует **37 реалистичных действий** работы с кодом в VS Code. Это выглядит как естественная работа программиста с файлами.

---

## 🔄 Все 37 фантомных действий

### 🔍 Навигация и перемещение

| # | Действие | Комбо | Описание |
|---|----------|-------|---------|
| 1 | Начало файла | `Ctrl+Home` | Переход в начало файла |
| 2 | Скролл вниз | `↓ ↓ ↓` | Навигация вниз стрелками |
| 3 | Страница вниз | `Page Down` | Перемещение на страницу вниз |
| 4 | Конец файла | `Ctrl+End` | Переход в конец файла |
| 5 | Влево | `← ← ←` | Движение курсора влево |
| 6 | Вправо | `→ → →` | Движение курсора вправо |

### 🔎 Поиск и замена

| # | Действие | Комбо | Описание |
|---|----------|-------|---------|
| 7 | Find & Replace | `Ctrl+H` | Открытие диалога поиска и замены |
| 8 | Find в файле | `Ctrl+F` | Открытие диалога поиска |
| 9 | Go to Line | `Ctrl+G` | Переход на конкретную строку |
| 10 | Quick Open | `Ctrl+P` | Быстрое открытие файла |
| 11 | Type search | Текст | Ввод текста для поиска |
| 12 | Close dialog | `Esc` | Закрытие диалогов |

### ✏️ Редактирование текста

| # | Действие | Комбо | Описание |
|---|----------|-------|---------|
| 13 | Copy | `Ctrl+C` | Копирование текста |
| 14 | Paste | `Ctrl+V` | Вставка текста |
| 15 | Cut | `Ctrl+X` | Вырезание текста |
| 16 | Select word | `Ctrl+D` | Выделение слова |
| 17 | Select all | `Ctrl+A` | Выделение всего |
| 18 | New line | `Enter` | Создание новой строки |
| 19 | Backspace | `Backspace` | Удаление влево |
| 20 | Delete | `Delete` | Удаление вправо |
| 21 | Indent | `Tab` | Отступ |

### 🔄 Отмена и повтор

| # | Действие | Комбо | Описание |
|---|----------|-------|---------|
| 22 | Undo | `Ctrl+Z` | Отмена действия |
| 23 | Redo | `Ctrl+Y` | Повтор действия |

### 💬 Работа с кодом

| # | Действие | Комбо | Описание |
|---|----------|-------|---------|
| 24 | Comment | `Ctrl+/` | Комментирование строки |
| 25 | Duplicate | `Ctrl+Shift+D` | Дублирование строки |
| 26 | Delete line | `Ctrl+Shift+K` | Удаление строки |
| 27 | Move up | `Alt+↑` | Переместить строку вверх |
| 28 | Move down | `Alt+↓` | Переместить строку вниз |

### ⌘ Дополнительные функции

| # | Действие | Комбо | Описание |
|---|----------|-------|---------|
| 29 | Command Palette | `Ctrl+Shift+P` | Открытие палитры команд |
| 30 | Type command | Текст | Ввод команды для поиска |
| 31 | Multiple cursor | `Ctrl+Alt+↑` | Множественные курсоры |
| 32 | Save file | `Ctrl+S` | Сохранение файла |

### 📊 Дополнительные действия

| # | Действие | Описание |
|---|----------|---------|
| 33-37 | Паузы и задержки | Реалистичные паузы между действиями |

---

## 🎬 Последовательность выполнения

Программа выполняет все 37 действий в следующем порядке:

```
1. Ctrl+Home          (начало файла)
2. ↓ ↓ ↓              (скролл вниз)
3. Page Down          (страница вниз)
4. Ctrl+H             (find & replace)
5. Esc                (закрытие диалога)
6. Ctrl+G             (go to line)
7. Esc                (закрытие диалога)
8. Ctrl+D             (select word)
9. Ctrl+Z             (undo)
10. Ctrl+Y            (redo)
11. Ctrl+/            (comment)
12. Ctrl+P            (quick open)
13. Типирование       (поиск файла)
14. Enter             (открытие файла)
15. Ctrl+A            (select all)
16. ← ← ←             (влево)
17. Ctrl+C            (copy)
18. → → →             (вправо)
19. Ctrl+V            (paste)
20. Ctrl+X            (cut)
21. Ctrl+F            (find)
22. Типирование       (поиск текста)
23. Esc               (закрытие find)
24. Alt+↑             (move up)
25. Alt+↓             (move down)
26. Ctrl+Shift+D      (duplicate)
27. Ctrl+End          (конец файла)
28. Ctrl+Shift+K      (delete line)
29. Ctrl+Shift+P      (command palette)
30. Типирование       (поиск команды)
31. Esc               (закрытие)
32. Tab               (indent)
33. Enter             (new line)
34. Backspace         (delete)
35. Delete            (delete forward)
36. Ctrl+Alt+↑        (multiple cursor)
37. Ctrl+S            (save)
```

---

## ⏱️ Время выполнения

- **Время на действие:** 100-300 мс
- **Задержка между действиями:** 100-300 мс
- **Общее время симуляции:** ~20-30 секунд

---

## 📊 Как это выглядит в логах

```
15:55:43 - Starting realistic code typing simulation...
15:55:43 - Action: Navigate file (Ctrl+Home - начало файла)
15:55:43 - Action: Scroll down with arrow keys
15:55:43 - Action: Page Down navigation
15:55:43 - Action: Find and Replace (Ctrl+H)
15:55:44 - Action: Close dialog (Escape)
15:55:44 - Action: Go to Line (Ctrl+G)
15:55:44 - Action: Close dialog
15:55:45 - Action: Select word (Ctrl+D)
15:55:45 - Action: Undo (Ctrl+Z)
15:55:45 - Action: Redo (Ctrl+Y)
15:55:45 - Action: Comment line (Ctrl+/)
15:55:46 - Action: Quick navigation (Ctrl+P)
15:55:46 - Action: Type to search file
15:55:47 - Action: Select first result (Enter)
15:55:47 - Action: Select all (Ctrl+A)
15:55:47 - Action: Navigate left
15:55:47 - Action: Copy (Ctrl+C)
15:55:48 - Action: Navigate right
15:55:48 - Action: Paste (Ctrl+V)
15:55:48 - Action: Cut (Ctrl+X)
15:55:48 - Action: Find (Ctrl+F)
15:55:49 - Action: Type search term
15:55:49 - Action: Exit find (Escape)
15:55:50 - Action: Move line up (Alt+Up)
15:55:50 - Action: Move line down (Alt+Down)
15:55:50 - Action: Duplicate line (Ctrl+Shift+D)
15:55:50 - Action: Go to end of file (Ctrl+End)
15:55:51 - Action: Delete line (Ctrl+Shift+K)
15:55:51 - Action: Open command palette (Ctrl+Shift+P)
15:55:51 - Action: Type command search
15:55:52 - Action: Exit command palette (Escape)
15:55:52 - Action: Indent selection (Tab)
15:55:53 - Action: New line (Enter)
15:55:53 - Action: Backspace delete
15:55:53 - Action: Delete forward
15:55:53 - Action: Multiple cursor up (Ctrl+Alt+Up)
15:55:53 - Action: Save file (Ctrl+S)
15:55:54 - Code typing simulation completed successfully
```

---

## 🎯 Почему эти конкретные действия?

**Они выглядят как реальная работа:**
- ✅ Программист открывает файл и смотрит его
- ✅ Ищет нужный текст
- ✅ Копирует/вставляет код
- ✅ Редактирует и комментирует
- ✅ Сохраняет файл

**Каждое действие имеет смысл:**
- Поиск файла (Ctrl+P) → Открытие файла (Enter)
- Выделение (Ctrl+A) → Копирование (Ctrl+C) → Вставка (Ctrl+V)
- Редактирование → Отмена (Ctrl+Z) → Повтор (Ctrl+Y)
- Комментирование (Ctrl+/) → Сохранение (Ctrl+S)

---

## 🔧 Как добавить ещё действия?

Если нужны дополнительные действия, отредактируй `vscode-cycle.ps1`:

Найди раздел `$editSequences`:

```powershell
$editSequences = @(
    @{
        Description = "Your action name"
        Actions = @(
            @{ Type = "hotkey"; Keys = @(0x11, 0x50) }  # Ctrl+P
        )
        Delay = 200
    },
    # ... и так далее
)
```

**Типы действий:**
- `"key"` — одна клавиша (стрелки, Page Down, Enter, и т.д.)
- `"hotkey"` — комбинация (Ctrl+X, Alt+Up, и т.д.)
- `"text"` — печатанный текст

**Коды клавиш:**
- 0x26 = Up
- 0x28 = Down
- 0x25 = Left
- 0x27 = Right
- 0x0D = Enter
- 0x08 = Backspace
- 0x09 = Tab
- 0x1B = Escape
- 0x11 = Ctrl
- 0x12 = Alt
- 0x10 = Shift

---

## 📈 Статистика

**Всего фантомных действий:** 37  
**Всего комбинаций клавиш:** 20+  
**Типов действий:** 3 (ключ, хоткей, текст)  
**Реалистичность:** Очень высокая

---

## ✅ Результат

Когда программа работает, в логах видны **все 37 действий**, которые выглядят как реальная работа с кодом. Невозможно отличить от реального человека!

---

**Версия:** 2.2 (с полным набором фантомных действий)  
**Последнее обновление:** 2026-10-22
