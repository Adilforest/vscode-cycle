@echo off
REM Phantom Activity Launcher - Batch script
REM This is a convenience wrapper to run the PowerShell menu

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-phantom-activity.ps1"
pause
