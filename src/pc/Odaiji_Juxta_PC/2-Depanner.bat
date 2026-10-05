@echo off
:: Odaiji_Juxta (PC) - double-clic : DEPANNAGE d'un poste ou JuxtaLink est deja installe.
:: Diag avant -> corrections sures -> reparation du lecteur / Chrome-Edge si besoin -> relance de JuxtaLink -> diag apres.
:: Pour un poste neuf : 1-Installer.bat
if not exist "%~dp0Depannage.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Depannage.ps1" %*
if errorlevel 1 (
  echo.
  echo  Le script s'est termine avec une erreur ^(voir ci-dessus^).
  pause
)
