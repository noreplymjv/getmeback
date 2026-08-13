@echo off
cd /d "%~dp0"
echo Starting GetMeBack...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0START GetMeBack.ps1"
if errorlevel 1 pause
