Set objShell = CreateObject("WScript.Shell")
Set objWshNet = CreateObject("WScript.Network")

' Get username dynamically instead of hardcoding
Dim strUsername
strUsername = objWshNet.UserName

' Get proper path with environment variable
Dim strUserPath
strUserPath = objShell.ExpandEnvironmentStrings("%USERPROFILE%")

' Run vscode-cycle.ps1 in completely hidden mode via PowerShell
Dim cmdLine
cmdLine = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strUserPath & "\Scripts\vscode-cycle.ps1"""

' Execute PowerShell script with no visible window
objShell.Run cmdLine, 0, False

' Terminate VBS process after PowerShell launch
WScript.Quit(0)
