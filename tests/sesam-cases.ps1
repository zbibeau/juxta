# Cas de sesam.ini : chaque poste vu sur le terrain devient un cas permanent. Ajouter un cas = ajouter une ligne a $cases.
param([string]$Kit)
. (Join-Path $PSScriptRoot "extract.ps1")
$ps = Join-Path $Kit "OdaijiJuxta.ps1"
. ([scriptblock]::Create((Get-KitFunction $ps "Get-SesamIniState")))
. ([scriptblock]::Create((Get-KitFunction $ps "Set-SesamKey")))
$fail = 0
function Check { param($ok, $msg) if ($ok) { Write-Host ("  ok   " + $msg) } else { Write-Host ("  ECHEC " + $msg) -ForegroundColor Red; $script:fail++ } }
$pd = "C:\ProgramData\santesocial\fsv\1.40.14"; $ssv = "C:\Program Files (x86)\santesocial\fsv\1.40.14\ssv"
$presents = @("$pd\conf\log4crc.xml", $ssv)
$ex = { param($p) $presents -contains $p }

# nom ; lignes du sesam.ini ; MgcOk attendu ; SsvOk attendu
$cases = @(
  @("complet (genere par le kit)", @("[COMMUN]","RepertoireTable=$ssv","[SSV]","RepertoireTable=$ssv","[MGC]","RepertoireConfigTrace=$pd\conf"), $true, $true),
  @("PC26-FILLATRE 05/10 : ProgramData ecrit par le MSI x64, sans cle [SSV] RepertoireTable", @("[COMMUN]","RepertoireTravail=$pd\adm","[MGC]","RepertoireConfigTrace=$pd\conf","[SSV]","tempoexclusivite=500"), $true, $false),
  @("PC26-FILLATRE 05/10 : [SSV] absent, [MGC] absent", @("[COMMUN]","RepertoireTravail=$pd\adm"), $false, $false),
  @("29/09 : chemin SSV x86 inexistant (existe seulement en x64)", @("[SSV]","RepertoireTable=C:\Program Files (x86)\santesocial\fsv\1.40.14\ssvX","[MGC]","RepertoireConfigTrace=$pd\conf"), $true, $false),
  @("Dr Plongeron 29/09 : [MGC] absent, tables OK", @("[SSV]","RepertoireTable=$ssv"), $false, $true),
  @("casse differente des sections et des cles", @("[ssv]","repertoiretable=$ssv","[mgc]","repertoireconfigtrace=$pd\conf"), $true, $true),
  @("fichier vide", @(), $false, $false)
)
foreach ($c in $cases) {
    $st = Get-SesamIniState -Lines $c[1] -Exists $ex
    Check (($st.MgcOk -eq $c[2]) -and ($st.SsvOk -eq $c[3])) ($c[0] + "  (Mgc=" + $st.MgcOk + " Ssv=" + $st.SsvOk + ")")
}

# Reparation : Set-SesamKey pose la cle sans casser le reste, et le diag la voit ensuite
$tmp = Join-Path ([IO.Path]::GetTempPath()) "sesam-test.ini"
foreach ($c in $cases) {
    [IO.File]::WriteAllText($tmp, (($c[1] -join "`r`n") + "`r`n"))
    Set-SesamKey $tmp "SSV" "RepertoireTable" $ssv
    $st = Get-SesamIniState -Lines @(Get-Content $tmp) -Exists $ex
    Check ($st.SsvOk) ("reparation : " + $c[0])
    if ($c[2]) { Check ($st.MgcOk) ("reparation sans effet de bord sur [MGC] : " + $c[0]) }
}
# idempotence : deux poses = une seule cle
[IO.File]::WriteAllText($tmp, "[SSV]`r`na=1`r`n")
Set-SesamKey $tmp "SSV" "RepertoireTable" $ssv; Set-SesamKey $tmp "SSV" "RepertoireTable" $ssv
Check ((@(Get-Content $tmp | Where-Object { $_ -match '^RepertoireTable=' }).Count -eq 1)) "idempotence de Set-SesamKey"
Remove-Item $tmp -ErrorAction SilentlyContinue
if ($fail) { Write-Host ("$fail echec(s)") -ForegroundColor Red; exit 1 }
