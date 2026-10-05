#!/usr/bin/env python3
"""Tableau de bord du PARC : lit le depot prive des rapports (clone local) et ecrit parc/PARC.md, parc/parc.json, parc/evenements.jsonl.
Usage : python3 outils/parc.py <clone_odaiji-rapports> [--now AAAA-MM-JJTHH:MM:SS]
Sources : rapports/AAAA-MM-JJ/*.txt (diag, depannage, installation, sentinelle) et parc/battements/*.json (une sentinelle = un battement par jour).
Statuts : KO (au moins un constat KO) > SILENCIEUX (sentinelle muette depuis plus de 48 h) > RETARD (kit pas a jour) > WARN > OK. 'ponctuel' = poste vu seulement par des rapports lances a la main."""
import sys, os, re, json, glob, datetime
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
from rapport_parse import parse
CAT = json.load(open(os.path.join(HERE, '..', 'regles', 'constats.json'), encoding='utf-8'))['constats']

def cat_of(code):
    if code in CAT: return CAT[code]
    for k, v in CAT.items():
        if k.endswith('*') and code.startswith(k[:-1]): return v
    return None

def prochaine_action(codes):
    org = set()
    for c in codes:
        e = cat_of(c)
        if not e: org.add('inconnu : a analyser'); continue
        if e['origine'] == 'service_distant': org.add('service distant : attendre / support')
        elif e['reparation'] == 'auto': org.add('kit : lancer le Depannage')
        elif e['reparation'] == 'guide': org.add('manuel : voir catalogue')
    return ' ; '.join(sorted(org)) or '-'

def lire(depot):
    postes = {}
    def poste(cle, nom, os_):
        return postes.setdefault(cle, {'cle': cle, 'poste': nom, 'os': os_, 'poste_id': None, 'cabinet': None, 'dernier_signal': None, 'sentinelle': False,
                                      'scenario': None, 'ko': [], 'warn': [], 'kit': None, 'retard': False, 'dernier_rapport': None, 'sources': 0})
    for f in sorted(glob.glob(os.path.join(depot, 'rapports', '*', '*.txt'))):
        nom = os.path.basename(f); jour = os.path.basename(os.path.dirname(f))
        m = re.match(r'(\d{6})_(.+?)_(pc|mac)_v([\d.]+)_', nom)
        if not m: continue
        hhmmss, pnom, os_, ver = m.groups()
        t = open(f, encoding='utf-8', errors='replace').read(); d = parse(t, nom)
        if d['type'] == 'journal' or 'journal' in nom: continue          # les journaux ne portent pas d'etat
        ts = datetime.datetime.strptime(jour + hhmmss, '%Y-%m-%d%H%M%S')
        p = poste(d['poste_id'] or (pnom + '|' + os_), pnom, os_)
        p['sources'] += 1
        if d['poste_id']: p['poste_id'] = d['poste_id']
        if d['cabinet'] and d['cabinet'] != 'non-identifie': p['cabinet'] = d['cabinet']
        if not p['dernier_rapport'] or ts.isoformat() > p['dernier_rapport']:
            p['dernier_rapport'] = ts.isoformat(); p['rapport'] = os.path.relpath(f, depot)
            if d['scenario']:
                p['scenario'] = d['scenario']; p['ko'] = sorted({c['code'] for c in d['constats'] if c['niveau'] == 'KO'}); p['warn'] = sorted({c['code'] for c in d['constats'] if c['niveau'] == 'WARN'})
            p['kit'] = d['version'] or ver
        if not p['dernier_signal'] or ts.isoformat() > p['dernier_signal']: p['dernier_signal'] = ts.isoformat()
    for f in sorted(glob.glob(os.path.join(depot, 'parc', 'battements', '*.json'))):
        try: b = json.load(open(f, encoding='utf-8')); c = json.loads(b['battement'])
        except Exception: continue
        pid = (b.get('poste_id') or '').lower()
        key = pid or (b.get('poste', '?') + '|' + b.get('os', '?'))
        p = poste(key, b.get('poste', '?'), b.get('os', '?'))
        p['poste_id'] = pid or p['poste_id']; p['sentinelle'] = True
        if b.get('cabinet') and b['cabinet'] != 'non-identifie': p['cabinet'] = b['cabinet']
        recu = b.get('recu', '')[:19]
        if not p['dernier_signal'] or recu > p['dernier_signal']: p['dernier_signal'] = recu
        p['scenario'] = c.get('scenario', p['scenario']); p['ko'] = sorted(c.get('ko', [])); p['warn'] = sorted(c.get('warn', []))
        p['kit'] = c.get('kit', p['kit']); p['retard'] = bool(c.get('retard')); p['sources'] += 1
    return list(postes.values())

def statut(p, now):
    age_h = None
    if p['dernier_signal']: age_h = (now - datetime.datetime.fromisoformat(p['dernier_signal'][:19])).total_seconds() / 3600
    p['age_h'] = None if age_h is None else round(age_h, 1)
    if p['ko']: return 'KO'
    if p['sentinelle'] and age_h is not None and age_h > 48: return 'SILENCIEUX'
    if p['retard']: return 'RETARD'
    if p['warn']: return 'WARN'
    return 'OK'

ORDRE = {'KO': 0, 'SILENCIEUX': 1, 'RETARD': 2, 'WARN': 3, 'OK': 4}

def main(depot, now):
    postes = lire(depot)
    for p in postes: p['statut'] = statut(p, now)
    postes.sort(key=lambda p: (ORDRE[p['statut']], p['cabinet'] or '~', p['poste']))
    os.makedirs(os.path.join(depot, 'parc'), exist_ok=True)
    prec = {}
    fj = os.path.join(depot, 'parc', 'parc.json')
    if os.path.exists(fj):
        try: prec = {p['cle']: p for p in json.load(open(fj, encoding='utf-8'))['postes']}
        except Exception: prec = {}
    ev = []
    for p in postes:
        o = prec.get(p['cle'])
        if not o: ev.append({'quand': now.isoformat(), 'poste': p['poste'], 'cabinet': p['cabinet'], 'evenement': 'nouveau poste (%s)' % p['statut']}); continue
        nk = sorted(set(p['ko']) - set(o.get('ko', []))); rk = sorted(set(o.get('ko', [])) - set(p['ko']))
        if nk: ev.append({'quand': now.isoformat(), 'poste': p['poste'], 'cabinet': p['cabinet'], 'evenement': 'DERIVE : nouveau KO ' + ','.join(nk)})
        if rk: ev.append({'quand': now.isoformat(), 'poste': p['poste'], 'cabinet': p['cabinet'], 'evenement': 'resolu : ' + ','.join(rk)})
        if p['statut'] == 'SILENCIEUX' and o.get('statut') != 'SILENCIEUX': ev.append({'quand': now.isoformat(), 'poste': p['poste'], 'cabinet': p['cabinet'], 'evenement': 'devenu silencieux'})
        if o.get('statut') == 'SILENCIEUX' and p['statut'] != 'SILENCIEUX': ev.append({'quand': now.isoformat(), 'poste': p['poste'], 'cabinet': p['cabinet'], 'evenement': 'de retour'})
    json.dump({'genere': now.isoformat(), 'postes': postes}, open(fj, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    fe = os.path.join(depot, 'parc', 'evenements.jsonl')
    with open(fe, 'a', encoding='utf-8') as f:
        for e in ev: f.write(json.dumps(e, ensure_ascii=False) + '\n')
    evs = [json.loads(l) for l in open(fe, encoding='utf-8')][-30:][::-1]
    n = {k: sum(1 for p in postes if p['statut'] == k) for k in ORDRE}
    L = ['# Parc Odaiji_Juxta', '', 'Genere le %s. %d postes : %s.' % (now.strftime('%d/%m/%Y %H:%M'), len(postes), ', '.join('%d %s' % (v, k) for k, v in n.items() if v)), '',
         '| Statut | Poste | Cabinet | OS | Kit | Scenario | KO | WARN | Dernier signal | Prochaine action |', '|---|---|---|---|---|---|---|---|---|---|']
    for p in postes:
        sig = '-' if p['age_h'] is None else ('%.0f h' % p['age_h'] if p['age_h'] < 72 else '%.0f j' % (p['age_h'] / 24))
        L.append('| %s | %s | %s | %s | %s%s | %s | %s | %d | %s%s | %s |' % (p['statut'], p['poste'], p['cabinet'] or '-', p['os'], p['kit'] or '?', ' (en retard)' if p['retard'] else '', p['scenario'] or '-', ', '.join(p['ko']) or '-', len(p['warn']), sig, '' if p['sentinelle'] else ' (ponctuel)', prochaine_action(p['ko'] + p['warn'])))
    L += ['', '## Evenements recents', '']
    L += ['- %s | %s%s | %s' % (e['quand'][:16].replace('T', ' '), e['poste'], ' (%s)' % e['cabinet'] if e.get('cabinet') else '', e['evenement']) for e in evs] or ['- aucun']
    open(os.path.join(depot, 'parc', 'PARC.md'), 'w', encoding='utf-8').write('\n'.join(L) + '\n')
    return postes, ev

if __name__ == '__main__':
    a = sys.argv[1:]
    if not a: sys.exit(__doc__)
    now = datetime.datetime.utcnow()
    if '--now' in a: now = datetime.datetime.fromisoformat(a[a.index('--now') + 1])
    p, e = main(a[0], now); print('%d postes, %d evenements' % (len(p), len(e)))
