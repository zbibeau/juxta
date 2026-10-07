# Fenetre du kit PC : logique (Odaiji-Ecran-Lib.ps1) et protocole de questions (Odaiji-Ecran-Hote.ps1). L'affichage WinForms ne se teste pas sous Linux.
param([string]$Kit)
. (Join-Path $Kit "Odaiji-Ecran-Lib.ps1")
$fail = 0
function Check { param($ok, $msg) if ($ok) { Write-Host ("  ok   " + $msg) } else { Write-Host ("  ECHEC " + $msg) -ForegroundColor Red; $script:fail++ } }

Check ((Get-LineKind '    [OK]  JuxtaLink installe (2.2.3)').Kind -eq 'ok') "ligne [OK]"
Check ((Get-LineKind '  [KO]   galss.ini VIDE').Text -eq 'galss.ini VIDE') "ligne [KO] : texte sans le marqueur"
Check ((Get-LineKind '  [WARN] diagAM installe').Kind -eq 'warn') "ligne [WARN]"
Check ((Get-LineKind '==> 3/6  user.config (serveurs MadeForMed)').Kind -eq 'step') "ligne d'etape"
Check ((Get-LineKind '@@ASK|Entree pour fermer').Kind -eq 'ask') "ligne de question"
Check ((Get-LineKind 'du texte quelconque').Kind -eq 'info') "ligne neutre"

Check ((Get-StepTitle '1/6  Diagnostic AVANT (lecture seule)') -eq 'Analyse du poste') "titre : diag avant"
Check ((Get-StepTitle '3/6  user.config (serveurs MadeForMed)') -eq 'Configuration MadeForMed') "titre : user.config"
Check ((Get-StepTitle "4/6  Corrections automatiques sures (sesam.ini, galss.ini, MICA x64 jFSE) - une fenetre s'ouvre, la laisser finir") -eq 'Corrections automatiques') "titre : corrections (pas de fuite du detail)"
Check ((Get-StepTitle '6/6  Diagnostic APRES') -eq ([regex]::Unescape('Contrôle final'))) "titre : controle final accentue"
Check ((Get-StepTitle '7/7  Une etape que le kit ne connait pas encore (detail)') -eq 'Une etape que le kit ne connait pas encore') "titre : etape inconnue = texte nettoye"
$dmp = Get-StepTitle '5d/6  galss.ini ABSENT : reparation du lecteur pour DMP Connect / iCanopee'
Check ($dmp -notmatch 'DMP|iCanopee') "titre : aucune mention DMP Connect / iCanopee dans la fenetre"
$dmp2 = Get-StepTitle '4a/7  Reparation du lecteur pour DMP Connect / iCanopee (CPS + Vitale inserees dans le lecteur)'
Check ($dmp2 -notmatch 'DMP|iCanopee') "titre : idem (depannage)"

$a = Get-AskInfo '    Le medecin facture-t-il ENCORE avec MediMust ? [o/n]'
Check ($a.Type -eq 'yesno' -and $a.Text -match 'facture-t-il encore avec MediMust' -and $a.Text -match [regex]::Unescape('médecin')) "question o/n : texte nettoye et accentue"
Check ($a.No -match 'ne plus' -and $a.Yes -match 'encore') "question 'encore' : boutons explicites"
$b = Get-AskInfo "    Lancer le menage des Cryptolib en doublon ? [o/n]"
Check ($b.Type -eq 'yesno' -and $b.Yes -eq 'Oui' -and $b.No -eq 'Non') "autre question o/n : Oui / Non"
$c = Get-AskInfo 'Entree pour fermer'
Check ($c.Type -eq 'close') "Entree pour fermer = fin"
$d = Get-AskInfo 'Envoyer cette capture dans le channel Claude. Entree pour fermer'
Check ($d.Type -eq 'error') "erreur du script detectee"
$ctx = @('######', '#  JUXTALINK REDEMARRE : installation automatique en cours de  #', '#     FSV  -  GALSS  -  MICA  -  Cryptolib   #', '########')
$w = Get-AskInfo "    Entree quand l'installation est terminee et la situation de facturation enregistree (ou tout de suite pour passer)" $ctx
Check ($w.Type -eq 'wait' -and $w.Body -match 'RED.MARRE' -and $w.Body -notmatch '#') "attente : bandeau du script repris sans les #"

$ok = Get-EndSummary @('[OK] x', 'Scenario : GALSS', '      Corriges : GALSS_EMPTY, GARDIEN_ABSENT', '      Restent  : DIAGAM', 'Journal transmis automatiquement a MadeForMed.')
Check ($ok.Ok -and $ok.Corriges -eq 'GALSS_EMPTY, GARDIEN_ABSENT' -and $ok.Restent -eq 'DIAGAM' -and $ok.Transmis -and $ok.Scenario -eq 'GALSS') "resume : tout va bien + corriges / restent"
$ko = Get-EndSummary @('  [KO]   user.config sans les serveurs MadeForMed', '  [WARN] diagAM installe')
Check ((-not $ko.Ok) -and $ko.Ko.Count -eq 1 -and $ko.Warn.Count -eq 1) "resume : un KO = point a traiter"

# Protocole : un faux script pilote (charge Odaiji-Ecran-Hote.ps1 comme Install / Depannage) lance comme la fenetre le fait (stdin / stdout redirigees)
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("ecran-" + [guid]::NewGuid().ToString("N")); New-Item -ItemType Directory -Path $tmp | Out-Null
@'
param()
if ($env:ODAIJI_GUI) { . (Join-Path $env:ECRAN_KIT 'Odaiji-Ecran-Hote.ps1') }
Write-Host "`n==> 1/2  Diagnostic AVANT"
Write-Host "    [OK]  rapport"
$r = (Read-Host "    Le medecin facture-t-il ENCORE avec Truc ? [o/n]").Trim()
Write-Host ("    reponse recue : " + $r)
Read-Host "    Entree une fois la lecture faite"
Write-Host "==> 2/2  Diagnostic APRES"
Write-Host "  [KO]   un point"
Read-Host "`nEntree pour fermer"
'@ | Set-Content (Join-Path $tmp "fake.ps1")
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = (Get-Process -Id $PID).Path; $psi.Arguments = '-NoProfile -File "' + (Join-Path $tmp "fake.ps1") + '"'
$psi.UseShellExecute = $false; $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.CreateNoWindow = $true
$psi.EnvironmentVariables['ODAIJI_GUI'] = '1'; $psi.EnvironmentVariables['ECRAN_KIT'] = $Kit
$p = [Diagnostics.Process]::Start($psi); $p.StandardInput.AutoFlush = $true
$lines = @(); $asks = 0; $t0 = Get-Date
while ($true) {
    $task = $p.StandardOutput.ReadLineAsync()
    if (-not $task.Wait(15000)) { break }
    $l = $task.Result; if ($null -eq $l) { break }
    $lines += $l
    if ($l -like '@@ASK|*') { $asks++; $p.StandardInput.WriteLine($(if ($asks -eq 1) { 'n' } else { '' })) }
}
[void]$p.WaitForExit(5000)
Check ($asks -eq 3) "protocole : les 3 questions du faux script arrivent comme @@ASK (recu : $asks)"
Check (($lines -join "`n") -match 'reponse recue : n') "protocole : la reponse renvoyee par la fenetre revient dans le script"
Check (($lines | Where-Object { $_ -match '^\s*==>' }).Count -eq 2) "protocole : les etapes passent par la sortie standard"
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
if ($fail) { exit 1 }
