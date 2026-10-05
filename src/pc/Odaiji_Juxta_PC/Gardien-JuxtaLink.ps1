<#
 Gardien-JuxtaLink.ps1 - MadeForMed / Odaiji - v1.0 (04/10/2026)
 Veille de JuxtaLink : lance par la tache planifiee \Odaiji\Gardien-JuxtaLink (compte SYSTEM) toutes les 10 min.
 Si JuxtaLink est arrete (quelqu'un l'a ferme, il a plante), il est relance via la tache \Odaiji\JuxtaLink
 (session du medecin, sans UAC). Si JuxtaLink tourne mais que le port 1234 ne repond pas 2 veilles de suite, il est relance.
 Garde-fous : rien si personne n'est connecte ; rien pendant une installation Windows (MSI) ni pendant un outil du kit
 (installation, depannage, reparation) ; au plus 3 relances en 30 min (au-dela : note "BOUCLE" dans le journal et on
 laisse le poste tranquille, un vrai probleme se voit au lieu d'etre masque).
 Journal : C:\ProgramData\MadeForMed\Gardien\gardien.log (a envoyer avec les rapports si besoin).
 Retrait : Demarrage-JuxtaLink.bat -Retirer (ou -Retirer depuis la ligne de commande).
#>
param([int]$Port = 1234, [int]$MaxRelances = 3, [int]$FenetreMin = 30)
$ErrorActionPreference = "SilentlyContinue"
$Dir = "C:\ProgramData\MadeForMed\Gardien"; New-Item -ItemType Directory -Force $Dir | Out-Null
$Log = Join-Path $Dir "gardien.log"; $State = Join-Path $Dir "etat.json"
function L { param($t)
    Add-Content -Path $Log -Value ((Get-Date -Format "dd/MM/yyyy HH:mm:ss") + "  " + $t) -Encoding UTF8
    try { if ((Get-Item $Log).Length -gt 200KB) { $c = Get-Content $Log -Tail 400; Set-Content $Log $c -Encoding UTF8 } } catch {}
}
$st = $null; try { $st = Get-Content $State -Raw | ConvertFrom-Json } catch {}
$relances = @(); $portKo = 0
if ($st) { try { $relances = @($st.relances | Where-Object { $_ }); $portKo = [int]$st.portKo } catch {} }
function Save { Set-Content -Path $State -Value (@{ relances = @($relances); portKo = $portKo } | ConvertTo-Json) -Encoding ASCII }

# Personne de connecte : rien a faire (JuxtaLink se lance dans la session du medecin)
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { exit 0 }
# Installation Windows en cours
$busy = $false; try { $m = [Threading.Mutex]::OpenExisting("Global\_MSIExecute"); $m.Dispose(); $busy = $true } catch {}
if ($busy) { exit 0 }
# Un outil du kit tourne (il arrete et relance JuxtaLink lui-meme)
$outil = Get-CimInstance Win32_Process -Filter "name='powershell.exe' or name='pwsh.exe'" | Where-Object { $_.CommandLine -match 'Install-OdaijiJuxta|Depannage\.ps1|OdaijiJuxta\.ps1|SansGalss|Neutraliser|Nettoyage|Autoriser-Odaiji' } | Select-Object -First 1
if ($outil) { exit 0 }

$jx = @(Get-Process JuxtaLink -ErrorAction SilentlyContinue)
$ecoute = [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
if ($jx.Count -and $ecoute) { if ($portKo -ne 0 -or $relances.Count) { $portKo = 0; Save }; exit 0 }

if ($jx.Count -and -not $ecoute) {
    # JuxtaLink tourne mais le port ne repond pas : on laisse une veille de grace (il demarre peut-etre)
    $portKo++; Save
    if ($portKo -lt 2) { L ("JuxtaLink tourne mais le port " + $Port + " ne repond pas (veille 1/2, on attend)"); exit 0 }
    $raison = "JuxtaLink bloque (port " + $Port + " muet depuis 2 veilles)"
} else { $raison = "JuxtaLink arrete" }

# Garde-fou anti-boucle
$limite = (Get-Date).AddMinutes(-$FenetreMin)
$relances = @($relances | Where-Object { try { [datetime]$_ -gt $limite } catch { $false } })
if ($relances.Count -ge $MaxRelances) { L ("BOUCLE : " + $raison + ", mais " + $relances.Count + " relances deja faites en " + $FenetreMin + " min : on ne relance plus (envoyer ce journal)"); Save; exit 0 }

if ($jx.Count) { $jx | Stop-Process -Force; Start-Sleep 2 }
$t = Get-ScheduledTask -TaskPath "\Odaiji\" -TaskName "JuxtaLink"
if (-not $t) { L ($raison + " : tache \Odaiji\JuxtaLink absente, relance impossible (lancer 2-Depanner.bat)"); exit 0 }
Start-ScheduledTask -TaskPath "\Odaiji\" -TaskName "JuxtaLink"
Start-Sleep 10
$relances += (Get-Date).ToString("s"); $portKo = 0; Save
if (Get-Process JuxtaLink -ErrorAction SilentlyContinue) { L ($raison + " -> JuxtaLink relance (" + $relances.Count + "/" + $MaxRelances + " sur " + $FenetreMin + " min)") }
else { L ($raison + " -> relance demandee mais JuxtaLink ne tourne toujours pas") }
