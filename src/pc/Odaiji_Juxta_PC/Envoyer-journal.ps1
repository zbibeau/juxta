# Envoyer-journal.ps1 - envoie un journal / rapport a MadeForMed (meme point de reception que les rapports du kit). Jamais bloquant.
param([Parameter(Mandatory)][string]$Fichier, [string]$Raison = "journal", [long]$Depuis = 0)
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $kv = "?"; $kp = Join-Path $PSScriptRoot "OdaijiJuxta.ps1"
    if (Test-Path $kp) { $kv = [regex]::Match((Get-Content $kp -Raw), '\$Script:Version\s*=\s*"([^"]+)"').Groups[1].Value }
    $t = [IO.File]::ReadAllText($Fichier); if ($Depuis -gt 0 -and $Depuis -lt $t.Length) { $t = $t.Substring($Depuis) }
    if ($t.Length -gt 240000) { $t = $t.Substring($t.Length - 240000) }
    $b = [Text.Encoding]::UTF8.GetBytes((@{ kit = "odaiji-juxta"; os = "pc"; version = $kv; poste = $env:COMPUTERNAME; nom = (Split-Path $Fichier -Leaf); raison = $Raison; rapport = $t } | ConvertTo-Json -Compress))
    [void](Invoke-RestMethod -Uri "https://odaiji-juxta.netlify.app/.netlify/functions/rapport" -Method Post -Body $b -ContentType "application/json; charset=utf-8" -TimeoutSec 25 -ErrorAction Stop)
    Write-Host "Journal transmis automatiquement a MadeForMed." -ForegroundColor Cyan
} catch { Write-Host ("Envoi automatique impossible (" + (($_.Exception.Message -replace "[\r\n]+", " ")) + ") : recuperer ce fichier par le transfert de fichiers TeamViewer.") -ForegroundColor Yellow }
