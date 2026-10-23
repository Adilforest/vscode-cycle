@echo off
REM ╔════════════════════════════════════════════════════════════════════╗
REM ║                                                                    ║
REM ║     🚀 PHANTOM ACTIVITY SYSTEM - Professional Edition v3.5        ║
REM ║                    24/7 Farm Activity Monitor                     ║
REM ║                                                                    ║
REM ║              Beautiful Interface & Optimized for 24/7              ║
REM ║                                                                    ║
REM ╚════════════════════════════════════════════════════════════════════╝

setlocal enabledelayedexpansion

REM Set title and colors
title Phantom Activity System v3.5 - Professional Edition
color 0A

REM Launch beautiful PowerShell interface
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0phantom-activity-main.ps1'"

pause
