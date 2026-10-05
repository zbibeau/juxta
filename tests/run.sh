#!/bin/bash
# Tests du kit avant publication :  bash tests/run.sh   (depuis la racine du depot)
# Controles : syntaxe + ASCII + CRLF des .ps1, syntaxe bash des scripts Mac, cas sesam.ini (fonctions reelles), lecture des constats Mac.
cd "$(dirname "$0")/.." || exit 1
ROOT=$PWD; PC="${KIT_PC:-$ROOT/src/pc/Odaiji_Juxta_PC}"; MAC="${KIT_MAC:-$ROOT/src/mac/Odaiji_Juxta_Mac}"
PWSH=$(command -v pwsh || echo /tmp/w/psh/pwsh); FAIL=0
echo "== 1. PowerShell : syntaxe, ASCII, CRLF"
for f in "$PC"/*.ps1; do
  e=$("$PWSH" -NoProfile -File tests/parse.ps1 -File "$f" 2>&1 | tail -1)
  na=$(grep -c -P '[^\x00-\x7F]' "$f"); crlf=$(grep -c -v $'\r$' "$f")
  case "$(basename "$f")" in LISEZMOI*) na=0;; esac
  if [ "$e" != 0 ] || [ "$na" != 0 ] || [ "$crlf" != 0 ]; then echo "  ECHEC $(basename "$f") : erreurs=$e non-ASCII=$na lignes-sans-CRLF=$crlf"; FAIL=1; else echo "  ok   $(basename "$f")"; fi
done
echo "== 2. Mac : bash -n"
for f in "$MAC"/*.sh "$MAC"/*.command; do bash -n "$f" 2>/dev/null && echo "  ok   $(basename "$f")" || { echo "  ECHEC $(basename "$f")"; FAIL=1; }; done
echo "== 3. Cas sesam.ini (fonctions reelles du kit PC)"
"$PWSH" -NoProfile -File tests/sesam-cases.ps1 -Kit "$PC" || FAIL=1
echo "== 4. Mac : codes de constats lus (minuscules comprises)"
eval "$(grep -m1 '^codes_()' "$MAC/2-Depanner.command")"
C=$(codes_ tests/corpus/mac-avant-constats.txt | tr '\n' ' ')
for k in LNA_Google_Chrome DMP_MULTI GARDIEN_ABSENT VITALE_ABSENT; do case " $C" in *" $k "*) echo "  ok   $k";; *) echo "  ECHEC code non lu : $k"; FAIL=1;; esac; done
echo "== 5. Mac : le code CPS et les blobs base64 ne sortent jamais dans un rapport"
SEDM=$(grep -m1 "base64-omis" "$MAC/OdaijiJuxta-Mac.sh" | grep -oE "sed -E '[^']*'" | head -1)
B64=$(printf '{"Request":{"Parameters":{"codecps":"0000","idfacture":"1"}},"Arguments":{"diagnostic":"La facture demandee n existe pas."}}' | base64 | tr -d '\n')
OUT=$(printf '[x] Plugin execute : %s\n[y] codecps": "0000"\n' "$B64" | eval "$SEDM")
case "$OUT" in *0000*|*"$B64"*) echo "  ECHEC code CPS ou base64 visible dans l'extrait de log"; FAIL=1;; *) echo "  ok   extrait de log masque (code CPS, base64)";; esac
echo "== 6. Mac : le JSON d'envoi du rapport reste valide (CR, tabulations, guillemets, octets non UTF-8)"
JL=$(grep -m1 'JSON_TXT=' "$MAC/OdaijiJuxta-Mac.sh" | sed -e 's/^ *JSON_TXT=\$(//' -e 's/)$//' -e 's#tail -c 240000 "\$REPORT"#cat "$TJ"#')
TJ=$(mktemp); printf 'ligne "q" \\ tab\there\r\nr\xe9ponse \xff fin\r\n\001\014ok\n' > "$TJ"
JT=$(eval "$JL")
if printf '{"rapport":"%s"}' "$JT" | python3 -c 'import sys,json;json.load(sys.stdin)' 2>/dev/null; then echo "  ok   JSON valide"; else echo "  ECHEC JSON d'envoi invalide (le serveur repondrait 400)"; FAIL=1; fi
rm -f "$TJ"
python3 tests/corpus_test.py || FAIL=1
echo; [ $FAIL = 0 ] && echo "TOUS LES TESTS PASSENT" || { echo "TESTS EN ECHEC : ne pas publier"; exit 1; }
