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
- PC v0.3.2 (suite, test DRSAMITIER) : nouvelle étape **5c** en fin d'installation — arrêt de JuxtaLink, redémarrage
  propre puis lecture de contrôle CPS + Vitale (1re lecture Vitale en échec, OK après redémarrage).
  JuxtaLink est désormais lancé via `explorer.exe` (installeur et diag) : non élevé, dans la session du médecin,
  hors de l'arbre de processus des scripts (supprime aussi la cause du blocage aux étapes 4/5b).
  Diag : verdict `A_TESTER` (poste configuré, aucun KO, pas de lecture Vitale réussie) au lieu de `UNKNOWN`.
- Mac v0.3.1 : même étape **5c** (arrêt + redémarrage de JuxtaLink, lecture de contrôle CPS + Vitale) avant le diag Après.

## 2026-09-24 (6) — incident Nettoyage DRSAMITIER
- Constat : pendant Nettoyage.bat, redémarrage forcé du poste et TeamViewer disparu.
  Causes probables : désinstalleur non-MSI d'un produit Cegedim lancé en `/S` (peut redémarrer), et/ou TeamViewer
  (souvent déployé par Cegedim) inclus dans les produits ou dossiers Cegedim supprimés.
- PC v0.3.3 : outils de prise en main à distance exclus partout (produits, dossiers, entrées Run) ; désinstalleurs
  non-MSI seulement listés (à faire à la main) ; tous les `msiexec` avec `REBOOT=ReallySuppress` ;
  Nettoyage.bat affiche un avertissement et attend une confirmation. Page : « Avec le support uniquement ».

## 2026-09-24 (7) — analyse DRSAMITIER après nettoyage
- PC v0.3.4 : **bug de verdict** — `if (Has "A" -or Has "B")` n'évaluait que A en PowerShell (le reste passait en
  arguments). Conséquence : `GALSS_MISMATCH` (KO) ignoré, poste déclaré OK. Corrigé par `(Has "A") -or (Has "B")`.
- Scénario GALSS aussi quand les canaux CPS/Vitale pointent un lecteur absent (galss.ini est partagé avec Icanopée,
  toujours installé chez nos clients). Réparation 7b : `galss-autofix.ps1` (réaligne CANAL1 CPS + CANAL2 Vitale).
- galss-autofix relance JuxtaLink via explorer.exe (non élevé).

## 2026-09-24 (8)
- PC v0.3.5 : 2e redémarrage forcé pendant Nettoyage (juste après les Cryptolib, donc à l'étape produits Cegedim).
  Le nettoyage ne désinstalle plus aucun produit Cegedim/jFSE : il les liste (à retirer à la main, hors consultation).
  Chaque msiexec du nettoyage est tracé AVANT son lancement pour identifier un éventuel coupable.

## 2026-09-24 (9) — DRPARDON
- Cas : `mica x64 4.01.00` {e01e10c5…} (source RarSFX0) porte le même code produit que le MICA x86 4.01.00 du plugin
  -> installation MICA x86 refusée (1638), Vitale « présente : False », « Erreur dans la détection des slots ».
  Le diag refusait la désinstallation en auto (source non CEGEDIM/JFSE).
- PC v0.3.6 : MICA x64 de source `RarSFX` désinstallé automatiquement (même famille que DRSAMITIER / DR-CARRE).
  Filet `GALSS_REVERT` désactivé quand l'échec a une autre cause connue (MICA, SESAM, READER).

## 2026-09-24 (10)
- PC v0.3.7 : cas MICA de bout en bout sans ligne de commande. Le MICA x64 fantôme (sources CEGEDIM/JFSE/RarSFX)
  est retiré automatiquement, puis le cache Plugins est vidé et JuxtaLink relancé dans la foulée (7d devient
  automatique quand 7c a réussi). En mode interactif, les questions précisent « taper o » (Entrée seul = non).
- PC v0.3.8 : « o » tapé à « Désinstaller ce MICA x64 ? » sans effet (DRPARDON, 18:36 — aucune ligne msiexec dans
  le rapport). Cause non établie (touche tapée d'avance absorbée probable). Désormais : tampon clavier vidé avant
  chaque question, réponse o/n obligatoire, réponse écrite dans le rapport ; après désinstallation, vérification
  que le MICA x64 a disparu, sinon KO + commande manuelle affichée.

## 2026-09-24 (11)
- PC v0.3.9 : **Neutraliser-Cegedim.bat** / **Restaurer-Cegedim.bat**. Coupe le lancement des restes Cegedim / jFSE
  (entrées Run, raccourcis Démarrage, services, tâches planifiées) et arrête ClmLive / java lancé depuis un dossier
  Cegedim/jFSE. Aucune désinstallation, aucun redémarrage ; journal JSON écrit avant chaque action
  (C:\ProgramData\MadeForMed\CegedimNeutralise) ; restauration à l'identique. Jamais touchés : outils de prise en
  main à distance, JuxtaLink, Icanopée, amelipro, composants GIE. Le diag le suggère quand ClmLive/java sont actifs.
- Constat terrain (3 postes) : PERFORMANCE 0-1 s malgré les FSV/Cryptolib orphelines -> pas de nettoyage systématique.
- Restaurer-Cegedim.bat retiré du kit (demande Vivien). Le retour arrière reste possible pour le support :
  `powershell -ExecutionPolicy Bypass -File Neutraliser-Cegedim.ps1 -Restaurer` (journal conservé).

## 2026-09-25 — v0.3.10 (PC)
- Constat DRPARDON : après retrait du MICA x64, le « Module lecteur de cartes » Cegedim affiche « La librairie MICA
  n'est pas installée sur votre poste ! ». Le MICA x64 servait à Cegedim.
- Règle : le MICA x64 n'est retiré que si le médecin n'utilise plus Cegedim ; les restes Cegedim sont alors
  neutralisés dans la foulée (Neutraliser-Cegedim.ps1 -Auto, sans désinstallation). Sinon : MICA x64 conservé et
  KO « conflit MICA x64 Cegedim / MICA x86 Juxta, à remonter à Juxta ».
- Installeur : étape 1b, une seule question si des restes Cegedim sont détectés (« le médecin a-t-il arrêté
  d'utiliser tout logiciel Cegedim ? »), réponse transmise au diag (-SansCegedim).
- Reparer-interactif : même question posée avant la désinstallation du MICA x64.

## 2026-09-25 — v0.3.11 (PC)
- GERBAL : installeur figé à l'étape 4, section 7b (réalignement galss.ini). galss-autofix était lancé en pipe et
  relançait JuxtaLink ; le processus relancé gardait la sortie ouverte -> attente infinie.
- 7b : galss-autofix lancé comme processus séparé (fenêtre cachée), attente limitée à 60 s, résultat lu dans son
  journal (ProgramData\MadeForMed\galss-autofix.log), option -NoRelaunch (la relance est faite par 7e / 5c).

## 2026-09-25 — PC v0.3.12 / Mac v0.3.2 (GERBAL)
- DRC sous Chrome 153 malgré la politique LNA (Odaiji) et chrome://flags, alors que Firefox passe.
  Hypothèse : la requête vers JuxtaLink part d'une page/iframe *.juxta.cloud (serveurs DRC Juxta), absente de la
  liste Chrome (autorisation par site d'origine) ; Firefox passe car sa liste inclut localhost (côté cible).
  Les flags LNA de Chrome ne sont plus fiables après M152 (l'opt-out temporaire est retiré après M152).
- Autoriser-Odaiji-Chrome : ajout de https://[*.]juxta.cloud (Chrome/Edge) et *.juxta.cloud (Firefox).
  Diag : WARN si la politique ne contient pas juxta.cloud.
- certutil -silent -scinfo (diag + galss-autofix) : plus de fenêtre PIN possible (blocage 7b GERBAL, galss.ini non réaligné).
- kits/Autoriser-Odaiji-Mac.zip : outil Autoriser seul pour Mac (Chrome/Edge/Firefox, avec *.juxta.cloud), à envoyer
  directement à un client. Lien : https://odaiji-juxta.netlify.app/kits/Autoriser-Odaiji-Mac.zip

## 2026-09-25 — page
- Liste des outils mise à jour : installeur (faux MICA x64, Cegedim, redémarrage final), Autoriser (*.juxta.cloud,
  vérification chrome://policy, lien vers l'outil Mac seul), Reparer-lecteur.bat ajouté côté Windows,
  Nettoyage présenté comme rarement utile. Procédure équipe : chrome://policy (flags obsolètes depuis Chrome 153).

## 2026-09-25 — PC v0.3.13 (Dr Neyens)
- Constat (installation manuelle) : ERR_TIMED_OUT sur https://localhost:1234 ; le port 1234 est tenu par
  fsenxt.exe (Affid Systèmes), pas par JuxtaLink. Odaiji parle au mauvais programme : connexion acceptée, aucune
  réponse (CLOSE_WAIT), timeout ~10 s ; fsenxt arrêté -> échec immédiat car JuxtaLink n'écoute pas.
- Diag : section 4 vérifie quel programme écoute sur le port JuxtaLink (user.config, 1234 par défaut) ;
  autre programme -> KO PORT_CONFLICT, scénario PORT (prioritaire après READER).
