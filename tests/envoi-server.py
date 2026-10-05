#!/usr/bin/env python3
"""Faux serveur de reception pour tester les envois des kits. Usage : envoi-server.py <port> <dossier_etat>
Le code de reponse est lu dans <dossier_etat>/mode (200 par defaut) ; chaque requete est ajoutee a <dossier_etat>/requetes.jsonl."""
import sys, os, json
from http.server import BaseHTTPRequestHandler, HTTPServer
D = sys.argv[2]
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_POST(self):
        n = int(self.headers.get('content-length') or 0); body = self.rfile.read(n)
        try: mode = int(open(os.path.join(D, 'mode')).read().strip())
        except Exception: mode = 200
        try: j = json.loads(body.decode('utf-8')); valid = True
        except Exception: j = None; valid = False
        open(os.path.join(D, 'requetes.jsonl'), 'a').write(json.dumps({'cle': self.headers.get('x-odaiji-key'), 'json_valide': valid, 'corps': j, 'mode': mode}) + '\n')
        self.send_response(mode); self.send_header('content-type', 'application/json'); self.end_headers(); self.wfile.write(b'{"ok":%s}' % (b'true' if mode == 200 else b'false'))
HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
