@echo off
:: Odaiji_Juxta (PC) - version a ECRANS : une fenetre au lieu de la console. Les autres .bat restent disponibles (secours).
if not exist "%~dp0Odaiji-Ecran.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Odaiji-Ecran.ps1" %*
