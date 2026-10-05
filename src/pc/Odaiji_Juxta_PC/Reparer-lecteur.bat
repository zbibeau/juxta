@echo off
:: Double-clic : realigne galss.ini sur le lecteur branche (CPS + Vitale inserees) et relance JuxtaLink (demande l'UAC).
:: Utilise le script du dossier du kit s'il est present, sinon celui installe par l'option -WithAutofix.
set "AF=%~dp0galss-autofix.ps1"
if not exist "%AF%" set "AF=C:\ProgramData\MadeForMed\galss-autofix.ps1"
if not exist "%AF%" (
  echo.
  echo  galss-autofix.ps1 introuvable : lancer ce fichier depuis le dossier du kit extrait.
  echo.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File \"%~dp0Reparer-lecteur.ps1\" -Autofix \"%AF%\"'"
