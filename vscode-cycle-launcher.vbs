Set objShell = CreateObject("WScript.Shell")

' Запускаем vscode-cycle.ps1 в полностью скрытом режиме через PowerShell
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Users\RoboSoft\Scripts\vscode-cycle.ps1""", 0, False

' Закрыть VBS процесс после запуска PowerShell
WScript.Quit(0)
