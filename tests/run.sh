#!/bin/bash
# Tests du kit avant publication :  bash tests/run.sh   (depuis la racine du depot)
# Controles : syntaxe + ASCII + CRLF des .ps1, syntaxe bash des scripts Mac, cas sesam.ini (fonctions reelles), lecture des constats Mac.
cd "$(dirname "$0")/.." || exit 1
ROOT=$PWD; PC="${KIT_PC:-/tmp/w/pc/Odaiji_Juxta_PC}"; MAC="${KIT_MAC:-/tmp/w/mac/Odaiji_Juxta_Mac}"
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
echo; [ $FAIL = 0 ] && echo "TOUS LES TESTS PASSENT" || { echo "TESTS EN ECHEC : ne pas publier"; exit 1; }
