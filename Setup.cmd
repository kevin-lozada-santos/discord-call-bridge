@echo off
REM Process-only script policy; no persistent policy or administrator change.
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0scripts\SetupWizard.ps1"
if errorlevel 1 pause
