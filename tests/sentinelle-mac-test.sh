#!/bin/bash
# Tests de la sentinelle Mac : resume des rapports (bash == parseur python sur le corpus reel), decision d'envoi, flux complet avec faux diag + faux serveur.
cd "$(dirname "$0")/.." || exit 1
MAC="${KIT_MAC:-$PWD/src/mac/Odaiji_Juxta_Mac}"
T=$(mktemp -d); PORT=$((50000 + RANDOM % 10000)); FAIL=0
ok() { if [ "$1" = 1 ]; then echo "  ok   $2"; else echo "  ECHEC $2"; FAIL=1; fi; }
echo "== 13. Sentinelle Mac"
. "$MAC/odaiji-commun.sh"
# a. oj_resume == rapport_parse.py (rapports Mac du corpus)
N=0; BAD=0
for f in tests/corpus/real/*MAC-*.txt; do
    case "$f" in *Depannage*|*Installation*) continue;; esac
    got=$(oj_resume "$f")
    exp=$(python3 - "$f" <<'PY'
import sys; sys.path.insert(0,'outils'); from rapport_parse import parse
f=sys.argv[1]; d=parse(open(f,encoding='utf-8').read(),f.split('/')[-1])
print('%s|%s|%s' % (d['scenario'] or '', ','.join(sorted({c['code'] for c in d['constats'] if c['niveau']=='KO'})), ','.join(sorted({c['code'] for c in d['constats'] if c['niveau']=='WARN'}))))
PY
)
    N=$((N+1)); [ "$got" = "$exp" ] || { BAD=$((BAD+1)); echo "  DIFF $f"; }
done
ok $([ $BAD = 0 ] && [ $N -ge 5 ] && echo 1 || echo 0) "resume bash identique au parseur python ($N rapports Mac, $BAD ecart)"
# b. decision
E="$T/etat"; printf 'scenario=OK\ncodes=A,B\ndernier_rapport_ts=%s\n' "$(( 1790000000 - 2*86400 ))" > "$E"; NOW=1790000000
oj_decision /nonexistent OK "A" $NOW; D1="$OJ_RAISON"
oj_decision "$E" OK "A,B" $NOW; D2="$OJ_RAISON"
oj_decision "$E" OK "A,B,C" $NOW; D3="$OJ_RAISON"
oj_decision "$E" SESAM "A" $NOW; D4="$OJ_RAISON"
printf 'scenario=OK\ncodes=A,B\ndernier_rapport_ts=%s\n' "$(( NOW - 9*86400 ))" > "$E"; oj_decision "$E" OK "A" $NOW; D5="$OJ_RAISON"
ok $([ "$D1|$D2|$D3|$D4|$D5" = "premier passage|inchange|nouveau constat C|scenario OK -> SESAM|rapport hebdomadaire" ] && echo 1 || echo 0) "decision : premier passage / inchange / nouveau constat / scenario / hebdomadaire"
ok $(oj_version_gt 1.1.0 1.0.3 && ! oj_version_gt 1.0.3 1.0.3 && ! oj_version_gt 1.0.2 1.0.10 && echo 1 || echo 0) "comparaison de versions"
# b2. delta Avant / Apres
printf 'Scenario : X\nConstats :\n           A_KO   KO   x\n           B_W    WARN x\n\n' > "$T/av.txt"; printf 'Scenario : X\nConstats :\n           B_W    WARN x\n           C_KO   KO   x\n\n' > "$T/ap.txt"
DL=$(oj_delta "$T/av.txt" "$T/ap.txt" | tr '\n' '|')
ok $(case "$DL" in *"Corriges : A_KO"*"Restent  : B_W"*"Nouveaux : C_KO"*) echo 1;; *) echo 0;; esac) "delta Avant / Apres : corriges A_KO, restent B_W, nouveaux C_KO"
# c. flux complet
export OJ_SYSDIR="$T/sys" OJ_HOMEDIR="$T/home" ODAIJI_URL="http://127.0.0.1:$PORT/f" ODAIJI_VERSION_URL="http://127.0.0.1:$PORT/version.json" HOME="$T/h"; mkdir -p "$HOME"
cat > "$T/fakediag.sh" <<'FD'
#!/bin/bash
mkdir -p "$ODAIJI_REPORT_DIR"; cp "$FAKE_REPORT" "$ODAIJI_REPORT_DIR/Sentinelle_MAC-TEST_$(date +%Y%m%d%H%M%S).txt"; sleep 1
FD
export ODAIJI_DIAG="$T/fakediag.sh"
python3 tests/envoi-server.py $PORT "$T" & SP=$!; sleep 1; echo 200 > "$T/mode"
cp "$MAC/sentinelle.sh" "$MAC/odaiji-commun.sh" "$MAC/OdaijiJuxta-Mac.sh" "$T/"
export FAKE_REPORT="$PWD/$(ls tests/corpus/real/Avant_MAC-*.txt | head -1)"
S() { bash "$T/sentinelle.sh" "$@" >/dev/null 2>&1; }; n() { wc -l < "$T/requetes.jsonl" 2>/dev/null | tr -d ' '; }
S --force; ok $([ "$(n)" = 2 ] && echo 1 || echo 0) "1er passage : battement + rapport complet (2 envois)"
ok $(python3 -c "import json;l=[json.loads(x)['corps'] for x in open('$T/requetes.jsonl')];b=[x for x in l if x.get('type')=='battement'][0];c=json.loads(b['rapport']);print(1 if c['leger'] and c['kit'] and isinstance(c['ko'],list) and isinstance(c['warn'],list) and 'retard' in c else 0)") "le battement contient scenario, ko, warn, version (JSON imbrique valide)"
S; ok $([ "$(n)" = 2 ] && echo 1 || echo 0) "relance < 20 h : rien n'est envoye"
S --force; ok $([ "$(n)" = 3 ] && echo 1 || echo 0) "2e passage, etat inchange : battement seul"
touch "$T/sys/sentinelle.off"; S --force; ok $([ "$(n)" = 3 ] && echo 1 || echo 0) "sentinelle.off : aucun envoi"; rm "$T/sys/sentinelle.off"
sed "s/^Constats :\$/Constats :\n           CODE_NOUVEAU          KO    nouveau/" "$FAKE_REPORT" > "$T/r2.txt"; export FAKE_REPORT="$T/r2.txt"; S --force
ok $([ "$(n)" -ge 5 ] && echo 1 || echo 0) "etat different : rapport complet renvoye"
ok $([ "$(ls "$T/sys/sentinelle"/Sentinelle_*.txt | wc -l | tr -d ' ')" -le 3 ] && echo 1 || echo 0) "menage : 3 rapports locaux au plus"
kill $SP 2>/dev/null; rm -rf "$T"; exit $FAIL
