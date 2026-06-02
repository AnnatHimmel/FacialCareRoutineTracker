#!/usr/bin/env node
// ARB translation editor — local dev server.
// Run from project root:  node tools/server.js
// Opens the editor in your browser and lets you save edits straight to disk.

const http  = require('http');
const fs    = require('fs');
const path  = require('path');
const cp    = require('child_process');
const url   = require('url');

const PORT = 8088;
const ROOT = path.resolve(__dirname, '..');   // project root

const SAVE_TARGETS = {
  '/save/he':   'lib/core/l10n/app_he.arb',
  '/save/heMA': 'lib/core/l10n/app_he_MA.arb',
};

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.arb':  'application/json; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.js':   'text/javascript',
  '.css':  'text/css',
};

// ── Request handler ──────────────────────────────────────────────────────────

const server = http.createServer((req, res) => {
  const { pathname } = url.parse(req.url);

  // ── POST endpoints ──
  if (req.method === 'POST') {
    if (SAVE_TARGETS[pathname]) return handleSave(req, res, SAVE_TARGETS[pathname]);
    if (pathname === '/generate') return handleGenerate(req, res);
    return sendJson(res, 404, { error: 'not found' });
  }

  // ── Static file serving ──
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return sendJson(res, 405, { error: 'method not allowed' });
  }

  const filePath = path.join(ROOT, pathname === '/' ? '/tools/arb_editor.html' : pathname);
  const ext      = path.extname(filePath).toLowerCase();

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    res.end(data);
  });
});

// ── Handlers ────────────────────────────────────────────────────────────────

function handleSave(req, res, relPath) {
  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    try {
      JSON.parse(body);                          // validate before writing
      const target = path.join(ROOT, relPath);
      fs.writeFile(target, body, 'utf8', err => {
        if (err) return sendJson(res, 500, { error: err.message });
        console.log('  saved ', relPath);
        sendJson(res, 200, { ok: true });
      });
    } catch (e) {
      sendJson(res, 400, { error: e.message });
    }
  });
}

function handleGenerate(req, res) {
  req.resume();   // drain body
  const flutter = process.platform === 'win32' ? 'flutter.bat' : 'flutter';
  const proc = cp.spawn(flutter, ['gen-l10n'], { cwd: ROOT });
  let out = '';
  proc.stdout.on('data', d => out += d);
  proc.stderr.on('data', d => out += d);
  proc.on('error', err => sendJson(res, 200, { ok: false, error: err.message }));
  proc.on('close', code => {
    if (code === 0) {
      console.log('  generated localizations');
      sendJson(res, 200, { ok: true });
    } else {
      sendJson(res, 200, { ok: false, error: out.trim() || `exit code ${code}` });
    }
  });
}

function sendJson(res, status, data) {
  const body = JSON.stringify(data);
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(body);
}

// ── Start ────────────────────────────────────────────────────────────────────

server.listen(PORT, '127.0.0.1', () => {
  const editorUrl = `http://localhost:${PORT}/tools/arb_editor.html`;
  console.log(`ARB Editor  →  ${editorUrl}`);
  console.log('Press Ctrl+C to stop.\n');

  // Open browser after a short delay
  const open =
    process.platform === 'win32'  ? ['cmd', ['/c', 'start', editorUrl]] :
    process.platform === 'darwin' ? ['open',  [editorUrl]] :
                                    ['xdg-open', [editorUrl]];
  cp.spawn(open[0], open[1], { detached: true, stdio: 'ignore' }).unref();
});
