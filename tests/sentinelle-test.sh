#!/bin/bash
# Tests de la sentinelle PC : resume des rapports (pwsh == parseur python sur le corpus reel), decision d'envoi, flux complet avec faux diag + faux serveur.
cd "$(dirname "$0")/.." || exit 1
PC="${KIT_PC:-$PWD/src/pc/Odaiji_Juxta_PC}"; PWSH=$(command -v pwsh || echo /tmp/w/psh/pwsh)
T=$(mktemp -d); PORT=$((40000 + RANDOM % 10000)); FAIL=0
ok() { if [ "$1" = 1 ]; then echo "  ok   $2"; else echo "  ECHEC $2"; FAIL=1; fi; }
echo "== 12. Sentinelle PC"
# a. Get-RapportResume (PowerShell) == rapport_parse.py sur tous les rapports PC du corpus
"$PWSH" -NoProfile -Command ". '$PC/Odaiji-Commun.ps1'; Get-ChildItem 'tests/corpus/real' -Filter *.txt | Where-Object { \$_.Name -notmatch '^(Depannage|Installation)' } | ForEach-Object { \$r = Get-RapportResume ([IO.File]::ReadAllText(\$_.FullName)); \$_.Name + '|' + \$r.scenario + '|' + ((\$r.constats | ForEach-Object { \$_.code + ':' + \$_.niveau }) -join ',') }" > "$T/ps.txt" 2>"$T/ps.err"
python3 - "$T/ps.txt" <<'PY' > "$T/cmp.txt"
import sys, os, glob
sys.path.insert(0, 'outils'); from rapport_parse import parse
bad = 0; n = 0
for l in open(sys.argv[1], encoding='utf-8'):
    nom, sc, cs = l.rstrip('\n').split('|', 2); t = open('tests/corpus/real/' + nom, encoding='utf-8').read(); d = parse(t, nom)
    exp = ','.join('%s:%s' % (c['code'], c['niveau']) for c in d['constats']); n += 1
    if (sc or None) != d['scenario'] or cs != exp: bad += 1; print('DIFF', nom)
print('N', n, 'BAD', bad)
PY
tail -1 "$T/cmp.txt" | grep -q "BAD 0" && grep -qE "N [1-9][0-9]+" "$T/cmp.txt"; ok $([ $? = 0 ] && echo 1 || echo 0) "resume PowerShell identique au parseur python ($(tail -1 "$T/cmp.txt"))"
# b. decision d'envoi
D=$("$PWSH" -NoProfile -Command ". '$PC/Odaiji-Commun.ps1'; \$now=[datetime]'2026-10-06'; \$e=[pscustomobject]@{codes=@('A','B');scenario='OK';dernier_rapport='2026-10-04'}
(Get-DecisionEnvoi \$null 'OK' @('A') \$now).raison
(Get-DecisionEnvoi \$e 'OK' @('A','B') \$now).raison
(Get-DecisionEnvoi \$e 'OK' @('A','B','C') \$now).raison
(Get-DecisionEnvoi \$e 'SESAM' @('A') \$now).raison
\$e.dernier_rapport='2026-09-20'; (Get-DecisionEnvoi \$e 'OK' @('A') \$now).raison" | tr '\n' '|')
ok $([ "$D" = "premier passage|inchange|nouveau constat C|scenario OK -> SESAM|rapport hebdomadaire|" ] && echo 1 || echo 0) "decision : premier passage / inchange / nouveau constat / scenario / hebdomadaire ($D)"
# b2. delta Avant / Apres
DL=$("$PWSH" -NoProfile -Command ". '$PC/Odaiji-Commun.ps1'; \$a=@{constats=@(@{code='A';niveau='KO'},@{code='B';niveau='WARN'},@{code='I';niveau='INFO'})}; \$b=@{constats=@(@{code='B';niveau='WARN'},@{code='C';niveau='KO'})}; \$d=Compare-Constats \$a \$b; (\$d.corriges -join ',') + '|' + (\$d.restent -join ',') + '|' + (\$d.nouveaux -join ',')")
ok $([ "$DL" = "A|B|C" ] && echo 1 || echo 0) "delta Avant / Apres : corriges A, restent B, nouveaux C (INFO ignore) ($DL)"
# c. flux complet : faux diag (copie un rapport du corpus) + faux serveur
export ProgramData="$T/pd"; export TEMP="$T/tmp"; mkdir -p "$ProgramData" "$TEMP"; export ODAIJI_URL="http://127.0.0.1:$PORT/f"; export COMPUTERNAME=POSTE-TEST
cat > "$T/fakediag.ps1" <<'FD'
param([switch]$Leger,[switch]$NoPause,[string]$Prefix)
$d = Join-Path $env:ProgramData "MadeForMed\sentinelle"; New-Item -ItemType Directory -Force $d | Out-Null
Copy-Item $env:FAKE_REPORT (Join-Path $d ("Sentinelle_POSTE-TEST_" + (Get-Date -Format "yyyyMMddHHmmss") + ".txt"))
FD
export ODAIJI_DIAG="$T/fakediag.ps1" ODAIJI_POWERSHELL="$PWSH" ODAIJI_VERSION_URL="http://127.0.0.1:$PORT/version.json"
python3 tests/envoi-server.py $PORT "$T" & SP=$!; sleep 1; echo 200 > "$T/mode"
R1=$(ls tests/corpus/real/Avant_POSTE-0[0-9]_2026100[1-5]*.txt | head -1); export FAKE_REPORT="$PWD/$R1"
cp "$PC/Sentinelle.ps1" "$PC/Odaiji-Commun.ps1" "$T/"
S() { "$PWSH" -NoProfile -File "$T/Sentinelle.ps1" "$@" >/dev/null 2>&1; }
n() { wc -l < "$T/requetes.jsonl" | tr -d ' '; }
S -Force; ok $([ "$(n)" = 2 ] && echo 1 || echo 0) "1er passage : battement + rapport complet (2 envois)"
ok $(python3 -c "import json;l=[json.loads(x)['corps'] for x in open('$T/requetes.jsonl')];b=[x for x in l if x.get('type')=='battement'][0];c=json.loads(b['rapport']);print(1 if c['leger'] and c['kit'] and 'ko' in c and 'warn' in c else 0)") "le battement contient scenario, ko, warn, version"
S; ok $([ "$(n)" = 2 ] && echo 1 || echo 0) "relance < 20 h : rien n'est envoye"
S -Force; ok $([ "$(n)" = 3 ] && echo 1 || echo 0) "2e passage, etat inchange : battement seul (1 envoi de plus)"
touch "$T/pd/MadeForMed/sentinelle.off"; S -Force; ok $([ "$(n)" = 3 ] && echo 1 || echo 0) "sentinelle.off : aucun envoi"
rm "$T/pd/MadeForMed/sentinelle.off"
sed "s/^Constats :\$/Constats :\n           CODE_NOUVEAU          KO    nouveau/" "$FAKE_REPORT" > "$T/r2.txt"; export FAKE_REPORT="$T/r2.txt"; S -Force
ok $([ "$(n)" -ge 5 ] && echo 1 || echo 0) "etat different : rapport complet renvoye"
ok $([ "$(ls "$T/pd/MadeForMed/sentinelle"/Sentinelle_*.txt | wc -l | tr -d ' ')" -le 3 ] && echo 1 || echo 0) "menage : 3 rapports locaux au plus"
kill $SP 2>/dev/null; rm -rf "$T"; exit $FAIL
