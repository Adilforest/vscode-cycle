# 🌐 Web Interface - Quick Start (5 minutes)

Управление фантомной активностью с любого устройства через веб-браузер.

---

## 🎯 Что это даст вам

✅ Управление активностью с личного ноутбука дома  
✅ Включать/выключать режимы одним кликом  
✅ Смотреть логи в реальном времени  
✅ Безопасный доступ через HTTPS  
✅ Доступ с мобильного телефона  

---

## ⚡ Быстрый старт (Шаг 1-2)

### На ферма ноутбуке (сейчас):

#### Шаг 1️⃣ : Изменить API ключ (ОБЯЗАТЕЛЬНО!)

Открыть `start-webserver.bat` в блокноте:

```batch
set API_KEY=phantom-secret-key-change-me
```

Изменить на что-то вроде:
```batch
set API_KEY=SuperSecure_FarmKey_12345xyz
```

Сохранить файл.

#### Шаг 2️⃣ : Запустить веб-сервер

Двойной клик на `start-webserver.bat`

Вы должны увидеть:
```
🟢 Web Server STARTED on port 5000
🌐 API Server running on http://localhost:5000/
📍 Use Cloudflare Tunnel for remote access
🔑 API Key: SuperSecure_FarmKey_12345xyz
```

**Оставить это окно открытым!**

---

## 🌍 Доступ с дома (без Tunnel - локальная сеть)

**Если вы в одной локальной сети:**

1. Узнать IP ферма ноутбука:
```bash
# На ферма ноутбуке в PowerShell:
ipconfig | findstr "IPv4"
# Результат: например 192.168.1.100
```

2. С личного ноутбука открыть:
```
http://192.168.1.100:5000/?key=SuperSecure_FarmKey_12345xyz
```

Готово! 🎉

---

## 🔐 Доступ из интернета (Cloudflare Tunnel)

**Для доступа из дома через интернет:**

### На ферма ноутбуке:

#### Шаг 1️⃣ : Установить cloudflared

```bash
# Скачать installer:
# https://github.com/cloudflare/cloudflared/releases
# Файл: cloudflared-windows-amd64.msi

# После установки, проверить:
cloudflared --version
```

#### Шаг 2️⃣ : Авторизоваться в Cloudflare

```bash
cloudflared tunnel login
```

Браузер откроется → выберите домен → разрешите доступ

#### Шаг 3️⃣ : Создать туннель

```bash
cloudflared tunnel create phantom-farm
```

Вы получите ID туннеля, например: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

#### Шаг 4️⃣ : Запустить туннель

```bash
cloudflared tunnel run phantom-farm
```

Вы должны увидеть:
```
INF Tunnel running at https://phantom-farm-abc123xyz.trycloudflare.me/
```

**Сохраните этот URL!**

### С личного ноутбука дома:

Открыть в браузере:
```
https://phantom-farm-abc123xyz.trycloudflare.me/?key=SuperSecure_FarmKey_12345xyz
```

Готово! Полный доступ из дома! 🎉

---

## 🎮 Веб-интерфейс - Как использовать

### Главная панель

```
🌐 Phantom Activity Remote Control

📊 SYSTEM STATUS
  🟢 RUNNING / 🔴 STOPPED
  Mode: Standard / Extended
  Uptime: 2h 15m

🎮 CONTROLS
  [Standard] [Extended]  ← выбрать режим
  [▶ START] [⏹ STOP]    ← управление

💻 SYSTEM INFO
  Status: ✅ Online
  Free Disk: 45.2 GB
  
⚙️ CONFIGURATION
  Working Hours: 8:25 - 18:58
  Lunch Break: 13:00 - 13:30
  Cycle Duration: 45s

📋 RECENT ACTIVITY
  [14:30:15] ✅ Cycle completed
  [14:25:12] 🚀 Running STANDARD cycle
  ...
```

### Использование:

1. **Выбрать режим:**
   - `Standard` — только VS Code
   - `Extended` — все 4 приложения

2. **Запустить активность:**
   - Нажать `[▶ START]`
   - Система начнет работать в фоне

3. **Остановить:**
   - Нажать `[⏹ STOP]`
   - Подтвердить в диалоге

4. **Смотреть логи:**
   - Прокручивать `Recent Activity`
   - Автоматически обновляется каждые 5 сек

5. **Проверить здоровье системы:**
   - Посмотреть статус процесса
   - Проверить свободное место на диске

---

## 🔒 Безопасность

### Что защищено:

✅ HTTPS шифрование (через Cloudflare)  
✅ API ключ в каждом запросе  
✅ Cloudflare DDoS protection  
✅ Rate limiting на запросы  

### Что НЕ защищено без мер:

⚠️ Старайтесь не открывать URL на публичных сетях  
⚠️ Используйте сложный API ключ  
⚠️ Мониторьте логи Cloudflare  

---

## 📱 Доступ с мобильного

1. Открыть URL в браузере телефона
2. Интерфейс адаптивный для мобайла
3. Можно сохранить ярлык на главном экране

```
https://phantom-farm-abc123xyz.trycloudflare.me/?key=SuperSecure_FarmKey_12345xyz
```

---

## 🐛 Проблемы и решения

### "Cannot connect to server"
```bash
# Проверить что веб-сервер запущен
netstat -ano | findstr :5000

# Если нет - запустить start-webserver.bat
```

### "Unauthorized - wrong key"
- Убедитесь что URL содержит `?key=...`
- Проверьте что ключ совпадает с тем что в `start-webserver.bat`

### "Tunnel not connecting"
```bash
# Перезапустить туннель
# Ctrl+C в окне cloudflared
# cloudflared tunnel run phantom-farm
```

### Slow connection / High latency
- Это нормально через Cloudflare Tunnel (100-200ms)
- Если нужно быстрее - используйте локальную сеть (http://192.168.x.x:5000)

---

## 🎯 Сценарий использования

### Утро (на ферма ноутбуке):
```
1. Запустить start-webserver.bat
2. Оставить окно открытым
3. Уходить на работу / в другое место
```

### День (на личном ноутбуке дома):
```
1. Открыть URL в браузере
2. Нажать [Standard] или [Extended]
3. Нажать [▶ START]
4. Смотреть логи в реальном времени
5. Можно включать/выключать когда угодно
```

### Вечер:
```
1. Нажать [⏹ STOP]
2. Закрыть браузер
```

---

## 📞 Справка по командам

### PowerShell (вручную)

Если батник не работает:

```powershell
# Перейти в папку скриптов
cd C:\Users\ГГГ\Scripts

# Запустить сервер
powershell -ExecutionPolicy Bypass -File phantom-activity-webserver.ps1 -Port 5000 -ApiKey "ваш-ключ"
```

### Cloudflare (вручную)

```bash
# Проверить статус туннеля
cloudflared tunnel info phantom-farm

# Просмотреть логи
cloudflared tunnel logs phantom-farm

# Перезапустить туннель
cloudflared tunnel run phantom-farm
```

---

## ✅ Финальный чек-лист

- [ ] API ключ изменен на уникальный
- [ ] start-webserver.bat работает
- [ ] Веб-интерфейс доступен локально (http://192.168.1.100:5000)
- [ ] cloudflared установлен
- [ ] Туннель создан и запущен
- [ ] URL туннеля сохранен где-то безопасно
- [ ] Доступ с дома работает

---

## 🚀 Готово!

Теперь вы можете управлять фантомной активностью из дома через веб-интерфейс! 🎉

**Краткая ссылка для доступа:**
```
https://phantom-farm-abc123xyz.trycloudflare.me/?key=ваш-ключ
```

**Сохраните в закладках!** 📌

---

**Версия:** v4.0  
**Тип:** Web Interface + Remote Control  
**Безопасность:** HTTPS + Cloudflare + API Key  
**Статус:** ✅ Ready to use
