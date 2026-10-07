<#
=====================================================================
 Odaiji_Juxta - DEPANNAGE d'un poste ou JuxtaLink est DEJA installe
 MadeForMed / Odaiji - v1.1.5 (07/10/2026)
=====================================================================
 Lance par 2-Depanner.bat (elevation UAC automatique). Un seul double-clic :
   1 diag AVANT -> 2 questions (anciens logiciels, port 1234) -> 3 corrections sures automatiques (-Fix -Auto)
   -> 3b Full PC/SC (SansGalss) automatique -> 4 reparation du lecteur / autorisation Chrome-Edge si le diag les justifie -> 5 relance de JuxtaLink
   -> 6 CertPropSvc en Manuel (automatique) + question menage Cryptolib -> 7 diag APRES + resume.
 Tout ce qui s'affiche est aussi enregistre dans Depannage_<poste>_<date>.txt sur le Bureau (a envoyer avec
 les rapports Avant_ et Apres_ pour faire evoluer le kit).
 Pour un poste NEUF (JuxtaLink absent) : 1-Installer.bat.
=====================================================================
#>
param()
trap { Write-Host ("`nERREUR : " + $_.Exception.Message) -ForegroundColor Red; Write-Host ($_.InvocationInfo.PositionMessage) -ForegroundColor DarkGray; Read-Host "Envoyer cette capture dans le channel Claude. Entree pour fermer"; exit 1 }

$Kit = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($Kit -match '\\AppData\\Local\\Temp\\|\\Windows\\Temp\\|\.zip\\') {
    Write-Host "`nLe kit est lance depuis le zip, sans l'avoir extrait (dossier temporaire :" -ForegroundColor Red
    Write-Host "  $Kit)" -ForegroundColor Red
    Write-Host "`nFermer cette fenetre, faire clic droit sur le zip > Extraire tout..., puis relancer depuis le dossier extrait." -ForegroundColor Yellow
    Read-Host "`nEntree pour fermer"; exit 1
}
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Start-Process powershell.exe -Verb RunAs -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); exit }

function Run-Diag { param($ArgList) $p = Start-Process powershell.exe -ArgumentList $ArgList -PassThru; $p.WaitForExit() }
try { . (Join-Path $Kit "JuxtaLink-Demarrage-lib.ps1") } catch { Write-Host ("  [WARN] Fonctions JuxtaLink-Demarrage non chargees : " + $_.Exception.Message) -ForegroundColor Yellow }
function Say  { param($t) Write-Host "`n==> $t" -ForegroundColor Cyan }
function OK   { param($t) Write-Host "    [OK]  $t" -ForegroundColor Green }
function KO   { param($t) Write-Host "    [KO]  $t" -ForegroundColor Red }
function Warn { param($t) Write-Host "    [WARN] $t" -ForegroundColor Yellow }
function Ask  { param([string]$q) try { $Host.UI.RawUI.FlushInputBuffer() } catch {}; do { $r = (Read-Host ($q + " [o/n]")).Trim() } while ($r -notmatch '^[oOnN]'); return ($r -match '^[oO]') }
function Test-Port1234 { try { if (Get-NetTCPConnection -LocalPort 1234 -State Listen -ErrorAction SilentlyContinue) { return $true }; throw "nolisten" } catch { return [bool](netstat -ano | Select-String ':1234\s+.*LISTENING') } }

# --- Profil du medecin (session ouverte), meme si l'UAC a utilise un autre compte
$owner = (Get-CimInstance Win32_Process -Filter "name='explorer.exe'" | Select-Object -First 1 | Invoke-CimMethod -MethodName GetOwner)
$prof = (Get-CimInstance Win32_UserProfile | Where-Object { $_.LocalPath -like ("*\" + $owner.User) } | Select-Object -First 1).LocalPath
if (-not $prof) { $prof = $env:USERPROFILE }
$UserAppData = Join-Path $prof "AppData\Roaming"
$Desktop = Join-Path $prof "Desktop"
# 05/10 : Bureau redirige vers OneDrive (ex. CABINET) : le diag ecrit dans le vrai Bureau, on cherche au meme endroit
try { $gd = [Environment]::GetFolderPath("Desktop"); if ($owner.User -eq $env:USERNAME -and $gd -and (Test-Path $gd)) { $Desktop = $gd } else { $od = Get-ChildItem $prof -Directory -Filter "OneDrive*" -ErrorAction SilentlyContinue | ForEach-Object { foreach ($n in "Desktop","Bureau") { Join-Path $_.FullName $n } } | Where-Object { Test-Path $_ } | Select-Object -First 1; if ($od -and -not (Test-Path (Join-Path $prof "Desktop"))) { $Desktop = $od } } } catch {}
$exe = "C:\Program Files (x86)\Juxta\JuxtaLink\JuxtaLink.exe"
$diagArgs = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$Kit\OdaijiJuxta.ps1`"","-NoPause","-UserAppData","`"$UserAppData`"")
$Stamp = Get-Date -Format "yyyyMMdd-HHmm"
$Journal = Join-Path $Desktop ("Depannage_" + $env:COMPUTERNAME + "_" + $Stamp + ".txt")
try { Start-Transcript -Path $Journal -Force | Out-Null } catch {}
Write-Host "Odaiji_Juxta - DEPANNAGE sur $env:COMPUTERNAME pour l'utilisateur $($owner.User)  (kit v1.1.5)"

if (-not (Test-Path $exe)) {
    KO "JuxtaLink n'est pas installe sur ce poste : utiliser 1-Installer.bat (poste neuf)."
    try { Stop-Transcript | Out-Null } catch {}; Read-Host "Entree pour fermer"; exit 1
}

function Get-Codes { param($Fichier) $c = @(); foreach ($l in (Get-Content $Fichier -ErrorAction SilentlyContinue)) { if ($l -match '^\s{8,}([A-Z][A-Z0-9_]+)\s+(KO|WARN|INFO)\s') { $c += $Matches[1] } }; return $c }
function Get-LastReport { param($Prefix) Get-ChildItem "$Desktop\${Prefix}_*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 }

# ---------------------------------------------------------------- 1. AVANT
Say "1/7  Diagnostic AVANT (lecture seule)"
Run-Diag ($diagArgs + @("-Prefix","Avant"))
$avant = Get-LastReport "Avant"
if (-not $avant) { KO "Rapport Avant introuvable"; try { Stop-Transcript | Out-Null } catch {}; Read-Host "Entree pour fermer"; exit 1 }
OK "Rapport : $($avant.FullName)"
Get-Content $avant.FullName | Select-String '^\s*\[KO\]|Scenario :' | Select-Object -First 12 | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
$codes = Get-Codes $avant.FullName
$avantTxt = Get-Content $avant.FullName -Raw

# ---------------------------------------------------------------- 2. ANCIENS LOGICIELS + PORT 1234 (questions posees une seule fois)
$sans = @(); $garde = @(); $edDet = @()
$cat = Join-Path $Kit "editeurs.psd1"
if (Test-Path $cat) {
    $procs = Get-Process -ErrorAction SilentlyContinue
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
    Say "2/7  Anciens logiciels metiers detectes sur ce poste"
    Write-Host "    Ces logiciels se disputent le lecteur de cartes avec JuxtaLink. S'ils ne servent plus au medecin (il facture avec Odaiji), ils sont coupes" -ForegroundColor Yellow
    Write-Host "    puis desinstalles (hors briques partagees FSV/Cryptolib/MICA, sans redemarrage). S'ils servent encore : on n'y touche pas." -ForegroundColor Yellow
    foreach ($e in $edDet) {
        Write-Host ("    - " + $e.Nom + " : " + $e.Bloquants) -ForegroundColor DarkGray
        if (Ask ("    Le medecin facture-t-il ENCORE avec " + $e.Libelle + " ?")) { $garde += $e.Nom; Write-Host ("    " + $e.Nom + " encore utilise : on n'y touche pas") -ForegroundColor Yellow }
        else { $sans += $e.Nom; OK ($e.Nom + " : plus utilise -> sera coupe puis desinstalle") }
    }
    if ($sans)  { $diagArgs += @("-SansEditeurs","`"" + ($sans -join ",") + "`"") }
    if ($garde) { $diagArgs += @("-GardeEditeurs","`"" + ($garde -join ",") + "`"") }
}
$holder = Get-NetTCPConnection -LocalPort 1234 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue } | Where-Object { $_.ProcessName -notmatch '^JuxtaLink' } | Select-Object -First 1
if ($holder) {
    $hp = try { $holder.Path } catch { "" }; $own = $edDet | Where-Object { ($holder.ProcessName + ' ' + $hp) -match $_.Motif } | Select-Object -First 1
    if ($own) {
        if ($sans -contains $own.Nom) { $diagArgs += "-LibererPort"; OK ("Port 1234 tenu par " + $holder.ProcessName + " (" + $own.Nom + ", plus utilise) : il sera libere") }
        else { Warn ("Port 1234 tenu par " + $holder.ProcessName + " (" + $own.Nom + ", encore utilise) : conflit a traiter avec le support") }
    } else {
        Say ("2b/7  Le port 1234 de JuxtaLink est occupe par " + $holder.ProcessName)
        if (-not (Ask ("    Le medecin utilise-t-il ENCORE ce logiciel (" + $holder.ProcessName + ") ? (non = il sera neutralise, sans desinstallation)"))) { $diagArgs += "-LibererPort"; OK "Il sera neutralise pour liberer le port" }
        else { Warn "Encore utilise : rien n'est modifie ; Odaiji ne pourra pas joindre JuxtaLink tant que le port est pris" }
    }
}

# ---------------------------------------------------------------- 3. CORRECTIONS SURES (sesam.ini, [MGC], tables FSV, MICA, galss.ini, user.config...)
$aCorriger = @($codes | Where-Object { $_ -notin @('STACK_X64','SRT_EMPTY','MSI_ECHEC','CERTPROP_AUTO','SESAM_WIN_ABSENT') })
$changed = $false
if ($aCorriger.Count -or $sans.Count) {
    Say "3/7  Corrections automatiques sures (une fenetre s'ouvre, la laisser finir) : $($aCorriger -join ', ')"
    Run-Diag ($diagArgs + @("-Prefix","Fix","-Auto"))
    $fix = Get-LastReport "Fix"
    if ($fix) { Get-Content $fix.FullName | Select-String '^>>|7[a-z]\.|\[OK\]   (sesam|galss|MICA|user\.config)|\[KO\]' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }; Remove-Item $fix.FullName -Force }
    $changed = $true
} else { OK "3/7  Rien a corriger automatiquement" }

# ---------------------------------------------------------------- 3b. FULL PC/SC (retrait du GALSS x86 Juxta + blocage de sa reinstallation)
# Automatique si le GALSS x86 est encore la, est revenu, ou si sa reinstallation n'est pas bloquee (plugin SSV present). Le diag verifie
# ses prerequis (lecteur PC/SC visible, Cryptolib hors filiere GALSS) et s'arrete sans rien retirer sinon ; galss.ini est sauvegarde/restaure.
if ($avantTxt -match 'GALSS x86 installe' -or $codes -contains 'GALSS_X86_BACK' -or $avantTxt -match 'BLOQUERINSTALLEGALSS dans le plugin SSV : false') {
    Say "3b/7  Full PC/SC : retrait du GALSS x86 Juxta + blocage de sa reinstallation (automatique)"
    Run-Diag ($diagArgs + @("-Prefix","Galss","-Auto","-SansGalss"))
    $gl = Get-LastReport "Galss"
    if ($gl) { Get-Content $gl.FullName | Select-String '7g\.|Prerequis|BLOQUER|GALSS x86|msiexec|Residus|galss\.ini' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }; Remove-Item $gl.FullName -Force }
    $changed = $true
}

# ---------------------------------------------------------------- 4. LECTEUR (galss.ini) + CHROME/EDGE
if ($codes | Where-Object { $_ -like 'GALSS_*' }) {
    Say "4a/7  Reparation du lecteur pour DMP Connect / iCanopee (CPS + Vitale inserees dans le lecteur)"
    $af = Join-Path $Kit "galss-autofix.ps1"
    if (Test-Path $af) {
        # 04/10 (poste MSI) : la CPS avait ete retiree entre le diag Avant et cette etape -> "Aucune carte vue", galss.ini non recree
        Write-Host "    >>> Inserer la CPS ET la Vitale dans le lecteur (les laisser jusqu'a la fin de cette etape)." -ForegroundColor Magenta
        [void](Read-Host "    Entree quand c'est fait")
        $afLog = Join-Path $env:ProgramData "MadeForMed\galss-autofix.log"
        for ($essai = 1; $essai -le 2; $essai++) {
            $before = @(Get-Content $afLog -ErrorAction SilentlyContinue).Count
            $pa = Start-Process powershell.exe -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-WindowStyle","Hidden","-File","`"$af`"","-NoRelaunch") -PassThru
            if (-not $pa.WaitForExit(60000)) { try { $pa.Kill() } catch {}; KO "galss-autofix : delai depasse (60 s)" }
            $afNew = @(Get-Content $afLog -ErrorAction SilentlyContinue) | Select-Object -Skip $before
            $afNew | ForEach-Object { Write-Host "    $_" }
            if ($essai -eq 1 -and ($afNew | Where-Object { $_ -match 'Aucune carte vue|Aucun lecteur' })) {
                Warn "Aucune carte vue par Windows : verifier que la CPS et la Vitale sont bien enfoncees dans le lecteur."
                [void](Read-Host "    Entree pour reessayer une fois")
            } else { break }
        }
        $svcD = @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { ($_.Name -match 'dmpconnect' -or $_.DisplayName -match 'DmpConnect') -and $_.PathName -match 'DmpConnect-JS2' -and $_.StartMode -ne 'Disabled' })
        foreach ($sv in $svcD) { try { Restart-Service $sv.Name -Force -ErrorAction Stop; OK ("Service redemarre : " + $sv.Name) } catch { try { Start-Service $sv.Name -ErrorAction Stop } catch { Write-Host ("    service " + $sv.Name + " non redemarre : " + $_.Exception.Message) } } }
        Start-Sleep -Seconds 4
        foreach ($sv in $svcD) { if ((Get-Service $sv.Name -ErrorAction SilentlyContinue).Status -eq 'Running') { OK ("DMP Connect actif : " + $sv.Name) } else { KO ("DMP Connect arrete (" + $sv.Name + ") : redemarrer le service ou le poste") } }
    } else { KO "galss-autofix.ps1 introuvable dans le kit" }
}
if ($codes | Where-Object { $_ -like 'LNA_*' }) {
    Say "4b/7  Chrome / Edge : autoriser Odaiji a joindre JuxtaLink"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$Kit\Autoriser-Odaiji-Chrome.ps1" -NoPause 2>&1 | Where-Object { $_ -notmatch 'Entree pour fermer' } | ForEach-Object { Write-Host "    $_" }
}

# ---------------------------------------------------------------- 5. RELANCE DE JUXTALINK (recharge sesam.ini, galss.ini, user.config)
$juxtaTourne = [bool](Get-Process JuxtaLink -ErrorAction SilentlyContinue)
if ($changed -or -not $juxtaTourne -or -not (Test-Port1234)) {
    Say "5/7  Redemarrage de JuxtaLink (recharge la configuration)"
    Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2
    for ($essai = 1; $essai -le 2; $essai++) {
        try { Start-JxTask | Out-Null } catch { Warn ("Tache de demarrage : " + $_.Exception.Message) }
        for ($i = 0; $i -lt 15; $i++) { Start-Sleep 2; if ((Get-Process JuxtaLink -ErrorAction SilentlyContinue) -and (Test-Port1234)) { break } }
        if ((Get-Process JuxtaLink -ErrorAction SilentlyContinue) -and (Test-Port1234)) { break }
        if ($essai -eq 1) { Warn "JuxtaLink pas encore a l'ecoute : nouvel essai"; Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2 }
    }
    if (Get-Process JuxtaLink -ErrorAction SilentlyContinue) { OK "JuxtaLink en cours d'execution" } else { KO "JuxtaLink ne s'est pas lance (UAC, antivirus ou SmartScreen ? le lancer a la main via l'icone du Bureau)" }
    if (Test-Port1234) { OK "JuxtaLink ecoute sur le port 1234" } else { KO "Rien n'ecoute sur le port 1234" }
} else { OK "5/7  JuxtaLink deja lance et a l'ecoute, rien a relancer" }

# ---------------------------------------------------------------- 6. QUESTIONS DE CONFORT (CertPropSvc, menage Cryptolib)
if ($codes -contains 'CERTPROP_AUTO') {
    Say "6a/7  Lecture de la carte CPS plus rapide : service Windows CertPropSvc passe en Manuel (automatique, reversible)"
    Write-Host "    Par defaut, Windows relit TOUS les certificats de la CPS a chaque insertion ; en Manuel il ne le fait plus : sans effet sur Odaiji ni la facturation." -ForegroundColor Yellow
    try { Set-Service CertPropSvc -StartupType Manual; Stop-Service CertPropSvc -Force -ErrorAction SilentlyContinue; OK "CertPropSvc : Manuel (retour arriere : Set-Service CertPropSvc -StartupType Automatic)" } catch { KO ("CertPropSvc : " + $_.Exception.Message) }
}
if ($avantTxt -match 'Cryptolib CPS installee (\d+) fois') {
    $nb = $Matches[1]
    Say "6b/7  Menage : $nb Cryptolib CPS installees sur ce poste"
    Write-Host "    Les Cryptolib en doublon ne servent a rien et alourdissent le poste. Le menage garde la plus recente de chaque type (x86 / x64)" -ForegroundColor Yellow
    Write-Host "    et NE TOUCHE JAMAIS a celles des outils Assurance Maladie (ProgramData\santesocial) ni de DMP Connect / iCanopee." -ForegroundColor Yellow
    Write-Host "    Il propose aussi de retirer les anciennes versions FSV inutilisees (une confirmation par element). Aucun logiciel metier n'est desinstalle. Conseille : oui." -ForegroundColor Yellow
    if (Ask "    Lancer le menage des Cryptolib en doublon ?") { Run-Diag ($diagArgs + @("-Prefix","Nettoyage","-Nettoyage")); $nt = Get-LastReport "Nettoyage"; if ($nt) { Get-Content $nt.FullName | Select-String 'Cryptolib|desinstall|msiexec|\[KO\]' | ForEach-Object { Write-Host "    $($_.Line.Trim())" } } }
    else { Write-Host "    Menage non fait (Nettoyage.bat reste disponible plus tard)." -ForegroundColor Yellow }
}

# ---------------------------------------------------------------- 7. APRES
Say "7/7  Diagnostic APRES"
Run-Diag ($diagArgs + @("-Prefix","Apres"))
$apres = Get-LastReport "Apres"
if ($apres) {
    OK "Rapport : $($apres.FullName)"
    Write-Host ""; Get-Content $apres.FullName | Select-String 'Scenario :' | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
    $reste = @(Get-Content $apres.FullName | Select-String '^\s*\[KO\]' | ForEach-Object { $_.Line.Trim() } | Select-Object -First 10)
    if ($reste.Count) { Write-Host "`n    Reste a traiter :" -ForegroundColor Yellow; $reste | ForEach-Object { Write-Host "    $_" -ForegroundColor Red } } else { OK "Aucun [KO] dans le rapport Apres" }
    try {
        . (Join-Path $Kit "Odaiji-Commun.ps1")
        if ($avant) {
            $dl = Compare-Constats (Get-RapportResume ([IO.File]::ReadAllText($avant.FullName))) (Get-RapportResume ([IO.File]::ReadAllText($apres.FullName)))
            Write-Host "`n    AVANT -> APRES (KO + WARN) :" -ForegroundColor Cyan
            Write-Host ("      Corriges : " + $(if ($dl.corriges.Count) { $dl.corriges -join ", " } else { "aucun" })) -ForegroundColor Green
            Write-Host ("      Restent  : " + $(if ($dl.restent.Count) { $dl.restent -join ", " } else { "aucun" })) -ForegroundColor Yellow
            Write-Host ("      Nouveaux : " + $(if ($dl.nouveaux.Count) { $dl.nouveaux -join ", " } else { "aucun" })) -ForegroundColor $(if ($dl.nouveaux.Count) { "Red" } else { "Gray" })
        }
    } catch {}
}
Write-Host "`n    PROCHAINE ETAPE : dans Odaiji, une facture avec une carte Vitale puis une facture sans Vitale (valider l'appel ADRi), puis 3-Diag-seul.bat si un doute persiste." -ForegroundColor Cyan
Write-Host "    Ces fichiers sont transmis automatiquement a MadeForMed ; si 'Envoi automatique impossible' s'affiche, les recuperer par le transfert de fichiers TeamViewer :" -ForegroundColor Cyan
if ($avant) { Write-Host ("      - " + $avant.FullName) }
if ($apres) { Write-Host ("      - " + $apres.FullName) }
Write-Host ("      - " + $Journal + "  (journal de ce depannage : actions et reponses)")
try { Stop-Transcript | Out-Null } catch {}
# 1.1.0 : le journal du depannage part aussi (Odaiji-Commun.ps1 : cle, file d'attente si pas de reseau)
try { & (Join-Path $Kit "Envoyer-journal.ps1") -Fichier $Journal -Raison "journal depannage" } catch { Write-Host "Envoi automatique du journal impossible : le recuperer par le transfert de fichiers TeamViewer." -ForegroundColor Yellow }
Read-Host "`nEntree pour fermer"
