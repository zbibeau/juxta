# Cas de sesam.ini : chaque poste vu sur le terrain devient un cas permanent. Ajouter un cas = ajouter une ligne a $cases.
param([string]$Kit)
. (Join-Path $PSScriptRoot "extract.ps1")
$ps = Join-Path $Kit "OdaijiJuxta.ps1"
. ([scriptblock]::Create((Get-KitFunction $ps "Get-SesamIniState")))
. ([scriptblock]::Create((Get-KitFunction $ps "Set-SesamKey")))
. ([scriptblock]::Create((Get-KitFunction $ps "Get-TableMissing")))
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
# DMP Connect : Efficience "Lecteurs de cartes introuvables" (CABINET 05/10) -> lignes de log a detecter ; lignes banales -> rien
$h = @(Get-DmpPcscHits @("261005:104045 [247] [E] Failed to get the list of connected PC/SC readers. Error #2", "x getPcscResourcesList failed", "INFO : Synchronization using DmpConnect NTP client legacy failed:", "[E] [UNHDLEX] Poco exception: SSL connection unexpectedly closed"))
Check ($h.Count -eq 2) ("DMP PC/SC : " + $h.Count + " ligne(s) detectee(s) sur 4 (attendu 2)")
exit $(if ($fail) { 1 } else { 0 })
