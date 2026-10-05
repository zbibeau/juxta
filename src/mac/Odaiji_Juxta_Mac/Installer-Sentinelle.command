#!/bin/bash
# Installer-Sentinelle.command - installe la sentinelle (diagnostic passif periodique) sur ce Mac. Double-clic ; demande le mot de passe administrateur.
#   Copie le kit dans /Library/Application Support/MadeForMed/sentinelle-kit puis charge le LaunchDaemon fr.madeformed.sentinelle (tous les jours 12:30, priorite basse).
#   La cle d'envoi du cabinet (cle-envoi.txt, fournie par MadeForMed) est copiee avec le kit si elle est a cote.
chmod +x "$(dirname "$0")"/*.command "$(dirname "$0")"/*.sh 2>/dev/null; xattr -dr com.apple.quarantine "$(dirname "$0")" 2>/dev/null
KIT="$(cd "$(dirname "$0")" && pwd)"; D="/Library/Application Support/MadeForMed"; DEST="$D/sentinelle-kit"; PL=/Library/LaunchDaemons/fr.madeformed.sentinelle.plist
echo "Installation de la sentinelle Odaiji_Juxta"; echo "Mot de passe administrateur requis."
sudo -v || { read -r -p "Entree pour fermer"; exit 1; }
for f in OdaijiJuxta-Mac.sh odaiji-commun.sh sentinelle.sh fr.madeformed.sentinelle.plist; do [ -f "$KIT/$f" ] || { echo "  [KO] fichier manquant dans le kit : $f"; read -r -p "Entree pour fermer"; exit 1; }; done
sudo mkdir -p "$DEST"
sudo cp "$KIT/OdaijiJuxta-Mac.sh" "$KIT/odaiji-commun.sh" "$KIT/sentinelle.sh" "$DEST/"; [ -f "$KIT/cle-envoi.txt" ] && sudo cp "$KIT/cle-envoi.txt" "$DEST/"
sudo chmod 755 "$DEST"/*.sh; sudo chown -R root:wheel "$DEST"
sudo rm -f "$D/sentinelle.off"
# meme identifiant de poste que les rapports lances a la main (cree dans le profil de l'utilisateur) : on le recopie cote systeme
UH=$(eval echo "~${SUDO_USER:-$USER}"); [ -f "$UH/Library/Application Support/MadeForMed/poste-id.txt" ] && [ ! -f "$D/poste-id.txt" ] && sudo cp "$UH/Library/Application Support/MadeForMed/poste-id.txt" "$D/poste-id.txt"
sudo cp "$KIT/fr.madeformed.sentinelle.plist" "$PL"; sudo chown root:wheel "$PL"; sudo chmod 644 "$PL"
sudo launchctl bootout system "$PL" 2>/dev/null
if sudo launchctl bootstrap system "$PL" 2>/dev/null || sudo launchctl load -w "$PL" 2>/dev/null; then echo "  [OK] Sentinelle chargee (tous les jours 12:30)."; else echo "  [KO] Chargement du LaunchDaemon impossible."; read -r -p "Entree pour fermer"; exit 1; fi
if [ -f "$DEST/cle-envoi.txt" ]; then echo "  Cle d'envoi : cle du cabinet trouvee"; else echo "  Cle d'envoi : pas de cle-envoi.txt -> les rapports partiront 'non identifies' (demander la cle a MadeForMed)"; fi
echo "  Premier passage maintenant (1 a 2 minutes)..."; sudo launchctl kickstart "system/fr.madeformed.sentinelle" 2>/dev/null
echo; echo "Desactiver : Desinstaller-Sentinelle.command  (ou creer $D/sentinelle.off)"
read -r -p "Entree pour fermer"
