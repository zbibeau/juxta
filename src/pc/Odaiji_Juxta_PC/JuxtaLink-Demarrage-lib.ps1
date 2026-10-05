<#
 JuxtaLink-Demarrage-lib.ps1 - fonctions partagees (tache planifiee JuxtaLink sans UAC)
 Charge par Demarrage-JuxtaLink.ps1, OdaijiJuxta.ps1 et Install-OdaijiJuxta.ps1 (dot-source, sans parametre).
 Explications : voir Demarrage-JuxtaLink.ps1.
#>

function Resolve-JxExe {
    # 28/09 : JuxtaLink pas toujours dans Program Files (x86) -> processus en cours, puis registre, puis emplacements connus
    # 29/09 : ne doit JAMAIS faire planter le diag (DisplayIcon vide -> Split-Path levait une erreur bloquante)
    $defaut = "C:\Program Files (x86)\Juxta\JuxtaLink\JuxtaLink.exe"
    try {
        $p = Get-Process JuxtaLink -ErrorAction SilentlyContinue | Where-Object { $_.Path } | Select-Object -First 1
        if ($p) { return $p.Path }
        foreach ($h in "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","Registry::HKEY_USERS\*\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") {
            foreach ($r in @(Get-ItemProperty $h -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '^JuxtaLink' })) {
                $dirs = @([string]$r.InstallLocation)
                $ico = ([string]$r.DisplayIcon -replace '"|,\d+$','').Trim()
                if ($ico) { try { $dirs += (Split-Path $ico -Parent) } catch {} }
                foreach ($d in $dirs) { if ($d -and (Test-Path (Join-Path $d "JuxtaLink.exe"))) { return (Join-Path $d "JuxtaLink.exe") } }
            }
        }
        $cands = @($defaut, "C:\Program Files\Juxta\JuxtaLink\JuxtaLink.exe")
        $cands += @(Get-ChildItem "C:\Users\*\AppData\Local\*Juxta*\*\JuxtaLink.exe","C:\Users\*\AppData\Local\Programs\*\JuxtaLink.exe","C:\Users\*\AppData\Local\*Juxta*\JuxtaLink.exe" -ErrorAction SilentlyContinue | ForEach-Object FullName)
        foreach ($c in $cands) { if ($c -and (Test-Path $c)) { return $c } }
    } catch {}
    return $defaut
}
$Script:JxExe      = Resolve-JxExe
$Script:JxTaskPath = "\Odaiji\"
$Script:JxTaskName = "JuxtaLink"
$Script:JxBackKey  = "HKLM:\SOFTWARE\MadeForMed\JuxtaLinkDemarrage"
$Script:JxBackDir  = "C:\ProgramData\MadeForMed\JuxtaLinkDemarrage"
$Script:JxPubDesk  = [Environment]::GetFolderPath("CommonDesktopDirectory"); if (-not $Script:JxPubDesk) { $Script:JxPubDesk = "C:\Users\Public\Desktop" }
$Script:JxLnk      = Join-Path $Script:JxPubDesk "JuxtaLink (Odaiji).lnk"

function Get-JxUser {
    # Utilisateur de la session ouverte (le medecin), meme si l'UAC a ete validee avec un autre compte
    $o = Get-CimInstance Win32_Process -Filter "name='explorer.exe'" -ErrorAction SilentlyContinue | Select-Object -First 1 | Invoke-CimMethod -MethodName GetOwner -ErrorAction SilentlyContinue
    if ($o -and $o.User) { $d = if ($o.Domain) { $o.Domain } else { $env:COMPUTERNAME }; return ($d + "\" + $o.User) }
    return ($env:USERDOMAIN + "\" + $env:USERNAME)
}

function Test-JxUserAdmin { param([string]$User)
    # $true / $false / $null (inconnu, ex. compte Azure AD admin via un groupe)
    try {
        $grp = (New-Object Security.Principal.SecurityIdentifier "S-1-5-32-544").Translate([Security.Principal.NTAccount]).Value.Split("\")[-1]
        $short = $User.Split("\")[-1]
        $lines = @(net localgroup "$grp" 2>$null)
        if (-not $lines.Count) { return $null }
        if ($lines | Where-Object { $_.Trim() -eq $User -or $_.Trim().Split("\")[-1] -eq $short }) { return $true }
        if ($User -match '^AzureAD\\') { return $null }
        return $false
    } catch { return $null }
}

function Get-JxTask { Get-ScheduledTask -TaskPath $Script:JxTaskPath -TaskName $Script:JxTaskName -ErrorAction SilentlyContinue }

function Test-JxTask {
    # Etat pour le diagnostic : Absente / OK / Incorrecte (+ detail)
    $t = Get-JxTask
    if (-not $t) { return [pscustomobject]@{ Etat = "Absente"; Detail = "" } }
    $act = ($t.Actions | Select-Object -First 1).Execute
    $det = "compte " + $t.Principal.UserId + ", niveau " + $t.Principal.RunLevel + ", " + $t.State
    if ($t.Principal.RunLevel -ne "Highest" -or $act -notmatch 'JuxtaLink\.exe' -or $t.State -eq "Disabled") { return [pscustomobject]@{ Etat = "Incorrecte"; Detail = $det } }
    return [pscustomobject]@{ Etat = "OK"; Detail = $det }
}

function Get-JxUserRoot { param([string]$User)
    # Racine registre du medecin (HKEY_USERS\<SID>) meme si le script tourne sous un autre compte admin
    try { $sid = (New-Object Security.Principal.NTAccount $User).Translate([Security.Principal.SecurityIdentifier]).Value; if (Test-Path ("Registry::HKEY_USERS\" + $sid)) { return ("Registry::HKEY_USERS\" + $sid) } } catch {}
    return "HKCU:"
}
function Get-JxSaKey { param($e, [string]$User)
    # Cle StartupApproved (= interrupteur du Gestionnaire des taches > Demarrage) correspondant a un lancement auto
    $sa = "\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\"
    if ($e.Type -eq "Run") {
        $root = if ($e.Ou -like "HKLM:*") { "HKLM:" } else { ($e.Ou -split '\\Software\\', 2)[0] }
        return ($root + $sa + $(if ($e.Ou -match 'WOW6432Node') { "Run32" } else { "Run" }))
    }
    $root = if ($e.Ou -like ($env:ProgramData + "*")) { "HKLM:" } else { Get-JxUserRoot $User }
    return ($root + $sa + "StartupFolder")
}
function Test-JxSaDisabled { param([string]$Key, [string]$Name)
    $v = (Get-ItemProperty $Key -Name $Name -ErrorAction SilentlyContinue).$Name
    return [bool]($v -and $v.Length -gt 0 -and ($v[0] % 2) -eq 1)
}
function Set-JxSa { param([string]$Key, [string]$Name, [bool]$Enabled)
    if (-not (Test-Path $Key)) { New-Item -Path $Key -Force | Out-Null }
    $b = New-Object byte[] 12; $b[0] = $(if ($Enabled) { 2 } else { 3 })
    New-ItemProperty -Path $Key -Name $Name -Value $b -PropertyType Binary -Force | Out-Null
}

function Get-JxAutostarts { param([string]$User, [string]$UserAppData)
    # Autres lancements automatiques de JuxtaLink (hors notre tache) : cles Run + dossiers Demarrage
    $res = @()
    $runs = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", ((Get-JxUserRoot $User) + "\Software\Microsoft\Windows\CurrentVersion\Run"))
    foreach ($k in $runs) {
        $p = Get-ItemProperty $k -ErrorAction SilentlyContinue; if (-not $p) { continue }
        foreach ($pr in $p.PSObject.Properties) { if ($pr.Name -notmatch '^PS' -and "$($pr.Value)" -match 'juxtalink') { $res += [pscustomobject]@{ Type = "Run"; Ou = $k; Nom = $pr.Name; Valeur = "$($pr.Value)"; Actif = $true } } }
    }
    $dirs = @((Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\StartUp"))
    if ($UserAppData) { $dirs += (Join-Path $UserAppData "Microsoft\Windows\Start Menu\Programs\Startup") }
    $sh = New-Object -ComObject WScript.Shell
    foreach ($d in $dirs) {
        foreach ($f in (Get-ChildItem $d -Filter *.lnk -ErrorAction SilentlyContinue)) {
            $tgt = try { $sh.CreateShortcut($f.FullName).TargetPath } catch { "" }
            if ($f.Name -match 'juxta' -or $tgt -match 'juxtalink') { $res += [pscustomobject]@{ Type = "Lnk"; Ou = $d; Nom = $f.Name; Valeur = $(if ($tgt) { $tgt } else { "(raccourci d'installation MSI)" }); Actif = $true } }
        }
    }
    foreach ($e in $res) { $e.Actif = -not (Test-JxSaDisabled (Get-JxSaKey $e $User) $e.Nom) }
    return $res
}

function Restore-JxMoved {
    # v0.3.24-0.3.27 DEPLACAIENT le raccourci / la cle Run d'origine. Or ils appartiennent au MSI JuxtaLink :
    # element manquant -> Windows Installer tente une reparation au lancement -> 3 fenetres d'erreur
    # (package introuvable / ressource reseau / erreur irrecuperable). On les remet en place (ils seront desactives, pas deplaces).
    $out = @()
    $b = Get-ItemProperty $Script:JxBackKey -ErrorAction SilentlyContinue; if (-not $b) { return $out }
    foreach ($pr in $b.PSObject.Properties) {
        if ($pr.Name -match '^PS' -or $pr.Name -like "SA|*") { continue }
        try {
            if ($pr.Name -like "LNK|*") { $src = $pr.Name.Substring(4); if ((Test-Path $pr.Value) -and -not (Test-Path $src)) { Copy-Item $pr.Value $src -Force; $out += ("Raccourci d'origine remis en place : " + (Split-Path $src -Leaf)) } }
            else { $i = $pr.Name.LastIndexOf("|"); $k = $pr.Name.Substring(0, $i); $n = $pr.Name.Substring($i + 1); if (-not (Get-ItemProperty $k -Name $n -ErrorAction SilentlyContinue)) { New-ItemProperty -Path $k -Name $n -Value $pr.Value -PropertyType String -Force | Out-Null; $out += ("Cle Run d'origine remise en place : " + $n) } }
            Remove-ItemProperty -Path $Script:JxBackKey -Name $pr.Name -ErrorAction SilentlyContinue
        } catch { $out += ("ATTENTION : remise en place impossible (" + $pr.Name + ") : " + $_.Exception.Message) }
    }
    return $out
}

# ---------------------------------------------------------------- Gardien : veille de JuxtaLink toutes les 10 min (04/10)
# Relance JuxtaLink si quelqu'un le ferme ou s'il plante. Script copie dans ProgramData (survit a la suppression du dossier du kit).
$Script:JxGardKitDir = $PSScriptRoot
$Script:JxGardDir    = "C:\ProgramData\MadeForMed\Gardien"
$Script:JxGardName   = "Gardien-JuxtaLink"
function Get-JxGardien { Get-ScheduledTask -TaskPath $Script:JxTaskPath -TaskName $Script:JxGardName -ErrorAction SilentlyContinue }
function Test-JxGardien {
    $t = Get-JxGardien
    if (-not $t) { return [pscustomobject]@{ Etat = "Absente"; Detail = "" } }
    if ($t.State -eq "Disabled" -or -not (Test-Path (Join-Path $Script:JxGardDir "Gardien-JuxtaLink.ps1"))) { return [pscustomobject]@{ Etat = "Incorrecte"; Detail = [string]$t.State } }
    return [pscustomobject]@{ Etat = "OK"; Detail = "toutes les 10 min, compte SYSTEM" }
}
function Install-JxGardien {
    $src = Join-Path $Script:JxGardKitDir "Gardien-JuxtaLink.ps1"
    if (-not (Test-Path $src)) { throw "Gardien-JuxtaLink.ps1 absent du kit" }
    New-Item -ItemType Directory -Force $Script:JxGardDir | Out-Null
    Copy-Item $src (Join-Path $Script:JxGardDir "Gardien-JuxtaLink.ps1") -Force
    $a = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"" + (Join-Path $Script:JxGardDir "Gardien-JuxtaLink.ps1") + "`"")
    $t = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 10)
    $p = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances IgnoreNew -StartWhenAvailable
    Register-ScheduledTask -TaskPath $Script:JxTaskPath -TaskName $Script:JxGardName -Action $a -Trigger $t -Principal $p -Settings $s -Description "Odaiji : veille JuxtaLink toutes les 10 min, le relance s'il est arrete (kit Odaiji_Juxta)" -Force | Out-Null
    return "Gardien installe : veille JuxtaLink toutes les 10 min, relance s'il est arrete (journal C:\ProgramData\MadeForMed\Gardien\gardien.log)"
}
function Remove-JxGardien {
    if (Get-JxGardien) { Unregister-ScheduledTask -TaskPath $Script:JxTaskPath -TaskName $Script:JxGardName -Confirm:$false; return "Gardien JuxtaLink retire" }
    return $null
}

function Install-JxTask { param([string]$User, [string]$UserAppData)
    # Retourne une liste de lignes de compte rendu ; leve une exception si la tache ne peut pas etre creee
    $out = @()
    if (-not (Test-Path $Script:JxExe)) { throw "JuxtaLink.exe introuvable ($Script:JxExe)" }
    if (-not $User) { $User = Get-JxUser }
    $adm = Test-JxUserAdmin $User
    if ($adm -eq $false) { $out += ("ATTENTION : " + $User + " n'est pas administrateur du poste : Windows demandera un mot de passe administrateur au lancement de JuxtaLink.") }

    $a = New-ScheduledTaskAction -Execute $Script:JxExe -WorkingDirectory (Split-Path $Script:JxExe)
    $t = New-ScheduledTaskTrigger -AtLogOn -User $User; $t.Delay = "PT15S"
    $p = New-ScheduledTaskPrincipal -UserId $User -LogonType Interactive -RunLevel Highest
    $s = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew -StartWhenAvailable
    Register-ScheduledTask -TaskPath $Script:JxTaskPath -TaskName $Script:JxTaskName -Action $a -Trigger $t -Principal $p -Settings $s -Description "Odaiji : JuxtaLink sans fenetre UAC a l'ouverture de session (kit Odaiji_Juxta)" -Force | Out-Null
    $out += ("Tache planifiee \Odaiji\JuxtaLink creee pour " + $User + " (ouverture de session, privileges eleves, sans UAC)")

    # Autres lancements automatiques : DESACTIVES (comme Gestionnaire des taches > Demarrage), jamais deplaces ni supprimes
    if (-not (Test-Path $Script:JxBackKey)) { New-Item -Path $Script:JxBackKey -Force | Out-Null }
    $out += @(Restore-JxMoved)
    foreach ($e in @(Get-JxAutostarts $User $UserAppData)) {
        if (-not $e.Actif) { continue }
        $sk = Get-JxSaKey $e $User
        Set-JxSa $sk $e.Nom $false
        New-ItemProperty -Path $Script:JxBackKey -Name ("SA|" + $sk + "|" + $e.Nom) -Value "1" -PropertyType String -Force | Out-Null
        $out += ("Lancement automatique d'origine desactive (sans le supprimer) : " + $e.Nom)
    }

    # Icone Bureau : relance sans UAC
    $sh = New-Object -ComObject WScript.Shell; $l = $sh.CreateShortcut($Script:JxLnk)
    $l.TargetPath = Join-Path $env:SystemRoot "System32\schtasks.exe"
    $l.Arguments = "/run /tn `"" + $Script:JxTaskPath + $Script:JxTaskName + "`""
    $l.IconLocation = $Script:JxExe + ",0"; $l.WindowStyle = 7; $l.Description = "Demarrer JuxtaLink (Odaiji) sans fenetre UAC"; $l.Save()
    $out += "Icone 'JuxtaLink (Odaiji)' posee sur le Bureau (relance sans UAC)"
    try { $out += (Install-JxGardien) } catch { $out += ("ATTENTION : gardien non installe : " + $_.Exception.Message) }
    return $out
}

function Remove-JxTask {
    $out = @()
    if (Get-JxTask) { Unregister-ScheduledTask -TaskPath $Script:JxTaskPath -TaskName $Script:JxTaskName -Confirm:$false; $out += "Tache \Odaiji\JuxtaLink supprimee" }
    $g = Remove-JxGardien; if ($g) { $out += $g }
    if (Test-Path $Script:JxLnk) { Remove-Item $Script:JxLnk -Force; $out += "Icone JuxtaLink (Odaiji) retiree" }
    $out += @(Restore-JxMoved)
    $b = Get-ItemProperty $Script:JxBackKey -ErrorAction SilentlyContinue
    if ($b) {
        foreach ($pr in $b.PSObject.Properties) {
            if ($pr.Name -notlike "SA|*") { continue }
            $i = $pr.Name.LastIndexOf("|"); $k = $pr.Name.Substring(3, $i - 3); $n = $pr.Name.Substring($i + 1)
            try { Set-JxSa $k $n $true; $out += ("Lancement automatique d'origine reactive : " + $n) } catch {}
        }
        Remove-Item $Script:JxBackKey -Force -ErrorAction SilentlyContinue
    }
    if (-not $out) { $out += "Rien a retirer" }
    return $out
}

# ---------------------------------------------------------------- Source d'installation MSI de JuxtaLink
# Retour terrain 29/09 : JuxtaLink installe depuis le zip ouvert sans extraction (dossier Temp purge ensuite).
# Des que Windows Installer veut "reparer" JuxtaLink (element manquant), il cherche SetupJuxtaLinkx86.msi dans ce dossier
# disparu -> 3 fenetres : "Aucun package d'installation...", "ressource reseau non disponible", "Erreur irrecuperable".
$Script:JxMsiDir = "C:\ProgramData\MadeForMed\JuxtaLink"
function Convert-JxPackedGuid { param([string]$Guid)
    $h = $Guid.Trim('{}').Replace('-', '').ToUpper(); if ($h.Length -ne 32) { return "" }
    $r = -join ($h.Substring(0, 8).ToCharArray()[7..0]) + -join ($h.Substring(8, 4).ToCharArray()[3..0]) + -join ($h.Substring(12, 4).ToCharArray()[3..0])
    for ($i = 16; $i -lt 32; $i += 2) { $r += $h[$i + 1] + [string]$h[$i] }
    return $r
}
function Get-JxMsi {
    try {
        foreach ($h in "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") {
            foreach ($r in @(Get-ItemProperty $h -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '^JuxtaLink' -and $_.WindowsInstaller -eq 1 })) {
                $pc = $r.PSChildName; $pk = "HKLM:\SOFTWARE\Classes\Installer\Products\" + (Convert-JxPackedGuid $pc)
                $sl = Get-ItemProperty ($pk + "\SourceList") -ErrorAction SilentlyContinue
                $pkg = [string]$sl.PackageName; $srcs = @()
                $net = Get-ItemProperty ($pk + "\SourceList\Net") -ErrorAction SilentlyContinue
                if ($net) { $srcs = @($net.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object { [Environment]::ExpandEnvironmentVariables([string]$_.Value) }) }
                if ($r.InstallSource) { $srcs += [string]$r.InstallSource }
                $ok = [bool]($pkg -and ($srcs | Where-Object { $_ -and (Test-Path (Join-Path $_ $pkg)) }))
                return [pscustomobject]@{ ProductCode = $pc; Version = [string]$r.DisplayVersion; ProdKey = $pk; PackageName = $pkg; PackageCode = [string](Get-ItemProperty $pk -ErrorAction SilentlyContinue).PackageCode; Sources = $srcs; SourceOk = $ok }
            }
        }
    } catch {}
    return $null
}
function Wait-JxMsiIdle { param([int]$Secondes = 90)
    # 29/09 (PCCABINET) : JuxtaLink relance juste apres notre reparation MSI -> sa mise a jour de plugin tombe sur
    # "une autre installation est en cours" (1618) puis 1603. On attend que Windows Installer soit libre.
    $fin = (Get-Date).AddSeconds($Secondes)
    while ((Get-Date) -lt $fin) {
        $busy = $false; try { $m = [Threading.Mutex]::OpenExisting("Global\_MSIExecute"); $m.Dispose(); $busy = $true } catch {}
        if (-not $busy) { return $true }
        Start-Sleep 3
    }
    return $false
}
function Get-JxMsiPackageCode { param([string]$Path)
    try { $i = New-Object -ComObject WindowsInstaller.Installer; $si = $i.GetType().InvokeMember("SummaryInformation", "GetProperty", $null, $i, @($Path, 0)); return [string]$si.GetType().InvokeMember("Property", "GetProperty", $null, $si, @(9)) } catch { return "" }
}
function Get-JxMsiErrors { param([int]$Jours = 7)
    # Evenements MsiInstaller 1004 (element manquant -> reparation) / 1001 lies a JuxtaLink
    $m = Get-JxMsi; if (-not $m) { return @() }
    try { return @(Get-WinEvent -FilterHashtable @{ LogName = "Application"; ProviderName = "MsiInstaller"; Id = 1001, 1004; StartTime = (Get-Date).AddDays(-$Jours) } -MaxEvents 200 -ErrorAction Stop | Where-Object { $_.Message -match [regex]::Escape($m.ProductCode) } | Select-Object -First 5) } catch { return @() }
}
function Repair-JxMsiSource { param([string]$KitMsi)
    # Rend a Windows Installer une source permanente (C:\ProgramData\MadeForMed\JuxtaLink) puis repare JuxtaLink en silence
    $out = @(); $m = Get-JxMsi
    if (-not $m) { return @("JuxtaLink n'est pas installe par MSI : rien a faire") }
    if (-not $m.SourceOk) {
        if (-not ($KitMsi -and (Test-Path $KitMsi))) { return @("ATTENTION : source MSI JuxtaLink introuvable et installeur du kit absent") }
        $kc = Convert-JxPackedGuid (Get-JxMsiPackageCode $KitMsi)
        if (-not $kc -or $kc -ne $m.PackageCode) { return @("ATTENTION : JuxtaLink " + $m.Version + " n'a pas ete installe avec le MSI du kit : relancer 1-Installer.bat (reinstallation propre) ou recuperer le MSI " + $m.Version + " aupres de Juxta") }
        New-Item -ItemType Directory -Force $Script:JxMsiDir | Out-Null
        $pkg = if ($m.PackageName) { $m.PackageName } else { Split-Path $KitMsi -Leaf }
        Copy-Item $KitMsi (Join-Path $Script:JxMsiDir $pkg) -Force
        $net = $m.ProdKey + "\SourceList\Net"; if (-not (Test-Path $net)) { New-Item -Path $net -Force | Out-Null }
        $idx = 1; $np = Get-ItemProperty $net -ErrorAction SilentlyContinue
        while ($np -and ($np.PSObject.Properties.Name -contains [string]$idx)) { $idx++ }
        New-ItemProperty -Path $net -Name ([string]$idx) -Value ($Script:JxMsiDir + "\") -PropertyType ExpandString -Force | Out-Null
        Set-ItemProperty -Path ($m.ProdKey + "\SourceList") -Name "LastUsedSource" -Value ("n;" + $idx + ";" + $Script:JxMsiDir + "\") -ErrorAction SilentlyContinue
        $out += ("Source d'installation JuxtaLink retablie : " + $Script:JxMsiDir + "\" + $pkg + " (l'ancienne etait dans un dossier temporaire purge)")
    } else { $out += "Source d'installation JuxtaLink presente" }
    $running = [bool](Get-Process JuxtaLink -ErrorAction SilentlyContinue)
    if ($running) { Get-Process JuxtaLink -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 2 }
    [void](Wait-JxMsiIdle 60)
    $p = Start-Process msiexec.exe -ArgumentList ("/fomus " + $m.ProductCode + " /qn /norestart REBOOT=ReallySuppress") -Wait -PassThru
    [void](Wait-JxMsiIdle 90)
    if ($p.ExitCode -in 0, 3010) { $out += ("JuxtaLink repare en silence (msiexec " + $p.ExitCode + ") : plus de fenetres 'package d'installation introuvable'") } else { $out += ("ATTENTION : reparation msiexec code " + $p.ExitCode) }
    if ($running) { $out += "RELANCER" }
    return $out
}

# ---------------------------------------------------------------- Source MSI du FSV (uniquement si elle est fragile)
# 05/10 : le FSV x64 peut avoir ete installe depuis Telechargements/Temp. Si ce dossier est vide ensuite, une reparation
# Windows affiche "Aucun package d'installation". On ne copie le MSI du kit dans ProgramData QUE dans ce cas (meme package).
$Script:FsvMsiDir = "C:\ProgramData\MadeForMed\FSV"
function Get-FsvMsiRisk {
    # Retourne les produits FSV (MSI) dont aucune source n'est durable : absente, ou dans un profil utilisateur / Temp.
    $res = @()
    try {
        foreach ($h in "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*") {
            foreach ($r in @(Get-ItemProperty $h -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'FSV' -and $_.DisplayName -notmatch 'Juxta' -and $_.WindowsInstaller -eq 1 })) {
                $pk = "HKLM:\SOFTWARE\Classes\Installer\Products\" + (Convert-JxPackedGuid $r.PSChildName)
                $sl = Get-ItemProperty ($pk + "\SourceList") -ErrorAction SilentlyContinue
                $pkg = [string]$sl.PackageName; $srcs = @()
                $net = Get-ItemProperty ($pk + "\SourceList\Net") -ErrorAction SilentlyContinue
                if ($net) { $srcs = @($net.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object { [Environment]::ExpandEnvironmentVariables([string]$_.Value) }) }
                if ($r.InstallSource) { $srcs += [string]$r.InstallSource }
                $durable = @($srcs | Where-Object { $_ -and $pkg -and (Test-Path (Join-Path $_ $pkg)) -and ($_ -notmatch '\\(Users|Temp|Downloads)\\') })
                if (-not $durable.Count) { $res += [pscustomobject]@{ ProductCode = $r.PSChildName; Nom = [string]$r.DisplayName; Version = [string]$r.DisplayVersion; ProdKey = $pk; PackageName = $pkg; Sources = $srcs } }
            }
        }
    } catch {}
    return $res
}
function Repair-FsvMsiSource { param([string[]]$KitMsis)
    $out = @(); $risk = @(Get-FsvMsiRisk)
    if (-not $risk.Count) { return @("Source MSI du FSV durable ou FSV absent : rien a faire") }
    foreach ($m in $risk) {
        $pc = Convert-JxPackedGuid ""; $done = $false
        foreach ($k in $KitMsis) {
            $kc = Convert-JxMsiPkgGuidSafe $k
            $mine = $null; try { $mine = (Get-ItemProperty $m.ProdKey -ErrorAction SilentlyContinue).PackageCode } catch {}
            if ($kc -and $mine -and $kc -eq [string]$mine) {
                New-Item -ItemType Directory -Force $Script:FsvMsiDir | Out-Null
                $pkg = if ($m.PackageName) { $m.PackageName } else { Split-Path $k -Leaf }
                Copy-Item $k (Join-Path $Script:FsvMsiDir $pkg) -Force
                $net = $m.ProdKey + "\SourceList\Net"; if (-not (Test-Path $net)) { New-Item -Path $net -Force | Out-Null }
                $idx = 1; $np = Get-ItemProperty $net -ErrorAction SilentlyContinue
                while ($np -and ($np.PSObject.Properties.Name -contains [string]$idx)) { $idx++ }
                New-ItemProperty -Path $net -Name ([string]$idx) -Value ($Script:FsvMsiDir + "\") -PropertyType ExpandString -Force | Out-Null
                Set-ItemProperty -Path ($m.ProdKey + "\SourceList") -Name "LastUsedSource" -Value ("n;" + $idx + ";" + $Script:FsvMsiDir + "\") -ErrorAction SilentlyContinue
                $out += ("Source d'installation du FSV " + $m.Version + " retablie : " + $Script:FsvMsiDir + "\" + $pkg); $done = $true; break
            }
        }
        if (-not $done) { $out += ("ATTENTION : " + $m.Nom + " " + $m.Version + " : aucun MSI du kit ne correspond a ce package (source laissee telle quelle)") }
    }
    return $out
}
function Convert-JxMsiPkgGuidSafe { param([string]$Path) try { return (Convert-JxPackedGuid (Get-JxMsiPackageCode $Path)) } catch { return "" } }

function Start-JxTask {
    # Demarre JuxtaLink : via la tache (sans UAC, hors arbre de processus) ; sinon via explorer.exe (session du medecin)
    if (Get-JxTask) { Start-ScheduledTask -TaskPath $Script:JxTaskPath -TaskName $Script:JxTaskName; return "tache" }
    if (Test-Path $Script:JxExe) { Start-Process explorer.exe -ArgumentList ("`"" + $Script:JxExe + "`""); return "explorer" }
    return ""
}
