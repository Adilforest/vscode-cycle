# Web Server on port 8080
$scriptsDir = "C:\Users\$env:USERNAME\Scripts"

Write-Host "🌐 Запускаю Web Server на порту 8080..." -ForegroundColor Green
& "$scriptsDir\phantom-activity-webserver.ps1" -Port 8080
