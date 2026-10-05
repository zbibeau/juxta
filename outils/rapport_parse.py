#!/usr/bin/env python3
"""Lecture d'un rapport du kit Odaiji_Juxta (PC ou Mac) -> dict. Partage par parc.py (tableau de bord du parc),
la synthese des rapports et les tests. Tolerant : un rapport ancien (sans bloc 'Constats') donne scenario=None."""
import re, sys, json

RE_HEAD = re.compile(r'OdaijiJuxta(-Mac)? v(\d+\.\d+\.\d+)\s+-\s+(\d\d/\d\d/\d{4}) (\d\d:\d\d)')
RE_CONST = re.compile(r'^\s{4,}([A-Z][A-Za-z0-9_]+)\s+(KO|WARN|INFO|OK)\s+(.*\S)?\s*$')
RE_POSTE = re.compile(r'^\s+(?:Poste|Mac)\s*:\s*(\S+)')
RE_POSTE_ID = re.compile(r'(?:Poste ID|poste_id)\s*:\s*([0-9a-fA-F-]{8,40})')
RE_CABINET = re.compile(r'^cabinet : (.+)$', re.M)
RE_SCEN = re.compile(r'^Scenario\s*:\s*(\S+)')


def prefix_of(nom):
    m = re.match(r'(Avant|Apres|Fix2|Fix|Galss|Nettoyage|Depannage|Installation|Sentinelle|OdaijiJuxta-Mac|OdaijiJuxta)_', nom or '')
    return m.group(1) if m else ''


def parse(text, nom=''):
    d = {'nom': nom, 'prefix': prefix_of(nom), 'kit': None, 'version': None, 'date': None, 'heure': None,
         'poste': None, 'poste_id': None, 'cabinet': None, 'type': 'inconnu', 'scenario': None, 'constats': []}
    lines = text.replace('\r', '').split('\n')
    for ln in lines[:15]:
        m = RE_HEAD.search(ln)
        if m:
            d['kit'] = 'mac' if m.group(1) else 'pc'; d['version'] = m.group(2); d['date'] = m.group(3); d['heure'] = m.group(4); d['type'] = 'diag'
        m = RE_POSTE.match(ln)
        if m and not d['poste']: d['poste'] = m.group(1)
    if d['type'] == 'inconnu' and ('transcription Windows PowerShell' in text[:400] or d['prefix'] in ('Depannage', 'Installation')):
        d['type'] = 'journal'
    m = RE_POSTE_ID.search(text[:2000])
    if m: d['poste_id'] = m.group(1).lower()
    m = RE_CABINET.search(text[:600])
    if m: d['cabinet'] = m.group(1).strip()
    in_c = False
    for ln in lines:
        m = RE_SCEN.match(ln)
        if m: d['scenario'] = m.group(1); continue
        if ln.startswith('Constats'): in_c = True; continue
        if in_c:
            m = RE_CONST.match(ln)
            if m: d['constats'].append({'code': m.group(1), 'niveau': m.group(2), 'msg': m.group(3) or ''})
            elif ln.strip() == '' or ln.startswith('===='): in_c = False
    return d


def codes(d, niveaux=('KO', 'WARN')):
    return sorted({c['code'] for c in d['constats'] if c['niveau'] in niveaux})


if __name__ == '__main__':
    out = []
    for p in sys.argv[1:]:
        out.append(parse(open(p, encoding='utf-8', errors='replace').read(), p.split('/')[-1]))
    json.dump(out if len(out) != 1 else out[0], sys.stdout, ensure_ascii=False, indent=1)
