<#
=====================================================================
 Odaiji_Juxta - Installation propre de JuxtaLink sur Windows
 MadeForMed / Odaiji - v0.3.35 (30/09/2026)
=====================================================================
 Lance par 1-Installer.bat (elevation UAC automatique).
 Contenu attendu du dossier :
   installeurs\SetupJuxtaLinkx86.msi   installeur JuxtaLink (WiX, 2.2.3 x86)
   installeurs\fsv-*.msi               FSV du GIE (repli si sesam.ini/tables manquent)
   user.config                          configuration MadeForMed
   OdaijiJuxta.ps1                      diagnostic / reparation
   galss-autofix.ps1 + Reparer-lecteur.bat   (option -WithAutofix)
 Deroule : 1 diag AVANT -> 2 MSI JuxtaLink -> 3 user.config -> 3b demarrage sans UAC -> 4 corrections auto sures -> 4b politiques Chrome/Edge
           -> 5 lancement + premiere lecture (le plugin installe FSV/GALSS/MICA/Cryptolib) -> 5a corrections rejouees
           -> 5 lancement + premiere lecture (le plugin SSV s'installe) -> 6 diag APRES
 Options : -NoInstall (poste deja equipe) ; -WithAutofix (lecteur a nommage instable)
           -AvecGalss (ne PAS retirer le GALSS x86 Juxta ; par defaut il est retire et bloque apres
                       la premiere lecture, avec retour arriere automatique si la lecture echoue ensuite)
 Le plugin SSV et ses prerequis (FSV, GALSS, MICA, Cryptolib) sont telecharges par
 JuxtaLink a la PREMIERE REQUETE : Internet requis, et un admin present pour l'UAC.
=====================================================================
#>
param([switch]$NoInstall, [switch]$WithAutofix, [switch]$AvecGalss)
trap { Write-Host ("`nERREUR : " + $_.Exception.Message) -ForegroundColor Red; Write-Host ($_.InvocationInfo.PositionMessage) -ForegroundColor DarkGray; Read-Host "Envoyer cette capture dans le channel Claude. Entree pour fermer"; exit 1 }

$Kit = Split-Path -Parent $MyInvocation.MyCommand.Path
# Retour terrain 29/09 : kit lance depuis le zip OUVERT (pas extrait) -> Windows le copie dans un dossier Temp purge ensuite ;
# JuxtaLink y garde sa source d'installation -> fenetres "package d'installation introuvable" a chaque reparation Windows.
if ($Kit -match '\\AppData\\Local\\Temp\\|\\Windows\\Temp\\|\.zip\\') {
    Write-Host "`nLe kit est lance depuis le zip, sans l'avoir extrait (dossier temporaire :" -ForegroundColor Red
    Write-Host "  $Kit)" -ForegroundColor Red
    Write-Host "`nFermer cette fenetre, faire clic droit sur le zip > Extraire tout..., puis relancer depuis le dossier extrait." -ForegroundColor Yellow
    Read-Host "`nEntree pour fermer"; exit 1
}
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { $a=@("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); if ($NoInstall){$a+="-NoInstall"}; if ($WithAutofix){$a+="-WithAutofix"}; if ($AvecGalss){$a+="-AvecGalss"}; Start-Process powershell.exe -Verb RunAs -ArgumentList $a; exit }
# Start-Process -Wait attend aussi les processus ENFANTS : si le diag relance JuxtaLink, l'installeur restait bloque
# (etape 4, DRSAMITIER 24/09). WaitForExit() n'attend que le diag lui-meme.
function Run-Diag { param($ArgList) $p = Start-Process powershell.exe -ArgumentList $ArgList -PassThru; $p.WaitForExit() }
# Lancement de JuxtaLink : via la tache \Odaiji\JuxtaLink (sans UAC, hors arbre de processus de l'installeur, etape 3b),
# sinon via explorer.exe (session du medecin). Fonctions dans JuxtaLink-Demarrage-lib.ps1.
try { . (Join-Path $Kit "JuxtaLink-Demarrage-lib.ps1") } catch { Write-Host ("  [WARN] Fonctions JuxtaLink-Demarrage non chargees : " + $_.Exception.Message) -ForegroundColor Yellow }
function Start-JuxtaUser { param($Exe) Start-JxTask | Out-Null }
function Say { param($t) Write-Host "`n==> $t" -ForegroundColor Cyan }
function OK  { param($t) Write-Host "    [OK]  $t" -ForegroundColor Green }
function KO  { param($t) Write-Host "    [KO]  $t" -ForegroundColor Red }

# --- Profil de l'utilisateur connecte (le medecin), meme si l'UAC a utilise un autre compte
$owner = (Get-CimInstance Win32_Process -Filter "name='explorer.exe'" | Select-Object -First 1 | Invoke-CimMethod -MethodName GetOwner)
$prof = (Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like ("*\" + $owner.User) } | Select-Object -First 1).LocalPath
if (-not $prof) { $prof = $env:USERPROFILE }
$UserAppData = Join-Path $prof "AppData\Roaming"
$Desktop = Join-Path $prof "Desktop"
# 05/10 : Bureau redirige vers OneDrive (ex. CABINET) : le diag ecrit dans le vrai Bureau, on cherche au meme endroit
try { $gd = [Environment]::GetFolderPath("Desktop"); if ($owner.User -eq $env:USERNAME -and $gd -and (Test-Path $gd)) { $Desktop = $gd } else { $od = Get-ChildItem $prof -Directory -Filter "OneDrive*" -ErrorAction SilentlyContinue | ForEach-Object { foreach ($n in "Desktop","Bureau") { Join-Path $_.FullName $n } } | Where-Object { Test-Path $_ } | Select-Object -First 1; if ($od -and -not (Test-Path (Join-Path $prof "Desktop"))) { $Desktop = $od } } } catch {}
$Journal = Join-Path $Desktop ("Installation_" + $env:COMPUTERNAME + "_" + (Get-Date -Format "yyyyMMdd-HHmm") + ".txt")
try { Start-Transcript -Path $Journal -Force | Out-Null } catch {}
Write-Host "Odaiji_Juxta - installation JuxtaLink sur $env:COMPUTERNAME pour l'utilisateur $($owner.User)"
$diagArgs = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$Kit\OdaijiJuxta.ps1`"","-NoPause","-UserAppData","`"$UserAppData`"")

# ---------------------------------------------------------------- 1. AVANT
Say "1/6  Diagnostic AVANT (lecture seule)"
Run-Diag ($diagArgs + @("-Prefix","Avant"))
$avant = Get-ChildItem "$Desktop\Avant_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($avant) { OK "Rapport : $($avant.FullName)"; Get-Content $avant.FullName | Select-String '^\s*\[KO\]|Scenario :' | Select-Object -First 10 | ForEach-Object { Write-Host "    $($_.Line.Trim())" } }

# ---------------------------------------------------------------- 1b. ANCIENS LOGICIELS METIERS (catalogue editeurs.psd1)
# Une question par editeur detecte, posee ici une seule fois (le diag de correction tourne sans question).
$sans = @(); $garde = @(); $edDet = @()
$cat = Join-Path $Kit "editeurs.psd1"
if (Test-Path $cat) {
    $procs = Get-Process -ErrorAction SilentlyContinue
    # 29/09 (HANSIANE) : HelloDoc installe mais ferme -> ni dossier connu ni processus : pas de question. On regarde aussi les programmes installes.
    $prods = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object DisplayName
    foreach ($e in (Import-PowerShellDataFile $cat).Editeurs) {
        $found = $false
        foreach ($d in $e.Dossiers) { if (Get-Item $d -ErrorAction SilentlyContinue) { $found = $true; break } }
        if (-not $found -and ($procs | Where-Object { ($_.ProcessName + ' ' + $(try { $_.Path } catch { '' })) -match $e.Motif -and $_.ProcessName -notmatch '^JuxtaLink' })) { $found = $true }
        if (-not $found -and ($prods | Where-Object { ($_.DisplayName + ' ' + $_.Publisher) -match $e.Motif -and $_.DisplayName -notmatch 'Cryptographiques|fsv|mica|galss' })) { $found = $true }
        if ($found) { $edDet += $e }
    }
}
if ($edDet) {
    Say "1b/6  Anciens logiciels metiers detectes sur ce poste"
    Write-Host "    Si Odaiji les remplace, repondre n : ils seront coupes puis DESINSTALLES (hors briques partagees FSV/Cryptolib/MICA, sans redemarrage)." -ForegroundColor Yellow
    foreach ($e in $edDet) {
        Write-Host ("    - " + $e.Nom + " : " + $e.Bloquants) -ForegroundColor DarkGray
        try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
        do { $r = (Read-Host ("    Le medecin facture-t-il ENCORE avec " + $e.Libelle + " ? [o/n]")).Trim() } while ($r -notmatch '^[oOnN]')
        if ($r -match '^[nN]') { $sans += $e.Nom; OK ($e.Nom + " : plus utilise -> sera coupe puis desinstalle (etape 4)") }
        else { $garde += $e.Nom; Write-Host ("    " + $e.Nom + " encore utilise : on n'y touche pas (" + $e.Bloquants + " : risque de blocage)") -ForegroundColor Yellow }
    }
    if ($sans)  { $diagArgs += @("-SansEditeurs","`"" + ($sans -join ",") + "`"") }
    if ($garde) { $diagArgs += @("-GardeEditeurs","`"" + ($garde -join ",") + "`"") }
}

# ---------------------------------------------------------------- 1c. PORT JUXTALINK (ancienne solution a l'ecoute)
$holder = Get-NetTCPConnection -LocalPort 1234 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue } | Where-Object { $_.ProcessName -notmatch '^JuxtaLink' } | Select-Object -First 1
if ($holder) { $hp = try { $holder.Path } catch { "" }; $own = $edDet | Where-Object { ($holder.ProcessName + ' ' + $hp) -match $_.Motif } | Select-Object -First 1 }
if ($holder -and $own) {
    if ($sans -contains $own.Nom) { $diagArgs += "-LibererPort"; OK ("Port 1234 tenu par " + $holder.ProcessName + " (" + $own.Nom + ", plus utilise) : il sera libere") }
    else { Write-Host ("    Port 1234 tenu par " + $holder.ProcessName + " (" + $own.Nom + ", encore utilise) : conflit a traiter avec les editeurs.") -ForegroundColor Yellow }
} elseif ($holder) {
    $hp = try { $holder.Path } catch { "" }; $hc = try { $holder.MainModule.FileVersionInfo.CompanyName } catch { "" }
    Say ("1c/6  Le port 1234 de JuxtaLink est occupe par " + $holder.ProcessName + " (" + $(if ($hc) { $hc } else { $hp }) + ")")
    try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
    do { $r = (Read-Host ("    Le medecin utilise-t-il ENCORE ce logiciel (" + $holder.ProcessName + ") ? [o/n]  (n = il sera neutralise)")).Trim() } while ($r -notmatch '^[oOnN]')
    if ($r -match '^[nN]') { $diagArgs += "-LibererPort"; OK "Il sera neutralise (sans desinstallation) pour liberer le port" }
    else { Write-Host "    Encore utilise : rien n'est modifie. Conflit de port a traiter avec le support (Odaiji ne pourra pas joindre JuxtaLink)." -ForegroundColor Yellow }
}

# ---------------------------------------------------------------- 2. MSI
if (-not $NoInstall) {
    Say "2/6  Installation de JuxtaLink (MSI silencieux)"
    $msi = Get-ChildItem "$Kit\installeurs\SetupJuxtaLink*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $msi) { KO "installeurs\SetupJuxtaLink*.msi introuvable"; Read-Host "Entree pour fermer"; exit 1 }
    Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2
    # 29/09 : le MSI est d'abord copie dans C:\ProgramData\MadeForMed\JuxtaLink = source PERMANENTE pour Windows Installer
    # (sinon il reste lie au dossier du kit : Telechargements supprime / Temp purge -> fenetres d'erreur a chaque reparation)
    $msiDir = "C:\ProgramData\MadeForMed\JuxtaLink"; New-Item -ItemType Directory -Force $msiDir | Out-Null
    $msiPerm = Join-Path $msiDir $msi.Name; Copy-Item $msi.FullName $msiPerm -Force
    $p = Start-Process msiexec.exe -ArgumentList "/i `"$msiPerm`" /qn /norestart ALLUSERS=1" -Wait -PassThru
    if ($p.ExitCode -in 0,3010,1638) { OK "JuxtaLink installe (msiexec $($p.ExitCode), source $msiPerm)" } else { KO "msiexec code $($p.ExitCode)"; Read-Host "Entree pour fermer"; exit 1 }
    try { $m = Get-JxMsi; if ($m -and -not $m.SourceOk) { Repair-JxMsiSource $msiPerm | Where-Object { $_ -ne "RELANCER" } | ForEach-Object { if ($_ -match '^ATTENTION') { KO $_ } else { OK $_ } } } } catch { KO ("Source MSI : " + $_.Exception.Message) }
} else { Say "2/6  Installation sautee (-NoInstall)" }

# ---------------------------------------------------------------- 3. user.config
Say "3/6  user.config (serveurs MadeForMed)"
$ucDir = Join-Path $UserAppData "juxta\juxtalink"; New-Item -ItemType Directory -Force $ucDir | Out-Null
$uc = Join-Path $ucDir "user.config"
if (Test-Path "$Kit\user.config") {
    if (Test-Path $uc) { Copy-Item $uc "$uc.bak-$(Get-Date -Format yyyyMMdd-HHmm)" -Force }
    Copy-Item "$Kit\user.config" $uc -Force; OK "user.config ecrit : $uc"
    Select-String $uc -Pattern 'tokenServerUrl|updateServerUrl|"port"' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    if ($env:APPDATA -and ($env:APPDATA -ne $UserAppData)) {
        $ucA = Join-Path $env:APPDATA "juxta\juxtalink"; New-Item -ItemType Directory -Force $ucA | Out-Null
        Copy-Item "$Kit\user.config" (Join-Path $ucA "user.config") -Force; OK "user.config ecrit aussi dans le profil du compte admin : $ucA"
    }
} else { KO "user.config absent du kit" }

# ---------------------------------------------------------------- 3b. DEMARRAGE SANS UAC
# retour terrain 28/09 : JuxtaLink exige l'UAC ; lance par une cle Run au demarrage de Windows, il est bloque en silence
# -> apres un redemarrage du PC, plus de JuxtaLink, "carte Vitale non lue". Tache planifiee "privileges eleves".
Say "3b/6  Demarrage de JuxtaLink sans fenetre UAC (tache planifiee a l'ouverture de session + icone Bureau)"
try { Install-JxTask -User ($(if ($owner.Domain) { $owner.Domain } else { $env:COMPUTERNAME }) + "\" + $owner.User) -UserAppData $UserAppData | ForEach-Object { if ($_ -match '^ATTENTION') { KO $_ } else { OK $_ } } }
catch { KO ("Tache de demarrage non creee : " + $_.Exception.Message + " (JuxtaLink demandera l'UAC a chaque lancement)") }

# ---------------------------------------------------------------- 4. FIX AUTO
Say "4/6  Corrections automatiques sures (sesam.ini, galss.ini, MICA x64 jFSE) - une fenetre s'ouvre, la laisser finir"
Write-Host "    (cartes CPS + Vitale inserees pour que galss.ini soit verifie avec les bons lecteurs)"
Run-Diag ($diagArgs + @("-Prefix","Fix","-Auto"))
$fix = Get-ChildItem "$Desktop\Fix_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($fix) { Get-Content $fix.FullName | Select-String '^>>|7[a-e]\.|\[OK\]   (sesam|galss|MICA)' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }; Remove-Item $fix.FullName -Force }
if ($WithAutofix) {
    $dst = "C:\ProgramData\MadeForMed"; New-Item -ItemType Directory -Force $dst | Out-Null
    Copy-Item "$Kit\galss-autofix.ps1" $dst -Force; Copy-Item "$Kit\Reparer-lecteur.bat" $Desktop -Force
    $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dst\galss-autofix.ps1`""
    schtasks /create /tn "MadeForMed galss-autofix (session)" /tr "$cmd" /sc onlogon /rl highest /f | Out-Null
    schtasks /create /tn "MadeForMed galss-autofix (5min)"    /tr "$cmd" /sc minute /mo 5 /rl highest /f | Out-Null
    OK "galss-autofix installe (taches planifiees + icone Reparer-lecteur.bat sur le Bureau)"
}

# ---------------------------------------------------------------- 4b. NAVIGATEURS
Say "4b/6  Chrome / Edge : autoriser Odaiji a joindre JuxtaLink (Local Network Access)"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$Kit\Autoriser-Odaiji-Chrome.ps1" -NoPause 2>&1 | Where-Object { $_ -notmatch 'Entree pour fermer' } | ForEach-Object { Write-Host "    $_" }

# ---------------------------------------------------------------- 5. LANCER
Say "5/6  Lancement de JuxtaLink"
$exe = "C:\Program Files (x86)\Juxta\JuxtaLink\JuxtaLink.exe"
function Test-Port1234 { try { if (Get-NetTCPConnection -LocalPort 1234 -State Listen -ErrorAction SilentlyContinue) { return $true }; throw "nolisten" } catch { return [bool](netstat -ano | Select-String ':1234\s+.*LISTENING') } }
if (Test-Path $exe) {
    # 02/10 : JuxtaLink pouvait deja tourner avec l'ancienne config (lance par le MSI ou le diag) -> toujours l'arreter, puis le relancer APRES user.config
    Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2
    Write-Host "    JuxtaLink arrete, user.config MadeForMed en place : relance..."
    for ($essai = 1; $essai -le 2; $essai++) {
        Start-JuxtaUser $exe
        for ($i = 0; $i -lt 15; $i++) { Start-Sleep 2; if ((Get-Process JuxtaLink -ErrorAction SilentlyContinue) -and (Test-Port1234)) { break } }
        if ((Get-Process JuxtaLink -ErrorAction SilentlyContinue) -and (Test-Port1234)) { break }
        if ($essai -eq 1) { Write-Host "    [WARN] JuxtaLink pas encore a l'ecoute : nouvel essai de lancement" -ForegroundColor Yellow; Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2 }
    }
    if (Get-Process JuxtaLink -ErrorAction SilentlyContinue) { OK "JuxtaLink en cours d'execution" } else { KO "JuxtaLink ne s'est pas lance (bloque par l'UAC, un antivirus ou SmartScreen ? le lancer a la main via l'icone du Bureau avant de continuer)" }
    if (Test-Port1234) { OK "JuxtaLink ecoute sur le port 1234" } else { KO "Rien n'ecoute sur le port 1234 : ne pas enregistrer la situation de facturation avant que JuxtaLink soit lance" }
} else { KO "JuxtaLink.exe introuvable" }
function Banner { param($lines, $bg="DarkMagenta")
    Write-Host ""
    $w = 70
    Write-Host ("  " + ("#" * $w)) -ForegroundColor White -BackgroundColor $bg
    foreach ($l in $lines) { Write-Host ("  # " + $l.PadRight($w - 4) + " #") -ForegroundColor White -BackgroundColor $bg }
    Write-Host ("  " + ("#" * $w)) -ForegroundColor White -BackgroundColor $bg
    Write-Host ""
}
try { [console]::Beep(880,300) } catch {}
Banner @("JUXTALINK REDEMARRE : installation automatique en cours de", "   FSV  -  GALSS  -  MICA  -  Cryptolib", "   (accepter les fenetres UAC si elles apparaissent)", "",
         "APRES L'INSTALLATION, dans Odaiji (navigateur) :", "   -> Enregistrer la situation de facturation", "      (l'installation des SSV demarre a ce moment-la)", "   -> puis UNE lecture CPS + Vitale (cartes inserees)")
Read-Host "    Entree quand l'installation est terminee et la situation de facturation enregistree (ou tout de suite pour passer)"

# ---------------------------------------------------------------- 5a. CORRECTIONS APRES INSTALLATION DU PLUGIN
Say "5a/6  Corrections apres installation des composants par le plugin (sesam.ini, tables, MICA)"
Run-Diag ($diagArgs + @("-Prefix","Fix2","-Auto"))
$fix2 = Get-ChildItem "$Desktop\Fix2_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($fix2) { Get-Content $fix2.FullName | Select-String '^>>|7[a-e]\.|\[OK\]   (sesam|galss|MICA|mica)' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }; Remove-Item $fix2.FullName -Force }

# ---------------------------------------------------------------- 5b. SANS GALSS (par defaut, demande Juxta)
if (-not $AvecGalss) {
    Say "5b/6  Full PC/SC (demande Juxta) : retrait du GALSS x86 Juxta + blocage de sa reinstallation"
    Run-Diag ($diagArgs + @("-Prefix","Galss","-Auto","-SansGalss"))
    $gl = Get-ChildItem "$Desktop\Galss_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($gl) { Get-Content $gl.FullName | Select-String '7g\.|Prerequis|BLOQUER|GALSS x86|msiexec|Residus' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }; Remove-Item $gl.FullName -Force }
    Write-Host "    >>> Dans Odaiji : une facture avec une carte Vitale, puis une facture sans Vitale (valider l'appel ADRi) - mode PC/SC direct." -ForegroundColor Magenta
    Read-Host "    Entree une fois testee"
}

# ---------------------------------------------------------------- 5c. REDEMARRAGE PROPRE
# Retour terrain DRSAMITIER 24/09 : 1re lecture Vitale en echec, OK apres redemarrage de JuxtaLink
# (composants installes par le plugin pendant la session JuxtaLink). On termine toujours par un redemarrage.
Say "5c/6  Redemarrage propre de JuxtaLink (charge les composants installes par le plugin)"
Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 3
if (Test-Path $exe) { Start-JuxtaUser $exe; Start-Sleep 10; if (Get-Process JuxtaLink -ErrorAction SilentlyContinue) { OK "JuxtaLink redemarre" } else { KO "JuxtaLink ne s'est pas relance : double-cliquer l'icone JuxtaLink (Odaiji) du Bureau" } }
Write-Host "    >>> CONTROLE dans Odaiji : une facture avec une carte Vitale, puis une facture sans Vitale (valider l'appel ADRi)." -ForegroundColor Magenta
Read-Host "    Entree une fois la lecture faite"

# ---------------------------------------------------------------- 5d. GALSS.INI (DMP Connect / iCanopee)
# 01/10 (DRLECLERE) : galss.ini absent apres l'installation, ou reste en mode serie : DMP Connect / iCanopee ne lit plus la CPS.
# -> on enchaine automatiquement avec la logique de Reparer-lecteur.bat (galss-autofix.ps1), puis on redemarre le service DMP Connect.
$galIni = "C:\Windows\galss.ini"
$dmpInst = (Test-Path "C:\Program Files (x86)\DmpConnect-JS2") -or (Test-Path "C:\Program Files\santesocial\galss")
if ($dmpInst) {
    $gtxt = ""; if (Test-Path $galIni) { $gtxt = Get-Content $galIni -Raw -ErrorAction SilentlyContinue }
    $gAbsent = -not (Test-Path $galIni)
    $gSerie = (-not $gAbsent) -and ($gtxt -match 'Caracteristiques\s*=\s*\d+,\d+,\d+')
    if ($gAbsent -or $gSerie) {
        Say "5d/6  galss.ini $(if ($gAbsent) { 'ABSENT' } else { 'en mode serie (pas PC/SC)' }) : reparation du lecteur pour DMP Connect / iCanopee"
        Write-Host "    (CPS + Vitale inserees dans le lecteur)" -ForegroundColor Magenta
        $afI = Join-Path $Kit "galss-autofix.ps1"
        if (Test-Path $afI) {
            $afLogI = Join-Path $env:ProgramData "MadeForMed\galss-autofix.log"; $beforeI = @(Get-Content $afLogI -ErrorAction SilentlyContinue).Count
            $paI = Start-Process powershell.exe -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-WindowStyle","Hidden","-File","`"$afI`"","-NoRelaunch") -PassThru
            if (-not $paI.WaitForExit(60000)) { try { $paI.Kill() } catch {}; KO "galss-autofix : delai depasse (60 s)" }
            @(Get-Content $afLogI -ErrorAction SilentlyContinue) | Select-Object -Skip $beforeI | ForEach-Object { Write-Host "    $_" }
            # uniquement le service iCanopee (DmpConnect-JS2), jamais un service desactive ni celui d'un autre logiciel
            $svcD = @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { ($_.Name -match 'dmpconnect' -or $_.DisplayName -match 'DmpConnect') -and $_.PathName -match 'DmpConnect-JS2' -and $_.StartMode -ne 'Disabled' })
            foreach ($sv in $svcD) { try { Restart-Service $sv.Name -Force -ErrorAction Stop; OK ("Service redemarre : " + $sv.Name) } catch { try { Start-Service $sv.Name -ErrorAction Stop } catch { Write-Host ("    service " + $sv.Name + " non redemarre : " + $_.Exception.Message) } } }
            Start-Sleep -Seconds 4
            foreach ($sv in $svcD) { $st = (Get-Service $sv.Name -ErrorAction SilentlyContinue).Status; if ($st -eq 'Running') { OK ("DMP Connect actif : " + $sv.Name) } else { try { Start-Service $sv.Name -ErrorAction Stop; OK ("Service relance : " + $sv.Name) } catch { KO ("DMP Connect arrete (" + $sv.Name + ") : redemarrer le service ou le poste") } } }
            $gOk = (Test-Path $galIni) -and ((Get-Content $galIni -Raw) -notmatch 'Caracteristiques\s*=\s*\d+,\d+,\d+')
            if ($gOk) { OK "galss.ini en PC/SC : tester une lecture CPS dans iCanopee" } else { KO "galss.ini toujours absent / serie : inserer CPS + Vitale puis lancer Reparer-lecteur.bat" }
        } else { KO "galss-autofix.ps1 introuvable dans le kit" }
    }
}

# ---------------------------------------------------------------- 6. APRES
# ---------------------------------------------------------------- 5e. CONFORT (identique au depannage) : CertPropSvc en Manuel + menage des Cryptolib en doublon
$cps = Get-Service CertPropSvc -ErrorAction SilentlyContinue
if ($cps -and $cps.StartType -eq 'Automatic') {
    Say "5e/6  Lecture de la carte CPS plus rapide : service Windows CertPropSvc passe en Manuel (automatique, reversible)"
    Write-Host "    Par defaut, Windows relit TOUS les certificats de la CPS a chaque insertion ; en Manuel il ne le fait plus : sans effet sur Odaiji ni la facturation." -ForegroundColor Yellow
    try { Set-Service CertPropSvc -StartupType Manual; Stop-Service CertPropSvc -Force -ErrorAction SilentlyContinue; OK "CertPropSvc : Manuel (retour arriere : Set-Service CertPropSvc -StartupType Automatic)" } catch { KO ("CertPropSvc : " + $_.Exception.Message) }
}
$nbCr = @(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Cryptographiques CPS' }).Count
if ($nbCr -gt 2) {
    Say "5f/6  Menage : $nbCr Cryptolib CPS installees sur ce poste"
    Write-Host "    Les Cryptolib en doublon ne servent a rien. Le menage garde la plus recente de chaque type (x86 / x64) et NE TOUCHE JAMAIS a celles des outils" -ForegroundColor Yellow
    Write-Host "    Assurance Maladie (ProgramData\santesocial) ni de DMP Connect / iCanopee. Il propose aussi de retirer les anciennes FSV inutilisees (une confirmation par element)." -ForegroundColor Yellow
    try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
    do { $rn = (Read-Host "    Lancer le menage des Cryptolib en doublon ? [o/n]").Trim() } while ($rn -notmatch '^[oOnN]')
    if ($rn -match '^[oO]') { Run-Diag ($diagArgs + @("-Prefix","Nettoyage","-Nettoyage")); Get-ChildItem "$Desktop\Nettoyage_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { Get-Content $_.FullName | Select-String 'Cryptolib|desinstall|msiexec|\[KO\]' | ForEach-Object { Write-Host "    $($_.Line.Trim())" } } }
}

Say "6/6  Diagnostic APRES"
Run-Diag ($diagArgs + @("-Prefix","Apres"))
$apres = Get-ChildItem "$Desktop\Apres_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($apres) { OK "Rapport : $($apres.FullName)"; Get-Content $apres.FullName | Select-String 'Scenario :|^\s*\[KO\]|^\s*\[WARN\]' | Select-Object -First 12 | ForEach-Object { Write-Host "    $($_.Line.Trim())" } }
Write-Host "`nTermine. Si le scenario n'est pas OK : envoyer Avant_*.txt et Apres_*.txt dans le channel Claude."
try { Stop-Transcript | Out-Null } catch {}
try { & (Join-Path $Kit "Envoyer-journal.ps1") -Fichier $Journal -Raison "journal installation" } catch {}
Read-Host "Entree pour fermer"
