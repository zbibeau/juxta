<#
=====================================================================
 Demarrage-JuxtaLink.ps1 - JuxtaLink sans fenetre UAC, relance a chaque ouverture de session
 MadeForMed / Odaiji - v1.0 (28/09/2026)
=====================================================================
 Pourquoi : JuxtaLink exige les droits administrateur (fenetre UAC "Voulez-vous autoriser cette
 application..." a chaque lancement). Au demarrage de Windows, un programme qui exige l'UAC et qui est
 lance par une cle Run / le dossier Demarrage est BLOQUE en silence : JuxtaLink ne repart pas apres un
 redemarrage du PC (retour terrain 28/09 : port 1234 vide, "carte Vitale non lue").

 Ce que fait -Installer (machine en administrateur) :
   1. tache planifiee \Odaiji\JuxtaLink : a l'ouverture de session du medecin, "privileges les plus
      eleves" -> JuxtaLink demarre directement, sans question ;
   2. DESACTIVE (comme Gestionnaire des taches > Demarrage, sans deplacer ni supprimer : ils appartiennent au MSI)
      les autres lancements automatiques de JuxtaLink (cles Run, dossier Demarrage) ; trace dans HKLM\SOFTWARE\MadeForMed ;
   3. icone "JuxtaLink (Odaiji)" sur le Bureau public : relance JuxtaLink via la tache, sans UAC.
 -Retirer : supprime la tache et l'icone, reactive les lancements automatiques d'origine.
 -Lancer  : demarre JuxtaLink via la tache (ou via explorer si la tache n'existe pas).
 Limite : le compte du medecin doit etre administrateur du poste (sinon Windows demandera un mot de passe).
 Fonctions dans JuxtaLink-Demarrage-lib.ps1 (partagees avec OdaijiJuxta.ps1 et Install-OdaijiJuxta.ps1).
=====================================================================
#>
param([switch]$Installer, [switch]$Retirer, [switch]$Lancer, [string]$UserAppData = "", [switch]$NoPause)
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "JuxtaLink-Demarrage-lib.ps1")

# ---------------------------------------------------------------- Utilisation directe (Demarrage-JuxtaLink.bat)
if (-not ($Installer -or $Retirer -or $Lancer)) { $Installer = $true }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $Lancer) {
    $a = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); if ($Installer) { $a += "-Installer" }; if ($Retirer) { $a += "-Retirer" }; if ($NoPause) { $a += "-NoPause" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $a; exit
}
if (-not $UserAppData) {
    $u = (Get-JxUser).Split("\")[-1]
    $prof = (Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like ("*\" + $u) } | Select-Object -First 1).LocalPath
    $UserAppData = if ($prof) { Join-Path $prof "AppData\Roaming" } else { $env:APPDATA }
}
try {
    if ($Retirer) { Remove-JxTask | ForEach-Object { Write-Host "  [OK]  $_" -ForegroundColor Green } }
    if ($Installer) {
        Install-JxTask -User (Get-JxUser) -UserAppData $UserAppData | ForEach-Object { if ($_ -match '^ATTENTION') { Write-Host "  [WARN] $_" -ForegroundColor Yellow } else { Write-Host "  [OK]  $_" -ForegroundColor Green } }
        # 29/09 : source MSI disparue (kit lance depuis le zip) -> fenetres "Aucun package d'installation" : retablie ici aussi
        $jm = Get-JxMsi
        if ($jm -and (-not $jm.SourceOk -or @(Get-JxMsiErrors 7).Count)) {
            $km = Get-ChildItem (Join-Path $PSScriptRoot "installeurs\SetupJuxtaLink*.msi") -ErrorAction SilentlyContinue | Select-Object -First 1
            Repair-JxMsiSource $(if ($km) { $km.FullName } else { "" }) | Where-Object { $_ -ne "RELANCER" } | ForEach-Object { if ($_ -match '^ATTENTION') { Write-Host "  [WARN] $_" -ForegroundColor Yellow } else { Write-Host "  [OK]  $_" -ForegroundColor Green } }
            Install-JxTask -User (Get-JxUser) -UserAppData $UserAppData | Out-Null
        }
        Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2; $Lancer = $true
    }
    if ($Lancer) {
        $via = Start-JxTask; Start-Sleep 8
        if (Get-Process JuxtaLink -ErrorAction SilentlyContinue) { Write-Host "  [OK]  JuxtaLink demarre (via $via)" -ForegroundColor Green } else { Write-Host "  [KO]  JuxtaLink ne s'est pas lance" -ForegroundColor Red }
    }
} catch { Write-Host ("  [KO]  " + $_.Exception.Message) -ForegroundColor Red }
if (-not $NoPause) { Read-Host "`nEntree pour fermer" }
