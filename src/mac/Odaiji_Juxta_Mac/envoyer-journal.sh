#!/bin/bash
# envoyer-journal.sh <fichier> <raison> : envoie un journal / rapport a MadeForMed (meme point de reception que les rapports du kit). Jamais bloquant.
F="${1:-}"; RAISON="${2:-journal}"; D="$(cd "$(dirname "$0")" && pwd)"
[ -f "$F" ] && command -v curl >/dev/null 2>&1 || exit 0
VERSION=$(grep -m1 '^VERSION=' "$D/OdaijiJuxta-Mac.sh" 2>/dev/null | cut -d'"' -f2); HOST=$(scutil --get ComputerName 2>/dev/null | tr ' ' '_'); [ -z "$HOST" ] && HOST=$(hostname -s)
T=$(mktemp -t juxtaj)
J=$(tail -c 240000 "$F" | LC_ALL=C tr -d '\000-\010\013-\037' | iconv -f UTF-8 -t UTF-8 -c 2>/dev/null | LC_ALL=C sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e $'s/\t/\\\\t/g' | LC_ALL=C awk '{printf "%s\\n",$0}')
printf '{"kit":"odaiji-juxta","os":"mac","version":"%s","poste":"%s","nom":"%s","raison":"%s","rapport":"%s"}' "${VERSION:-?}" "$HOST" "$(basename "$F")" "$RAISON" "$J" > "$T.json"
C=$(curl -sS -m 40 -o "$T.out" -w '%{http_code}' -X POST -H 'Content-Type: application/json; charset=utf-8' --data-binary @"$T.json" https://odaiji-juxta.netlify.app/.netlify/functions/rapport 2>"$T.err")
if [ "$C" = "200" ]; then echo "Journal transmis automatiquement a MadeForMed."; else echo "Envoi automatique du journal impossible (HTTP ${C:-000} $(head -c 100 "$T.err" "$T.out" 2>/dev/null | tr '\n' ' ')) : le recuperer par le transfert de fichiers TeamViewer."; fi
rm -f "$T" "$T.json" "$T.out" "$T.err"
