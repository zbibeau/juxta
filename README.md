# odaiji-juxta
Outils MadeForMed pour l'installation et le dépannage de JuxtaLink (Odaiji) sur les postes des médecins.
Site déployé par Netlify depuis ce dépôt. Voir `CHANGELOG.md`.

## Developpement
- Sources : `src/pc/Odaiji_Juxta_PC`, `src/mac/Odaiji_Juxta_Mac`. Version unique : `src/VERSION` (ligne 1 = version, ligne 2 = date).
- `bash build.sh` : tampon de version, controles, zips dans `kits/` (les installeurs .msi sont repris du zip precedent ou de `$INSTALLEURS_PC`).
- `bash tests/run.sh` : doit passer avant toute publication.
- Ne jamais modifier les zips ni les fichiers tamponnes a la main.
