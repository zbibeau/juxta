#!/bin/bash
# build.sh - LA seule facon de produire les kits publies.   Usage :  bash build.sh [--check]
#   1. tamponne la version (src/VERSION : ligne 1 = version, ligne 2 = date JJ/MM/AAAA) dans tous les fichiers concernes
#   2. controles : ASCII + CRLF des .ps1/.bat, syntaxe PowerShell (pwsh) et bash, droits d'execution Mac, coherence des versions
#   3. assemble les zips dans kits/ (les installeurs binaires du kit PC sont repris du zip precedemment publie ou de $INSTALLEURS_PC)
#   --check : controles seulement, aucun zip
# Les sources sont dans src/pc/Odaiji_Juxta_PC et src/mac/Odaiji_Juxta_Mac. Ne JAMAIS editer les zips ni les fichiers tamponnes a la main.
set -u
cd "$(dirname "$0")" || exit 1
ROOT=$PWD; V=$(sed -n 1p src/VERSION | tr -d '\r '); D=$(sed -n 2p src/VERSION | tr -d '\r ')
PCD=src/pc/Odaiji_Juxta_PC; MACD=src/mac/Odaiji_Juxta_Mac; FAIL=0
PWSH=${PWSH:-$(command -v pwsh || echo /tmp/w/psh/pwsh)}
case "$V" in [0-9]*.[0-9]*.[0-9]*) ;; *) echo "src/VERSION illisible : '$V'"; exit 1;; esac

stamp() { # fichier  regex-sed-E  remplacement
  [ -f "$1" ] || { echo "  ECHEC fichier absent : $1"; FAIL=1; return; }
  sed -E -i "s|$2|$3|" "$1"
}
echo "== Tampon de version $V ($D)"
stamp $PCD/OdaijiJuxta.ps1   '^(\$Script:Version = ")[^"]*(")' "\\1$V\\2"
stamp $PCD/Depannage.ps1     '^( MadeForMed / Odaiji - v)[0-9.]+ \([0-9/]+\)' "\\1$V ($D)"
stamp $PCD/Depannage.ps1     '\(kit v[0-9.]+\)' "(kit v$V)"
sed -E -i "1s/ - v[0-9.]+/ - v$V/" $PCD/LISEZMOI.txt $MACD/LISEZMOI.txt
stamp $MACD/OdaijiJuxta-Mac.sh '^VERSION="[^"]*"' "VERSION=\"$V\""
stamp $MACD/2-Depanner.command '^(#  MadeForMed / Odaiji - v)[0-9.]+ \([0-9/]+\)' "\\1$V ($D)"
stamp $MACD/1-Installer.command '^(#  MadeForMed / Odaiji - v)[0-9.]+ \([0-9/]+\)' "\\1$V ($D)"
stamp index.html '(var VERSION = \{ win: "v)[0-9.]+(", mac: "v)[0-9.]+(" \})' "\\1$V\\2$V\\3"
printf '{"version":"%s","date":"%s"}\n' "$V" "$D" > version.json

echo "== Controles"
for f in $PCD/*.ps1 $PCD/*.bat; do
  na=$(grep -c -P '[^\x00-\x7F]' "$f"); crlf=$(grep -c -v $'\r$' "$f")
  [ "$na" = 0 ] && [ "$crlf" = 0 ] || { echo "  ECHEC $(basename "$f") : non-ASCII=$na lignes-sans-CRLF=$crlf"; FAIL=1; }
done
for f in $PCD/*.ps1; do e=$("$PWSH" -NoProfile -File tests/parse.ps1 -File "$f" 2>&1 | tail -1); [ "$e" = 0 ] || { echo "  ECHEC syntaxe PowerShell : $(basename "$f")"; FAIL=1; }; done
for f in $MACD/*.sh $MACD/*.command; do
  bash -n "$f" 2>/dev/null || { echo "  ECHEC syntaxe bash : $(basename "$f")"; FAIL=1; }
  [ -x "$f" ] || { echo "  ECHEC non executable : $(basename "$f")"; FAIL=1; }
done
nv=$(grep -rhoE "(Script:Version = \"|^VERSION=\"|kit v|win: \"v)$V" $PCD $MACD index.html | wc -l)
[ "$nv" -ge 4 ] || { echo "  ECHEC versions non coherentes ($nv/4 trouvees)"; FAIL=1; }
[ $FAIL = 0 ] || { echo "BUILD EN ECHEC"; exit 1; }
echo "  ok"
[ "${1:-}" = "--check" ] && exit 0

echo "== Assemblage des zips"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/pc" "$TMP/mac"; cp -a $PCD "$TMP/pc/"; cp -a $MACD "$TMP/mac/"
if [ -n "${INSTALLEURS_PC:-}" ] && [ -d "$INSTALLEURS_PC" ]; then cp -a "$INSTALLEURS_PC" "$TMP/pc/Odaiji_Juxta_PC/installeurs"
else unzip -q -o kits/Odaiji_Juxta_PC.zip 'Odaiji_Juxta_PC/installeurs/*' -d "$TMP/old" && cp -a "$TMP/old/Odaiji_Juxta_PC/installeurs" "$TMP/pc/Odaiji_Juxta_PC/installeurs"; fi
ls "$TMP/pc/Odaiji_Juxta_PC/installeurs"/*.msi >/dev/null 2>&1 || { echo "  ECHEC : installeurs .msi introuvables (definir INSTALLEURS_PC)"; exit 1; }
mkdir -p "$TMP/mac/Odaiji_Juxta_Mac/installeurs/SSV"
rm -f kits/Odaiji_Juxta_PC.zip.new kits/Odaiji_Juxta_Mac.zip.new
(cd "$TMP/pc" && zip -qrX "$ROOT/kits/Odaiji_Juxta_PC.zip.new" Odaiji_Juxta_PC) && mv kits/Odaiji_Juxta_PC.zip.new kits/Odaiji_Juxta_PC.zip
(cd "$TMP/mac" && zip -qrX "$ROOT/kits/Odaiji_Juxta_Mac.zip.new" Odaiji_Juxta_Mac) && mv kits/Odaiji_Juxta_Mac.zip.new kits/Odaiji_Juxta_Mac.zip
ls -la kits/*.zip
echo "OK : kits $V construits. Reste : bash tests/run.sh, CHANGELOG.md, git commit/push."
