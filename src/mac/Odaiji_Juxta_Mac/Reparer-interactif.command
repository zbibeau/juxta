#!/bin/bash
chmod +x "$(dirname "$0")"/*.command "$(dirname "$0")"/*.sh 2>/dev/null; xattr -dr com.apple.quarantine "$(dirname "$0")" 2>/dev/null
# Reparation interactive (confirmation a chaque etape)
cd "$(dirname "$0")"; bash ./OdaijiJuxta-Mac.sh --fix; read -r -p "Entree pour fermer"
