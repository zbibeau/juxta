@echo off
:: JuxtaLink sans fenetre UAC : tache planifiee a l'ouverture de session + icone Bureau "JuxtaLink (Odaiji)"
:: (poste deja installe). Pour annuler : Demarrage-JuxtaLink.bat retirer
if not exist "%~dp0Demarrage-JuxtaLink.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
if /i "%1"=="retirer" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Demarrage-JuxtaLink.ps1" -Retirer
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Demarrage-JuxtaLink.ps1" -Installer
)
