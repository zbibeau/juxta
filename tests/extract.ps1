# Extrait les fonctions REELLES du kit (pas de copie) : renvoie le texte ; l'appelant fait :  . ([scriptblock]::Create((Get-KitFunction <fichier> <nom>)))
function Get-KitFunction { param([string]$File, [string]$Name)
    $t = (Get-Content $File -Raw) -replace "`r`n", "`n"
    $m = [regex]::Match($t, "(?ms)^function " + [regex]::Escape($Name) + " .*?^\}\s*$")
    if (-not $m.Success) { throw ("fonction introuvable : " + $Name + " dans " + $File) }
    return $m.Value
}
