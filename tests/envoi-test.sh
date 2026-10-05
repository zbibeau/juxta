#!/bin/bash
# Tests de l'envoi PC (Odaiji-Commun.ps1) contre un faux serveur : envoi, cle, file d'attente, reprise, refus definitif.
cd "$(dirname "$0")/.." || exit 1
PC="${KIT_PC:-$PWD/src/pc/Odaiji_Juxta_PC}"; PWSH=$(command -v pwsh || echo /tmp/w/psh/pwsh)
T=$(mktemp -d); PORT=$((20000 + RANDOM % 10000)); FAIL=0
export ProgramData="$T/pd"; export TEMP="$T/tmp"; mkdir -p "$ProgramData" "$TEMP"; export ODAIJI_URL="http://127.0.0.1:$PORT/f"; export COMPUTERNAME=POSTE-TEST
ok() { if [ "$1" = 1 ]; then echo "  ok   $2"; else echo "  ECHEC $2"; FAIL=1; fi; }
python3 tests/envoi-server.py $PORT "$T" & SP=$!; sleep 1
printf 'Rapport de test\nligne "guillemets" \\ tab\there\r\nfin\n' > "$T/r.txt"
run() { "$PWSH" -NoProfile -Command ". '$PC/Odaiji-Commun.ps1'; $1" 2>&1 | tail -1; }
echo "== 10. Envoi PC : cle, file d'attente, reprise (faux serveur)"
echo 200 > "$T/mode"
R=$(run "(Send-OjRapport -Fichier '$T/r.txt' -Raison 'test').statut"); ok $([ "$R" = envoye ] && echo 1 || echo 0) "envoi nominal : envoye"
ok $(python3 -c "import json;l=[json.loads(x) for x in open('$T/requetes.jsonl')];r=l[-1];print(1 if r['json_valide'] and r['corps']['poste']=='POSTE-TEST' and len(r['corps']['poste_id'])>=8 and r['cle'] is None else 0)") "JSON valide, poste et poste_id presents, pas de cle"
echo "kA_cle_de_test_123" > "$T/pd/MadeForMed/cle-envoi.txt"; run "(Send-OjRapport -Fichier '$T/r.txt' -Raison 'test').statut" >/dev/null
ok $(python3 -c "import json;l=[json.loads(x) for x in open('$T/requetes.jsonl')];print(1 if l[-1]['cle']=='kA_cle_de_test_123' else 0)") "la cle du cabinet part dans l'en-tete X-Odaiji-Key"
P1=$("$PWSH" -NoProfile -Command ". '$PC/Odaiji-Commun.ps1'; Get-PosteId"); P2=$("$PWSH" -NoProfile -Command ". '$PC/Odaiji-Commun.ps1'; Get-PosteId")
ok $([ -n "$P1" ] && [ "$P1" = "$P2" ] && echo 1 || echo 0) "identifiant de poste stable entre deux passages"
echo 500 > "$T/mode"; R=$(run "(Send-OjRapport -Fichier '$T/r.txt' -Raison 'hors-ligne').statut")
ok $([ "$R" = differe ] && [ "$(ls "$T/pd/MadeForMed/spool" | wc -l)" = 1 ] && echo 1 || echo 0) "serveur en panne : rapport mis en file d'attente"
echo 200 > "$T/mode"; R=$(run "(Send-OjRapport -Fichier '$T/r.txt' -Raison 'retour').statut"); N=$(ls "$T/pd/MadeForMed/spool" | wc -l)
ok $([ "$R" = envoye ] && [ "$N" = 0 ] && echo 1 || echo 0) "serveur de retour : le nouvel envoi vide aussi la file d'attente"
echo 401 > "$T/mode"; R=$(run "(Send-OjRapport -Fichier '$T/r.txt' -Raison 'cle-refusee').statut")
ok $([ "$R" = refuse ] && [ "$(ls "$T/pd/MadeForMed/spool" 2>/dev/null | wc -l)" = 0 ] && echo 1 || echo 0) "cle refusee (401) : pas de file d'attente (echec definitif)"
echo 200 > "$T/mode"; R=$(run "(Send-OjBattement -Corps '{\"scenario\":\"OK\"}').statut")
ok $(python3 -c "import json;l=[json.loads(x) for x in open('$T/requetes.jsonl')];print(1 if l[-1]['corps']['type']=='battement' else 0)") "battement : type battement envoye"
kill $SP 2>/dev/null; rm -rf "$T"; exit $FAIL
