#!/bin/bash
# envoyer-journal.sh <fichier> <raison> [depuis_octets] : envoie un journal / rapport a MadeForMed (file d'attente si pas de reseau). Jamais bloquant.
. "$(cd "$(dirname "$0")" && pwd)/odaiji-commun.sh" 2>/dev/null || { echo "Envoi automatique du journal impossible (odaiji-commun.sh absent)."; exit 0; }
oj_envoyer_rapport "${1:-}" "${2:-journal}" "${3:-0}"
oj_message "Journal"
oj_secours "${1:-}"
