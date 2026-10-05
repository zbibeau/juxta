param([string]$File)
$e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile($File, [ref]$null, [ref]$e); $e.Count
