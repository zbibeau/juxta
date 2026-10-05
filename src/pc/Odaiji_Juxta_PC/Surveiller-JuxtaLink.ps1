<#
 Surveiller-JuxtaLink.ps1 - MadeForMed / Odaiji - v1.0 (28/09/2026)
 Pour les postes ou "JuxtaLink est injoignable par moment" (poste 28/09, Weda/Vitalzen + Sophos).
 Toutes les 20 s pendant 8 h (par defaut) : JuxtaLink tourne-t-il (et avec quel PID : un changement = redemarrage),
 qui tient le port 1234, JuxtaLink repond-il en HTTPS (et en combien de temps), processus Weda/Vitalzen/antivirus.
 N'ecrit QUE les changements d'etat et les lenteurs dans Bureau\Surveillance-JuxtaLink_<poste>_<date>.txt.
 Ne modifie rien. Fermer la fenetre pour arreter. Laisser le PC travailler normalement pendant ce temps.
#>
param([int]$Heures = 8, [int]$Pas = 20, [int]$Port = 1234)
$Desk = [Environment]::GetFolderPath("Desktop")
$Log = Join-Path $Desk ("Surveillance-JuxtaLink_" + $env:COMPUTERNAME + "_" + (Get-Date -Format "yyyyMMdd-HHmm") + ".txt")
function L { param($t) $l = (Get-Date -Format "dd/MM HH:mm:ss") + "  " + $t; Write-Host $l; Add-Content -Path $Log -Value $l -Encoding UTF8 }
try { [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } } catch {}
try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 } catch {}
L ("Debut surveillance JuxtaLink sur " + $env:COMPUTERNAME + " (port " + $Port + ", toutes les " + $Pas + " s, " + $Heures + " h). Fenetre a laisser ouverte.")
$fin = (Get-Date).AddHours($Heures); $prev = ""; $nOk = 0; $nKo = 0
while ((Get-Date) -lt $fin) {
    $jx = @(Get-Process JuxtaLink -ErrorAction SilentlyContinue)
    $pidJx = if ($jx) { ($jx | ForEach-Object Id) -join "," } else { "-" }
    $own = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | ForEach-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName } | Select-Object -Unique) -join ","
    if (-not $own) { $own = "personne" }
    $rep = "KO"; $ms = 0
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try { $r = [Net.HttpWebRequest]::Create("https://localhost:$Port/"); $r.Timeout = 8000; $resp = $r.GetResponse(); $resp.Close(); $rep = "OK" }
    catch [Net.WebException] { if ($_.Exception.Response) { $rep = "OK" } else { $rep = "KO (" + $_.Exception.Status + ")" } }
    catch { $rep = "KO (" + $_.Exception.Message + ")" }
    $ms = $sw.ElapsedMilliseconds
    $autres = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'vitalzen|weda|pyxvital' -or ($(try { $_.Path } catch { "" }) -match 'vitalzen|weda|pyxvital') } | ForEach-Object ProcessName | Select-Object -Unique) -join ","
    $etat = "JuxtaLink PID " + $pidJx + " | port " + $Port + " tenu par " + $own + " | reponse " + $rep + " | Weda/Vitalzen/Pyxvital : " + $(if ($autres) { $autres } else { "aucun" })
    if ($rep -eq "OK") { $nOk++ } else { $nKo++ }
    if ($etat -ne $prev) { L ("CHANGEMENT : " + $etat + " (" + $ms + " ms)"); $prev = $etat }
    elseif ($ms -gt 3000) { L ("LENT : reponse en " + $ms + " ms") }
    Start-Sleep -Seconds $Pas
}
L ("Fin : " + $nOk + " controles OK, " + $nKo + " KO. Envoyer ce fichier dans le channel Claude.")
Read-Host "Entree pour fermer"
