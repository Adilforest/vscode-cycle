Set objShell = CreateObject("WScript.Shell")

' Функция для регистрации активности в Manic Time перед запуском
Sub RegisterActivity
    On Error Resume Next

    ' Способ 1: команда cmd.exe генерирует событие WM_CREATE/WM_ACTIVATE в Windows
    objShell.Run "cmd.exe /c exit", 0, True

    On Error GoTo 0
End Sub

' Запускаем активность перед началом
RegisterActivity()

objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Users\RoboSoft\Scripts\vscode-cycle-tray.ps1""", 0, False

' Закрыть VBS процесс после запуска PowerShell (избегаем видимых окон)
WScript.Quit(0)
