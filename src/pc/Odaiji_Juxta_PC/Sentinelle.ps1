# Sentinelle.ps1 - diagnostic PASSIF periodique (tache planifiee \Odaiji\Sentinelle) : remonte l'etat du poste a MadeForMed.
#   - ne repare JAMAIS, ne touche JAMAIS au lecteur ni aux cartes (OdaijiJuxta.ps1 -Leger), ne cree aucun fichier sur le Bureau
#   - un passage par jour au plus ; envoie un petit "battement" (etat + version) ; le rapport complet seulement si l'etat change (ou 1 fois / semaine)
#   - desactivation : creer C:\ProgramData\MadeForMed\sentinelle.off  (ou Desinstaller-Sentinelle.bat)
param([switch]$Force, [switch]$SansEnvoi)
$ErrorActionPreference = "SilentlyContinue"
$t0 = Get-Date
. (Join-Path $PSScriptRoot "Odaiji-Commun.ps1")
$base = Get-OjDir
if (Test-Path (Join-Path $base "sentinelle.off")) { exit 0 }
$dir = Join-Path $base "sentinelle"; New-Item -ItemType Directory -Force -Path $dir | Out-Null
$fe = Join-Path $dir "etat.json"; $etat = $null
try { if (Test-Path $fe) { $etat = Get-Content $fe -Raw | ConvertFrom-Json } } catch { $etat = $null }
if (-not $Force -and $etat -and $etat.derniere_execution) {
    $le = [datetime]::MinValue; try { $le = [datetime]::Parse([string]$etat.derniere_execution, [Globalization.CultureInfo]::InvariantCulture) } catch {}
    if (($t0 - $le).TotalHours -lt 20) { exit 0 }
}
try { (Get-Process -Id $PID).PriorityClass = "BelowNormal" } catch {}
# 1. diagnostic passif (processus enfant cache)
$diag = if ($env:ODAIJI_DIAG) { $env:ODAIJI_DIAG } else { Join-Path $PSScriptRoot "OdaijiJuxta.ps1" }   # ODAIJI_DIAG / ODAIJI_POWERSHELL : tests uniquement
$ps = if ($env:ODAIJI_POWERSHELL) { $env:ODAIJI_POWERSHELL } else { "powershell.exe" }
& $ps -NoProfile -ExecutionPolicy Bypass -File $diag -Leger -NoPause -Prefix Sentinelle 2>&1 | Out-Null
$rap = Get-ChildItem $dir -Filter "Sentinelle_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $rap) { exit 0 }
$res = Get-RapportResume ([IO.File]::ReadAllText($rap.FullName))
$ko = @($res.constats | Where-Object { $_.niveau -eq "KO" } | ForEach-Object { $_.code } | Sort-Object -Unique)
$warn = @($res.constats | Where-Object { $_.niveau -eq "WARN" } | ForEach-Object { $_.code } | Sort-Object -Unique)
$codes = @($ko + $warn)
$sc = if ($res.scenario) { $res.scenario } else { "?" }
$dec = Get-DecisionEnvoi -Etat $etat -Scenario $sc -Codes $codes -Maintenant $t0
# 2. version publiee (alerte "kit en retard", jamais de mise a jour automatique)
$ver = Get-OjVersion; $dispo = $ver
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $dispo = [string](Invoke-RestMethod -Uri $(if ($env:ODAIJI_VERSION_URL) { $env:ODAIJI_VERSION_URL } else { "https://odaiji-juxta.netlify.app/version.json" }) -TimeoutSec 15).version } catch {}
$retard = $false; try { $retard = ([version]$dispo -gt [version]$ver) } catch {}
$corps = @{ scenario = $sc; ko = @($ko); warn = @($warn); leger = $true; kit = $ver; dispo = $dispo; retard = $retard; duree_s = [int]((Get-Date) - $t0).TotalSeconds; complet = $dec.complet; raison = $dec.raison } | ConvertTo-Json -Compress -Depth 4
$dernierRapport = if ($etat) { [string]$etat.dernier_rapport } else { "" }
if (-not $SansEnvoi) {
    [void](Send-OjBattement $corps)
    if ($dec.complet) { $r = Send-OjRapport -Fichier $rap.FullName -Raison ("sentinelle " + $dec.raison); if ($r.statut -ne "refuse") { $dernierRapport = $t0.ToString("yyyy-MM-dd") } }
    else { [void](Invoke-OjSpool) }
}
# 3. etat + menage (3 derniers rapports locaux)
@{ derniere_execution = $t0.ToString("s", [Globalization.CultureInfo]::InvariantCulture); scenario = $sc; codes = @($codes); dernier_rapport = $dernierRapport } | ConvertTo-Json -Compress | Set-Content -Path $fe -Encoding ASCII
Get-ChildItem $dir -Filter "Sentinelle_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 | Remove-Item -Force
