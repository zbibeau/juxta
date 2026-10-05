# Odaiji-Commun.ps1 - fonctions partagees du kit (dot-source : . "$PSScriptRoot\Odaiji-Commun.ps1")
#   Get-PosteId     : identifiant stable du poste (GUID cree au premier passage, ProgramData\MadeForMed\poste-id.txt)
#   Get-CleEnvoi    : cle d'envoi du cabinet (cle-envoi.txt a cote du kit ou dans ProgramData\MadeForMed) - JAMAIS dans le zip public
#   Send-OjRapport  : envoie un rapport / journal ; en cas d'echec reseau, le met en FILE D'ATTENTE (spool) pour le prochain passage
#   Send-OjBattement: envoie le petit message "je suis vivant + etat" de la sentinelle
#   Invoke-OjSpool  : renvoie la file d'attente (appele apres chaque envoi reussi)
# Jamais bloquant : aucune fonction ne leve d'exception.
$Script:OJ_Kit = $PSScriptRoot
$Script:OJ_Url = if ($env:ODAIJI_URL) { $env:ODAIJI_URL } else { "https://odaiji-juxta.netlify.app/.netlify/functions/rapport" }   # ODAIJI_URL : tests uniquement
function Get-OjDir {
    $d = Join-Path $env:ProgramData "MadeForMed"
    try { New-Item -ItemType Directory -Force -Path $d -ErrorAction Stop | Out-Null; $t = Join-Path $d ".w"; Set-Content -Path $t -Value "x" -ErrorAction Stop; Remove-Item $t -Force -ErrorAction SilentlyContinue; return $d } catch { return $env:TEMP }
}
function Get-PosteId {
    try {
        $f = Join-Path (Get-OjDir) "poste-id.txt"
        if (Test-Path $f) { $v = ([string](Get-Content $f -Raw)).Trim(); if ($v -match '^[0-9a-fA-F-]{8,40}$') { return $v.ToLower() } }
        $v = [guid]::NewGuid().ToString(); Set-Content -Path $f -Value $v -Encoding ASCII; return $v
    } catch { return "" }
}
function Get-CleEnvoi {
    foreach ($p in @((Join-Path $Script:OJ_Kit "cle-envoi.txt"), (Join-Path (Get-OjDir) "cle-envoi.txt"))) {
        try { if (Test-Path $p) { $k = ([string](Get-Content $p -Raw)).Trim(); if ($k -match '^[A-Za-z0-9_-]{8,80}$') { return $k } } } catch {}
    }
    return ""
}
function Get-OjVersion {
    try { $kp = Join-Path $Script:OJ_Kit "OdaijiJuxta.ps1"; if (Test-Path $kp) { return [regex]::Match((Get-Content $kp -Raw), '\$Script:Version\s*=\s*"([^"]+)"').Groups[1].Value } } catch {}
    return "?"
}
# Envoi d'un JSON deja serialise (octets). Retourne @{ ok; permanent; err }  (permanent = inutile de reessayer : 400 / 401 / 413)
function Send-OjBytes {
    param([byte[]]$Bytes)
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $h = @{}; $k = Get-CleEnvoi; if ($k) { $h["X-Odaiji-Key"] = $k }
        [void](Invoke-RestMethod -Uri $Script:OJ_Url -Method Post -Body $Bytes -ContentType "application/json; charset=utf-8" -Headers $h -TimeoutSec 25 -ErrorAction Stop)
        return @{ ok = $true; permanent = $false; err = "" }
    } catch {
        $e = ([string]$_.Exception.Message -replace "[\r\n]+", " "); if ($e.Length -gt 120) { $e = $e.Substring(0, 120) }
        $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        return @{ ok = $false; permanent = ($code -in 400, 401, 413); err = $e }
    }
}
function Add-OjSpool {
    param([string]$Json)
    try {
        $d = Join-Path (Get-OjDir) "spool"; New-Item -ItemType Directory -Force -Path $d | Out-Null
        $all = @(Get-ChildItem $d -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object Name)
        while ($all.Count -ge 50) { Remove-Item $all[0].FullName -Force -ErrorAction SilentlyContinue; $all = @($all | Select-Object -Skip 1) }
        $n = "{0}_{1}.json" -f (Get-Date -Format "yyyyMMddHHmmss"), ([guid]::NewGuid().ToString().Substring(0, 8))
        [IO.File]::WriteAllText((Join-Path $d $n), $Json, (New-Object Text.UTF8Encoding($false)))
        return $true
    } catch { return $false }
}
function Invoke-OjSpool {
    try {
        $d = Join-Path (Get-OjDir) "spool"; if (-not (Test-Path $d)) { return 0 }
        $sent = 0
        foreach ($f in @(Get-ChildItem $d -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 25)) {
            if ($f.LastWriteTime -lt (Get-Date).AddDays(-14)) { Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue; continue }
            $r = Send-OjBytes ([IO.File]::ReadAllBytes($f.FullName))
            if ($r.ok -or $r.permanent) { Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue; if ($r.ok) { $sent++ } } else { break }
        }
        return $sent
    } catch { return 0 }
}
# Retourne @{ statut = envoye | differe | refuse ; err }
function Send-OjPayload {
    param([hashtable]$Payload)
    try {
        $json = $Payload | ConvertTo-Json -Compress -Depth 4
        $r = Send-OjBytes ([Text.Encoding]::UTF8.GetBytes($json))
        if ($r.ok) { [void](Invoke-OjSpool); return @{ statut = "envoye"; err = "" } }
        if ($r.permanent) { return @{ statut = "refuse"; err = $r.err } }
        if (Add-OjSpool $json) { return @{ statut = "differe"; err = $r.err } }
        return @{ statut = "refuse"; err = $r.err }
    } catch { return @{ statut = "refuse"; err = ([string]$_.Exception.Message) } }
}
function Send-OjRapport {
    param([string]$Fichier, [string]$Raison = "rapport", [long]$Depuis = 0, [string]$Os = "pc")
    try {
        $t = [IO.File]::ReadAllText($Fichier); if ($Depuis -gt 0 -and $Depuis -lt $t.Length) { $t = $t.Substring($Depuis) }
        if ($t.Length -gt 240000) { $t = $t.Substring($t.Length - 240000) }
        return (Send-OjPayload @{ kit = "odaiji-juxta"; os = $Os; version = (Get-OjVersion); poste = $env:COMPUTERNAME; poste_id = (Get-PosteId); nom = (Split-Path $Fichier -Leaf); raison = $Raison; rapport = $t })
    } catch { return @{ statut = "refuse"; err = ([string]$_.Exception.Message) } }
}
function Send-OjBattement {
    param([string]$Corps)
    return (Send-OjPayload @{ kit = "odaiji-juxta"; type = "battement"; os = "pc"; version = (Get-OjVersion); poste = $env:COMPUTERNAME; poste_id = (Get-PosteId); nom = "battement"; raison = "battement"; rapport = $Corps })
}
function Format-OjStatut {
    param($R, [string]$Quoi = "Rapport")
    switch ($R.statut) {
        "envoye" { return ($Quoi + " transmis automatiquement a MadeForMed.") }
        "differe" { return ($Quoi + " mis en file d'attente (envoi differe : " + $R.err + ") : il partira au prochain passage du kit.") }
        default { return ("Envoi automatique impossible (" + $R.err + ") : recuperer ce fichier par le transfert de fichiers TeamViewer et l'envoyer a l'equipe.") }
    }
}

# ---- Sentinelle : fonctions pures (testees contre le corpus de rapports reels)
# Resume d'un rapport du kit : @{ scenario; constats = @(@{code;niveau}) }
function Get-RapportResume {
    param([string]$Texte)
    $sc = $null; $cs = @(); $in = $false
    foreach ($l in ($Texte -split "`r?`n")) {
        if ($l -match '^Scenario\s*:\s*(\S+)') { $sc = $Matches[1]; continue }
        if ($l -match '^Constats') { $in = $true; continue }
        if ($in) {
            if ($l -cmatch '^\s{4,}([A-Z][A-Za-z0-9_]+)\s+(KO|WARN|INFO|OK)\s+') { $cs += @{ code = $Matches[1]; niveau = $Matches[2] } }
            elseif ($l.Trim() -eq "" -or $l.StartsWith("====")) { $in = $false }
        }
    }
    return @{ scenario = $sc; constats = $cs }
}
# Faut-il envoyer le rapport COMPLET (sinon : battement seul) ?  $Etat = objet lu dans etat.json ou $null.
# Retourne @{ complet = bool ; raison = texte }.  Regles : premier passage ; scenario change ; nouveau code KO / WARN ; rapport complet vieux de 7 jours.
function Get-DecisionEnvoi {
    param($Etat, [string]$Scenario, [string[]]$Codes, [datetime]$Maintenant)
    if (-not $Etat) { return @{ complet = $true; raison = "premier passage" } }
    $avant = @($Etat.codes)
    $nouveaux = @($Codes | Where-Object { $avant -notcontains $_ })
    if ($nouveaux.Count) { return @{ complet = $true; raison = ("nouveau constat " + ($nouveaux -join ",")) } }
    if ($Etat.scenario -ne $Scenario) { return @{ complet = $true; raison = ("scenario " + $Etat.scenario + " -> " + $Scenario) } }
    $d = [datetime]::MinValue; try { $d = [datetime]::ParseExact([string]$Etat.dernier_rapport, "yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture) } catch {}
    if (($Maintenant - $d).TotalDays -ge 7) { return @{ complet = $true; raison = "rapport hebdomadaire" } }
    return @{ complet = $false; raison = "inchange" }
}

# Delta Avant / Apres (KO + WARN) : @{ corriges; restent; nouveaux } (listes de codes triees)
function Compare-Constats {
    param($Avant, $Apres)
    $a = @($Avant.constats | Where-Object { $_.niveau -in "KO", "WARN" } | ForEach-Object { $_.code } | Sort-Object -Unique)
    $b = @($Apres.constats | Where-Object { $_.niveau -in "KO", "WARN" } | ForEach-Object { $_.code } | Sort-Object -Unique)
    return @{ corriges = @($a | Where-Object { $b -notcontains $_ }); restent = @($a | Where-Object { $b -contains $_ }); nouveaux = @($b | Where-Object { $a -notcontains $_ }) }
}
