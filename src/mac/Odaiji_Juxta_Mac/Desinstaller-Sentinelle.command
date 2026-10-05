#!/bin/bash
# Desinstaller-Sentinelle.command - retire la sentinelle de ce Mac (les rapports deja envoyes restent chez MadeForMed).
D="/Library/Application Support/MadeForMed"; PL=/Library/LaunchDaemons/fr.madeformed.sentinelle.plist
echo "Desinstallation de la sentinelle Odaiji_Juxta"; sudo -v || { read -r -p "Entree pour fermer"; exit 1; }
sudo launchctl bootout system "$PL" 2>/dev/null || sudo launchctl unload "$PL" 2>/dev/null
sudo rm -f "$PL"; sudo rm -rf "$D/sentinelle-kit" "$D/sentinelle"
echo "  [OK] Sentinelle desinstallee."; read -r -p "Entree pour fermer"
