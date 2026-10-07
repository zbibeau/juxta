#!/bin/bash
# =====================================================================
#  Odaiji_Juxta - Installation propre de JuxtaLink + plugin SSV sur macOS
#  MadeForMed / Odaiji - v1.1.6 (07/10/2026)
# =====================================================================
#  Double-clic depuis le Finder (ou : bash 1-Installer.command)
#
#  Contenu attendu du dossier :
#    installeurs/JuxtaLink*.pkg          installeur JuxtaLink
#    installeurs/SSV/<version>/          plugin SSV (ex. 4.1.1.0, avec ComposantsSV.dll)
#    OdaijiJuxta-Mac.sh                  diagnostic / reparation
#    galss-autofix.sh + .plist + Reparer-lecteur.command   auto-alignement lecteur
#
#  Deroule :
#    1. Diag AVANT (lecture seule)            -> Bureau/Avant_<mac>_<date>.txt
#    2. Installation JuxtaLink (.pkg)
#    3. Copie du plugin SSV dans l'application ; 3b. user.config MadeForMed
#    4. Corrections automatiques sures (galss.ini PC/SC, quarantaine)
#    5. Lancement JuxtaLink
#    5c. Redemarrage propre de JuxtaLink + lecture de controle ; 5d. gardien (veille toutes les 10 min)
#    6. Diag APRES + verdict                  -> Bureau/Apres_<mac>_<date>.txt
#  Options : --with-autofix  installe aussi l'agent galss-autofix (lecteurs a nommage instable)
#            --no-install    saute 2 et 3 (poste deja installe : diag + corrections seulement)
#            --keep-gatekeeper-off  ne pas reactiver Gatekeeper apres le pkg Juxta (qui le desactive)
#            --avec-galss    ne PAS retirer le GALSS Juxta (par defaut : retire et bloque apres la 1re lecture,
#                            avec retour arriere automatique par le diag si la lecture echoue ensuite)
# =====================================================================
set -u
KIT="$(cd "$(dirname "$0")" && pwd)"; cd "$KIT"
RAPDIR="${ODAIJI_RAPPORTS:-$HOME/Library/Logs/Odaiji}"; mkdir -p "$RAPDIR" 2>/dev/null
JOURNAL="$RAPDIR/Installation_$(scutil --get ComputerName 2>/dev/null | tr ' ' '_')_$(date +%Y%m%d-%H%M).txt"
exec > >(tee "$JOURNAL") 2>&1
WITH_AUTOFIX=0; NO_INSTALL=0; KEEP_GK_OFF=0; SANS_GALSS=1
for a in "$@"; do [ "$a" = "--with-autofix" ] && WITH_AUTOFIX=1; [ "$a" = "--no-install" ] && NO_INSTALL=1; [ "$a" = "--keep-gatekeeper-off" ] && KEEP_GK_OFF=1; [ "$a" = "--sans-galss" ] && SANS_GALSS=1; [ "$a" = "--avec-galss" ] && SANS_GALSS=0; done
APP="/Applications/JuxtaLink.app"
[ -f "$KIT/odaiji-commun.sh" ] && . "$KIT/odaiji-commun.sh" 2>/dev/null
say_(){ printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok_(){ printf '    \033[32m[OK]\033[0m %s\n' "$*"; }
ko_(){ printf '    \033[31m[KO]\033[0m %s\n' "$*"; }
# spin_ "message" <commande...> : lance la commande en arriere-plan (sortie dans $SPIN_OUT) et affiche une animation + le temps ecoule,
# pour qu'on voie que ca travaille (01/10 iMac Poste3 : l'installation du pkg paraissait bloquee). Retourne le code de la commande.
spin_(){
    local msg="$1"; shift
    SPIN_OUT=$(mktemp /tmp/odaiji-spin.XXXXXX)
    "$@" >"$SPIN_OUT" 2>&1 &
    local pid=$! t0=$SECONDS i=0 fr='|/-\\'
    if [ -t 1 ]; then
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r    \033[35m%s\033[0m %s  (%ds, ne pas fermer)   ' "${fr:$((i%4)):1}" "$msg" "$((SECONDS-t0))"; i=$((i+1)); sleep 0.5
        done
        printf '\r%*s\r' 100 ''
    else echo "    $msg ..."; fi
    wait "$pid"; local rc=$?
    echo "    ($msg : $((SECONDS-t0)) s)"
    return $rc
}

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

echo "Odaiji_Juxta - installation JuxtaLink sur $(scutil --get ComputerName 2>/dev/null)"
echo "Mot de passe administrateur requis."
sudo -v || { ko_ "Pas de droits admin."; exit 1; }
chmod +x "$KIT"/*.sh "$KIT"/*.command 2>/dev/null

# ---------------------------------------------------------------- 0. SOURCES (telechargement optionnel)
dl(){ # dl <url> <destination>  (gere les liens Google Drive et les gros fichiers)
    local url="$1" dst="$2" id=""
    if [[ "$url" =~ drive\.google\.com ]]; then
        id=$(echo "$url" | grep -oE '(/d/|id=)[A-Za-z0-9_-]{20,}' | head -1 | sed -E 's#^(/d/|id=)##')
        [ -n "$id" ] && url="https://drive.google.com/uc?export=download&id=$id&confirm=t"
        curl -L -S --progress-bar -o "$dst" "$url" || return 1
        if head -c 400 "$dst" | grep -qi '<html'; then   # page de confirmation antivirus
            local tok; tok=$(grep -oE 'confirm=[A-Za-z0-9_-]+' "$dst" | head -1 | cut -d= -f2); local uuid; uuid=$(grep -oE 'name="uuid" value="[^"]+"' "$dst" | grep -oE 'value="[^"]+"' | cut -d'"' -f2)
            curl -L -S --progress-bar -o "$dst" "https://drive.usercontent.google.com/download?id=$id&export=download&confirm=${tok:-t}${uuid:+&uuid=$uuid}" || return 1
        fi
    elif [[ "$url" =~ dropbox\.com ]]; then
        url="${url/\?dl=0/?dl=1}"; url="${url/&dl=0/&dl=1}"; [[ "$url" != *dl=1* ]] && url="$url?dl=1"
        curl -L -S --progress-bar -o "$dst" "$url" || return 1
    else curl -L -S --progress-bar -o "$dst" "$url" || return 1; fi
    [ -s "$dst" ] && ! head -c 400 "$dst" | grep -qi '<html'
}
if [ -f "$KIT/sources.conf" ]; then
    # shellcheck disable=SC1090
    . "$KIT/sources.conf"
    mkdir -p "$KIT/installeurs/SSV"
    if [ -n "${KIT_URL:-}" ] && { ! ls "$KIT"/installeurs/JuxtaLink*.pkg >/dev/null 2>&1 || ! ls -d "$KIT"/installeurs/SSV/[0-9]* >/dev/null 2>&1; }; then
        say_ "0/6  Telechargement du dossier d'installeurs (KIT_URL)"
        rm -rf /tmp/odaiji_kit; mkdir -p /tmp/odaiji_kit
        if dl "$KIT_URL" /tmp/odaiji_kit.zip && unzip -o -q /tmp/odaiji_kit.zip -d /tmp/odaiji_kit; then
            PK=$(find /tmp/odaiji_kit -iname 'JuxtaLink*.pkg' -not -path '*__MACOSX*' | head -1)
            [ -n "$PK" ] && mv -f "$PK" "$KIT/installeurs/" && ok_ "pkg : $(basename "$PK") ($(du -h "$KIT/installeurs/$(basename "$PK")" | cut -f1))" || ko_ "Aucun JuxtaLink*.pkg dans le dossier telecharge"
            SV=$(find /tmp/odaiji_kit -iname 'ComposantsSV.dll' -not -path '*__MACOSX*' | head -1)
            if [ -n "$SV" ]; then SVD=$(dirname "$SV"); SVN=$(basename "$SVD"); [[ "$SVN" =~ ^[0-9] ]] || SVN="${SSV_VERSION:-4.1.1.0}"
                rm -rf "$KIT/installeurs/SSV/$SVN"; mkdir -p "$KIT/installeurs/SSV/$SVN"; cp -R "$SVD/." "$KIT/installeurs/SSV/$SVN/"; ok_ "plugin SSV : $SVN"
            else ko_ "Aucun ComposantsSV.dll dans le dossier telecharge"; fi
            rm -rf /tmp/odaiji_kit /tmp/odaiji_kit.zip
        else ko_ "Echec du telechargement de KIT_URL"; fi
    fi
    if [ -n "${PKG_URL:-}" ] && ! ls "$KIT"/installeurs/JuxtaLink*.pkg >/dev/null 2>&1; then
        say_ "0/6  Telechargement de l'installeur JuxtaLink"
        dl "$PKG_URL" "$KIT/installeurs/JuxtaLink.pkg" && ok_ "pkg telecharge ($(du -h "$KIT/installeurs/JuxtaLink.pkg" | cut -f1))" || { ko_ "Echec du telechargement du pkg"; rm -f "$KIT/installeurs/JuxtaLink.pkg"; }
    fi
    if [ -n "${SSV_URL:-}" ] && ! ls -d "$KIT"/installeurs/SSV/[0-9]* >/dev/null 2>&1; then
        say_ "0/6  Telechargement du plugin SSV"
        if dl "$SSV_URL" /tmp/ssv.zip && unzip -o -q /tmp/ssv.zip -d "$KIT/installeurs/SSV/"; then
            rm -rf "$KIT/installeurs/SSV/__MACOSX"
            # lien de dossier Dropbox : fichiers a la racine -> on recree <version>/
            if [ -f "$KIT/installeurs/SSV/SSV.dll" ]; then
                v="${SSV_VERSION:-}"; [ -z "$v" ] && v=$(grep -o 'SOCLE_FSV" value="[^"]*"' "$KIT/installeurs/SSV/SSV.dll.config" 2>/dev/null | cut -d'"' -f4)
                [ -z "$v" ] && v="4.1.1.0"
                mkdir -p "$KIT/installeurs/SSV/$v"; find "$KIT/installeurs/SSV" -maxdepth 1 -type f -exec mv {} "$KIT/installeurs/SSV/$v/" \;
            fi
            ok_ "plugin SSV : $(ls -d "$KIT"/installeurs/SSV/[0-9]* | xargs -n1 basename)"
        else ko_ "Echec du telechargement du plugin SSV"; fi
    fi
fi

# ---------------------------------------------------------------- 1. AVANT
say_ "1/6  Diagnostic AVANT installation (lecture seule)"
spin_ "Analyse du Mac en cours (1 a 2 min)" env JDPREFIX=Avant bash "$KIT/OdaijiJuxta-Mac.sh"
AVANT=$(ls -t "$RAPDIR"/Avant_*.txt 2>/dev/null | head -1); ok_ "Rapport : $AVANT"
grep -E '^\s*\[KO\]|Scenario :' "$AVANT" | head -12

# ---------------------------------------------------------------- 2. PKG
if [ $NO_INSTALL = 0 ]; then
    say_ "2/6  Installation de JuxtaLink"
    PKG=$(ls "$KIT"/installeurs/JuxtaLink*.pkg 2>/dev/null | head -1)
    if [ -z "$PKG" ]; then ko_ "Aucun installeurs/JuxtaLink*.pkg trouve"; exit 1; fi
    if pgrep -x JuxtaLink >/dev/null; then pkill -x JuxtaLink; sleep 2; fi
    echo "    Installation du pkg JuxtaLink : 1 a 3 minutes, c'est normal, ne rien fermer."
    spin_ "Installation du pkg JuxtaLink" sudo installer -pkg "$PKG" -target / && ok_ "JuxtaLink installe ($(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null))" || { ko_ "Echec installer -pkg"; tail -8 "$SPIN_OUT"; exit 1; }
    sudo xattr -dr com.apple.quarantine "$APP" 2>/dev/null
    # 01/10 (MacBook Pro) : le pkg peut lancer JuxtaLink tout seul ; il ecrit alors sa propre config. On l'arrete avant de poser plugin + user.config.
    pkill -x JuxtaLink 2>/dev/null; sleep 2
    # Le preinstall Juxta desactive Gatekeeper sur tout le Mac (spctl --master-disable) : on le reactive.
    if [ $KEEP_GK_OFF = 0 ]; then sudo spctl --master-enable 2>/dev/null; ok_ "Gatekeeper reactive ($(spctl --status 2>&1))"; else ko_ "Gatekeeper laisse desactive (--keep-gatekeeper-off)"; fi

    # ------------------------------------------------------------ 3. SSV
    say_ "3/6  Plugin SSV"
    SSVSRC=$(ls -d "$KIT"/installeurs/SSV/[0-9]* 2>/dev/null | sort -V | tail -1)
    if [ -z "$SSVSRC" ]; then ko_ "Aucun dossier installeurs/SSV/<version> : le plugin sera telecharge a la premiere requete (necessite Internet)"
    elif [ ! -f "$SSVSRC/ComposantsSV.dll" ] || [ ! -f "$SSVSRC/SSV.dll" ]; then ko_ "Dossier SSV incomplet (ComposantsSV.dll / SSV.dll manquant) : non copie"
    else
        DST="$APP/Contents/Resources/Plugins/SSV/$(basename "$SSVSRC")"
        if oj_poser_plugin "$SSVSRC"; then ok_ "Plugin SSV $(basename "$SSVSRC") en place dans $DST"; else ko_ "Plugin SSV NON depose dans $DST"; oj_msg_permission; fi
        sudo chmod -R a+rwX "$APP/Contents/Resources/logs" 2>/dev/null
    fi
else
    say_ "2-3/6  Installation sautee (--no-install)"
fi

# ---------------------------------------------------------------- 3b. user.config
say_ "3b/6  Configuration user.config (serveurs MadeForMed)"
UC_LIST="$APP/Contents/Resources/user.config"
for c in "$APP/Contents/MacOS/user.config" "$HOME/.config/juxta/juxtalink/user.config"; do [ -f "$c" ] && UC_LIST="$UC_LIST
$c"; done
if [ -f "$KIT/user.config" ]; then
    while IFS= read -r UC_DST; do
        [ -z "$UC_DST" ] && continue
        if oj_poser_uc_dst "$KIT/user.config" "$UC_DST"; then ok_ "user.config MadeForMed ecrit : $UC_DST"; else ko_ "user.config MadeForMed NON ecrit : $UC_DST"; oj_msg_permission; fi
        grep -E 'tokenServerUrl|updateServerUrl|port"' "$UC_DST" | sed 's/^/    /'
    done <<< "$UC_LIST"
else ko_ "user.config absent du kit : configuration Juxta non appliquee"; fi

# ---------------------------------------------------------------- 4. FIX AUTO
# 28/09 : anciens logiciels Mac (MediMust, MediStory/Prokov) -> meme question que sur PC
MMARG=""
for kp in "medimust|MediMust|medimust" "prokov|MediStory (Prokov)|prokov|medistory|m.distory"; do
    k=${kp%%|*}; rest=${kp#*|}; lbl=${rest%%|*}; pat=${rest#*|}
    if sudo grep -rqilE "$pat" /Library/LaunchDaemons /Library/LaunchAgents "$HOME/Library/LaunchAgents" 2>/dev/null || pgrep -fi "$pat" >/dev/null; then
        r=""; while [[ ! "$r" =~ ^[oOnN] ]]; do read -r -p "    Le medecin facture-t-il ENCORE avec $lbl ? [o/n] (n = coupe, rien n'est supprime) " r; done
        [[ "$r" =~ ^[nN] ]] && MMARG="$MMARG --sans-$k"
    fi
done
say_ "4/6  Corrections automatiques sures"
echo "    (cartes CPS + Vitale inserees pour que galss.ini soit genere avec les bons noms de lecteur)"
spin_ "Corrections en cours (1 a 2 min)" env JDPREFIX=Fix bash "$KIT/OdaijiJuxta-Mac.sh" --auto $MMARG
grep -E '^\s*(\[OK\]|\[KO\]|\[WARN\]|>>)' "$SPIN_OUT" | grep -iE 'galss|quarantaine|auto|ignore|medimust|prokov|medistory|coupe' | head -16
rm -f "$RAPDIR"/Fix_*.txt
if [ $WITH_AUTOFIX = 1 ]; then
    mkdir -p "$HOME/Library/Application Support/MadeForMed" "$HOME/Library/LaunchAgents"
    cp "$KIT/galss-autofix.sh" "$HOME/Library/Application Support/MadeForMed/"; chmod +x "$HOME/Library/Application Support/MadeForMed/galss-autofix.sh"
    sudo chown "$USER" /Library/Preferences/galss.ini 2>/dev/null
    sed "s#__HOME__#$HOME#g" "$KIT/fr.madeformed.galss-autofix.plist" > "$HOME/Library/LaunchAgents/fr.madeformed.galss-autofix.plist"
    launchctl bootout gui/$(id -u)/fr.madeformed.galss-autofix 2>/dev/null; launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/fr.madeformed.galss-autofix.plist"
    cp "$KIT/Reparer-lecteur.command" "$HOME/Desktop/"; chmod +x "$HOME/Desktop/Reparer-lecteur.command"; xattr -d com.apple.quarantine "$HOME/Desktop/Reparer-lecteur.command" 2>/dev/null
    ok_ "Agent galss-autofix installe + icone Reparer-lecteur sur le Bureau"
fi

# ---------------------------------------------------------------- 4b. NAVIGATEURS
say_ "4b/6  Chrome / Edge : autoriser Odaiji a joindre JuxtaLink (Local Network Access)"
bash "$KIT/Autoriser-Odaiji-Chrome.command" 2>&1 | grep -v 'Mot de passe' | sed 's/^/    /'
# 01/10 (MacBook Air Audrey) : LNA restait KO apres l'installation -> on verifie, et on reessaie une fois en affichant les erreurs
for dom in com.google.Chrome com.microsoft.Edge; do
    [ -d "/Applications/$([ $dom = com.google.Chrome ] && echo 'Google Chrome' || echo 'Microsoft Edge').app" ] || continue
    if defaults read "/Library/Preferences/$dom" LocalNetworkAccessAllowedForUrls 2>/dev/null | grep -q odaiji; then ok_ "Politique Local Network Access en place ($dom)"
    else
        ko_ "Politique Local Network Access absente ($dom) : nouvelle tentative"
        sudo defaults write "/Library/Preferences/$dom" LocalNetworkAccessAllowedForUrls -array "https://app.odaiji.co" "https://[*.]odaiji.co" "https://[*.]madeformed.fr" "https://[*.]juxta.cloud"; echo "    (code $?)"
        sudo chmod 644 "/Library/Preferences/$dom.plist" 2>/dev/null
        defaults read "/Library/Preferences/$dom" LocalNetworkAccessAllowedForUrls 2>&1 | sed 's/^/    /'
    fi
done

# ---------------------------------------------------------------- 5. LANCER
# 01/10 : ordre impose  user.config MadeForMed (3b) -> (re)lancement -> verification -> SEULEMENT ENSUITE enregistrement de la situation de facturation.
say_ "5/6  Lancement de JuxtaLink (avec la configuration MadeForMed)"
# Ordre impose : 1) user.config MadeForMed ecrit PARTOUT, 2) JuxtaLink arrete, 3) JuxtaLink relance (il installe alors tout seul FSV/GALSS/MICA/Cryptolib du plugin SSV).
# Si JuxtaLink reecrit sa config au demarrage, on recommence en verrouillant le fichier (chflags uchg) ; 3 essais.
UCMAIN="$APP/Contents/Resources/user.config"
for essai in 1 2 3; do
    pkill -x JuxtaLink 2>/dev/null; sleep 2
    if [ -f "$KIT/user.config" ]; then
        while IFS= read -r UC_DST; do [ -z "$UC_DST" ] && continue
            oj_poser_uc_dst "$KIT/user.config" "$UC_DST" >/dev/null 2>&1
        done <<< "$UC_LIST"
        [ "$essai" -ge 2 ] && sudo chflags uchg "$UCMAIN" 2>/dev/null
        sync
    fi
    if [ "$essai" = 1 ]; then echo "    JuxtaLink arrete, user.config MadeForMed pose, relance (le plugin SSV installe ses prerequis tout seul)..."; fi
    open -a JuxtaLink 2>/dev/null; sleep 8
    if [ ! -f "$KIT/user.config" ] || grep -q 'madeformed-drc-token' "$UCMAIN" 2>/dev/null; then break; fi
    ko_ "essai $essai : JuxtaLink a remis sa propre config (tokenServerUrl : $(grep -o 'tokenServerUrl" value="[^"]*"' "$UCMAIN" 2>/dev/null | cut -d'"' -f4))"
    ls -l "$UCMAIN" 2>&1 | sed 's/^/    /'
done
pgrep -x JuxtaLink >/dev/null && ok_ "JuxtaLink en cours d'execution" || ko_ "JuxtaLink ne s'est pas lance"
grep -q 'madeformed-drc-token' "$APP/Contents/Resources/user.config" 2>/dev/null && ok_ "user.config MadeForMed charge" || ko_ "user.config MadeForMed absent"
for i in 1 2 3 4 5 6 7 8 9 10; do lsof -nP -iTCP:1234 -sTCP:LISTEN >/dev/null 2>&1 && break; sleep 2; done
lsof -nP -iTCP:1234 -sTCP:LISTEN >/dev/null 2>&1 && ok_ "JuxtaLink ecoute sur le port 1234" || ko_ "Rien n'ecoute sur le port 1234 (JuxtaLink demarre encore ? sinon envoyer le rapport)"
printf '\a'
printf '\n\033[1;97;45m%s\033[0m\n' "  ######################################################################  " \
  "  #  JUXTALINK REDEMARRE : installation automatique en cours de       #  " \
  "  #     FSV  -  GALSS  -  MICA  -  Cryptolib                          #  " \
  "  #  (accepter les demandes macOS si elles apparaissent)              #  " \
  "  #                                                                    #  " \
  "  #  APRES L'INSTALLATION, dans Odaiji (navigateur) :                 #  " \
  "  #     -> Enregistrer la situation de facturation                    #  " \
  "  #        (l'installation des SSV demarre a ce moment-la)            #  " \
  "  #     -> puis UNE lecture CPS + Vitale (cartes inserees)            #  " \
  "  ######################################################################  "
echo
read -r -p "    Entree quand l'installation est terminee et la situation de facturation enregistree (ou tout de suite pour passer) "

# ---------------------------------------------------------------- 5b. SANS GALSS
if [ $SANS_GALSS = 1 ]; then
    say_ "5b/6  Full PC/SC (demande Juxta) : retrait du GALSS Juxta + blocage de sa reinstallation"
    spin_ "Retrait du GALSS Juxta en cours" env JDPREFIX=Galss bash "$KIT/OdaijiJuxta-Mac.sh" --auto --sans-galss
    grep -E '7g|Prerequis|BLOQUER|GALSS|>>>' "$SPIN_OUT" | head -12
    rm -f "$RAPDIR"/Galss_*.txt
    read -r -p "    Dans Odaiji : une facture avec une carte Vitale, puis une facture sans Vitale (valider l'appel ADRi), puis Entree "
fi

# ---------------------------------------------------------------- 5c. REDEMARRAGE PROPRE
# Retour terrain (PC DRSAMITIER 24/09) : 1re lecture Vitale en echec, OK apres redemarrage de JuxtaLink.
# On termine toujours par un redemarrage pour charger le plugin et la configuration finale.
say_ "5c/6  Redemarrage propre de JuxtaLink"
pkill -x JuxtaLink 2>/dev/null; sleep 3
open -a JuxtaLink 2>/dev/null; sleep 10
pgrep -x JuxtaLink >/dev/null && ok_ "JuxtaLink redemarre" || ko_ "JuxtaLink ne s'est pas relance : l'ouvrir depuis Applications"
# 01/10 : verification finale du user.config (JuxtaLink l'a pu reecrire) ; si les serveurs MadeForMed ont disparu, on le repose et on relance.
if [ -f "$KIT/user.config" ] && ! grep -q 'madeformed-drc-token' "$APP/Contents/Resources/user.config" 2>/dev/null; then
    ko_ "user.config sans les serveurs MadeForMed : repose et relance de JuxtaLink"
    pkill -x JuxtaLink 2>/dev/null; sleep 2
    oj_poser_uc "$KIT/user.config" >/dev/null 2>&1 || oj_msg_permission
    open -a JuxtaLink 2>/dev/null; sleep 8
else ok_ "user.config MadeForMed en place"; fi
echo "    >>> CONTROLE dans Odaiji : une facture avec une carte Vitale, puis une facture sans Vitale (valider l'appel ADRi)."
read -r -p "    Entree une fois les deux factures faites "

say_ "5d/6  Gardien : veille de JuxtaLink toutes les 10 min"
gardien_

# ---------------------------------------------------------------- 6. APRES
say_ "6/6  Diagnostic APRES"
spin_ "Analyse du Mac en cours (1 a 2 min)" env JDPREFIX=Apres bash "$KIT/OdaijiJuxta-Mac.sh"
APRES=$(ls -t "$RAPDIR"/Apres_*.txt 2>/dev/null | head -1); ok_ "Rapport : $APRES"
echo; grep -E 'Scenario :' "$APRES"; grep -E '^\s*\[KO\]|^\s*\[WARN\]' "$APRES" | head -10
[ -f "$KIT/odaiji-commun.sh" ] && [ -n "${AVANT:-}" ] && [ -f "$AVANT" ] && { . "$KIT/odaiji-commun.sh" 2>/dev/null; oj_delta "$AVANT" "$APRES"; }
echo
echo "Termine. Rapports et journal transmis automatiquement a MadeForMed (copie locale : $RAPDIR)."
bash "$KIT/envoyer-journal.sh" "$JOURNAL" "journal installation"
