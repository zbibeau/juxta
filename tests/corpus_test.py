#!/usr/bin/env python3
"""Tests du corpus de rapports reels (anonymises) et du catalogue des constats.
 1. le parseur donne exactement les valeurs attendues (tests/corpus/expected.json) : garde-fou du parseur
 2. tous les codes vus dans le corpus sont dans regles/constats.json
 3. tous les codes que le code des kits peut emettre sont dans regles/constats.json
 4. aucun rapport du corpus ne contient de jeton sensible connu (FINESS / numero PS / NIR / IP privee / email)"""
import sys, os, re, json, glob
R = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(R)
sys.path.insert(0, os.path.join(ROOT, 'outils'))
from rapport_parse import parse
fail = 0
def ko(m):
    global fail; fail = 1; print('  ECHEC', m)

cat = json.load(open(os.path.join(ROOT, 'regles', 'constats.json'), encoding='utf-8'))['constats']
def known(code):
    return code in cat or any(k.endswith('*') and code.startswith(k[:-1]) for k in cat)

exp = json.load(open(os.path.join(R, 'corpus', 'expected.json'), encoding='utf-8'))
files = sorted(glob.glob(os.path.join(R, 'corpus', 'real', '*.txt')))
print('== 7. Corpus reel : parseur (%d rapports)' % len(files))
seen = set(); bad = 0
for f in files:
    nom = os.path.basename(f); t = open(f, encoding='utf-8').read(); d = parse(t, nom)
    got = {k: d[k] for k in ('kit', 'version', 'type', 'prefix', 'scenario')}; got['constats'] = [[c['code'], c['niveau']] for c in d['constats']]
    if nom not in exp or exp[nom] != got: ko('parse different : ' + nom); bad += 1
    for c in d['constats']: seen.add(c['code'])
    for pat, nm in ((r'\b\d{12,}\b', 'longue suite de chiffres'), (r'\b(192\.168|10\.\d{1,3})\.\d{1,3}\.\d{1,3}\b', 'IP privee'), (r'[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[a-z]{2,}', 'email'), (r"(?i)(numNatPs|finess)\W{1,6}\d{5,}", 'FINESS / numero PS')):
        m = re.search(pat, t)
        if m and not (nm == 'longue suite de chiffres' and re.match(r'20\d{10,12}$', m.group(0))): ko('%s dans %s : %s' % (nm, nom, m.group(0)[:20])); bad += 1
if not bad: print('  ok   parseur et donnees sensibles')
print('== 8. Catalogue des constats')
miss = sorted(c for c in seen if not known(c))
for c in miss: ko('code du corpus absent du catalogue : ' + c)
em = set()
for p in glob.glob(os.path.join(ROOT, 'src', 'pc', '*', '*.ps1')):
    s = open(p, encoding='ascii', errors='replace').read()
    em |= set(re.findall(r'Finding\s+"([A-Z][A-Z0-9_]+)"', s)); em |= {x + '*' for x in re.findall(r'Finding\s+\("([A-Z_]+_)"\s*\+', s)}
for p in glob.glob(os.path.join(ROOT, 'src', 'mac', '*', '*.sh')) + glob.glob(os.path.join(ROOT, 'src', 'mac', '*', '*.command')):
    s = open(p, encoding='utf-8', errors='replace').read()
    em |= set(re.findall(r'\bfinding\s+([A-Z][A-Z0-9_]+)\s+(?:KO|WARN|INFO)', s)); em |= {x + '*' for x in re.findall(r'finding\s+"?([A-Z]+_)\$', s)}
for c in sorted(em):
    if not known(c): ko('code emis par un kit absent du catalogue : ' + c)
if not fail: print('  ok   %d codes du corpus, %d codes emis par les kits' % (len(seen), len(em)))
sys.exit(fail)
