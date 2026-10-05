@echo off
:: Surveille JuxtaLink toutes les 20 s pendant 8 h (JuxtaLink "injoignable par moment") -> fichier sur le Bureau
if not exist "%~dp0Surveiller-JuxtaLink.ps1" (
  echo  Extraire d abord le zip puis relancer depuis le dossier extrait.
  pause
  exit /b 1
)
start "Surveillance JuxtaLink" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Surveiller-JuxtaLink.ps1"
