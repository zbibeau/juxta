# Odaiji × JuxtaLink — kits d'installation et de dépannage

Page de téléchargement : `index.html` (détection Mac / Windows).
Kits : `kits/Odaiji_Juxta_PC.zip`, `kits/Odaiji_Juxta_Mac.zip`.

## 2026-09-24
- Mise en ligne initiale.
- PC v0.3.1 : installeur complet (MSI JuxtaLink 2.2.3 x86 inclus), diag, réparation, nettoyage,
  politique Chrome/Edge (Local Network Access), Full PC/SC par défaut avec retour arrière automatique.
- Mac v0.3 : installeur (pkg + plugin SSV téléchargés depuis KIT_URL, dossier Dropbox), diag,
  réparation, galss-autofix, politique Chrome/Edge, Full PC/SC par défaut.

## 2026-09-24 (2)
- Mac : sources.conf pointe sur la release GitHub `juxta-2.2.3` (pkg + plugin SSV 4.1.1.0) au lieu de Dropbox.

## 2026-09-24 (3)
- Page : section « Que contient le kit ? » (cartes par fichier : quand l'utiliser, ce qu'il fait, résultat), sélecteur Windows / Mac ; remplace la liste « Autres situations ».

## 2026-09-24 (4)
- PC + Mac : Autoriser-Odaiji-Chrome v1.1 — ajout Firefox 145+ (politique LocalNetworkAccess.SkipDomains :
  app.odaiji.co, *.odaiji.co, *.madeformed.fr, localhost, 127.0.0.1). Chrome/Edge inchangés. Partie Firefox
  isolée (try/catch) : un échec n'interrompt pas l'installeur. Vérification : about:policies.
- Page : outils regroupés Nouveau poste / Poste déjà équipé / Sur indication du rapport ;
  libellé « Local Network Access : Odaiji autorisé » ; encadré « Procédure d'installation — équipe »
  (reste manuel : chrome://flags, formation facturation seule ou totale).

## 2026-09-24 (5)
- PC v0.3.2 : correction du blocage à l'étape 4 (DRSAMITIER). `Start-Process -Wait` attendait aussi les processus
  enfants ; en scénario SESAM/GALSS le diag relance JuxtaLink (7e), qui ne se ferme jamais -> installeur figé.
  Les 5 appels du diag passent par `Run-Diag` (`-PassThru` + `WaitForExit()`, n'attend que le diag).
