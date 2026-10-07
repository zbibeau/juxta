#!/bin/bash
# 16. Mac : attribution CPS / Vitale dans galss.ini (galss-autofix.sh) avec un faux system_profiler. Cas reel iMac 07/10 : Vitale 1 (ATR 3F65...) dans le lecteur
# sans numero, CPS dans "Reader 02", "Reader 01" vide -> la Vitale doit etre rattachee au lecteur qui la contient, pas a la fente vide.
cd "$(dirname "$0")/.." || exit 1
MAC=src/mac/Odaiji_Juxta_Mac; T=$(mktemp -d /tmp/ojgalss.XXXXXX); FAIL=0
mkdir -p "$T/bin" "$T/home"
cat > "$T/bin/system_profiler" <<'EOT'
#!/bin/bash
cat <<'EOS'
SmartCards:

    Readers:
      #01: Ingenico TL TELIUM(1) (no card present)
      #02: F600 F600 Smart Card Reader 01 (no card present)
      #03: Ingenico TL TELIUM(2) (no card present)
      #04: F600 F600 Smart Card Reader 02 (ATR:{length = 17, bytes = 0x3bac00402a001225006480000310009000})
      #05: Ingenico TL TELIUM(3) (no card present)
      #06: F600 F600 Smart Card Reader (ATR:{length = 9, bytes = 0x3f6525002c09699000})
    Reader Drivers:
EOS
EOT
chmod +x "$T/bin/system_profiler"
: > "$T/galss.ini"
PATH="$T/bin:$PATH" HOME="$T/home" OJ_GALSS_INI="$T/galss.ini" bash "$MAC/galss-autofix.sh" >/dev/null 2>&1
c1=$(tr '\r' '\n' < "$T/galss.ini" | sed -n '/^\[CANAL1\]/,/^\[/p' | grep -i '^Caracteristiques=' | cut -d= -f2-)
c2=$(tr '\r' '\n' < "$T/galss.ini" | sed -n '/^\[CANAL2\]/,/^\[/p' | grep -i '^Caracteristiques=' | cut -d= -f2-)
echo "== 16. Mac : galss.ini attribue la CPS et la Vitale (Vitale 1, ATR 3F65)"
[ "$c1" = "F600 F600 Smart Card Reader 02" ] && echo "  ok   CPS -> '$c1'" || { echo "  ECHEC CPS -> '$c1'"; FAIL=1; }
[ "$c2" = "F600 F600 Smart Card Reader" ] && echo "  ok   Vitale -> '$c2' (lecteur qui contient la carte, pas la fente vide 01)" || { echo "  ECHEC Vitale -> '$c2'"; FAIL=1; }
grep -q "0x3b7513|0x3f65" "$MAC/OdaijiJuxta-Mac.sh" && echo "  ok   le diag Mac reconnait aussi la Vitale 1" || { echo "  ECHEC le diag Mac ne reconnait pas 3F65"; FAIL=1; }
rm -rf "$T"; exit $FAIL
