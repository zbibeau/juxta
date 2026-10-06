# Cas de sesam.ini : chaque poste vu sur le terrain devient un cas permanent. Ajouter un cas = ajouter une ligne a $cases.
param([string]$Kit)
. (Join-Path $PSScriptRoot "extract.ps1")
$ps = Join-Path $Kit "OdaijiJuxta.ps1"
. ([scriptblock]::Create((Get-KitFunction $ps "Get-SesamIniState")))
. ([scriptblock]::Create((Get-KitFunction $ps "Set-SesamKey")))
. ([scriptblock]::Create((Get-KitFunction $ps "Get-TableMissing")))
. ([scriptblock]::Create((Get-KitFunction $ps "Get-TablesIncompletes")))
. ([scriptblock]::Create((Get-KitFunction $ps "Get-ScinfoMulti")))
. ([scriptblock]::Create((Get-KitFunction $ps "W")))
. ([scriptblock]::Create((Get-KitFunction $ps "Get-DmpPcscHits")))
$fail = 0
function Check { param($ok, $msg) if ($ok) { Write-Host ("  ok   " + $msg) } else { Write-Host ("  ECHEC " + $msg) -ForegroundColor Red; $script:fail++ } }
$pd = "C:\ProgramData\santesocial\fsv\1.40.14"; $ssv = "C:\Program Files (x86)\santesocial\fsv\1.40.14\ssv"
$presents = @("$pd\conf\log4crc.xml", $ssv)
$ex = { param($p) $presents -contains $p }

# nom ; lignes du sesam.ini ; MgcOk attendu ; SsvOk attendu
$cases = @(
  @("complet (genere par le kit)", @("[COMMUN]","RepertoireTable=$ssv","[SSV]","RepertoireTable=$ssv","[MGC]","RepertoireConfigTrace=$pd\conf"), $true, $true, $true),
  @("PC26-FILLATRE 05/10 : ProgramData ecrit par le MSI x64, sans cle [SSV] RepertoireTable", @("[COMMUN]","RepertoireTravail=$pd\adm","[MGC]","RepertoireConfigTrace=$pd\conf","[SSV]","tempoexclusivite=500"), $true, $false, $false),
  @("PC26-FILLATRE 05/10 : [SSV] absent, [MGC] absent", @("[COMMUN]","RepertoireTravail=$pd\adm"), $false, $false, $false),
  @("29/09 : chemin SSV x86 inexistant (existe seulement en x64)", @("[SSV]","RepertoireTable=C:\Program Files (x86)\santesocial\fsv\1.40.14\ssvX","[MGC]","RepertoireConfigTrace=$pd\conf"), $true, $false, $false),
  @("Dr Plongeron 29/09 : [MGC] absent, tables OK", @("[SSV]","RepertoireTable=$ssv"), $false, $true, $false),
  @("casse differente des sections et des cles", @("[ssv]","repertoiretable=$ssv","[mgc]","repertoireconfigtrace=$pd\conf"), $true, $true, $false),
  @("PC26-FILLATRE 05/10 apres reparation : tous les ini corrects (l'erreur persiste -> ini lu ailleurs)", @("[COMMUN]","RepertoireTable=$ssv","[SSV]","RepertoireTable=$ssv","[MGC]","RepertoireConfigTrace=$pd\conf"), $true, $true, $true),
  @("fichier vide", @(), $false, $false, $false)
)
foreach ($c in $cases) {
    $st = Get-SesamIniState -Lines $c[1] -Exists $ex
    Check (($st.MgcOk -eq $c[2]) -and ($st.SsvOk -eq $c[3]) -and ($st.CommunOk -eq $c[4])) ($c[0] + "  (Mgc=" + $st.MgcOk + " Ssv=" + $st.SsvOk + ")")
}

# Reparation : Set-SesamKey pose la cle sans casser le reste, et le diag la voit ensuite
$tmp = Join-Path ([IO.Path]::GetTempPath()) "sesam-test.ini"
foreach ($c in $cases) {
    [IO.File]::WriteAllText($tmp, (($c[1] -join "`r`n") + "`r`n"))
    Set-SesamKey $tmp "SSV" "RepertoireTable" $ssv
    Set-SesamKey $tmp "COMMUN" "RepertoireTable" $ssv
    $st = Get-SesamIniState -Lines @(Get-Content $tmp) -Exists $ex
    Check ($st.SsvOk -and $st.CommunOk) ("reparation : " + $c[0])
    if ($c[2]) { Check ($st.MgcOk) ("reparation sans effet de bord sur [MGC] : " + $c[0]) }
}
# idempotence : deux poses = une seule cle
[IO.File]::WriteAllText($tmp, "[SSV]`r`na=1`r`n")
Set-SesamKey $tmp "SSV" "RepertoireTable" $ssv; Set-SesamKey $tmp "SSV" "RepertoireTable" $ssv
Check ((@(Get-Content $tmp | Where-Object { $_ -match '^RepertoireTable=' }).Count -eq 1)) "idempotence de Set-SesamKey"
Remove-Item $tmp -ErrorAction SilentlyContinue
if ($fail) { Write-Host ("$fail echec(s)") -ForegroundColor Red; exit 1 }

# Tables x86/x64 : cas reels. POSTE2 05/10 = x86 a les .pem, x64 a tablebin/scripts -> 4 fichiers a copier ; PC26-FILLATRE = x86 complet -> rien.
$p2x86 = @("acint.pem","certamcr.pem","certamct.pem","crl.crl","crl.pem","scripts.sms")
$p2x64 = @("scripts.sms","scripts.ssv","tablebin.smc","tablebin.ssp","tablebin.ssv")
$m = @(Get-TableMissing -Rel86 $p2x86 -Rel64 $p2x64)
Check (($m.Count -eq 4) -and ($m -contains "tablebin.ssv") -and ($m -contains "scripts.ssv")) ("POSTE2 : fichiers a copier = " + ($m -join ","))
$m = @(Get-TableMissing -Rel86 @("A.pem","TABLEBIN.SSV","scripts.ssv") -Rel64 @("tablebin.ssv","scripts.ssv"))
Check ($m.Count -eq 0) "PC26-FILLATRE : x86 complet (casse ignoree) -> rien a copier"
# POSTE1 06/10 : arbre reel recree dans un dossier temporaire. x86 ssv = 14 fichiers (certificats + scripts.sms), x64 ssv = 5 fichiers (dont 4 absents du x86),
# sts x86 vide / x64 = 3 fichiers (non signale : sesam.ini pointe alors sur x64). Le MSI x64 pose les tables APRES le diag initial -> recalcul a l'execution.
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("oj-tables-" + [guid]::NewGuid().ToString("N")); $v = "1.40.14"
$r86 = Join-Path $tmp "x86"; $r64 = Join-Path $tmp "x64"
foreach ($d in "$r86\fsv\$v\ssv","$r86\fsv\$v\sts","$r86\fsv\$v\srt","$r64\fsv\$v\ssv","$r64\fsv\$v\sts","$r64\fsv\$v\srt") { New-Item -ItemType Directory -Force $d | Out-Null }
foreach ($f in "acint.pem","certamcr.pem","certamct.pem","certamoamcr.pem","certamoamct.pem","certamor.pem","certamot.pem","certbabusr.pem","certbabust.pem","certgier.pem","certgiet.pem","crl.crl","crl.pem","scripts.sms") { Set-Content "$r86\fsv\$v\ssv\$f" "x" }
foreach ($f in "scripts.sms","scripts.ssv","tablebin.smc","tablebin.ssp","tablebin.ssv") { Set-Content "$r64\fsv\$v\ssv\$f" "x" }
foreach ($f in "scriptsi.sts","scriptsm.sts","tablesi.sts") { Set-Content "$r64\fsv\$v\sts\$f" "x" }
$inc = Get-TablesIncompletes -Root86 $r86 -Root64 $r64 -Version $v
Check (($inc.Keys.Count -eq 1) -and ($inc["ssv"].Count -eq 4) -and ($inc["ssv"] -contains "tablebin.ssv") -and ($inc["ssv"] -contains "scripts.ssv")) ("POSTE1 : ssv x86 incomplet, 4 fichiers a copier (" + (@($inc["ssv"]) -join ",") + "), sts/srt non signales")
foreach ($f in $inc["ssv"]) { Copy-Item "$r64\fsv\$v\ssv\$f" "$r86\fsv\$v\ssv\$f" }
Check ((Get-TablesIncompletes -Root86 $r86 -Root64 $r64 -Version $v).Count -eq 0) "POSTE1 : apres copie des 4 fichiers, plus rien d'incomplet"
Check ((Get-TablesIncompletes -Root86 (Join-Path $tmp "absent") -Root64 $r64 -Version $v).Count -eq 0) "dossier x86 absent : pas d'erreur, rien a copier"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
# Masquage : un horodatage de transcription n'est pas un NIR ; 13 et 15 chiffres le restent
$Report = Join-Path ([IO.Path]::GetTempPath()) ("oj-w-" + [guid]::NewGuid().ToString("N") + ".txt")
W "Heure de debut : 20261006142130" "Gray" | Out-Null; W "suite 1850575123456 / 185057512345678" "Gray" | Out-Null
$wr = Get-Content $Report -Raw; Remove-Item $Report -Force -ErrorAction SilentlyContinue
W "laisser finir) : LNA_CHROME" "Gray" | Out-Null; W "numNatPs: 12345678" "Gray" | Out-Null
$wr2 = Get-Content $Report -Raw; Remove-Item $Report -Force -ErrorAction SilentlyContinue
Check (($wr2 -match "finir\) : LNA_CHROME") -and ($wr2 -match "numNatPs: \[masque\]")) "masquage kit : 'finir) : LNA_CHROME' conserve, numNatPs masque"
Check (($wr -match "debut : 20261006142130") -and ($wr -match "suite \[nir-masque\] / \[nir-masque\]")) "masquage kit : horodatage conserve, 13 et 15 chiffres masques"
# 06/10 (DESKTOP-5G0VEGR) : 2 lecteurs OLAQIN avec une CPS dans chacun -> Odaiji "Plusieurs cartes de meme type". certutil liste chaque lecteur 2 fois.
$sc2 = "--- Lecteur: OLAQIN 90048020 TL VITALACT 1 0`r`n--- Statut: SCARD_STATE_PRESENT`r`n--- Carte: CPS`r`n--- Lecteur: OLAQIN 90048293 TL VITALACT 1 1`r`n--- Carte: CPS`r`n--- Lecteur: OLAQIN 90048020 TL VITALACT 1 0`r`n--- Carte: CPS`r`n--- Lecteur: OLAQIN 90048293 TL VITALACT 1 1`r`n--- Carte: CPS"
$mm = Get-ScinfoMulti -Text $sc2
Check ((@($mm.Cps).Count -eq 2) -and (@($mm.Vitale).Count -eq 0)) ("2 lecteurs avec une CPS chacun : " + @($mm.Cps).Count + " CPS distinctes (chaque lecteur compte une fois)")
$mm = Get-ScinfoMulti -Text "--- Lecteur: A 1 0`r`n--- Carte: CPS`r`n--- Lecteur: A 1 0`r`n--- Carte: CPS`r`n--- Lecteur: B 2 0`r`n--- Carte: Vitale"
Check ((@($mm.Cps).Count -eq 1) -and (@($mm.Vitale).Count -eq 1)) "1 CPS et 1 Vitale : aucune alerte (lecteur liste deux fois = une seule CPS)"
# DMP Connect : Efficience "Lecteurs de cartes introuvables" (CABINET 05/10) -> lignes de log a detecter ; lignes banales -> rien
$h = @(Get-DmpPcscHits @("261005:104045 [247] [E] Failed to get the list of connected PC/SC readers. Error #2", "x getPcscResourcesList failed", "INFO : Synchronization using DmpConnect NTP client legacy failed:", "[E] [UNHDLEX] Poco exception: SSL connection unexpectedly closed"))
Check ($h.Count -eq 2) ("DMP PC/SC : " + $h.Count + " ligne(s) detectee(s) sur 4 (attendu 2)")
exit $(if ($fail) { 1 } else { 0 })
