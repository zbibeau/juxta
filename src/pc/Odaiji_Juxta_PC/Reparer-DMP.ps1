# Reparer-DMP.ps1 - redemarre le service DMP Connect / iCanopee (Efficience : "Lecteurs de cartes introuvables", getPcscResourcesList).
# Ne modifie rien d'autre. Se relance en administrateur si besoin.
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); exit
}
$Jn = Join-Path $env:TEMP ("ReparerDMP_" + $env:COMPUTERNAME + "_" + (Get-Date -Format "yyyyMMdd-HHmm") + ".txt")
try { Start-Transcript -Path $Jn -Force | Out-Null } catch {}
Write-Host "Odaiji_Juxta - redemarrage de DMP Connect / iCanopee" -ForegroundColor Cyan
$svc = @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { ($_.Name -match 'dmpconnect' -or $_.DisplayName -match 'DmpConnect') -and $_.PathName -match 'DmpConnect-JS2' -and $_.StartMode -ne 'Disabled' })
if (-not $svc.Count) {
    Write-Host "  Service DMP Connect introuvable (non installe ?). On arrete les processus : le moniteur les relance." -ForegroundColor Yellow
    Get-Process dmpconnect-js2 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
foreach ($sv in $svc) {
    try { Restart-Service $sv.Name -Force -ErrorAction Stop; Write-Host ("  Service redemarre : " + $sv.Name) -ForegroundColor Green }
    catch { try { Start-Service $sv.Name -ErrorAction Stop; Write-Host ("  Service demarre : " + $sv.Name) -ForegroundColor Green } catch { Write-Host ("  Service " + $sv.Name + " non redemarre : " + $_.Exception.Message) -ForegroundColor Red } }
}
Start-Sleep -Seconds 6
$js2 = @(Get-Process dmpconnect-js2 -ErrorAction SilentlyContinue)
if ($js2.Count) { Write-Host ("  dmpconnect-js2 actif (" + $js2.Count + " processus). Relancer la connexion dans Efficience (nouvel onglet).") -ForegroundColor Green }
else { Write-Host "  dmpconnect-js2 n'est pas actif : redemarrer le poste ou lancer 2-Depanner.bat." -ForegroundColor Red }
try { Stop-Transcript | Out-Null } catch {}
try { & (Join-Path $PSScriptRoot "Envoyer-journal.ps1") -Fichier $Jn -Raison "reparation DMP" } catch {}
Read-Host "Entree pour fermer"
