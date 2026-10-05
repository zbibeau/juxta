@echo off
:: Double-clic : desinstalle la sentinelle Odaiji_Juxta (diagnostic passif periodique). Demande l'UAC.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Installer-Sentinelle.ps1" -Desinstaller
