# Envoyer-journal.ps1 - envoie un journal / rapport a MadeForMed (file d'attente si pas de reseau). Jamais bloquant.
param([Parameter(Mandatory)][string]$Fichier, [string]$Raison = "journal", [long]$Depuis = 0)
try {
    . (Join-Path $PSScriptRoot "Odaiji-Commun.ps1")
    $r = Send-OjRapport -Fichier $Fichier -Raison $Raison -Depuis $Depuis
    $c = if ($r.statut -eq "envoye") { "Cyan" } else { "Yellow" }
    Write-Host (Format-OjStatut $r "Journal") -ForegroundColor $c
} catch { Write-Host ("Envoi automatique impossible : " + $_.Exception.Message) -ForegroundColor Yellow }
