#!/bin/bash
chmod +x "$(dirname "$0")"/*.command "$(dirname "$0")"/*.sh 2>/dev/null; xattr -dr com.apple.quarantine "$(dirname "$0")" 2>/dev/null
# Autoriser Odaiji a joindre JuxtaLink (localhost) dans Chrome, Edge et Firefox - Local Network Access
# MadeForMed / Odaiji - v1.2 (05/10/2026) : guillemets autour des motifs [*.] (defaults refusait de les ecrire) + repli PlistBuddy ; v1.1 (24/09/2026) : ajout Firefox 145+ (LocalNetworkAccess.SkipDomains). Remplace chrome://flags. Preferences managees, tous utilisateurs du Mac.
ORIGINS=("https://app.odaiji.co" "https://[*.]odaiji.co" "https://[*.]madeformed.fr" "https://[*.]juxta.cloud")
FF_DOMAINS=("app.odaiji.co" "*.odaiji.co" "*.madeformed.fr" "*.juxta.cloud" "localhost" "127.0.0.1")
echo "Mot de passe administrateur requis."; sudo -v || exit 1
for dom in com.google.Chrome com.microsoft.Edge; do
    for key in LocalNetworkAccessAllowedForUrls LocalNetworkAllowedForUrls; do
        if [ "$1" = "--remove" ]; then sudo defaults delete "/Library/Preferences/$dom" "$key" 2>/dev/null
        else
            # 05/10 : "defaults" n'accepte pas [*.] sans guillemets de plist ("Could not parse") -> chaque element est guillemete ;
            # si malgre tout la cle est absente, repli PlistBuddy (n'interprete rien).
            QA=(); for o in "${ORIGINS[@]}"; do QA+=("\"$o\""); done
            sudo defaults write "/Library/Preferences/$dom" "$key" -array "${QA[@]}" 2>/dev/null
            if ! defaults read "/Library/Preferences/$dom" "$key" 2>/dev/null | grep -q 'odaiji'; then
                PB=/usr/libexec/PlistBuddy; PL="/Library/Preferences/$dom.plist"
                sudo "$PB" -c "Delete :$key" "$PL" 2>/dev/null; sudo "$PB" -c "Add :$key array" "$PL" 2>/dev/null
                i=0; for o in "${ORIGINS[@]}"; do sudo "$PB" -c "Add :$key:$i string $o" "$PL" 2>/dev/null; i=$((i+1)); done
            fi
        fi
    done
    sudo chmod 644 "/Library/Preferences/$dom.plist" 2>/dev/null
done
# Firefox : preferences managees /Library/Preferences/org.mozilla.firefox (EnterprisePoliciesEnabled requis)
FF=/Library/Preferences/org.mozilla.firefox
if [ "$1" = "--remove" ]; then sudo defaults delete "$FF" LocalNetworkAccess 2>/dev/null
else
    ffl=""; for d in "${FF_DOMAINS[@]}"; do ffl="$ffl\"$d\","; done
    sudo defaults write "$FF" EnterprisePoliciesEnabled -bool true \
      && sudo defaults write "$FF" LocalNetworkAccess "{ SkipDomains = ( ${ffl%,} ); }" \
      && echo "Politique ecrite (Firefox) : ${FF_DOMAINS[*]}  -> verification : about:policies" \
      || echo "Firefox : politique non ecrite"
fi
sudo chmod 644 "$FF.plist" 2>/dev/null
if [ "$1" = "--remove" ]; then echo "Politiques retirees."; else
    echo "Politiques ecrites (Chrome + Edge) : ${ORIGINS[*]}"
    echo "Relancer le navigateur. Verification : chrome://policy doit lister LocalNetworkAccessAllowedForUrls."
fi
sleep 3
