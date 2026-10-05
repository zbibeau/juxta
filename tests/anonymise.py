#!/usr/bin/env python3
"""Anonymise des rapports reels du kit pour le depot PUBLIC (tests/corpus/real).
Usage : python3 tests/anonymise.py <dossier_brut> <dossier_sortie>
Remplace : noms de postes -> POSTE-NN / MAC-NN ; comptes utilisateurs -> utilisateur-NN ; noms propres derives ;
numeros de serie / identifiants longs ; FINESS, numero PS (RPPS), NIR ; adresses IP privees ; emails.
Un controle final refuse d'ecrire si un jeton d'origine reste present. Les rapports bruts ne sont JAMAIS commites."""
import re, sys, os, glob

GENERIC_USERS = {'admin', 'administrateur', 'administrator', 'utilisateur', 'poste', 'public', 'default', 'all users', 'dr', 'user', 'root', 'system', 'default user', 'defaultuser0'}
GENERIC_HOST_WORDS = {'MSI', 'CABINET', 'SERVEUR', 'POSTE1', 'POSTE2', 'CMIC', 'MacBook_Pro', 'MacBook_Air'}  # trop courants : remplaces seulement en contexte
KEY_RE = re.compile(r'(?i)((?:numNatPs|numeroNatPs|finess|nir|numSecu[a-z]*|numeroSecu[a-z]*|dateNaissance|nomPatient|prenomPatient|rpps|adeli)[^A-Za-z0-9]{1,6})[A-Za-z0-9]{3,}')


def host_of(name):
    m = re.match(r'(?:Avant|Apres|Fix2|Fix|Galss|Nettoyage|Depannage|Installation|Sentinelle|OdaijiJuxta-Mac|OdaijiJuxta)_(.+)_\d{8}-\d{4}\.txt$', name)
    return m.group(1) if m else None


def build_maps(files):
    hosts, users = set(), set()
    for f in files:
        t = open(f, encoding='utf-8', errors='replace').read()
        h = host_of(os.path.basename(f))
        if h: hosts.add(h)
        for m in re.finditer(r'^\s+(?:Poste|Mac)\s*:\s*(\S+)', t, re.M): hosts.add(m.group(1))
        for m in re.finditer(r'Utilisateur\s*:\s*(\S+)', t): users.add(m.group(1))
        for m in re.finditer(r'Users[\\/]([^\\/\r\n"\'<>|]+)', t): users.add(m.group(1).strip())
        for m in re.finditer(r"utilisateur : [A-Za-z0-9_.-]+\\([A-Za-z0-9_. -]+)", t, re.I): users.add(m.group(1).strip())
    users = {u for u in users if u.lower() not in GENERIC_USERS and len(u) >= 3}
    return sorted(hosts), sorted(users)


def labels(hosts, users):
    hl, mi, pi = {}, 0, 0
    for h in hosts:
        if re.search(r'mac|imac', h, re.I) and ('_' in h or 'Mac' in h):
            mi += 1; hl[h] = 'MAC-%02d' % mi
        else:
            pi += 1; hl[h] = 'POSTE-%02d' % pi
    ul = {u: 'utilisateur-%02d' % (i + 1) for i, u in enumerate(users)}
    return hl, ul


def name_tokens(hosts, users):
    """Noms propres reperables dans les noms de postes / comptes : sous-chaines a retirer partout."""
    toks = set()
    for h in hosts:
        for part in re.split(r'[_\- .]+', h):
            if len(part) >= 4 and not re.match(r'(?i)^(macbook|mini|desktop|laptop|air|pro|poste|serveur|cabinet|dell|msi|imac|windows|pc\d*)$', part) and not re.match(r'^[A-Z0-9]{7,9}$', part) and part.lower() not in ('de', 'du'):
                toks.add(part)
    for u in users:
        for part in re.split(r'[._\- ]+', u):
            if len(part) >= 4: toks.add(part)
        if len(u) >= 4: toks.add(u)
    for h in hosts:  # noms accoles : DRLECLERE, PC26-FILLATRE...
        m = re.match(r'(?i)^(?:dr|pc\d*|hp|nb)[-_]?([A-Za-z]{5,})$', h)
        if m: toks.add(m.group(1))
    toks -= {t for t in toks if t.lower() in GENERIC_USERS or t.lower() in ('macbook', 'desktop', 'poste', 'poste1', 'poste2', 'serveur', 'cabinet')}
    return sorted(toks, key=len, reverse=True)


def anonymise(t, hl, ul, toks, host_here):
    # 1. hotes et comptes : chaines completes (variantes espaces / tirets / .local)
    for h in sorted(hl, key=len, reverse=True):
        lab = hl[h]
        variants = {h, h.replace('_', ' '), h.replace('_', '-')}
        for v in variants:
            if h in GENERIC_HOST_WORDS:
                # contextes surs seulement
                t = re.sub(r'((?:Poste|Mac)\s*:\s*)' + re.escape(v) + r'(?![A-Za-z0-9])', r'\g<1>' + lab, t)
                t = re.sub(r'(_)' + re.escape(v) + r'(_\d{8}-\d{4})', r'\g<1>' + lab + r'\g<2>', t)
                t = re.sub(r'(?i)(?<![A-Za-z0-9_])' + re.escape(v) + r'(?=\\[A-Za-z0-9_. -]+)', lab, t) if len(v) > 3 else t  # HOTE\compte
                if host_here == h: t = re.sub(r'(?<![A-Za-z0-9_-])' + re.escape(v) + r'(?![A-Za-z0-9_-])(?=[\\ ]|$)', lab, t)
            else:
                t = re.sub(r'(?i)(?<![A-Za-z0-9])' + re.escape(v) + r'(?![A-Za-z0-9])', lab, t)
    for u in sorted(ul, key=len, reverse=True):
        t = re.sub(r'(?i)(?<![A-Za-z0-9])' + re.escape(u) + r'(?![A-Za-z0-9])', ul[u], t)
    # 2. noms propres residuels
    for tok in toks:
        if len(tok) >= 7 and '~' not in tok: t = re.sub(r'(?i)' + re.escape(tok), '[nom]', t)
        else: t = re.sub(r'(?i)(?<![A-Za-z0-9])' + re.escape(tok) + r'(?![A-Za-z0-9])', '[nom]', t)
    # 3. identifiants
    t = KEY_RE.sub(r'\1[masque]', t)
    t = re.sub(r'(?<![0-9])(?!20\d{6}(?:\d{4,6})?(?![0-9]))\d{8,}(?![0-9])', '[n]', t)
    t = re.sub(r'\b(192\.168|10\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01]))\.\d{1,3}(\.\d{1,3})?\b', 'x.x.x.x', t)
    t = re.sub(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[email]', t)
    t = re.sub(r'S-1-5-21-[0-9-]+', 'S-1-5-21-[sid]', t)
    return t


def main(src, dst):
    files = [f for f in sorted(glob.glob(os.path.join(src, '*.txt'))) if os.path.getsize(f) > 200]
    hosts, users = build_maps(files)
    hl, ul = labels(hosts, users); toks = name_tokens(hosts, users)
    os.makedirs(dst, exist_ok=True)
    seen_content, n = set(), 0
    for f in files:
        base = os.path.basename(f); h = host_of(base)
        raw = open(f, encoding='utf-8', errors='replace').read()
        out = anonymise(raw, hl, ul, toks, h)
        nn = base
        if h and h in hl: nn = base.replace('_' + h + '_', '_' + hl[h] + '_')
        key = (nn, out)
        if out in seen_content: continue          # doublons stricts ignores
        seen_content.add(out)
        open(os.path.join(dst, nn), 'w', encoding='utf-8').write(out); n += 1
    # controle final : aucun jeton d'origine
    leaks = []
    bad = [u for u in users] + [t for t in toks] + [h for h in hosts if h not in GENERIC_HOST_WORDS]
    for g in glob.glob(os.path.join(dst, '*.txt')):
        t = open(g, encoding='utf-8').read()
        for b in bad:
            pat = re.escape(b) if len(b) >= 7 else r'(?<![A-Za-z0-9])' + re.escape(b) + r'(?![A-Za-z0-9])'
            if re.search('(?i)' + pat, t): leaks.append((os.path.basename(g), b))
    if leaks:
        print('FUITES :', leaks[:20]); sys.exit(2)
    print('%d rapports anonymises (%d postes, %d comptes, %d noms propres)' % (n, len(hosts), len(users), len(toks)))
    return hl, ul


if __name__ == '__main__':
    if len(sys.argv) != 3: sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
