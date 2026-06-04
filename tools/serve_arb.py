#!/usr/bin/env python3
"""
ARB translation editor server.
Run from the project root:  python tools/serve_arb.py
Opens the editor in your browser and lets you save edits straight to disk.
"""

import http.server
import json
import os
import subprocess
import sys
import threading
import urllib.parse
import webbrowser
from pathlib import Path

PORT = 8088
ROOT = Path(__file__).resolve().parent.parent   # project root

SAVE_TARGETS = {
    '/save/en':   'lib/core/l10n/app_en.arb',
    '/save/he':   'lib/core/l10n/app_he.arb',
    '/save/heMA': 'lib/core/l10n/app_he_MA.arb',
}


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    # ── POST ──────────────────────────────────────────────────────────────
    def do_POST(self):
        path = urllib.parse.urlparse(self.path).path
        if path in SAVE_TARGETS:
            self._save(SAVE_TARGETS[path])
        elif path == '/generate':
            self._generate()
        else:
            self._json(404, {'error': 'not found'})

    def _save(self, rel_path):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length)
        try:
            json.loads(body)                         # validate before writing
            target = ROOT / rel_path
            target.write_bytes(body)
            print(f'  saved  {rel_path}')
            self._json(200, {'ok': True})
        except Exception as exc:
            self._json(400, {'error': str(exc)})

    def _generate(self):
        try:
            result = subprocess.run(
                ['flutter', 'gen-l10n'],
                cwd=str(ROOT),
                capture_output=True,
                text=True,
                timeout=40,
            )
            if result.returncode == 0:
                print('  generated localizations')
                self._json(200, {'ok': True})
            else:
                msg = (result.stderr or result.stdout or 'unknown error').strip()
                self._json(200, {'ok': False, 'error': msg})
        except FileNotFoundError:
            self._json(200, {'ok': False, 'error': 'flutter not found in PATH'})
        except subprocess.TimeoutExpired:
            self._json(200, {'ok': False, 'error': 'flutter gen-l10n timed out'})
        except Exception as exc:
            self._json(200, {'ok': False, 'error': str(exc)})

    def _json(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', len(body))
        self.end_headers()
        self.wfile.write(body)

    # ── Logging: suppress noisy GET lines ─────────────────────────────────
    def log_message(self, fmt, *args):
        line = fmt % args
        if line.startswith('"GET') or line.startswith('"HEAD'):
            return
        super().log_message(fmt, *args)


url = f'http://localhost:{PORT}/tools/arb_editor.html'
threading.Timer(0.5, lambda: webbrowser.open(url)).start()
print(f'ARB Editor  →  {url}')
print('Press Ctrl+C to stop.\n')

try:
    with http.server.ThreadingHTTPServer(('', PORT), Handler) as srv:
        srv.serve_forever()
except KeyboardInterrupt:
    print('\nStopped.')
    sys.exit(0)
