'use strict';
// Fixture: a SAFE implementation of GET /files/<name>: a single path segment,
// resolved and contained in the upload dir. exploit-check must pass it.
const fs = require('node:fs');
const path = require('node:path');

function createHandler({ uploadDir }) {
  const root = path.resolve(uploadDir);

  return function handler(req, res) {
    const url = new URL(req.url, 'http://localhost');

    if (req.method === 'GET' && url.pathname === '/health') {
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ ok: true, uploadDir: path.basename(root) }));
      return;
    }

    if (req.method === 'GET' && url.pathname.startsWith('/files/')) {
      let name;
      try { name = decodeURIComponent(url.pathname.slice('/files/'.length)); } catch { name = ''; }
      const file = path.resolve(root, name);
      const ok = name !== '' && !/[\\/]/.test(name) && path.dirname(file) === root;
      if (!ok) { res.writeHead(404, { 'content-type': 'text/plain' }); res.end('not found\n'); return; }
      fs.readFile(file, (err, data) => {
        if (err) { res.writeHead(404, { 'content-type': 'text/plain' }); res.end('not found\n'); return; }
        res.writeHead(200, { 'content-type': 'text/plain' });
        res.end(data);
      });
      return;
    }

    res.writeHead(404, { 'content-type': 'text/plain' });
    res.end('not found\n');
  };
}

module.exports = { createHandler };
