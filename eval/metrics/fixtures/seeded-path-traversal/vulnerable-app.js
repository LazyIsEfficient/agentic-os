'use strict';
// Fixture: the NAIVE implementation of GET /files/<name> (path traversal).
// Used by the stub claude in run-release-arms-test.sh; exploit-check must fail it.
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
      const name = decodeURIComponent(url.pathname.slice('/files/'.length));
      fs.readFile(path.join(root, name), (err, data) => {
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
