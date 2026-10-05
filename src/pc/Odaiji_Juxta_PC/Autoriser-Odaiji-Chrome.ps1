<#
 Autoriser Odaiji a joindre JuxtaLink (localhost) dans Chrome, Edge et Firefox - Local Network Access
 MadeForMed / Odaiji - v1.1 (24/09/2026) : ajout Firefox (politique LocalNetworkAccess.SkipDomains, Firefox 145+)
 Remplace la manipulation chrome://flags "Local Network Access Checks = Disabled".
 Ecrit les politiques LocalNetworkAccessAllowedForUrls (Chrome 140-145) et LocalNetworkAllowedForUrls
 (Chrome 146+) pour Chrome et Edge, dans HKLM (tous les utilisateurs). Aucune protection desactivee :
 seuls les sites Odaiji sont autorises a appeler le reseau local. Les navigateurs doivent etre relances.
#>
param([string[]]$Origins = @("https://app.odaiji.co","https://[*.]odaiji.co","https://[*.]madeformed.fr","https://[*.]juxta.cloud"),
      [string[]]$FirefoxDomains = @("app.odaiji.co","*.odaiji.co","*.madeformed.fr","*.juxta.cloud","localhost","127.0.0.1"), [switch]$Remove, [switch]$NoPause)
trap { Write-Host ("`nERREUR : " + $_.Exception.Message) -ForegroundColor Red; Write-Host ($_.InvocationInfo.PositionMessage) -ForegroundColor DarkGray; Read-Host "Envoyer cette capture dans le channel Claude. Entree pour fermer"; exit 1 }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { $a=@("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`""); if ($Remove){$a+="-Remove"}; Start-Process powershell.exe -Verb RunAs -ArgumentList $a; exit }
$targets = @("HKLM:\SOFTWARE\Policies\Google\Chrome","HKLM:\SOFTWARE\Policies\Microsoft\Edge")
$keys = @("LocalNetworkAccessAllowedForUrls","LocalNetworkAllowedForUrls")
foreach ($t in $targets) { foreach ($k in $keys) {
    $p = Join-Path $t $k
    if ($Remove) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue; continue }
    New-Item -Path $p -Force | Out-Null
    Get-ItemProperty $p | Select-Object -ExpandProperty PSObject | Select-Object -ExpandProperty Properties | Where-Object Name -match '^\d+$' | ForEach-Object { Remove-ItemProperty $p -Name $_.Name }
    $i = 1; foreach ($o in $Origins) { New-ItemProperty -Path $p -Name $i -Value $o -PropertyType String -Force | Out-Null; $i++ }
} }
if ($Remove) { Write-Host "Politiques Local Network Access retirees (Chrome + Edge + Firefox)." -ForegroundColor Yellow }
else {
    Write-Host "Politiques ecrites pour Chrome et Edge :" -ForegroundColor Green
    foreach ($t in $targets) { $v = Get-ItemProperty (Join-Path $t $keys[0]) -ErrorAction SilentlyContinue; if ($v) { Write-Host ("  " + $t + " : " + (($v.PSObject.Properties | Where-Object Name -match '^\d+$' | ForEach-Object Value) -join ", ")) } }
    Write-Host "Pris en compte au prochain redemarrage de Chrome/Edge (inutile de le faire maintenant). Verification : chrome://policy."
}
# --- Firefox 145+ : politique LocalNetworkAccess\SkipDomains (sans toucher a Enabled / Locked)
try {
    $ffp = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\LocalNetworkAccess\SkipDomains"
    if ($Remove) { Remove-Item "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\LocalNetworkAccess" -Recurse -Force -ErrorAction SilentlyContinue }
    else {
        New-Item -Path $ffp -Force | Out-Null
        Get-ItemProperty $ffp | Select-Object -ExpandProperty PSObject | Select-Object -ExpandProperty Properties | Where-Object Name -match '^\d+$' | ForEach-Object { Remove-ItemProperty $ffp -Name $_.Name }
        $i = 1; foreach ($d in $FirefoxDomains) { New-ItemProperty -Path $ffp -Name $i -Value $d -PropertyType String -Force | Out-Null; $i++ }
        Write-Host ("Politique ecrite pour Firefox : " + ($FirefoxDomains -join ", ")) -ForegroundColor Green
        Write-Host "Pris en compte au prochain redemarrage de Firefox (inutile de le faire maintenant)."
    }
} catch { Write-Host ("Firefox : politique non ecrite (" + $_.Exception.Message + ")") -ForegroundColor Yellow }
if ($Host.Name -eq "ConsoleHost" -and -not $NoPause) { Read-Host "Entree pour fermer" }
