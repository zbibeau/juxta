#!/bin/bash
chmod +x "$(dirname "$0")"/*.command "$(dirname "$0")"/*.sh 2>/dev/null; xattr -dr com.apple.quarantine "$(dirname "$0")" 2>/dev/null
# Efficience "Lecteurs de cartes introuvables" (getPcscResourcesList) : relance DMP Connect / iCanopee. Ne modifie rien d'autre.
JOURNAL=$(mktemp "${TMPDIR:-/tmp}/RelancerDMP.XXXXXX"); exec > >(tee "$JOURNAL") 2>&1
echo "Odaiji_Juxta - relance de DMP Connect / iCanopee"
echo "Mot de passe administrateur requis."
sudo -v || { bash "$(dirname "$0")/envoyer-journal.sh" "$JOURNAL" "reparation DMP"
read -r -p "Entree pour fermer"; exit 1; }
UIDN=$(id -u); fait=0
for pl in /Library/LaunchDaemons/com.icanopee.*.plist; do
    [ -f "$pl" ] || continue; lab=$(/usr/libexec/PlistBuddy -c 'Print :Label' "$pl" 2>/dev/null); [ -n "$lab" ] || continue
    if sudo launchctl kickstart -k "system/$lab" 2>/dev/null; then echo "  relance : $lab"; fait=1; fi
done
for pl in /Library/LaunchAgents/com.icanopee.*.plist "$HOME"/Library/LaunchAgents/com.icanopee.*.plist; do
    [ -f "$pl" ] || continue; lab=$(/usr/libexec/PlistBuddy -c 'Print :Label' "$pl" 2>/dev/null); [ -n "$lab" ] || continue
    if launchctl kickstart -k "gui/$UIDN/$lab" 2>/dev/null; then echo "  relance : $lab"; fait=1; fi
done
if [ "$fait" = 0 ]; then echo "  Aucun service launchd com.icanopee.* relance : arret des processus (le moniteur les relance)."; sudo pkill -f dmpconnect-js2; fi
sleep 6
if ps -axo comm | grep -v grep | grep -qi 'dmpconnect-js2'; then echo "  OK : dmpconnect-js2 actif. Relancer la connexion dans Efficience (nouvel onglet)."
else echo "  dmpconnect-js2 n'est pas actif : redemarrer le Mac ou lancer 2-Depanner.command."; fi
bash "$(dirname "$0")/envoyer-journal.sh" "$JOURNAL" "reparation DMP"
read -r -p "Entree pour fermer"
