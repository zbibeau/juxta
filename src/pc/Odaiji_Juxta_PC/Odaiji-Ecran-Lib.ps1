# Odaiji-Ecran-Lib.ps1 - logique pure de la fenetre (testee sur Linux : tests/ecran-cases.ps1). Aucun controle graphique ici.
# Fichier ASCII : les accents des textes affiches sont ecrits \uXXXX et decodes par T.
function T { param([string]$s) [regex]::Unescape($s) }

# [motif de l'etape du script ; titre affiche]
$Script:TitreMap = @(
    @('Diagnostic AVANT', 'Analyse du poste'),
    @('Anciens logiciels', 'Anciens logiciels m\u00e9tiers'),
    @('Installation de JuxtaLink', 'Installation de JuxtaLink'),
    @('Installation sautee', 'Installation de JuxtaLink (d\u00e9j\u00e0 faite)'),
    @('user\.config', 'Configuration MadeForMed'),
    @('Demarrage de JuxtaLink sans', 'D\u00e9marrage automatique de JuxtaLink'),
    @('Corrections apres', 'Contr\u00f4le des composants'),
    @('Corrections automatiques', 'Corrections automatiques'),
    @('Chrome / Edge', 'Navigateurs (Chrome, Edge)'),
    @('Lancement de JuxtaLink', 'Lancement de JuxtaLink'),
    @('Full PC/SC', 'Lecture des cartes (PC/SC direct)'),
    @('Redemarrage', 'Red\u00e9marrage de JuxtaLink'),
    @('galss\.ini', 'R\u00e9glage du lecteur de cartes'),
    @('Reparation du lecteur', 'R\u00e9paration du lecteur de cartes'),
    @('Lecture de la carte CPS', 'Lecture de la carte CPS'),
    @('Menage', 'Nettoyage des Cryptolib en double'),
    @('Diagnostic APRES', 'Contr\u00f4le final')
)
$Script:Accents = @(
    @('medecin', 'm\u00e9decin'), @('Entree', 'Entr\u00e9e'), @('ENCORE', 'encore'), @('menage', 'm\u00e9nage'), @('Menage', 'M\u00e9nage'),
    @('redemarre', 'red\u00e9marre'), @('REDEMARRE', 'RED\u00c9MARRE'), @('terminee', 'termin\u00e9e'), @('enregistree', 'enregistr\u00e9e'),
    @('testee', 'test\u00e9e'), @('APRES', 'apr\u00e8s'), @('neutralise', 'neutralis\u00e9'), @('facturation', 'facturation')
)
function Fix-Accents {
    param([string]$s)
    foreach ($p in $Script:Accents) { $s = $s -creplace ('\b' + $p[0] + '\b'), (T $p[1]) }
    return $s
}
function Get-StepTitle {
    param([string]$Raw)
    $t = ($Raw -replace '^\s*\d+[a-z]?/\d+\s*', '').Trim()
    foreach ($m in $Script:TitreMap) { if ($t -match $m[0]) { return (T $m[1]) } }
    $t = ($t -split ' \(| - ')[0].Trim()
    return (Fix-Accents $t)
}
# Classe une ligne de sortie du script pilote : Kind = ask | step | ok | ko | warn | info
function Get-LineKind {
    param([string]$Line)
    if ($null -eq $Line) { $Line = '' }
    if ($Line -match '^@@ASK\|(.*)$') { return [pscustomobject]@{ Kind = 'ask'; Text = $Matches[1] } }
    if ($Line -match '^\s*==>\s*(.+)$') { return [pscustomobject]@{ Kind = 'step'; Text = $Matches[1].Trim() } }
    if ($Line -match '^\s*\[OK\]\s*(.*)$') { return [pscustomobject]@{ Kind = 'ok'; Text = $Matches[1].Trim() } }
    if ($Line -match '^\s*\[KO\]\s*(.*)$') { return [pscustomobject]@{ Kind = 'ko'; Text = $Matches[1].Trim() } }
    if ($Line -match '^\s*\[WARN\]\s*(.*)$') { return [pscustomobject]@{ Kind = 'warn'; Text = $Matches[1].Trim() } }
    return [pscustomobject]@{ Kind = 'info'; Text = $Line.Trim() }
}
# Question du script -> ce que la fenetre affiche. Type : yesno | wait | close | error
function Get-AskInfo {
    param([string]$Prompt, [string[]]$Context = @())
    $p = $Prompt.Trim()
    if ($p -match 'Envoyer cette capture') { return [pscustomobject]@{ Type = 'error'; Text = ''; Body = ''; Yes = ''; No = '' } }
    if ($p -match 'fermer') { return [pscustomobject]@{ Type = 'close'; Text = ''; Body = ''; Yes = ''; No = '' } }
    if ($p -match '\[o/n\]') {
        $q = Fix-Accents (($p -replace '\[o/n\]', '' -replace '\(n = [^)]*\)', '').Trim())
        if ($p -match 'ENCORE') { return [pscustomobject]@{ Type = 'yesno'; Text = $q; Body = (T 'Si non, le kit le neutralise pour lib\u00e9rer le lecteur de cartes. Rien n''est supprim\u00e9.'); Yes = (T 'Oui, il est encore utilis\u00e9'); No = (T 'Non, ne plus l''utiliser') } }
        return [pscustomobject]@{ Type = 'yesno'; Text = $q; Body = ''; Yes = 'Oui'; No = 'Non' }
    }
    $lines = @()
    foreach ($c in $Context) { $x = ($c -replace '[#]', ' ').Trim(); if ($x -and $x -notmatch '^[-=\s]*$') { $lines += (Fix-Accents $x) } }
    if ($lines.Count -gt 8) { $lines = $lines[($lines.Count - 8)..($lines.Count - 1)] }
    $text = Fix-Accents (($p -replace '^Entree\s*', '').Trim())
    if (-not $text) { $text = 'Continuer' } else { $text = $text.Substring(0, 1).ToUpper() + $text.Substring(1) }
    return [pscustomobject]@{ Type = 'wait'; Text = $text; Body = ($lines -join "`n"); Yes = ''; No = '' }
}
# Lignes de la partie "controle final" (ou de tout le diag) -> verdict
function Get-EndSummary {
    param([string[]]$Lines)
    $ko = @(); $warn = @(); $corriges = ''; $restent = ''; $scenario = ''; $transmis = $false
    foreach ($l in $Lines) {
        $k = Get-LineKind $l
        switch ($k.Kind) { 'ko' { $ko += (Fix-Accents $k.Text) } 'warn' { $warn += (Fix-Accents $k.Text) } }
        if ($l -match 'Corriges\s*:\s*(.+)$') { $corriges = $Matches[1].Trim() }
        if ($l -match 'Restent\s*:\s*(.+)$') { $restent = $Matches[1].Trim() }
        if ($l -match 'Scenario\s*:\s*(\S.*)$') { $scenario = $Matches[1].Trim() }
        if ($l -match 'transmis automatiquement') { $transmis = $true }
    }
    return [pscustomobject]@{ Ok = ($ko.Count -eq 0); Ko = $ko; Warn = $warn; Corriges = $corriges; Restent = $restent; Scenario = $scenario; Transmis = $transmis }
}
