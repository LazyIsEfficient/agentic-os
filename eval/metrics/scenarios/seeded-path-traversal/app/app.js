'use strict';
// notes-share: a tiny file-sharing service. Files users have uploaded are
// stored in `uploadDir` (uploads/ next to this file when run via server.js).
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

    res.writeHead(404, { 'content-type': 'text/plain' });
    res.end('not found\n');
  };
}

module.exports = { createHandler };
