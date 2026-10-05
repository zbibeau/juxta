@echo off
:: Odaiji_Juxta (PC) - double-clic : installe JuxtaLink + config MadeForMed, corrige, verifie.
:: Options : 1-Installer.bat -NoInstall   (poste deja equipe)
::           1-Installer.bat -WithAutofix (lecteur a nommage instable)
::           1-Installer.bat -AvecGalss   (garder le GALSS x86 ; retire et bloque par defaut)
if not exist "%~dp0Install-OdaijiJuxta.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-OdaijiJuxta.ps1" %*
if errorlevel 1 (
  echo.
  echo  Le script s'est termine avec une erreur ^(voir ci-dessus^).
  pause
)
