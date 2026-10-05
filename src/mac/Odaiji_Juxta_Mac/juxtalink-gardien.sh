#!/bin/bash
# =====================================================================
#  juxtalink-gardien - Veille de JuxtaLink (Mac) - MadeForMed / Odaiji - v1.1 (05/10/2026)
#  Lance par l'agent launchd fr.madeformed.juxtalink-gardien toutes les 10 min (session du medecin).
#  JuxtaLink arrete (ferme, plante) -> relance. JuxtaLink qui tourne mais port 1234 muet 2 veilles de suite -> relance.
#  Garde-fous : rien pendant 1-Installer / 2-Depanner / OdaijiJuxta-Mac ; rien si l'ecran de session est verrouille
#  sans JuxtaLink installe ; au plus 3 relances en 30 min (au-dela : "BOUCLE" dans le journal, on laisse tranquille).
#  v1.1 : a chaque veille, si JuxtaLink repond, galss-autofix verifie que galss.ini suit les fentes reelles (CPS/Vitale
#  inversees ou deplacees) ; s'il le reecrit, JuxtaLink est relance. Au plus 2 realignements en 30 min.
#  Journal : ~/Library/Logs/juxtalink-gardien.log
# =====================================================================
APP="/Applications/JuxtaLink.app"; PORT=1234; MAX=3; FENETRE=1800
LOG="$HOME/Library/Logs/juxtalink-gardien.log"
STDIR="$HOME/Library/Application Support/MadeForMed"; ST="$STDIR/gardien.state"
mkdir -p "$(dirname "$LOG")" "$STDIR"
log(){ printf '%s %s\n' "$(date '+%d/%m/%Y %H:%M:%S')" "$*" >> "$LOG"; [ "$(wc -c < "$LOG" 2>/dev/null || echo 0)" -gt 200000 ] && tail -n 400 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"; }
[ -d "$APP" ] || exit 0
# Un outil du kit tourne : il arrete et relance JuxtaLink lui-meme
pgrep -f '1-Installer\.command|2-Depanner\.command|OdaijiJuxta-Mac\.sh|Autoriser-Odaiji-Chrome' >/dev/null 2>&1 && exit 0
# Etat : PORTKO=<n>  puis une ligne d'horodatage (epoch) par relance
PORTKO=0; RELANCES=""
if [ -f "$ST" ]; then PORTKO=$(grep -m1 '^PORTKO=' "$ST" | cut -d= -f2); PORTKO=${PORTKO:-0}; RELANCES=$(grep -E '^[0-9]+$' "$ST"); fi
save(){ { echo "PORTKO=$PORTKO"; [ -n "$RELANCES" ] && echo "$RELANCES"; } > "$ST"; }
ecoute(){ lsof -nP -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; }
if pgrep -x JuxtaLink >/dev/null 2>&1; then
    if ecoute; then
        [ "$PORTKO" != 0 ] && { PORTKO=0; save; }
        # --- realignement de galss.ini si les cartes ont change de fente
        GA="$STDIR/galss-autofix.sh"; INI="/Library/Preferences/galss.ini"; RS="$STDIR/realign.state"
        if [ -x "$GA" ] && [ -w "$INI" ]; then
            NOW=$(date +%s); RE=$( [ -f "$RS" ] && awk -v lim=$((NOW-FENETRE)) '$1>lim' "$RS" )
            if [ "$(echo "$RE" | grep -c '^[0-9]')" -ge 2 ]; then exit 0; fi
            AVANT=$(cksum < "$INI" 2>/dev/null)
            bash "$GA" >/dev/null 2>&1
            if [ "$(cksum < "$INI" 2>/dev/null)" != "$AVANT" ]; then
                { echo "$RE" | grep -E '^[0-9]+$'; echo "$NOW"; } > "$RS"
                log "Cartes changees de fente : galss.ini realigne par galss-autofix, JuxtaLink relance"
            fi
        fi
        exit 0
    fi
    PORTKO=$((PORTKO+1)); save
    if [ "$PORTKO" -lt 2 ]; then log "JuxtaLink tourne mais le port $PORT ne repond pas (veille 1/2, on attend)"; exit 0; fi
    RAISON="JuxtaLink bloque (port $PORT muet depuis 2 veilles)"; BLOQUE=1
else RAISON="JuxtaLink arrete"; BLOQUE=0; fi
NOW=$(date +%s); RELANCES=$(echo "$RELANCES" | awk -v lim=$((NOW-FENETRE)) '$1>lim')
N=$(echo "$RELANCES" | grep -c '^[0-9]'); N=${N:-0}
if [ "$N" -ge "$MAX" ]; then log "BOUCLE : $RAISON, mais $N relances deja faites en 30 min : on ne relance plus (envoyer ce journal)"; save; exit 0; fi
[ "$BLOQUE" = 1 ] && { pkill -x JuxtaLink; sleep 2; }
open -a JuxtaLink 2>/dev/null; sleep 10
RELANCES="$RELANCES
$NOW"; RELANCES=$(echo "$RELANCES" | grep -E '^[0-9]+$'); PORTKO=0; save
if pgrep -x JuxtaLink >/dev/null 2>&1; then log "$RAISON -> JuxtaLink relance ($((N+1))/$MAX sur 30 min)"; else log "$RAISON -> relance demandee mais JuxtaLink ne tourne toujours pas"; fi
