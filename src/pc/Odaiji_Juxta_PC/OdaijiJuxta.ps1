<#
=====================================================================
 OdaijiJuxta (ex JuxtaDiag) - Diagnostic & reparation JuxtaLink / Vitale / lenteurs
 MadeForMed / Odaiji
=====================================================================
 Version : 0.3  (23/09/2026)
 Auteur  : Vivien + Claude

 USAGE
   Lancer-JuxtaDiag.bat       : diagnostic (lecture seule), rapport sur le Bureau
   Lancer-JuxtaDiag-FIX.bat   : reparation, confirmation a chaque etape

 CHANGELOG
   0.3.35 - (NB-DELL-01 30/09) dossier srt x86 absent = WARN + cree par -Fix (7a-quater), au lieu d'un KO sesam.ini qui revenait a chaque regeneration
   0.3.35 - (POSTE1 30/09) profil de l'utilisateur de la session (et non de l'admin UAC) pour user.config / plugins / tache ; user.config absent ou port != 1234
            = KO + correction 7k ; [MGC] posee dans les autres sesam.ini meme si C:\Windows\sesam.ini est correct (7a-ter)
   0.3.34 - (POSTE1 30/09) galss-autofix : galss.ini a un seul canal serie (ancien logiciel) = message clair, plus d'ERREUR ;
            neutralisation : message de fin honnete (nombre de dossiers reellement mis en quarantaine)
   0.3.33 - Neutraliser-Ancien-Logiciel.bat (equipe) : liste du catalogue editeurs.psd1 avec l'etat detecte sur le poste, choix du logiciel
            puis du mode (N = neutralisation seule, D = + desinstallation, jamais pour les logiciels medicaux), restauration par logiciel (R)
            et des elements coupes a tort (S), rapport Neutralisation_<poste>_<date>.txt ; meme moteur que l'installeur (Neutraliser-Cegedim.ps1)
   0.3.32 - Neutraliser-Cegedim v1.5 : le motif "synchro" ne desactive plus d'elements Windows / Microsoft / Adobe (garde-fou) ;
            -Restaurer -Systeme remet en route ceux deja touches ; Nettoyage : Cryptolib des outils GIE (ProgramData\santesocial, atsam)
            et de DMP Connect jamais desinstallee ni reparee, msiexec avec delai max ; diag DMP Connect : Cryptolib x64 correctement
            detectee (plus de "absente" a tort) ; galss-autofix : 2e fente trouvee aussi sur les lecteurs nommes "Reader 0 / Reader 1"
   0.3.31 - erreur MGC renvoyee par la FSV (derniere reponse) = KO SESAM ; [MGC] verifiee et posee dans TOUS les sesam.ini ;
   0.3.28 - 3 fenetres "Aucun package d'installation" au demarrage : source MSI retablie + reparation silencieuse (7r),
            lancements auto d'origine DESACTIVES (StartupApproved) au lieu d'etre deplaces, kit refuse de tourner depuis le zip ;
   0.3.27 - correctif : le diag plantait au demarrage si l'entree JuxtaLink du registre n'a pas d'icone (Split-Path chaine vide) ;
   0.3.26 - causes de lenteur listees a chaque diag (lecteur dispute, CertPropSvc, VPN, antivirus, Cryptolib) + 7v CertPropSvc ;
            DMP Connect en timeout a cause de galss.ini -> KO + realignement + redemarrage du service (7d-bis) ; Octave/MICA x64
   0.3.25 - poste serveur (base Oracle de l'ancien logiciel) : base conservee, question adaptee ; MICA x64 revenu + 1638 = scenario MICA
            catalogue : Weda (VitalZen, Weda Connect, services, comunica) avec desinstallation non-MSI silencieuse, Pyxvital ; inventaire des logiciels actifs (ports locaux, demarrages, services,
            produits sante) pour reperer un concurrent inconnu
   0.3.24 - galss.ini incoherent = WARN Icanopee (pas scenario GALSS) si JuxtaLink en Full PC/SC lit deja ; 7l : la reparation autorise aussi les navigateurs (LNA) ; galss-autofix : Vitale sur un 2e lecteur (seul autre lecteur avec carte) ; C:\Windows\sesam.ini absent = WARN
            si celui de la FSV (ProgramData) existe
   0.3.23 - "n" a "facture-t-il ENCORE avec ... ?" = neutralisation PUIS desinstallation (MSI de l'editeur un par un,
            sans redemarrage, hors FSV/Cryptolib/MICA/GALSS/Java/.NET, controle apres chaque produit) + dossiers en quarantaine
   0.3.22 - JuxtaLink sans UAC : tache \Odaiji\JuxtaLink (ouverture de session, privileges eleves) + icone Bureau ;
            diag : JuxtaLink arrete = KO (JUXTA_STOPPED), demarrage auto absent = WARN ; 7s cree la tache et relance ;
            Smart App Control actif = scenario SAC (mica.dll bloque, 0xc0e90002), evaluation = WARN ;
            poste neuf sans plugin SSV = scenario PREMIERE_LECTURE (au lieu de TABLES) ; srt vides = WARN ;
            tri des versions FSV corrige (1.40.9 etait prise pour la plus recente devant 1.40.14)
   0.3.21 - Catalogue editeurs.psd1 : une question "facture-t-il ENCORE avec X ?" par ancien logiciel detecte, neutralisation si n (7n)
   0.3.20 - Verdict : MICA/TABLES/SESAM avant GALSS ; question Cegedim inversee (ENCORE utilise ? n = retrait MICA x64) ; KO explicite si MICA x64 conserve
   0.3.19 - galss-autofix : analyse certutil FR corrigee (espace insecable) + lecteurs transmis par le diag
   0.3.18 - filet GALSS_REVERT : jamais si une autre cause connue est presente (tables, sesam, MICA, port)
   0.3.17 - 7t : tables FSV manquantes -> MSI FSV officiel installe (auto) puis sesam.ini regenere ; MSI cherche aussi dans installeurs\
   0.3.16 - sesam.ini en chemins absolus, [MGC] majuscules, log4crc.xml pour chaque version FSV ; autres sesam.ini signales
   0.3.15 - sesam.ini : verification section [MGC] / RepertoireConfigTrace / log4crc.xml (sinon regeneration 7a)
   0.3.14 - 7p : menage propose quand un ancien logiciel tient le port JuxtaLink (Neutraliser generique -Nom/-Motif)
   0.3.13 - Port JuxtaLink : detection d'un autre programme a l'ecoute (ex. fsenxt.exe Affid) -> scenario PORT
   0.3.12 - certutil -silent (aucune fenetre PIN) ; politique LNA etendue a *.juxta.cloud (DRC GERBAL, Chrome 153)
   0.3.11 - 7b : galss-autofix lance hors pipe avec delai max 60 s et sans relance JuxtaLink (blocage GERBAL)
   0.3.10 - MICA x64 retire seulement si Cegedim n'est plus utilise (question ou -SansCegedim), puis Neutraliser-Cegedim -Auto
   0.3.9 - Nouvel outil Neutraliser-Cegedim.bat (demarrage des residus coupe, sans desinstallation)
   0.3.8 - Questions : tampon clavier vide, reponse o/n obligatoire et tracee dans le rapport ; MICA x64 verifie apres retrait
   0.3.7 - MICA : apres retrait du MICA x64, vidage du cache Plugins + relance enchaines automatiquement ; questions explicites (taper o)
   0.3.6 - MICA x64 de source RarSFX desinstalle en auto ; filet GALSS_REVERT seulement hors scenarios MICA/SESAM/READER
   0.3.5 - Nettoyage : plus aucune desinstallation de produit Cegedim/jFSE (liste seulement) apres 2e redemarrage force
   0.3.4 - Correctif verdict : "Has X -or Has Y" n'evaluait que X (PowerShell) -> GALSS_MISMATCH ignore ;
           scenario GALSS aussi pour canal CPS/Vitale sur lecteur absent ; 7b utilise galss-autofix.ps1
   0.3.3 - Nettoyage securise (incident DRSAMITIER) : outils de prise en main a distance exclus (produits, dossiers,
           Run) ; desinstalleurs non-MSI listes au lieu d'etre lances en silencieux ; MSI avec REBOOT=ReallySuppress
   0.3.2 - JuxtaLink relance via explorer.exe (non eleve, session du medecin) ; verdict A_TESTER
           (poste configure sans KO mais sans lecture Vitale reussie) au lieu de UNKNOWN
   0.3.1 - -Nettoyage (Nettoyage.bat) : FSV anciennes, Cryptolib en doublon (+ reparation des
           conservees), produits/dossiers/entrees Run Cegedim-jFSE-Crossway, diagAM ; avec confirmation
         - Verification apres 7d retablie ; TABLES_X64_ONLY passe en info
   0.3  - Section 3c NAVIGATEURS : version Chrome/Edge et politique LocalNetworkAccessAllowedForUrls
          (erreurs DRC teletransmission) ; Autoriser-Odaiji-Chrome.bat
        - -SansGalss : passage Full PC/SC (prerequis lecteur PC/SC + Cryptolib non GALSS,
          desinstallation GALSS x86 Juxta uniquement, residus *w32, BLOQUERINSTALLEGALSS=true) ;
          diag : etat GALSS x86 / cle de blocage / retour du GALSS apres MAJ plugin
        - Renomme OdaijiJuxta ; parametres -Auto (corrections sures sans question),
          -Prefix (nom du rapport Avant/Apres), -UserAppData (profil du medecin si UAC autre compte)
        - Section 3b ICANOPEE : DmpConnect-JS2 installe/actif/ports/pile x64/erreurs log ;
          GALSS et Cryptolib etiquetes Juxta (x86) ou Icanopee (x64)
        - Section PERFORMANCE : durees requete->reponse par action (ADRi, FSE, lecture)
          mesurees dans le log JuxtaLink, alerte si > 3 s
        - Decodage des reponses base64 du log : champ "diagnostic" en clair
          (ex. rejet ADRi "FINESS / numero praticien")
        - sesam.ini : verification que les repertoires declares existent
        - galss.ini : canaux pointant sur un lecteur absent, canal Vitale sur
          interface sans contact (CL), canaux inutiles
        - CertPropSvc, antivirus installes, Cryptolib en double
        - Correctifs : parsing certutil (accents/OEM), version FSV
        - Fix : sesam.ini recree dans tous les scenarios ou il manque
        - Tables FSV : inventaire x86/x64, detection sesam.ini pointant sur la mauvaise
          arborescence (SESAM_WRONG_ARCH) ; le fix 7a ecrit des chemins de tables RESOLUS
          (celles qui existent), cree log4crc.xml et la cle registre GIE
        - Fix 7a-bis : installation/reparation FSV via un fsv*.msi depose a cote du script
          (x86 prefere, x64 accepte) ; cle registre GIE FSV verifiee
   0.2  - Coherence galss.ini <-> lecteur, pile 64 bits, processus concurrents
   0.1  - Premiere version : diag complet + fix MICA x64 / sesam.ini
=====================================================================
#>
[CmdletBinding()]
param([switch]$Fix, [switch]$NoPause, [switch]$Auto, [switch]$SansGalss, [switch]$Nettoyage, [switch]$SansCegedim, [switch]$LibererPort, [switch]$Leger, [string]$SansEditeurs = "", [string]$GardeEditeurs = "", [string]$Prefix = "OdaijiJuxta", [string]$UserAppData = "")

trap { Write-Host ("`nERREUR : " + $_.Exception.Message) -ForegroundColor Red; Write-Host ($_.InvocationInfo.PositionMessage) -ForegroundColor DarkGray; try { Add-Content -Path $Report -Value ("ERREUR SCRIPT : " + $_.Exception.Message + " | " + $_.InvocationInfo.PositionMessage) } catch {}; if (-not ($Auto -or $NoPause)) { Read-Host "Envoyer cette capture dans le channel Claude. Entree pour fermer" }; exit 1 }

$Script:Version = "1.1.3"

# --- Auto-elevation
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $a = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); if ($Fix) { $a += "-Fix" }; if ($NoPause) { $a += "-NoPause" }; if ($Auto) { $a += "-Auto" }; if ($SansGalss) { $a += "-SansGalss" }; if ($Nettoyage) { $a += "-Nettoyage" }; if ($SansCegedim) { $a += "-SansCegedim" }; if ($LibererPort) { $a += "-LibererPort" }; if ($Leger) { $a += "-Leger" }; if ($SansEditeurs) { $a += @("-SansEditeurs","`"$SansEditeurs`"") }; if ($GardeEditeurs) { $a += @("-GardeEditeurs","`"$GardeEditeurs`"") }; $a += @("-Prefix",$Prefix); if ($UserAppData) { $a += @("-UserAppData","`"$UserAppData`"") }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $a; exit
}

# --- Utilitaires
$Desktop = [Environment]::GetFolderPath("Desktop"); $Stamp = Get-Date -Format "yyyyMMdd-HHmm"
if (-not $UserAppData) {
    $UserAppData = $env:APPDATA
    # 30/09 (POSTE1) : lance par un compte admin (UAC) autre que le medecin, $env:APPDATA = profil de l'admin -> user.config / plugins / tache
    # crees pour le mauvais utilisateur. On vise le profil de la session ouverte (proprietaire d'explorer.exe), comme l'installeur.
    try {
        $o = Get-CimInstance Win32_Process -Filter "name='explorer.exe'" -OperationTimeoutSec 30 -ErrorAction Stop | Select-Object -First 1 | Invoke-CimMethod -MethodName GetOwner -ErrorAction Stop
        if ($o -and $o.User) {
            $pf = (Get-CimInstance Win32_UserProfile -OperationTimeoutSec 30 | Where-Object { $_.LocalPath -like ("*\" + $o.User) } | Select-Object -First 1).LocalPath
            if ($pf -and (Test-Path (Join-Path $pf "AppData\Roaming"))) { $UserAppData = Join-Path $pf "AppData\Roaming" }
        }
    } catch {}
}
if ($Auto -or $Nettoyage) { $Fix = $true }
$Report  = Join-Path $Desktop ("{0}_{1}_{2}.txt" -f $Prefix, $env:COMPUTERNAME, $Stamp)
# -Leger (sentinelle) : diagnostic passif. Jamais de reparation, aucune sonde du lecteur / des cartes, rapport hors du Bureau du medecin.
if ($Leger) { $Fix = $false; $Auto = $false; $NoPause = $true; $ld = Join-Path $env:ProgramData "MadeForMed\sentinelle"; New-Item -ItemType Directory -Force -Path $ld | Out-Null; $Report = Join-Path $ld ("{0}_{1}_{2}.txt" -f $Prefix, $env:COMPUTERNAME, $Stamp) }
$Script:Findings = @()
# 05/10 : jamais de blob base64 (les reponses d'erreur contiennent la requete, donc le code CPS) ni de code CPS dans un rapport
function W    { param([string]$t="", [string]$c="Gray") $t = [regex]::Replace([string]$t, '[A-Za-z0-9+/=]{80,}', '[base64-omis]'); $t = [regex]::Replace($t, '(?i)(codecps[^0-9]{0,6})\d{4,8}', '$1****'); $t = [regex]::Replace($t, '(?i)(?<![A-Za-z])((?:numNatPs|numeroNatPs|finess|nir|numSecu\w*|numeroSecu\w*|dateNaissance|nomPatient|prenomPatient|rpps|adeli)\W{1,6})[A-Za-z0-9]{3,}', '$1[masque]'); $t = [regex]::Replace($t, '(?<!\d)20\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])([01]\d|2[0-3])[0-5]\d[0-5]\d(?!\d)|\d{13,15}', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) if ($m.Value -match '^20\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])([01]\d|2[0-3])[0-5]\d[0-5]\d$') { $m.Value } else { '[nir-masque]' } }); Write-Host $t -ForegroundColor $c; Add-Content -Path $Report -Value $t -Encoding UTF8 }
function H1   { param($t) W ""; W ("=" * 70) "Cyan"; W ("  " + $t) "Cyan"; W ("=" * 70) "Cyan" }
function H2   { param($t) W ""; W ("--- " + $t) "Yellow" }
function OK   { param($t) W ("  [OK]   " + $t) "Green" }
function WARN { param($t) W ("  [WARN] " + $t) "Yellow" }
function KO   { param($t) W ("  [KO]   " + $t) "Red" }
function INFO { param($t) W ("         " + $t) "Gray" }
function Finding { param($Code,$Level,$Msg) $Script:Findings += [pscustomobject]@{Code=$Code;Level=$Level;Msg=$Msg} }
function Has  { param($Code) return [bool]($Script:Findings | Where-Object Code -eq $Code) }
# 05/10 (PC26-FILLATRE) : "Le chemin des tables binaires des SSV est absent du fichier sesam.ini" = le sesam.ini lu par la FSV
# (ProgramData\santesocial\fsv\<ver>\conf, ecrit par le MSI x64) n'a pas [SSV] RepertoireTable. Pose/remplace une cle dans une section.
function Set-SesamKey { param([string]$File, [string]$Section, [string]$Key, [string]$Value)
    $lines = @(Get-Content $File -ErrorAction SilentlyContinue); $out = @(); $sec = ""; $inTarget = $false; $done = $false; $seen = $false
    foreach ($ln in $lines) {
        if ($ln -match '^\s*\[(.+?)\]') {
            if ($inTarget -and -not $done) { $out += ($Key + "=" + $Value); $done = $true }
            $sec = $Matches[1].Trim().ToUpper(); $inTarget = ($sec -eq $Section.ToUpper()); if ($inTarget) { $seen = $true }
            $out += $ln; continue
        }
        if ($inTarget -and $ln -match ('^\s*' + [regex]::Escape($Key) + '\s*=')) { if (-not $done) { $out += ($Key + "=" + $Value); $done = $true }; continue }
        $out += $ln
    }
    if ($inTarget -and -not $done) { $out += ($Key + "=" + $Value); $done = $true }
    if (-not $seen) { $out += @("", ("[" + $Section + "]"), ($Key + "=" + $Value)) }
    [IO.File]::WriteAllText($File, (($out -join "`r`n") + "`r`n"), [Text.Encoding]::GetEncoding(1252))
}
# MSI FSV avec reparation automatique des droits : erreur "Impossible de definir la securite du fichier C:\ProgramData\santesocial\fsv\..." (DESKTOP-LD0E22D, 02/10)
# = ACL NTFS du dossier. takeown + icacls (SID Administrateurs/SYSTEM, independant de la langue) puis UN seul nouvel essai.
# Etat d'un sesam.ini (fonction pure, testee par tests\run.sh) : cle [MGC] RepertoireConfigTrace + log4crc.xml, cle [SSV] RepertoireTable.
# $Exists = scriptblock { param($chemin) ... } (Test-Path sur le poste, simule dans les tests)
# Fichiers presents dans les tables x64 et absents du x86 (noms relatifs, casse ignoree). Fonction pure, testee par tests\run.sh (POSTE2 05/10).
# 05/10 (CABINET) : Efficience "Lecteurs de cartes introuvables / getPcscResourcesList" -> le redemarrage du service DMP Connect a suffi.
function Get-DmpPcscHits { param([string[]]$Lines)
    return @($Lines | Where-Object { $_ -match '(?i)getPcscResourcesList|SCARD_E_|ListReaders|pc/?sc.*(fail|error|erreur|exception|not suc)|(fail|error|erreur|exception).*pc/?sc' })
}
function Get-TableMissing { param([string[]]$Rel86, [string[]]$Rel64)
    $have = @($Rel86 | ForEach-Object { $_.ToLower() })
    return @($Rel64 | Where-Object { $have -notcontains $_.ToLower() })
}
# Tables x86 incompletes : fichiers presents en x64 et absents du x86, par table (srt/sts/ssv). Fonction parametree, testee par tests\run.sh (POSTE1 06/10 :
# le MSI FSV a pose les tables en x64 APRES le diag initial, donc l'incompletude n'existait pas encore au moment de la detection).
function Get-TablesIncompletes { param([string]$Root86, [string]$Root64, [string]$Version)
    $res = @{}
    foreach ($t in "ssv","srt","sts") {
        $c86 = Join-Path $Root86 ("fsv\" + $Version + "\" + $t); $c64 = Join-Path $Root64 ("fsv\" + $Version + "\" + $t)
        if (-not ((Test-Path $c86) -and (Test-Path $c64))) { continue }
        $rel86 = @(Get-ChildItem $c86 -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName.Substring($c86.Length).TrimStart('\','/') })
        $rel64 = @(Get-ChildItem $c64 -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName.Substring($c64.Length).TrimStart('\','/') })
        if ($rel86.Count -le 0 -or $rel64.Count -le 0) { continue }
        $miss = @(Get-TableMissing -Rel86 $rel86 -Rel64 $rel64)
        if ($miss.Count) { $res[$t] = $miss }
    }
    return $res
}
# Plusieurs cartes de meme type dans des lecteurs differents (06/10 : 2 lecteurs OLAQIN, 1 CPS dans chacun -> Odaiji Full PC/SC : "Plusieurs cartes de meme type
# identifiees lors de la detection automatique"). Fonction pure sur la sortie de certutil -scinfo, testee par tests\run.sh.
function Get-ScinfoMulti { param([string]$Text)
    $cur = ""; $cps = @(); $vit = @()
    foreach ($line in ($Text -split "`r?`n")) {
        if     ($line -match '^\s*---\s*Lecteur\W*:\s*(.+?)\s*$') { $cur = $Matches[1] }
        elseif ($line -match 'Carte\W*:\s*(.*CPS.*)$')           { if ($cur -and ($cps -notcontains $cur)) { $cps += $cur } }
        elseif ($line -match 'Carte\W*:\s*(.*Vitale.*)$')        { if ($cur -and ($vit -notcontains $cur)) { $vit += $cur } }
    }
    return [pscustomobject]@{ Cps = $cps; Vitale = $vit }
}
function Get-SesamIniState { param([string[]]$Lines, [scriptblock]$Exists)
    $sec = ""; $tr = ""; $tb = ""; $tc = ""
    foreach ($ln in $Lines) {
        if ($ln -match '^\s*\[(.+?)\]') { $sec = $Matches[1].Trim().ToUpper(); continue }
        if ($sec -eq "MGC" -and $ln -match '^\s*RepertoireConfigTrace\s*=\s*(.+?)\s*$') { $tr = [Environment]::ExpandEnvironmentVariables($Matches[1]) }
        if ($sec -eq "SSV" -and $ln -match '^\s*RepertoireTable\s*=\s*(.+?)\s*$') { $tb = [Environment]::ExpandEnvironmentVariables($Matches[1]) }
        if ($sec -eq "COMMUN" -and $ln -match '^\s*RepertoireTable\s*=\s*(.+?)\s*$') { $tc = [Environment]::ExpandEnvironmentVariables($Matches[1]) }
    }
    $mgcOk = [bool]($tr -and (& $Exists ($tr.TrimEnd('\') + "\log4crc.xml")))
    $ssvOk = [bool]($tb -and (& $Exists $tb))
    $communOk = [bool]($tc -and (& $Exists $tc))
    return [pscustomobject]@{ MgcTrace = $tr; MgcOk = $mgcOk; SsvTable = $tb; SsvOk = $ssvOk; CommunTable = $tc; CommunOk = $communOk }
}
function Invoke-MsiFsvUne { param([string]$Arguments, [int]$Sec)
    $pp = Start-Process msiexec.exe -ArgumentList $Arguments -PassThru
    if ($pp.WaitForExit($Sec * 1000)) { return [int]$pp.ExitCode } else { WARN ("  msiexec toujours en cours apres " + $Sec + " s : abandonne"); return -1 }
}
function Invoke-FsvMsi { param([string]$Arguments, [int]$Sec = 300)
    $code = Invoke-MsiFsvUne $Arguments $Sec
    if ($code -notin 0,3010,1638,1641) {
        $dir = "C:\ProgramData\santesocial\fsv"
        if (Test-Path $dir) {
            WARN ("  MSI FSV code " + $code + " : reparation des droits de " + $dir + " puis nouvel essai")
            & takeown.exe /f $dir /r /d o 2>&1 | Out-Null
            & icacls.exe $dir /grant "*S-1-5-32-544:(OI)(CI)F" "*S-1-5-18:(OI)(CI)F" /t /c /q 2>&1 | Out-Null
            $code = Invoke-MsiFsvUne $Arguments $Sec
            INFO ("  nouvel essai MSI FSV : " + $code)
        } else { INFO "  dossier ProgramData\santesocial\fsv absent : pas de reparation de droits possible" }
    }
    return $code
}
# Le MSI FSV (7a-bis, 7t) reecrit C:\ProgramData\santesocial\fsv\<ver>\conf\sesam.ini SANS section [MGC] : on la repose apres chaque MSI
# (DESKTOP-H0L11PM 03/10 : 7a posait [MGC] puis 7a-bis l'effacait -> erreur MGC a la lecture suivante).
function Set-MgcApresMsi {
    $fs = @("C:\ProgramData\santesocial","C:\Program Files (x86)\santesocial","C:\Program Files\santesocial") | ForEach-Object { Get-ChildItem $_ -Recurse -Filter sesam.ini -ErrorAction SilentlyContinue } | ForEach-Object FullName
    foreach ($o in @($fs)) {
        $sec = ""; $tr = ""
        foreach ($ln in (Get-Content $o -ErrorAction SilentlyContinue)) { if ($ln -match '^\s*\[(.+?)\]') { $sec = $Matches[1].Trim().ToUpper(); continue }; if ($sec -eq "MGC" -and $ln -match '^\s*RepertoireConfigTrace\s*=\s*(.+?)\s*$') { $tr = [Environment]::ExpandEnvironmentVariables($Matches[1]) } }
        if ($tr -and (Test-Path (Join-Path $tr "log4crc.xml"))) { continue }
        try {
            $ov = if ($o -match 'fsv\\(\d+\.\d+\.\d+)') { $Matches[1] } else { $FsvVersion }
            $odir = "C:\ProgramData\santesocial\fsv\$ov\conf"; New-Item -ItemType Directory -Force $odir | Out-Null
            if (-not (Test-Path (Join-Path $odir "log4crc.xml"))) { $src = Get-ChildItem "C:\ProgramData\santesocial\fsv" -Recurse -Filter log4crc.xml -ErrorAction SilentlyContinue | Select-Object -First 1; if ($src) { Copy-Item $src.FullName (Join-Path $odir "log4crc.xml") -Force } }
            Copy-Item $o ($o + ".bak-" + $Stamp + "-mgc") -Force
            $keep = @(); $sec = ""
            foreach ($ln in (Get-Content $o)) { if ($ln -match '^\s*\[(.+?)\]') { $sec = $Matches[1].Trim().ToUpper() }; if ($sec -ne "MGC") { $keep += $ln } }
            $keep += @("", "[MGC]", ("RepertoireConfigTrace=" + $odir))
            [IO.File]::WriteAllText($o, (($keep -join "`r`n") + "`r`n"), [Text.Encoding]::GetEncoding(1252))
            OK ("[MGC] reposee apres MSI dans " + $o)
        } catch { WARN ("[MGC] non reposee dans " + $o + " : " + $_.Exception.Message) }
    }
}
function Confirm-Step { param([string]$q, [switch]$Safe)
    if ($Auto) { if ($Safe) { W (">> " + $q + " -> oui (auto)") "Magenta"; return $true } else { W (">> " + $q + " -> ignore en mode auto (a valider par un humain)") "Yellow"; return $false } }
    # DRPARDON 24/09 : "o" tape mais action non executee -> on vide les touches deja tapees, on exige o ou n,
    # et la reponse est ecrite dans le rapport (preuve de ce qui a ete choisi).
    try { $Host.UI.RawUI.FlushInputBuffer() } catch {}
    do { $r = (Read-Host ("`n>> " + $q + " [o/n]")).Trim() } while ($r -notmatch '^[oOyYnN]')
    $yes = ($r -match '^[oOyY]'); Add-Content -Path $Report -Value (">> " + $q + " -> " + $(if ($yes) { "oui" } else { "non" })) -Encoding UTF8
    return $yes }
function Expand { param($p) [Environment]::ExpandEnvironmentVariables($p) }

$Paths = @{
    JuxtaExe = "C:\Program Files (x86)\Juxta\JuxtaLink\JuxtaLink.exe"
    JuxtaLog = Join-Path $UserAppData "Juxta\JuxtaLink\logs\trace.txt"
    PlugDir  = Join-Path $UserAppData "juxta\juxtalink\Plugins"
    SanteX86 = "C:\Program Files (x86)\santesocial"; SanteX64 = "C:\Program Files\santesocial"
    SesamIni = "C:\Windows\sesam.ini"; GalssIni = "C:\Windows\galss.ini"
    MicaLog  = Join-Path $env:LOCALAPPDATA "santesocial\mica\mica.log"
}
# Demarrage de JuxtaLink sans UAC (tache planifiee) : fonctions partagees avec l'installeur
$Script:HasJxLib = Test-Path (Join-Path $PSScriptRoot "JuxtaLink-Demarrage-lib.ps1")
if ($Script:HasJxLib) { try { . (Join-Path $PSScriptRoot "JuxtaLink-Demarrage-lib.ps1"); if ($Script:JxExe) { $Paths.JuxtaExe = $Script:JxExe } } catch { $Script:HasJxLib = $false; Write-Host ("  [WARN] Fonctions JuxtaLink-Demarrage non chargees : " + $_.Exception.Message) -ForegroundColor Yellow } }
function Start-Jx { if ($Script:HasJxLib) { Start-JxTask | Out-Null } elseif (Test-Path $Paths.JuxtaExe) { Start-Process explorer.exe -ArgumentList ("`"" + $Paths.JuxtaExe + "`"") } }
$Hives = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")

"" | Set-Content -Path $Report -Encoding UTF8
H1 ("OdaijiJuxta v" + $Script:Version + " - " + (Get-Date -Format "dd/MM/yyyy HH:mm"))
try { . (Join-Path $PSScriptRoot "Odaiji-Commun.ps1"); $Script:PosteId = Get-PosteId } catch { $Script:PosteId = "" }
INFO ("Poste : " + $env:COMPUTERNAME + "   Utilisateur : " + $env:USERNAME + "   Mode : " + $(if ($Fix) { "REPARATION" } else { "DIAGNOSTIC" }) + $(if ($Script:PosteId) { "   Poste ID : " + $Script:PosteId } else { "" }))
INFO ("Rapport : " + $Report)

# ====================================================================
H1 "1. SYSTEME"
# ====================================================================
$os = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 30
INFO ("Windows : " + $os.Caption + " " + $os.Version + " (" + $os.OSArchitecture + ")   Boot : " + $os.LastBootUpTime.ToString("dd/MM HH:mm"))
$svc = Get-Service SCardSvr -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") { OK "SCardSvr : Running" } else { KO "SCardSvr absent/arrete"; Finding "SCARDSVR" "KO" "Service carte a puce non demarre" }
$cps = Get-Service CertPropSvc -ErrorAction SilentlyContinue
# Smart App Control (Windows 11) : bloque les DLL non signees, dont mica.dll (erreur 0xc0e90002).
# En mode evaluation (2), Windows l'active seul quelques jours plus tard : le poste marche puis casse sans intervention.
$sac = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy" -ErrorAction SilentlyContinue).VerifiedAndReputablePolicyState
if ($sac -eq 1) { KO "Smart App Control ACTIF : Windows bloque mica.dll (non signe) -> Vitale illisible (0xc0e90002). Le desactiver (Securite Windows > Controle des applications)"; Finding "SAC_ON" "KO" "Smart App Control actif (bloque mica.dll)" }
elseif ($sac -eq 2) { WARN "Smart App Control en EVALUATION : Windows l'activera seul et bloquera mica.dll. Le desactiver maintenant (Securite Windows > Controle des applications)"; Finding "SAC_EVAL" "WARN" "Smart App Control en evaluation (bombe a retardement)" }
elseif ($sac -eq 0) { OK "Smart App Control desactive" }
if ($cps) { INFO ("CertPropSvc : " + $cps.Status + " / " + $cps.StartType + "  (lit tous les certificats CPS a l'insertion ; source de lenteur possible)") }
try { $av = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop | Select-Object -ExpandProperty displayName
      INFO ("Antivirus : " + ($av -join ", ")) ; if ($av -notmatch '^Windows Defender$' -and $av.Count) { Finding "AV_TIERS" "INFO" ("Antivirus tiers : " + ($av -join ", ")) } } catch {}

# ====================================================================
H1 "2. LECTEURS ET CARTES"
# ====================================================================
Get-PnpDevice -Class SmartCardReader -ErrorAction SilentlyContinue | ForEach-Object { INFO ("PnP : " + $_.FriendlyName + " [" + $_.Status + "]") }
if ($Leger) {
    $Script:Readers = @(); $Script:CpsReader = ""; $Script:VitReader = ""
    INFO "Mode leger (sentinelle) : lecteur et cartes non sondes (aucun acces a la carte)"
} else {
    H2 "certutil -scinfo (resume)"
    $sc = (& certutil -silent -scinfo 2>&1 | Out-String) -replace '[\u00A0\u00E1\u00FF]', ' '
    $Script:Readers = @(); $Script:CpsReader = ""; $Script:VitReader = ""; $cur = ""
    foreach ($line in ($sc -split "`r?`n")) {
        if     ($line -match '^\s*---\s*Lecteur\W*:\s*(.+?)\s*$') { $cur = $Matches[1]; $Script:Readers += $cur; INFO ("Lecteur : " + $cur) }
        elseif ($line -match 'Carte\W*:\s*(.*CPS.*)$')           { $Script:CpsReader = $cur; OK ("  CPS dans '" + $cur + "'") }
        elseif ($line -match 'Carte\W*:\s*(.*Vitale.*)$')        { $Script:VitReader = $cur; OK ("  Vitale dans '" + $cur + "'") }
        elseif ($line -match 'SCARD_STATE_(PRESENT|INUSE|EMPTY|UNPOWERED)') { INFO ("  " + $line.Trim()) }
        elseif ($line -match 'partag\W+e par un autre processus') { WARN ("  '" + $cur + "' : carte tenue par un autre processus (acces exclusif SSV retarde)"); Finding "CARD_SHARED" "WARN" ("Carte partagee dans " + $cur) }
    }
    if (-not $Script:CpsReader) { KO "CPS non vue par Windows"; Finding "NO_CPS" "KO" "CPS non detectee" }
    $multi = Get-ScinfoMulti -Text $sc
    if (@($multi.Cps).Count -gt 1) { KO ("Plusieurs CPS inserees dans des lecteurs differents (" + (@($multi.Cps) -join " | ") + ") : Odaiji (Full PC/SC) refuse la detection automatique ('Plusieurs cartes de meme type'). Ne laisser qu'UNE CPS inseree : retirer celle du lecteur non utilise."); Finding "PCSC_MULTI_CPS" "KO" "Plusieurs CPS inserees (detection PC/SC ambigue)" }
    if (@($multi.Vitale).Count -gt 1) { KO ("Plusieurs cartes Vitale reconnues dans des lecteurs differents (" + (@($multi.Vitale) -join " | ") + ") : Odaiji (Full PC/SC) refuse la detection automatique. Ne laisser qu'UNE Vitale inseree."); Finding "PCSC_MULTI_VITALE" "KO" "Plusieurs Vitale inserees (detection PC/SC ambigue)" }
    if (-not $Script:VitReader) { WARN "Vitale non identifiee par certutil (peut etre presente mais non reconnue : voir statut PRESENT ci-dessus)" }
}

# ====================================================================
H1 "3. PILE SESAM-VITALE"
# ====================================================================
H2 "Dossiers"
foreach ($p in @($Paths.SanteX86, $Paths.SanteX64)) { if (Test-Path $p) { INFO ($p + " -> " + ((Get-ChildItem $p -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) -join ", ")) } else { INFO ($p + " -> absent") } }
$fsvX86 = @(Get-ChildItem (Join-Path $Paths.SanteX86 "fsv") -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name | Where-Object { $_ -match '^\d+(\.\d+)+$' } | Sort-Object { [version]$_ } -Descending)
$FsvVersion = if ($fsvX86.Count) { $fsvX86[0] } else { "1.40.14" }
if ($fsvX86.Count) { OK ("FSV x86 : " + ($fsvX86 -join ", ") + "  (utilisee : " + $FsvVersion + ")") } else { KO "FSV x86 absentes"; Finding "NO_FSV_X86" "KO" "FSV 32 bits absentes" }
if (Test-Path $Paths.SanteX64) { WARN "Pile 64 bits presente (Program Files\santesocial)"; Finding "STACK_X64" "WARN" "Pile 64 bits presente" }
H2 "Tables FSV disponibles (donnees identiques x86/x64)"
$Script:TableDir = @{}; $Script:TblMissing = @{}
foreach ($t in "ssv","srt","sts") {
    $c86 = Join-Path $Paths.SanteX86 ("fsv\" + $FsvVersion + "\" + $t); $c64 = Join-Path $Paths.SanteX64 ("fsv\" + $FsvVersion + "\" + $t)
    $n86 = if (Test-Path $c86) { (Get-ChildItem $c86 -File -Recurse -ErrorAction SilentlyContinue).Count } else { -1 }
    $n64 = if (Test-Path $c64) { (Get-ChildItem $c64 -File -Recurse -ErrorAction SilentlyContinue).Count } else { -1 }
    $pick = if ($n86 -gt 0) { $c86 } elseif ($n64 -gt 0) { $c64 } else { "" }
    $Script:TableDir[$t] = $pick
    INFO (("{0,-4} x86: {1,-8} x64: {2,-8} -> {3}" -f $t, $(if ($n86 -lt 0) { "absent" } else { "$n86 fich." }), $(if ($n64 -lt 0) { "absent" } else { "$n64 fich." }), $(if ($pick) { $pick } else { "AUCUNE TABLE" })))
    # srt vides : 2 postes le 28/09 facturaient sans -> remplies au fil des mises a jour (repertoiremodification), pas un blocage
    if (-not $pick -and $t -eq "srt" -and ($n86 -ge 0 -or $n64 -ge 0)) { WARN "Tables srt vides : normal sur une installation recente (remplies par les mises a jour), pas un blocage"; Finding "SRT_EMPTY" "WARN" "Tables srt vides (non bloquant)" }
    elseif (-not $pick) { KO ("Tables " + $t + " introuvables des deux cotes"); Finding "NO_TABLES" "KO" ("Tables FSV " + $t + " absentes") }
    elseif ($n86 -le 0) { WARN ("Tables " + $t + " uniquement en x64 : sesam.ini doit pointer sur Program Files\ (pas x86)"); Finding "TABLES_X64_ONLY" "WARN" ("Tables " + $t + " seulement en 64 bits") }
    # 05/10 (PC26-FILLATRE) : tables x86 incompletes (ssv 18 contre 22, sts 3 contre 45) alors que le x64 est complet -> la FSV ne trouve pas ses tables binaires
    if ($n86 -gt 0 -and $n64 -gt 0) {
        $rel86 = @(Get-ChildItem $c86 -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName.Substring($c86.Length).TrimStart('\') })
        $rel64 = @(Get-ChildItem $c64 -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName.Substring($c64.Length).TrimStart('\') })
        $miss = @(Get-TableMissing -Rel86 $rel86 -Rel64 $rel64)
        if ($miss.Count) { $Script:TblMissing[$t] = $miss; WARN ("  Tables " + $t + " x86 incompletes : " + $miss.Count + " fichier(s) presents en x64 seulement (" + (($miss | Select-Object -First 8) -join ", ") + ")"); Finding "TABLES_X86_INCOMPLET" "WARN" ($t + " : " + $miss.Count + " fichier(s) absents en x86") }
    }
}

# Chronologie (POSTE1 06/10 : facturation OK le matin, tables SSV inaccessibles a 13h41) : dates des fichiers de tables + detections Defender recentes,
# pour savoir QUAND les fichiers ont ete poses/modifies/supprimes et si l'antivirus les a mis en quarantaine.
foreach ($t in "ssv","srt","sts") {
    foreach ($arch in @(@("x86",$Paths.SanteX86),@("x64",$Paths.SanteX64))) {
        $d = Join-Path $arch[1] ("fsv\" + $FsvVersion + "\" + $t)
        if (Test-Path $d) {
            $fs = @(Get-ChildItem $d -File -Recurse -ErrorAction SilentlyContinue)
            if ($fs.Count) { $nw = $fs | Sort-Object LastWriteTime -Descending | Select-Object -First 1; $od = $fs | Sort-Object LastWriteTime | Select-Object -First 1; INFO ("  dates " + $t + " " + $arch[0] + " : plus ancien " + $od.LastWriteTime.ToString("dd/MM HH:mm") + " ; plus recent " + $nw.Name + " " + $nw.LastWriteTime.ToString("dd/MM HH:mm")) }
        }
    }
}
try {
    $det = @(Get-MpThreatDetection -ErrorAction Stop | Where-Object { $_.InitialDetectionTime -gt (Get-Date).AddDays(-3) } | Sort-Object InitialDetectionTime -Descending | Select-Object -First 5)
    foreach ($x in $det) { WARN ("Windows Defender a detecte le " + $x.InitialDetectionTime.ToString("dd/MM HH:mm") + " : " + ((@($x.Resources) | Select-Object -First 1) -replace '^file:_','')) }
} catch {}

foreach ($t in "ssv","sts") {
    foreach ($arch in @(@("x86",$Paths.SanteX86),@("x64",$Paths.SanteX64))) {
        $d = Join-Path $arch[1] ("fsv\" + $FsvVersion + "\" + $t)
        if (Test-Path $d) { INFO ("--- " + $t + " " + $arch[0] + " : " + (@(Get-ChildItem $d -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 70 | ForEach-Object { $_.Name + " (" + $_.Length + ")" }) -join ", ")) }
    }
}

H2 "MICA"
$micaX86 = Get-ChildItem $Paths.SanteX86 -Recurse -Include mica.dll -ErrorAction SilentlyContinue
if ($micaX86) { OK ("mica.dll x86 : " + $micaX86[0].FullName) } else { KO "mica.dll x86 ABSENT"; Finding "NO_MICA_X86" "KO" "mica.dll 32 bits absent" }

H2 "Produits GIE / Cryptolib / GALSS inscrits"
$gie = Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object { $_.Publisher -like "*GIE*" -or $_.DisplayName -match 'mica|fsv|galss|cryptolib|cps' } | Select-Object DisplayName, DisplayVersion, PSChildName, InstallLocation, InstallSource
$Script:MicaX64Product = $null
foreach ($g in $gie) {
    $who = ""
    if ($g.DisplayName -match 'galss|cryptolib') {
        if ($g.InstallSource -match 'DmpConnect|icanopee' -or ($g.InstallLocation -like "C:\Program Files\*" -and $g.InstallLocation -notlike "*(x86)*") -or $g.DisplayName -match 'x64') { $who = "  [DMP Connect / iCanopee - x64]" } else { $who = "  [Juxta / SSV - x86]" }
    }
    INFO (("{0,-28} {1,-12} {2}{3}" -f $g.DisplayName, $g.DisplayVersion, $g.PSChildName, $who)); if ($g.InstallSource) { INFO ("    src : " + $g.InstallSource) }
    if ($g.DisplayName -match '^mica' -and $g.DisplayName -match 'x64') { $Script:MicaX64Product = $g }
}
if ($Script:MicaX64Product) { WARN "MICA x64 inscrit (bloque l'installation de MICA x86 : erreur 1638)"; Finding "MICA_X64" "WARN" "MICA x64 inscrit" }
$Script:GalssX86 = @($gie | Where-Object { $_.DisplayName -match 'galss' -and -not ($_.InstallSource -match 'DmpConnect|icanopee' -or $_.DisplayName -match 'x64' -or ($_.InstallLocation -like "C:\Program Files\*" -and $_.InstallLocation -notlike "*(x86)*")) })
$Script:BloqGalss = @(Get-ChildItem (Join-Path $Paths.PlugDir "SSV") -Recurse -Filter SSV.dll.config -ErrorAction SilentlyContinue | ForEach-Object { $v = (Select-String $_.FullName -Pattern 'BLOQUERINSTALLEGALSS"\s+value="(\w+)"').Matches; if ($v) { $v[0].Groups[1].Value } })
H2 "GALSS Juxta (x86) - politique Full PC/SC"
if ($Script:GalssX86.Count) { INFO ("GALSS x86 installe : " + (($Script:GalssX86 | ForEach-Object { $_.DisplayName + " " + $_.DisplayVersion }) -join ", ")) } else { INFO "GALSS x86 absent (mode Full PC/SC)" }
INFO ("BLOQUERINSTALLEGALSS dans le plugin SSV : " + $(if ($Script:BloqGalss.Count) { $Script:BloqGalss -join "," } else { "(plugin non installe)" }))
if ($Script:GalssX86.Count -and ($Script:BloqGalss -contains "true")) { WARN "GALSS x86 revenu alors que sa reinstallation est bloquee : mise a jour du plugin ? a re-desinstaller"; Finding "GALSS_X86_BACK" "WARN" "GALSS x86 reinstalle malgre le blocage" }
if ($SansGalss -and $Script:GalssX86.Count) { Finding "GALSS_X86_TODO" "INFO" "GALSS x86 a desinstaller (-SansGalss)" }
$Script:CryptoGalss = $false
$cconf = Get-ChildItem "C:\ProgramData\santesocial\CPS","C:\Program Files (x86)\santesocial\CPS" -Recurse -Include cps3_pkcs11*.ini,cps3_pkcs11*.conf,*.ini -ErrorAction SilentlyContinue | Select-String -Pattern 'galss' -SimpleMatch | Where-Object { $_.Line -notmatch '^\s*;' }
if ($cconf) { foreach ($c in $cconf | Select-Object -First 4) { INFO ("Cryptolib config : " + $c.Filename + " : " + $c.Line.Trim()) }; if ($cconf.Line -match '(?i)galss\s*=\s*(1|true|oui)|filiere\s*=\s*galss') { $Script:CryptoGalss = $true; WARN "Cryptolib CPS x86 configuree en filiere GALSS : a reinstaller en Full PC/SC AVANT de retirer GALSS"; Finding "CRYPTO_GALSS" "WARN" "Cryptolib en mode GALSS" } }
$cryptos = @($gie | Where-Object DisplayName -match 'cryptolib')
if ($cryptos.Count -gt 1) { WARN ("Cryptolib installee " + $cryptos.Count + " fois : " + (($cryptos | ForEach-Object { $_.DisplayName + " " + $_.DisplayVersion }) -join " | ")); Finding "CRYPTO_MULTI" "INFO" "Plusieurs Cryptolib" }

H2 "sesam.ini"
$others = @("C:\ProgramData\santesocial","C:\Program Files (x86)\santesocial","C:\Program Files\santesocial") | ForEach-Object { Get-ChildItem $_ -Recurse -Filter sesam.ini -ErrorAction SilentlyContinue } | ForEach-Object FullName
if ($others) { foreach ($o in $others) { WARN ("Autre sesam.ini sur le poste : " + $o + " (verifier lequel la FSV utilise)") } }
# 05/10 (PC26-FILLATRE) : tous les sesam.ini de santesocial etaient corrects et l'erreur 'tables binaires des SSV' restait :
# la FSV lisait un sesam.ini AILLEURS (dossier de JuxtaLink, plugin, profil utilisateur...). On les cherche aussi la, et on les affiche.
$more = @()
foreach ($r in @("C:\Program Files (x86)\Juxta","C:\Program Files\Juxta","C:\ProgramData\Juxta","C:\ProgramData\MadeForMed",(Join-Path $UserAppData "Juxta"),(Join-Path $UserAppData "juxta"),(Join-Path $env:LOCALAPPDATA "santesocial"),(Join-Path $env:APPDATA "santesocial"))) {
    if (Test-Path $r) { $more += @(Get-ChildItem $r -Recurse -Filter sesam.ini -ErrorAction SilentlyContinue | ForEach-Object FullName) }
}
foreach ($r in @("C:\Windows\SysWOW64","C:\Windows\System32","C:\")) { $f = Join-Path $r "sesam.ini"; if (Test-Path $f) { $more += $f } }
$more = @($more | Select-Object -Unique | Where-Object { ($others -notcontains $_) -and ($_ -ne $Paths.SesamIni) -and ($_ -notmatch '\.bak') })
foreach ($o in $more) { WARN ("sesam.ini HORS santesocial : " + $o + " (la FSV peut lire celui-ci)") }
$others = @($others) + $more
foreach ($o in @($Paths.SesamIni) + @($others)) {
    if (Test-Path $o) {
        INFO ("--- contenu de " + $o + " (" + (Get-Item $o).Length + " octets, " + (Get-Item $o).LastWriteTime.ToString("dd/MM HH:mm") + ")")
        try { $hb = [IO.File]::ReadAllBytes($o); INFO ("    octets : debut=" + (($hb | Select-Object -First 16 | ForEach-Object { $_.ToString("X2") }) -join " ") + "  NUL=" + @($hb | Where-Object { $_ -eq 0 }).Count + "  lignes=" + @(Get-Content $o -ErrorAction SilentlyContinue).Count) } catch {}
        foreach ($ln in @(Get-Content $o -ErrorAction SilentlyContinue | Select-Object -First 60)) { INFO ("    | " + $ln) }
    }
}
foreach ($ev in @("SESAMINI","SESAM_INI","SESAM","SESAMVITALE")) { $evv = [Environment]::GetEnvironmentVariable($ev, "Machine"); if ($evv) { WARN ("Variable d'environnement " + $ev + " = " + $evv) } }
$Script:SesamBad = $false
# 29/09 (Dr Plongeron) : "Section MGC absente..." renvoye par la FSV alors que C:\Windows\sesam.ini etait correct :
# la FSV lisait un AUTRE sesam.ini. On verifie la section [MGC] de chacun.
$Script:MgcOthers = @(); $Script:SsvOthers = @()
foreach ($o in @($others)) {
    $st = Get-SesamIniState -Lines @(Get-Content $o -ErrorAction SilentlyContinue) -Exists { param($p) Test-Path $p }
    if (-not $st.MgcOk) { WARN ("  " + $o + " : section [MGC] absente ou log4crc.xml introuvable"); $Script:MgcOthers += $o }
    if ((-not $st.SsvOk) -or (-not $st.CommunOk)) { KO ("  " + $o + " : [SSV] ou [COMMUN] RepertoireTable absent ou introuvable -> erreur 'chemin des tables binaires des SSV absent du sesam.ini' (PC26-FILLATRE 05/10 : [COMMUN] manquant)"); Finding "SESAM_SSV_TABLE" "KO" $o; $Script:SsvOthers += $o }
}
if ($Script:MgcOthers.Count) { Finding "SESAM_MGC" "WARN" ("[MGC] manquante dans " + $Script:MgcOthers.Count + " autre(s) sesam.ini") }
if (Test-Path $Paths.SesamIni) {
    $ini = Get-Content $Paths.SesamIni -ErrorAction SilentlyContinue
    if (($ini | Measure-Object -Character).Characters -lt 50) { KO "sesam.ini VIDE"; Finding "SESAM_EMPTY" "KO" "sesam.ini vide"; $Script:SesamBad = $true }
    else {
        foreach ($l in ($ini | Select-String 'Repertoire\w*=')) {
            $kv = $l.Line -split '=', 2; $p = Expand $kv[1].Trim()
            if (Test-Path $p) { OK ($kv[0].Trim() + " -> " + $p) }
            else {
                $alt = if ($p -match '\(x86\)') { $p -replace 'Program Files \(x86\)', 'Program Files' } else { $p -replace 'Program Files\\', 'Program Files (x86)\' }
                if ($p -match '\(x86\)\\santesocial\\fsv\\[\d.]+\\srt\\?$') {
                    # 30/09 (NB-DELL-01) : tables srt vides = normal ; le dossier x86 n'existe pas (seul le x64 l'a) -> cree par -Fix (7a-quater), pas de regeneration de sesam.ini
                    WARN ($kv[0].Trim() + " -> " + $p + "  dossier srt absent (tables srt vides : normal) ; -Fix le cree"); Finding "SRT_DIR_ABSENT" "WARN" $p
                    continue
                }
                if ($p -ne $alt -and (Test-Path $alt)) { KO ($kv[0].Trim() + " -> " + $p + "  INEXISTANT, mais existe en " + $(if ($alt -match 'x86') { "x86" } else { "x64" }) + " : " + $alt); Finding "SESAM_WRONG_ARCH" "KO" ("sesam.ini pointe sur la mauvaise arborescence : " + $p) }
                else { KO ($kv[0].Trim() + " -> " + $p + "  INEXISTANT (SSV reessaie 10 x 500 ms)"); Finding "SESAM_PATH" "KO" ("Repertoire sesam.ini absent : " + $p) }
                $Script:SesamBad = $true
            }
        }
        # Section [MGC] (Dr Neyens 25/09 : "Section MGC absente, ou cle RepertoireConfigTrace absente, ou fichier
        # log4crc.xml non trouve a l'emplacement indique par la cle RepertoireConfigTrace")
        $sec = ""; $mgcTrace = $null; $mgcRaw = ""; $hasMgc = $false
        foreach ($ln in $ini) {
            if ($ln -match '^\s*\[(.+?)\]') { $sec = $Matches[1].Trim().ToUpper(); if ($sec -eq "MGC") { $hasMgc = $true }; continue }
            if ($sec -eq "MGC" -and $ln -match '^\s*RepertoireConfigTrace\s*=\s*(.+?)\s*$') { $mgcRaw = $Matches[1]; $mgcTrace = Expand $Matches[1] }
        }
        if (-not $hasMgc) { KO "sesam.ini : section [MGC] absente"; Finding "SESAM_MGC" "KO" "Section MGC absente"; $Script:SesamBad = $true }
        elseif (-not $mgcTrace) { KO "sesam.ini : [MGC] sans cle RepertoireConfigTrace"; Finding "SESAM_MGC" "KO" "MGC sans RepertoireConfigTrace"; $Script:SesamBad = $true }
        elseif (-not (Test-Path (Join-Path $mgcTrace "log4crc.xml"))) { KO ("log4crc.xml absent de " + $mgcTrace); Finding "SESAM_MGC" "KO" "log4crc.xml introuvable"; $Script:SesamBad = $true }
        else { OK ("[MGC] RepertoireConfigTrace -> " + $mgcTrace + " (log4crc.xml present)") }
        if ($mgcRaw -match '%') { WARN "RepertoireConfigTrace contient une variable (%...%) : certaines FSV ne la developpent pas"; Finding "SESAM_MGC" "KO" "Chemin MGC non absolu"; $Script:SesamBad = $true }
    }
} else {
    # 28/09 : deux postes facturaient sans C:\Windows\sesam.ini, avec seulement celui de la FSV (ProgramData\...\conf)
    $pdIni = "C:\ProgramData\santesocial\fsv\" + $FsvVersion + "\conf\sesam.ini"
    if ((Test-Path $pdIni) -and ((Get-Content $pdIni -Raw -ErrorAction SilentlyContinue).Length -ge 50)) { WARN ("C:\Windows\sesam.ini absent, mais celui de la FSV " + $FsvVersion + " est present (" + $pdIni + ") : non bloquant"); Finding "SESAM_WIN_ABSENT" "WARN" "sesam.ini Windows absent (celui de la FSV suffit)" }
    else { KO "sesam.ini ABSENT"; Finding "SESAM_MISSING" "KO" "sesam.ini absent"; $Script:SesamBad = $true }
}

H2 "Inscription FSV (registre GIE) et MSI disponibles"
$regFsv = @("HKLM:\SOFTWARE\WOW6432Node\GIE SESAM VITALE\FSV","HKLM:\SOFTWARE\GIE SESAM VITALE\FSV") | Where-Object { Test-Path $_ } | ForEach-Object { Get-ChildItem $_ -ErrorAction SilentlyContinue | ForEach-Object { $_.PSChildName + " (" + $(if ($_.Name -match 'WOW6432') { "x86" } else { "x64" }) + ")" } }
if ($regFsv) { INFO ("Registre GIE FSV : " + ($regFsv -join ", ")) } else { WARN "Aucune cle HKLM\SOFTWARE\GIE SESAM VITALE\FSV (FSV jamais installees par MSI officiel)"; Finding "FSV_NOREG" "INFO" "FSV non inscrites au registre GIE" }
$Script:FsvMsi = @(Get-ChildItem (Split-Path $PSCommandPath),(Join-Path (Split-Path $PSCommandPath) "installeurs") -Filter "fsv*.msi" -ErrorAction SilentlyContinue | Sort-Object { if ($_.Name -match 'x86') { 0 } else { 1 } })
if ($Script:FsvMsi.Count) { INFO ("MSI FSV disponibles a cote du script : " + (($Script:FsvMsi | ForEach-Object Name) -join ", ")) }

H2 "galss.ini (canaux vs lecteurs reels)"
$Script:GalssReader = ""; $Script:Canals = @()
if (Test-Path $Paths.GalssIni) {
    $sec = ""; $canal = $null
    foreach ($l in (Get-Content $Paths.GalssIni)) {
        if ($l -match '^\s*\[(CANAL(\d+))(\.PAD\d+(\.LAD\d+)?)?\]') { $sec = $Matches[1]; if (-not $Matches[3]) { $canal = [pscustomobject]@{Name=$Matches[1]; Reader=""; LADs=@()}; $Script:Canals += $canal } elseif ($Matches[4]) { $canal = $Script:Canals | Where-Object Name -eq $Matches[1] } }
        elseif ($l -match '^\s*\[') { $sec = "" }
        elseif ($sec -and $l -match '^\s*Caracteristiques\s*=\s*(.+)$') { ($Script:Canals | Where-Object Name -eq $sec).Reader = $Matches[1].Trim() }
        elseif ($sec -and $l -match '^\s*NomLAD\s*=\s*(.+)$' -and $canal) { $canal.LADs += $Matches[1].Trim() }
    }
    foreach ($c in $Script:Canals) {
        $present = $Script:Readers | Where-Object { $_ -eq $c.Reader }
        $tag = if ($present) { "present" } else { "ABSENT" }
        INFO (("{0} : '{1}' [{2}]  LAD: {3}" -f $c.Name, $c.Reader, $tag, ($c.LADs -join ",")))
        if (-not $present -and $Script:Readers.Count) { WARN ("  canal declare sur un lecteur absent -> timeouts GALSS"); Finding "GALSS_ABSENT_READER" "WARN" ($c.Name + " sur lecteur absent : " + $c.Reader) }
        if ($c.LADs -contains "Vitale" -and $c.Reader -match '\bCL\b|contactless|sans contact') { KO "  canal Vitale sur une interface SANS CONTACT"; Finding "GALSS_VITALE_CL" "KO" "Vitale declaree sur interface sans contact" }
        if ($c.LADs -contains "Vitale" -and $Script:VitReader -and $c.Reader -ne $Script:VitReader) { KO ("  canal Vitale = '" + $c.Reader + "' mais la Vitale est dans '" + $Script:VitReader + "'"); Finding "GALSS_MISMATCH" "KO" "galss.ini Vitale sur le mauvais lecteur"; $Script:GalssReader = $c.Reader }
        if ($c.LADs -contains "CPS" -and $Script:CpsReader -and $c.Reader -ne $Script:CpsReader) { WARN ("  canal CPS = '" + $c.Reader + "' mais la CPS est dans '" + $Script:CpsReader + "'"); Finding "GALSS_MISMATCH_CPS" "WARN" "galss.ini CPS sur le mauvais lecteur" }
    }
    if (-not (Has "GALSS_MISMATCH") -and -not (Has "GALSS_ABSENT_READER") -and -not (Has "GALSS_VITALE_CL") -and $Script:Canals.Count) { if (Has "GALSS_MISMATCH_CPS") { INFO "galss.ini : lecteurs presents, mais canaux CPS / Vitale inverses (DMP Connect lit la CPS via galss.ini)" } else { OK "galss.ini coherent avec les lecteurs presents" } }
    (Get-Content $Paths.GalssIni | Select-String '^NomLib') | ForEach-Object { INFO $_.Line.Trim() }
} else {
    WARN "galss.ini absent"
    # 01/10 (DRLECLERE) : sans galss.ini, DMP Connect / iCanopee ne lit plus la CPS (JuxtaLink, en PC/SC direct, n'est pas concerne)
    if ((Test-Path "C:\Program Files (x86)\DmpConnect-JS2") -or (Test-Path "C:\Program Files\santesocial\galss")) { WARN "  DMP Connect / iCanopee a besoin de galss.ini : Reparer-lecteur.bat le recree (CPS + Vitale inserees)"; Finding "GALSS_MISSING" "WARN" "galss.ini absent (DMP Connect / iCanopee)" }
}

H2 "Processus concurrents sur le lecteur"
$conc = @(
    @{Name="dmpconnectjs_monitor";Desc="DMP Connect / iCanopee";Keep=$true}, @{Name="SRVSVCNAM";Desc="amelipro CNAM";Keep=$true},
    @{Name="SynchroSystray";Desc="Cegedim CLM";Keep=$false}, @{Name="ClmLive";Desc="Cegedim AVI";Keep=$false}, @{Name="MMTCServer";Desc="Cegedim CLM";Keep=$false},
    @{Name="jfse";Desc="jFSE";Keep=$false}, @{Name="java";Desc="Java (jFSE ?)";Keep=$false}, @{Name="JuxtaLink";Desc="JuxtaLink";Keep=$true})
foreach ($c in $conc) { $pr = Get-Process ($c.Name + "*") -ErrorAction SilentlyContinue
    if ($pr) { if ($c.Keep) { INFO ("actif : " + $c.Name.PadRight(22) + $c.Desc) } else { WARN ("actif : " + $c.Name.PadRight(22) + $c.Desc + "  <- residu (Neutraliser-Cegedim.bat)"); Finding ("PROC_" + $c.Name.ToUpper()) "WARN" ($c.Desc + " actif") } } }
if (Test-Path "C:\CEGEDIM\JFSE") { WARN "C:\CEGEDIM\JFSE present"; Finding "JFSE_DIR" "WARN" "Dossier jFSE present" }

# ====================================================================
# --- Anciens logiciels metiers (catalogue editeurs.psd1) : detection
H2 "Anciens logiciels metiers detectes (catalogue editeurs.psd1)"
$Script:Editeurs = @(); $Script:Decision = @{}
$sansL = @($SansEditeurs -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }); if ($SansCegedim) { $sansL += "Cegedim" }
$gardeL = @($GardeEditeurs -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
foreach ($n in $sansL) { $Script:Decision[$n] = $true }; foreach ($n in $gardeL) { $Script:Decision[$n] = $false }
$cat = Join-Path $PSScriptRoot "editeurs.psd1"
if (Test-Path $cat) {
    $prods = Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object DisplayName
    $procs = Get-Process -ErrorAction SilentlyContinue
    foreach ($e in (Import-PowerShellDataFile $cat).Editeurs) {
        $why = @()
        foreach ($d in $e.Dossiers) { if (Get-Item $d -ErrorAction SilentlyContinue) { $why += "dossier" ; break } }
        if ($procs | Where-Object { ($_.ProcessName + ' ' + $(try { $_.Path } catch { '' })) -match $e.Motif -and $_.ProcessName -notmatch '^JuxtaLink' }) { $why += "processus actif" }
        if ($prods | Where-Object { ($_.DisplayName + ' ' + $_.Publisher) -match $e.Motif -and $_.DisplayName -notmatch 'Cryptographiques|fsv|mica|galss' }) { $why += "produit inscrit" }
        if ($why) {
            $srv = [bool](Get-CimInstance Win32_Service -OperationTimeoutSec 30 -ErrorAction SilentlyContinue | Where-Object { ($_.Name -match '^Oracle' -or $_.PathName -match 'oracle|TNSLSNR') -and ($_.PathName + ' ' + $_.Name) -match $e.Motif })
            $Script:Editeurs += [pscustomobject]@{ Nom=$e.Nom; Libelle=$e.Libelle; Motif=$e.Motif; Bloquants=$e.Bloquants; Dossiers=@($e.Dossiers); NonMsi=[bool]$e.DesinstallerNonMsi; Serveur=$srv; Garder=[bool]$e.NeutraliserSeulement }
            if ($srv) { WARN ("Ce poste heberge la BASE DE DONNEES " + $e.Nom + " (service Oracle) : a conserver (cabinet / historique des dossiers). Reponse n = seuls les programmes lies au lecteur sont coupes + MICA x64 retire ; rien n'est desinstalle ni deplace."); Finding ("SRV_" + $e.Nom.ToUpper()) "WARN" ("Base " + $e.Nom + " hebergee sur ce poste") }
            $etat = if ($Script:Decision.ContainsKey($e.Nom)) { if ($Script:Decision[$e.Nom]) { "plus utilise (a neutraliser)" } else { "encore utilise (conserve)" } } else { "usage a confirmer" }
            WARN ($e.Nom + " : " + ($why -join ", ") + " -> " + $etat + "  [bloquants connus : " + $e.Bloquants + "]"); Finding ("OLD_" + $e.Nom.ToUpper()) "WARN" ($e.Nom + " detecte (" + ($why -join ", ") + ")")
        }
    }
    if (-not $Script:Editeurs) { OK "Aucun ancien logiciel metier du catalogue" }
    # 29/09 (HANSIANE) : kit perime sans HelloDoc -> on affiche le contenu du catalogue pour le reperer
    INFO ("Catalogue : " + ((Import-PowerShellDataFile $cat).Editeurs.Nom -join ", "))
} else { INFO "Catalogue editeurs.psd1 absent" }

# Inventaire pour reperer un logiciel concurrent INCONNU du catalogue (poste 28/09 : Vitalzen / Weda Connect)
H2 "Autres logiciels actifs (inventaire, a signaler si concurrent)"
$sante = 'sesam|vitale|vitalzen|weda|comunica|pyxvital|\bcps\b|\bfse\b|carte|lecteur|reader|medic|m.dical|sante|sant.|doctolib|crossway|hellodoc|axisante|maiia|mediboard|chorus|ordoclic|galss|mica|pcsc|smartcard|scard'
$known = 'juxta|dmpconnect|icanopee|amelipro|srvsvcnam|diagam|teamviewer|anydesk|microsoft|windows|google|intel|nvidia|realtek|dell|hp |lenovo|adobe|sophos|mcafee|eset|defender|onedrive|zoom|teams'
$lis = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalAddress -in @('127.0.0.1','0.0.0.0','::','::1') -and $_.LocalPort -lt 49152 } | ForEach-Object { $pp = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; if ($pp -and $pp.ProcessName -notmatch '^(System|svchost|lsass|wininit|services|spoolsv|Idle)$') { [pscustomobject]@{ Port = $_.LocalPort; Nom = $pp.ProcessName; Chemin = $(try { $pp.Path } catch { "" }) } } } | Sort-Object Port -Unique)
foreach ($l in $lis) { $t = ($l.Nom + ' ' + $l.Chemin); $m = if ($t -match $sante -and $t -notmatch $known) { "   <- a verifier (concurrent ?)" } else { "" }; INFO ("Port local " + $l.Port + " : " + $l.Nom + " (" + $l.Chemin + ")" + $m) }
$runAll = @(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run","HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue | ForEach-Object { $_.PSObject.Properties } | Where-Object { $_.Name -notmatch '^PS' })
foreach ($r in $runAll) { $t = ($r.Name + ' ' + $r.Value); if ($t -notmatch $known) { INFO ("Demarrage auto : " + $r.Name + " -> " + ([string]$r.Value).Substring(0, [Math]::Min(120, ([string]$r.Value).Length)) + $(if ($t -match $sante) { "   <- a verifier (concurrent ?)" } else { "" })) } }
$svcX = @(Get-CimInstance Win32_Service -OperationTimeoutSec 30 -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Running' -and $_.PathName -and $_.PathName -notmatch '\\Windows\\' -and ($_.Name + ' ' + $_.DisplayName + ' ' + $_.PathName) -notmatch $known })
foreach ($v in $svcX) { $t = ($v.Name + ' ' + $v.DisplayName + ' ' + $v.PathName); INFO ("Service : " + $v.DisplayName + " (" + $v.Name + ")" + $(if ($t -match $sante) { "   <- a verifier (concurrent ?)" } else { "" })) }
$prodX = @(Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and ($_.DisplayName + ' ' + $_.Publisher) -match $sante -and ($_.DisplayName + ' ' + $_.Publisher) -notmatch ($known + '|cryptographiques|fsv|galss|mica') })
foreach ($x in $prodX) { INFO ("Produit sante : " + $x.DisplayName + " " + $x.DisplayVersion + " (" + $x.Publisher + ")   <- a verifier (concurrent ?)") }
if (-not ($lis -or $runAll -or $svcX -or $prodX)) { INFO "(rien a signaler)" }
# Decision unique par editeur (question posee au plus une fois ; en -Auto, reponse fournie par l'installeur)
function Decide-Editeur { param($e)
    if ($Script:Decision.ContainsKey($e.Nom)) { return $Script:Decision[$e.Nom] }
    if ($Auto) { return $null }
    $txt = if ($e.Serveur) { " ? (ce poste heberge sa BASE : conservee ; n = seuls les programmes lies au lecteur sont coupes + MICA x64 retire)" } else { " ? (n = il est coupe puis desinstalle, hors briques partagees FSV/Cryptolib/MICA, sans redemarrage)" }
    $still = Confirm-Step ("Le medecin facture-t-il ENCORE avec " + $e.Libelle + $txt)
    $Script:Decision[$e.Nom] = -not $still; return (-not $still) }

H1 "3b. DMP CONNECT / ICANOPEE (doit fonctionner en parallele de JuxtaLink)"
# ====================================================================
$dmpDir = "C:\Program Files (x86)\DmpConnect-JS2"; $dmpOK = $true
$dmpReg = Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object DisplayName -match 'DmpConnect' | Select-Object -First 1
if ($dmpReg) { OK ("Installe : " + $dmpReg.DisplayName + " " + $dmpReg.DisplayVersion) } elseif (Test-Path $dmpDir) { INFO "Dossier present, produit non inscrit" } else { INFO "DmpConnect-JS2 non installe sur ce poste"; $dmpOK = $null }
if ($dmpOK) {
    $mon = Get-Process dmpconnectjs_monitor -ErrorAction SilentlyContinue; $js2 = Get-Process dmpconnect-js2 -ErrorAction SilentlyContinue
    if ($mon) { OK "dmpconnectjs_monitor actif" } else { WARN "dmpconnectjs_monitor non lance"; $dmpOK = $false }
    if ($js2) { OK ("dmpconnect-js2 actif (" + @($js2).Count + " processus)") } else { WARN "dmpconnect-js2 non lance"; $dmpOK = $false }
    $ports = @(); foreach ($pr in @($js2) + @($mon)) { if ($pr) { $ports += Get-NetTCPConnection -OwningProcess $pr.Id -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalPort } }
    if ($ports) { OK ("Ecoute locale sur port(s) : " + (($ports | Sort-Object -Unique) -join ", ")) } elseif ($js2) { WARN "dmpconnect-js2 lance mais aucun port en ecoute"; $dmpOK = $false }
    $run = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -ErrorAction SilentlyContinue | ForEach-Object { $_.PSObject.Properties } | Where-Object Name -match 'dmpconnect'
    if ($run) { INFO ("Demarrage auto : " + ($run.Name -join ", ")) } else { WARN "Pas d'entree de demarrage automatique DmpConnect" }
    $g64 = $gie | Where-Object { $_.DisplayName -match 'galss' -and ($_.InstallSource -match 'DmpConnect' -or $_.DisplayName -match 'x64') }
    $c64 = $gie | Where-Object { $_.DisplayName -match 'cryptolib|Cryptographiques' -and ($_.InstallSource -match 'DmpConnect' -or $_.DisplayName -match 'x64') }
    INFO ("Pile 64 bits DMP Connect : GALSS " + $(if ($g64) { $g64.DisplayVersion } else { "absent" }) + " / Cryptolib " + $(if ($c64) { $c64.DisplayVersion } else { "absente" }))
    $dlog = Get-ChildItem $dmpDir, (Join-Path $env:ProgramData "DmpConnect*"), (Join-Path $env:LOCALAPPDATA "DmpConnect*") -Recurse -Include *.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($dlog) { INFO ("Log recent : " + $dlog.FullName + " (" + $dlog.LastWriteTime.ToString("dd/MM HH:mm") + ")"); (Get-Content $dlog.FullName -Tail 200 -ErrorAction SilentlyContinue | Select-String 'error|erreur|exception|fail' | Select-Object -Last 3) | ForEach-Object { WARN ("  " + $_.Line.Trim()) } }
    # DRSAMITIER 28/09 : "Timeout" en serie dans le log DMP Connect + canal galss.ini sur l'ancien lecteur -> CPS illisible pour le DMP
    if ($dlog) {
        $nTo = @(Get-Content $dlog.FullName -Tail 300 -ErrorAction SilentlyContinue | Select-String 'Timeout').Count
        if ($nTo -ge 2 -and (Has "GALSS_ABSENT_READER")) { KO ("DMP Connect : " + $nTo + " 'Timeout' recents ET galss.ini declare un lecteur absent -> le DMP ne lit plus la CPS. Correction : Reparer-lecteur.bat puis redemarrage du service DMP Connect (-Fix le fait)"); Finding "DMP_TIMEOUT_GALSS" "KO" "DMP Connect en timeout : canal galss.ini sur un lecteur absent" }
        elseif ($nTo -ge 2) { WARN ("DMP Connect : " + $nTo + " 'Timeout' recents sans cause locale evidente (reseau, VPN, proxy ?)"); Finding "DMP_TIMEOUT" "WARN" "DMP Connect en timeout" }
    }
    if ($dlog) {
        $ph = @(Get-DmpPcscHits @(Get-Content $dlog.FullName -Tail 400 -ErrorAction SilentlyContinue))
        if ($ph.Count) {
            $pl = [string]$ph[$ph.Count - 1]; $pl = $pl.Trim(); if ($pl.Length -gt 200) { $pl = $pl.Substring(0, 200) + "..." }
            WARN ("DMP Connect : " + $ph.Count + " erreur(s) de lecture des lecteurs PC/SC dans son log (derniere : " + $pl + ")")
            Finding "DMP_PCSC_ERR" "WARN" "DMP Connect n'arrive plus a lister les lecteurs PC/SC (redemarrer son service)"
        }
    }
    try { $jp = @($js2) | Where-Object { $_ } | Sort-Object StartTime | Select-Object -First 1; if ($jp) { INFO ("dmpconnect-js2 lance depuis " + $jp.StartTime.ToString("dd/MM HH:mm")) } } catch {}
    if ($dmpOK) { OK "DMP Connect / iCanopee operationnel (processus + port)"; } else { KO "DMP Connect / iCanopee non operationnel"; Finding "DMP_KO" "KO" "DmpConnect-JS2 non operationnel" }
}
W ""; INFO "Rappel : ne jamais desinstaller 'GALSS' ou 'Cryptolib' en bloc ; le x64 appartient a DMP Connect / iCanopee, le x86 a Juxta."

# ====================================================================
H1 "3c. NAVIGATEURS - Local Network Access (erreurs DRC a la teletransmission)"
# ====================================================================
foreach ($b in @(@{N="Chrome";Exe="C:\Program Files\Google\Chrome\Application\chrome.exe";Exe2="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe";Pol="HKLM:\SOFTWARE\Policies\Google\Chrome"},
                 @{N="Edge";Exe="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe";Exe2="C:\Program Files\Microsoft\Edge\Application\msedge.exe";Pol="HKLM:\SOFTWARE\Policies\Microsoft\Edge"})) {
    $exe = @($b.Exe,$b.Exe2) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $exe) { INFO ($b.N + " non installe"); continue }
    $ver = (Get-Item $exe).VersionInfo.ProductVersion; $major = [int]($ver -split '\.')[0]
    $pol = Get-ItemProperty (Join-Path $b.Pol "LocalNetworkAccessAllowedForUrls") -ErrorAction SilentlyContinue
    $urls = if ($pol) { ($pol.PSObject.Properties | Where-Object Name -match '^\d+$' | ForEach-Object Value) -join ", " } else { "" }
    if ($urls -match 'odaiji' -and $urls -match 'juxta\.cloud') { OK ($b.N + " " + $ver + " : politique Local Network Access OK (" + $urls + ")") }
    elseif ($urls -match 'odaiji') { WARN ($b.N + " " + $ver + " : politique sans *.juxta.cloud (DRC GERBAL) -> relancer Autoriser-Odaiji-Chrome.bat"); Finding ("LNA_" + $b.N.ToUpper()) "WARN" ($b.N + " : politique LNA incomplete (juxta.cloud)") }
    elseif ($major -ge 142) { KO ($b.N + " " + $ver + " : Local Network Access actif et Odaiji non autorise -> erreurs DRC possibles (Autoriser-Odaiji-Chrome.bat)"); Finding ("LNA_" + $b.N.ToUpper()) "KO" ($b.N + " sans politique Local Network Access") }
    else { INFO ($b.N + " " + $ver + " : version < 142, pas encore concerne ; politique a poser quand meme (Autoriser-Odaiji-Chrome.bat)") }
}

# ====================================================================
H1 "4. JUXTALINK"
# ====================================================================
if (Test-Path $Paths.JuxtaExe) { OK ("JuxtaLink " + (Get-Item $Paths.JuxtaExe).VersionInfo.FileVersion) } else { KO "JuxtaLink.exe introuvable"; Finding "NO_JUXTA" "KO" "JuxtaLink absent" }
if (Get-Process JuxtaLink -ErrorAction SilentlyContinue) { OK "JuxtaLink en cours d'execution" }
elseif (Test-Path $Paths.JuxtaExe) { KO "JuxtaLink ne tourne pas : Odaiji ne peut lire aucune carte"; Finding "JUXTA_STOPPED" "KO" "JuxtaLink arrete (pas relance apres un redemarrage du PC ?)" }
else { WARN "JuxtaLink non lance" }
# retour terrain 28/09 : JuxtaLink exige l'UAC ; lance par une cle Run au demarrage de Windows, il est bloque en silence.
if ($Script:HasJxLib -and (Test-Path $Paths.JuxtaExe)) {
    $jt = Test-JxTask
    if ($jt.Etat -eq "OK") { OK ("Demarrage auto sans UAC : tache \Odaiji\JuxtaLink (" + $jt.Detail + ")") }
    else { WARN ("Demarrage auto sans UAC : tache " + $jt.Etat.ToLower() + $(if ($jt.Detail) { " (" + $jt.Detail + ")" } else { "" }) + " -> JuxtaLink demande l'UAC et ne repart pas seul apres un redemarrage (Demarrage-JuxtaLink.bat)"); Finding "NO_AUTOSTART" "WARN" "Pas de demarrage automatique de JuxtaLink sans UAC" }
    # 04/10 : gardien = veille toutes les 10 min, relance JuxtaLink si on le ferme ou s'il plante
    $gd = Test-JxGardien
    if ($gd.Etat -eq "OK") { OK ("Gardien JuxtaLink : veille " + $gd.Detail) }
    else { WARN ("Gardien JuxtaLink : tache " + $gd.Etat.ToLower() + " -> JuxtaLink ne serait pas relance s'il est ferme ou plante en cours de journee (2-Depanner.bat)"); Finding "GARDIEN_ABSENT" "WARN" "Pas de gardien : JuxtaLink n'est pas relance s'il s'arrete" }
    foreach ($e in @(Get-JxAutostarts (Get-JxUser) $UserAppData)) { INFO ("Autre lancement auto : " + $e.Type + " '" + $e.Nom + "' -> " + $e.Valeur + $(if (-not $e.Actif) { "  (desactive par Odaiji)" } elseif ($jt.Etat -ne "OK") { "  (bloque en silence au demarrage : JuxtaLink exige l'UAC)" } else { "" })) }
    # Retour terrain 29/09 : 3 fenetres au demarrage ("Aucun package d'installation...", "ressource reseau non disponible",
    # "Erreur irrecuperable") = Windows Installer veut reparer JuxtaLink (element manquant) mais sa source MSI a disparu
    # (installe depuis le zip ouvert sans extraction -> dossier Temp purge).
    if ($Script:HasJxLib) {
        # 06/10 : sur 3 postes la source reste "fragile" apres 7r2 -> on journalise le package installe et ceux du kit pour voir si le code de package correspond (condition de la copie)
        $kitCodes = @(Get-ChildItem (Join-Path $PSScriptRoot "installeurs\fsv*.msi"),(Join-Path $PSScriptRoot "fsv*.msi") -ErrorAction SilentlyContinue | ForEach-Object { $_.Name + "=" + (Convert-JxMsiPkgGuidSafe $_.FullName) })
        foreach ($x in @(Get-FsvMsiRisk)) {
            WARN ("Source d'installation du FSV fragile (" + (@($x.Sources) -join " ; ") + ") : une reparation Windows afficherait 'Aucun package d'installation'"); Finding "FSV_MSI_SOURCE" "WARN" "Source MSI du FSV dans un dossier temporaire/utilisateur"
            $mine = ""; try { $mine = [string](Get-ItemProperty $x.ProdKey -ErrorAction SilentlyContinue).PackageCode } catch {}
            INFO ("      produit : " + $x.Nom + " " + $x.Version + " ; package : " + $x.PackageName + " ; code installe " + (Convert-JxPackedGuid $mine) + " ; MSI du kit : " + $(if ($kitCodes.Count) { $kitCodes -join ", " } else { "aucun" }))
        }
    }
    $jm = Get-JxMsi
    if ($jm) {
        if ($jm.SourceOk) { OK ("Source d'installation JuxtaLink presente (" + $jm.PackageName + ")") }
        else { WARN ("Source d'installation JuxtaLink introuvable (" + (@($jm.Sources) -join " ; ") + ") : toute reparation Windows de JuxtaLink affichera 'Aucun package d'installation...'"); Finding "JX_MSI_SOURCE" "WARN" "Source d'installation MSI de JuxtaLink disparue (dossier temporaire purge)" }
        $jev = @(Get-JxMsiErrors 7)
        # 1.0.0 : apres une reparation, les anciens evenements restent 7 jours dans le journal -> on ne compte que ceux posterieurs au dernier lancement de JuxtaLink
        if ($jev.Count -and $jm.SourceOk) { try { $jps = Get-Process JuxtaLink -ErrorAction SilentlyContinue | Sort-Object StartTime | Select-Object -Last 1; if ($jps) { $jev = @($jev | Where-Object { $_.TimeCreated -gt $jps.StartTime }) } } catch {} }
        if ($jev.Count) {
            WARN ("Windows Installer tente de reparer JuxtaLink (" + $jev.Count + " evenement(s) sur 7 jours) : fenetres d'erreur au lancement probables")
            foreach ($x in $jev) { INFO ($x.TimeCreated.ToString("dd/MM HH:mm") + "  " + (($x.Message -replace '\s+', ' ').Trim() | ForEach-Object { if ($_.Length -gt 230) { $_.Substring(0, 230) + "..." } else { $_ } })) }
            Finding "JX_MSI_REPAIR" "WARN" "Fenetres 'package d'installation introuvable' au lancement de JuxtaLink"
        }
    }
    $bk = Get-ItemProperty $Script:JxBackKey -ErrorAction SilentlyContinue
    if ($bk -and @($bk.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' -and $_.Name -notlike "SA|*" }).Count) {
        WARN "Raccourci / cle de demarrage d'origine de JuxtaLink DEPLACE par une ancienne version du kit (v0.3.24-0.3.27) : Windows Installer le voit manquant et veut reparer"
        Finding "JX_MOVED" "WARN" "Elements de demarrage JuxtaLink deplaces par le kit (a remettre en place)"
    }
}
# Port d'ecoute : Odaiji appelle https://localhost:1234. Cas Dr Neyens 25/09 : fsenxt.exe (Affid Systemes) occupait
# le port 1234 -> Odaiji parlait au mauvais programme (connexion ouverte, aucune reponse, ERR_TIMED_OUT apres ~10 s).
$JxPort = 1234; try { $uc = Join-Path $UserAppData "juxta\juxtalink\user.config"; if (Test-Path $uc) { $m = Select-String $uc -Pattern 'key="port"\s+value="(\d+)"' | Select-Object -First 1; if ($m) { $JxPort = [int]$m.Matches[0].Groups[1].Value } } } catch {}
# 30/09 (POSTE1) : user.config absent du profil de l'utilisateur -> JuxtaLink sans serveurs token/update (erreurs 1100/1200 dans Odaiji) ;
# port different de 1234 -> Odaiji (qui appelle localhost:1234) ne le joint pas
if (Test-Path $Paths.JuxtaExe) {
    $ucf = Join-Path $UserAppData "juxta\juxtalink\user.config"
    if (-not (Test-Path $ucf)) { KO ("user.config absent de " + (Split-Path $ucf) + " : JuxtaLink sans les serveurs MadeForMed (erreurs token 1100 / update 1200 dans Odaiji). Correction : -Fix (7k)"); Finding "UC_ABSENT" "KO" "user.config absent du profil de l'utilisateur" }
    else {
        $uct = Get-Content $ucf -Raw -ErrorAction SilentlyContinue
        if ($uct -notmatch 'tokenServerUrl' -or $uct -notmatch 'updateServerUrl') { KO ("user.config sans tokenServerUrl / updateServerUrl : " + $ucf); Finding "UC_INCOMPLET" "KO" "user.config sans serveurs token/update" }
        if ($JxPort -ne 1234) { KO ("JuxtaLink configure sur le port " + $JxPort + " alors qu'Odaiji appelle le port 1234 (" + $ucf + "). Correction : -Fix (7k)"); Finding "PORT_CFG" "KO" ("JuxtaLink configure sur le port " + $JxPort) }
    }
}
# 30/09 : si JuxtaLink est lance avec le compte admin de l'UAC, il lit le user.config du profil ADMIN
if ((Test-Path $Paths.JuxtaExe) -and $env:APPDATA -and ($env:APPDATA -ne $UserAppData)) {
    $ucA = Join-Path $env:APPDATA "juxta\juxtalink\user.config"
    if (-not (Test-Path $ucA) -or ((Get-Content $ucA -Raw -ErrorAction SilentlyContinue) -notmatch 'tokenServerUrl')) { WARN ("user.config absent/incomplet aussi dans le profil du compte admin (" + $ucA + ") : necessaire si JuxtaLink est lance avec ce compte. Correction : -Fix (7k)"); Finding "UC_ADMIN" "WARN" "user.config absent du profil admin" }
}
$lis = @(Get-NetTCPConnection -LocalPort $JxPort -State Listen -ErrorAction SilentlyContinue)
if (-not $lis) { WARN ("Aucun programme n'ecoute sur le port " + $JxPort + " (JuxtaLink arrete ou n'a pas pu demarrer)") }
foreach ($l in $lis) {
    $pp = Get-Process -Id $l.OwningProcess -ErrorAction SilentlyContinue
    $nm = if ($pp) { $pp.ProcessName } else { "PID " + $l.OwningProcess }
    if ($nm -match '^JuxtaLink') { OK ("Port " + $JxPort + " : JuxtaLink") }
    else {
        $path = try { $pp.Path } catch { "" }
        KO ("Port " + $JxPort + " occupe par " + $nm + " (" + $path + ") et non par JuxtaLink : Odaiji parle au mauvais programme (ERR_TIMED_OUT)")
        Finding "PORT_CONFLICT" "KO" ("Port " + $JxPort + " occupe par " + $nm)
        $Script:PortHolder = [pscustomobject]@{ Name=$nm; Path=$path; Company=$(try { $pp.MainModule.FileVersionInfo.CompanyName } catch { "" }) }
    }
}
$Script:PluginSSV = [bool](Get-ChildItem (Join-Path $Paths.PlugDir "SSV") -Directory -ErrorAction SilentlyContinue | Where-Object Name -match '^\d')
if ((Test-Path $Paths.JuxtaExe) -and -not $Script:PluginSSV) { WARN "Plugin SSV pas encore installe : aucune lecture faite depuis Odaiji (normal sur un poste neuf)"; Finding "NO_PLUGIN" "INFO" "Premiere lecture jamais faite (plugin SSV absent)" }
if (Test-Path $Paths.PlugDir) { INFO ("Plugins : " + ((Get-ChildItem $Paths.PlugDir -Recurse -Directory -Depth 1 -ErrorAction SilentlyContinue | Where-Object Name -match '^\d' | ForEach-Object { $_.Parent.Name + " " + $_.Name }) -join ", ")) }

$Script:SigMica=$false; $Script:Sig1638=$false; $Script:VitaleOK=$false; $Script:CpsOK=$false; $Script:LogLines=@()
if (Test-Path $Paths.JuxtaLog) {
    $Script:LogLines = Get-Content $Paths.JuxtaLog -Tail 3000
    $tail = $Script:LogLines | Select-Object -Last 400
    $all = $tail -join "`n"
    if ($all -match 'Mica\.\.ctor')        { $Script:SigMica = $true }
    if ($all -match 'code de sortie 1638') { $Script:Sig1638 = $true }
    $lastV = $tail | Select-String 'Vitale pr.sente : (True|False)' | Select-Object -Last 1; if ($lastV -and $lastV.Line -match 'True') { $Script:VitaleOK = $true }
    # 29/09 (PCCABINET) : Vitale retiree avant le diag -> derniere ligne False alors que la lecture marchait : une lecture True recente suffit
    if (-not $Script:VitaleOK -and ($tail | Select-String 'Vitale pr.sente : True')) { $Script:VitaleOK = $true }
    $lastC = $tail | Select-String 'CPS pr.sente : (True|False)'    | Select-Object -Last 1; if ($lastC -and $lastC.Line -match 'True') { $Script:CpsOK = $true }
    H2 "Derniers etats de lecture"
    if ($lastC) { INFO $lastC.Line.Trim() }; if ($lastV) { INFO $lastV.Line.Trim() }
    if ($Script:SigMica) { KO "Signature 'Mica..ctor' (MICA introuvable)"; Finding "SIG_MICA" "KO" "Erreur Mica..ctor" }
    if ($Script:Sig1638) { KO "Signature MSI 1638 (MICA x64 bloque MICA x86)"; Finding "SIG_1638" "KO" "Erreur MSI 1638" }

    H2 "Erreurs recentes"
    $errs = $tail | Select-String '\[ERROR\]' | Select-Object -Last 5
    # 04/10 (poste MSI) : le plugin SSV retente la Cryptolib 5.2.2 x64 a chaque lancement ; echec 1603 sans effet quand une Cryptolib x64 plus recente est deja inscrite
    $cryptoRecente = $false
    try { foreach ($h in "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*") { foreach ($r in @(Get-ItemProperty $h -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Composants Cryptographiques CPS.*\(x64\)' -and $_.DisplayName -notmatch 'v5\.2\.2' })) { if ([version]([string]$r.DisplayVersion) -gt [version]"5.2.2") { $cryptoRecente = $true } } } } catch {}
    if ($errs) { foreach ($e in $errs) { if ($cryptoRecente -and $e.Line -match '\[SSV\].*code de sortie 1603') { INFO ($e.Line.Trim() + "   (connu, sans effet : une Cryptolib x64 plus recente est deja installee)") } else { KO $e.Line.Trim() } } } else { OK "Aucune ligne [ERROR] dans les 400 dernieres lignes" }
    # 29/09 : codes 1603 / 1618 du plugin SSV (question ouverte) -> Windows Installer journalise le produit en cause et l'erreur
    # detaillee (evenements MsiInstaller 1033/11708 = produit + statut, 11xxx = "Erreur NNNN" avec le message)
    if ($errs | Where-Object { $_.Line -match 'code de sortie 16\d\d' }) {
        try {
            $mev = @(Get-WinEvent -FilterHashtable @{ LogName = "Application"; ProviderName = "MsiInstaller"; StartTime = (Get-Date).AddDays(-3) } -MaxEvents 300 -ErrorAction Stop |
                Where-Object { ($_.Id -eq 1033 -and $_.Message -notmatch ': 0\.?\s*$') -or $_.Id -eq 11708 -or ($_.Id -ge 11000 -and $_.Id -le 11999 -and $_.Id -notin @(11707, 11724, 11728)) } | Select-Object -First 8)
            if ($mev.Count) {
                INFO "Windows Installer (echecs des 3 derniers jours, produit en cause) :"
                foreach ($x in $mev) { $t = ($x.Message -replace '\s+', ' ').Trim(); if ($t.Length -gt 240) { $t = $t.Substring(0, 240) + "..." }; INFO ("  " + $x.TimeCreated.ToString("dd/MM HH:mm") + " [" + $x.Id + "] " + $t) }
                Finding "MSI_ECHEC" "INFO" "Installation(s) MSI en echec (detail section 4)"
            } else { INFO "Aucun echec detaille dans le journal Windows Installer (installation lancee par JuxtaLink sans journal)" }
        } catch { INFO "Journal Windows Installer illisible" }
    }

    H2 "Diagnostics decodes des reponses (base64)"
    $b64s = $Script:LogLines | Select-String 'Reponse \(format de sortie : json\) : ([A-Za-z0-9+/=]{40,})' | Select-Object -Last 6
    $shown = 0
    foreach ($b in $b64s) {
        try { $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b.Matches[0].Groups[1].Value))
              $diag = [regex]::Match($json, '"diagnostic"\s*:\s*"([^"]+)"').Groups[1].Value
              $msg  = [regex]::Match($json, '"Message"\s*:\s*"([^"]+)"').Groups[1].Value
              $ts   = [regex]::Match($b.Line, '^\[([^\]]+)\]').Groups[1].Value
              if ($diag -or ($msg -and $msg -notmatch '^\s*$')) { $shown++; WARN ($ts + "  " + $(if ($diag) { $diag } else { $msg })); if ($diag -match 'tables binaires') { $Script:SsvTablesErr = $true }; if ($diag -match 'FINESS|praticien|utilisateur') { Finding "ADRI_REJET" "KO" ("Rejet serveur : " + $diag) } }
        } catch {}
    }
    if (-not $shown) { INFO "Aucun message d'erreur serveur dans les dernieres reponses" }
    # 05/10 (CABINET) : erreur ADR siram_40 / FASIBEN = service amont de l'Assurance Maladie indisponible ; "Carte Vitale absente" = carte non inseree
    $dec = @(); foreach ($b in $b64s) { try { $dec += [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b.Matches[0].Groups[1].Value)) } catch {} }
    if (@($dec | Where-Object { $_ -match 'siram_\d+|FASIBEN' }).Count) { Finding "ADR_SERVEUR" "INFO" "Erreur ADR cote Assurance Maladie (siram_40 / FASIBEN)" }
    if (@($dec | Where-Object { $_ -match 'Carte Vitale est absente' }).Count) { Finding "VITALE_ABSENTE" "INFO" "Lecture demandee sans carte Vitale dans le lecteur" }
    # 05/10 (PC26-FILLATRE) : meme apres correction du sesam.ini de ProgramData, la FSV x86 de JuxtaLink peut chercher C:\Windows\sesam.ini (absent)
    if ($Script:SsvTablesErr -and (Has "SESAM_WIN_ABSENT")) { WARN "Erreur 'tables binaires des SSV' alors que C:\Windows\sesam.ini n'existe pas : -Fix le recree"; Finding "SSV_TABLES_ERR" "WARN" "Erreur tables SSV et sesam.ini Windows absent" }
    $cl = @($Script:LogLines | Select-String 'Chemin . charger :\s+(.+?)\s*$' | Select-Object -Last 1)
    if ($cl.Count) { $cp = $cl[0].Matches[0].Groups[1].Value; INFO ("Le plugin SSV charge : " + $cp + $(if (Test-Path $cp) { "" } else { "  (FICHIER ABSENT)" })) }
    # 05/10 (PC26-FILLATRE) : contexte du log autour de la derniere erreur SSV (la FSV y cite parfois le fichier/chemin qu'elle ouvre)
    $iErr = -1; for ($k = $Script:LogLines.Count - 1; $k -ge 0; $k--) { if ($Script:LogLines[$k] -match 'lirecarteps') { $iErr = $k; break } }
    if ($iErr -ge 0) {
        H2 "Contexte du log autour de la derniere erreur SSV"
        $k0 = [math]::Max(0, $iErr - 14); $k1 = [math]::Min($Script:LogLines.Count - 1, $iErr + 2)
        for ($k = $k0; $k -le $k1; $k++) { $x = [string]$Script:LogLines[$k]; $x = [regex]::Replace($x, '(?<!\d)20\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])([01]\d|2[0-3])[0-5]\d[0-5]\d(?!\d)|\d{13,15}', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) if ($m.Value -match '^20\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])([01]\d|2[0-3])[0-5]\d[0-5]\d$') { $m.Value } else { '[nir-masque]' } }); $x = [regex]::Replace($x, '[A-Za-z0-9+/=]{80,}', '[base64-omis]'); $x = [regex]::Replace($x, '(?i)(?<![A-Za-z])((?:numNatPs|numeroNatPs|finess|nir|numSecu\w*|numeroSecu\w*|dateNaissance|nomPatient|prenomPatient|rpps|adeli)\W{1,6})[A-Za-z0-9]{3,}', '$1[masque]'); if ($x.Length -gt 260) { $x = $x.Substring(0, 260) + "..." }; INFO ("  | " + $x) }
    }
    # 29/09 (Dr Plongeron) : erreur MGC sur la DERNIERE reponse = la FSV ne trouve pas sa config de traces -> lecture impossible
    $lastB = $b64s | Select-Object -Last 1
    $lastErrTables = $false; if ($lastB) { try { $lj0 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($lastB.Matches[0].Groups[1].Value)); if ($lj0 -match 'tables binaires') { $lastErrTables = $true } } catch {} }
    if ($lastB) { try { $lj = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($lastB.Matches[0].Groups[1].Value)); if ($lj -match 'Section MGC absente|log4crc') { KO "Derniere reponse de la FSV : erreur MGC (sesam.ini lu par la FSV sans section [MGC] valide) -> lecture impossible"; Finding "MGC_ERREUR" "KO" "Erreur MGC renvoyee par la FSV"; $Script:SesamBad = $true; $Script:VitaleOK = $false } } catch {} }
    if ($Script:SsvTablesErr -and -not (Has "SESAM_WIN_ABSENT") -and -not (Has "SESAM_SSV_TABLE") -and ($lastErrTables)) { KO "Erreur 'tables binaires des SSV' a la DERNIERE lecture alors que tous les sesam.ini sont corrects : tables x86 incompletes ou autre cause (voir TABLES_X86_INCOMPLET et le contenu des sesam.ini ci-dessus)"; Finding "SSV_TABLES_PERSIST" "KO" "Erreur tables SSV persistante malgre sesam.ini corrects" }
} else { WARN "trace.txt absent : lancer une lecture depuis Odaiji puis relancer le diag" }

# ====================================================================
H1 "5. PERFORMANCE (durees mesurees dans le log JuxtaLink)"
# ====================================================================
$Script:Slow = @()
if ($Script:LogLines.Count) {
    $pending = $null; $rows = @()
    foreach ($l in $Script:LogLines) {
        if ($l -match '^\[(\d\d/\d\d/\d{4} \d\d:\d\d:\d\d)\].*\[CLIENT\] Requ.te : GET .*action=([A-Za-z]+)') { $pending = @{T=[datetime]::ParseExact($Matches[1],'dd/MM/yyyy HH:mm:ss',$null); A=$Matches[2]} }
        elseif ($pending -and $l -match '^\[(\d\d/\d\d/\d{4} \d\d:\d\d:\d\d)\].*Reponse envoy') { $t2=[datetime]::ParseExact($Matches[1],'dd/MM/yyyy HH:mm:ss',$null); $rows += [pscustomobject]@{Heure=$pending.T.ToString("dd/MM HH:mm:ss"); Action=$pending.A; Sec=($t2-$pending.T).TotalSeconds}; $pending=$null }
    }
    $rows = $rows | Select-Object -Last 25
    foreach ($r in $rows) { $tag = if ($r.Sec -ge 3) { " <- LENT" } else { "" }; W (("  {0}  {1,-28} {2,5:N0} s{3}" -f $r.Heure, $r.Action, $r.Sec, $tag)) $(if ($r.Sec -ge 3) { "Yellow" } else { "Gray" }) }
    $stats = $rows | Group-Object Action | ForEach-Object { [pscustomobject]@{Action=$_.Name; N=$_.Count; Moy=[math]::Round(($_.Group | Measure-Object Sec -Average).Average,1); Max=($_.Group | Measure-Object Sec -Maximum).Maximum} }
    H2 "Par action"
    foreach ($s in $stats) { INFO (("{0,-28} n={1,-3} moy={2,5} s  max={3,4} s" -f $s.Action, $s.N, $s.Moy, $s.Max)); if ($s.Moy -ge 3) { $Script:Slow += $s.Action; Finding ("SLOW_" + $s.Action.ToUpper()) "WARN" ($s.Action + " : " + $s.Moy + " s en moyenne") } }
    if (-not $rows.Count) { INFO "Aucune paire requete/reponse trouvee" }
} else { INFO "Pas de log" }

# DRSAMITIER 28/09 : "appels CPS tres longs" -> causes locales listees a chaque diag, meme sans mesure
H2 "Causes de lenteur presentes sur ce poste (a traiter si les lectures sont lentes)"
$lent = 0
$rivaux = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $pth = $(try { $_.Path } catch { "" }); ($_.ProcessName -match '^(ClmLive|Pyxvital|VitalZen)$') -or ($pth -match 'JFSE\\Lecteur|RESIP\\JFSE|\\jfse\\|pyxvital|vitalzen|weda') } | ForEach-Object { $_.ProcessName + " (" + $(try { $_.Path } catch { "" }) + ")" } | Select-Object -Unique)
if ($rivaux) { WARN ("Programmes qui se disputent le lecteur avec JuxtaLink / DMP Connect : " + ($rivaux -join ", ") + " -> a couper si l'ancien logiciel n'est plus utilise (question 7n)"); Finding "PROC_READER" "WARN" "Autres programmes sur le lecteur"; $lent++ }
$cp = Get-Service CertPropSvc -ErrorAction SilentlyContinue
if ($cp -and $cp.StartType -eq "Automatic") { WARN "CertPropSvc en demarrage automatique : relit tous les certificats de la CPS a chaque insertion -> passer en Manuel (-Fix 7v)"; Finding "CERTPROP_AUTO" "WARN" "CertPropSvc automatique"; $lent++ }
$vpn = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" -and ($_.InterfaceDescription + " " + $_.Name) -match 'TAP|TUN|Wintun|OpenVPN|WireGuard|Fortinet|AnyConnect|GlobalProtect|Pulse|VPN' })
if ($vpn) { WARN ("VPN connecte (" + (($vpn | ForEach-Object Name) -join ", ") + ") : ADRi, DMP et teletransmission peuvent passer par le tunnel -> test : deconnecter le VPN et comparer (verifier avec le cabinet)"); Finding "VPN_ACTIF" "WARN" "VPN connecte"; $lent++ }
if (Has "AV_TIERS") { WARN "Antivirus tiers : demander les exclusions C:\Program Files (x86)\santesocial, C:\Program Files (x86)\Juxta, C:\Program Files (x86)\DmpConnect-JS2 (et le processus JuxtaLink.exe)"; $lent++
    # 29/09 (PCCABINET) : Bitdefender grand public = exceptions a poser a la main (pas de ligne de commande, autoprotection)
    if (($Script:Findings | Where-Object Code -eq "AV_TIERS").Msg -match 'Bitdefender') { INFO "  Bitdefender : Protection > Antivirus > Parametres > Gerer les exceptions > + Ajouter une exception (dossiers ci-dessus, cocher Antivirus ET Advanced Threat Defense) ; Protection > Prevention des menaces en ligne > Gerer les exceptions : app.odaiji.co et localhost" } }
$crAll = @($gie | Where-Object { $_.DisplayName -match 'cryptolib|Cryptographiques' })
if ($crAll.Count -gt 2) { WARN ("Cryptolib CPS installee " + $crAll.Count + " fois : nettoyage possible avec le support (Nettoyage.bat), apres mesure"); $lent++ }
if (-not $lent) { OK "Aucune cause de lenteur connue sur ce poste" }

# ====================================================================
H1 "6. VERDICT"
# ====================================================================
$Script:Scenario = "UNKNOWN"
# JuxtaLink en Full PC/SC (GALSS x86 bloque et absent) et lectures presentes dans le log : galss.ini ne le concerne plus
$Script:PcscOnly = ($Script:BloqGalss -contains "true") -and -not $Script:GalssX86.Count -and [bool](@($Script:LogLines) -match 'LireDroitsVitale|LireCartePS')
if ((Has "NO_CPS") -or (Has "SCARDSVR"))                     { $Script:Scenario = "READER"; KO "Windows ne voit pas la CPS -> lecteur / USB / pilote." }
elseif (Has "SAC_ON")                                    { $Script:Scenario = "SAC";    KO "Smart App Control bloque mica.dll : desactiver Smart App Control (Parametres > Confidentialite et securite > Securite Windows > Controle des applications et du navigateur), puis redemarrer JuxtaLink. Prevenir le medecin : non reactivable sans reinstaller Windows." }
elseif ((Has "JUXTA_STOPPED") -and -not ($Script:Findings | Where-Object { $_.Level -eq "KO" -and $_.Code -notin @("JUXTA_STOPPED","LNA_CHROME","LNA_EDGE") })) { $Script:Scenario = "ARRETE"; KO "JuxtaLink ne tourne pas : Odaiji ne joint aucun lecteur (carte non lue). Icone JuxtaLink (Odaiji) du Bureau ou Demarrage-JuxtaLink.bat ; -Fix le relance et cree le demarrage sans UAC." }
elseif (Has "PORT_CONFLICT")                            { $Script:Scenario = "PORT";   KO "Un autre logiciel occupe le port de JuxtaLink : l'arreter (et son demarrage auto) ou le reconfigurer, puis relancer JuxtaLink." }
elseif (Has "NO_PLUGIN")                                 { $Script:Scenario = "PREMIERE_LECTURE"; OK "Poste neuf : aucune lecture faite depuis Odaiji. FSV/MICA/tables/sesam.ini arrivent a la 1re lecture CPS + Vitale : lancer 1-Installer.bat (ou faire une lecture) puis refaire le diag." }
elseif (Has "ADRI_REJET")                                { $Script:Scenario = "ADRI";   KO "Cartes lues, mais rejet serveur ADRi (FINESS / praticien). Parametrage Odaiji ou support Juxta, rien a faire sur le poste." }
elseif ((($Script:SigMica -or (Has "MICA_X64")) -and -not $micaX86) -or ((Has "MICA_X64") -and $Script:Sig1638))              { $Script:Scenario = "MICA";   KO "MICA x86 absent" + $(if ($Script:MicaX64Product) { " + MICA x64 fantome" } else { "" }) + ". Correction : -Fix." }
elseif (Has "NO_TABLES")                                { $Script:Scenario = "TABLES"; KO "Tables FSV manquantes (srt/ssv/sts) : lecture et facturation impossibles. Correction : -Fix (MSI FSV du GIE)." }
elseif ($Script:SesamBad -or (Has "SESAM_SSV_TABLE"))      { $Script:Scenario = "SESAM";  KO "sesam.ini absent/vide/incorrect. Correction : -Fix." }
elseif (((Has "GALSS_VITALE_CL") -or (Has "GALSS_MISMATCH") -or ((Has "GALSS_ABSENT_READER") -and (Has "GALSS_MISMATCH_CPS"))) -and -not $Script:PcscOnly) { $Script:Scenario = "GALSS";  KO "galss.ini ne decrit pas le lecteur reel (fichier partage avec DMP Connect / iCanopee). Correction : -Fix." }
elseif ($Script:VitaleOK -and $Script:CpsOK)             { $Script:Scenario = "OK";     OK "Derniere lecture CPS + Vitale OK." }
elseif ((Test-Path $Paths.JuxtaExe) -and -not ($Script:Findings | Where-Object { $_.Level -eq "KO" -and $_.Code -notlike "LNA_*" })) { $Script:Scenario = "A_TESTER"; OK "Poste configure, aucun blocage detecte. Pas de lecture Vitale reussie dans le log : faire une lecture CPS + Vitale dans Odaiji puis 3-Diag-seul.bat."; INFO "Si Odaiji dit 'carte Vitale non reconnue' alors que la carte est inseree : relancer JuxtaLink (icone 'JuxtaLink (Odaiji)' sur le Bureau, ou Reparer-lecteur.bat), puis relire (HANSIANE 29/09 : lecteur Telium 3 fentes)." }
else { WARN "Cas non reconnu : envoyer ce rapport a Claude." }
# 28/09 : en Full PC/SC, JuxtaLink n'utilise plus galss.ini (lectures OK) -> galss.ini incoherent ne concerne qu'Icanopee (DMP)
if ($Script:Scenario -ne "GALSS" -and ((Has "GALSS_VITALE_CL") -or (Has "GALSS_MISMATCH") -or ((Has "GALSS_ABSENT_READER") -and (Has "GALSS_MISMATCH_CPS")))) { WARN "galss.ini ne decrit pas le lecteur reel : sans effet sur Odaiji (JuxtaLink en PC/SC direct), a corriger seulement si DMP Connect / iCanopee ne marche pas (Reparer-lecteur.bat)." }
if (Has "GALSS_MISSING") { WARN "galss.ini ABSENT : DMP Connect / iCanopee ne lit pas la CPS. Reparer-lecteur.bat (CPS + Vitale inserees) le recree, puis redemarrer le service DMP Connect." }
if (Has "ADR_SERVEUR") { WARN "Erreurs ADR 'siram_40 / FASIBEN' : c'est le service de l'Assurance Maladie qui est indisponible, pas le poste. Reessayer plus tard ; si cela dure, noter les horaires et contacter le support Assurance Maladie." }
if (Has "VITALE_ABSENTE") { WARN "Une lecture a ete faite sans carte Vitale dans le lecteur ('La Carte Vitale est absente') : inserer la Vitale (bien enfoncee) puis relire." }
if (Has "DMP_PCSC_ERR") { WARN "DMP Connect n'arrive plus a lister les lecteurs (Efficience : 'Lecteurs de cartes introuvables') : Reparer-DMP.bat (ou 2-Depanner.bat) redemarre son service." }
if (Has "DMP_TIMEOUT_GALSS") { KO "En plus : DMP Connect / iCanopee en timeout a cause de galss.ini (lecteur absent) : Reparer-lecteur.bat puis redemarrer le service DMP Connect." }
if ((Has "SRV_CEGEDIM") -and (Has "MICA_X64")) { WARN "Le service Octave (mise a jour Cegedim) reinstalle le MICA x64 : repondre n a Cegedim (Octave coupe, base Oracle conservee)." }
if ((Has "SAC_EVAL") -and $Script:Scenario -ne "SAC") { WARN "Smart App Control en evaluation : le desactiver maintenant, sinon Windows bloquera mica.dll dans quelques jours." }
if ((Has "JUXTA_STOPPED") -and $Script:Scenario -ne "ARRETE") { KO "En plus : JuxtaLink ne tourne pas (cause immediate de 'carte non lue') : le relancer (icone JuxtaLink (Odaiji) ou -Fix)." }
if ($Script:Slow.Count) {
    W ""; WARN ("LENTEURS sur : " + ($Script:Slow -join ", ") + ". Causes candidates presentes sur ce poste :")
    $causes = @()
    if (Has "PROC_READER")         { $causes += "programmes concurrents sur le lecteur (voir 'Causes de lenteur')" }
    if (Has "VPN_ACTIF")           { $causes += "VPN connecte (ADRi / DMP par le tunnel)" }
    if ((Has "SESAM_PATH") -or (Has "SESAM_MISSING") -or (Has "SESAM_EMPTY") -or (Has "SESAM_WRONG_ARCH") -or (Has "SESAM_MGC")) { $causes += "sesam.ini absent/incorrect ou tables introuvables (retries fichiers 10x500ms)" }
    if (Has "GALSS_ABSENT_READER") { $causes += "canal galss.ini sur lecteur absent (timeouts)" }
    if (Has "GALSS_VITALE_CL")     { $causes += "canal Vitale sur interface sans contact" }
    if (Has "CARD_SHARED")         { $causes += "carte tenue par un autre processus (retries exclusivite 10x500ms)" }
    if ($Script:Findings | Where-Object Code -like "PROC_*") { $causes += "residus editeur actifs sur le lecteur (Neutraliser-Cegedim.bat si Cegedim n'est plus utilise)" }
    if (Has "AV_TIERS")            { $causes += "antivirus tiers (exclusions santesocial/Juxta a verifier)" }
    if ($cps -and $cps.Status -eq "Running") { $causes += "CertPropSvc actif (test : Stop-Service CertPropSvc)" }
    if (Has "CRYPTO_MULTI")        { $causes += "Cryptolib en double" }
    if ($Script:Slow -contains "PatientAdrSilent" -and -not $causes) { $causes += "aucune cause locale trouvee -> reseau/proxy/TLS vers ADRi" }
    foreach ($c in $causes) { INFO ("  - " + $c) }
}
# Filet de securite Full PC/SC : blocage GALSS pose mais lecture en echec -> retour a false
# DRPARDON 24/09 : le filet se declenchait alors que l'echec venait de MICA -> uniquement si aucune autre cause connue
if (($Script:BloqGalss -contains "true") -and -not $Script:GalssX86.Count -and -not ($Script:CpsOK -and $Script:VitaleOK) -and $Script:LogLines.Count -and ($Script:Scenario -notin @("MICA","SESAM","READER","PORT","TABLES")) -and -not ((Has "NO_TABLES") -or (Has "SESAM_MISSING") -or (Has "SESAM_MGC") -or (Has "NO_MICA_X86") -or (Has "PORT_CONFLICT"))) {
    $recent = ($Script:LogLines | Select-Object -Last 400) -join "`n"
    if ($recent -match 'CPS pr.sente : False|Vitale pr.sente : False') {
        WARN "Lecture en echec alors que la reinstallation du GALSS est bloquee : retour a BLOQUERINSTALLEGALSS=false (filet de securite)"
        Get-ChildItem (Join-Path $Paths.PlugDir "SSV") -Recurse -Filter SSV.dll.config -ErrorAction SilentlyContinue | ForEach-Object { $t = Get-Content $_.FullName -Raw; $t = $t -replace 'BLOQUERINSTALLEGALSS"\s+value="true"', 'BLOQUERINSTALLEGALSS" value="false"'; [IO.File]::WriteAllText($_.FullName, $t, [Text.Encoding]::UTF8) }
        Finding "GALSS_REVERT" "WARN" "Blocage GALSS annule automatiquement (lecture en echec)"
        INFO "Relancer JuxtaLink et refaire une lecture ; si elle repasse, le poste a besoin du GALSS x86 : le signaler a Juxta."
    }
}
W ""; W ("Scenario : " + $Script:Scenario) "Cyan"; W "Constats :"
foreach ($f in $Script:Findings) { INFO ("  " + $f.Code.PadRight(22) + $f.Level.PadRight(6) + $f.Msg) }

# ====================================================================
if ($Fix) {
H1 "7. REPARATION"
# ====================================================================
    if ($Script:Scenario -in @("ADRI","READER","OK","UNKNOWN") -and -not $Script:SesamBad -and -not ((Has "NO_AUTOSTART") -or (Has "JUXTA_STOPPED") -or (Has "JX_MSI_SOURCE") -or (Has "JX_MSI_REPAIR") -or (Has "JX_MOVED"))) { WARN ("Rien a reparer automatiquement pour le scenario " + $Script:Scenario + ".") }

    # 7k. user.config du profil de l'utilisateur (serveurs MadeForMed + port 1234) - POSTE1 30/09
    if ((Test-Path $Paths.JuxtaExe) -and ((Has "UC_ABSENT") -or (Has "UC_INCOMPLET") -or (Has "PORT_CFG") -or (Has "UC_ADMIN"))) {
        H2 "7k. user.config JuxtaLink (serveurs MadeForMed, port 1234)"
        $kitUc = Join-Path $PSScriptRoot "user.config"
        if (-not (Test-Path $kitUc)) { WARN "user.config absent du kit : rien a poser" }
        elseif (Confirm-Step ("Poser le user.config MadeForMed dans le profil de l'utilisateur (" + $UserAppData + ") et remettre le port 1234 ?") -Safe) {
            try {
                $ucd = Join-Path $UserAppData "juxta\juxtalink"; New-Item -ItemType Directory -Force $ucd | Out-Null; $ucf = Join-Path $ucd "user.config"
                if (Test-Path $ucf) { Copy-Item $ucf ($ucf + ".bak-" + $Stamp) -Force }
                if ((Test-Path $ucf) -and (Has "PORT_CFG") -and -not (Has "UC_INCOMPLET")) {
                    $t = (Get-Content $ucf -Raw) -replace '(key="port"\s+value=")\d+(")', '${1}1234${2}'
                    [IO.File]::WriteAllText($ucf, $t, (New-Object Text.UTF8Encoding $false)); OK ("Port remis a 1234 dans " + $ucf)
                } else { Copy-Item $kitUc $ucf -Force; OK ("user.config MadeForMed pose : " + $ucf) }
                Select-String $ucf -Pattern 'tokenServerUrl|updateServerUrl|"port"' | ForEach-Object { INFO ("    " + $_.Line.Trim()) }
                if ($env:APPDATA -and ($env:APPDATA -ne $UserAppData)) {
                    $ucdA = Join-Path $env:APPDATA "juxta\juxtalink"; New-Item -ItemType Directory -Force $ucdA | Out-Null; $ucA = Join-Path $ucdA "user.config"
                    if (Test-Path $ucA) { Copy-Item $ucA ($ucA + ".bak-" + $Stamp) -Force }
                    Copy-Item $kitUc $ucA -Force; OK ("user.config MadeForMed pose aussi dans le profil du compte admin : " + $ucA)
                }
                Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2; Start-Jx; OK "JuxtaLink relance avec la nouvelle configuration. Refaire une lecture dans Odaiji."
            } catch { KO ("user.config non pose : " + $_.Exception.Message) }
        }
    }

    # 7s. Demarrage de JuxtaLink sans UAC + relance si arrete (retour terrain 28/09)
    if ($Script:HasJxLib -and (Test-Path $Paths.JuxtaExe) -and ((Has "NO_AUTOSTART") -or (Has "JUXTA_STOPPED") -or (Has "GARDIEN_ABSENT"))) {
        H2 "7s. Demarrage de JuxtaLink sans UAC"
        if ((Has "NO_AUTOSTART") -and (Confirm-Step "Creer le demarrage automatique de JuxtaLink sans UAC (tache planifiee + icone Bureau) ?" -Safe)) {
            try { Install-JxTask -User (Get-JxUser) -UserAppData $UserAppData | ForEach-Object { if ($_ -match '^ATTENTION') { WARN $_ } else { OK $_ } } } catch { KO ("Tache non creee : " + $_.Exception.Message) }
        }
        if ((Has "GARDIEN_ABSENT") -and -not (Has "NO_AUTOSTART") -and (Confirm-Step "Installer le gardien : veille de JuxtaLink toutes les 10 min, relance s'il est arrete ?" -Safe)) {
            try { OK (Install-JxGardien) } catch { KO ("Gardien non installe : " + $_.Exception.Message) }
        }
        if (Has "JUXTA_STOPPED") { Start-Jx; Start-Sleep 8; if (Get-Process JuxtaLink -ErrorAction SilentlyContinue) { OK "JuxtaLink demarre" } else { KO "JuxtaLink ne demarre pas : le lancer a la main et noter le message d'erreur" } }
    }

    # 7r2. FSV : source MSI fragile (Telechargements/Temp) -> copie du MSI du kit dans ProgramData, UNIQUEMENT dans ce cas
    if ($Script:HasJxLib) {
        if (Has "FSV_MSI_SOURCE") {
            $kitFsv = @(Get-ChildItem (Join-Path $PSScriptRoot "installeurs\fsv*.msi"),(Join-Path $PSScriptRoot "fsv*.msi") -ErrorAction SilentlyContinue | ForEach-Object FullName)
            if ($kitFsv.Count) {
                H2 "7r2. FSV : source d'installation durable"
                if (Confirm-Step "Copier le MSI FSV du kit dans C:\ProgramData\MadeForMed\FSV et le declarer comme source de Windows Installer (sans reinstaller) ?" -Safe) {
                    try { Repair-FsvMsiSource $kitFsv | ForEach-Object { if ($_ -match '^ATTENTION') { WARN $_ } else { OK $_ } } } catch { KO ("7r2 : " + $_.Exception.Message) }
                }
            }
        }
    }

    # 7r. Fenetres "package d'installation introuvable" : source MSI + elements deplaces (retour terrain 29/09)
    if ($Script:HasJxLib -and ((Has "JX_MSI_SOURCE") -or (Has "JX_MSI_REPAIR") -or (Has "JX_MOVED"))) {
        H2 "7r. JuxtaLink : fenetres 'Aucun package d'installation' (source MSI)"
        if (Confirm-Step "Remettre en place les elements d'origine de JuxtaLink (desactives, pas deplaces), retablir sa source d'installation et le reparer en silence ?" -Safe) {
            try {
                Restore-JxMoved | ForEach-Object { if ($_ -match '^ATTENTION') { WARN $_ } else { OK $_ } }
                $kitMsi = Get-ChildItem (Join-Path $PSScriptRoot "installeurs\SetupJuxtaLink*.msi") -ErrorAction SilentlyContinue | Select-Object -First 1
                $rr = @(Repair-JxMsiSource $(if ($kitMsi) { $kitMsi.FullName } else { "" }))
                $rr | Where-Object { $_ -ne "RELANCER" } | ForEach-Object { if ($_ -match '^ATTENTION') { WARN $_ } else { OK $_ } }
                if (Get-JxTask) { Install-JxTask -User (Get-JxUser) -UserAppData $UserAppData | ForEach-Object { if ($_ -match '^ATTENTION') { WARN $_ } else { OK $_ } } }
                if ($rr -contains "RELANCER") { Start-Jx; Start-Sleep 8; if (Get-Process JuxtaLink -ErrorAction SilentlyContinue) { OK "JuxtaLink relance" } else { WARN "JuxtaLink a relancer (icone 'JuxtaLink (Odaiji)')" } }
            } catch { KO ("7r : " + $_.Exception.Message) }
        }
    }

    # 7l. Navigateurs sans politique Local Network Access (erreurs DRC) : jusqu'ici seulement a l'installation (4b)
    if (($Script:Findings | Where-Object { $_.Code -like "LNA_*" -and $_.Level -in @("KO","WARN") }) -and (Test-Path (Join-Path $PSScriptRoot "Autoriser-Odaiji-Chrome.ps1"))) {
        H2 "7l. Navigateurs : autoriser Odaiji (Local Network Access)"
        if (Confirm-Step "Autoriser Odaiji dans Chrome, Edge et Firefox (erreurs DRC a la teletransmission) ?" -Safe) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "Autoriser-Odaiji-Chrome.ps1") -NoPause 2>&1 | Where-Object { $_ -notmatch 'Entree pour fermer' } | ForEach-Object { INFO ("  " + $_) }
            INFO "Pris en compte au prochain redemarrage des navigateurs (verifier : chrome://policy)"
        }
    }

    # 7n. Anciens logiciels metiers : une question par editeur detecte, neutralisation si plus utilise
    if ($Script:Editeurs) {
        H2 "7n. Anciens logiciels metiers"
        foreach ($e in $Script:Editeurs) {
            $gone = Decide-Editeur $e
            if ($gone -eq $true) {
                if ($e.Garder) { W (">> " + $e.Nom + " n'est plus utilise -> services et programmes coupes SEULEMENT (dossiers patients possibles : ni desinstallation ni quarantaine)") "Magenta" }
                else { W (">> " + $e.Nom + " n'est plus utilise -> neutralisation puis desinstallation (hors briques partagees, sans redemarrage)") "Magenta" }
                $nc = Join-Path $PSScriptRoot "Neutraliser-Cegedim.ps1"
                if ((Test-Path $nc) -and $e.Garder) { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $nc -Auto -Nom $e.Nom -Motif $e.Motif 2>&1 | ForEach-Object { INFO ("  " + $_) } }
                elseif (Test-Path $nc) { $ncArgs = @("-Auto","-Desinstaller","-Nom",$e.Nom,"-Motif",$e.Motif); $dj = (@($e.Dossiers) | Where-Object { $_ }) -join "|"; if ($dj) { $ncArgs += @("-Dossiers",$dj) }; if ($e.NonMsi) { $ncArgs += "-NonMsi" }
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $nc @ncArgs 2>&1 | ForEach-Object { INFO ("  " + $_) } }
                if ($e.Nom -eq "Cegedim") { $SansCegedim = $true }
            } elseif ($gone -eq $false) { INFO ($e.Nom + " encore utilise : rien n'est modifie (" + $e.Bloquants + ")") }
            else { WARN ($e.Nom + " : usage non confirme, rien n'est modifie (relancer Reparer-interactif.bat pour repondre)") }
        }
    }

    # 7p. Conflit de port (Dr Neyens 25/09) : comme pour Cegedim, menage propose si l'ancienne solution n'est plus utilisee
    if ((Has "PORT_CONFLICT") -and $Script:PortHolder) {
        $ph = $Script:PortHolder
        H2 ("7p. Liberer le port " + $JxPort + " (occupe par " + $ph.Name + ")")
        $sys = $ph.Name -match '^(System|svchost|Idle|lsass|services|wininit|smss|csrss)$' -or -not $ph.Path
        $dirp = if ($ph.Path) { Split-Path $ph.Path -Parent } else { "" }
        $lbl = if ($ph.Company) { $ph.Company } elseif ($dirp) { Split-Path $dirp -Leaf } else { $ph.Name }
        if ($sys) { KO ("Port tenu par un composant Windows (" + $ph.Name + ") : a traiter par le support, rien n'est modifie") }
        elseif ($dirp -match 'Juxta|DmpConnect|santesocial|TeamViewer|AnyDesk') { KO ("Programme a ne pas toucher (" + $ph.Path + ") : a traiter par le support") }
        else {
            INFO ("Programme : " + $ph.Path + "  (editeur : " + $lbl + ")")
            $go = $false; $own = $Script:Editeurs | Where-Object { ($ph.Name + ' ' + $ph.Path) -match $_.Motif } | Select-Object -First 1
            if ($own -and $Script:Decision.ContainsKey($own.Nom)) { $go = [bool]$Script:Decision[$own.Nom]; if (-not $go) { KO ("Conflit : " + $own.Nom + " (encore utilise) et JuxtaLink veulent le meme port " + $JxPort + ". A traiter avec les editeurs.") } }
            elseif ($Auto) { if ($LibererPort) { $go = $true; W (">> " + $lbl + " n'est plus utilise (reponse donnee a l'installeur) -> neutralisation") "Magenta" } else { WARN "Usage de l'ancienne solution non confirme : rien n'est modifie" } }
            else { $go = -not (Confirm-Step ("Le medecin utilise-t-il ENCORE " + $lbl + " (" + $ph.Name + ") ? (n = il sera neutralise)")) }
            if ($go) {
                $motif = [regex]::Escape($ph.Name) + '|' + [regex]::Escape($dirp)
                $nc = Join-Path $PSScriptRoot "Neutraliser-Cegedim.ps1"
                if (Test-Path $nc) { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $nc -Auto -Nom $lbl -Motif $motif 2>&1 | ForEach-Object { INFO ("  " + $_) } }
                Get-NetTCPConnection -LocalPort $JxPort -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue } | Where-Object { $_.ProcessName -notmatch '^JuxtaLink' } | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep 2; Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2
                Start-Jx; Start-Sleep 8
                $now = @(Get-NetTCPConnection -LocalPort $JxPort -State Listen -ErrorAction SilentlyContinue | ForEach-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName })
                if ($now -match '^JuxtaLink') { OK ("Port " + $JxPort + " : JuxtaLink a l'ecoute. Refaire une lecture CPS dans Odaiji.") } else { KO ("Port " + $JxPort + " : " + ($now -join ", ") + " -> verifier a la main (netstat -ano | findstr :" + $JxPort + ")") }
            } elseif (-not $Auto) { KO ("Conflit : " + $lbl + " et JuxtaLink veulent le meme port " + $JxPort + ". Changer le port de l'un des deux (support editeur / Juxta).") }
        }
    }

    # 7t. Tables FSV manquantes (Dr Neyens 25/09 : srt vides en x86 ; sur GERBAL elles n'existaient qu'en x64).
    # Le MSI FSV x64 officiel du GIE (dans le kit) les fournit. Installe sans question, puis sesam.ini regenere.
    if ((Has "NO_TABLES") -and $Script:FsvMsi.Count) {
        H2 "7t. Tables FSV manquantes : installation du MSI FSV officiel (GIE)"
        $msi = $Script:FsvMsi[0]; INFO ("MSI : " + $msi.FullName)
        if (Confirm-Step "Installer les FSV du GIE pour recuperer les tables manquantes ?" -Safe) {
            $p = [pscustomobject]@{ ExitCode = (Invoke-FsvMsi "/i `"$($msi.FullName)`" /qn /norestart REBOOT=ReallySuppress") }
            INFO ("msiexec : " + $p.ExitCode)
            if ($p.ExitCode -eq 1638) { $p2 = Start-Process msiexec.exe -ArgumentList "/fa `"$($msi.FullName)`" /qn /norestart REBOOT=ReallySuppress" -Wait -PassThru; INFO ("reparation /fa : " + $p2.ExitCode) }
            Set-MgcApresMsi
            foreach ($t in "ssv","srt","sts") {
                if ($Script:TableDir[$t]) { continue }
                $cand = @(Get-ChildItem ($Paths.SanteX86 + "\fsv"),($Paths.SanteX64 + "\fsv") -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName $t } | Where-Object { (Get-ChildItem $_ -File -Recurse -ErrorAction SilentlyContinue).Count -gt 0 })
                if ($cand) { $Script:TableDir[$t] = $cand[0]; OK ("Tables " + $t + " -> " + $cand[0]) } else { KO ("Tables " + $t + " toujours absentes apres MSI") }
            }
            $Script:SesamBad = $true   # sesam.ini regenere avec les bons chemins (le MSI peut ecrire le sien)
        }
    }

    if (Has "SSV_TABLES_ERR") { $Script:SesamBad = $true }   # 7a recree C:\Windows\sesam.ini (tables resolues sur ce poste)
    if ($Script:SesamBad) {
        H2 ("7a. sesam.ini (FSV " + $FsvVersion + ", x86)")
        if (Confirm-Step "Recreer C:\Windows\sesam.ini et ses repertoires ?" -Safe) {
            if (Test-Path $Paths.SesamIni) { Copy-Item $Paths.SesamIni ($Paths.SesamIni + ".bak-" + $Stamp) -Force }
            $v = $FsvVersion
            $tSsv = if ($Script:TableDir["ssv"]) { $Script:TableDir["ssv"] } else { "%ProgramFiles(x86)%\santesocial\fsv\$v\ssv" }
            $tSrt = if ($Script:TableDir["srt"]) { $Script:TableDir["srt"] } else { "%ProgramFiles(x86)%\santesocial\fsv\$v\srt" }
            $tSts = if ($Script:TableDir["sts"]) { $Script:TableDir["sts"] } else { "%ProgramFiles(x86)%\santesocial\fsv\$v\sts" }
            INFO ("Tables retenues : ssv=" + $tSsv); INFO ("                  srt=" + $tSrt); INFO ("                  sts=" + $tSts)
            # Chemins ABSOLUS (Dr Neyens 25/09 : erreur MGC ; certaines FSV ne developpent pas %ALLUSERSPROFILE%)
            $pd = "C:\ProgramData\santesocial\fsv\$v"
            $tSsv = [Environment]::ExpandEnvironmentVariables($tSsv); $tSrt = [Environment]::ExpandEnvironmentVariables($tSrt); $tSts = [Environment]::ExpandEnvironmentVariables($tSts)
            $content = @"
; sesam.ini genere par JuxtaDiag v$($Script:Version) - chemins de tables resolus sur ce poste
[COMMUN]
RepertoireTravail=$pd\adm
RepertoireTable=$tSsv
ActivationTracesLog4c=0
RepertoireConfigTrace=$pd\conf

[SSV]
RepertoireTable=$tSsv
tempoexclusivite=500
repetitionexclusivite=10
tempoexclusivitePCSC=500
repetitionexclusivitePCSC=10
tempoaccesfichier=500
repetitionaccesfichier=10

[MGC]
RepertoireConfigTrace=$pd\conf

[SRT]
RepertoireTable=$tSrt
repertoiremodification=$pd\srt

[STS]
RepertoireTable=$tSts
"@
            [IO.File]::WriteAllText($Paths.SesamIni, $content, [Text.Encoding]::GetEncoding(1252))
            foreach ($d in "adm","conf","srt") { New-Item -ItemType Directory -Force (Join-Path "C:\ProgramData\santesocial\fsv\$v" $d) | Out-Null }
            $vers = @($v) + @(Get-ChildItem "C:\Program Files (x86)\santesocial\fsv","C:\Program Files\santesocial\fsv" -Directory -ErrorAction SilentlyContinue | Where-Object Name -match '^\d+\.\d+\.\d+$' | ForEach-Object Name) | Select-Object -Unique
            foreach ($vv in $vers) {
            New-Item -ItemType Directory -Force "C:\ProgramData\santesocial\fsv\$vv\conf" | Out-Null
            $l4c = "C:\ProgramData\santesocial\fsv\$vv\conf\log4crc.xml"
            if (-not (Test-Path $l4c)) { [IO.File]::WriteAllText($l4c, "<?xml version=`"1.0`" encoding=`"ISO-8859-1`"?>`r`n<!DOCTYPE log4c SYSTEM `"`">`r`n<log4c version=`"1.2.4`">`r`n  <config><bufsize>0</bufsize><debug level=`"0`"/><nocleanup>0</nocleanup><reread>1</reread></config>`r`n  <category name=`"root`" priority=`"error`"/>`r`n  <appender name=`"stderr`" type=`"stream`" layout=`"basic`"/>`r`n  <layout name=`"basic`" type=`"basic`"/>`r`n</log4c>`r`n", [Text.Encoding]::GetEncoding(1252)); INFO "log4crc.xml cree (traces desactivees)" }
            }
            $rk = "HKLM:\SOFTWARE\WOW6432Node\GIE SESAM VITALE\FSV\$v"
            if (-not (Test-Path $rk)) { New-Item -Path $rk -Force | Out-Null; New-ItemProperty -Path $rk -Name "InstallDir" -Value (Join-Path $Paths.SanteX86 "fsv\$v") -Force | Out-Null; INFO "Cle registre GIE FSV creee" }
            OK "sesam.ini ecrit"
            # 29/09 : la FSV peut lire un autre sesam.ini (ProgramData\...\conf, Program Files) : on y (re)pose seulement la section [MGC]
            foreach ($o in @($Script:MgcOthers)) {
                try {
                    $ov = if ($o -match 'fsv\\(\d+\.\d+\.\d+)') { $Matches[1] } else { $v }
                    $odir = "C:\ProgramData\santesocial\fsv\$ov\conf"; New-Item -ItemType Directory -Force $odir | Out-Null
                    if (-not (Test-Path (Join-Path $odir "log4crc.xml")) -and (Test-Path "$pd\conf\log4crc.xml")) { Copy-Item "$pd\conf\log4crc.xml" (Join-Path $odir "log4crc.xml") -Force }
                    Copy-Item $o ($o + ".bak-" + $Stamp) -Force
                    $keep = @(); $sec = ""
                    foreach ($ln in (Get-Content $o)) { if ($ln -match '^\s*\[(.+?)\]') { $sec = $Matches[1].Trim().ToUpper() }; if ($sec -ne "MGC") { $keep += $ln } }
                    $keep += @("", "[MGC]", ("RepertoireConfigTrace=" + $odir))
                    [IO.File]::WriteAllText($o, (($keep -join "`r`n") + "`r`n"), [Text.Encoding]::GetEncoding(1252))
                    OK ("[MGC] posee dans " + $o + " -> " + $odir)
                } catch { WARN ("[MGC] non posee dans " + $o + " : " + $_.Exception.Message) }
            }
            if ($Script:MgcOthers.Count -or (Has "MGC_ERREUR")) { INFO "Relancer JuxtaLink puis refaire une lecture (la FSV relit sesam.ini au chargement)" }
        }
    }

    if ($Script:FsvMsi.Count -and ($Script:SesamBad -or (Has "NO_FSV_X86") -or (Has "FSV_NOREG"))) {
        H2 "7a-bis. Installer / reparer les FSV via le MSI officiel du GIE"
        $msi = $Script:FsvMsi[0]; INFO ("MSI : " + $msi.Name + "  (" + $(if ($msi.Name -match 'x86') { "32 bits, celui que JuxtaLink utilise" } else { "64 bits : recree sesam.ini et les repertoires partages, n'installe pas les DLL 32 bits" }) + ")")
        if (Confirm-Step "Lancer msiexec /i (installation ou reparation silencieuse) ?") {
            $p = [pscustomobject]@{ ExitCode = (Invoke-FsvMsi "/i `"$($msi.FullName)`" /qn /norestart REINSTALLMODE=amus REINSTALL=ALL") }
            INFO ("msiexec code de sortie : " + $p.ExitCode + "  (0 = OK, 1638 = deja installe -> reparation tentee, 3010 = redemarrage requis)")
            if ($p.ExitCode -eq 1638) { $p2 = Start-Process msiexec.exe -ArgumentList "/fa `"$($msi.FullName)`" /qn /norestart REBOOT=ReallySuppress" -Wait -PassThru; INFO ("reparation /fa : " + $p2.ExitCode) }
            if (Test-Path $Paths.SesamIni) { OK "sesam.ini present apres MSI" } else { WARN "sesam.ini toujours absent : utiliser 7a" }
            Set-MgcApresMsi
        }
    }

    $Script:GalssBad = (Has "GALSS_MISSING") -or (Has "GALSS_VITALE_CL") -or (Has "GALSS_MISMATCH") -or ((Has "GALSS_ABSENT_READER") -and (Has "GALSS_MISMATCH_CPS")) -or (Has "DMP_TIMEOUT_GALSS") -or (Has "GALSS_ABSENT_READER")
    if ($Script:GalssBad) {
        H2 "7b. Realigner galss.ini sur le lecteur reel"
        $af = Join-Path $PSScriptRoot "galss-autofix.ps1"
        if ((Test-Path $af) -and (Confirm-Step "Realigner galss.ini (CANAL1 CPS / CANAL2 Vitale) sur le lecteur branche (sauvegarde .bak) ?" -Safe)) {
            # GERBAL 25/09 : lance en pipe, le script restait bloque (le processus relance heritait de la sortie).
            # -> processus separe, attente du script seul, resultat lu dans son journal ; pas de relance de JuxtaLink ici (7e).
            $afLog = Join-Path $env:ProgramData "MadeForMed\galss-autofix.log"; $before = @(Get-Content $afLog -ErrorAction SilentlyContinue).Count
            $afArgs = @("-NoProfile","-ExecutionPolicy","Bypass","-WindowStyle","Hidden","-File","`"$af`"","-NoRelaunch"); if ($Script:CpsReader) { $afArgs += @("-CpsReader","`"$($Script:CpsReader)`"") }; if ($Script:VitReader) { $afArgs += @("-VitReader","`"$($Script:VitReader)`"") }
            $pa = Start-Process powershell.exe -ArgumentList $afArgs -PassThru
            if (-not $pa.WaitForExit(60000)) { try { $pa.Kill() } catch {}; WARN "galss-autofix : delai depasse (60 s), arrete" }
            @(Get-Content $afLog -ErrorAction SilentlyContinue) | Select-Object -Skip $before | ForEach-Object { INFO ("  " + $_) }
        } else {
        $target = $Script:VitReader
        if (-not $target -and (Has "GALSS_VITALE_CL")) { $target = ($Script:Readers | Where-Object { $_ -match 'Contact' -and $_ -notmatch '\bCL\b' } | Select-Object -First 1) }
        $vc = $Script:Canals | Where-Object { $_.LADs -contains "Vitale" } | Select-Object -First 1
        if ($vc -and $target) {
            INFO ("'" + $vc.Reader + "'  ->  '" + $target + "'")
            if (Confirm-Step "Modifier C:\Windows\galss.ini (sauvegarde .bak) ?" -Safe) {
                Copy-Item $Paths.GalssIni ($Paths.GalssIni + ".bak-" + $Stamp) -Force
                $g = Get-Content $Paths.GalssIni -Raw
                $other = $Script:Canals | Where-Object { $_.Reader -eq $target -and $_.Name -ne $vc.Name } | Select-Object -First 1
                if ($other) { $g = $g -replace [regex]::Escape("Caracteristiques=" + $target), "Caracteristiques=__TMP__" }
                $g = $g -replace [regex]::Escape("Caracteristiques=" + $vc.Reader), ("Caracteristiques=" + $target)
                if ($other) { $g = $g -replace "Caracteristiques=__TMP__", ("Caracteristiques=" + $vc.Reader) }
                [IO.File]::WriteAllText($Paths.GalssIni, $g, [Text.Encoding]::GetEncoding(1252))
                (Get-Content $Paths.GalssIni | Select-String 'CANAL\d\]|Caracteristiques|NomLAD') | ForEach-Object { INFO $_.Line.Trim() }
                OK "galss.ini modifie"
            }
        } else { WARN "Impossible de determiner le lecteur cible (Vitale non identifiee par certutil)" }
        }
    }

    if ($Script:Scenario -eq "MICA" -or ((Has "NO_MICA_X86") -and $Script:MicaX64Product)) {
        if ($Script:MicaX64Product) {
            H2 "7c. Desinstaller MICA x64 fantome"; INFO ("Source : " + $Script:MicaX64Product.InstallSource)
            if ($Script:MicaX64Product.InstallSource -notmatch 'CEGEDIM|JFSE') { WARN "Source non jFSE : verifier qu'aucun logiciel 64 bits n'en depend." }
            # RarSFX = installeur auto-extractible (ex-Cegedim) : meme cas que DRSAMITIER / DR-CARRE / DRPARDON
            $safeMica = ($Script:MicaX64Product.InstallSource -match 'CEGEDIM|JFSE|RarSFX')
            # DRPARDON 25/09 : apres retrait du MICA x64, le "Module lecteur de cartes" Cegedim affiche "librairie MICA
            # n'est pas installee". Regle : MICA x64 retire SEULEMENT si le medecin n'utilise plus Cegedim, et les restes
            # Cegedim sont alors neutralises dans la foulee (Neutraliser-Cegedim.ps1 -Auto).
            $cegPresent = (Test-Path "C:\CEGEDIM") -or (Test-Path "C:\Program Files (x86)\CEGEDIM") -or [bool]($Script:Findings | Where-Object Code -like "PROC_*")
            $okCeg = (-not $cegPresent) -or $SansCegedim
            if ($cegPresent -and -not $SansCegedim) {
                if ($Script:Decision.ContainsKey("Cegedim") -and -not $Script:Decision["Cegedim"]) { KO "Conflit : Cegedim (encore utilise) a besoin du MICA x64, Juxta du MICA x86 (meme identifiant). MICA x64 conserve : la Vitale ne pourra PAS etre lue dans Odaiji. A remonter a Juxta."; Finding "MICA_KEPT" "KO" "MICA x64 conserve (Cegedim)" }
                elseif ($Auto) { KO "MICA x64 CONSERVE (Cegedim declare encore utilise) : la Vitale ne pourra PAS etre lue dans Odaiji. Si Cegedim n'est plus utilise : Reparer-interactif.bat et repondre n."; Finding "MICA_KEPT" "KO" "MICA x64 conserve (Cegedim)" }
                elseif (-not (Confirm-Step "Le medecin facture-t-il ENCORE avec un logiciel Cegedim ? (n = MICA x64 retire + Cegedim neutralise, recommande si Odaiji remplace Cegedim)")) { $okCeg = $true; $SansCegedim = $true }
                else { KO "Conflit : Cegedim a besoin du MICA x64, Juxta du MICA x86 (meme identifiant, installation impossible des deux). A remonter a Juxta." }
            }
            $safeMica = $safeMica -and $okCeg
            if ($okCeg) {
            if (Confirm-Step "Desinstaller ce MICA x64 ? (taper o puis Entree ; Entree seul = non)" -Safe:$safeMica) { $p = Start-Process msiexec.exe -ArgumentList "/x `"$($Script:MicaX64Product.PSChildName)`" /qn /norestart REBOOT=ReallySuppress" -Wait -PassThru; INFO ("msiexec : " + $p.ExitCode); $still = Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq $Script:MicaX64Product.PSChildName -and $_.DisplayName -match 'x64' }
                if (-not $still) { $Script:MicaRemoved = $true; OK "MICA x64 retire : le plugin peut maintenant installer MICA x86" }
                else { KO ("MICA x64 toujours inscrit (msiexec " + $p.ExitCode + "). Commande manuelle : msiexec /x `"" + $Script:MicaX64Product.PSChildName + "`" /qn /norestart") } }
            if ($Script:MicaRemoved -and $cegPresent) {
                $nc = Join-Path $PSScriptRoot "Neutraliser-Cegedim.ps1"
                if (Test-Path $nc) { INFO "Neutralisation des restes Cegedim (evite le message 'librairie MICA n'est pas installee')"; & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $nc -Auto 2>&1 | ForEach-Object { INFO ("  " + $_) } }
            }
            }
        }
        H2 "7d. Reinstaller le plugin SSV"
        # Apres retrait du MICA x64 (DRPARDON 24/09), la reinstallation du plugin est l'etape suivante logique : sure en auto
        if (Confirm-Step "Arreter JuxtaLink, vider le cache Plugins et le relancer ? (taper o)" -Safe:([bool]$Script:MicaRemoved)) {
            Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2
            if (Test-Path $Paths.PlugDir) { Rename-Item $Paths.PlugDir ("Plugins_old-" + $Stamp) -Force }
            Start-Jx
            W "  >>> Dans Odaiji, lancer une lecture Vitale maintenant (accepter l'UAC)." "Magenta"; if (-not $Auto) { Read-Host "Entree une fois la lecture tentee" } else { Start-Sleep 20 }
            Start-Sleep 5
            $micaNow = Get-ChildItem $Paths.SanteX86 -Recurse -Include mica.dll -ErrorAction SilentlyContinue
            if ($micaNow) { OK ("mica.dll x86 present : " + $micaNow[0].FullName) } else { KO "mica.dll x86 toujours absent : verifier Internet / UAC, puis relancer" }
            $chk = Get-Content $Paths.JuxtaLog -Tail 200 -ErrorAction SilentlyContinue | Select-String 'MICA|1638|Vitale pr.sente' | Select-Object -Last 5
            foreach ($c in $chk) { INFO $c.Line.Trim() }
            if (($chk | Out-String) -match 'Vitale pr.sente : True') { OK "LECTURE VITALE REUSSIE" } else { WARN "Refaire une lecture Vitale puis 3-Diag-seul.bat" }
        }
    }

    # 7a-ter. [MGC] dans les autres sesam.ini meme quand C:\Windows\sesam.ini est correct (POSTE1 30/09 : la FSV lisait
    # C:\ProgramData\santesocial\fsv\<version>\conf\sesam.ini sans section [MGC] -> "Section MGC absente..." a la 1re lecture).
    # Avant, la section n'etait posee que lors de la regeneration de C:\Windows\sesam.ini (7a).
    if ($Script:MgcOthers.Count -and -not $Script:SesamBad) {
        H2 "7a-ter. Section [MGC] des autres sesam.ini"
        if (Confirm-Step "Poser la section [MGC] dans les autres sesam.ini lus par la FSV (sauvegarde .bak) ?" -Safe) {
            $v = $FsvVersion; $pd = "C:\ProgramData\santesocial\fsv\$v"
            foreach ($o in @($Script:MgcOthers)) {
                try {
                    $ov = if ($o -match 'fsv\\(\d+\.\d+\.\d+)') { $Matches[1] } else { $v }
                    $odir = "C:\ProgramData\santesocial\fsv\$ov\conf"; New-Item -ItemType Directory -Force $odir | Out-Null
                    if (-not (Test-Path (Join-Path $odir "log4crc.xml")) -and (Test-Path "$pd\conf\log4crc.xml")) { Copy-Item "$pd\conf\log4crc.xml" (Join-Path $odir "log4crc.xml") -Force }
                    Copy-Item $o ($o + ".bak-" + $Stamp) -Force
                    $keep = @(); $sec = ""
                    foreach ($ln in (Get-Content $o)) { if ($ln -match '^\s*\[(.+?)\]') { $sec = $Matches[1].Trim().ToUpper() }; if ($sec -ne "MGC") { $keep += $ln } }
                    $keep += @("", "[MGC]", ("RepertoireConfigTrace=" + $odir))
                    [IO.File]::WriteAllText($o, (($keep -join "`r`n") + "`r`n"), [Text.Encoding]::GetEncoding(1252))
                    OK ("[MGC] posee dans " + $o + " -> " + $odir)
                } catch { WARN ("[MGC] non posee dans " + $o + " : " + $_.Exception.Message) }
            }
            Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2; Start-Jx; OK "JuxtaLink relance (la FSV relit sesam.ini au chargement). Refaire une lecture dans Odaiji."
        }
    }

    # 7a-quinquies. [SSV] RepertoireTable absent des autres sesam.ini (PC26-FILLATRE 05/10)
    if ((Has "SESAM_SSV_TABLE") -and $Script:SsvOthers.Count) {
        H2 "7a-quinquies. Chemin des tables SSV dans les autres sesam.ini"
        if (Confirm-Step "Poser [SSV] RepertoireTable (et [SRT]/[STS] s'ils manquent) dans les sesam.ini lus par la FSV (sauvegarde .bak) ?" -Safe) {
            $v = $FsvVersion
            $tSsv = if ($Script:TableDir["ssv"]) { [Environment]::ExpandEnvironmentVariables($Script:TableDir["ssv"]) } else { "C:\Program Files (x86)\santesocial\fsv\$v\ssv" }
            $tSrt = if ($Script:TableDir["srt"]) { [Environment]::ExpandEnvironmentVariables($Script:TableDir["srt"]) } else { "C:\Program Files (x86)\santesocial\fsv\$v\srt" }
            $tSts = if ($Script:TableDir["sts"]) { [Environment]::ExpandEnvironmentVariables($Script:TableDir["sts"]) } else { "C:\Program Files (x86)\santesocial\fsv\$v\sts" }
            foreach ($o in @($Script:SsvOthers)) {
                try {
                    Copy-Item $o ($o + ".bak-" + $Stamp) -Force
                    Set-SesamKey $o "SSV" "RepertoireTable" $tSsv
                    Set-SesamKey $o "COMMUN" "RepertoireTable" $tSsv
                    $hasSec = @(Get-Content $o | Where-Object { $_ -match '^\s*\[(SRT|STS)\]' }).Count
                    if ($hasSec -lt 2) { Set-SesamKey $o "SRT" "RepertoireTable" $tSrt; Set-SesamKey $o "STS" "RepertoireTable" $tSts }
                    OK ("[SSV] RepertoireTable pose dans " + $o + " -> " + $tSsv)
                } catch { WARN ("Non pose dans " + $o + " : " + $_.Exception.Message) }
            }
            Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2; Start-Jx; OK "JuxtaLink relance (la FSV relit sesam.ini au chargement). Refaire une lecture dans Odaiji."
        }
    }

    # 7a-sexies. Tables x86 incompletes : on copie depuis le x64 les SEULS fichiers manquants (aucun ecrasement). POSTE2 05/10 : le x86 avait les .pem
    # mais pas tablebin.ssv / scripts.ssv (que le MSI x64 avait poses cote x64) -> erreur "fichier contenant les tables SSV, identifie par 0, inaccessible".
    # POSTE1 06/10 : le MSI FSV (7t) vient de poser les tables en x64 PENDANT ce passage : l'etat est donc recalcule ICI, pas lu dans le diag initial.
    if ($Fix) {
        $Script:TblMissing = Get-TablesIncompletes -Root86 $Paths.SanteX86 -Root64 $Paths.SanteX64 -Version $FsvVersion
        if ($Script:TblMissing.Count) {
            H2 "7a-sexies. Completer les tables FSV 32 bits avec les fichiers manquants du 64 bits"
            foreach ($t in @($Script:TblMissing.Keys)) { INFO ("  " + $t + " : " + (@($Script:TblMissing[$t]).Count) + " fichier(s) absents en x86 (" + ((@($Script:TblMissing[$t]) | Select-Object -First 6) -join ", ") + ")") }
            if (Confirm-Step "Copier dans les tables x86 les fichiers qui n'existent qu'en x64 (aucun fichier existant n'est ecrase) ?" -Safe) {
                $nCop = 0
                foreach ($t in @($Script:TblMissing.Keys)) {
                    $c86 = Join-Path $Paths.SanteX86 ("fsv\" + $FsvVersion + "\" + $t); $c64 = Join-Path $Paths.SanteX64 ("fsv\" + $FsvVersion + "\" + $t)
                    foreach ($rel in @($Script:TblMissing[$t])) {
                        try { $dst = Join-Path $c86 $rel; if (Test-Path $dst) { continue }; New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null; Copy-Item (Join-Path $c64 $rel) $dst -ErrorAction Stop; $nCop++; INFO ("  copie : " + $t + "\" + $rel) } catch { WARN ("Non copie : " + $rel + " : " + $_.Exception.Message) }
                    }
                }
                $reste = Get-TablesIncompletes -Root86 $Paths.SanteX86 -Root64 $Paths.SanteX64 -Version $FsvVersion
                if ($reste.Count) { KO ($nCop + " fichier(s) copies mais tables x86 encore incompletes : " + (($reste.Keys) -join ", ")) } else { OK ($nCop + " fichier(s) copies : tables x86 completes") }
                Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2; Start-Jx; OK "JuxtaLink relance. Refaire une lecture dans Odaiji."
            }
        }
    }

    # 7a-septies. Erreur 'tables SSV' persistante alors que le sesam.ini lu par le plugin (ProgramData\...\conf) semble correct :
    # on lui donne exactement le contenu du C:\Windows\sesam.ini genere par le kit (qui a [COMMUN] + [SSV] + [MGC] + [SRT] + [STS]) - PC26-FILLATRE 05/10
    if ($Fix -and (Has "SSV_TABLES_PERSIST") -and (Test-Path $Paths.SesamIni)) {
        H2 "7a-septies. Aligner le sesam.ini de la FSV sur celui de Windows"
        if (Confirm-Step "Remplacer le sesam.ini lu par la FSV (ProgramData\santesocial\fsv\...\conf) par une copie du sesam.ini Windows verifie (sauvegarde .bak) ?" -Safe) {
            $ref = @(Get-Content $Paths.SesamIni -ErrorAction SilentlyContinue)
            $stRef = Get-SesamIniState -Lines $ref -Exists { param($p) Test-Path $p }
            if ($ref -match '^\s*\[COMMUN\]' -and $stRef.SsvOk) {
                foreach ($o in @(@($others) | Where-Object { $_ -like 'C:\ProgramData\santesocial\*' })) {
                    try {
                        Copy-Item $o ($o + ".bak-" + $Stamp) -Force
                        [IO.File]::WriteAllText($o, (($ref -join "`r`n") + "`r`n"), [Text.Encoding]::GetEncoding(1252))
                        OK ($o + " : remplace par le contenu de " + $Paths.SesamIni)
                    } catch { WARN ("Non remplace : " + $o + " : " + $_.Exception.Message) }
                }
                Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2; Start-Jx; OK "JuxtaLink relance. Refaire une lecture CPS dans Odaiji."
            } else { WARN "C:\Windows\sesam.ini n'est pas un modele fiable (pas de [COMMUN] ou tables introuvables) : rien remplace" }
        }
    }

    # 7a-quater. Dossier srt x86 absent (tables srt vides) : on le cree vide, comme sur les autres postes (NB-DELL-01 30/09)
    if ($Fix -and (Has "SRT_DIR_ABSENT")) {
        H2 "7a-quater. Dossier des tables srt (x86)"
        foreach ($f in @($Script:Findings | Where-Object Code -eq "SRT_DIR_ABSENT")) {
            try { New-Item -ItemType Directory -Force $f.Msg | Out-Null; OK ("Dossier cree (vide, normal) : " + $f.Msg) } catch { WARN ("Dossier non cree : " + $f.Msg + " : " + $_.Exception.Message) }
        }
    }

    if ($Script:GalssBad -or $Script:SesamBad -or $Script:Scenario -in @("GALSS","SESAM")) {
        H2 "7e. Relancer JuxtaLink"
        if (Confirm-Step "Relancer JuxtaLink pour recharger la configuration ?" -Safe) { Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2; Start-Jx; OK "JuxtaLink relance. Tester CPS + Vitale dans Odaiji." }
    }
}

    # 7d-bis. DMP Connect relance apres realignement de galss.ini (DRSAMITIER 28/09)
    if ($Fix -and ((Has "DMP_TIMEOUT_GALSS") -or (Has "DMP_PCSC_ERR"))) {
        H2 "7d-bis. Redemarrer le service DMP Connect / iCanopee"
        if (Confirm-Step "Redemarrer le service DMP Connect (recharge galss.ini et la liste des lecteurs) ?" -Safe) { Get-Service *dmpconnect* -ErrorAction SilentlyContinue | Restart-Service -Force -ErrorAction SilentlyContinue; Start-Sleep 5; Get-Service *dmpconnect* -ErrorAction SilentlyContinue | ForEach-Object { INFO ("  " + $_.Name + " : " + $_.Status) }; INFO "Se reauthentifier au DMP dans Odaiji (CPS)." }
    }
    # 7v. CertPropSvc (lenteur CPS) - pas en automatique : a valider par un humain
    if ($Fix -and (Has "CERTPROP_AUTO")) {
        H2 "7v. CertPropSvc (lecture des certificats a chaque insertion de CPS)"
        if (Confirm-Step "Passer CertPropSvc en demarrage Manuel (reversible, accelere la lecture CPS) ?") { Set-Service CertPropSvc -StartupType Manual; Stop-Service CertPropSvc -Force -ErrorAction SilentlyContinue; OK "CertPropSvc : Manuel (retour arriere : Set-Service CertPropSvc -StartupType Automatic)" }
    }

if ($Fix -and $SansGalss) {
    H1 "7g. PASSAGE EN FULL PC/SC (desinstallation du GALSS x86 Juxta)"
    $blockers = @()
    if (-not $Script:Readers.Count) { $blockers += "aucun lecteur PC/SC vu par Windows (lecteur serie/PSS ?)" }
    if ($Script:CryptoGalss) { $blockers += "Cryptolib CPS x86 en filiere GALSS" }
    if ($blockers.Count) { KO ("Prerequis non remplis, on ne retire pas GALSS : " + ($blockers -join " ; ")) }
    else {
        OK ("Prerequis OK : lecteur(s) PC/SC = " + ($Script:Readers -join " | ") + " ; Cryptolib sans indication GALSS")
        if ($Script:GalssX86.Count) {
            # 01/10 (DRLECLERE) : la desinstallation du GALSS x86 a fait disparaitre C:\Windows\galss.ini (utilise par DMP Connect / iCanopee) : sauvegarde puis restauration
            $gBak = $null; if (Test-Path $Paths.GalssIni) { $gBak = Join-Path $env:TEMP "galss.ini.avant-7g"; Copy-Item $Paths.GalssIni $gBak -Force }
            foreach ($g in $Script:GalssX86) {
                if (Confirm-Step ("Desinstaller " + $g.DisplayName + " " + $g.DisplayVersion + " (x86 Juxta) ?") -Safe) {
                    if ($g.PSChildName -match '^\{[0-9A-F-]+\}$') { $p = Start-Process msiexec.exe -ArgumentList "/x `"$($g.PSChildName)`" /qn /norestart REBOOT=ReallySuppress" -Wait -PassThru; INFO ("msiexec : " + $p.ExitCode) }
                    elseif ($g.UninstallString) { INFO ("Desinstalleur : " + $g.UninstallString); cmd /c ($g.UninstallString + " /S") }
                }
            }
            if ($gBak -and (Test-Path $gBak) -and -not (Test-Path $Paths.GalssIni)) { Copy-Item $gBak $Paths.GalssIni -Force; OK "galss.ini restaure (la desinstallation GALSS x86 l'avait supprime ; DMP Connect / iCanopee en depend)" }
            $left = Get-ChildItem "C:\Windows\SysWOW64\gal*w32*","C:\Windows\gal*w32*","C:\Windows\SysWOW64\pssinw32.dll","C:\Windows\SysWOW64\pcscw32.dll" -ErrorAction SilentlyContinue
            if ($left) { INFO ("Residus 32 bits : " + (($left | ForEach-Object Name) -join ", ")); if (Confirm-Step "Supprimer ces fichiers GALSS 32 bits residuels (galss.ini conserve pour DMP Connect / iCanopee) ?" -Safe) { $left | Remove-Item -Force -ErrorAction SilentlyContinue; OK "Residus supprimes" } }
        } else { OK "GALSS x86 deja absent" }
        $cfgs = Get-ChildItem (Join-Path $Paths.PlugDir "SSV") -Recurse -Filter SSV.dll.config -ErrorAction SilentlyContinue
        if ($cfgs) { foreach ($c in $cfgs) { $t = Get-Content $c.FullName -Raw; if ($t -match 'BLOQUERINSTALLEGALSS"\s+value="false"') { $t = $t -replace 'BLOQUERINSTALLEGALSS"\s+value="false"', 'BLOQUERINSTALLEGALSS" value="true"'; [IO.File]::WriteAllText($c.FullName, $t, [Text.Encoding]::UTF8); OK ("BLOQUERINSTALLEGALSS=true dans " + $c.FullName) } else { INFO ("Deja bloque : " + $c.FullName) } } }
        else { WARN "Plugin SSV pas encore installe : relancer avec -SansGalss apres la premiere lecture (le plugin reinstallera GALSS entre-temps)" }
        if (Confirm-Step "Relancer JuxtaLink ?" -Safe) { Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2; Start-Jx }
        W "  >>> Tester CPS + Vitale + une ADRi dans Odaiji, puis relancer le diag : section PERFORMANCE et 'GALSS x86 absent' attendus." "Magenta"
    }
}

if ($Fix -and $Nettoyage) {
    H1 "7h. NETTOYAGE DES RESIDUS (ex-Cegedim / jFSE / Crossway)"
    $all = Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object DisplayName
    # --- FSV anciennes (autres que la version utilisee)
    $oldFsv = $all | Where-Object { $_.DisplayName -match '^fsv' -and $_.DisplayName -notmatch [regex]::Escape($FsvVersion.Replace('.','')) -and $_.DisplayName -notmatch [regex]::Escape($FsvVersion) }
    $oldFsv = $oldFsv | Where-Object { $_.DisplayName -match '1\.40\.1[0-3]' -or $_.DisplayName -match '1408' }
    foreach ($f in $oldFsv) { if (Confirm-Step ("Desinstaller " + $f.DisplayName + " (ancienne FSV, source " + $f.InstallSource + ") ?")) { INFO ("  lancement msiexec /x " + $f.DisplayName); $p = Start-Process msiexec.exe -ArgumentList "/x `"$($f.PSChildName)`" /qn /norestart REBOOT=ReallySuppress" -Wait -PassThru; INFO ("  msiexec : " + $p.ExitCode) } }
    # --- Cryptolib : garder la plus recente par architecture
    $cryptos = $all | Where-Object { $_.DisplayName -match 'Cryptographiques CPS' } | ForEach-Object { $_ | Add-Member -NotePropertyName Arch -NotePropertyValue $(if ($_.DisplayName -match 'x64') { "x64" } else { "x86" }) -PassThru | Add-Member -NotePropertyName Ver -NotePropertyValue ([version]($_.DisplayVersion -replace '[^\d\.]','')) -PassThru }
    $keep = @(); foreach ($arch in "x86","x64") { $k = $cryptos | Where-Object Arch -eq $arch | Sort-Object Ver -Descending | Select-Object -First 1; if ($k) { $keep += $k; INFO ("Cryptolib conservee (" + $arch + ") : " + $k.DisplayName) } }
    # 30/09 (DESKTOP-RNFKE1A) : jamais toucher une Cryptolib livree avec les outils du GIE (ProgramData\santesocial : cps, atsam = Diagnostic
    # Assurance Maladie) ni celle de DMP Connect / iCanopee ; msiexec avec delai max (un /fa sans source pouvait rester bloque)
    $Proteges = 'ProgramData\\santesocial|atsam|DmpConnect'
    function Invoke-MsiDelai { param([string]$Arguments, [int]$Sec = 180) $pp = Start-Process msiexec.exe -ArgumentList $Arguments -PassThru; if ($pp.WaitForExit($Sec * 1000)) { return [int]$pp.ExitCode } else { WARN ("  msiexec toujours en cours apres " + $Sec + " s : abandonne (verifier a la main)"); return -1 } }
    $drop = @($cryptos | Where-Object { $keep.PSChildName -notcontains $_.PSChildName })
    $gardees = @($drop | Where-Object { [string]$_.InstallSource -match $Proteges })
    if ($gardees) { INFO ("Cryptolib conservees (outils GIE / DMP Connect) : " + (($gardees | ForEach-Object { $_.DisplayName + " " + $_.DisplayVersion }) -join " | ")) }
    $drop = @($drop | Where-Object { [string]$_.InstallSource -notmatch $Proteges })
    if ($drop) {
        INFO ("Cryptolib en doublon : " + (($drop | ForEach-Object DisplayName) -join " | "))
        if (Confirm-Step ("Desinstaller ces " + @($drop).Count + " anciennes Cryptolib, puis reparer celles conservees ?")) {
            foreach ($d in ($drop | Sort-Object Ver)) { INFO ("  lancement msiexec /x " + $d.DisplayName); $code = Invoke-MsiDelai ("/x `"$($d.PSChildName)`" /qn /norestart REBOOT=ReallySuppress"); INFO ("  " + $d.DisplayName + " : msiexec " + $code + $(if ($code -eq 1605) { " (deja absent du registre Windows Installer, rien retire)" } else { "" })) }
            foreach ($k in $keep) { if ([string]$k.InstallSource -match 'DmpConnect') { INFO ("  reparation ignoree (Cryptolib de DMP Connect / iCanopee) : " + $k.DisplayName); continue }; $code = Invoke-MsiDelai ("/fa `"$($k.PSChildName)`" /qn /norestart REBOOT=ReallySuppress"); INFO ("  reparation " + $k.DisplayName + " : msiexec " + $code) }
        }
    } else { OK "Pas de Cryptolib en doublon a retirer" }
    # --- Produits Cegedim / Crossway / jFSE encore inscrits
    # Incident DRSAMITIER 24/09 : redemarrage force + TeamViewer disparu pendant le nettoyage.
    # Jamais d'outil de prise en main a distance ; jamais de desinstalleur non-MSI en silencieux (peut redemarrer).
    $Remote = 'teamviewer|anydesk|quick ?support|quickassist|assistance|splashtop|rustdesk|supremo|ammyy|vnc|logmein|bomgar|beyondtrust|remote|dameware|netviewer'
    $ceg = $all | Where-Object { ($_.Publisher -match 'cegedim|resip|clm' -or $_.DisplayName -match 'crossway|jfse|cegedim|clm ') -and $_.DisplayName -notmatch 'Cryptographiques' -and ($_.DisplayName + ' ' + $_.Publisher + ' ' + $_.InstallLocation + ' ' + $_.UninstallString) -notmatch $Remote }
    # 2e redemarrage force (24/09) au moment de cette etape : les desinstalleurs Cegedim (meme MSI) peuvent redemarrer
    # via leurs propres actions. On ne desinstalle plus rien ici : liste seulement, a traiter a la main hors consultation.
    if ($ceg) {
        WARN "Produits Cegedim / jFSE encore inscrits (NON desinstalles automatiquement : risque de redemarrage) :"
        foreach ($c in $ceg) { WARN ("  - " + $c.DisplayName + " " + $c.DisplayVersion + " (" + $c.Publisher + ")") }
        INFO "  -> si le medecin n'utilise plus Cegedim : Parametres > Applications, un par un, en fin de journee."
    } else { OK "Aucun produit Cegedim / jFSE inscrit" }
    # --- Dossiers residuels
    foreach ($d in "C:\CEGEDIM","C:\Program Files (x86)\CEGEDIM","C:\AVI","C:\Program Files (x86)\santesocial\diagAM") {
        if (Test-Path $d) {
            $busy = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like ($d + "\*") }
            $rem = Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $Remote } | Select-Object -First 1
            if ($rem) { WARN ($d + " : contient un outil de prise en main a distance (" + $rem.Name + "), non supprime") }
            elseif ($busy) { WARN ($d + " : processus actifs (" + (($busy | ForEach-Object ProcessName) -join ",") + "), non supprime") }
            elseif (Confirm-Step ("Supprimer le dossier residuel " + $d + " ?")) { Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue; OK ("supprime : " + $d) }
        }
    }
    # --- Entrees Run Cegedim
    foreach ($h in "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run","HKLM:\Software\Microsoft\Windows\CurrentVersion\Run","HKCU:\Software\Microsoft\Windows\CurrentVersion\Run") {
        $rp = Get-ItemProperty $h -ErrorAction SilentlyContinue; if (-not $rp) { continue }
        foreach ($prop in $rp.PSObject.Properties | Where-Object { $_.Name -match 'CLM\w*Synchro|Synchro\w*CLM|\bCLM\b|jfse|Cegedim' -and ($_.Name + ' ' + $_.Value) -notmatch $Remote -and ($_.Name + ' ' + $_.Value) -notmatch 'Adobe|Acrobat|Microsoft' }) { if (Confirm-Step ("Retirer l'entree de demarrage " + $prop.Name + " (" + $prop.Value + ") ?")) { Remove-ItemProperty $h -Name $prop.Name -ErrorAction SilentlyContinue; OK ("retiree : " + $prop.Name) } }
    }
    W "  >>> Refaire une lecture CPS + Vitale dans Odaiji, puis 3-Diag-seul.bat." "Magenta"
    W "  Antivirus : en garder UN seul (decision du cabinet), via Parametres > Applications." "Yellow"
}

H1 "FIN"
W ("Rapport : " + $Report) "Cyan"
# 05/10 : envoi automatique a MadeForMed, SANS question. 1.0.0 : systematique (Avant / Apres / diag seul).
# (un [KO] qui reste ou un scenario inconnu). Jamais bloquant ; echec silencieux -> repli : transfert de fichiers TeamViewer.
$statutEnvoi = $null
try {
    $ko = @($Script:Findings | Where-Object { $_.Level -eq "KO" })
    $raison = if ($ko.Count) { "KO " + ((($ko | Select-Object -First 4 | ForEach-Object Code)) -join ",") } elseif ($Script:Scenario -eq "UNKNOWN" -and $Script:Findings.Count) { "scenario inconnu" } else { "systematique " + $Script:Scenario }
    # 1.1.0 : TOUS les rapports partent (Avant / Apres / Fix / Galss / Nettoyage / diag seul) via Odaiji-Commun.ps1 (cle, file d'attente si pas de reseau)
    if ($raison) { $statutEnvoi = Send-OjRapport -Fichier $Report -Raison $raison }
} catch { $statutEnvoi = @{ statut = "refuse"; err = ([string]$_.Exception.Message) -replace "[\r\n]+", " " } }
if ($statutEnvoi) { try { W (Format-OjStatut $statutEnvoi "Rapport") "Cyan" } catch { W "Envoi automatique impossible : recuperer ce fichier par le transfert de fichiers TeamViewer et l'envoyer a l'equipe." "Cyan" } }
if (-not $NoPause) { Read-Host "`nEntree pour fermer" }
