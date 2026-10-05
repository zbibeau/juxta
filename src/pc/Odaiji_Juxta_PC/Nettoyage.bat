@echo off
:: Nettoyage des residus d'un ancien editeur (Cegedim, jFSE, Crossway) : FSV anciennes, Cryptolib en doublon,
:: produits et dossiers residuels. Confirmation a chaque etape. A faire APRES une reparation reussie.
if not exist "%~dp0OdaijiJuxta.ps1" (
  echo.
  echo  Ce fichier est lance depuis le ZIP ou seul. Il faut d'abord EXTRAIRE le zip :
  echo  clic droit sur Odaiji_Juxta_PC-*.zip ^> Extraire tout... puis relancer depuis le dossier extrait.
  echo.
  pause
  exit /b 1
)
echo.
echo  NETTOYAGE : desinstalle d'anciens composants. A lancer uniquement avec le support MadeForMed,
echo  hors consultation, apres avoir enregistre le travail en cours (un redemarrage reste possible).
echo  Les outils de prise en main a distance (TeamViewer, AnyDesk...) ne sont jamais touches.
echo.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0OdaijiJuxta.ps1" -Nettoyage
if errorlevel 1 (
  echo.
  echo  Le script s'est termine avec une erreur ^(voir ci-dessus^).
  pause
)
