#!/bin/bash
# 17. Mac : depot dans JuxtaLink.app quand macOS refuse l'ecriture directe ("Operation not permitted" meme avec sudo : Gestion des apps).
# Faux sudo qui refuse toute ecriture dans l'app ; faux pkgbuild / installer qui, eux, posent les fichiers (comme le programme d'installation du systeme).
cd "$(dirname "$0")/.." || exit 1
COM=src/mac/Odaiji_Juxta_Mac/odaiji-commun.sh; FAIL=0
T=$(mktemp -d /tmp/ojdepot.XXXXXX); mkdir -p "$T/bin" "$T/kit/SSV/4.1.1.0"
export APP="$T/JuxtaLink.app"; mkdir -p "$APP/Contents/Resources/Plugins"
echo '<add key="tokenServerUrl" value="http://wwsapjd01.juxta.network:10300" />' > "$APP/Contents/Resources/user.config"
echo '<add key="tokenServerUrl" value="https://madeformed-drc-token.juxta.cloud" />' > "$T/kit/user.config"
echo x > "$T/kit/SSV/4.1.1.0/SSV.dll"; echo x > "$T/kit/SSV/4.1.1.0/ComposantsSV.dll"
export OJ_T="$T"
cat > "$T/bin/sudo" <<'EOT'
#!/bin/bash
# simule l'App Management : toute ecriture visant l'app est refusee, sauf par le "systeme" (installer)
cmd="$1"; shift
case "$cmd" in
  installer) exec "$OJ_T/bin/installer" "$@" ;;
  touch|rm|cp|mkdir|chmod|chflags) for a in "$@"; do case "$a" in "$APP"*) echo "$cmd: $a: Operation not permitted" >&2; exit 1;; esac; done ;;
esac
exec "$cmd" "$@"
EOT
cat > "$T/bin/pkgbuild" <<'EOT'
#!/bin/bash
root=""; base=""; out=""
while [ $# -gt 0 ]; do case "$1" in --root) root="$2"; shift 2;; --install-location) base="$2"; shift 2;; --identifier|--version) shift 2;; *) out="$1"; shift;; esac; done
mkdir -p "$out"; cp -R "$root" "$out/payload"; echo "$base" > "$out/base"
EOT
cat > "$T/bin/installer" <<'EOT'
#!/bin/bash
[ -n "$OJ_FAKE_INSTALLER_FAIL" ] && exit 1
pkg=""; while [ $# -gt 0 ]; do case "$1" in -pkg) pkg="$2"; shift 2;; *) shift;; esac; done
base=$(cat "$pkg/base"); mkdir -p "$base"; cp -R "$pkg/payload/." "$base/"
EOT
chmod +x "$T/bin/"*
export PATH="$T/bin:$PATH"
. "$COM"
echo "== 17. Mac : depot dans l'app quand l'ecriture directe est refusee"
oj_app_ecriture_ok && { echo "  ECHEC le faux sudo aurait du refuser l'ecriture"; FAIL=1; } || echo "  ok   ecriture directe refusee (simulation App Management)"
if oj_poser_uc "$T/kit/user.config"; then echo "  ok   user.config MadeForMed pose via le pkg local"; else echo "  ECHEC user.config non pose"; FAIL=1; fi
grep -q madeformed-drc-token "$APP/Contents/Resources/user.config" && echo "  ok   contenu MadeForMed present dans l'app" || { echo "  ECHEC contenu"; FAIL=1; }
if oj_poser_plugin "$T/kit/SSV/4.1.1.0"; then echo "  ok   plugin SSV 4.1.1.0 pose via le pkg local"; else echo "  ECHEC plugin non pose"; FAIL=1; fi
[ -f "$APP/Contents/Resources/Plugins/SSV/4.1.1.0/SSV.dll" ] && echo "  ok   SSV.dll present" || { echo "  ECHEC SSV.dll absent"; FAIL=1; }
# installer en echec : la fonction doit le DIRE (renvoyer non-zero), pas afficher OK
rm -rf "$APP/Contents/Resources/Plugins/SSV"; echo '<add key="tokenServerUrl" value="http://x" />' > "$APP/Contents/Resources/user.config"
OJ_FAKE_INSTALLER_FAIL=1 oj_poser_uc "$T/kit/user.config" && { echo "  ECHEC succes annonce alors que rien n'est pose (user.config)"; FAIL=1; } || echo "  ok   echec detecte (user.config)"
OJ_FAKE_INSTALLER_FAIL=1 oj_poser_plugin "$T/kit/SSV/4.1.1.0" && { echo "  ECHEC succes annonce alors que rien n'est pose (plugin)"; FAIL=1; } || echo "  ok   echec detecte (plugin)"
# ecriture directe possible (pas d'App Management) : pas de pkg
rm -rf "$T/bin/sudo"; printf '#!/bin/bash\nshift 0\nc="$1"; shift\nexec "$c" "$@"\n' > "$T/bin/sudo"; chmod +x "$T/bin/sudo"
OJ_FAKE_INSTALLER_FAIL=1 oj_poser_uc "$T/kit/user.config" && echo "  ok   ecriture directe quand macOS l'autorise (sans pkg)" || { echo "  ECHEC ecriture directe"; FAIL=1; }
rm -rf "$T"; exit $FAIL
