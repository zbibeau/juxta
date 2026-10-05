@echo off
:: Erreurs DRC a la teletransmission (Chrome 142+ "Local Network Access") :
:: autorise app.odaiji.co a joindre JuxtaLink sans toucher aux flags. Chrome + Edge + Firefox, tous utilisateurs.
if not exist "%~dp0Autoriser-Odaiji-Chrome.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Autoriser-Odaiji-Chrome.ps1" 
if errorlevel 1 (
  echo.
  echo  Le script s'est termine avec une erreur ^(voir ci-dessus^).
  pause
)
