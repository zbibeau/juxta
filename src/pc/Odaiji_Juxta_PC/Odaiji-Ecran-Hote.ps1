# Odaiji-Ecran-Hote.ps1 - charge par Install-OdaijiJuxta.ps1 et Depannage.ps1 UNIQUEMENT quand la fenetre (Odaiji-Ecran.ps1) les pilote
# (variable d'environnement ODAIJI_GUI=1). Les questions Read-Host du script deviennent des lignes "@@ASK|<question>" sur la sortie standard ;
# la fenetre affiche la question et renvoie la reponse sur l'entree standard. Sans fenetre, ce fichier n'est jamais charge : rien ne change.
function Read-Host {
    param([Parameter(Position = 0)][string]$Prompt, [switch]$AsSecureString)
    $q = ($Prompt -replace '[\r\n]+', ' ').Trim()
    [Console]::Out.WriteLine('@@ASK|' + $q)
    [Console]::Out.Flush()
    $l = [Console]::In.ReadLine()
    if ($null -eq $l) { $l = '' }
    return $l
}
