# Installer-Sentinelle.ps1 - installe la sentinelle (diagnostic passif periodique) sur ce poste. A lancer en administrateur (le .bat demande l'UAC).
#   Copie le kit dans C:\ProgramData\MadeForMed\sentinelle-kit (le dossier de telechargement peut disparaitre) puis cree la tache \Odaiji\Sentinelle :
#   SYSTEM, tous les jours a 12:30 + 10 min apres chaque demarrage, priorite basse, 20 min maximum, jamais en double.
#   La cle d'envoi du cabinet (cle-envoi.txt, fournie par MadeForMed) est copiee avec le kit si elle est a cote.
param([switch]$Desinstaller)
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $al = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); if ($Desinstaller) { $al += "-Desinstaller" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $al; exit
}
$Kit = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dest = Join-Path $env:ProgramData "MadeForMed\sentinelle-kit"
if ($Desinstaller) {
    try { Unregister-ScheduledTask -TaskName "Sentinelle" -TaskPath "\Odaiji\" -Confirm:$false -ErrorAction Stop; Write-Host "Tache \Odaiji\Sentinelle supprimee." -ForegroundColor Green } catch { Write-Host "Tache absente." -ForegroundColor Yellow }
    Remove-Item $Dest -Recurse -Force -ErrorAction SilentlyContinue; Write-Host "Sentinelle desinstallee (les rapports deja envoyes restent chez MadeForMed)." -ForegroundColor Green
    Read-Host "Entree pour fermer"; exit
}
Write-Host "Installation de la sentinelle Odaiji_Juxta" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Get-ChildItem $Kit -File | Where-Object { $_.Extension -in ".ps1", ".psd1", ".txt", ".config" -and $_.Name -notmatch '^(Install|Depannage|Neutraliser|Reparer)' } | Copy-Item -Destination $Dest -Force
foreach ($f in "OdaijiJuxta.ps1","Odaiji-Commun.ps1","Sentinelle.ps1") { if (-not (Test-Path (Join-Path $Dest $f))) { Write-Host ("  [KO] fichier manquant dans le kit : " + $f) -ForegroundColor Red; Read-Host "Entree pour fermer"; exit 1 } }
Remove-Item (Join-Path $Dest "sentinelle.off") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:ProgramData "MadeForMed\sentinelle.off") -Force -ErrorAction SilentlyContinue
$act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path $Dest "Sentinelle.ps1") + '"')
$t1 = New-ScheduledTaskTrigger -Daily -At "12:30"
$t2 = New-ScheduledTaskTrigger -AtStartup; $t2.Delay = "PT10M"
$set = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 20) -MultipleInstances IgnoreNew
$set.Priority = 8
$pr = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
try {
    Register-ScheduledTask -TaskName "Sentinelle" -TaskPath "\Odaiji\" -Action $act -Trigger @($t1, $t2) -Settings $set -Principal $pr -Force -ErrorAction Stop | Out-Null
    Write-Host "  [OK] Tache \Odaiji\Sentinelle creee (tous les jours 12:30 + au demarrage)." -ForegroundColor Green
} catch { Write-Host ("  [KO] Creation de la tache impossible : " + $_.Exception.Message) -ForegroundColor Red; Read-Host "Entree pour fermer"; exit 1 }
$k = if (Test-Path (Join-Path $Dest "cle-envoi.txt")) { "cle du cabinet trouvee" } else { "pas de cle-envoi.txt : les rapports partiront 'non identifies' (demander la cle a MadeForMed)" }
Write-Host ("  Cle d'envoi : " + $k)
Write-Host "  Premier passage maintenant (1 a 2 minutes)..."
try { Start-ScheduledTask -TaskName "Sentinelle" -TaskPath "\Odaiji\" } catch {}
Write-Host "`nDesactiver : Desinstaller-Sentinelle.bat  (ou creer C:\ProgramData\MadeForMed\sentinelle.off)" -ForegroundColor Cyan
Read-Host "Entree pour fermer"
