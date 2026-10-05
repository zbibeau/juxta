@echo off
:: Double-clic : redemarre le service DMP Connect / iCanopee (Efficience "Lecteurs de cartes introuvables"). Demande l'UAC.
if not exist "%~dp0Reparer-DMP.ps1" (
  echo.
  echo  Lancer ce fichier depuis le dossier du kit EXTRAIT ^(pas depuis le zip^).
  echo.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reparer-DMP.ps1"
