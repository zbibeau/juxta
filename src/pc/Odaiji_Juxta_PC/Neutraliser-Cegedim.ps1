<#
=====================================================================
 Neutraliser-Cegedim - MadeForMed / Odaiji - v1.5 (30/09/2026)
 v1.5 : motif trop large corrige ("synchro" attrapait "Synchronize Time", OneSyncSvc, Adobe Acrobat Synchronizer... :
        poste DESKTOP-RNFKE1A 30/09) ; garde-fou : un element Windows / Microsoft / Adobe n'est JAMAIS cible, sauf s'il porte le nom
        de l'editeur ; -Restaurer -Systeme remet en route seulement les elements Windows / Microsoft / Adobe desactives a tort
 v1.4 : poste serveur (base Oracle de l'editeur) detecte -> Oracle jamais touche, ni desinstallation ni quarantaine
 v1.3 : -NonMsi (editeurs marques DesinstallerNonMsi au catalogue, ex. Weda Connect qui se relance au demarrage) :
        desinstalleurs non-MSI lances en silencieux (QuietUninstallString, sinon Inno /VERYSILENT, Squirrel -s, NSIS /S),
        5 min max, meme controle apres chaque produit. Les autres editeurs (Cegedim...) restent en liste seulement.
 v1.2 : -Desinstaller (reponse "n" a "facture-t-il ENCORE avec ... ?") : apres la neutralisation, desinstalle les
        produits MSI de l'editeur un par un (sans redemarrage), hors briques partagees, avec controle apres chaque
        produit (prise en main a distance, JuxtaLink, Icanopee, MICA) ; dossiers de l'editeur mis en quarantaine
        dans C:\_Odaiji_a_supprimer (a vider apres validation). Desinstalleurs non-MSI : listes, pas lances.
 v1.1 : generique pour tout ancien editeur (-Nom "Affid" -Motif "affid|fsenxt"), journal par editeur
=====================================================================
 Empeche les residus Cegedim / jFSE / Crossway de se lancer (ClmLive, demon jFSE...)
 SANS RIEN DESINSTALLER et SANS REDEMARRAGE. Tout est journalise et reversible :
     Neutraliser-Cegedim.bat          -> neutralise
     powershell -File Neutraliser-Cegedim.ps1 -Restaurer  -> remet l'etat d'avant (support uniquement)
 Actions : entrees de demarrage (Run) et raccourcis Demarrage deplaces en sauvegarde,
           services Cegedim passes en Desactive, taches planifiees desactivees,
           processus Cegedim arretes (java seulement s'il tourne depuis un dossier Cegedim/jFSE).
 Jamais touche : outils de prise en main a distance (TeamViewer, AnyDesk...), JuxtaLink, Icanopee,
                 amelipro, composants GIE (FSV, Cryptolib, GALSS, MICA).
 A n'utiliser QUE si le medecin ne facture plus avec un logiciel Cegedim.
=====================================================================
#>
param([switch]$Restaurer, [switch]$Systeme, [switch]$Auto, [switch]$Desinstaller, [switch]$NonMsi, [string]$Dossiers = "", [string]$Nom = "Cegedim", [string]$Motif = 'cegedim|clmlive|\bclm\b|jfse|crossway|resip|clm\w*synchro|synchro\w*clm|\bavi\b')
trap { Write-Host ("`nERREUR : " + $_.Exception.Message) -ForegroundColor Red; Read-Host "Envoyer cette capture dans le channel Claude. Entree pour fermer"; exit 1 }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { $a=@("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); if ($Restaurer){$a+="-Restaurer"}; if ($Systeme){$a+="-Systeme"}; if ($Auto){$a+="-Auto"}; if ($Desinstaller){$a+="-Desinstaller"}; if ($NonMsi){$a+="-NonMsi"}; if ($Dossiers){$a+=@("-Dossiers","`"$Dossiers`"")}; $a += @("-Nom","`"$Nom`"","-Motif","`"$Motif`""); Start-Process powershell.exe -Verb RunAs -ArgumentList $a; exit }

$Dir = "C:\ProgramData\MadeForMed\CegedimNeutralise"; New-Item -ItemType Directory -Force $Dir | Out-Null
$Journal = if ($Nom -eq "Cegedim") { Join-Path $Dir "journal.json" } else { Join-Path $Dir ("journal-" + ($Nom -replace '[^\w-]','_') + ".json") }
$Match  = $Motif
$Remote = 'teamviewer|anydesk|quick ?support|quickassist|assistance|splashtop|rustdesk|supremo|ammyy|vnc|logmein|bomgar|beyondtrust|remote|dameware|netviewer'
$Keep   = 'juxta|dmpconnect|icanopee|amelipro|srvsvcnam|santesocial|galss|cryptolib|cryptographiques|mica|fsv|oracle|orahome|tnslsnr|openvpn|postgres|psql'
# 28/09 (cabinet de groupe) : poste qui heberge la BASE de l'ancien logiciel (Oracle Cegedim/Crossway...) -> base jamais touchee,
# ni desinstallation ni quarantaine sur ce poste ; seuls les programmes lies au lecteur sont coupes.
$Serveur = [bool](Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { ($_.Name -match '^Oracle' -or $_.PathName -match 'oracle|TNSLSNR') -and ($_.PathName + ' ' + $_.Name) -match $Motif })
function OK { param($t) Write-Host "  [OK]  $t" -ForegroundColor Green }
function IN { param($t) Write-Host "        $t" }
# 30/09 : elements du systeme jamais cibles (sauf s'ils portent le nom de l'editeur) : taches \Microsoft\Windows\..., services svchost,
# Adobe / Acrobat (le motif "synchro" avait desactive SynchronizeTime, OneSyncSvc, vmictimesync, Adobe Acrobat Synchronizer...)
$Sys = '\\Microsoft\\|\\Windows\\|svchost|Adobe|Acrobat|OneSyncSvc|vmictimesync|w32time'
$NomRx = [regex]::Escape($Nom)
function EstSysteme { param([string]$txt) return ($txt -match $Sys -and $txt -notmatch $NomRx) }
# faux positif = element du systeme OU element que le motif corrige ne cible plus (ex. User_Feed_Synchronization, vmictimesync)
function FauxPositif { param([string]$txt) return (($txt -notmatch $Match) -or (EstSysteme $txt)) }
function Target { param([string]$txt) return ($txt -match $Match -and $txt -notmatch $Remote -and $txt -notmatch $Keep -and -not (EstSysteme $txt)) }

# ------------------------------------------------------------------ RESTAURATION
if ($Restaurer) {
    if (-not (Test-Path $Journal)) { Write-Host "Aucun journal : rien a restaurer." -ForegroundColor Yellow; Read-Host "Entree pour fermer"; exit 0 }
    $j = Get-Content $Journal -Raw | ConvertFrom-Json
    if ($Systeme) {
        # v1.5 : ne remet en route que les elements desactives a tort (Windows / Microsoft / Adobe, ou que le motif corrige ne cible plus ; motif trop large avant v0.3.32) ;
        # les elements de l'editeur restent neutralises. Les elements remis en route sortent du journal.
        $fRun = @(); $fSvc = @(); $fTask = @()
        foreach ($r in @($j.Run) | Where-Object { $_ }) { if (FauxPositif ($r.Name + ' ' + $r.Value)) { New-Item -Path $r.Key -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $r.Key -Name $r.Name -Value $r.Value -PropertyType String -Force | Out-Null; OK ("Demarrage restaure : " + $r.Name); $fRun += $r } }
        foreach ($s in @($j.Services) | Where-Object { $_ }) { $pn = [string](Get-CimInstance Win32_Service -Filter ("Name='" + $s.Name + "'") -ErrorAction SilentlyContinue).PathName; if (FauxPositif ($s.Name + ' ' + $pn)) { Set-Service -Name $s.Name -StartupType $s.StartMode -ErrorAction SilentlyContinue; OK ("Service " + $s.Name + " -> " + $s.StartMode); $fSvc += $s } }
        foreach ($tk in @($j.Tasks) | Where-Object { $_ }) { if (FauxPositif ($tk.Path + ' ' + $tk.Name)) { Enable-ScheduledTask -TaskPath $tk.Path -TaskName $tk.Name -ErrorAction SilentlyContinue | Out-Null; OK ("Tache reactivee : " + $tk.Name); $fTask += $tk } }
        if (-not ($fRun.Count + $fSvc.Count + $fTask.Count)) { Write-Host "Aucun element desactive a tort dans le journal : rien a remettre en route." -ForegroundColor Yellow }
        else { $j.Run = @($j.Run | Where-Object { $_ -and ($fRun -notcontains $_) }); $j.Services = @($j.Services | Where-Object { $_ -and ($fSvc -notcontains $_) }); $j.Tasks = @($j.Tasks | Where-Object { $_ -and ($fTask -notcontains $_) })
               $j | ConvertTo-Json -Depth 5 | Set-Content $Journal -Encoding UTF8
               Write-Host ("`nElements remis en route (desactives a tort) : " + ($fRun.Count + $fSvc.Count + $fTask.Count) + " (les elements " + $Nom + " restent neutralises).") -ForegroundColor Cyan }
        Read-Host "Entree pour fermer"; exit 0
    }
    foreach ($r in @($j.Run))      { New-Item -Path $r.Key -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $r.Key -Name $r.Name -Value $r.Value -PropertyType String -Force | Out-Null; OK ("Demarrage restaure : " + $r.Name) }
    foreach ($l in @($j.Lnk))      { if (Test-Path $l.Backup) { Move-Item $l.Backup $l.Path -Force; OK ("Raccourci restaure : " + $l.Path) } }
    foreach ($s in @($j.Services)) { Set-Service -Name $s.Name -StartupType $s.StartMode -ErrorAction SilentlyContinue; OK ("Service " + $s.Name + " -> " + $s.StartMode) }
    foreach ($d in @($j.Quarantaine)) { if ($d -and (Test-Path $d.Dst) -and -not (Test-Path $d.Src)) { Move-Item $d.Dst $d.Src -Force; OK ("Dossier remis en place : " + $d.Src) } }
    if (@($j.Desinstalles).Count) { Write-Host ("Produits desinstalles (a reinstaller par l'editeur si besoin) : " + ((@($j.Desinstalles) | ForEach-Object Nom) -join ", ")) -ForegroundColor Yellow }
    foreach ($t in @($j.Tasks))    { Enable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null; OK ("Tache reactivee : " + $t.Name) }
    Rename-Item $Journal ("journal-restaure-" + (Get-Date -Format yyyyMMdd-HHmm) + ".json")
    Write-Host ("`nEtat d'origine restaure. Les programmes " + $Nom + " se relanceront a la prochaine ouverture de session.") -ForegroundColor Cyan
    Read-Host "Entree pour fermer"; exit 0
}

# ------------------------------------------------------------------ INVENTAIRE
$Deja = Test-Path $Journal
# 28/09 : journal present mais ClmLive / java relances -> on ne s'arrete plus : nouvelle passe sur ce qui est revenu
if ($Deja) { Write-Host "Deja neutralise une premiere fois (journal present) : nouvelle passe sur les elements revenus." -ForegroundColor Yellow }
$runKeys = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run","HKCU:\Software\Microsoft\Windows\CurrentVersion\Run")
# retour terrain 28/09 : ClmLive / jFSE revenus au redemarrage -> aussi la ruche et le dossier Demarrage du MEDECIN
# (l'UAC peut avoir ete validee avec un autre compte que celui de la session ouverte)
$Doc = Get-CimInstance Win32_Process -Filter "name='explorer.exe'" -ErrorAction SilentlyContinue | Select-Object -First 1 | Invoke-CimMethod -MethodName GetOwner -ErrorAction SilentlyContinue
$DocStartup = ""
if ($Doc -and $Doc.User) {
    try { $sid = (New-Object Security.Principal.NTAccount ($(if ($Doc.Domain) { $Doc.Domain } else { $env:COMPUTERNAME }) + "\" + $Doc.User)).Translate([Security.Principal.SecurityIdentifier]).Value
          $runKeys += @(("Registry::HKEY_USERS\" + $sid + "\Software\Microsoft\Windows\CurrentVersion\Run"), ("Registry::HKEY_USERS\" + $sid + "\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run")) } catch {}
    $prof = (Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue | Where-Object { $_.LocalPath -like ("*\" + $Doc.User) } | Select-Object -First 1).LocalPath
    if ($prof) { $DocStartup = Join-Path $prof "AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" }
}
$runKeys = @($runKeys | Select-Object -Unique)
$runs = @(); foreach ($k in $runKeys) { $p = Get-ItemProperty $k -ErrorAction SilentlyContinue; if ($p) { foreach ($pr in $p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }) { if (Target ($pr.Name + ' ' + $pr.Value)) { $runs += [pscustomobject]@{Key=$k;Name=$pr.Name;Value=[string]$pr.Value} } } } }
$startDirs = @(@([Environment]::GetFolderPath("CommonStartup"), [Environment]::GetFolderPath("Startup"), $DocStartup) | Where-Object { $_ } | Select-Object -Unique)
$lnks = @(); foreach ($d in $startDirs) { Get-ChildItem $d -File -ErrorAction SilentlyContinue | Where-Object { Target $_.Name } | ForEach-Object { $lnks += $_ } }
$svcs = @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { (Target ($_.Name + ' ' + $_.DisplayName + ' ' + $_.PathName)) -and $_.StartMode -ne 'Disabled' })
$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -ne 'Disabled' -and (Target ($_.TaskName + ' ' + $_.TaskPath + ' ' + (($_.Actions | ForEach-Object { $_.Execute }) -join ' '))) })
$procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and ((Target $_.ProcessName) -or ($_.Path -match 'CEGEDIM|JFSE|Crossway')) -and ($_.Path -notmatch $Remote) -and ($_.ProcessName -notmatch $Keep) -and -not (EstSysteme $_.Path) })

Write-Host ("`nNeutraliser les residus " + $Nom + " (sans desinstaller, sans redemarrer)") -ForegroundColor Cyan
Write-Host ("A faire UNIQUEMENT si le medecin n'utilise plus " + $Nom + ".`n") -ForegroundColor Yellow
IN ("Entrees de demarrage : " + $(if ($runs) { ($runs | ForEach-Object Name) -join ", " } else { "aucune" }))
IN ("Raccourcis Demarrage : " + $(if ($lnks) { ($lnks | ForEach-Object Name) -join ", " } else { "aucun" }))
IN ("Services             : " + $(if ($svcs) { ($svcs | ForEach-Object { $_.Name + " (" + $_.StartMode + ")" }) -join ", " } else { "aucun" }))
IN ("Taches planifiees    : " + $(if ($tasks) { ($tasks | ForEach-Object TaskName) -join ", " } else { "aucune" }))
IN ("Processus a arreter  : " + $(if ($procs) { ($procs | ForEach-Object { $_.ProcessName + " (" + $_.Path + ")" }) -join ", " } else { "aucun" }))
if (-not ($runs -or $lnks -or $svcs -or $tasks -or $procs) -and -not $Desinstaller) { OK "Rien a neutraliser."; if (-not $Auto) { Read-Host "Entree pour fermer" }; exit 0 }
if (-not $Auto) {
try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
do { $r = (Read-Host ("`n>> Le medecin n'utilise plus " + $Nom + " : neutraliser ces elements ? [o/n]")).Trim() } while ($r -notmatch '^[oOnN]')
if ($r -notmatch '^[oO]') { Write-Host "Rien n'a ete modifie."; Read-Host "Entree pour fermer"; exit 0 }
}

# ------------------------------------------------------------------ NEUTRALISATION (journal ecrit AVANT chaque action)
if ($Deja) { $jj = Get-Content $Journal -Raw | ConvertFrom-Json; $j = [ordered]@{}; foreach ($pp in $jj.PSObject.Properties) { $j[$pp.Name] = @($pp.Value | Where-Object { $_ -ne $null }) }; $j.Date = [string]$jj.Date; $j.Poste = [string]$jj.Poste }
else { $j = [ordered]@{ Date=(Get-Date).ToString("s"); Poste=$env:COMPUTERNAME; Run=@(); Lnk=@(); Services=@(); Tasks=@() } }
foreach ($k in "Run","Lnk","Services","Tasks","Desinstalles","Quarantaine") { if (-not $j.Contains($k)) { $j[$k] = @() } }
function Save { $j | ConvertTo-Json -Depth 5 | Set-Content $Journal -Encoding UTF8 }
foreach ($x in $runs)  { $j.Run += $x; Save; Remove-ItemProperty -Path $x.Key -Name $x.Name -ErrorAction SilentlyContinue; OK ("Demarrage retire : " + $x.Name) }
foreach ($l in $lnks)  { $b = Join-Path $Dir ("lnk_" + [guid]::NewGuid().ToString("N").Substring(0,8) + "_" + $l.Name); $j.Lnk += [pscustomobject]@{Path=$l.FullName;Backup=$b}; Save; Move-Item $l.FullName $b -Force; OK ("Raccourci Demarrage mis de cote : " + $l.Name) }
foreach ($s in $svcs)  { $mode = @{Auto="Automatic";Manual="Manual";Boot="Automatic";System="Automatic"}[$s.StartMode]; if (-not $mode) { $mode = "Manual" }
                         $j.Services += [pscustomobject]@{Name=$s.Name;StartMode=$mode}; Save
                         Stop-Service -Name $s.Name -Force -ErrorAction SilentlyContinue; Set-Service -Name $s.Name -StartupType Disabled -ErrorAction SilentlyContinue; OK ("Service desactive : " + $s.Name) }
foreach ($t in $tasks) { $j.Tasks += [pscustomobject]@{Path=$t.TaskPath;Name=$t.TaskName}; Save; Disable-ScheduledTask -TaskPath $t.TaskPath -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null; OK ("Tache desactivee : " + $t.TaskName) }
Save
foreach ($p in $procs) {
    # Qui l'a lance ? (pour trouver un lanceur que la neutralisation ne couvre pas encore)
    $par = ""; try { $w = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $p.Id) -ErrorAction Stop; if ($w -and $w.ParentProcessId) { $pw = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $w.ParentProcessId) -ErrorAction Stop; if ($pw) { $par = " | lance par " + $pw.Name + " : " + $pw.CommandLine } } } catch {}
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; OK ("Processus arrete : " + $p.ProcessName + " (" + $p.Path + ")" + $par) }
# ------------------------------------------------------------------ DESINSTALLATION (reponse "n" : ne facture plus avec cet editeur)
# Historique : les desinstalleurs Cegedim NON-MSI ont redemarre des postes et fait perdre TeamViewer (24/09).
# Donc : MSI uniquement, un par un, REBOOT=ReallySuppress, delai max, et controle apres chaque produit.
if ($Desinstaller -and $Serveur) {
    Write-Host ("`nCe poste heberge la BASE DE DONNEES de " + $Nom + " (service Oracle) : utilisee par tout le cabinet / l'historique des dossiers.") -ForegroundColor Yellow
    Write-Host "Rien n'est desinstalle ni deplace sur ce poste. Seuls les programmes lies au lecteur ont ete coupes (ci-dessus)." -ForegroundColor Yellow
    $Desinstaller = $false
}
if ($Desinstaller) {
    Write-Host ("`nDesinstallation de " + $Nom + " (hors briques partagees, sans redemarrage)") -ForegroundColor Cyan
    $Shared = 'java|jre|\.net|visual c\+\+|redistribuable|redistributable|microsoft|sql server|adobe|acrobat'
    $Hives = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
    # Applications installees par utilisateur (ex. Weda Connect) : ruche de l'utilisateur courant et du medecin
    $Hives += "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"; if ($sid) { $Hives += ("Registry::HKEY_USERS\" + $sid + "\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") }
    $prods = @(Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and $_.DisplayName -notmatch $Shared -and (Target ([string]$_.DisplayName + ' ' + $_.Publisher + ' ' + $_.InstallLocation + ' ' + $_.InstallSource)) })
    function Guard {
        $g = [ordered]@{}
        foreach ($sv in @(Get-Service -ErrorAction SilentlyContinue | Where-Object { ($_.Name + ' ' + $_.DisplayName) -match $Remote })) { $g["service " + $sv.Name] = $true }
        foreach ($f in @("C:\Program Files (x86)\Juxta\JuxtaLink\JuxtaLink.exe", "C:\Program Files (x86)\santesocial\mica\mica.dll", "C:\Program Files (x86)\DmpConnect-JS2")) { if (Test-Path $f) { $g[$f] = $true } }
        return $g }
    function Get-SilentUninstall { param($pr)
        $q = [string]$pr.QuietUninstallString; $u = [string]$pr.UninstallString; $s = if ($q) { $q } else { $u }
        if (-not $s) { return $null }
        if ($s -match '^\s*"([^"]+)"\s*(.*)$') { $f = $Matches[1]; $a = $Matches[2] } elseif ($s -match '^\s*(.+?\.exe)\s*(.*)$') { $f = $Matches[1]; $a = $Matches[2] } else { return $null }
        if (-not (Test-Path $f)) { return $null }
        if (-not $q) {
            if ($f -match 'unins\d*\.exe$') { $a += ' /VERYSILENT /SUPPRESSMSGBOXES /NORESTART' }
            elseif ($f -match '\\Update\.exe$' -and $a -match '--uninstall') { $a += ' -s' }
            elseif ($f -match 'uninst') { $a += ' /S' }
            else { return $null }
        }
        return [pscustomobject]@{ File = $f; Args = $a.Trim() } }
    $avant = Guard; $stop = $false
    foreach ($pr in $prods) {
        $guid = if ($pr.PSChildName -match '^\{[0-9A-Fa-f-]{36}\}$') { $pr.PSChildName } else { "" }
        if (-not $guid -or ([string]$pr.UninstallString -notmatch 'msiexec')) {
            if (-not $NonMsi) { IN ("A retirer avec le support (desinstalleur non-MSI, risque de redemarrage) : " + $pr.DisplayName); continue }
            $sc = Get-SilentUninstall $pr
            if (-not $sc) { IN ("A retirer a la main (desinstalleur non reconnu ou absent) : " + $pr.DisplayName + " -> " + $pr.UninstallString); continue }
            IN ("Desinstallation silencieuse : " + $pr.DisplayName + " (" + $sc.File + " " + $sc.Args + ")")
            $pp = Start-Process -FilePath $sc.File -ArgumentList $sc.Args -PassThru -WindowStyle Hidden
            if (-not $pp.WaitForExit(300000)) { Write-Host ("  [KO]  " + $pr.DisplayName + " : pas termine apres 5 min, arret de la desinstallation") -ForegroundColor Red; $stop = $true; break }
            Start-Sleep 5   # les desinstalleurs NSIS/Squirrel se relancent parfois en copie temporaire
            $code = $pp.ExitCode; $j.Desinstalles += [pscustomobject]@{ Nom = [string]$pr.DisplayName; Guid = "non-MSI"; Code = $code }; Save
            $still = Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $pr.DisplayName }
            if (-not $still) { OK ("Desinstalle : " + $pr.DisplayName) } else { Write-Host ("  [WARN] " + $pr.DisplayName + " : toujours inscrit apres desinstallation (code " + $code + ") : verifier a la main") -ForegroundColor Yellow }
            $apres = Guard; $perdu = @($avant.Keys | Where-Object { -not $apres.Contains($_) })
            if ($perdu) { Write-Host ("  [KO]  ARRET : element disparu apres ce produit : " + ($perdu -join ", ") + " -> prevenir le support") -ForegroundColor Red; $stop = $true; break }
            continue
        }
        $pp = Start-Process msiexec.exe -ArgumentList "/x $guid /qn /norestart REBOOT=ReallySuppress MSIRESTARTMANAGERCONTROL=Disable" -PassThru
        if (-not $pp.WaitForExit(300000)) { Write-Host ("  [KO]  " + $pr.DisplayName + " : pas termine apres 5 min, arret de la desinstallation") -ForegroundColor Red; $stop = $true; break }
        $code = $pp.ExitCode
        $j.Desinstalles += [pscustomobject]@{ Nom = [string]$pr.DisplayName; Guid = $guid; Code = $code }; Save
        if ($code -in 0,1605,3010) { OK ("Desinstalle : " + $pr.DisplayName + $(if ($code -eq 3010) { " (redemarrage a faire plus tard, rien de force)" } else { "" })) }
        else { Write-Host ("  [WARN] " + $pr.DisplayName + " : msiexec code " + $code + " (laisse en place)") -ForegroundColor Yellow }
        $apres = Guard; $perdu = @($avant.Keys | Where-Object { -not $apres.Contains($_) })
        if ($perdu) { Write-Host ("  [KO]  ARRET : element disparu apres ce produit : " + ($perdu -join ", ") + " -> prevenir le support") -ForegroundColor Red; $stop = $true; break }
    }
    if (-not $prods) { OK "Aucun produit propre a l'editeur (briques partagees conservees)" }
    # Dossiers de l'editeur : quarantaine (deplacement sur le meme disque = instantane, reversible)
    if (-not $stop -and $Dossiers) {
        $q = Join-Path "C:\_Odaiji_a_supprimer" ($Nom + "-" + (Get-Date -Format yyyyMMdd-HHmm)); 
        foreach ($pat in ($Dossiers -split '\|')) {
            foreach ($d in @(Get-Item $pat -ErrorAction SilentlyContinue | Where-Object PSIsContainer)) {
                if ($d.FullName -match $Remote -or $d.FullName -match 'santesocial|Juxta|DmpConnect') { continue }
                Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like ($d.FullName + "\*") } | Stop-Process -Force -ErrorAction SilentlyContinue
                New-Item -ItemType Directory -Force $q | Out-Null; $dst = Join-Path $q ($d.FullName -replace '[:\\]','_')
                try { Move-Item $d.FullName $dst -ErrorAction Stop; $j.Quarantaine += [pscustomobject]@{ Src = $d.FullName; Dst = $dst }; Save; OK ("Dossier retire : " + $d.FullName + " (quarantaine " + $q + ")") }
                catch { Write-Host ("  [WARN] " + $d.FullName + " : fichiers en cours d'utilisation, laisse en place (" + $_.Exception.Message + ")") -ForegroundColor Yellow }
            }
        }
    }
    Save
    $nq = @($j.Quarantaine).Count
    $qtxt = if ($nq -gt 0) { "$nq dossier(s) en quarantaine (C:\_Odaiji_a_supprimer, a vider apres validation de la facturation Odaiji)" } else { "aucun dossier deplace" }
    Write-Host ("`nTermine. " + $Nom + " : lancement coupe, produits MSI desinstalles, " + $qtxt + ".") -ForegroundColor Cyan
    Write-Host "Briques partagees conservees : FSV, Cryptolib, MICA, GALSS, Java/.NET. Journal : $Journal" -ForegroundColor Cyan
} else {
Write-Host "`nTermine. Rien n'a ete desinstalle. Journal : $Journal" -ForegroundColor Cyan
Write-Host "Retour arriere possible par le support MadeForMed (journal ci-dessus)." -ForegroundColor Cyan
}
Write-Host "Ensuite : lecture CPS + Vitale + ADRi dans Odaiji, puis 3-Diag-seul.bat (section PERFORMANCE)."
if (-not $Auto) { Read-Host "Entree pour fermer" }
