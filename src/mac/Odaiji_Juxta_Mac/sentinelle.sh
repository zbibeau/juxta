#!/bin/bash
# sentinelle.sh - diagnostic PASSIF periodique (LaunchDaemon fr.madeformed.sentinelle) : remonte l'etat du Mac a MadeForMed.
#   - ne repare JAMAIS, ne touche JAMAIS au lecteur ni aux cartes (OdaijiJuxta-Mac.sh --leger), ne cree aucun fichier sur le Bureau
#   - un passage par jour au plus ; envoie un petit "battement" (etat + version) ; le rapport complet seulement si l'etat change (ou 1 fois / semaine)
#   - desactivation : creer "/Library/Application Support/MadeForMed/sentinelle.off"  (ou Desinstaller-Sentinelle.command)
# Options (tests) : --force (ignore la limite de 20 h), --sans-envoi
KIT="$(cd "$(dirname "$0")" && pwd)"
FORCE=0; SANS=0; for a in "$@"; do [ "$a" = "--force" ] && FORCE=1; [ "$a" = "--sans-envoi" ] && SANS=1; done
. "$KIT/odaiji-commun.sh" 2>/dev/null || exit 0
BASE="$(oj_dir)"; DIR="$BASE/sentinelle"; mkdir -p "$DIR" 2>/dev/null
[ -f "$BASE/sentinelle.off" ] && exit 0; [ -f "$OJ_HOME/sentinelle.off" ] && exit 0; [ -f "$OJ_SYS/sentinelle.off" ] && exit 0
ETAT="$DIR/etat"; NOW=$(date +%s); T0=$NOW
if [ $FORCE = 0 ] && [ -f "$ETAT" ]; then LE=$(sed -n 's/^derniere_execution=//p' "$ETAT"); [ $((NOW - ${LE:-0})) -lt 72000 ] && exit 0; fi
# le diag lit le profil de l'utilisateur connecte : on prend son HOME (le daemon tourne en root)
CU=$(stat -f%Su /dev/console 2>/dev/null)
if [ -n "$CU" ] && [ "$CU" != root ] && [ "$CU" != _mbsetupuser ]; then H=$(dscl . -read "/Users/$CU" NFSHomeDirectory 2>/dev/null | awk '{print $2}'); [ -d "$H" ] && export HOME="$H" USER="$CU"; fi
# 1. diagnostic passif, priorite basse
env JDPREFIX=Sentinelle ODAIJI_REPORT_DIR="$DIR" nice -n 10 bash "${ODAIJI_DIAG:-$KIT/OdaijiJuxta-Mac.sh}" --leger >/dev/null 2>&1
REP=$(ls -t "$DIR"/Sentinelle_*.txt 2>/dev/null | head -1); [ -n "$REP" ] || exit 0
RES=$(oj_resume "$REP"); SC="${RES%%|*}"; R2="${RES#*|}"; KO="${R2%%|*}"; WARN="${R2#*|}"; [ -z "$SC" ] && SC="?"
CODES="$KO${KO:+${WARN:+,}}$WARN"
oj_decision "$ETAT" "$SC" "$CODES" "$NOW"
# 2. version publiee (alerte "kit en retard", jamais de mise a jour automatique)
VER=$(oj_version); DISPO="$VER"
V=$(curl -s -m 15 "${ODAIJI_VERSION_URL:-https://odaiji-juxta.netlify.app/version.json}" 2>/dev/null | sed -n 's/.*"version":"\([0-9.]*\)".*/\1/p'); [ -n "$V" ] && DISPO="$V"
RETARD=false; oj_version_gt "$DISPO" "$VER" && RETARD=true
COMPLET=$([ "$OJ_COMPLET" = 1 ] && echo true || echo false)
CORPS=$(printf '{"scenario":"%s","ko":%s,"warn":%s,"leger":true,"kit":"%s","dispo":"%s","retard":%s,"duree_s":%s,"complet":%s,"raison":"%s"}' "$SC" "$(oj_csv_json "$KO")" "$(oj_csv_json "$WARN")" "$VER" "$DISPO" "$RETARD" "$(( $(date +%s) - T0 ))" "$COMPLET" "$OJ_RAISON")
DR=$(sed -n 's/^dernier_rapport_ts=//p' "$ETAT" 2>/dev/null); DR=${DR:-0}
if [ $SANS = 0 ]; then
    oj_battement "$CORPS"
    if [ "$OJ_COMPLET" = 1 ]; then oj_envoyer_rapport "$REP" "sentinelle $OJ_RAISON"; [ "$OJ_STATUT" != refuse ] && DR=$NOW; else oj_spool_flush; fi
fi
# 3. etat + menage (3 derniers rapports locaux)
printf 'derniere_execution=%s\nscenario=%s\ncodes=%s\ndernier_rapport_ts=%s\n' "$NOW" "$SC" "$CODES" "$DR" > "$ETAT"
ls -t "$DIR"/Sentinelle_*.txt 2>/dev/null | tail -n +4 | while read -r x; do rm -f "$x"; done
exit 0
