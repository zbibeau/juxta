#!/bin/bash
# odaiji-commun.sh - fonctions partagees du kit Mac (a sourcer :  . "$KIT/odaiji-commun.sh").  Compatible bash 3.2 (macOS).
#   oj_poste_id        identifiant stable du poste (UUID cree au 1er passage)
#   oj_cle             cle d'envoi du cabinet (cle-envoi.txt a cote du kit ou dans Application Support/MadeForMed) - JAMAIS dans le zip public
#   oj_envoyer_rapport <fichier> <raison> [depuis_octets]   envoie un rapport / journal ; sans reseau : FILE D'ATTENTE (spool) pour le prochain passage
#   oj_battement <json> envoie le petit message "je suis vivant + etat" de la sentinelle
#   oj_spool_flush     renvoie la file d'attente
#   Apres un envoi : OJ_STATUT = envoye | differe | refuse ; OJ_ERR = cause ; oj_message "Rapport" affiche la phrase pour le technicien.
# Jamais bloquant.
OJ_KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OJ_URL="${ODAIJI_URL:-https://odaiji-juxta.netlify.app/.netlify/functions/rapport}"
OJ_SYS="${OJ_SYSDIR:-/Library/Application Support/MadeForMed}"
OJ_HOME="${OJ_HOMEDIR:-$HOME/Library/Application Support/MadeForMed}"
OJ_STATUT=""; OJ_ERR=""

oj_dir() {  # dossier ou ecrire : systeme si possible (root / sentinelle), sinon profil de l'utilisateur
    if mkdir -p "$OJ_SYS" 2>/dev/null && [ -w "$OJ_SYS" ]; then echo "$OJ_SYS"; return; fi
    mkdir -p "$OJ_HOME" 2>/dev/null; echo "$OJ_HOME"
}
oj_poste_id() {
    local f v
    for f in "$OJ_SYS/poste-id.txt" "$OJ_HOME/poste-id.txt"; do
        if [ -r "$f" ]; then v=$(tr -d ' \r\n' < "$f" 2>/dev/null); if printf '%s' "$v" | grep -Eq '^[0-9a-f-]{8,40}$'; then printf '%s' "$v"; return; fi; fi
    done
    v=$(uuidgen 2>/dev/null | tr 'A-Z' 'a-z'); [ -z "$v" ] && v=$(od -An -N16 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
    printf '%s\n' "$v" > "$(oj_dir)/poste-id.txt" 2>/dev/null
    printf '%s' "$v"
}
oj_cle() {
    local f k
    for f in "$OJ_KIT/cle-envoi.txt" "$OJ_SYS/cle-envoi.txt" "$OJ_HOME/cle-envoi.txt"; do
        if [ -r "$f" ]; then k=$(tr -d ' \r\n' < "$f" 2>/dev/null); if printf '%s' "$k" | grep -Eq '^[A-Za-z0-9_-]{8,80}$'; then printf '%s' "$k"; return; fi; fi
    done
}
oj_version() {
    if [ -n "${VERSION:-}" ]; then printf '%s' "$VERSION"; else grep -m1 '^VERSION=' "$OJ_KIT/OdaijiJuxta-Mac.sh" 2>/dev/null | cut -d'"' -f2; fi
}
oj_host() { local h; h=$(scutil --get ComputerName 2>/dev/null | tr ' ' '_'); [ -z "$h" ] && h=$(hostname -s); printf '%s' "$h"; }
# texte -> contenu d'une chaine JSON (stdin -> stdout). LC_ALL=C + iconv : octets non UTF-8 ; CR retires (sinon HTTP 400)
oj_json_escape() {
    LC_ALL=C tr -d '\000-\010\013-\037' | iconv -f UTF-8 -t UTF-8 -c 2>/dev/null | LC_ALL=C sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e $'s/\t/\\\\t/g' | LC_ALL=C awk '{printf "%s\\n",$0}'
}
oj_post() {  # <fichier json> -> code HTTP sur stdout ; erreur curl dans OJ_ERR
    local k t code; k=$(oj_cle); t=$(mktemp "${TMPDIR:-/tmp}/ojp.XXXXXX")
    if [ -n "$k" ]; then code=$(curl -sS -m 40 -o "$t" -w '%{http_code}' -X POST -H 'Content-Type: application/json; charset=utf-8' -H "X-Odaiji-Key: $k" --data-binary @"$1" "$OJ_URL" 2>"$t.err")
    else code=$(curl -sS -m 40 -o "$t" -w '%{http_code}' -X POST -H 'Content-Type: application/json; charset=utf-8' --data-binary @"$1" "$OJ_URL" 2>"$t.err"); fi
    OJ_ERR="HTTP ${code:-000} $(head -c 100 "$t.err" "$t" 2>/dev/null | tr '\n' ' ')"
    rm -f "$t" "$t.err"; printf '%s' "${code:-000}"
}
oj_spool_flush() {
    local d f c n=0; d="$(oj_dir)/spool"; [ -d "$d" ] || return 0
    find "$d" -name '*.json' -mtime +14 -delete 2>/dev/null
    for f in $(ls "$d"/*.json 2>/dev/null | sort | head -25); do
        c=$(oj_post "$f")
        case "$c" in 200) rm -f "$f"; n=$((n+1));; 400|401|413) rm -f "$f";; *) break;; esac
    done
}
oj_envoyer_json() {  # <fichier json> : file d'attente si echec transitoire
    local c; c=$(oj_post "$1")
    case "$c" in
        200) OJ_STATUT=envoye; oj_spool_flush;;
        400|401|413) OJ_STATUT=refuse;;
        *) local d n; d="$(oj_dir)/spool"; mkdir -p "$d" 2>/dev/null
           n=$(ls "$d"/*.json 2>/dev/null | wc -l | tr -d ' ')
           if [ "${n:-0}" -ge 50 ]; then ls "$d"/*.json | sort | head -n $((n-49)) | while read -r x; do rm -f "$x"; done; fi
           if cp "$1" "$d/$(date +%Y%m%d%H%M%S)_$RANDOM.json" 2>/dev/null; then OJ_STATUT=differe; else OJ_STATUT=refuse; fi;;
    esac
}
oj_envoyer_rapport() {  # <fichier> <raison> [depuis_octets]
    local f="$1" raison="$2" depuis="${3:-0}" j t
    OJ_STATUT=refuse; OJ_ERR="fichier absent"; [ -f "$f" ] || return 0
    command -v curl >/dev/null 2>&1 || { OJ_ERR="curl absent"; return 0; }
    t=$(mktemp "${TMPDIR:-/tmp}/ojr.XXXXXX")
    j=$(tail -c +$((depuis+1)) "$f" | tail -c 240000 | oj_json_escape)
    printf '{"kit":"odaiji-juxta","os":"mac","version":"%s","poste":"%s","poste_id":"%s","nom":"%s","raison":"%s","rapport":"%s"}' "$(oj_version)" "$(oj_host)" "$(oj_poste_id)" "$(basename "$f")" "$raison" "$j" > "$t"
    oj_envoyer_json "$t"; rm -f "$t"
}
oj_battement() {  # <json de l'etat>
    local t j; t=$(mktemp "${TMPDIR:-/tmp}/ojb.XXXXXX"); j=$(printf '%s' "$1" | oj_json_escape)
    printf '{"kit":"odaiji-juxta","type":"battement","os":"mac","version":"%s","poste":"%s","poste_id":"%s","nom":"battement","raison":"battement","rapport":"%s"}' "$(oj_version)" "$(oj_host)" "$(oj_poste_id)" "$j" > "$t"
    oj_envoyer_json "$t"; rm -f "$t"
}
oj_message() {  # <Rapport|Journal>
    case "$OJ_STATUT" in
        envoye) echo "${1:-Rapport} transmis automatiquement a MadeForMed.";;
        differe) echo "${1:-Rapport} mis en file d'attente (envoi differe : $OJ_ERR) : il partira au prochain passage du kit.";;
        *) echo "Envoi automatique impossible ($OJ_ERR) : recuperer ce fichier par le transfert de fichiers TeamViewer et l'envoyer a l'equipe.";;
    esac
}

# ---- Sentinelle : fonctions pures (testees contre le corpus de rapports reels)
# oj_resume <rapport> -> "scenario|KO1,KO2|WARN1,WARN2"
oj_resume() {
    local sc ko warn
    sc=$(grep -m1 '^Scenario :' "$1" 2>/dev/null | awk '{print $3}')
    ko=$(awk '/^Constats/{c=1;next} c&&/^[[:space:]]+[A-Z][A-Za-z0-9_]+[[:space:]]+KO[[:space:]]/{print $1} c&&(/^$/||/^====/){c=0}' "$1" 2>/dev/null | sort -u | paste -sd, -)
    warn=$(awk '/^Constats/{c=1;next} c&&/^[[:space:]]+[A-Z][A-Za-z0-9_]+[[:space:]]+WARN[[:space:]]/{print $1} c&&(/^$/||/^====/){c=0}' "$1" 2>/dev/null | sort -u | paste -sd, -)
    printf '%s|%s|%s' "$sc" "$ko" "$warn"
}
# oj_decision <fichier_etat> <scenario> <codes_csv> <maintenant_epoch> -> OJ_COMPLET (1/0) et OJ_RAISON
# Regles : premier passage ; nouveau code KO / WARN ; scenario change ; rapport complet vieux de 7 jours.
oj_decision() {
    local f="$1" sc="$2" codes="$3" now="$4" old_sc old_codes old_ts c nouveaux=""
    OJ_COMPLET=1; OJ_RAISON="premier passage"
    [ -f "$f" ] || return 0
    old_sc=$(sed -n 's/^scenario=//p' "$f"); old_codes=$(sed -n 's/^codes=//p' "$f"); old_ts=$(sed -n 's/^dernier_rapport_ts=//p' "$f")
    local IFS=','
    for c in $codes; do [ -z "$c" ] && continue; case ",$old_codes," in *",$c,"*) ;; *) nouveaux="$nouveaux${nouveaux:+,}$c";; esac; done
    unset IFS
    if [ -n "$nouveaux" ]; then OJ_RAISON="nouveau constat $nouveaux"; return 0; fi
    if [ "$old_sc" != "$sc" ]; then OJ_RAISON="scenario $old_sc -> $sc"; return 0; fi
    if [ $((now - ${old_ts:-0})) -ge 604800 ]; then OJ_RAISON="rapport hebdomadaire"; return 0; fi
    OJ_COMPLET=0; OJ_RAISON="inchange"
}
oj_csv_json() { local out="" x; local IFS=','; for x in $1; do [ -n "$x" ] && out="$out${out:+,}\"$x\""; done; printf '[%s]' "$out"; }
oj_version_gt() {  # a > b ? (x.y.z)
    local IFS=.; set -- $1 $2; [ "$(( ${1:-0}*1000000 + ${2:-0}*1000 + ${3:-0} ))" -gt "$(( ${4:-0}*1000000 + ${5:-0}*1000 + ${6:-0} ))" ]
}
# oj_delta <avant> <apres> : affiche les codes KO+WARN corriges / restants / nouveaux (compare deux rapports)
oj_delta() {
    local a b x ca="" cb="" corr="" rest="" nouv="" IFS
    a=$(oj_resume "$1"); b=$(oj_resume "$2")
    ca=$(printf '%s' "${a#*|}" | tr '|' ','); cb=$(printf '%s' "${b#*|}" | tr '|' ',')
    IFS=','
    for x in $ca; do [ -z "$x" ] && continue; case ",$cb," in *",$x,"*) rest="$rest${rest:+, }$x";; *) corr="$corr${corr:+, }$x";; esac; done
    for x in $cb; do [ -z "$x" ] && continue; case ",$ca," in *",$x,"*) ;; *) nouv="$nouv${nouv:+, }$x";; esac; done
    unset IFS
    echo "    AVANT -> APRES (KO + WARN) :"; echo "      Corriges : ${corr:-aucun}"; echo "      Restent  : ${rest:-aucun}"; echo "      Nouveaux : ${nouv:-aucun}"
}
