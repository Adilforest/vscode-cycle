# 🌐 Phantom Activity - Cloudflare Tunnel Setup

Настройка безопасного удаленного доступа к веб-интерфейсу через Cloudflare.

---

## 📋 Что вам потребуется

- ✅ Cloudflare account (бесплатный)
- ✅ Cloudflare API Token (есть)
- ✅ Домен на Cloudflare (опционально)
- ✅ `cloudflared` утилита для Windows

---

## 🚀 Быстрая настройка (5 минут)

### Шаг 1: Скачать и установить cloudflared

```bash
# Скачать cloudflared для Windows
# https://github.com/cloudflare/cloudflared/releases
# Ищите: cloudflared-windows-amd64.msi

# Или через PowerShell:
curl.exe -o "C:\Users\ГГГ\cloudflared.msi" "https://github.com/cloudflare/cloudflared/releases/download/2026.1.0/cloudflared-windows-amd64.msi"

# Установить
msiexec.exe /i "C:\Users\ГГГ\cloudflared.msi" /quiet
```

Проверить установку:
```bash
cloudflared --version
```

### Шаг 2: Запустить веб-сервер

На ноутбуке фермы:
```bash
cd C:\Users\ГГГ\Scripts

# С изменением API ключа!
powershell -ExecutionPolicy Bypass -File phantom-activity-webserver.ps1 -Port 5000 -ApiKey "ваш-секретный-ключ-здесь"
```

**Важно:** Измените `ApiKey` на уникальный сложный пароль!

### Шаг 3: Запустить Cloudflare Tunnel

В новом окне PowerShell на ферме ноутбуке:
```bash
# Первый запуск - авторизация
cloudflared tunnel login

# (откроется браузер, выберите домен)

# Создать туннель
cloudflared tunnel create phantom-farm

# Запустить туннель
cloudflared tunnel run phantom-farm
```

Или используйте конфиг файл (см. ниже).

### Шаг 4: Доступ с дома

Когда туннель активен, вы получите URL вида:
```
https://phantom-farm-abc123.trycloudflare.me
```

**Доступ с дома:**
```
https://phantom-farm-abc123.trycloudflare.me/?key=ваш-секретный-ключ
```

---

## 🔒 Безопасная конфигурация

### Файл конфига для Cloudflare Tunnel

Создать `C:\Users\ГГГ\Scripts\cloudflared-config.yml`:

```yaml
tunnel: phantom-farm
credentials-file: C:\Users\ГГГ\.cloudflared\phantom-farm.json

ingress:
  # Основной веб-интерфейс
  - hostname: phantom-farm.yourdomain.com
    service: http://localhost:5000
    originRequest:
      connectTimeout: 30s

  # Fallback на Cloudflare URL
  - service: http_status:404
```

### Запуск с конфигом

```bash
cloudflared tunnel run -c C:\Users\ГГГ\Scripts\cloudflared-config.yml
```

---

## 🎯 Интеграция с Phantom Activity

### Автоматический запуск при загрузке

Создать батник `C:\Users\ГГГ\Scripts\start-web-tunnel.bat`:

```batch
@echo off
title Phantom Activity - Web Server + Tunnel

REM Запустить веб-сервер в фоне
start "" powershell -ExecutionPolicy Bypass -File "%~dp0phantom-activity-webserver.ps1" -Port 5000 -ApiKey "ваш-секретный-ключ"

REM Дать серверу время запуститься
timeout /t 3

REM Запустить туннель
cloudflared tunnel run phantom-farm
```

Поместить в автозагрузку:
```powershell
# Запустить как администратор PowerShell:
$taskName = "Phantom Activity Web Tunnel"
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c C:\Users\ГГГ\Scripts\start-web-tunnel.bat"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest
```

---

## 🔐 Безопасность: Best Practices

### 1. Изменить API ключ
```powershell
# Сгенерировать сложный пароль
[convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((New-Guid).Guid + (New-Guid).Guid)) | Out-Clipboard
```

### 2. Использовать Cloudflare Bot Management
В Cloudflare Dashboard:
- Security → Bots → Enable Super Bot Fight Mode
- Rules → Create Custom Rule для вашего туннеля

### 3. Rate Limiting
```yaml
# В cloudflared-config.yml:
  - hostname: phantom-farm.yourdomain.com
    service: http://localhost:5000
    originRequest:
      # Rate limit: 100 requests per 10 minutes per IP
      rateLimit: 100
      rateLimitPeriod: 600
```

### 4. Мониторинг доступа
```bash
# Смотреть логи туннеля
cloudflared tunnel logs phantom-farm
```

---

## 📱 Мобильный доступ

1. Откройте URL на телефоне:
```
https://phantom-farm-abc123.trycloudflare.me/?key=ваш-секретный-ключ
```

2. Интерфейс адаптивный для мобильных устройств

3. Сохраните страницу в закладки или на главный экран

---

## 🐛 Решение проблем

### "Failed to connect to tunnel"
```bash
# Проверить интернет
ping 1.1.1.1

# Переавторизоваться
cloudflared tunnel login

# Перезапустить туннель
cloudflared tunnel run phantom-farm
```

### "Connection refused on localhost:5000"
```bash
# Проверить что веб-сервер запущен
netstat -ano | findstr :5000

# Перезапустить сервер
powershell -ExecutionPolicy Bypass -File phantom-activity-webserver.ps1 -Port 5000 -ApiKey "ключ"
```

### "Unauthorized" при доступе
- Убедитесь что в URL добавлен `?key=ваш-секретный-ключ`
- Проверьте что ключ совпадает с `-ApiKey` в powershell команде

---

## 📊 Мониторинг

### Просмотр трафика туннеля
```bash
# Все логи за день
cloudflared tunnel logs --level debug phantom-farm
```

### Статистика в Cloudflare Dashboard
- Доступ → Analytics
- Видно все запросы к туннелю
- Просмотр заблокированных ботов

---

## 🔄 Автоматическое обновление

`cloudflared` автоматически обновляется, но можно обновить вручную:
```bash
# Скачать последнюю версию
https://github.com/cloudflare/cloudflared/releases
```

---

## ✅ Чек-лист финальной настройки

- [ ] cloudflared установлен и работает
- [ ] API ключ изменен на уникальный
- [ ] Веб-сервер запускается на порту 5000
- [ ] Туннель успешно создан и активен
- [ ] Доступ по https:// из дома работает
- [ ] Мониторинг включен в Cloudflare Dashboard
- [ ] Батник для автозапуска создан
- [ ] Задача в Scheduler зарегистрирована

---

## 🚀 Быстрый доступ с дома

Сохраните эту ссылку в избранное (измените на вашу):
```
https://phantom-farm-abc123.trycloudflare.me/?key=ваш-секретный-ключ
```

Или создайте ярлык на рабочем столе личного ноутбука:
```
https://phantom-farm-abc123.trycloudflare.me/?key=ваш-секретный-ключ
```

---

**Версия:** v4.0  
**Безопасность:** ✅ Зашифровано (HTTPS)  
**Доступность:** ✅ 24/7 через Cloudflare
