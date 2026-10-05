# Catalogue des anciens logiciels metiers (MadeForMed / Odaiji).
# Un bloc par editeur. Pour chaque editeur detecte, les outils demandent :
#   "Le medecin facture-t-il ENCORE avec <Libelle> ?"   n = lancement coupe, produits MSI desinstalles (hors FSV/Cryptolib/MICA/GALSS), Dossiers en quarantaine
# Ajouter un editeur = ajouter un bloc ici (Dossiers : chemins, jokers * autorises ; Motif : expression reguliere
# qui reconnait ses programmes, services, taches et entrees de demarrage).
@{
    Editeurs = @(
        @{
            Nom      = 'Cegedim'
            Libelle  = 'un logiciel Cegedim (Crossway, MLM, Mediclick, jFSE...)'
            Dossiers = @('C:\CEGEDIM', 'C:\Program Files (x86)\CEGEDIM', 'C:\Program Files\CEGEDIM')
            Motif    = 'cegedim|clmlive|\bclm\b|jfse|crossway|resip|clm\w*synchro|synchro\w*clm|\bavi\b'   # 30/09 : "synchro" seul attrapait des elements Windows
            Bloquants = 'MICA x64 (empeche le MICA x86 de Juxta), processus ClmLive / demon jFSE sur le lecteur'
        },
        @{
            Nom      = 'Affid'
            Libelle  = 'Affid Systemes (fsenxt)'
            Dossiers = @('C:\Program Files (x86)\Affid Syst*', 'C:\Program Files\Affid Syst*')
            Motif    = 'affid|fsenxt'
            # 29/09 : logiciel medical local (dossiers patients possibles, cabinet de groupe) -> reponse n = coupe seulement,
            # ni desinstallation ni quarantaine (le port 1234 est libere quand meme)
            NeutraliserSeulement = $true
            Bloquants = 'fsenxt.exe occupe le port 1234 de JuxtaLink'
        },
        @{
            Nom      = 'Shaman'
            Libelle  = 'Shaman'
            Dossiers = @('C:\Program Files (x86)\Shaman', 'C:\Program Files\Shaman', 'C:\Shaman')
            Motif    = 'shaman|maj400'
            Bloquants = 'sesam.ini pointant sur ses anciens dossiers (C:\Program Files\sesam), galss.ini de lecteur serie'
        },
        @{
            Nom      = 'Weda'
            Libelle  = 'Weda (VitalZen, Weda Connect, Pyxvital)'
            Dossiers = @('C:\Program Files\Weda*', 'C:\Program Files (x86)\Weda*', 'C:\Program Files\Vitalzen*', 'C:\Program Files (x86)\Vitalzen*', 'C:\ProgramData\Weda*', 'C:\ProgramData\Vitalzen*', 'C:\Users\*\AppData\Local\Programs\*Weda*', 'C:\Users\*\AppData\Local\Programs\*Vitalzen*')
            Motif    = 'vitalzen|\bweda|comunica'
            # Terrain 28/09 : Weda Connect se relance a chaque demarrage -> desinstalle (non-MSI, silencieux) ;
            # couper aussi Pyxvital (entree dediee) et les services Windows au nom de Weda
            DesinstallerNonMsi = $true
            Bloquants = 'VitalZen (WEDA SAS, C:\Program Files\VitalZen, port local 10100, demarrage fr.comunica.vitalzen) sur le lecteur'
        },
        @{
            Nom      = 'Pyxvital'
            Libelle  = 'Pyxvital (module SESAM-Vitale utilise par d autres logiciels, ex. Weda)'
            Dossiers = @('C:\pyxvital', 'C:\Program Files\Pyxvital*', 'C:\Program Files (x86)\Pyxvital*')
            Motif    = 'pyxvital'
            Bloquants = 'Pyxvital.exe (port local 10500) accede au lecteur de cartes en parallele de JuxtaLink'
        },
        @{
            Nom      = 'DrSante'
            Libelle  = 'DrSante (Calimaps)'
            # Terrain 29/09 : DrSante 22.10 (C:\ProgramData\Calimaps\Versions\...\DrSante.Api.exe, port local 20003,
            # services DrSante.LauncherService / DrSante.WatcherService). Logiciel medical = dossiers patients possibles :
            # reponse n = services et programmes COUPES seulement (ni desinstallation ni quarantaine). Desinstaller a la main
            # une fois l'historique patients recupere / confirme ailleurs.
            Dossiers = @()
            Motif    = 'drsante|calimaps'
            NeutraliserSeulement = $true
            Bloquants = 'services DrSante (Launcher, Watcher) et DrSante.Api relances en permanence (pas de conflit lecteur constate)'
        },
        @{
            Nom      = 'HelloDoc'
            Libelle  = 'HelloDoc (Imagine Editions)'
            # Terrain 29/09 (Axel) : HelloDoc 5.60 + base PostgreSQL 9.2 locale (C:\Program Files (x86)\psql, service
            # postgresql-9.2) = DOSSIERS PATIENTS : jamais touchee. Reponse n = programmes / demarrages HelloDoc coupes seulement.
            # Dossiers : detection seulement (NeutraliserSeulement = jamais de quarantaine)
            Dossiers = @('C:\Program Files (x86)\Imagine Editions', 'C:\Program Files\Imagine Editions', 'C:\HelloDoc*')
            Motif    = 'hellodoc|imagine ?editions'
            NeutraliserSeulement = $true
            Bloquants = 'module SESAM-Vitale HelloDoc sur le lecteur quand il est ouvert ; a installe 4 Cryptolib (C:\Program Files (x86)\Imagine Editions\Technique)'
        }
    )
}
