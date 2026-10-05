@echo off
:: Neutraliser-Ancien-Logiciel : outil de l'EQUIPE. Choix d'un ancien logiciel metier du catalogue (Cegedim, Affid, Weda, HelloDoc...), neutralisation ou restauration.
if not exist "%~dp0Neutraliser-Ancien-Logiciel.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Neutraliser-Ancien-Logiciel.ps1"
