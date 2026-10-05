#!/bin/bash
# Double-clic depuis le Finder : realigne galss.ini et relance JuxtaLink.
cd "$(dirname "$0")"
JOURNAL=$(mktemp -t ReparerLecteur); exec > >(tee "$JOURNAL") 2>&1
echo "Verification du lecteur de cartes..."
bash "$HOME/Library/Application Support/MadeForMed/galss-autofix.sh"
echo ""
echo "Termine. Refaire une lecture de carte dans Odaiji."
echo "(Cette fenetre peut etre fermee.)"
bash "$(dirname "$0")/envoyer-journal.sh" "$JOURNAL" "reparation lecteur"
sleep 4
