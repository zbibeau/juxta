@echo off
:: Neutraliser-Cegedim : residus Cegedim / jFSE (ClmLive, demon jFSE...) - sans desinstallation, sans redemarrage, reversible.
if not exist "%~dp0Neutraliser-Cegedim.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Neutraliser-Cegedim.ps1"
