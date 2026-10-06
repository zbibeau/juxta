#!/bin/bash
# =====================================================================
#  Odaiji_Juxta - DEPANNAGE d'un Mac deja equipe (diag -> bons outils -> diag)
#  MadeForMed / Odaiji - v1.1.3 (06/10/2026)
# =====================================================================
#  Double-clic depuis le Finder (ou : bash 2-Depanner.command)
#  A utiliser quand JuxtaLink est DEJA installe. Sinon : 1-Installer.command.
#
#  Deroule :
#    1. Diag AVANT (lecture seule)                 -> Bureau/Avant_<mac>_<date>.txt
#    2. Questions : anciens logiciels (MediMust / MediStory) encore utilises ?
#    3. Corrections automatiques sures selon les constats (--auto)
#    4. Lecteur : realignement galss.ini si probleme GALSS ; Chrome/Edge si Local Network Access
#    5. Full PC/SC (retrait du GALSS Juxta) si GALSS present (jamais avec DMP Connect / iCanopee)
#    6. user.config MadeForMed verifie, JuxtaLink arrete/relance, port 1234 verifie, gardien (veille toutes les 10 min) installe
#    7. Diag APRES + verdict                       -> Bureau/Apres_<mac>_<date>.txt
#  Journal complet : Bureau/Depannage_<mac>_<date>.txt (a envoyer avec Avant/Apres)
# =====================================================================
set -u
KIT="$(cd "$(dirname "$0")" && pwd)"; cd "$KIT"
APP="/Applications/JuxtaLink.app"
STAMP=$(date +%Y%m%d-%H%M); HOSTN=$(scutil --get ComputerName 2>/dev/null | tr -c 'A-Za-z0-9\n' '_')
JOURNAL="$HOME/Desktop/Depannage_${HOSTN}_${STAMP}.txt"
exec > >(tee "$JOURNAL") 2>&1
say_(){ printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok_(){ printf '    \033[32m[OK]\033[0m %s\n' "$*"; }
ko_(){ printf '    \033[31m[KO]\033[0m %s\n' "$*"; }
warn_(){ printf '    \033[33m[WARN]\033[0m %s\n' "$*"; }
# spin_ : animation sur le terminal (pas dans le journal) + temps ecoule
spin_(){
    local msg="$1"; shift
    SPIN_OUT=$(mktemp /tmp/odaiji-spin.XXXXXX)
    "$@" >"$SPIN_OUT" 2>&1 &
    local pid=$! t0=$SECONDS i=0 fr='|/-\\'
    if [ -w /dev/tty ]; then
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r    \033[35m%s\033[0m %s  (%ds, ne pas fermer)   ' "${fr:$((i%4)):1}" "$msg" "$((SECONDS-t0))" >/dev/tty; i=$((i+1)); sleep 0.5
        done
        printf '\r%*s\r' 100 '' >/dev/tty
    else echo "    $msg ..."; fi
    wait "$pid"; local rc=$?
    echo "    ($msg : $((SECONDS-t0)) s)"
    return $rc
}
# codes presents dans un rapport (lignes "           CODE   KO|WARN|INFO  texte" sous "Constats :")
codes_(){ grep -E '^[[:space:]]{8,}[A-Za-z][A-Za-z0-9_]+[[:space:]]+(KO|WARN|INFO)[[:space:]]' "$1" 2>/dev/null | awk '{print $1}' | sort -u; }

# 04/10 : gardien = veille de JuxtaLink toutes les 10 min (agent launchd utilisateur), relance s'il est arrete ou bloque
gardien_(){
    local D="$HOME/Library/Application Support/MadeForMed" P="$HOME/Library/LaunchAgents/fr.madeformed.juxtalink-gardien.plist"
    [ -f "$KIT/juxtalink-gardien.sh" ] && [ -f "$KIT/fr.madeformed.juxtalink-gardien.plist" ] || { ko_ "Gardien : fichiers absents du kit"; return; }
    mkdir -p "$D" "$HOME/Library/LaunchAgents" && cp "$KIT/juxtalink-gardien.sh" "$D/" && chmod +x "$D/juxtalink-gardien.sh"
    [ -f "$KIT/galss-autofix.sh" ] && cp "$KIT/galss-autofix.sh" "$D/" && chmod +x "$D/galss-autofix.sh"
    [ -f /Library/Preferences/galss.ini ] && sudo chmod a+rw /Library/Preferences/galss.ini 2>/dev/null   # le gardien realigne galss.ini sans mot de passe
    sed "s#__HOME__#$HOME#g" "$KIT/fr.madeformed.juxtalink-gardien.plist" > "$P"
    launchctl bootout gui/$(id -u)/fr.madeformed.juxtalink-gardien 2>/dev/null; launchctl bootstrap gui/$(id -u) "$P" 2>/dev/null
    if launchctl print gui/$(id -u)/fr.madeformed.juxtalink-gardien >/dev/null 2>&1; then ok_ "Gardien installe : veille de JuxtaLink toutes les 10 min, relance s'il est arrete (journal ~/Library/Logs/juxtalink-gardien.log)"
    else ko_ "Gardien : agent launchd non charge (fr.madeformed.juxtalink-gardien)"; fi
}

echo "Odaiji_Juxta - DEPANNAGE sur $(scutil --get ComputerName 2>/dev/null)"
if [ ! -d "$APP" ]; then ko_ "JuxtaLink n'est pas installe sur ce Mac : lancer 1-Installer.command"; read -r -p "Entree pour fermer"; exit 1; fi
echo "Mot de passe administrateur requis."
sudo -v || { ko_ "Pas de droits admin."; exit 1; }
chmod +x "$KIT"/*.sh "$KIT"/*.command 2>/dev/null

# ---------------------------------------------------------------- 1. AVANT
say_ "1/7  Diagnostic AVANT (lecture seule)"
echo "    (cartes CPS + Vitale inserees)"
spin_ "Analyse du Mac en cours (1 a 2 min)" env JDPREFIX=Avant bash "$KIT/OdaijiJuxta-Mac.sh"
AVANT=$(ls -t "$HOME/Desktop"/Avant_*.txt 2>/dev/null | head -1); ok_ "Rapport : $AVANT"
CODES=$(codes_ "$AVANT"); SCEN=$(grep -m1 'Scenario :' "$AVANT")
echo "    $SCEN"
grep -E '^\s*\[KO\]' "$AVANT" | head -8
has_(){ echo "$CODES" | grep -qE "$1"; }

# ---------------------------------------------------------------- 2. QUESTIONS
say_ "2/7  Anciens logiciels de facturation"
MMARG=""
for kp in "medimust|MediMust|medimust" "prokov|MediStory (Prokov)|prokov|medistory|m.distory"; do
    k=${kp%%|*}; rest=${kp#*|}; lbl=${rest%%|*}; pat=${rest#*|}
    if sudo grep -rqilE "$pat" /Library/LaunchDaemons /Library/LaunchAgents "$HOME/Library/LaunchAgents" 2>/dev/null || pgrep -fi "$pat" >/dev/null; then
        r=""; while [[ ! "$r" =~ ^[oOnN] ]]; do read -r -p "    Le medecin facture-t-il ENCORE avec $lbl ? [o/n] (n = coupe, rien n'est supprime) " r; done
        [[ "$r" =~ ^[nN] ]] && MMARG="$MMARG --sans-$k"
    fi
done
if has_ '^JFSE_(RUN|AGENT|DIR)'; then
    r=""; while [[ ! "$r" =~ ^[oOnN] ]]; do read -r -p "    jFSE / Cegedim est installe et tient le lecteur : le medecin facture-t-il ENCORE avec Cegedim (jFSE, Medimust) ? [o/n] (n = jFSE est arrete puis supprime) " r; done
    [[ "$r" =~ ^[nN] ]] && MMARG="$MMARG --sans-jfse"
fi
[ -z "$MMARG" ] && echo "    Rien a couper."

# ---------------------------------------------------------------- 3. FIX AUTO
say_ "3/7  Corrections automatiques sures"
if has_ '^(GALSS_|JFSE_|DIAGAM|DMP_MULTI|GATEKEEPER_OFF|OLD_|CRYPTO_GALSS)' || [ -n "$MMARG" ]; then
    spin_ "Corrections en cours (1 a 2 min)" env JDPREFIX=Fix bash "$KIT/OdaijiJuxta-Mac.sh" --auto $MMARG
    grep -E '^\s*(\[OK\]|\[KO\]|\[WARN\]|>>)' "$SPIN_OUT" | head -20
    rm -f "$HOME/Desktop"/Fix_*.txt
else ok_ "Aucune correction automatique necessaire"; fi

# ---------------------------------------------------------------- 4. LECTEUR + NAVIGATEURS
say_ "4/7  Lecteur de cartes et navigateurs"
if has_ '^GALSS_(SERIE|MISMATCH|REVERT|EMPTY|BACK)'; then
    echo "    Probleme galss.ini : realignement sur les fentes reelles du lecteur"
    read -r -p "    Inserer la CPS ET la Vitale dans le lecteur, puis Entree " _
    GA="$HOME/Library/Application Support/MadeForMed/galss-autofix.sh"; [ -f "$GA" ] || GA="$KIT/galss-autofix.sh"
    bash "$GA" 2>&1 | sed 's/^/    /'
else ok_ "galss.ini : rien a realigner"; fi
if has_ '^LNA_'; then
    echo "    Chrome / Edge : autoriser Odaiji a joindre JuxtaLink (Local Network Access)"
    bash "$KIT/Autoriser-Odaiji-Chrome.command" 2>&1 | grep -v 'Mot de passe' | sed 's/^/    /'
    for dom in com.google.Chrome com.microsoft.Edge; do
        [ -d "/Applications/$([ $dom = com.google.Chrome ] && echo 'Google Chrome' || echo 'Microsoft Edge').app" ] || continue
        if defaults read "/Library/Preferences/$dom" LocalNetworkAccessAllowedForUrls 2>/dev/null | grep -q odaiji; then ok_ "Politique Local Network Access en place ($dom)"
        else
            ko_ "Politique absente ($dom) : nouvelle tentative"
            sudo defaults write "/Library/Preferences/$dom" LocalNetworkAccessAllowedForUrls -array '"https://app.odaiji.co"' '"https://[*.]odaiji.co"' '"https://[*.]madeformed.fr"' '"https://[*.]juxta.cloud"' 2>/dev/null
            sudo chmod 644 "/Library/Preferences/$dom.plist" 2>/dev/null
        fi
    done
    warn_ "Fermer puis rouvrir Chrome / Edge pour que la politique soit prise en compte"
else ok_ "Navigateurs : rien a faire"; fi

# ---------------------------------------------------------------- 5. FULL PC/SC
say_ "5/7  Full PC/SC (retrait du GALSS Juxta)"
if has_ '^(CRYPTO_GALSS|GALSS_)' || ls /Library/Preferences/galss.ini >/dev/null 2>&1; then
    spin_ "Passage Full PC/SC en cours" env JDPREFIX=Galss bash "$KIT/OdaijiJuxta-Mac.sh" --auto --sans-galss
    grep -E '7g|Prerequis|BLOQUER|GALSS|>>>' "$SPIN_OUT" | head -12
    rm -f "$HOME/Desktop"/Galss_*.txt
else ok_ "Pas de GALSS a retirer"; fi

# ---------------------------------------------------------------- 6. JUXTALINK
say_ "6/7  user.config MadeForMed + redemarrage de JuxtaLink"
UC_LIST="$APP/Contents/Resources/user.config"
for c in "$APP/Contents/MacOS/user.config" "$HOME/.config/juxta/juxtalink/user.config"; do [ -f "$c" ] && UC_LIST="$UC_LIST
$c"; done
UCMAIN="$APP/Contents/Resources/user.config"
for essai in 1 2 3; do
    pkill -x JuxtaLink 2>/dev/null; sleep 2
    if [ -f "$KIT/user.config" ]; then
        while IFS= read -r UC_DST; do [ -z "$UC_DST" ] && continue
            sudo chflags nouchg "$UC_DST" 2>/dev/null; sudo mkdir -p "$(dirname "$UC_DST")"
            if ! cmp -s "$KIT/user.config" "$UC_DST"; then [ -f "$UC_DST" ] && sudo cp "$UC_DST" "$UC_DST.bak-$(date +%Y%m%d-%H%M)"; sudo cp "$KIT/user.config" "$UC_DST"; fi
            sudo chmod a+rw "$UC_DST"
        done <<< "$UC_LIST"
        [ "$essai" -ge 2 ] && sudo chflags uchg "$UCMAIN" 2>/dev/null
        sync
    fi
    open -a JuxtaLink 2>/dev/null; sleep 8
    if [ ! -f "$KIT/user.config" ] || grep -q 'madeformed-drc-token' "$UCMAIN" 2>/dev/null; then break; fi
    ko_ "essai $essai : JuxtaLink a remis sa propre config (tokenServerUrl : $(grep -o 'tokenServerUrl" value="[^"]*"' "$UCMAIN" 2>/dev/null | cut -d'"' -f4))"
done
grep -q 'madeformed-drc-token' "$UCMAIN" 2>/dev/null && ok_ "user.config MadeForMed charge" || ko_ "user.config MadeForMed absent"
pgrep -x JuxtaLink >/dev/null && ok_ "JuxtaLink en cours d'execution" || ko_ "JuxtaLink ne s'est pas lance : l'ouvrir depuis Applications"
for i in 1 2 3 4 5 6 7 8 9 10; do lsof -nP -iTCP:1234 -sTCP:LISTEN >/dev/null 2>&1 && break; sleep 2; done
lsof -nP -iTCP:1234 -sTCP:LISTEN >/dev/null 2>&1 && ok_ "JuxtaLink ecoute sur le port 1234" || ko_ "Rien n'ecoute sur le port 1234 (JuxtaLink demarre encore ? sinon envoyer les rapports)"
gardien_
printf '\a'
echo "    >>> CONTROLE dans Odaiji : une facture avec une carte Vitale, puis une facture sans Vitale (valider l'appel ADRi)."
read -r -p "    Entree une fois les deux factures faites "

# ---------------------------------------------------------------- 7. APRES
say_ "7/7  Diagnostic APRES"
spin_ "Analyse du Mac en cours (1 a 2 min)" env JDPREFIX=Apres bash "$KIT/OdaijiJuxta-Mac.sh"
APRES=$(ls -t "$HOME/Desktop"/Apres_*.txt 2>/dev/null | head -1); ok_ "Rapport : $APRES"
echo; echo "    AVANT : $SCEN"; echo "    APRES : $(grep -m1 'Scenario :' "$APRES")"
[ -f "$KIT/odaiji-commun.sh" ] && [ -n "${AVANT:-}" ] && [ -f "$AVANT" ] && { . "$KIT/odaiji-commun.sh" 2>/dev/null; oj_delta "$AVANT" "$APRES"; }
grep -E '^\s*\[KO\]|^\s*\[WARN\]' "$APRES" | head -10
echo
echo "A envoyer dans le channel Claude si le scenario n'est pas OK :"
echo "    $AVANT"; echo "    $APRES"; echo "    $JOURNAL"
echo "Ensuite, si un doute persiste : 3-Diag-seul.command apres ces deux factures."
open -R "$APRES" 2>/dev/null
bash "$KIT/envoyer-journal.sh" "$JOURNAL" "journal depannage"
