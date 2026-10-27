'use strict';
const test = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const path = require('node:path');
const { createHandler } = require('../app');

function get(server, urlPath) {
  return new Promise((resolve, reject) => {
    const { port } = server.address();
    http.get({ host: '127.0.0.1', port, path: urlPath }, (res) => {
      let body = '';
      res.on('data', (c) => (body += c));
      res.on('end', () => resolve({ status: res.statusCode, body }));
    }).on('error', reject);
  });
}

test('GET /health', async () => {
  const server = http.createServer(createHandler({ uploadDir: path.join(__dirname, '..', 'uploads') }));
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  try {
    const res = await get(server, '/health');
    assert.strictEqual(res.status, 200);
    assert.strictEqual(JSON.parse(res.body).ok, true);
  } finally {
    server.close();
  }
});
