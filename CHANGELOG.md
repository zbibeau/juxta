# Odaiji × JuxtaLink — kits d'installation et de dépannage

Page de téléchargement : `index.html` (détection Mac / Windows).
Kits : `kits/Odaiji_Juxta_PC.zip`, `kits/Odaiji_Juxta_Mac.zip`.

## Correctif deploiement (1.1.0, sans changement de kit)
- Le build Netlify de 1.1.0 echouait : le scan de secrets detectait le nom du depot prive (valeur de GITHUB_REPO) cite en exemple dans rapport.mjs. Exemple retire ; test 15 ajoute pour empecher la recidive.

## PC / Mac 1.1.0 - 06/10/2026
- **Envoi des rapports robuste** : fichier d'attente local si pas de reseau (reprise automatique au passage suivant), identifiant de poste stable (Poste ID dans l'en-tete du rapport), cle d'envoi par cabinet (cle-envoi.txt, jamais dans le zip), JSON propre cote Mac, erreurs lisibles. Nouveaux : Odaiji-Commun.ps1 (PC), odaiji-commun.sh (Mac). Fonction de reception : authentification par cle (ODAIJI_KEYS / REQUIRE_KEY), idempotente, limitee, battements.
- **Sentinelle (pilote, optionnelle)** : Installer-Sentinelle.bat / .command. Diagnostic PASSIF (`-Leger` / `--leger` : aucune reparation, aucun acces au lecteur ni aux cartes, rien sur le Bureau) une fois par jour ; battement + rapport complet seulement si l'etat change ; pause par sentinelle.off ; jamais de mise a jour automatique.
- **Delta Avant -> Apres** affiche en fin de depannage / d'installation (corriges / restent / nouveaux).
- Masquage renforce des rapports : FINESS, numero PS (RPPS), NIR, dates de naissance, noms de patients (kits et serveur).
- Depot : catalogue des constats (regles/constats.json), parseur de rapports (outils/rapport_parse.py), tableau de bord du parc (outils/parc.py), corpus de 90 rapports reels anonymises (tests/corpus/real) et tests 7 a 14.

## PC / Mac 1.0.3 - 06/10/2026
- Mac : envoyer-journal.sh laissait les retours chariot dans le JSON (meme defaut que le rapport en 1.0.1, HTTP 400). Corrige.
- Depot : les sources des kits sont maintenant dans src/ ; `bash build.sh` tamponne la version (src/VERSION), controle (ASCII, CRLF, syntaxe, droits) et produit les zips. Les zips ne s'editent plus a la main.

## PC 1.0.2 / Mac 1.0.2 - 05/10/2026
- TOUT ce que le kit emet part maintenant a MadeForMed : rapports Avant / Apres / diag seul / Fix / Galss / Nettoyage, journal du depannage, journal de l'installation (nouveau), reparation DMP et reparation lecteur (nouveau). Nouveaux fichiers : Envoyer-journal.ps1 / Reparer-lecteur.ps1 (PC), envoyer-journal.sh (Mac).

## PC 1.0.1 - 05/10/2026
- Envoi automatique du rapport : en cas d'echec, le message affiche la cause (erreur HTTP / reseau) au lieu d'un echec silencieux.

## Mac 1.0.2 - 05/10/2026
- Envoi automatique du rapport : les retours chariot (CR) restaient dans le JSON, le serveur repondait 400 "JSON invalide". Ils sont maintenant retires. Nouveau test 6 (JSON d'envoi valide avec CR, tabulations, guillemets, octets non UTF-8).

## Mac 1.0.1 - 05/10/2026
- Envoi automatique du rapport : JSON construit en LC_ALL=C + iconv -c (octets non UTF-8 du log JuxtaLink), et le message d'echec affiche maintenant le code HTTP / l'erreur curl pour diagnostiquer.

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

## 2026-09-25 — PC v0.3.14
- Ménage proposé pour tout ancien logiciel qui occupe le port de JuxtaLink (cas Dr Neyens : fsenxt.exe, Affid),
  sur le modèle Cegedim : installeur étape 1c (question unique, -LibererPort transmis au diag) ;
  Reparer-interactif étape 7p (question « le médecin a-t-il arrêté d'utiliser … ? »).
  Si oui : Neutraliser générique (démarrage, services, tâches, processus du dossier de l'éditeur ; rien désinstallé,
  journal par éditeur), arrêt du programme, relance de JuxtaLink, vérification que JuxtaLink tient le port.
  Si non : KO « conflit de port », rien modifié. Jamais touchés : composants Windows, Juxta, Icanopée, santesocial,
  outils de prise en main à distance.
- Neutraliser-Cegedim.ps1 v1.1 : paramètres -Nom / -Motif (générique), journal distinct par éditeur.
- Reparer-lecteur.bat : utilisait uniquement C:\ProgramData\MadeForMed\galss-autofix.ps1 (présent seulement avec
  -WithAutofix) -> échouait depuis le kit. Utilise maintenant le script du dossier du kit, sinon celui de ProgramData.

## 2026-09-25 — PC v0.3.15 (Dr Neyens)
- Erreur Odaiji : « Section MGC absente, ou clé RepertoireConfigTrace absente, ou fichier log4crc.xml non trouvé ».
  Le diag ne vérifiait que les répertoires de sesam.ini. Il contrôle maintenant la section [MGC], sa clé
  RepertoireConfigTrace et la présence de log4crc.xml ; sinon KO SESAM_MGC -> sesam.ini régénéré (7a, sauvegarde .bak)
  avec [MGC] + log4crc.xml.

## 2026-09-25 — PC v0.3.16 (Dr Neyens, erreur MGC persistante)
- sesam.ini généré en chemins ABSOLUS (C:\ProgramData\santesocial\fsv\<v>\…) : certaines FSV ne développent pas
  %ALLUSERSPROFILE% -> log4crc.xml « introuvable » alors que le diag (qui développe) le voyait. Section [MGC] en majuscules.
- log4crc.xml créé dans le conf de chaque version FSV présente (le plugin peut utiliser une autre version).
- Diag : KO si RepertoireConfigTrace contient une variable %…% (-> régénération) ; signale tout autre sesam.ini
  trouvé sous santesocial.

## 2026-09-25 — PC v0.3.17 (Dr Neyens, POSTE1)
- Rapport : tables FSV **srt vides** (x86 0 fichier, pas de x64) -> « Exception lors de l'appel à ssv.lirecarteps »
  + message MGC. Sur GERBAL, les srt n'existaient qu'en x64 : le plugin Juxta installe les FSV x86 sans tables srt.
- Bug : le MSI FSV du kit n'était jamais trouvé (cherché à la racine du kit, il est dans installeurs\).
- Nouvelle étape 7t (auto, installeur compris) : tables manquantes -> installation du MSI FSV officiel du GIE
  (fsv-1.40.1413_x64.msi), recherche des tables dans toutes les FSV x86/x64, puis sesam.ini régénéré
  (chemins absolus). Nouveau scénario TABLES dans le verdict.
- Constat annexe : le port de JuxtaLink était 1230 dans la config manuelle (Odaiji appelle 1234) ; corrigé par
  notre user.config.

## 2026-09-25 — PC v0.3.18
- Filet GALSS_REVERT déclenché à tort sur POSTE1 (échec dû aux tables srt manquantes, verdict affiché GALSS) :
  il ne s'applique plus dès qu'une autre cause connue est présente (tables, sesam.ini, MGC, MICA, port).
- Question ouverte : sur POSTE1 (FSV 1.40.14), l'erreur MGC persistait avec un C:\Windows\sesam.ini correct ;
  il existe aussi C:\ProgramData\santesocial\fsv\1.40.14\conf\sesam.ini. Vérifier lequel la FSV 1.40.14 lit.

## 2026-09-25 — PC v0.3.19 (CLIENT022, POSTE1)
- galss-autofix ne reconnaissait aucune carte sur Windows FR (« Aucune carte vue ») : certutil met un espace
  insécable avant « : ». Analyse alignée sur celle du diag (\W*, nettoyage des caractères OEM) ; le diag transmet en
  plus les lecteurs CPS / Vitale qu'il a identifiés (-CpsReader / -VitReader). Effet : galss.ini réellement réaligné
  (CLIENT022 : CPS et Vitale inversées entre les deux Gemalto).
- CLIENT022 : MICA x64 conservé car restes Cegedim présents et réponse « Cegedim encore utilisé » (ou non confirmée).

## 2026-09-25 — PC v0.3.20 (CLIENT020, CLIENT022 : « carte Vitale non lue » chez Axel)
- Les deux postes : faux MICA x64 conservé -> Mica..ctor / 1638 -> Vitale non lue. L'outil n'avait pas retiré le
  MICA x64 car la question Cegedim (« a-t-il ARRÊTÉ… ? ») avait reçu « n » / pas de confirmation, et le verdict
  affichait GALSS au lieu de MICA.
- Question inversée et expliquée : « Le médecin facture-t-il ENCORE avec un logiciel Cegedim ? » ; n (cas normal
  quand Odaiji remplace Cegedim) = MICA x64 retiré + Cegedim neutralisé. Même logique pour le port 1234.
- MICA x64 conservé -> KO explicite « la Vitale ne pourra PAS être lue » (MICA_KEPT).
- Verdict : MICA, TABLES, SESAM passent avant GALSS (galss.ini ne sert plus qu'à iCanopée). Les réparations
  MICA / galss.ini / relance JuxtaLink s'exécutent selon les constats, plus seulement selon le scénario affiché.

## 2026-09-26 — PC v0.3.21 : mécanisme générique « facture-t-il ENCORE avec… ? »
- Nouveau catalogue `editeurs.psd1` (Cegedim, Affid) : nom, libellé, dossiers, motif de reconnaissance, bloquants
  connus. Ajouter un ancien logiciel = ajouter un bloc, sans toucher aux scripts.
- Installeur, étape 1b : pour chaque éditeur détecté, une seule question « Le médecin facture-t-il ENCORE avec … ? ».
  n = composants neutralisés (démarrage, services, tâches, processus ; rien n'est désinstallé) ; réponses transmises
  au diag (-SansEditeurs / -GardeEditeurs). Le port 1234 tenu par un éditeur connu suit la même réponse.
- Diag : section « Anciens logiciels métiers détectés » ; réparation 7n (une question par éditeur en interactif,
  jamais deux fois) ; MICA x64 (7c) et port (7p) utilisent la même décision ; conflit explicite si encore utilisé.

## 2026-09-28 — PC v0.3.22 : JuxtaLink sans UAC, Smart App Control, verdicts plus justes
- JuxtaLink exige l'UAC : lancé par une clé Run au démarrage de Windows, il était bloqué en silence -> après un
  redémarrage du PC, port 1234 vide et « carte Vitale non lue ». Nouveau : tâche planifiée `\Odaiji\JuxtaLink`
  (ouverture de session du médecin, privilèges les plus élevés) = démarrage sans fenêtre UAC ; icône
  « JuxtaLink (Odaiji) » sur le Bureau public ; anciens lancements auto mis de côté (sauvegarde
  HKLM\SOFTWARE\MadeForMed\JuxtaLinkDemarrage), jamais supprimés. Installeur étape 3b ; outil seul
  `Demarrage-JuxtaLink.bat` (`retirer` pour annuler) ; relances du diag via la tâche.
- Diag : JuxtaLink arrêté = KO (scénario ARRETE si c'est la seule cause, sinon ligne « En plus »), tâche absente = WARN,
  réparation 7s (crée la tâche + relance).
- Smart App Control (Windows 11) : actif = scénario SAC (mica.dll non signé bloqué, erreur 0xc0e90002) ; en
  évaluation = WARN (Windows l'active seul plus tard). Correction manuelle, signalée à Juxta (DLL non signées).
- Poste neuf sans plugin SSV = scénario PREMIERE_LECTURE au lieu d'un faux KO TABLES.
- Tables srt vides = WARN (2 postes facturaient sans) ; KO seulement si ssv/sts manquent.
- Tri des versions FSV corrigé : 1.40.9 était prise pour la plus récente devant 1.40.14 (tri alphabétique).
- Neutraliser : couvre aussi la ruche Run et le dossier Démarrage du médecin (résidus revenus au redémarrage).

## 2026-09-28 — PC v0.3.23 : « n » = désinstallation de l'ancien logiciel
- Réponse n à « Le médecin facture-t-il ENCORE avec … ? » : après la neutralisation, Neutraliser-Cegedim v1.2
  `-Desinstaller` retire les produits MSI de l'éditeur un par un (`msiexec /x /qn /norestart REBOOT=ReallySuppress`,
  5 min max chacun). Exclus : FSV, Cryptolib, MICA, GALSS, santesocial, JuxtaLink, iCanopée, amelipro, Java, .NET,
  Visual C++, prise en main à distance. Contrôle après chaque produit : si un outil de prise en main, JuxtaLink,
  iCanopée ou mica.dll disparaît, arrêt immédiat.
- Désinstalleurs non-MSI (ceux qui ont redémarré des postes le 24/09) : listés, jamais lancés.
- Dossiers de l'éditeur (catalogue editeurs.psd1) déplacés dans `C:\_Odaiji_a_supprimer\<éditeur>-<date>` (à vider
  après validation de la facturation Odaiji ; remis en place par -Restaurer). Journal complété (Desinstalles, Quarantaine).
- Neutraliser-Cegedim.bat lancé seul : inchangé (neutralisation sans désinstallation).
- Neutraliser : un journal existant ne bloque plus une nouvelle passe (ClmLive / java revenus malgré une 1re neutralisation) ;
  le lanceur (processus parent) de chaque processus arrêté est écrit dans le rapport.
- Correctif : relance de JuxtaLink en réparation (fonction Start-Jx cassée, erreur « elseStart-Jx ») ; contrôle automatique
  des noms de commandes inconnus ajouté avant chaque publication.
- Correctif galss-autofix : avec un seul candidat pour la fente Vitale, seule sa 1re lettre était écrite (Vitale='K') ;
  garde-fou : seuls des noms de lecteurs vus par Windows sont écrits.
- Correctif 7n : « Argument manquant pour le paramètre Dossiers » (dossiers du catalogue non transmis) -> désinstallation non lancée.

## 2026-09-28 — PC v0.3.24
- galss-autofix / Reparer-lecteur : deux lecteurs séparés (CPS sur l'un, Vitale sur l'autre, Vitale non identifiée par certutil)
  -> le seul autre lecteur où une carte est présente est retenu pour la Vitale.
- C:\Windows\sesam.ini absent = WARN (et non KO) si le sesam.ini de la FSV (ProgramData\santesocial\fsv\<version>\conf) existe :
  3 postes facturaient ainsi.
- Réparation 7l : Reparer-interactif autorise aussi Chrome/Edge/Firefox (Local Network Access) quand le diag les voit en KO
  (jusqu'ici seulement à l'installation, étape 4b).
- JuxtaLink.exe cherché aussi hors de Program Files (x86) : processus en cours, registre (InstallLocation), Program Files, AppData.
- Verdict : galss.ini incohérent = avertissement Icanopée (et non scénario GALSS) quand JuxtaLink est en PC/SC direct et lit déjà.
- Catalogue editeurs.psd1 : ajout de **Shaman** (dossiers Program Files\Shaman, C:\Shaman ; motif shaman|maj400).
- Libellés : « DMP Connect / iCanopée » partout dans les rapports ; galss.ini incohérent = à corriger seulement si DMP Connect ne marche pas.

## 2026-09-28 — Mac v0.3.3 (1er Mac terrain : JuxtaLink + DMP Connect OK)
- Aucun lecteur : inventaire USB via ioreg (SPUSBDataType vide sur macOS 15+), lecteur absent du bus = matériel,
  alerte lecteur branché sur un clavier (courant), rappel « Autoriser les accessoires à se connecter ».
- MediMust : détection (démarrages launchd, processus) ; 7m / installeur : « facture-t-il ENCORE avec MediMust ? »
  n = démarrages coupés et sauvegardés sur le Bureau (_Odaiji_a_supprimer), rien n'est supprimé.
- --sans-galss : le GALSS n'est jamais retiré si DMP Connect / iCanopée est installé (GALSS unique partagé sur Mac).

## 2026-09-28 — PC v0.3.25
- Catalogue : **Weda** (Vitalzen, Weda Connect) — motif vitalzen|weda, dossiers Program Files / ProgramData / AppData\Local\Programs.
  Composants exacts à confirmer sur le 1er poste.
- Diag : section « Autres logiciels actifs » (ports locaux, démarrages automatiques, services hors Windows, produits santé)
  avec repère « a verifier (concurrent ?) », pour repérer un logiciel concurrent absent du catalogue.
- Nouvel outil Surveiller-JuxtaLink.bat : contrôle toutes les 20 s pendant 8 h (processus, PID, port 1234, réponse HTTPS, Weda/Vitalzen),
  n'écrit que les changements et lenteurs (JuxtaLink « injoignable par moment »).
- 1er poste Weda : VitalZen 0.61.4 (WEDA SAS) = C:\Program Files\VitalZen, port 10100, démarrage fr.comunica.vitalzen ;
  désinstalleur non-MSI (listé). Catalogue : ajout de **Pyxvital** (C:\pyxvital, port 10500). Neutraliser : plus d'erreur
  Get-CimInstance quand le processus parent a disparu.
- Surveiller-JuxtaLink : suit aussi Pyxvital (retour éventuel après coupure).
- Weda (retour terrain) : Weda Connect se relance à chaque démarrage -> désinstallé. Neutraliser v1.3 -NonMsi (éditeurs marqués
  DesinstallerNonMsi) : désinstalleurs non-MSI en silencieux (QuietUninstallString, Inno, Squirrel, NSIS), 5 min max, contrôles
  habituels ; applications par utilisateur (HKCU / ruche du médecin) incluses. Motif Weda élargi à « comunica » (fr.comunica.vitalzen).

## 2026-09-28 — Mac v0.3.4 (Dr De Paris : iMac + MacBook Air, lecteur Ingenico Telium)
- CPS via Telium (ATR 3bdc18…) reconnue (diag + galss-autofix) : faux « CPS non vue » et galss.ini jamais réaligné.
- galss.ini à fins de ligne CR (Mac classique) lu correctement (faux « galss.ini déclare 1NomL… »).
- Anciens logiciels Mac génériques : MediMust + **MediStory (Prokov)** (question, coupure launchd, rien supprimé).
- **Poste serveur** (base Oracle de l'ancien logiciel, ex. Crossway/Cegedim sur le poste du cabinet) : base jamais touchée ;
  réponse n = seulement les programmes liés au lecteur coupés + MICA x64 retiré, ni désinstallation ni quarantaine.
  Oracle / OpenVPN ajoutés aux éléments protégés. Verdict : MICA x64 revenu (mise à jour Cegedim) + erreur 1638 = scénario MICA.
- galss-autofix / Reparer-lecteur : canaux supplémentaires (3, 4…) en fin de galss.ini pointant vers un lecteur absent supprimés
  (ListeCanaux / NbCanaux mis à jour) — DRSAMITIER : CANAL3 sur l'ancien Ingenico empêchait DMP Connect de lire la CPS.

## 2026-09-28 — PC v0.3.26 (retour DRSAMITIER : DMP Connect KO, appels CPS lents)
- Diag : « Causes de lenteur présentes » à chaque rapport — programmes qui se disputent le lecteur (jFSE, ClmLive, Pyxvital,
  VitalZen, Weda), CertPropSvc automatique, VPN connecté, antivirus tiers (exclusions à demander), Cryptolib multiples.
- 7v : CertPropSvc en Manuel (avec confirmation, réversible).
- DMP Connect : « Timeout » répétés + canal galss.ini sur lecteur absent = KO DMP_TIMEOUT_GALSS ; -Fix réaligne galss.ini
  (canaux fantômes supprimés) puis redémarre le service DMP Connect (7d-bis).
- Poste serveur Cegedim + MICA x64 revenu : rappel que le service Octave le réinstalle (réponse n : Octave coupé, base conservée).

## 2026-09-29 — PC v0.3.27 (correctif bloquant)
- Le diag (et l'installeur) plantait dès le démarrage avec « Impossible de lier l'argument au paramètre Path, car il s'agit
  d'une chaîne vide » (JuxtaLink-Demarrage-lib.ps1:13) quand l'entrée JuxtaLink du registre n'a pas d'icône (DisplayIcon vide).
  Recherche de JuxtaLink.exe rendue infaillible (repli sur l'emplacement par défaut) et chargement des fonctions
  JuxtaLink-Demarrage protégé : une erreur à cet endroit ne peut plus bloquer le diagnostic.

## 2026-09-29 — PC v0.3.28 (3 fenêtres d'erreur au démarrage de JuxtaLink)
- Symptôme : « Aucun package d'installation pour le produit JuxtaLink… SetupJuxtaLinkx86.msi », « ressource réseau non
  disponible » (source dans `AppData\Local\Temp\…`), « Erreur irrécupérable lors de l'installation ».
- Cause : kit lancé depuis le zip ouvert sans extraction → MSI installé depuis un dossier Temp purgé ensuite ; et les
  v0.3.24-0.3.27 DÉPLAÇAIENT le raccourci / la clé de démarrage d'origine, qui appartiennent au MSI → Windows Installer
  les voit manquants, veut réparer, ne trouve plus sa source.
- Installeur : refuse de tourner depuis le zip / un dossier Temp ; MSI copié dans `C:\ProgramData\MadeForMed\JuxtaLink`
  (source permanente) avant installation.
- Lancements auto d'origine désormais DÉSACTIVÉS (StartupApproved, comme le Gestionnaire des tâches) au lieu d'être
  déplacés ; ceux déplacés par les versions précédentes sont remis en place.
- Diag : source MSI JuxtaLink, événements MsiInstaller 1001/1004, éléments déplacés (JX_MSI_SOURCE / JX_MSI_REPAIR / JX_MOVED).
- Réparation 7r (et Demarrage-JuxtaLink.bat) : source rétablie depuis le MSI du kit (même PackageCode) + `msiexec /fomus` silencieux.
- Diag : plus de « galss.ini cohérent » affiché juste après un canal CPS inversé (retour PCCABINET 29/09).
- Verdict : Vitale retirée avant le diag → « OK » si une lecture Vitale récente a réussi (au lieu de « Cas non reconnu »).

## 2026-09-29 — PC v0.3.29 (retour PCCABINET)
- Catalogue : **DrSanté (Calimaps)** (DrSante.Api, services Launcher / Watcher). Nouveau mode `NeutraliserSeulement` :
  réponse n = services et programmes coupés, **ni désinstallation ni quarantaine** (logiciel médical : dossiers patients possibles).
- Causes de lenteur : chemin des exceptions Bitdefender (Antivirus + Advanced Threat Defense, prévention des menaces en ligne).
- 7r : attend que Windows Installer soit libre avant de relancer JuxtaLink (sinon sa mise à jour de plugin échoue en 1618 puis 1603 — PCCABINET 29/09).
- Diag : erreurs 1603/1618 du plugin SSV → affiche les échecs Windows Installer des 3 derniers jours (produit en cause + message d'erreur), pour enfin isoler la cause des 1603.
- Catalogue : **HelloDoc (Imagine Editions)** en neutralisation seule ; PostgreSQL (base HelloDoc) ajouté aux éléments protégés de Neutraliser (retour HANSIANE 29/09).
- Installeur : question « facture-t-il encore avec… ? » aussi quand l'ancien logiciel est installé mais fermé (programmes installés vérifiés) ; dossiers HelloDoc pour la détection.
- Catalogue : Affid passe en neutralisation seule (logiciel médical local, dossiers patients possibles).

## 2026-09-29 — PC v0.3.30 (retour HANSIANE : « carte Vitale non reconnue »)
- Débloqué en relançant JuxtaLink (Reparer-lecteur) ; Reparer-interactif n'avait rien trouvé. Verdict A_TESTER : conseil
  « relancer JuxtaLink » si Odaiji dit carte Vitale non reconnue.
- Reparer-lecteur relance JuxtaLink via la tâche \Odaiji\JuxtaLink (sans UAC) quand elle existe.
- Diag : liste du catalogue affichée (repère un kit périmé : HelloDoc absent de la détection sur HANSIANE).

## 2026-09-29 — PC v0.3.31 (retour Dr Plongeron : erreur MGC après installation)
- Verdict « OK » à tort : CPS/Vitale présentes, mais la dernière lecture renvoyait « Section MGC absente… » (exception
  ssv.lirecarteps). La dernière réponse de la FSV est maintenant décodée : erreur MGC → KO scénario SESAM, lecture non comptée OK.
- La FSV peut lire un autre sesam.ini que C:\Windows\sesam.ini : la section [MGC] est vérifiée dans tous les sesam.ini
  (ProgramData / Program Files) et reposée par la réparation 7a (sauvegarde, seule la section [MGC] est réécrite).

## 2026-09-30 — PC v0.3.32 (retour DESKTOP-RNFKE1A : neutralisation trop large, Cryptolib du GIE)
- Neutraliser-Cegedim v1.5 : le motif `synchro` attrapait des éléments Windows / Adobe (tâches « SynchronizeTime »,
  « ForceSynchronizeTime », « SynchronizeTimeZone », « Synchronize Language Settings », « Work Folders Logon Synchronization »,
  « User_Feed_Synchronization », services OneSyncSvc et vmictimesync, entrées « Adobe Acrobat Synchronizer ») qui étaient désactivés.
  Motif resserré (`clm\w*synchro|synchro\w*clm`) + garde-fou : un élément Windows / Microsoft / Adobe n'est jamais ciblé, sauf s'il porte
  le nom de l'éditeur. Même correction dans `editeurs.psd1` et dans l'étape Run du Nettoyage.
- Nouveau : `Neutraliser-Cegedim.ps1 -Restaurer -Systeme` (administrateur) remet en route uniquement les éléments désactivés à tort
  (Windows / Microsoft / Adobe, ou que le motif corrigé ne cible plus) ; les éléments de l'ancien logiciel restent neutralisés.
  À lancer sur les postes traités avec le kit v0.3.29 à v0.3.31 si la neutralisation Cegedim y a été faite.
- Nettoyage 7h : les Cryptolib livrées avec les outils du GIE (`ProgramData\santesocial` : cps, atsam = Diagnostic Assurance Maladie) et celle
  de DMP Connect / iCanopée ne sont plus désinstallées ni réparées ; msiexec avec délai max de 180 s (la réparation `/fa` pouvait rester bloquée,
  rapport coupé à l'étape 7h) ; code 1605 expliqué (produit déjà absent).
- Diag 3b : la Cryptolib x64 de DMP Connect est enfin détectée (le libellé « Composants Cryptographiques CPS » ne contenait pas « cryptolib » :
  « Cryptolib absente » à tort).
- galss-autofix v1.1 : lecteurs nommés « … Reader 0 / Reader 1 » (Identive CLOUD 2700 R) : la 2e fente est retrouvée (le nom n'a qu'un chiffre
  final), le réalignement ne dépend plus de la présence de la Vitale ; message clair si CPS ou Vitale manque.

## 2026-09-30 — PC v0.3.33 (outil de neutralisation à part, pour l'équipe)
- Nouveau : `Neutraliser-Ancien-Logiciel.bat` (équipe uniquement). Menu construit depuis le catalogue `editeurs.psd1` : pour chaque logiciel,
  ce qui est détecté sur le poste (dossier, processus actif, produit inscrit, base de données de l'éditeur). Choix du logiciel puis du mode :
  **N** neutralisation seule (démarrage, services, tâches, processus ; rien n'est désinstallé, recommandé) ou **D** neutralisation +
  désinstallation MSI (dossiers en quarantaine) — D jamais proposé pour les logiciels médicaux du catalogue (dossiers patients possibles)
  ni sur un poste qui héberge la base de l'éditeur. Le moteur montre ce qui sera coupé et demande confirmation.
- **R** remet en route un logiciel neutralisé (un journal par logiciel) ; **S** remet en route les éléments Windows / Adobe coupés à tort par
  les kits 0.3.29 à 0.3.31 (journaux dont le logiciel est au catalogue, avec le motif de chaque logiciel). `-Nom X` va directement au choix du
  mode ; `-Simulation` affiche la commande sans rien exécuter. Rapport `Neutralisation_<poste>_<date>.txt` sur le Bureau.
- Même moteur que l'installeur (`Neutraliser-Cegedim.ps1` v1.5, inchangé) : l'installeur et la réparation continuent de proposer la
  neutralisation pour chaque ancien logiciel détecté. `Neutraliser-Cegedim.bat` reste (Cegedim seulement). La page de téléchargement présente le nouvel outil.


## 2026-09-30 — Mac v0.3.5 (Mac mini de Lancelot)
- Diag : version DmpConnect lue via pkgutil (affichait « v » vide) ; accents des logs JuxtaLink conservés (locale UTF-8) ;
  BLOQUERINSTALLEGALSS sans virgule finale ; « Dossier Plugins non inscriptible » devient une info quand le plugin SSV est installé.

## 2026-09-30 — PC v0.3.34 (POSTE1 : port 1234 pris par Affid)
- galss-autofix : un galss.ini à un seul canal série (ancien logiciel, sans [CANAL2]) n'est plus signalé en ERREUR ; il n'est pas modifié et le message explique l'impact (DMP Connect seulement).
- Neutralisation : le message de fin indique le nombre de dossiers réellement mis en quarantaine (il annonçait une quarantaine même quand rien n'était déplacé).

## 2026-09-30 — PC v0.3.35 (POSTE1 : erreurs token 1100 / update 1200, puis MGC)
- Profil : quand l'UAC est validée avec un autre compte que le médecin, le kit vise le profil de la session ouverte (propriétaire d'explorer.exe) pour user.config, plugins et tâche de démarrage, comme l'installateur.
- user.config : absent du profil, sans serveurs token/update, ou port différent de 1234 = KO au diag ; correction 7k (copie du user.config MadeForMed ou port remis à 1234) puis relance de JuxtaLink.
- sesam.ini : la section [MGC] est désormais posée dans les autres sesam.ini (ProgramData\santesocial\fsv\<version>\conf) même quand C:\Windows\sesam.ini est correct (étape 7a-ter). Avant, seulement lors de sa régénération.
- sesam.ini : un dossier des tables srt (x86) absent n'est plus un KO qui relance la régénération ; WARN puis dossier créé vide par -Fix (7a-quater) (NB-DELL-01).

## 2026-09-30 — PC v0.3.36 (user.config aussi côté compte admin)
- user.config : quand l'UAC est validée avec un autre compte (ex. admin.agtek), JuxtaLink lancé avec ce compte lit le user.config de SON profil. Le kit le pose désormais aussi dans le profil du compte admin (installateur + correction 7k) ; le diag signale son absence (UC_ADMIN, WARN).

## 2026-10-01 — Mac v0.3.6 (MacBook Pro : user.config sans les serveurs MadeForMed)
- Installateur : JuxtaLink est arrêté juste après le pkg (qui peut le lancer seul et lui faire écrire sa propre config) ; le user.config MadeForMed est posé dans Contents/Resources et dans tout autre emplacement existant, puis vérifié après le redémarrage final (repose + relance si les serveurs ont disparu).
- Diag : contrôle que le user.config contient les serveurs MadeForMed (UC_NOT_MFM / UC_ABSENT).

## 2026-10-01 — PC v0.3.37 (POSTE1 : iCanopée ne lit pas, galss.ini en série)
- galss-autofix v1.2 : un galss.ini d'ancien logiciel (un seul canal série `9600,1,8,0,0` portant CPS + Vitale, sans CANAL2) est converti en PC/SC (2 canaux : CPS puis Vitale, bibliothèque PCSCW64.DLL), sur le modèle du galss.ini Mac, en gardant le [PROTOCOLE0] d'origine ; sauvegarde `.bak`, JuxtaLink relancé. Avant, ce cas n'était pas modifié, donc DMP Connect / iCanopée ne voyait pas le lecteur. Testé sur le fichier du POSTE1 (simulation) ; à confirmer sur le poste (redémarrer le service DMP Connect, lecture CPS via iCanopée).

## 2026-10-01 — PC v0.3.38 / Mac v0.3.7 (retours installation)
- PC : l'installateur ne s'arrête plus sur « Relancer Firefox… Entrée pour fermer » (Autoriser-Odaiji-Chrome avec -NoPause ; les politiques sont prises en compte au prochain redémarrage du navigateur). Bandeau coloré net à l'étape « Enregistrer la situation de facturation » + lecture CPS/Vitale.
- Mac : le diagnostic ne parcourt plus ~/Library (demandes macOS iCloud / OneDrive / Photothèque supprimées). Étape 5 : JuxtaLink est relancé avec le user.config MadeForMed, vérifié (config chargée + port 1234 en écoute), puis seulement ensuite le bandeau « Enregistrer la situation de facturation ».

## 2026-10-01 — Mac v0.3.8 (MacBook Air : installation OK, faux KO Mica, LNA)
- Diag : une erreur Mica du log antérieure au dernier démarrage de JuxtaLink (session précédente, avant l'installation de MICA par le plugin) est ignorée au lieu d'être comptée KO.
- Installateur : après Autoriser-Odaiji-Chrome, vérifie la politique Local Network Access de Chrome/Edge et la repose (erreurs affichées) si elle est absente.

## 2026-10-01 — PC v0.3.39 (DRLECLERE : DMP Connect ne lit plus, galss.ini disparu)
- Sur ce poste `C:\Windows\galss.ini` (série, hérité de Shaman) existait avant l'installation et était absent après : DMP Connect / iCanopée n'avait plus de fichier pour trouver le lecteur (JuxtaLink, en PC/SC direct, restait OK ; aucun rapport avec le port 1234).
- galss-autofix v1.3 : un galss.ini absent est recréé en PC/SC (CPS / Vitale) si DMP Connect ou le GALSS x64 est installé.
- Diag : galss.ini absent avec DMP Connect installé = WARN GALSS_MISSING, traité par Reparer-lecteur / 7b.
- Étape 7g (retrait du GALSS x86) : sauvegarde de galss.ini avant et restauration s'il a disparu.

## 2026-10-01 — PC v0.3.40 (installateur : enchaîne avec la réparation du lecteur)
- Fin d'installation (étape 5d, après le redémarrage propre de JuxtaLink) : si DMP Connect / iCanopée (ou le GALSS x64) est installé et que `C:\Windows\galss.ini` est absent ou encore en mode série, l'installateur lance la logique de Reparer-lecteur (galss-autofix, avec CPS + Vitale insérées), redémarre le service DMP Connect, puis vérifie que le fichier est en PC/SC. Le diag « Après » reflète le résultat.

## 2026-10-02 — PC v0.3.41 (Reparer-lecteur figé et muet : PC-MED2-0220, SUZANNE-PC-PORT)
- galss-autofix v1.4 : la première action du script, `certutil -scinfo`, pouvait ne jamais rendre la main (carte tenue par un autre programme) alors que la fenêtre n'affichait rien. L'étape est maintenant annoncée (« Analyse des lecteurs et des cartes… 45 s maximum ») et limitée à 45 s, avec un message clair et une ligne dans `C:\ProgramData\MadeForMed\galss-autofix.log`. Cause réelle du blocage non confirmée : si le message de délai apparaît, c'était bien certutil.
- Les échecs MSI 1603 « Composants Cryptographiques CPS v5.2.2 (x64) » observés pendant les essais ne viennent pas du script : c'est le plugin SSV qui retente cette installation à chaque relance de JuxtaLink (déjà vu, sans effet sur les lectures).

## 2026-10-02 — PC v0.3.42
- Neutraliser-Ancien-Logiciel : le prompt n'affiche plus `[N/D/A]` quand la désinstallation n'est pas proposée (logiciels médicaux comme HelloDoc) mais `[N/A]` ; D était refusé sans explication (SUPERMYLOUNE).

## 2026-10-02 — PC v0.3.43
- DESKTOP-LD0E22D (retour Axel) : le MSI FSV échouait avec « Impossible de définir la sécurité du fichier C:\ProgramData\santesocial\fsv\… ». Le diag (-Fix, 7t et 7a-bis) exécute maintenant `takeown` + `icacls` (SID Administrateurs/SYSTEM) sur ce dossier puis relance le MSI une seule fois.
- Installeur, étape 5d : seul le service iCanopee (DmpConnect-JS2, non désactivé) est redémarré ; son état est vérifié et il est relancé s'il est arrêté.

## 2026-10-02 — Mac v0.3.9
- Installateur : animation avec le temps écoulé pendant le diagnostic, l’installation du pkg JuxtaLink (1 à 3 min), les corrections et le retrait du GALSS, et barre de progression des téléchargements. L’écran restait figé après « installer: Installing at base path / » (iMac Poste3) et semblait bloqué.

## 2026-10-02 — Mac v0.3.10
- Étape 5 : user.config MadeForMed écrit partout avant l’arrêt et le redémarrage de JuxtaLink (déclenche l’installation automatique des prérequis du plugin SSV). Si JuxtaLink remet sa config par défaut (iMac Poste3 : « user.config MadeForMed absent »), jusqu’à 3 essais dont un avec fichier verrouillé, et la valeur réelle de tokenServerUrl est affichée pour diagnostic.

## 2026-10-02 — Mac v0.3.11
- Étape 5 : le bandeau « A VOUS DE JOUER » est remplacé par l’annonce du redémarrage de JuxtaLink et de l’installation automatique (FSV, GALSS, MICA, Cryptolib) ; « Enregistrer la situation de facturation » est demandé après l’installation.

## 2026-10-02 — PC v0.3.44
- Installateur, étape 5 : JuxtaLink est toujours arrêté puis relancé après la pose du user.config MadeForMed (il pouvait déjà tourner avec l’ancienne config), avec contrôle du port 1234 et un second essai ; message explicite s’il est bloqué (UAC, antivirus, SmartScreen). Le bandeau annonce le redémarrage et l’installation automatique de FSV/GALSS/MICA/Cryptolib, puis demande « Enregistrer la situation de facturation » après l’installation.

## 2026-10-03 — PC v0.3.45
- DESKTOP-H0L11PM : 7a posait la section [MGC] dans `C:\ProgramData\santesocial\fsv\<ver>\conf\sesam.ini`, puis 7a-bis (MSI FSV en réparation) réécrivait ce fichier sans [MGC] ; l’erreur « Section MGC absente » revenait à la lecture suivante. La section est maintenant reposée après chaque passage du MSI FSV (7a-bis et 7t).

## 2026-10-03 — PC v0.3.46
- Nouveau `Depannage.bat` pour un poste où JuxtaLink est déjà installé : diag Avant → questions (anciens logiciels, port 1234) → corrections sûres (`-Fix -Auto`) → réparation du lecteur (`galss-autofix`, redémarrage ciblé du service iCanopée) et autorisation Chrome/Edge selon les constats → relance de JuxtaLink avec contrôle du port 1234 → questions de confort (CertPropSvc en Manuel, ménage des Cryptolib en doublon via `-Nettoyage`) → diag Après avec résumé. Journal `Depannage_<poste>_<date>.txt` sur le Bureau.
- Les questions CertPropSvc et ménage Cryptolib sont reformulées : à quoi ça sert, ce qui est protégé, réponse conseillée.

## 2026-10-03 — PC v0.3.47
- Depannage.bat : CertPropSvc passe en Manuel automatiquement (plus de question, une ligne explicative et le retour arrière sont affichés).

## 2026-10-03 — PC v0.3.48
- Depannage.bat : retrait automatique du GALSS x86 Juxta (Full PC/SC, `-SansGalss`) quand il est présent, revenu, ou que sa réinstallation n’est pas bloquée ; le diag vérifie ses prérequis et sauvegarde/restaure `galss.ini`.
- Installateur : CertPropSvc passe en Manuel automatiquement et le ménage des Cryptolib en doublon est proposé (même question que le dépannage), pour que les deux parcours fassent la même chose.

## 2026-10-03 — PC v0.3.49 / Mac v0.3.13
- Fichiers numérotés dans les deux kits : `1-Installer`, `2-Depanner`, `3-Diag-seul` (ex Installer-Odaiji-Juxta, Depannage, Diag-seul).
- Mac : nouveau `2-Depanner.command` (diag Avant, questions anciens logiciels, corrections auto, lecteur galss, Chrome/Edge, Full PC/SC, relance JuxtaLink avec user.config vérifié et port 1234, diag Après, journal `Depannage_…txt`).
- Page : switch Windows/Mac avec un seul bouton Télécharger, switch Installation/Dépannage, étapes détaillées par kit, « Ce qu’il vous reste à faire » (GED, chrome://flags avec capture, rapports, formation).

## 2026-10-04 — PC v0.3.50 / Mac v0.3.14
- Gardien JuxtaLink : veille toutes les 10 min ; JuxtaLink fermé ou planté → relancé seul (PC : tâche planifiée `\Odaiji\Gardien-JuxtaLink` SYSTEM, relance via la tâche JuxtaLink sans UAC ; Mac : agent launchd `fr.madeformed.juxtalink-gardien`).
- Garde-fous : rien si personne n'est connecté, rien pendant une installation Windows ni un outil du kit, 3 relances max en 30 min (puis « BOUCLE » dans le journal), JuxtaLink qui tourne mais port 1234 muet 2 veilles → relancé.
- Posé par 1-Installer, 2-Depanner (et Demarrage-JuxtaLink.bat sur PC) ; le diag signale `GARDIEN_ABSENT`. Journaux : `C:\ProgramData\MadeForMed\Gardien\gardien.log` (PC), `~/Library/Logs/juxtalink-gardien.log` (Mac).

## 2026-10-05 — PC v0.3.51
- 2-Depanner.bat : demande d'insérer CPS + Vitale juste avant la réparation du lecteur (poste MSI : la CPS avait été retirée entre le diag Avant et cette étape, galss.ini n'a pas été recréé) et réessaie une fois si Windows ne voit aucune carte.
- Diag : l'échec 1603 « Composants Cryptographiques CPS v5.2.2 (x64) » du plugin SSV passe en information (et non plus [KO]) quand une Cryptolib x64 plus récente est déjà installée.
- Plus de message d'erreur parasite « Get-NetTCPConnection » dans le journal à l'étape de relance de JuxtaLink.

## 2026-10-05 — PC v0.3.52 / Mac v0.3.15
- Messages alignés sur l'Installateur : l'installation des SSV démarre à « Enregistrer la situation de facturation » ; le contrôle final = une facture avec une carte Vitale, puis une facture sans Vitale (valider l'appel ADRi). Bannière et textes PC/Mac, page de téléchargement.

## 2026-10-05 — PC v0.3.53
- FSV : si sa source d'installation Windows Installer est fragile (dossier Téléchargements/Temp/profil utilisateur, ou disparue), le diag le signale (FSV_MSI_SOURCE) et la réparation copie le MSI FSV du kit dans C:\ProgramData\MadeForMed\FSV puis le déclare comme source (sans réinstaller). Rien n'est fait sur les postes où la source est durable.

## 2026-10-05 — PC v0.3.54 / Mac v0.3.16
- Envoi automatique du rapport à assistance.odaiji@madeformed.com (via une fonction Netlify `netlify/functions/rapport.mjs` + Resend), sans question à l'utilisateur, uniquement si un [KO] reste (PC : ou scénario inconnu). Échec silencieux, avec message de repli (Intercom). Aucune clé dans le kit : RESEND_API_KEY / REPORT_TO / REPORT_FROM sont des variables d'environnement Netlify.

## 2026-10-05 — Mac v0.3.17
- 2-Depanner.command : bug corrigé — les constats dont le code contient des minuscules (ex. LNA_Google_Chrome) n'étaient pas lus, donc l'autorisation Chrome/Edge (Local Network Access) n'était jamais appliquée par le dépannage (« Navigateurs : rien à faire » alors que le diag signalait un [KO]).
- 2-Depanner.command : demande d'insérer CPS + Vitale juste avant le réalignement de galss.ini (sans les deux cartes, galss-autofix ne peut pas identifier les fentes).

## 2026-10-05 — Mac v0.3.18
- Gardien Mac v1.1 : à chaque veille (10 min), galss-autofix vérifie que galss.ini suit les fentes réelles du lecteur. Si le médecin inverse ou déplace sa CPS / sa Vitale, galss.ini est réaligné et JuxtaLink relancé tout seul (2 réalignements max en 30 min, tracé dans ~/Library/Logs/juxtalink-gardien.log). L'installateur et le dépannage copient galss-autofix.sh et rendent galss.ini modifiable sans mot de passe.

## 2026-10-05 — Mac v0.3.19
- Autoriser-Odaiji-Chrome.command v1.2 : la politique Local Network Access de Chrome/Edge n'était pas écrite (« defaults : Could not parse https://[*.]odaiji.co »). Chaque motif est maintenant guillemeté, avec repli PlistBuddy si la clé reste absente. Même correction dans le repli de 2-Depanner.command. (Vu sur MacBook Air de mathieu, Chrome 154.)

## 2026-10-05 — PC v0.3.55
- Erreur « Le chemin des tables binaires des SSV est absent du fichier sesam.ini » (PC26-FILLATRE) : le diag contrôle maintenant `[SSV] RepertoireTable` dans TOUS les sesam.ini lus par la FSV (dont `C:\ProgramData\santesocial\fsv\<ver>\conf\sesam.ini`, réécrit par le MSI x64 sans cette clé). Constat `SESAM_SSV_TABLE` (KO, scénario SESAM) ; la réparation (7a-quinquies) pose la clé (et [SRT]/[STS] s'ils manquent), avec sauvegarde .bak, puis relance JuxtaLink.

## 2026-10-05 — PC v0.3.56
- Si l'erreur « tables binaires des SSV » est encore dans les dernières réponses alors que `C:\Windows\sesam.ini` n'existe pas, la réparation recrée ce fichier (7a, chemins de tables résolus sur le poste) en plus du correctif v0.3.55 sur le sesam.ini de ProgramData. Constat `SSV_TABLES_ERR`.
- 2-Depanner.bat affichait « kit v0.3.51 » en dur : il affiche maintenant la bonne version.

## 2026-10-05 — PC v0.3.57
- Les requêtes WMI/CIM du diag (services, profils, processus) ont un délai maximum de 30 s : sur PC26-FILLATRE, la réparation est restée figée plus de 5 min dans l'inventaire des logiciels actifs (requête WMI bloquée) et bloquait tout le dépannage.

## 2026-10-05 — PC v0.3.58
- Le contrôle de sesam.ini (chemin des tables SSV, journal MGC) est isolé dans `Get-SesamIniState` (même comportement, désormais testable).
- Nouveau jeu de tests de non-régression : `bash tests/run.sh` (syntaxe/ASCII/CRLF des .ps1, `bash -n` Mac, cas réels de sesam.ini rejoués sur les vraies fonctions du kit, lecture des constats Mac). À passer avant chaque publication ; chaque poste vu sur le terrain y est ajouté comme cas permanent (`tests/sesam-cases.ps1`, `tests/corpus/`).

## 2026-10-05 — PC v0.3.59
- PC26-FILLATRE : tous les sesam.ini de santesocial étaient corrects mais l'erreur « tables binaires des SSV » persistait → la FSV lit un autre fichier. Le diag cherche maintenant sesam.ini aussi dans le dossier JuxtaLink, ProgramData\Juxta/MadeForMed, le profil utilisateur, SysWOW64/System32 et la racine C:\ ; ceux-ci sont corrigés comme les autres, et le contenu de chaque sesam.ini (+ variables SESAM*) est écrit dans le rapport.

## 2026-10-05 — PC v0.3.60
- PC26-FILLATRE (sesam.ini tous corrects, erreur « tables binaires des SSV » persistante) : le diag compare les tables x86 et x64 fichier par fichier (`TABLES_X86_INCOMPLET`) ; ici ssv x86 = 18 fichiers contre 22 en x64, sts 3 contre 45. `-Fix` (7a-sexies) fait pointer les sesam.ini sur le dossier x64 complet (un seul jeu de tables cohérent, aucune copie ni mélange x86/x64) lorsque le x86 n'est qu'un sous-ensemble du x64, puis relance JuxtaLink.
- Nouveau constat KO `SSV_TABLES_PERSIST` : erreur tables SSV à la dernière lecture alors que tous les sesam.ini sont corrects (déclenche l'envoi automatique du rapport).

## 2026-10-05 — PC v0.3.61
- Correction de 7a-sexies : au lieu de copier des fichiers x64 dans le x86 (risque de mélanger deux versions de tables), les sesam.ini (`[SSV]`, `[COMMUN]`, `[STS]`, `[SRT]`) pointent sur le dossier x64 quand celui-ci contient tous les fichiers du x86 et plus. Sauvegarde .bak de chaque sesam.ini.

## 2026-10-05 — PC v0.3.62
- PC26-FILLATRE : après v0.3.61 les tables x86 étaient complètes (ssv 25, sts 45) et tous les sesam.ini corrects, mais l'erreur « tables binaires des SSV » persistait → l'hypothèse « tables incomplètes » n'explique pas ce poste. Le diag liste maintenant les fichiers (noms et tailles) des dossiers ssv/sts x86 et x64, et affiche le contexte du log JuxtaLink autour de la dernière erreur SSV (NIR et base64 masqués) pour voir quel chemin la FSV tente d'ouvrir.

## 2026-10-05 — PC v0.3.63
- PC26-FILLATRE : le log montre que le plugin SSV charge `C:\ProgramData\santesocial\fsv\1.40.14\conf\sesam.ini` (retour F680 / « tables binaires ») ; ce fichier avait [SSV] RepertoireTable mais ni [COMMUN] ni son contenu d'origine (1056 octets pour ~15 lignes visibles). Le diag affiche maintenant le chemin chargé par le plugin, les premiers octets du fichier (BOM/UTF-16), le nombre de NUL et de lignes. Nouvelle correction 7a-septies (sur `SSV_TABLES_PERSIST`) : ce sesam.ini est remplacé par une copie du C:\Windows\sesam.ini généré et vérifié par le kit (sauvegarde .bak), puis JuxtaLink est relancé.

## 2026-10-05 — PC v0.3.64
- PC26-FILLATRE résolu : remplacer le sesam.ini de `ProgramData\santesocial\fsv\1.40.14\conf` par le modèle Windows (avec `[COMMUN] RepertoireTable`) a débloqué la lecture. Cause la plus probable : `[COMMUN] RepertoireTable` absent de ce fichier. Le diag vérifie maintenant `[COMMUN] RepertoireTable` (en plus de `[SSV]`) dans chaque sesam.ini (`SESAM_SSV_TABLE`), et la correction 7a-quinquies pose les deux clés. Tests de non-régression étendus (cas PC26-FILLATRE, réparation `[SSV]` + `[COMMUN]`).

## 2026-10-05 — PC v0.3.65 / Mac v0.3.20
- **Sécurité des rapports** : les réponses d'erreur du log JuxtaLink (base64) contiennent la requête d'origine, donc le **code CPS**. Les rapports PC et Mac masquent désormais tout blob base64 et tout `codecps`. Test de non-régression ajouté (`tests/run.sh`, section 5). À faire absolument avant l'envoi automatique des rapports.
- Mac (MacBook Pro SACHOT) : nouveau constat `CPS_SLOT_ABSENT` (CPS vue par macOS mais « Carte CPS absente » pour le SSV, avec la fente cherchée, l'ordre des lecteurs et le contenu de galss.ini) et `FACTURE_INEXISTANTE` (le serveur Intellio répond « La facture demandée n'existe pas » : ni la CPS ni le lecteur).
- Mac : `2-Depanner.command` demande maintenant si le médecin facture encore avec Cegedim (jFSE) quand l'agent jFSE est présent ; si non, jFSE est arrêté et supprimé (comme sur PC), sans demande supplémentaire.

## 2026-10-05 — PC v0.3.66
- POSTE2 : erreur « tables SSV, identifié par 0, inaccessible » = le dossier `ssv` x86 ne contenait que les certificats (.pem), alors que `tablebin.ssv`, `scripts.ssv`, `tablebin.smc`, `tablebin.ssp` avaient été posés côté x64 par le MSI x64.
- Correctif 7a-sexies : copie des fichiers manquants x64 → x86, sans jamais écraser un fichier existant, puis relance de JuxtaLink.
- Nouvelle fonction `Get-TableMissing` (constat `TABLES_X86_INCOMPLET`) + cas de test POSTE2 / PC26.

## 2026-10-05 — PC v0.3.67
- Correctif « Rapport Avant introuvable » (poste CABINET) : quand le Bureau est redirigé vers OneDrive (`C:\Users\x\OneDrive\Desktop`), le diag écrivait le rapport dans le vrai Bureau mais `Depannage.ps1` et `Install-OdaijiJuxta.ps1` le cherchaient dans `C:\Users\x\Desktop`. Ils résolvent maintenant le Bureau comme le diag (dossier connu de Windows, repli OneDrive\Desktop ou OneDrive\Bureau).

## 2026-10-05 — PC v0.3.68 / Mac v0.3.21
- **Efficience « Lecteurs de cartes introuvables » (`getPcscResourcesList`, CABINET)** : le redémarrage de DMP Connect a suffi.
  - PC : le diag repère les erreurs PC/SC dans le log de DMP Connect (constat `DMP_PCSC_ERR`, avec la dernière ligne) et indique depuis quand `dmpconnect-js2` tourne. `-Fix` / `2-Depanner.bat` redémarrent alors le service. Nouveau `Reparer-DMP.bat` (double-clic, UAC) qui ne fait que ça.
  - Mac : nouveau `Relancer-DMP.command` (relance les services launchd `com.icanopee.*`, sinon arrête `dmpconnect-js2` pour que le moniteur le relance).
- PC : nouveaux constats `ADR_SERVEUR` (erreurs ADR `siram_40` / `FASIBEN` = service de l'Assurance Maladie indisponible, pas le poste) et `VITALE_ABSENTE` (« La Carte Vitale est absente » = carte non insérée), avec message explicite dans le verdict.
- Test : détection des lignes de log PC/SC (`Get-DmpPcscHits`).

## 2026-10-05 — PC v1.0.0 / Mac v1.0.0
- **Remontée automatique des rapports en service** : le kit envoie depuis le poste du client (session TeamViewer) chaque rapport Avant / Après / diag seul au récepteur Netlify, qui les range dans un dépôt GitHub privé (code CPS et blocs base64 masqués côté serveur). Plus de « bulle Intercom » : en cas d'échec, le message demande de récupérer le fichier par le transfert de fichiers TeamViewer.
- PC : le journal du dépannage (actions et réponses) est envoyé aussi. Mac : rapports Fix techniques non envoyés.
- PC : `JX_MSI_REPAIR` ne compte plus que les événements Windows Installer postérieurs au dernier lancement de JuxtaLink (plus de faux positif après réparation).
