<#
 Odaiji_Juxta - fenetre (version "beaux ecrans" du kit PC), lancee par 0-Ecran-Odaiji.bat.
 Elle ne remplace pas les scripts : elle lance Install-OdaijiJuxta.ps1 / Depannage.ps1 / OdaijiJuxta.ps1 sans console, affiche leur avancement
 et transforme leurs questions (Read-Host) en boutons. Les .bat habituels restent disponibles en secours.
 Hors perimetre pour l'instant : tout ce qui concerne DMP Connect / iCanopee (reste en terminal).
#>
param([ValidateSet('', 'installer', 'depanner', 'diag')][string]$Mode = '')
$ErrorActionPreference = 'Stop'
$Kit = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $Kit 'Odaiji-Ecran-Lib.ps1')
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
function Msg { param($t, $icon = 'Information') [void][System.Windows.Forms.MessageBox]::Show($t, 'Odaiji Juxta', 'OK', $icon) }

if ($Kit -match '\\AppData\\Local\\Temp\\|\\Windows\\Temp\\|\.zip\\') {
    Msg (T "Le kit est lanc\u00e9 depuis le zip, sans l'avoir extrait.`n`nFermez cette fen\u00eatre, faites clic droit sur le zip > Extraire tout..., puis relancez depuis le dossier extrait.") 'Warning'
    exit 1
}
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try { Start-Process powershell.exe -Verb RunAs -WindowStyle Hidden -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', "`"$PSCommandPath`"") } catch { Msg (T "Les droits administrateur sont n\u00e9cessaires (fen\u00eatre UAC).") 'Warning' }
    exit
}

function C { param([string]$h) [System.Drawing.ColorTranslator]::FromHtml($h) }
$cInk = C '#12303a'; $cMute = C '#4a6168'; $cLine = C '#dbe4e2'; $cBand = C '#f7faf9'; $cTeal = C '#0f7b6c'; $cOk = C '#1b7f4b'; $cWarn = C '#b25e09'; $cKo = C '#b3261e'; $cSoft = C '#f1f8f6'
$fUi = 'Segoe UI'
function Font { param($sz, $bold = $false) New-Object System.Drawing.Font($fUi, [single]$sz, $(if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular })) }
function New-Lbl {
    param($text, $x, $y, $w, $h, $size = 10, $bold = $false, $color = $cInk)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object System.Drawing.Point($x, $y); $l.Size = New-Object System.Drawing.Size($w, $h)
    $l.Font = Font $size $bold; $l.ForeColor = $color; $l.BackColor = [System.Drawing.Color]::Transparent; $l.AutoSize = $false
    return $l
}
function New-Btn {
    param($text, $x, $y, $w, $h, $primary = $false)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text; $b.Location = New-Object System.Drawing.Point($x, $y); $b.Size = New-Object System.Drawing.Size($w, $h)
    $b.FlatStyle = 'Flat'; $b.Font = Font 10.5 $true; $b.Cursor = 'Hand'; $b.TabStop = $true
    if ($primary) { $b.BackColor = $cTeal; $b.ForeColor = [System.Drawing.Color]::White; $b.FlatAppearance.BorderSize = 0 }
    else { $b.BackColor = [System.Drawing.Color]::White; $b.ForeColor = $cInk; $b.FlatAppearance.BorderColor = C '#c5d0ce' }
    return $b
}
function New-Panel { $p = New-Object System.Windows.Forms.Panel; $p.Dock = 'Fill'; $p.BackColor = [System.Drawing.Color]::White; $p.Visible = $false; return $p }
function New-Footer { $f = New-Object System.Windows.Forms.Panel; $f.Dock = 'Bottom'; $f.Height = 76; $f.BackColor = $cBand; return $f }

$posteNom = $env:COMPUTERNAME
$os = try { (Get-CimInstance Win32_OperatingSystem).Caption -replace 'Microsoft ', '' } catch { 'Windows' }
$verKit = try { (Get-Content (Join-Path $Kit 'VERSION') -TotalCount 1) } catch { '' }
if (-not $verKit) { $m = Select-String -Path (Join-Path $Kit 'Depannage.ps1') -Pattern 'v(\d+\.\d+\.\d+)' -List -ErrorAction SilentlyContinue; if ($m) { $verKit = $m.Matches[0].Groups[1].Value } }
$juxtaPresent = $false
try {
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*') {
        if (Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*Juxta*' }) { $juxtaPresent = $true; break }
    }
} catch {}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Odaiji Juxta'; $form.ClientSize = New-Object System.Drawing.Size(780, 506); $form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'; $form.MaximizeBox = $false; $form.BackColor = [System.Drawing.Color]::White; $form.Font = Font 10

# ---------------- Ecran 1 : accueil
$pHome = New-Panel
$logo = New-Object System.Windows.Forms.Label; $logo.Text = 'M'; $logo.Font = Font 16 $true; $logo.ForeColor = [System.Drawing.Color]::White; $logo.BackColor = $cTeal
$logo.TextAlign = 'MiddleCenter'; $logo.Location = New-Object System.Drawing.Point(56, 28); $logo.Size = New-Object System.Drawing.Size(36, 36)
$pHome.Controls.Add($logo)
$pHome.Controls.Add((New-Lbl 'MadeForMed' 100 34 200 26 11 $true))
$pHome.Controls.Add((New-Lbl ("$posteNom  " + [char]0x00B7 + "  $os" + $(if ($verKit) { "  " + [char]0x00B7 + "  kit $verKit" } else { '' })) 380 38 344 22 9 $false $cMute))
$pHome.Controls[$pHome.Controls.Count - 1].TextAlign = 'MiddleRight'
$pHome.Controls.Add((New-Lbl (T 'Que voulez-vous faire sur ce poste ?') 56 84 668 40 19 $true))
$pHome.Controls.Add((New-Lbl (T "Gardez la carte CPS et la carte Vitale \u00e0 port\u00e9e de main.") 56 126 668 24 10.5 $false $cMute))
function New-Card {
    param($y, $titre, $desc, $mode, $hot, $badge)
    $p = New-Object System.Windows.Forms.Panel; $p.Location = New-Object System.Drawing.Point(56, $y); $p.Size = New-Object System.Drawing.Size(668, 78)
    $p.BorderStyle = 'FixedSingle'; $p.Cursor = 'Hand'; $p.BackColor = $(if ($hot) { $cSoft } else { [System.Drawing.Color]::White })
    $t = New-Lbl $titre 18 12 460 26 12.5 $true; $d = New-Lbl $desc 18 40 630 34 9.5 $false $cMute
    $p.Controls.Add($t); $p.Controls.Add($d)
    if ($badge) { $b = New-Lbl $badge 500 14 150 22 8.5 $true $cTeal; $b.TextAlign = 'MiddleRight'; $p.Controls.Add($b); $b.Cursor = 'Hand'; $b.Add_Click({ Start-Run $this.Parent.Tag }) }
    $p.Tag = $mode
    $p.Add_Click({ Start-Run $this.Tag }); $t.Add_Click({ Start-Run $this.Parent.Tag }); $d.Add_Click({ Start-Run $this.Parent.Tag })
    return $p
}
$pHome.Controls.Add((New-Card 172 (T 'D\u00e9panner ce poste') (T "\u00c7a ne lit plus, une erreur dans Odaiji, un doute. Diagnostic puis r\u00e9parations.") 'depanner' $juxtaPresent $(if ($juxtaPresent) { (T 'JuxtaLink d\u00e9tect\u00e9') } else { '' })))
$pHome.Controls.Add((New-Card 262 'Installer un nouveau poste' (T "JuxtaLink, composants SESAM-Vitale, lecteur, navigateurs. 10 \u00e0 15 minutes.") 'installer' (-not $juxtaPresent) ''))
$pHome.Controls.Add((New-Card 352 'Diagnostic seul' (T 'Regarder sans rien modifier. 1 \u00e0 2 minutes.') 'diag' $false ''))
$fh = New-Footer; $fh.Height = 52
$fh.Controls.Add((New-Lbl (T "Les rapports sont envoy\u00e9s automatiquement \u00e0 MadeForMed. Aucun fichier du m\u00e9decin n'est lu.") 56 14 668 24 9 $false $cMute))
$pHome.Controls.Add($fh)

# ---------------- Ecran 2 : avancement
$pRun = New-Panel
$lblRunT = New-Lbl '' 56 26 668 36 18 $true; $lblRunS = New-Lbl '' 56 64 668 24 10.5 $false $cMute
$bar = New-Object System.Windows.Forms.ProgressBar; $bar.Style = 'Marquee'; $bar.MarqueeAnimationSpeed = 30; $bar.Location = New-Object System.Drawing.Point(56, 98); $bar.Size = New-Object System.Drawing.Size(668, 8)
$steps = New-Object System.Windows.Forms.FlowLayoutPanel; $steps.Location = New-Object System.Drawing.Point(56, 120); $steps.Size = New-Object System.Drawing.Size(668, 300)
$steps.FlowDirection = 'TopDown'; $steps.WrapContents = $false; $steps.AutoScroll = $true
$txtLog = New-Object System.Windows.Forms.TextBox; $txtLog.Multiline = $true; $txtLog.ReadOnly = $true; $txtLog.ScrollBars = 'Vertical'; $txtLog.Font = New-Object System.Drawing.Font('Consolas', 9)
$txtLog.Location = $steps.Location; $txtLog.Size = $steps.Size; $txtLog.Visible = $false
$fr = New-Footer; $fr.Height = 64
$fr.Controls.Add((New-Lbl (T "Journal d\u00e9taill\u00e9 enregistr\u00e9 sur le poste et envoy\u00e9 \u00e0 la fin.") 56 20 420 24 9 $false $cMute))
$btnDetail = New-Btn (T 'Afficher le d\u00e9tail') 560 12 164 40; $fr.Controls.Add($btnDetail)
foreach ($c in $lblRunT, $lblRunS, $bar, $steps, $txtLog, $fr) { $pRun.Controls.Add($c) }

# ---------------- Ecran 3 : question / attente
$pAsk = New-Panel
$lblAskHead = New-Lbl '' 72 70 640 24 9.5 $true $cWarn
$lblAskQ = New-Lbl '' 72 104 640 90 19 $true
$lblAskBody = New-Lbl '' 72 200 640 130 11 $false $cMute
$btnYes = New-Btn '' 72 350 270 52 $true; $btnNo = New-Btn '' 356 350 270 52
foreach ($c in $lblAskHead, $lblAskQ, $lblAskBody, $btnYes, $btnNo) { $pAsk.Controls.Add($c) }

# ---------------- Ecran 5/6 : resultat
$pEnd = New-Panel
$ico = New-Object System.Windows.Forms.Label; $ico.Font = New-Object System.Drawing.Font('Segoe UI Symbol', 26, [System.Drawing.FontStyle]::Bold); $ico.ForeColor = [System.Drawing.Color]::White
$ico.TextAlign = 'MiddleCenter'; $ico.Location = New-Object System.Drawing.Point(72, 56); $ico.Size = New-Object System.Drawing.Size(64, 64)
$gp = New-Object System.Drawing.Drawing2D.GraphicsPath; $gp.AddEllipse(0, 0, 64, 64); $ico.Region = New-Object System.Drawing.Region($gp)
$lblEndT = New-Lbl '' 72 136 640 44 22 $true; $lblEndM = New-Lbl '' 72 184 640 56 11 $false $cMute
$lblEndD = New-Lbl '' 72 246 640 150 10.5 $false $cInk
$fe = New-Footer
$btnEndDetail = New-Btn (T 'Voir le d\u00e9tail') 72 16 160 44; $btnEndClose = New-Btn 'Terminer' 560 16 144 44 $true
$fe.Controls.Add($btnEndDetail); $fe.Controls.Add($btnEndClose)
foreach ($c in $ico, $lblEndT, $lblEndM, $lblEndD, $fe) { $pEnd.Controls.Add($c) }

foreach ($p in $pHome, $pRun, $pAsk, $pEnd) { $form.Controls.Add($p) }
function Show-Panel { param($p) foreach ($x in $pHome, $pRun, $pAsk, $pEnd) { $x.Visible = ($x -eq $p) } }

# ---------------- Pilotage du script
$Script:proc = $null; $Script:readTask = $null; $Script:mode = ''; $Script:log = New-Object System.Collections.Generic.List[string]
$Script:ctx = New-Object System.Collections.Generic.List[string]; $Script:afterApres = New-Object System.Collections.Generic.List[string]
$Script:stepRow = $null; $Script:stepN = 0; $Script:stepKo = $false; $Script:inApres = $false; $Script:sawError = $false; $Script:errLines = New-Object System.Collections.Generic.List[string]
$Script:ended = $false

function Add-StepRow {
    param($titre)
    $row = New-Object System.Windows.Forms.Panel; $row.Size = New-Object System.Drawing.Size(640, 38); $row.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 2)
    $i = New-Lbl ([string][char]0x25CF) 4 6 28 26 12 $false $cTeal; $i.Font = New-Object System.Drawing.Font('Segoe UI Symbol', 12); $i.TextAlign = 'MiddleCenter'
    $t = New-Lbl $titre 40 6 440 26 11 $true; $t.TextAlign = 'MiddleLeft'
    $s = New-Lbl (T 'en cours') 490 6 140 26 9.5 $true $cTeal; $s.TextAlign = 'MiddleRight'
    $row.Controls.Add($i); $row.Controls.Add($t); $row.Controls.Add($s)
    $steps.Controls.Add($row); $steps.ScrollControlIntoView($row)
    return $row
}
function Close-StepRow {
    if ($null -eq $Script:stepRow) { return }
    $i = $Script:stepRow.Controls[0]; $s = $Script:stepRow.Controls[2]
    if ($Script:stepKo) { $i.Text = '!'; $i.ForeColor = $cWarn; $i.Font = Font 12 $true; $s.Text = (T '\u00e0 v\u00e9rifier'); $s.ForeColor = $cWarn }
    else { $i.Text = [string][char]0x2713; $i.ForeColor = $cOk; $i.Font = New-Object System.Drawing.Font('Segoe UI Symbol', 12, [System.Drawing.FontStyle]::Bold); $s.Text = ''; }
    $Script:stepRow.Controls[1].Font = Font 11 $false
    $Script:stepRow = $null; $Script:stepKo = $false
}
function Send-Answer { param([string]$a) try { $Script:proc.StandardInput.WriteLine($a); $Script:proc.StandardInput.Flush() } catch {}; Show-Panel $pRun }

function Show-Ask {
    param($info)
    $lblAskBody.Text = ''; $btnNo.Visible = $true
    if ($info.Type -eq 'yesno') {
        $lblAskHead.Text = (T 'UNE R\u00c9PONSE EST N\u00c9CESSAIRE'); $lblAskQ.Text = $info.Text; $lblAskBody.Text = $info.Body
        $btnYes.Text = $info.No; $btnNo.Text = $info.Yes
        $Script:ansYes = 'n'; $Script:ansNo = 'o'
        if (-not $info.Body) { $btnYes.Text = $info.Yes; $btnNo.Text = $info.No; $Script:ansYes = 'o'; $Script:ansNo = 'n' }
    } else {
        $lblAskHead.Text = (T '\u00c0 VOUS DE JOUER'); $lblAskQ.Text = $info.Text; $lblAskBody.Text = $info.Body
        $btnYes.Text = 'Continuer'; $btnNo.Visible = $false; $Script:ansYes = ''; $Script:ansNo = ''
    }
    Show-Panel $pAsk
}
$btnYes.Add_Click({ Send-Answer $Script:ansYes }); $btnNo.Add_Click({ Send-Answer $Script:ansNo })

function Handle-Line {
    param([string]$line)
    $Script:log.Add($line); $txtLog.AppendText($line + "`r`n")
    $k = Get-LineKind $line
    if ($Script:inApres -or $Script:mode -eq 'diag') { $Script:afterApres.Add($line) }
    switch ($k.Kind) {
        'step' {
            Close-StepRow
            $Script:stepN++; $titre = Get-StepTitle $k.Text
            if ($k.Text -match 'APRES') { $Script:inApres = $true }
            $Script:stepRow = Add-StepRow $titre
            $lblRunS.Text = (T ("\u00c9tape " + $Script:stepN + " \u00b7 ne fermez pas cette fen\u00eatre."))
        }
        'ko' { $Script:stepKo = $true }
        'warn' { }
        'ask' {
            $info = Get-AskInfo $k.Text @($Script:ctx)
            switch ($info.Type) {
                'close' { try { $Script:proc.StandardInput.WriteLine(''); $Script:proc.StandardInput.Flush() } catch {} }
                'error' { $Script:sawError = $true; try { $Script:proc.StandardInput.WriteLine(''); $Script:proc.StandardInput.Flush() } catch {} }
                default { Show-Ask $info }
            }
            $Script:ctx.Clear()
        }
        'info' {
            if ($k.Text) { $Script:ctx.Add($k.Text); if ($Script:ctx.Count -gt 30) { $Script:ctx.RemoveAt(0) } }
            if ($k.Text -match '^(ERREUR|Le kit est lance)') { $Script:sawError = $true; $Script:errLines.Add($k.Text) }
        }
    }
}

function Show-End {
    if ($Script:ended) { return }; $Script:ended = $true
    $timer.Stop(); $bar.Style = 'Continuous'; $bar.Value = 100
    Close-StepRow
    $code = 0; try { [void]$Script:proc.WaitForExit(4000); $code = $Script:proc.ExitCode } catch {}
    $sum = Get-EndSummary @($Script:afterApres)
    $ico.BackColor = $cOk; $ico.Text = [string][char]0x2713
    if ($Script:sawError -or ($code -ne 0 -and -not $Script:afterApres.Count)) {
        $ico.BackColor = $cKo; $ico.Text = '!'
        $lblEndT.Text = (T "Le kit s'est arr\u00eat\u00e9 sur une erreur")
        $lblEndM.Text = (T "Rien n'est perdu : relancez le kit. Si cela se reproduit, ouvrez le d\u00e9tail et envoyez-le \u00e0 l'\u00e9quipe.")
        $lblEndD.Text = (($Script:errLines | Select-Object -First 3) -join "`n")
    } elseif ($Script:mode -eq 'diag') {
        $lblEndT.Text = (T 'Diagnostic termin\u00e9')
        $lblEndM.Text = $(if ($sum.Transmis) { (T 'Rapport transmis automatiquement \u00e0 MadeForMed.') } else { (T "Rapport enregistr\u00e9 sur le Bureau. Voir le d\u00e9tail pour l'envoi.") })
        $lblEndD.Text = (T ("" + $sum.Ko.Count + " point(s) bloquant(s), " + $sum.Warn.Count + " \u00e0 surveiller.")) + $(if ($sum.Ko.Count) { "`n`n" + (($sum.Ko | Select-Object -First 4) -join "`n") } else { '' })
        if ($sum.Ko.Count) { $ico.BackColor = $cWarn; $ico.Text = '!' }
    } elseif ($sum.Ok) {
        $lblEndT.Text = $(if ($Script:mode -eq 'installer') { (T 'Ce poste est pr\u00eat') } else { (T 'D\u00e9pannage termin\u00e9') })
        $lblEndM.Text = (T "Aucun probl\u00e8me bloquant apr\u00e8s les r\u00e9parations. ") + $(if ($sum.Transmis) { (T 'Rapport transmis \u00e0 MadeForMed.') } else { (T "Envoi du rapport : voir le d\u00e9tail.") })
        $lblEndD.Text = $(if ($sum.Corriges) { (T 'Corrig\u00e9 : ') + $sum.Corriges } else { '' }) + $(if ($sum.Restent) { "`n" + (T '\u00c0 surveiller : ') + $sum.Restent } else { '' })
    } else {
        $ico.BackColor = $cWarn; $ico.Text = '!'
        $lblEndT.Text = (T 'Un point reste \u00e0 traiter')
        $lblEndM.Text = (T "Le reste est en ordre. L'\u00e9quipe MadeForMed re\u00e7oit le rapport et peut agir \u00e0 distance.")
        $lblEndD.Text = (($sum.Ko | Select-Object -First 3) -join "`n")
    }
    Show-Panel $pEnd
}
function Tick {
    if ($null -eq $Script:proc) { return }
    try {
        if ($null -eq $Script:readTask) { $Script:readTask = $Script:proc.StandardOutput.ReadLineAsync() }
        $n = 0
        while ($Script:readTask -and $Script:readTask.IsCompleted -and $n -lt 80) {
            $line = $Script:readTask.Result
            if ($null -eq $line) { $Script:readTask = $null; Show-End; return }
            Handle-Line $line; $n++
            $Script:readTask = $Script:proc.StandardOutput.ReadLineAsync()
        }
    } catch { $Script:errLines.Add($_.Exception.Message); $Script:sawError = $true; Show-End }
}
$timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 120; $timer.Add_Tick({ Tick })

function Start-Run {
    param([string]$mode)
    if ($Script:proc) { return }
    $Script:mode = $mode; $Script:ended = $false; $Script:stepN = 0; $Script:inApres = $false; $Script:sawError = $false
    $Script:log.Clear(); $Script:ctx.Clear(); $Script:afterApres.Clear(); $Script:errLines.Clear(); $steps.Controls.Clear(); $txtLog.Clear()
    switch ($mode) {
        'installer' { $script = 'Install-OdaijiJuxta.ps1'; $extra = ''; $lblRunT.Text = 'Installation en cours' }
        'depanner' { $script = 'Depannage.ps1'; $extra = ''; $lblRunT.Text = (T 'D\u00e9pannage en cours') }
        default { $script = 'OdaijiJuxta.ps1'; $extra = ' -NoPause'; $lblRunT.Text = (T 'Analyse du poste') }
    }
    $lblRunS.Text = (T 'D\u00e9marrage... ne fermez pas cette fen\u00eatre.')
    if ($mode -eq 'diag') { $Script:stepRow = Add-StepRow (T 'Analyse du poste (1 \u00e0 2 minutes)'); $Script:stepN = 1 }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $Kit $script) + '"' + $extra
    $psi.WorkingDirectory = $Kit; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true
    $psi.EnvironmentVariables['ODAIJI_GUI'] = '1'
    $Script:proc = [System.Diagnostics.Process]::Start($psi)
    $Script:proc.StandardInput.AutoFlush = $true
    $Script:readTask = $null; $bar.Style = 'Marquee'
    Show-Panel $pRun; $timer.Start()
}
$btnDetail.Add_Click({ $txtLog.Visible = -not $txtLog.Visible; $steps.Visible = -not $txtLog.Visible; $btnDetail.Text = $(if ($txtLog.Visible) { (T 'Masquer le d\u00e9tail') } else { (T 'Afficher le d\u00e9tail') }) })
$btnEndDetail.Add_Click({
    $f = Join-Path $env:TEMP ('Odaiji_detail_' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
    [System.IO.File]::WriteAllLines($f, $Script:log.ToArray()); Start-Process notepad.exe -ArgumentList ('"' + $f + '"')
})
$btnEndClose.Add_Click({ $form.Close() })
$form.Add_FormClosing({
    param($s, $e)
    if ($Script:proc -and -not $Script:ended) {
        $r = [System.Windows.Forms.MessageBox]::Show((T "Une op\u00e9ration est en cours. L'arr\u00eater maintenant ?"), 'Odaiji Juxta', 'YesNo', 'Warning')
        if ($r -ne 'Yes') { $e.Cancel = $true; return }
        try { Start-Process taskkill.exe -ArgumentList @('/PID', $Script:proc.Id, '/T', '/F') -WindowStyle Hidden -Wait } catch {}
    }
})
Show-Panel $pHome
if ($Mode) { $form.Add_Shown({ Start-Run $Mode }) }
[void]$form.ShowDialog()
