#!/bin/bash
# Tests de l'envoi Mac (odaiji-commun.sh) contre un faux serveur : envoi, cle, file d'attente, reprise, refus definitif, JSON valide.
cd "$(dirname "$0")/.." || exit 1
MAC="${KIT_MAC:-$PWD/src/mac/Odaiji_Juxta_Mac}"
T=$(mktemp -d); PORT=$((30000 + RANDOM % 10000)); FAIL=0
export OJ_SYSDIR="/proc/inexistant/MadeForMed"; export OJ_HOMEDIR="$T/home"; export ODAIJI_URL="http://127.0.0.1:$PORT/f"; export HOME="$T/h"; mkdir -p "$HOME"
ok() { if [ "$1" = 1 ]; then echo "  ok   $2"; else echo "  ECHEC $2"; FAIL=1; fi; }
python3 tests/envoi-server.py $PORT "$T" & SP=$!; sleep 1
printf 'Rapport mac\nligne "q" \\ tab\there\r\nr\xe9ponse \xff fin\r\n\001ok\n' > "$T/r.txt"
echo "== 11. Envoi Mac : cle, file d'attente, reprise (faux serveur)"
mkdir -p "$T/home"
run() { bash -c ". '$MAC/odaiji-commun.sh'; $1" 2>&1 | tail -1; }
echo 200 > "$T/mode"; R=$(run "oj_envoyer_rapport '$T/r.txt' test; echo \$OJ_STATUT")
ok $([ "$R" = envoye ] && echo 1 || echo 0) "envoi nominal : envoye (profil utilisateur si le dossier systeme est ferme)"
ok $(python3 -c "import json;l=[json.loads(x) for x in open('$T/requetes.jsonl')];r=l[-1];print(1 if r['json_valide'] and r['corps']['os']=='mac' and len(r['corps']['poste_id'])>=8 and r['cle'] is None and 'ponse' in r['corps']['rapport'] and '\r' not in r['corps']['rapport'] else 0)") "JSON valide malgre CR / octets non UTF-8 ; poste_id present ; pas de cle"
mkdir -p "$T/home"; echo "kM_cle_de_test_456" > "$T/home/cle-envoi.txt"; run "oj_envoyer_rapport '$T/r.txt' test" >/dev/null
ok $(python3 -c "import json;l=[json.loads(x) for x in open('$T/requetes.jsonl')];print(1 if l[-1]['cle']=='kM_cle_de_test_456' else 0)") "la cle du cabinet part dans X-Odaiji-Key"
A=$(run "oj_poste_id"); B=$(run "oj_poste_id"); ok $([ -n "$A" ] && [ "$A" = "$B" ] && echo 1 || echo 0) "identifiant de poste stable"
echo 500 > "$T/mode"; R=$(run "oj_envoyer_rapport '$T/r.txt' horsligne; echo \$OJ_STATUT")
ok $([ "$R" = differe ] && [ "$(ls "$T/home/spool" | wc -l | tr -d ' ')" = 1 ] && echo 1 || echo 0) "serveur en panne : file d'attente"
echo 200 > "$T/mode"; R=$(run "oj_envoyer_rapport '$T/r.txt' retour; echo \$OJ_STATUT")
ok $([ "$R" = envoye ] && [ "$(ls "$T/home/spool" | wc -l | tr -d ' ')" = 0 ] && echo 1 || echo 0) "retour du serveur : la file d'attente est videe"
echo 401 > "$T/mode"; R=$(run "oj_envoyer_rapport '$T/r.txt' refus; echo \$OJ_STATUT")
ok $([ "$R" = refuse ] && [ "$(ls "$T/home/spool" 2>/dev/null | wc -l | tr -d ' ')" = 0 ] && echo 1 || echo 0) "cle refusee (401) : pas de file d'attente"
echo 200 > "$T/mode"; run "oj_battement '{\"scenario\":\"OK\",\"codes\":[\"A\"]}'" >/dev/null
ok $(python3 -c "import json;l=[json.loads(x) for x in open('$T/requetes.jsonl')];r=l[-1]['corps'];print(1 if r['type']=='battement' and json.loads(r['rapport'])['scenario']=='OK' else 0)") "battement : JSON imbrique valide"
kill $SP 2>/dev/null; chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"; exit $FAIL
