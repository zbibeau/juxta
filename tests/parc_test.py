#!/usr/bin/env python3
"""Test du tableau de bord du parc (outils/parc.py) sur un faux depot construit avec des rapports reels anonymises + des battements."""
import sys, os, json, glob, shutil, tempfile, datetime
R = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(R); sys.path.insert(0, os.path.join(ROOT, 'outils'))
import parc
fail = 0
def ok(c, m):
    global fail
    print(('  ok   ' if c else '  ECHEC ') + m); fail |= (not c)
print('== 14. Tableau de bord du parc')
D = tempfile.mkdtemp(); now = datetime.datetime(2026, 10, 6, 12, 0, 0)
def rapport(corpus_nom, jour, hhmmss, poste, pid, cabinet='cabinet-a', os_='pc'):
    t = open(os.path.join(R, 'corpus', 'real', corpus_nom), encoding='utf-8').read()
    p = os.path.join(D, 'rapports', jour); os.makedirs(p, exist_ok=True)
    open(os.path.join(p, '%s_%s_%s_v1.1.0_systematique_abc123.txt' % (hhmmss, poste, os_)), 'w', encoding='utf-8').write('[Kit Odaiji] x\ncabinet : %s\nposte_id : %s\n%s\n%s\n' % (cabinet, pid, '=' * 60, t))
def battement(pid, poste, recu, ko=(), warn=(), retard=False, os_='pc'):
    p = os.path.join(D, 'parc', 'battements'); os.makedirs(p, exist_ok=True)
    c = {'scenario': 'OK' if not ko else 'SESAM', 'ko': list(ko), 'warn': list(warn), 'leger': True, 'kit': '1.1.0', 'dispo': '1.1.1' if retard else '1.1.0', 'retard': retard}
    json.dump({'recu': recu, 'cabinet': 'cabinet-a', 'poste': poste, 'poste_id': pid, 'os': os_, 'version': '1.1.0', 'battement': json.dumps(c)}, open(os.path.join(p, pid + '.json'), 'w'))
avant = sorted(os.path.basename(x) for x in glob.glob(os.path.join(R, 'corpus', 'real', 'Avant_POSTE-*.txt')))
ko_rep = next(n for n in avant if parc.parse(open(os.path.join(R, 'corpus', 'real', n), encoding='utf-8').read(), n)['constats'] and any(c['niveau'] == 'KO' for c in parc.parse(open(os.path.join(R, 'corpus', 'real', n), encoding='utf-8').read(), n)['constats']))
rapport(ko_rep, '2026-10-05', '081500', 'POSTE-A', 'aaaaaaaa-0000-0000-0000-000000000001')                  # poste ponctuel avec KO
battement('bbbbbbbb-0000-0000-0000-000000000002', 'POSTE-B', '2026-10-06T02:00:00.000Z')                      # OK, vu il y a 10 h
battement('cccccccc-0000-0000-0000-000000000003', 'POSTE-C', '2026-10-03T08:00:00.000Z')                      # silencieux (> 48 h)
battement('dddddddd-0000-0000-0000-000000000004', 'POSTE-D', '2026-10-06T03:00:00.000Z', retard=True)         # kit en retard
battement('eeeeeeee-0000-0000-0000-000000000005', 'POSTE-E', '2026-10-06T04:00:00.000Z', warn=['STACK_X64'])  # WARN
postes, ev = parc.main(D, now); P = {p['poste']: p for p in postes}
ok(P['POSTE-A']['statut'] == 'KO' and not P['POSTE-A']['sentinelle'], 'poste ponctuel avec KO : KO')
ok(P['POSTE-B']['statut'] == 'OK', 'poste sain : OK')
ok(P['POSTE-C']['statut'] == 'SILENCIEUX', 'sentinelle muette depuis plus de 48 h : SILENCIEUX')
ok(P['POSTE-D']['statut'] == 'RETARD', 'kit pas a jour : RETARD')
ok(P['POSTE-E']['statut'] == 'WARN', 'WARN')
ok([p['statut'] for p in postes][:2] == ['KO', 'SILENCIEUX'], 'tri : KO puis SILENCIEUX')
md = open(os.path.join(D, 'parc', 'PARC.md'), encoding='utf-8').read()
ok('| KO | POSTE-A |' in md and '5 postes' in md and '(ponctuel)' in md, 'PARC.md : tableau et compte')
ok(all(e['evenement'].startswith('nouveau poste') for e in ev) and len(ev) == 5, 'premier passage : 5 evenements "nouveau poste"')
battement('bbbbbbbb-0000-0000-0000-000000000002', 'POSTE-B', '2026-10-06T11:00:00.000Z', ko=['NO_JUXTA'])            # derive
battement('cccccccc-0000-0000-0000-000000000003', 'POSTE-C', '2026-10-06T11:30:00.000Z')                       # de retour
postes, ev = parc.main(D, now + datetime.timedelta(hours=1)); E = [e['evenement'] for e in ev]
ok(any(e.startswith('DERIVE : nouveau KO NO_JUXTA') for e in E), 'derive detectee : nouveau KO NO_JUXTA')
ok('de retour' in E, 'poste silencieux de retour detecte')
ok(len(open(os.path.join(D, 'parc', 'evenements.jsonl')).read().splitlines()) == 5 + len(ev), 'historique des evenements conserve')
ok(parc.prochaine_action(['NO_JUXTA']) == 'kit : lancer le Depannage' and 'service distant' in parc.prochaine_action(['ADR_SERVEUR']) and 'inconnu' in parc.prochaine_action(['CODE_BIDON']), 'prochaine action tiree du catalogue')
shutil.rmtree(D); sys.exit(fail)
