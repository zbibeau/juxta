#!/bin/bash
# =====================================================================
#  galss-autofix - Realigne galss.ini sur les fentes reelles du lecteur
#  MadeForMed / Odaiji - v1.1 (28/09/2026) : CPS Telium (ATR 3bdc...), galss.ini a fins de ligne CR
# =====================================================================
#  Probleme : certains lecteurs USB (ex. FEI Card Reader/QR Scanner)
#  changent de numerotation 01/02 au redemarrage. galss.ini identifie
#  les fentes par nom -> la CPS n'est plus lue par JuxtaLink.
#  Solution : detecter par ATR ou est la CPS (et la Vitale), reecrire
#  galss.ini si necessaire, relancer JuxtaLink.
#  Ne fait RIEN si la config est deja correcte.
# =====================================================================

INI="${OJ_GALSS_INI:-/Library/Preferences/galss.ini}"   # OJ_GALSS_INI : tests uniquement
LOG="$HOME/Library/Logs/galss-autofix.log"
mkdir -p "$(dirname "$LOG")"
log(){ printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; [ -t 1 ] && echo "$*"; }

# --- 1. Lecteurs et ATR vus par macOS
SC=$(system_profiler SPSmartCardsDataType 2>/dev/null | sed -n '/Readers:/,/Reader Drivers:/p' | grep -E '^[[:space:]]+#')
[ -z "$SC" ] && { log "Aucun lecteur vu par macOS, rien a faire."; exit 0; }

CPS_RDR=""; VIT_RDR=""; OTHERS=()
while IFS= read -r line; do
    name=$(echo "$line" | sed -E 's/^[[:space:]]*#[0-9]+: //; s/ \((ATR|no card).*//')
    atr=$(echo "$line" | grep -oE 'bytes = 0x[0-9a-f]+' | sed 's/bytes = 0x//')
    case "$atr" in
        3bac00402a*|3b7b18*|3bac*|3bdc18*|*12250064800*) CPS_RDR="$name" ;;   # CPS3 / CPS2ter / CPS via Ingenico Telium
        3b7513*|3b75*|3b1*)        VIT_RDR="$name" ;;          # Vitale 2
        3f65*)                     VIT_RDR="$name" ;;          # Vitale 1 (ATR 3F65...) : iMac Dr 07/10, non reconnue -> Vitale attribuee a une fente vide
        *)                          OTHERS+=("$name") ;;
    esac
done <<< "$SC"

# --- 2. Si une carte manque, on garde une fente "numerotee" restante
pick_other(){ local n; for n in "${OTHERS[@]}"; do [[ "$n" =~ [[:space:]][0-9]{2}$ ]] && [ "$n" != "$1" ] && { echo "$n"; return; }; done; }
[ -z "$VIT_RDR" ] && [ -n "$CPS_RDR" ] && VIT_RDR=$(pick_other "$CPS_RDR")
[ -z "$CPS_RDR" ] && [ -n "$VIT_RDR" ] && CPS_RDR=$(pick_other "$VIT_RDR")
if [ -z "$CPS_RDR" ] || [ -z "$VIT_RDR" ]; then
    log "Impossible d'identifier les deux fentes (CPS='$CPS_RDR' Vitale='$VIT_RDR'). Inserer les cartes puis relancer."
    exit 0
fi

# --- 3. Comparer avec la config actuelle
CUR_CPS=$(tr '\r' '\n' < "$INI" 2>/dev/null | sed -n '/^\[CANAL1\]/,/^\[/p' | grep -i '^Caracteristiques=' | cut -d= -f2-)
CUR_VIT=$(tr '\r' '\n' < "$INI" 2>/dev/null | sed -n '/^\[CANAL2\]/,/^\[/p' | grep -i '^Caracteristiques=' | cut -d= -f2-)
if [ "$CUR_CPS" = "$CPS_RDR" ] && [ "$CUR_VIT" = "$VIT_RDR" ]; then
    log "OK : galss.ini deja aligne (CPS='$CPS_RDR', Vitale='$VIT_RDR')."
    exit 0
fi

# --- 4. Reecrire galss.ini
if [ ! -w "$INI" ] && [ ! -w "$(dirname "$INI")" ]; then
    log "ERREUR : $INI non modifiable. Lancer install.sh une fois (sudo) pour donner les droits."
    exit 1
fi
[ -f "$INI" ] && cp "$INI" "$INI.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null
cat > "$INI" << EOT
; Configuration GALSS macOS - lecteur bi-fente USB en PC/SC
; Regenere automatiquement par galss-autofix le $(date '+%d/%m/%Y %H:%M')

[PROTOCOLE0]
Config=1000,20,15000
TempoInit=1,1500,1000
NomLib=pssinosx.framework

[PROTOCOLE1]
Config=0
NomLib=pcscosx.framework
ListeCanaux=1,2

[CONFIG]
NbCanaux=2

[CANAL1]
TCanal=3
Index=1
Protocole=1
Caracteristiques=$CPS_RDR
NbPAD=1

[CANAL1.PAD1]
PAD=0
NbLAD=1

[CANAL1.PAD1.LAD1]
LAD=1
NomLAD=CPS
NbAlias=1
NomAlias1=TRANSPA1

[CANAL2]
TCanal=3
Index=2
Protocole=1
Caracteristiques=$VIT_RDR
NbPAD=1

[CANAL2.PAD1]
PAD=0
NbLAD=1

[CANAL2.PAD1.LAD1]
LAD=1
NomLAD=Vitale
NbAlias=1
NomAlias1=TRANSPA2
EOT
log "galss.ini reecrit : CPS='$CPS_RDR' (etait '$CUR_CPS'), Vitale='$VIT_RDR' (etait '$CUR_VIT')."

# --- 5. Relancer JuxtaLink pour qu'il recharge GALSS
if pgrep -x JuxtaLink >/dev/null; then
    pkill -x JuxtaLink; sleep 2; open -a JuxtaLink 2>/dev/null
    log "JuxtaLink relance."
fi
exit 0
