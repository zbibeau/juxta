<#
=====================================================================
 Neutraliser-Ancien-Logiciel - MadeForMed / Odaiji - v1.0 (30/09/2026)
=====================================================================
 Outil de l'EQUIPE (pas du medecin). Neutralise, a la demande, un ancien logiciel metier du catalogue
 editeurs.psd1 (Cegedim, Affid, Shaman, Weda, Pyxvital, DrSante, HelloDoc...) sur ce poste.
   1. liste les logiciels du catalogue et ce qui est detecte sur le poste
   2. choix du logiciel, puis du mode :
        N = neutralisation seule (coupe demarrage, services, taches, processus ; rien n'est desinstalle) - recommande
        D = neutralisation + desinstallation (produits MSI ; dossiers en quarantaine C:\_Odaiji_a_supprimer)
            jamais propose pour les logiciels medicaux du catalogue (dossiers patients possibles) ni sur un poste qui heberge la base
   3. le moteur (Neutraliser-Cegedim.ps1, le meme que celui de l'installeur) montre ce qui sera coupe et demande confirmation
 Restauration : R = remet en route un logiciel neutralise (journal) ; S = remet en route les elements Windows / Adobe
 coupes a tort par les kits 0.3.29 a 0.3.31 (motif " synchro " trop large).
 Jamais touche : prise en main a distance, JuxtaLink, DMP Connect / iCanopee, amelipro, briques GIE, bases de donnees,
 elements Windows / Microsoft / Adobe.
 -Nom X      : va directement au choix du mode pour le logiciel X du catalogue
 -Simulation : n'execute rien, affiche seulement la commande qui serait lancee
 Rapport : Neutralisation_<poste>_<date>.txt sur le Bureau (a coller dans le channel Claude).
=====================================================================
#>
param([string]$Nom = "", [switch]$Simulation)
trap { Write-Host ("`nERREUR : " + $_.Exception.Message) -ForegroundColor Red; try { Stop-Transcript | Out-Null } catch {}; Read-Host "Envoyer cette capture dans le channel Claude. Entree pour fermer"; exit 1 }
$isAdmin = try { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } catch { $false }
if (-not $isAdmin -and -not $Simulation) {
    $a = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); if ($Nom) { $a += @("-Nom","`"$Nom`"") }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $a; exit
}

$Eng = Join-Path $PSScriptRoot "Neutraliser-Cegedim.ps1"
$CatF = Join-Path $PSScriptRoot "editeurs.psd1"
if (-not (Test-Path $Eng) -or -not (Test-Path $CatF)) { Write-Host "Neutraliser-Cegedim.ps1 ou editeurs.psd1 introuvable : lancer depuis le dossier EXTRAIT du kit." -ForegroundColor Red; Read-Host "Entree pour fermer"; exit 1 }
$Cat = @((Import-PowerShellDataFile $CatF).Editeurs)
$JDir = "C:\ProgramData\MadeForMed\CegedimNeutralise"

$Desktop = [Environment]::GetFolderPath("Desktop"); if (-not $Desktop) { $Desktop = [IO.Path]::GetTempPath() }
$Rapport = Join-Path $Desktop ("Neutralisation_{0}_{1}.txt" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd-HHmm"))
try { Start-Transcript -Path $Rapport -Force | Out-Null } catch {}

function Say { param($t, $c = "Gray") Write-Host $t -ForegroundColor $c }
function Ask { param([string]$q) try { $Host.UI.RawUI.FlushInputBuffer() } catch {}; return (Read-Host $q).Trim() }

# --- Detection : memes signaux que le diag (dossier, processus actif, produit inscrit) + base de donnees de l'editeur
function Detecter {
    $Hives = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")
    $prods = @(Get-ItemProperty $Hives -ErrorAction SilentlyContinue | Where-Object DisplayName)
    $procs = @(Get-Process -ErrorAction SilentlyContinue)
    $svcs  = @(Get-CimInstance Win32_Service -ErrorAction SilentlyContinue)
    $res = @{}
    foreach ($e in $Cat) {
        $why = @()
        foreach ($d in @($e.Dossiers)) { if ($d -and (Get-Item $d -ErrorAction SilentlyContinue)) { $why += "dossier"; break } }
        if ($procs | Where-Object { ($_.ProcessName + ' ' + $(try { $_.Path } catch { '' })) -match $e.Motif -and $_.ProcessName -notmatch '^JuxtaLink' }) { $why += "processus actif" }
        if ($prods | Where-Object { ($_.DisplayName + ' ' + $_.Publisher) -match $e.Motif -and $_.DisplayName -notmatch 'Cryptographiques|fsv|mica|galss' }) { $why += "produit inscrit" }
        $srv = [bool]($svcs | Where-Object { ($_.Name -match '^Oracle' -or $_.PathName -match 'oracle|TNSLSNR') -and ($_.PathName + ' ' + $_.Name) -match $e.Motif })
        $res[$e.Nom] = [pscustomobject]@{ Why = $why; Serveur = $srv }
    }
    return $res
}

# --- Appel du moteur (dans la meme session : sortie dans le rapport, questions [o/n] posees normalement)
function Lancer-Moteur { param([hashtable]$p)
    if ($Simulation) { Say ("SIMULATION : Neutraliser-Cegedim.ps1 " + (($p.GetEnumerator() | Sort-Object Name | ForEach-Object { if ($_.Value -is [bool]) { "-" + $_.Name } else { "-" + $_.Name + " '" + $_.Value + "'" } }) -join " ")) "Magenta"; return }
    & $Eng @p
}
function Entree-Catalogue { param([string]$n) return ($Cat | Where-Object { $_.Nom -ieq $n } | Select-Object -First 1) }

function Neutraliser-Logiciel { param($e, $etat)
    $srv = [bool]$etat.Serveur
    Say ("`n>> " + $e.Nom + " : " + $e.Libelle) "Cyan"
    if ($etat.Why) { Say ("   Detecte : " + ($etat.Why -join ", ")) } else { Say "   Rien de detecte sur ce poste (les residus ne sont pas toujours visibles : le moteur le dira)." "Yellow" }
    if ($e.Bloquants) { Say ("   Bloquants connus : " + $e.Bloquants) "DarkGray" }
    if ($srv) { Say "   Ce poste heberge la BASE DE DONNEES de cet editeur (service Oracle) : jamais desinstallee ni deplacee ; seuls les programmes lies au lecteur sont coupes." "Yellow" }
    $peutDes = (-not $e.NeutraliserSeulement) -and (-not $srv)
    Say "   N = neutraliser seulement : coupe demarrage, services, taches, processus ; rien n'est desinstalle (recommande)"
    if ($peutDes) { Say "   D = neutraliser + desinstaller les produits MSI, dossiers en quarantaine (C:\_Odaiji_a_supprimer)" }
    elseif ($e.NeutraliserSeulement) { Say "   (desinstallation non proposee : logiciel medical, dossiers patients possibles)" "DarkGray" }
    Say "   A = annuler"
    $choixMode = if ($peutDes) { "[N/D/A]" } else { "[N/A]" }
    do { $m = Ask ("   Mode ? " + $choixMode) } while ($m -notmatch '^[nNdDaA]$' -or ($m -match '^[dD]$' -and -not $peutDes))
    if ($m -match '^[aA]$') { Say "Annule, rien n'a ete modifie."; return }
    $p = @{ Nom = [string]$e.Nom; Motif = [string]$e.Motif }
    if ($m -match '^[dD]$') {
        $p.Desinstaller = $true
        $dj = (@($e.Dossiers) | Where-Object { $_ }) -join "|"; if ($dj) { $p.Dossiers = $dj }
        if ($e.DesinstallerNonMsi) { $p.NonMsi = $true }
    }
    Lancer-Moteur $p
}

function Liste-Journaux {
    return @(Get-ChildItem $JDir -Filter "journal*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^journal-restaure' } | ForEach-Object {
        [pscustomobject]@{ Nom = $(if ($_.Name -eq "journal.json") { "Cegedim" } else { $_.BaseName -replace '^journal-','' }); Fichier = $_.Name; Date = $_.LastWriteTime.ToString("dd/MM/yyyy HH:mm") } })
}

function Restaurer-Logiciel {
    $j = Liste-Journaux
    if (-not $j) { Say "Aucun journal de neutralisation sur ce poste : rien a restaurer." "Yellow"; return }
    Say "`nLogiciels neutralises sur ce poste (journaux) :" "Cyan"
    $i = 0; foreach ($x in $j) { $i++; Say ("  {0}. {1,-14} neutralise le {2}" -f $i, $x.Nom, $x.Date) }
    $c = Ask "Numero a remettre en route (Entree = annuler)"
    if ($c -notmatch '^\d+$' -or [int]$c -lt 1 -or [int]$c -gt $j.Count) { Say "Annule."; return }
    $x = $j[[int]$c - 1]; $e = Entree-Catalogue $x.Nom
    $p = @{ Restaurer = $true; Nom = [string]$x.Nom }; if ($e) { $p.Motif = [string]$e.Motif }
    Lancer-Moteur $p
}

function Restaurer-FauxPositifs {
    $j = Liste-Journaux
    if (-not $j) { Say "Aucun journal de neutralisation sur ce poste : rien a restaurer." "Yellow"; return }
    Say "`nRemet en route les elements coupes a tort (Windows / Microsoft / Adobe, ou que le motif corrige ne cible plus)." "Cyan"
    Say "Les elements de l'ancien logiciel restent neutralises. Seuls les journaux dont le logiciel est au catalogue sont traites." "DarkGray"
    foreach ($x in $j) {
        $e = Entree-Catalogue $x.Nom
        if (-not $e) { Say ("  Journal " + $x.Nom + " : logiciel absent du catalogue, ignore (a traiter a la main).") "Yellow"; continue }
        Say ("`n  Journal " + $x.Nom) "Cyan"
        Lancer-Moteur @{ Restaurer = $true; Systeme = $true; Nom = [string]$e.Nom; Motif = [string]$e.Motif }
    }
}

# --- Menu
$Sortie = $false
while (-not $Sortie) {
    $Etat = Detecter
    Say ("`n======================================================================") "Cyan"
    Say ("  Neutraliser un ancien logiciel - poste " + $env:COMPUTERNAME + $(if ($Simulation) { "   [SIMULATION : rien n'est execute]" } else { "" })) "Cyan"
    Say ("======================================================================") "Cyan"
    $i = 0
    foreach ($e in $Cat) {
        $i++; $s = $Etat[$e.Nom]
        $tag = if ($s.Why) { "DETECTE (" + ($s.Why -join ", ") + ")" } else { "absent" }
        $col = if ($s.Why) { "Yellow" } else { "DarkGray" }
        Say ("  {0}. {1,-10} {2}" -f $i, $e.Nom, $tag) $col
        Say ("       " + $e.Libelle + $(if ($e.NeutraliserSeulement) { "  [neutralisation seule]" } else { "" }) + $(if ($s.Serveur) { "  [BASE DE DONNEES sur ce poste]" } else { "" })) "DarkGray"
    }
    Say "  R. Remettre en route un logiciel neutralise"
    Say "  S. Remettre en route les elements Windows / Adobe coupes a tort (kits 0.3.29 a 0.3.31)"
    Say "  Q. Quitter"
    if ($Nom) { $ch = ($Cat | ForEach-Object { $_.Nom } | Where-Object { $_ -ieq $Nom } | Select-Object -First 1); if (-not $ch) { Say ("Logiciel '" + $Nom + "' absent du catalogue.") "Red"; $Nom = ""; continue }; $c = ([array]::IndexOf(@($Cat | ForEach-Object { $_.Nom }), $ch) + 1).ToString(); $Nom = ""; $Sortie = $true }
    else { $c = Ask "`nChoix" }
    if ($c -match '^[qQ]?$') { $Sortie = $true; continue }
    elseif ($c -match '^[rR]$') { Restaurer-Logiciel }
    elseif ($c -match '^[sS]$') { Restaurer-FauxPositifs }
    elseif ($c -match '^\d+$' -and [int]$c -ge 1 -and [int]$c -le $Cat.Count) { $e = $Cat[[int]$c - 1]; Neutraliser-Logiciel $e $Etat[$e.Nom] }
    else { Say "Choix non reconnu." "Yellow" }
}
Say ("`nTermine. Ensuite : lecture CPS + Vitale + ADRi dans Odaiji, puis 3-Diag-seul.bat (section PERFORMANCE).") "Cyan"
Say ("Rapport : " + $Rapport) "Cyan"
try { Stop-Transcript | Out-Null } catch {}
Read-Host "Copier le rapport dans le channel Claude. Entree pour fermer"
