<#
=====================================================================
 galss-autofix (Windows) - Realigne galss.ini sur les fentes reelles
 MadeForMed / Odaiji - v1.2 (01/10/2026)
 v1.4 : certutil -scinfo limite a 45 s avec message (Reparer-lecteur fige et muet, PC-MED2-0220 02/10)
# v1.3 : galss.ini absent = recree en PC/SC (DRLECLERE 01/10)
# v1.2 : galss.ini d'un ancien logiciel (un seul canal serie CANAL1 9600,1,8,0,0, pas de CANAL2) = converti en PC/SC (2 canaux CPS / Vitale), sauvegarde .bak (POSTE1 01/10)
 v1.1 : lecteurs nommes "... Reader 0 / Reader 1" (Identive CLOUD 2700 R) : l'autre fente est retrouvee (un seul chiffre final)
=====================================================================
 Detecte via certutil dans quel lecteur PC/SC se trouvent la CPS et
 la Vitale, met a jour [CANAL1]/[CANAL2] Caracteristiques de
 C:\Windows\galss.ini si necessaire, et relance JuxtaLink.
 Ne modifie rien si la config est deja correcte.
 Le reste de galss.ini (protocoles, NomLib, LAD...) est conserve tel quel.
=====================================================================
#>
param([switch]$NoRelaunch, [string]$CpsReader = "", [string]$VitReader = "")
$Ini = "C:\Windows\galss.ini"
$Log = Join-Path $env:ProgramData "MadeForMed\galss-autofix.log"
New-Item -ItemType Directory -Force (Split-Path $Log) | Out-Null
function L { param($m) $t = (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " " + $m; Add-Content -Path $Log -Value $t -Encoding UTF8; if ($Host.Name -ne "ServerRemoteHost") { Write-Host $m } }

# --- 1. Lecteurs et cartes via certutil
# 02/10 (PC-MED2-0220, SUZANNE-PC-PORT) : Reparer-lecteur.bat restait fige et muet. Premiere action = certutil -scinfo, qui peut ne jamais rendre la main
# (carte tenue par un autre programme). On annonce l'etape (visible dans la fenetre et le journal) et on limite certutil a 45 s.
L "Analyse des lecteurs et des cartes (CPS + Vitale inserees) - 45 s maximum..."
$job = Start-Job -ScriptBlock { (& certutil -silent -scinfo 2>&1 | Out-String) }
if (Wait-Job $job -Timeout 45) { $scRaw = Receive-Job $job } else { $scRaw = $null; Get-Process certutil -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
Stop-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force -ErrorAction SilentlyContinue
if ($null -eq $scRaw) {
    L "ERREUR : la lecture des cartes (certutil -scinfo) ne repond pas : une carte est tenue par un autre programme. Retirer puis reinserer la CPS et la Vitale, fermer iCanopee, puis relancer. Si cela se reproduit : envoyer ce journal (C:\ProgramData\MadeForMed\galss-autofix.log)."
    exit 1
}
$sc = $scRaw -replace '[\u00A0\u00E1\u00FF]', ' '   # FR : espace insecable avant ':' (CLIENT022/POSTE1)
$cps = ""; $vit = ""; $cur = ""; $named = @(); $present = @()
foreach ($line in ($sc -split "`r?`n")) {
    if     ($line -match '^\s*---\s*Lecteur\W*:\s*(.+?)\s*$') { $cur = $Matches[1]; $named += $cur }
    elseif ($line -match 'SCARD_STATE_PRESENT')               { $present += $cur }
    elseif ($line -match 'Carte\W*:\s*.*CPS')                 { $cps = $cur }
    elseif ($line -match 'Carte\W*:\s*.*Vitale')              { $vit = $cur }
}
if ($CpsReader) { $cps = $CpsReader }; if ($VitReader) { $vit = $VitReader }
if (-not $cps -and -not $vit) { L "Aucune carte vue par Windows, rien a faire."; exit 0 }

# --- 2. Fente manquante : on prend l'autre fente du meme lecteur physique
function PickOther($known) {
    $base = $known -replace '\s+\d+(\s+\d+)?\s*$', ''
    # @() : avec un seul candidat, $cands etait une chaine et $cands[0] sa 1re lettre (Vitale='K', lecteur KAPELSE 28/09)
    $cands = @($named | Where-Object { $_ -ne $known -and $_ -like ($base + "*") } | Select-Object -Unique)
    if ($cands) { return $cands[0] } else { return "" }
}
if (-not $vit) { $vit = PickOther $cps }
# Deux lecteurs separes (poste 28/09 : CPS sur Identive, Vitale sur un lecteur Gemalto non identifiee par certutil) :
# le seul AUTRE lecteur ou une carte est presente est celui de la Vitale
if (-not $vit -and $cps) { $o = @($present | Where-Object { $_ -ne $cps } | Select-Object -Unique); if ($o.Count -eq 1) { $vit = $o[0]; L "Vitale non identifiee par certutil : lecteur '$vit' retenu (seul autre lecteur avec une carte)" } }
if (-not $cps) { $cps = PickOther $vit }
if (-not $cps -or -not $vit) { L "Impossible d'identifier les deux fentes (CPS='$cps' Vitale='$vit'). Inserer la CPS ET la Vitale dans le lecteur, puis relancer Reparer-lecteur.bat."; exit 0 }
# Garde-fou : n'ecrire que des noms de lecteurs reellement vus par Windows
if (($named -notcontains $cps) -or ($named -notcontains $vit)) { L "Noms de lecteurs inattendus (CPS='$cps' Vitale='$vit'), galss.ini non modifie."; exit 0 }

# --- 3. Lire galss.ini et localiser les sections
# 01/10 (DRLECLERE) : galss.ini ABSENT apres l'installation (supprime avec le GALSS x86 desinstalle) -> DMP Connect / iCanopee ne lit plus la CPS : on le recree en PC/SC.
$absent = -not (Test-Path $Ini)
if ($absent) {
    if (-not ((Test-Path "C:\Program Files (x86)\DmpConnect-JS2") -or (Test-Path "C:\Program Files\santesocial\galss"))) { L "galss.ini absent mais ni DMP Connect ni GALSS x64 installes : rien a creer."; exit 0 }
    L "galss.ini absent : creation d'un galss.ini PC/SC (DMP Connect / iCanopee en a besoin)."
    $lines = @()
} else { $lines = Get-Content $Ini }
$idx1 = -1; $idx2 = -1; $sec = ""
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*\[(.+?)\]') { $sec = $Matches[1].ToUpper() }
    elseif ($lines[$i] -match '^\s*Caracteristiques\s*=') {
        if ($sec -eq "CANAL1") { $idx1 = $i } elseif ($sec -eq "CANAL2") { $idx2 = $i }
    }
}
if ($idx1 -lt 0 -or $idx2 -lt 0) {
    # 01/10 (POSTE1, NB-DELL-01) : galss.ini d'un ancien logiciel = un seul canal serie (CANAL1 9600,1,8,0,0 portant CPS+Vitale+Log_SV), pas de CANAL2.
    # DMP Connect / iCanopee ne voit alors pas le lecteur PC/SC. On le convertit en PC/SC (2 canaux : CPS, Vitale) sur le modele Mac, en gardant
    # le [PROTOCOLE0] d'origine ; l'ancien fichier est sauvegarde (.bak). Odaiji / JuxtaLink n'en dependent pas (PC/SC direct).
    $serie = ($absent -or ($idx1 -ge 0 -and $idx2 -lt 0 -and ($lines[$idx1] -split '=', 2)[1].Trim() -match '^\d+,\d+,\d+'))
    if (-not $serie) { L "galss.ini NON modifie : structure inhabituelle (ni serie a canal unique, ni PC/SC a 2 canaux). Sans effet sur Odaiji ni JuxtaLink (PC/SC direct) ; seul DMP Connect / iCanopee en depend. Envoyer le contenu de C:\Windows\galss.ini a l'equipe si DMP Connect ne lit pas la CPS."; exit 0 }
    $p0 = @(); $in0 = $false
    foreach ($l in $lines) { if ($l -match '^\s*\[PROTOCOLE0\]') { $in0 = $true; $p0 += "[PROTOCOLE0]"; continue }; if ($in0) { if ($l -match '^\s*\[') { break }; if ($l.Trim()) { $p0 += $l.Trim() } } }
    if ($p0.Count -lt 2) { $p0 = @("[PROTOCOLE0]", "Config=1000,20,15000", "TempoInit=1,200,1000", "NomLib=PSSINW64.DLL") }
    $nv = @($p0) + @("[PROTOCOLE1]", "Config=0", "NomLib=PCSCW64.DLL", "ListeCanaux=1,2", "[CONFIG]", "NbCanaux=2",
        "[CANAL1]", "TCanal=3", "Index=1", "Protocole=1", ("Caracteristiques=" + $cps), "NbPAD=1", "[CANAL1.PAD1]", "PAD=0", "NbLAD=1", "[CANAL1.PAD1.LAD1]", "LAD=1", "NomLAD=CPS", "NbAlias=1", "NomAlias1=TRANSPA1",
        "[CANAL2]", "TCanal=3", "Index=2", "Protocole=1", ("Caracteristiques=" + $vit), "NbPAD=1", "[CANAL2.PAD1]", "PAD=0", "NbLAD=1", "[CANAL2.PAD1.LAD1]", "LAD=1", "NomLAD=Vitale", "NbAlias=1", "NomAlias1=TRANSPA2")
    Copy-Item $Ini ($Ini + ".bak-" + (Get-Date -Format "yyyyMMdd-HHmmss")) -Force -ErrorAction SilentlyContinue
    Set-Content -Path $Ini -Value $nv -Encoding Default
    L ("galss.ini " + $(if ($absent) { "cree en PC/SC (etait absent)" } else { "converti en PC/SC (ancien fichier : un seul canal serie)" }) + " : CPS='$cps', Vitale='$vit'. Sauvegarde : galss.ini.bak-*. Redemarrer le service DMP Connect puis tester une lecture CPS via iCanopee.")
    $exe0 = "C:\Program Files (x86)\Juxta\JuxtaLink\JuxtaLink.exe"
    if (-not $NoRelaunch -and (Get-Process JuxtaLink -ErrorAction SilentlyContinue)) {
        Get-Process JuxtaLink | Stop-Process -Force; Start-Sleep 2
        $vt = $false; try { if (Get-ScheduledTask -TaskPath "\Odaiji\" -TaskName "JuxtaLink" -ErrorAction Stop) { Start-ScheduledTask -TaskPath "\Odaiji\" -TaskName "JuxtaLink"; $vt = $true } } catch {}
        if (-not $vt -and (Test-Path $exe0)) { Start-Process explorer.exe -ArgumentList ("`"" + $exe0 + "`"") }
        L "JuxtaLink relance."
    }
    exit 0
}
$curCps = ($lines[$idx1] -split '=', 2)[1].Trim()
$curVit = ($lines[$idx2] -split '=', 2)[1].Trim()
$aligne = ($curCps -eq $cps -and $curVit -eq $vit)
$lines[$idx1] = "Caracteristiques=" + $cps
$lines[$idx2] = "Caracteristiques=" + $vit

# --- 3b. Canaux supplementaires (3, 4...) en fin de fichier sur un lecteur ABSENT : supprimes
# (DRSAMITIER 28/09 : CANAL3 sur l'ancien Ingenico -> timeouts GALSS, DMP Connect ne lisait plus la CPS)
$canaux = @{}; $sec = ""
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*\[CANAL(\d+)(\.[^\]]*)?\]') { $sec = [int]$Matches[1]; if (-not $canaux.ContainsKey($sec)) { $canaux[$sec] = @{ Debut = $i; Carac = "" } } }
    elseif ($lines[$i] -match '^\s*\[') { $sec = "" }
    elseif ($sec -ne "" -and $lines[$i] -match '^\s*Caracteristiques\s*=\s*(.*)$') { $canaux[$sec].Carac = $Matches[1].Trim() }
}
$retires = @()
$nums = @($canaux.Keys | Sort-Object -Descending)
foreach ($n in $nums) {
    if ($n -le 2) { break }
    $c = $canaux[$n].Carac
    if ($c -and $c -notmatch '^\d+,' -and ($named -notcontains $c)) { $retires += $n; $lines = $lines[0..($canaux[$n].Debut - 1)] } else { break }
}
if ($retires.Count) {
    $reste = @($canaux.Keys | Where-Object { $retires -notcontains $_ } | Sort-Object)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*ListeCanaux\s*=') { $lines[$i] = "ListeCanaux=" + ((($lines[$i] -split '=', 2)[1].Split(',') | Where-Object { $retires -notcontains [int]$_.Trim() }) -join ',') }
        elseif ($lines[$i] -match '^\s*NbCanaux\s*=') { $lines[$i] = "NbCanaux=" + $reste.Count }
    }
    while ($lines.Count -and -not $lines[-1].Trim()) { $lines = $lines[0..($lines.Count - 2)] }
}
if ($aligne -and -not $retires.Count) { L "OK : galss.ini deja aligne (CPS='$cps', Vitale='$vit')."; exit 0 }

# --- 4. Ecrire
Copy-Item $Ini ($Ini + ".bak-" + (Get-Date -Format "yyyyMMdd-HHmmss")) -Force -ErrorAction SilentlyContinue
Set-Content -Path $Ini -Value $lines -Encoding Default
L ("galss.ini reecrit : CPS='$cps' (etait '$curCps'), Vitale='$vit' (etait '$curVit')" + $(if ($retires.Count) { " ; canal(aux) sur lecteur absent supprime(s) : " + ($retires -join ",") } else { "" }) + ".")

# --- 5. Relancer JuxtaLink
$exe = "C:\Program Files (x86)\Juxta\JuxtaLink\JuxtaLink.exe"
if (-not $NoRelaunch -and (Get-Process JuxtaLink -ErrorAction SilentlyContinue)) {
    Get-Process JuxtaLink | Stop-Process -Force; Start-Sleep 2
    # 29/09 : via la tache \Odaiji\JuxtaLink si elle existe (sans fenetre UAC), sinon via explorer (session du medecin)
    $viaTache = $false; try { if (Get-ScheduledTask -TaskPath "\Odaiji\" -TaskName "JuxtaLink" -ErrorAction Stop) { Start-ScheduledTask -TaskPath "\Odaiji\" -TaskName "JuxtaLink"; $viaTache = $true } } catch {}
    if (-not $viaTache -and (Test-Path $exe)) { Start-Process explorer.exe -ArgumentList ("`"" + $exe + "`"") }
    L "JuxtaLink relance."
}
exit 0
