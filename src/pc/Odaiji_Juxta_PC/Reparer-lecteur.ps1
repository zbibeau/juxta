# Reparer-lecteur.ps1 - lance galss-autofix.ps1 puis envoie ce qu'il a journalise a MadeForMed.
param([Parameter(Mandatory)][string]$Autofix)
$Log = Join-Path $env:ProgramData "MadeForMed\galss-autofix.log"
$n = 0; if (Test-Path $Log) { $n = ([IO.File]::ReadAllText($Log)).Length }
& $Autofix
$h = Join-Path $PSScriptRoot "Envoyer-journal.ps1"
if ((Test-Path $h) -and (Test-Path $Log)) { try { & $h -Fichier $Log -Raison "reparation lecteur" -Depuis $n } catch {} }
