#!/bin/bash
chmod +x "$(dirname "$0")"/*.command "$(dirname "$0")"/*.sh 2>/dev/null; xattr -dr com.apple.quarantine "$(dirname "$0")" 2>/dev/null
# =====================================================================
#  Construire-kit - assemble le kit Odaiji_Juxta_Mac avec les installeurs
#  presents dans le Drive synchronise (option 2). A lancer sur le Mac de MadeForMed.
#  Cherche : JuxtaLink*.pkg et un dossier <version> contenant ComposantsSV.dll
#  dans ~/Library/CloudStorage/*/ (Google Drive), ~/Downloads, ~/Desktop.
#  Produit : ~/Desktop/Odaiji_Juxta_Mac-<date>.zip
# =====================================================================
KIT="$(cd "$(dirname "$0")" && pwd)"; cd "$KIT"
say_(){ printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
PKG=$(find ~/Library/CloudStorage ~/Downloads ~/Desktop -maxdepth 6 -iname 'JuxtaLink*.pkg' 2>/dev/null | sort | tail -1)
SSV=$(find ~/Library/CloudStorage ~/Downloads ~/Desktop -maxdepth 8 -iname 'ComposantsSV.dll' 2>/dev/null | head -1)
say_ "Installeur JuxtaLink : ${PKG:-INTROUVABLE}"
say_ "Plugin SSV          : ${SSV:+$(dirname "$SSV")}${SSV:-INTROUVABLE}"
[ -z "$PKG" ] || [ -z "$SSV" ] && { echo "Fichiers manquants. Verifier que le Drive est synchronise (fichiers disponibles hors ligne)."; read -r -p "Entree pour fermer"; exit 1; }
mkdir -p installeurs/SSV; rm -f installeurs/JuxtaLink*.pkg; rm -rf installeurs/SSV/[0-9]*
cp "$PKG" "installeurs/$(basename "$PKG")"
SSVDIR=$(dirname "$SSV"); cp -R "$SSVDIR" "installeurs/SSV/$(basename "$SSVDIR")"
OUT="$HOME/Desktop/Odaiji_Juxta_Mac-$(date +%Y%m%d).zip"; rm -f "$OUT"
cd .. && zip -r -q "$OUT" "$(basename "$KIT")" -x '*.DS_Store' '*__MACOSX*' && say_ "Kit pret : $OUT ($(du -h "$OUT" | cut -f1))"
open -R "$OUT"; read -r -p "Entree pour fermer"
