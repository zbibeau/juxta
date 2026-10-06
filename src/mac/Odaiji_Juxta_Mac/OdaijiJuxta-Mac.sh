#!/bin/bash
# =====================================================================
#  OdaijiJuxta-Mac (ex JuxtaDiag-Mac) - Diagnostic & reparation JuxtaLink
#  MadeForMed / Odaiji
# =====================================================================
#  Version : 0.3  (23/09/2026)
#
#  USAGE
#    Diagnostic (lecture seule)    : bash ~/Downloads/JuxtaDiag-Mac.sh
#    Reparation (avec confirmations): bash ~/Downloads/JuxtaDiag-Mac.sh --fix
#    Rapport sur le Bureau : JuxtaDiag-Mac_<nom>_<date>.txt -> a coller a Claude.
#
#  CHANGELOG
#    0.3.8 - erreur Mica du log ignoree si anterieure au dernier demarrage de JuxtaLink
#    0.3.7 - plus de parcours de ~/Library (demandes macOS iCloud/OneDrive/Photos supprimees)
#    0.3.6 - (MacBook Pro 01/10) installateur : JuxtaLink arrete apres le pkg, user.config pose partout et verifie ; diag : user.config MadeForMed controle
#    0.3.5 - (Mac mini Lancelot 30/09) version DmpConnect lue via pkgutil ; accents des logs conserves (locale UTF-8) ;
#            BLOQUERINSTALLEGALSS sans virgule finale ; "Plugins non inscriptible" = info si le plugin est installe
#    0.3.4 - (Dr De Paris 28/09) CPS reconnue par ATR elargi (3bdc... Telium) ; galss.ini a fins de ligne CR (Mac classique)
#            lu correctement ; MediStory (Prokov) ajoute aux anciens logiciels (question + coupure, rien supprime)
#    0.3.3 - (1er Mac terrain 28/09) Aucun lecteur : inventaire USB (ioreg), lecteur sur clavier, autorisation accessoires ;
#            MediMust : detection + 7m "facture-t-il ENCORE avec MediMust ?" (n = coupe, rien supprime) ;
#            --sans-galss : GALSS jamais retire si DMP Connect / iCanopee est installe (il l'utilise)
#    0.3  - Section 4b NAVIGATEURS : version Chrome/Edge + politique Local Network Access (erreurs DRC)
#         - --sans-galss : passage Full PC/SC (retrait du paquet GALSS, BLOQUERINSTALLEGALSS=true)
#         - Renomme OdaijiJuxta-Mac ; variable JDPREFIX pour nommer le rapport (Avant/Apres)
#         - Detection galss.ini en mode SERIE (GALSS_SERIE) et generation PC/SC via galss-autofix
#         - Mode --auto : applique sans question les corrections sures (galss.ini, quarantaine)
#         - Recu de paquet orphelin : faux positif DmpConnect corrige
#    0.2  - Processus Java detectes (JavaAppLauncher, "Gestion Lecteur SV")
#         - Agent jFSE Cegedim (org.clm.jfse) : detection + suppression (--fix)
#         - Codes de sortie launchd interpretes (negatif = crash par signal)
#         - Crash reports DmpConnect / diagAM comptes
#         - Section cartes reduite aux lecteurs (plus de certificats)
#         - Recherche logs JuxtaLink elargie
#         - Recus de paquets orphelins (fichiers absents) marques *
#         - Coherence galss.ini <-> lecteur reel
#         - Verdict : READER / JFSE_AGENT / DMPCONNECT / DIAGAM / OK / UNKNOWN
#         - Mode --fix : jFSE, diagAM ; DmpConnect = arret temporaire seulement
#    0.1  Premiere version : inventaire.
# =====================================================================

VERSION="1.1.3"
export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8   # accents des logs JuxtaLink conserves (sudo/terminal en locale C)
FIX=0; AUTO=0; SANSGALSS=0; SANSLIST=","; LEGER=0
for a in "$@"; do [ "$a" = "--leger" ] && LEGER=1; [ "$a" = "--fix" ] && FIX=1; [ "$a" = "--auto" ] && { FIX=1; AUTO=1; }; [ "$a" = "--sans-galss" ] && { FIX=1; SANSGALSS=1; }; case "$a" in --sans-*) SANSLIST="$SANSLIST${a#--sans-},";; esac; done
# Anciens logiciels metiers Mac (cle | libelle | motif) - meme principe que editeurs.psd1 sur PC
OLD_KEYS=(medimust prokov); OLD_LBL=("MediMust" "MediStory (Prokov)"); OLD_PAT=("medimust" "prokov|medistory|m.distory")
KITDIR="$(cd "$(dirname "$0")" && pwd)"
STAMP=$(date +%Y%m%d-%H%M)
HOST=$(scutil --get ComputerName 2>/dev/null | tr ' ' '_'); [ -z "$HOST" ] && HOST=$(hostname -s)
REPORT="$HOME/Desktop/${JDPREFIX:-OdaijiJuxta-Mac}_${HOST}_${STAMP}.txt"
# --leger (sentinelle) : diagnostic passif. Jamais de reparation, aucune sonde du lecteur / des cartes, rapport hors du Bureau.
if [ "$LEGER" = 1 ]; then FIX=0; AUTO=0; SANSGALSS=0; LDIR="${ODAIJI_REPORT_DIR:-/Library/Application Support/MadeForMed/sentinelle}"; mkdir -p "$LDIR" 2>/dev/null; REPORT="$LDIR/${JDPREFIX:-Sentinelle}_${HOST}_${STAMP}.txt"; fi
UID_=$(id -u)
PAT='sesam|santesocial|galss|mica|cryptolib|cps|fsv|ssv|juxta|prokov|medistory|médistory|medimust|médimust|cegedim|clm|jfse|icanopee|dmpconnect|omnidoc|olaqin|ingenico|sensyl|vitale|diagam'
PROCPAT='galss|mica|prokov|medistory|medimust|cegedim|jfse|JavaAppLauncher|Gestion Lecteur|dmpconnect|icanopee|omnidoc|juxta|pcscd|ctkpcscd|diagam|java'

FINDINGS=()
w()   { printf '%s\n' "$*" | tee -a "$REPORT"; }
h1()  { w ""; w "======================================================================"; w "  $*"; w "======================================================================"; }
h2()  { w ""; w "--- $*"; }
ok()  { w "  [OK]   $*"; }
warn(){ w "  [WARN] $*"; }
ko()  { w "  [KO]   $*"; }
info(){ w "         $*"; }
finding(){ FINDINGS+=("$1|$2|$3"); }
has()  { local f; for f in "${FINDINGS[@]}"; do [[ "$f" == "$1|"* ]] && return 0; done; return 1; }
confirm(){ local r; if [ $AUTO = 1 ]; then [ "$2" = "safe" ] && { w ">> $1 -> oui (auto)"; return 0; } || { w ">> $1 -> ignore en mode auto (action a valider par un humain)"; return 1; }; fi; read -r -p ">> $1 [o/N] " r; [[ "$r" =~ ^[oOyY] ]]; }

: > "$REPORT"
h1 "OdaijiJuxta-Mac v$VERSION - $(date '+%d/%m/%Y %H:%M')"
POSTE_ID=""; [ -f "$KITDIR/odaiji-commun.sh" ] && { . "$KITDIR/odaiji-commun.sh" 2>/dev/null && POSTE_ID=$(oj_poste_id); }
info "Mac         : $HOST   Utilisateur : $USER${POSTE_ID:+   Poste ID : $POSTE_ID}"
info "Rapport     : $REPORT"
if [ $FIX = 1 ]; then info "Mode        : REPARATION"; else info "Mode        : DIAGNOSTIC (lecture seule)"; fi
w ""
sudo -v 2>/dev/null || warn "Pas de droits sudo : certaines sections seront incompletes."

# =====================================================================
h1 "1. SYSTEME"
# =====================================================================
info "macOS       : $(sw_vers -productName) $(sw_vers -productVersion) (build $(sw_vers -buildVersion))"
ARCH=$(uname -m); info "Architecture: $ARCH   Modele : $(sysctl -n hw.model)"
if [ "$ARCH" = "arm64" ]; then
    if /usr/bin/pgrep -q oahd; then ok "Rosetta 2 installe"; else ko "Rosetta 2 absent -> softwareupdate --install-rosetta"; finding ROSETTA KO "Rosetta 2 absent"; fi
fi
GK=$(spctl --status 2>&1); info "Gatekeeper  : $GK"
echo "$GK" | grep -qi disabled && { warn "Gatekeeper DESACTIVE sur tout le Mac (effet du preinstall JuxtaLink : spctl --master-disable). Reactiver : sudo spctl --master-enable"; finding GATEKEEPER_OFF WARN "Gatekeeper desactive"; }

# =====================================================================
h1 "2. LECTEURS ET CARTES"
# =====================================================================
h2 "Lecteurs vus par macOS"
if [ "$LEGER" = 1 ]; then
    SC=""; info "Mode leger (sentinelle) : lecteur et cartes non sondes (aucun acces a la carte)"
else
    SC=$(system_profiler SPSmartCardsDataType 2>/dev/null)
    READERS=$(echo "$SC" | sed -n '/Readers:/,/Reader Drivers:/p' | grep -E '^[[:space:]]+#')
    if [ -n "$READERS" ]; then
        echo "$READERS" | sed 's/^/         /' | tee -a "$REPORT"
        CPS_R=$(echo "$READERS" | grep -ciE '0x3bac00402a|0x3b7b18|0x3bdc18|12250064800')
        VIT_R=$(echo "$READERS" | grep -c '0x3b7513')
        if [ "$CPS_R" -gt 0 ]; then ok "CPS presente"; else ko "CPS non vue"; finding NO_CPS KO "CPS non detectee"; fi
        if [ "$VIT_R" -gt 0 ]; then ok "Vitale presente"
        elif [ "$CPS_R" -gt 0 ]; then warn "Vitale non vue (absente du lecteur ? inserer la carte et relancer)"; finding VITALE_ABSENT WARN "Vitale non inseree ou non lue"
        else ko "Vitale non vue"; finding NO_VITALE KO "Vitale non detectee"; fi
    else
        ko "Aucun lecteur vu par macOS"; finding NO_READER KO "Aucun lecteur smartcard"
        # 28/09 (1er Mac) : SPUSBDataType vide sur macOS 15+ -> ioreg ; lecteur HS / branche sur le clavier
        h2 "Appareils USB branches (ioreg)"
        USBL=$(ioreg -p IOUSB -w0 2>/dev/null | grep -o '+-o [^<@]*' | sed 's/+-o //; s/ *$//' | grep -viE '^Root$|XHCI')
        if [ -n "$USBL" ]; then echo "$USBL" | sed 's/^/         /' | tee -a "$REPORT"; else info "(aucun appareil USB)"; fi
        if echo "$USBL" | grep -qiE 'reader|lecteur|sensyl|fei|ingenico|olaqin|kapelse|identive|gemalto|ccid|smart ?card|xiring|telium'; then
            warn "Un lecteur est branche en USB mais n'apparait pas comme lecteur de cartes : autorisation des accessoires (Reglages Systeme > Confidentialite et securite > Autoriser les accessoires a se connecter : Toujours) ou pilote"; finding USB_READER_NOT_SC WARN "Lecteur vu en USB mais pas comme lecteur de cartes"
        else
            ko "Aucun lecteur sur le bus USB : adaptateur USB-C, cable ou lecteur HS (tester le lecteur sur un autre poste)"; finding USB_NO_READER KO "Lecteur absent du bus USB"
        fi
        echo "$USBL" | grep -qi 'Keyboard Hub' && warn "Clavier avec hub USB branche : ne PAS y brancher le lecteur (courant insuffisant)"
        info "macOS 15+ : a la 1re connexion d'un lecteur, accepter 'Autoriser l'accessoire a se connecter ?' (Mac deverrouille)"
    fi
fi
h2 "Pilotes lecteur"
echo "$SC" | sed -n '/Reader Drivers:/,/SmartCard Drivers:/p' | grep -E '^[[:space:]]+#' | sed 's/^/         /' | tee -a "$REPORT"

h2 "Processus clients du lecteur (en ce moment)"
PROCS=$(ps -axo pid,etime,comm | grep -iE "$PROCPAT" | grep -v grep)
if [ -n "$PROCS" ]; then echo "$PROCS" | sed 's/^/         /' | tee -a "$REPORT"; else info "(aucun)"; fi
N_DMP=$(echo "$PROCS" | grep -ci 'dmpconnect-js2$')
N_PCSC=$(echo "$PROCS" | grep -ci 'ctkpcscd')
JFSE_RUN=$(echo "$PROCS" | grep -ciE 'JavaAppLauncher|Gestion Lecteur')
info "dmpconnect-js2 : $N_DMP instance(s)   ctkpcscd : $N_PCSC   agent jFSE : $JFSE_RUN"
if [ "$N_DMP" -gt 1 ]; then warn "Plusieurs dmpconnect-js2 simultanes"; finding DMP_MULTI WARN "$N_DMP instances dmpconnect-js2"; fi
if [ "$JFSE_RUN" -gt 0 ]; then ko "Agent jFSE 'Gestion Lecteur SV' EN COURS D'EXECUTION"; finding JFSE_RUN KO "Agent jFSE actif (tient le lecteur)"; fi

# =====================================================================
h1 "3. PILE SESAM-VITALE ET EDITEURS"
# =====================================================================
h2 "Paquets installes (pkgutil) - * = fichiers absents (recu orphelin)"
pkgutil --pkgs 2>/dev/null | grep -iE "$PAT" | while read -r p; do
    inf=$(pkgutil --pkg-info "$p" 2>/dev/null)
    v=$(echo "$inf" | awk -F': ' '/^version/{print $2}')
    d=$(echo "$inf" | awk -F': ' '/install-time/{print $2}')
    loc=$(echo "$inf" | awk -F': ' '/^location/{print $2}')
    dt=""; [ -n "$d" ] && dt=$(date -r "$d" '+%d/%m/%Y' 2>/dev/null)
    orph=" "; if [ -n "$loc" ] && [ "$loc" != "/" ] && [ ! -e "/$loc" ]; then orph="*"; fi
    info "$(printf '%s%-52s v%-11s %-11s %s' "$orph" "$p" "$v" "$dt" "$loc")"
done

h2 "jFSE (Cegedim / Medimust / MediStory)"
JFSE_PLIST=$(ls /Library/LaunchAgents/org.clm.jfse* "$HOME"/Library/LaunchAgents/org.clm.jfse* 2>/dev/null)
if [ -n "$JFSE_PLIST" ]; then ko "Agent de demarrage jFSE : $JFSE_PLIST"; finding JFSE_AGENT KO "Agent launchd jFSE present"; else ok "Pas d'agent launchd jFSE"; fi
if [ -d /Applications/jFSE ]; then
    warn "/Applications/jFSE present"; finding JFSE_DIR WARN "/Applications/jFSE present"
    L=/Applications/jFSE/Lecteur/logDebug.txt
    [ -f "$L" ] && info "Derniere activite jFSE Lecteur : $(tail -1 "$L" | cut -c1-23)"
else ok "/Applications/jFSE absent"; fi

h2 "Anciens logiciels metiers (MediMust, MediStory...)"
OLD_ACTIVE=""
for i in "${!OLD_KEYS[@]}"; do
    k=${OLD_KEYS[$i]}; lbl=${OLD_LBL[$i]}; pat=${OLD_PAT[$i]}
    pl=$(sudo grep -rilE "$pat" /Library/LaunchDaemons /Library/LaunchAgents "$HOME/Library/LaunchAgents" 2>/dev/null)
    pr=$(ps -axo pid,args | grep -iE "$pat" | grep -v grep)
    if [ -n "$pl$pr" ]; then
        warn "$lbl encore actif (demarrage automatique / processus) : a couper si le medecin ne facture plus avec (--fix, etape 7m)"; finding "OLD_$(echo "$k" | tr a-z A-Z)" WARN "$lbl actif"
        OLD_ACTIVE="$OLD_ACTIVE $i"
        echo "$pl" | grep . | sed 's/^/         demarrage : /' | tee -a "$REPORT"
        echo "$pr" | grep . | cut -c1-140 | sed 's/^/         processus : /' | tee -a "$REPORT"
    elif ls /Applications 2>/dev/null | grep -qiE "$pat" || pkgutil --pkgs 2>/dev/null | grep -qiE "$pat"; then ok "$lbl installe mais inactif (rien ne se lance)"
    else ok "$lbl absent"; fi
done

h2 "GALSS Juxta - politique Full PC/SC"
GPKG=$(pkgutil --pkgs 2>/dev/null | grep -i 'sesamvitale.galss')
[ -n "$GPKG" ] && info "GALSS installe : $GPKG v$(pkgutil --pkg-info "$GPKG" 2>/dev/null | awk -F': ' '/^version/{print $2}')" || info "GALSS absent (Full PC/SC)"
[ -d /Library/Frameworks/galssosx.framework ] && info "galssosx.framework present"
BLOQ=$(grep -ho 'BLOQUERINSTALLEGALSS" value="[a-z]*"' /Applications/JuxtaLink.app/Contents/Resources/Plugins/SSV/*/SSV.dll.config 2>/dev/null | grep -o '"[a-z]*"$' | tr -d '"' | sort -u | tr '\n' ',' | sed 's/,$//')
info "BLOQUERINSTALLEGALSS dans le plugin SSV : ${BLOQ:-(plugin non installe)}"
if [ -n "$GPKG" ] && echo "$BLOQ" | grep -q true; then warn "GALSS revenu alors que sa reinstallation est bloquee (MAJ du plugin ?)"; finding GALSS_BACK WARN "GALSS reinstalle malgre le blocage"; fi
CRYPTO_GALSS=0
if sudo grep -qiE 'galss\s*=\s*(1|true|oui)|filiere\s*=\s*galss' /Library/Preferences/santesocial/CPS/*.conf /etc/cps3_pkcs11* 2>/dev/null; then warn "Cryptolib CPS configuree en filiere GALSS : a reinstaller en Full PC/SC avant de retirer GALSS"; finding CRYPTO_GALSS WARN "Cryptolib en mode GALSS"; CRYPTO_GALSS=1; fi

h2 "DmpConnect-JS2 (Icanopee)"
[ -d /Applications/DmpConnectJS2.app ] && DMPV=$(defaults read /Applications/DmpConnectJS2.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null); [ -z "$DMPV" ] && DMPV=$(pkgutil --pkg-info org.icanopee.dmpcjs2 2>/dev/null | awk -F': ' '/^version/{print $2}'); info "Installe : v${DMPV:-inconnue}"
ls /Library/LaunchDaemons/com.icanopee.* /Library/LaunchAgents/com.icanopee.* "$HOME"/Library/LaunchAgents/com.icanopee.* 2>/dev/null | sed 's/^/         /' | tee -a "$REPORT"

h2 "diagAM (telemetrie GIE)"
if [ -d /Applications/DiagAM.app ] || ls "$HOME"/Library/LaunchAgents/fr.sesam-vitale.diagam* >/dev/null 2>&1; then
    warn "diagAM installe (inutile pour la facturation)"; finding DIAGAM WARN "diagAM present"
else ok "diagAM absent"; fi

h2 "Fichiers de configuration GIE"
for f in /Library/Preferences/galss.ini /etc/galss.ini /etc/sesam.ini /Library/Preferences/sesam.ini; do
    if sudo test -f "$f" 2>/dev/null; then
        sz=$(sudo stat -f %z "$f")
        if [ "$sz" -lt 50 ]; then ko "$f VIDE"; finding GALSS_EMPTY KO "$f vide"; else ok "$f ($sz octets)"; fi
        sudo cat "$f" | tr '\r' '\n' | grep -iE 'Caracteristiques|NomLib|NomLAD|RepertoireTable' | sed 's/^/             /' | tee -a "$REPORT"
    fi
done
if sudo grep -qiE '^Caracteristiques=[0-9]+,[0-9]+' /Library/Preferences/galss.ini 2>/dev/null || ! sudo grep -qi 'pcscosx' /Library/Preferences/galss.ini 2>/dev/null; then
    ko "galss.ini en mode SERIE (COM/PSS) : aucun canal PC/SC -> JuxtaLink ne verra pas les cartes via GALSS"; finding GALSS_SERIE KO "galss.ini en mode serie"
fi
GI=$(sudo cat /Library/Preferences/galss.ini /etc/galss.ini 2>/dev/null | tr '\r' '\n' | grep -i Caracteristiques | head -1 | cut -d= -f2 | cut -c1-6)
RN=$(echo "$READERS" | head -1 | sed -E 's/^[[:space:]]*#[0-9]+: //; s/ \(ATR.*//')
if [ -n "$GI" ] && [ -n "$RN" ] && ! echo "$RN" | grep -qi "$GI"; then
    warn "galss.ini declare '$GI...' mais macOS voit '$RN'"; finding GALSS_MISMATCH WARN "galss.ini ne correspond pas au lecteur reel"
fi

h2 "Bibliotheques MICA / GALSS et leur architecture"
sudo find /usr/local/lib /Library/Frameworks "/Library/Application Support/santesocial" /usr/local/dmpconnectjs2 "$HOME/Library/Application Support"/*[jJ]uxta* -maxdepth 5 \( -iname 'libmica*' -o -iname 'galss*' \) -type f 2>/dev/null | while read -r f; do
    a=$(file -b "$f" 2>/dev/null | grep -oE 'x86_64|arm64' | sort -u | tr '\n' '/' | sed 's#/$##')
    info "$(printf '%-95s %s' "$f" "$a")"
done

h2 "Applications metier"
ls -1 /Applications 2>/dev/null | grep -iE 'medistory|médistory|medimust|médimust|juxta|odaiji|cegedim|prokov|dmp|icanopee|omnidoc|jfse|diagam' | sed 's/^/         /' | tee -a "$REPORT"

# =====================================================================
h1 "4. SERVICES launchd (col.2 = dernier code de sortie ; negatif = crash par signal)"
# =====================================================================
{ launchctl list 2>/dev/null; sudo launchctl list 2>/dev/null; } | grep -iE "$PAT" | grep -viE 'com\.apple' | sort -u -k3 | while read -r pid st lbl; do
    if [ "$st" -lt 0 ] 2>/dev/null; then
        ko "$(printf '%-6s %-5s %s   <- CRASH (signal %s)' "$pid" "$st" "$lbl" "${st#-}")"
        echo "CRASH_$(echo "$lbl" | tr '.-' '__')|KO|$lbl crashe (signal ${st#-})" >> "$REPORT.findings"
    else info "$(printf '%-6s %-5s %s' "$pid" "$st" "$lbl")"; fi
done
if [ -f "$REPORT.findings" ]; then while IFS='|' read -r c l m; do finding "$c" "$l" "$m"; done < "$REPORT.findings"; rm -f "$REPORT.findings"; fi
h2 "Crash reports (30 derniers jours)"
for k in dmpconnect diagam juxta galss JavaAppLauncher; do
    n=$(find "$HOME/Library/Logs/DiagnosticReports" /Library/Logs/DiagnosticReports -iname "*$k*" -mtime -30 2>/dev/null | wc -l | tr -d ' ')
    if [ "$n" -gt 0 ]; then last=$(ls -t "$HOME"/Library/Logs/DiagnosticReports/*$k* /Library/Logs/DiagnosticReports/*$k* 2>/dev/null | head -1); warn "$k : $n crash(s), dernier : $(basename "$last")"; fi
done

# =====================================================================
h1 "4b. NAVIGATEURS - Local Network Access (erreurs DRC a la teletransmission)"
# =====================================================================
for b in "Google Chrome|com.google.Chrome" "Microsoft Edge|com.microsoft.Edge"; do
    name="${b%%|*}"; dom="${b##*|}"; app="/Applications/$name.app"
    [ -d "$app" ] || { info "$name non installe"; continue; }
    ver=$(defaults read "$app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null); major=${ver%%.*}
    pol=$(defaults read "/Library/Preferences/$dom" LocalNetworkAccessAllowedForUrls 2>/dev/null | tr -d '\n ')
    if echo "$pol" | grep -q odaiji; then ok "$name $ver : politique Local Network Access OK"
    elif [ "${major:-0}" -ge 142 ]; then ko "$name $ver : Local Network Access actif et Odaiji non autorise -> erreurs DRC possibles (Autoriser-Odaiji-Chrome.command)"; finding "LNA_${name// /_}" KO "$name sans politique Local Network Access"
    else info "$name $ver : < 142, pas encore concerne ; politique a poser quand meme"; fi
done

# =====================================================================
h1 "5. JUXTALINK"
# =====================================================================
JAPP=$(ls -d /Applications/JuxtaLink*.app 2>/dev/null | head -1)
if [ -n "$JAPP" ]; then
    ok "$JAPP  v$(defaults read "$JAPP/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)  ($(file -b "$JAPP/Contents/MacOS/"* 2>/dev/null | grep -oE 'x86_64|arm64' | sort -u | tr '\n' ' '))"
else warn "JuxtaLink absent de /Applications"; fi
if [ -n "$JAPP" ]; then
    PLUG="$JAPP/Contents/Resources/Plugins"
    NPLUG=$(ls -d "$PLUG"/SSV/[0-9]* 2>/dev/null | wc -l | tr -d ' ')
    if [ "$NPLUG" -gt 0 ]; then ok "Plugin SSV present : $(ls -d "$PLUG"/SSV/[0-9]* | xargs -n1 basename | tr '\n' ' ')"
    else warn "Dossier Plugins vide : le plugin SSV n'a pas ete telecharge (copie manuelle necessaire sur Mac)"; finding NO_PLUGIN WARN "Plugin SSV absent"; fi
    if [ -f "$JAPP/Contents/Resources/user.config" ]; then
        if grep -q 'madeformed-drc-token' "$JAPP/Contents/Resources/user.config"; then ok "user.config MadeForMed (serveurs token/update)"
        else ko "user.config sans les serveurs MadeForMed (erreurs token 1100 / update 1200 dans Odaiji). Correction : 1-Installer.command"; finding UC_NOT_MFM KO "user.config sans serveurs MadeForMed"; fi
    else warn "user.config absent de $JAPP/Contents/Resources"; finding UC_ABSENT WARN "user.config absent"; fi
    UPD=$(grep -o 'updateServerUrl" value="[^"]*"' "$JAPP/Contents/Resources/user.config" 2>/dev/null | cut -d'"' -f4)
    if [ -n "$UPD" ]; then HTTP=$(curl -sS -o /dev/null -w '%{http_code}' -m 8 "$UPD/" 2>/dev/null); info "Serveur de mise a jour $UPD -> HTTP ${HTTP:-injoignable}"; [ "${HTTP:-000}" = "000" ] && { warn "Serveur de mise a jour injoignable (proxy/reseau ?)"; finding UPD_UNREACHABLE WARN "Serveur MAJ Juxta injoignable"; }; fi
    if [ ! -w "$PLUG" ] 2>/dev/null; then if [ "$NPLUG" -gt 0 ]; then info "Dossier Plugins non inscriptible par l'utilisateur (normal : le plugin est deja installe)"; else warn "Dossier Plugins non inscriptible par l'utilisateur ET plugin absent : copie manuelle a faire"; fi; fi
fi
# 04/10 : gardien (veille de JuxtaLink toutes les 10 min)
if [ -n "$JAPP" ]; then
    if launchctl print gui/$(id -u)/fr.madeformed.juxtalink-gardien >/dev/null 2>&1; then ok "Gardien JuxtaLink : veille toutes les 10 min"
    else warn "Gardien JuxtaLink absent : JuxtaLink ne serait pas relance s'il est ferme ou plante (2-Depanner.command)"; finding GARDIEN_ABSENT WARN "Pas de gardien : JuxtaLink n'est pas relance s'il s'arrete"; fi
fi
# 01/10 : ne plus parcourir tout ~/Library (declenchait les demandes macOS iCloud / OneDrive / Photos) : seulement les dossiers Juxta
LOGDIRS=("$JAPP/Contents/Resources/logs"); for d in "$HOME/Library/Application Support"/*[jJ]uxta* "$HOME/Library/Logs"/*[jJ]uxta*; do [ -d "$d" ] && LOGDIRS+=("$d"); done
LOGF=$(find "${LOGDIRS[@]}" -maxdepth 7 \( -iname 'trace.txt' -o -iname '*.log' \) 2>/dev/null | head -1)
JLOG_OK=0
if [ -n "$LOGF" ]; then
    h2 "Log JuxtaLink : $LOGF (40 dernieres lignes)"
    # 05/10 : les reponses d'erreur (base64) contiennent la requete d'origine, donc le code CPS : jamais dans un rapport
    tail -40 "$LOGF" | sed -E 's/[A-Za-z0-9+\/=]{80,}/[base64-omis]/g; s/([Cc]ode[Cc][Pp][Ss][^0-9]{0,6})[0-9]{4,8}/\1****/g; s/(^|[^A-Za-z])([nN][uU][mM][nN][aA][tT][pP][sS]|[nN][uU][mM][eE][rR][oO][nN][aA][tT][pP][sS]|[fF][iI][nN][eE][sS][sS]|[nN][iI][rR]|[nN][uU][mM][sS][eE][cC][uU][A-Za-z]*|[nN][uU][mM][eE][rR][oO][sS][eE][cC][uU][A-Za-z]*|[dD][aA][tT][eE][nN][aA][iI][sS][sS][aA][nN][cC][eE]|[nN][oO][mM][pP][aA][tT][iI][eE][nN][tT]|[pP][rR][eE][nN][oO][mM][pP][aA][tT][iI][eE][nN][tT]|[rR][pP][pP][sS]|[aA][dD][eE][lL][iI])([^A-Za-z0-9]{1,6})[A-Za-z0-9]{3,}/\1\2\3[masque]/g; s/[0-9]{13,15}/[nir-masque]/g' | sed 's/^/         /' | tee -a "$REPORT"
    # 05/10 (MacBook Pro SACHOT) : CPS vue par macOS mais 'Carte CPS absente' pour le SSV, et erreur serveur 'facture inexistante'
    SLOTL=$(tail -400 "$LOGF" | grep -E 'Slot de carte trouv' | tail -1 | grep -oE '[0-9]+$')
    if tail -400 "$LOGF" | grep -E 'CPS pr.sente : (True|False)' | tail -1 | grep -q 'False' && [ "${CPS_R:-0}" -gt 0 ]; then
        ko "Le SSV cherche la CPS dans la fente ${SLOTL:-?} et la declare absente alors que macOS la voit dans un lecteur : fente mal attribuee ou lecteur tenu par un autre logiciel (jFSE, DMP Connect)"; finding CPS_SLOT_ABSENT KO "CPS vue par macOS mais absente pour le SSV (fente ${SLOTL:-?})"
        info "Lecteurs (ordre macOS) : $(echo "$SC" | grep -E '^[[:space:]]+#[0-9]+:' | grep -iE 'card|telium|reader' | sed -E 's/\(ATR.*//; s/^[[:space:]]+//' | tr '\n' ';')"
        info "galss.ini : $(sudo grep -iE 'Caracteristiques|NomLib' /Library/Preferences/galss.ini 2>/dev/null | tr '\r\n' '  ' | cut -c1-300)"
    fi
    if tail -400 "$LOGF" | grep -qE 'ewogICJBcmd1bWVudHMi'; then
        for B in $(tail -400 "$LOGF" | grep -oE 'ewogICJBcmd1bWVudHMi[A-Za-z0-9+/=]+' | sort -u | tail -3); do
            D=$(echo "$B" | base64 -d 2>/dev/null | grep -oE '"diagnostic": "[^"]*"' | head -1)
            case "$D" in *"existe pas"*) ko "Le serveur Intellio repond : facture inexistante (ce n'est ni la CPS ni le lecteur : verifier l'identifiant et l'environnement/URL de la facture cote Odaiji)"; finding FACTURE_INEXISTANTE KO "Intellio : la facture demandee n'existe pas";; esac
        done
    fi
    # 01/10 (MacBook Air Audrey) : une erreur Mica d'une session PRECEDENTE (avant l'installation de MICA par le plugin) n'est plus un KO
    LSTART=$(grep -n 'Le serveur est d.*marr' "$LOGF" | tail -1 | cut -d: -f1); LSTART=${LSTART:-0}
    LMICA=$(grep -nE 'Mica\.\.ctor|libmica' "$LOGF" | tail -1 | cut -d: -f1)
    if [ -n "$LMICA" ]; then
        if [ "$LMICA" -gt "$LSTART" ]; then ko "Signature MICA dans le log (session en cours)"; finding SIG_MICA KO "Erreur Mica dans log JuxtaLink"
        else info "Erreur Mica dans le log mais AVANT le dernier demarrage de JuxtaLink (session precedente) : ignoree"; fi
    fi
    grep -iE 'PluginsLoader|\[SEARCH\]|telecharg|download|UrlUpdate' "$LOGF" | grep -iE 'erreur|error|exception|echec|fail|introuvable' | tail -3 | sed 's/^/         MAJ plugin : /' | tee -a "$REPORT"
    tail -400 "$LOGF" | grep -qE 'Vitale pr.sente : True' && JLOG_OK=1
else
    info "Aucun log JuxtaLink trouve sous ~/Library (chemin Mac a identifier : envoyer le rapport a Claude)"
fi

# =====================================================================
h1 "6. VERDICT"
# =====================================================================
SCEN=UNKNOWN
if has NO_READER || { has NO_CPS && has NO_VITALE; }; then SCEN=READER; ko "macOS ne voit aucune carte -> lecteur / cable / pilote. JuxtaLink hors de cause."
elif has GALSS_SERIE || has GALSS_MISMATCH; then SCEN=GALSS; ko "galss.ini ne decrit pas le lecteur reel (mode serie ou mauvais nom). Correction : --fix / --auto (regeneration PC/SC)."
elif has JFSE_AGENT || has JFSE_RUN; then SCEN=JFSE_AGENT; ko "Agent jFSE 'Gestion Lecteur SV' present : il gere le lecteur pour Cegedim et entre en concurrence avec JuxtaLink."; info "Correction : --fix (suppression jFSE si le medecin ne facture plus avec Medimust/MediStory)."
elif has DMP_MULTI || has CRASH_com_icanopee_dmpcjsmonitor2; then SCEN=DMPCONNECT; warn "DmpConnect-JS2 instable (crash / instances multiples) : suspect principal de l'intermittence."; info "Test : --fix propose un arret temporaire."
elif has DIAGAM && has CRASH_fr_sesam_vitale_diagam_collecteur; then SCEN=DIAGAM; warn "diagAM crashe periodiquement ; a retirer (--fix)."
elif has NO_PLUGIN; then SCEN=NO_PLUGIN; ko "Plugin SSV absent de JuxtaLink : copier le dossier SSV/<version> dans Contents/Resources/Plugins/SSV/ puis faire une lecture."
elif [ $JLOG_OK = 1 ]; then SCEN=OK; ok "Derniere lecture Vitale OK dans le log JuxtaLink."
else warn "Cas non reconnu : envoyer ce rapport a Claude."; fi
if echo "$BLOQ" | grep -q true && [ -z "$GPKG" ] && [ $JLOG_OK = 0 ] && [ -n "$LOGF" ] && tail -400 "$LOGF" | grep -qE 'CPS pr.sente : False|Vitale pr.sente : False'; then
    warn "Lecture en echec alors que la reinstallation du GALSS est bloquee : retour a BLOQUERINSTALLEGALSS=false (filet de securite)"
    for c in /Applications/JuxtaLink.app/Contents/Resources/Plugins/SSV/*/SSV.dll.config; do [ -f "$c" ] && sudo sed -i '' 's/BLOQUERINSTALLEGALSS" value="true"/BLOQUERINSTALLEGALSS" value="false"/' "$c"; done
    finding GALSS_REVERT WARN "Blocage GALSS annule automatiquement (lecture en echec)"
fi
w ""; w "Scenario : $SCEN"; w "Constats :"
for f in "${FINDINGS[@]}"; do IFS='|' read -r c l m <<< "$f"; info "$(printf '%-38s %-5s %s' "$c" "$l" "$m")"; done

# =====================================================================
if [ $FIX = 1 ]; then
h1 "7. REPARATION"
# =====================================================================
    if has GALSS_SERIE || has GALSS_MISMATCH; then
        h2 "7-0. Regenerer galss.ini en PC/SC depuis les lecteurs vus par macOS"
        if confirm "Reecrire /Library/Preferences/galss.ini (sauvegarde .bak) ?" safe; then
            sudo cp /Library/Preferences/galss.ini "/Library/Preferences/galss.ini.bak-$STAMP" 2>/dev/null
            sudo chown "$USER" /Library/Preferences/galss.ini 2>/dev/null || sudo touch /Library/Preferences/galss.ini && sudo chown "$USER" /Library/Preferences/galss.ini
            bash "$KITDIR/galss-autofix.sh"; tail -1 "$HOME/Library/Logs/galss-autofix.log"
            grep -E 'Caracteristiques|NomLib' /Library/Preferences/galss.ini | sed 's/^/         /' | tee -a "$REPORT"
        fi
    fi
    if has GATEKEEPER_OFF; then
        h2 "7-0b. Gatekeeper"
        if confirm "Reactiver Gatekeeper (spctl --master-enable) ?" safe; then sudo spctl --master-enable; ok "Gatekeeper : $(spctl --status 2>&1)"; fi
    fi
    if [ -n "$JAPP" ] && xattr -p com.apple.quarantine "$JAPP" >/dev/null 2>&1; then
        h2 "7-1. Quarantaine Gatekeeper sur JuxtaLink"
        if confirm "Retirer l'attribut de quarantaine de $JAPP ?" safe; then sudo xattr -dr com.apple.quarantine "$JAPP"; ok "Quarantaine retiree"; fi
    fi
    if has JFSE_AGENT || has JFSE_RUN || has JFSE_DIR; then
        h2 "7a. Agent jFSE (Cegedim)"
        w "  Prerequis : le medecin ne facture PLUS depuis Medimust / MediStory."
        if echo "$SANSLIST" | grep -q ",jfse,"; then w ">> jFSE (Cegedim) n'est plus utilise (reponse donnee a l'installation) -> suppression"; JFSE_OK=1; elif confirm "Arreter et SUPPRIMER l'agent jFSE et /Applications/jFSE ?"; then JFSE_OK=1; else JFSE_OK=0; fi
        if [ "$JFSE_OK" = 1 ]; then
            launchctl bootout gui/$UID_/org.clm.jfse.launchd 2>/dev/null
            pkill -f "Gestion Lecteur SV"; pkill -f JavaAppLauncher; sleep 2
            sudo rm -f /Library/LaunchAgents/org.clm.jfse* "$HOME"/Library/LaunchAgents/org.clm.jfse*
            sudo rm -rf /Applications/jFSE
            for p in $(pkgutil --pkgs | grep -iE 'jfse'); do sudo pkgutil --forget "$p"; done
            if ps -axo pid,args | grep -v grep | grep -qiE 'Gestion Lecteur|JavaAppLauncher'; then ko "Un processus jFSE tourne encore"; else ok "jFSE supprime"; fi
        else warn "jFSE conserve"; fi
    fi
    for i in $OLD_ACTIVE; do
        k=${OLD_KEYS[$i]}; lbl=${OLD_LBL[$i]}; pat=${OLD_PAT[$i]}
        h2 "7m. $lbl"
        CUT=0
        if echo "$SANSLIST" | grep -q ",$k,"; then CUT=1; w ">> $lbl n'est plus utilise (reponse donnee a l'installation)"
        elif [ $AUTO = 1 ]; then w ">> Usage de $lbl non confirme en mode auto : rien n'est modifie (Reparer-interactif.command pour repondre)"
        else r=""; while [[ ! "$r" =~ ^[oOnN] ]]; do read -r -p ">> Le medecin facture-t-il ENCORE avec $lbl ? [o/n] (n = coupe, rien n'est supprime) " r; done; w ">> Facture encore avec $lbl ? -> $r"; [[ "$r" =~ ^[nN] ]] && CUT=1; fi
        if [ $CUT = 1 ]; then
            Q="$HOME/Desktop/_Odaiji_a_supprimer/$k-$STAMP"; mkdir -p "$Q"
            sudo grep -rilE "$pat" /Library/LaunchDaemons /Library/LaunchAgents "$HOME/Library/LaunchAgents" 2>/dev/null | while read -r f; do
                case "$f" in /Library/LaunchDaemons/*) sudo launchctl bootout system "$f" ;; *) launchctl bootout gui/$UID_ "$f"; sudo launchctl bootout gui/$UID_ "$f" ;; esac 2>/dev/null
                sudo mv "$f" "$Q/" && ok "Demarrage coupe : $f (sauvegarde dans $Q)"
            done
            sudo pkill -f -i "$pat"; sleep 2
            if ps -axo args | grep -v grep | grep -qiE "$pat"; then warn "Un processus $lbl tourne encore"; else ok "$lbl coupe (application et donnees conservees)"; fi
        fi
    done
    if has DIAGAM; then
        h2 "7b. diagAM"
        if confirm "Supprimer diagAM (telemetrie GIE, sans impact facturation) ?"; then
            for l in diagam_collecteur diagam_transmission diagam; do launchctl bootout gui/$UID_/fr.sesam-vitale.$l 2>/dev/null; done
            rm -f "$HOME"/Library/LaunchAgents/fr.sesam-vitale.diagam*.plist
            pkill -f DiagAM; sudo rm -rf /Applications/DiagAM.app
            sudo pkgutil --forget fr.sesamvitale.diagAM.pkg 2>/dev/null
            ok "diagAM supprime"
        fi
    fi
    if has DMP_MULTI || has CRASH_com_icanopee_dmpcjsmonitor2; then
        h2 "7c. DmpConnect-JS2 (arret TEMPORAIRE pour test, rien n'est supprime)"
        if confirm "Arreter DmpConnect jusqu'au prochain redemarrage pour tester la lecture Vitale ?"; then
            sudo launchctl bootout system/com.icanopee.dmpcjs2 2>/dev/null
            launchctl bootout gui/$UID_/com.icanopee.dmpcjsmonitor2 2>/dev/null
            pkill -f dmpconnect; sleep 1
            if ps -axo pid,comm | grep -v grep | grep -qi dmpconnect; then warn "DmpConnect tourne encore"; else ok "DmpConnect arrete. Faire 10 lectures Vitale. Il revient au redemarrage."; fi
        fi
    fi
    if [ $SANSGALSS = 1 ]; then
        h2 "7g. Passage en Full PC/SC : retrait du GALSS Juxta"
        # 28/09 (1er Mac) : sur Mac il n'y a qu'un GALSS, partage avec DMP Connect / iCanopee -> jamais retire dans ce cas
        if [ -d /usr/local/dmpconnectjs2 ] || [ -d /Applications/DmpConnectJS2.app ] || pkgutil --pkgs 2>/dev/null | grep -qi icanopee; then ok "DMP Connect / iCanopee installe : GALSS conserve (il l'utilise). galss.ini regenere en PC/SC suffit."
        elif [ -z "$READERS" ]; then ko "Aucun lecteur PC/SC vu par macOS : on ne retire pas GALSS"
        elif [ $CRYPTO_GALSS = 1 ]; then ko "Cryptolib en filiere GALSS : on ne retire pas GALSS"
        else
            ok "Prerequis OK (lecteur PC/SC present, Cryptolib sans indication GALSS)"
            if [ -n "$GPKG" ] && confirm "Desinstaller $GPKG (framework galssosx + fichiers du paquet) ?" safe; then
                pkgutil --files "$GPKG" 2>/dev/null | grep -iE 'galss|pssin|pcscosx' | sed 's#^#/#' | while read -r f; do [ -e "$f" ] && sudo rm -rf "$f"; done
                sudo rm -rf /Library/Frameworks/galssosx.framework "/Library/Application Support/Galss" 2>/dev/null
                sudo pkgutil --forget "$GPKG" 2>/dev/null; ok "GALSS retire (galss.ini conserve)"
            fi
            for c in /Applications/JuxtaLink.app/Contents/Resources/Plugins/SSV/*/SSV.dll.config; do
                [ -f "$c" ] || { warn "Plugin SSV absent : relancer --sans-galss apres la premiere lecture"; continue; }
                sudo sed -i '' 's/BLOQUERINSTALLEGALSS" value="false"/BLOQUERINSTALLEGALSS" value="true"/' "$c" && ok "BLOQUERINSTALLEGALSS=true dans $c"
            done
            pkill -x JuxtaLink; sleep 2; open -a JuxtaLink 2>/dev/null
            w "  >>> Tester CPS + Vitale + une ADRi dans Odaiji, puis relancer le diag."
        fi
    fi
    w ""; w "  >>> Redemarrer le Mac, puis 10 lectures Vitale dans Odaiji. Relancer le diag apres."
fi

h1 "FIN"
w "Rapport : $REPORT"
# 05/10 : envoi automatique a MadeForMed, SANS question, uniquement si le rapport peut faire evoluer l'outil
# (un [KO] qui reste ou un scenario inconnu). Jamais bloquant ; echec silencieux -> repli : transfert de fichiers TeamViewer.
RAISON=""
KOC=$(grep -E '^[[:space:]]+[A-Z0-9_]+[[:space:]]+KO[[:space:]]' "$REPORT" 2>/dev/null | awk '{print $1}' | head -4 | paste -sd, -)
[ -n "$KOC" ] && RAISON="KO $KOC" || RAISON="systematique"
# 1.0.2 : on envoie TOUS les rapports (Avant / Apres / Fix / Galss / diag seul)
[ "$LEGER" = 1 ] && RAISON=""   # sentinelle : c'est elle qui decide quoi envoyer
if [ -n "$RAISON" ]; then
    # 1.1.0 : envoi via odaiji-commun.sh (cle du cabinet, file d'attente si pas de reseau, JSON propre)
    if . "$KITDIR/odaiji-commun.sh" 2>/dev/null; then oj_envoyer_rapport "$REPORT" "$RAISON"; w "$(oj_message Rapport)"
    else w "Envoi automatique impossible (odaiji-commun.sh absent) : recuperer ce fichier par le transfert de fichiers TeamViewer et l'envoyer a l'equipe."; fi
fi
[ "$LEGER" = 1 ] || open -R "$REPORT" 2>/dev/null
