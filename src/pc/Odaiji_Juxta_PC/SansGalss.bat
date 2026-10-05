@echo off
:: Poste deja installe : passage en Full PC/SC (retire le GALSS x86 Juxta, bloque sa reinstallation).
:: A lancer cartes inserees, JuxtaLink deja utilise au moins une fois (plugin SSV present).
if not exist "%~dp0OdaijiJuxta.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OdaijiJuxta.ps1" -Fix -SansGalss
if errorlevel 1 (
  echo.
  echo  Le script s'est termine avec une erreur ^(voir ci-dessus^).
  pause
)
