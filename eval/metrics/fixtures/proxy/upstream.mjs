// Fake Anthropic upstream for api-proxy-test.sh (plain HTTP, never the real
// API). Logs each request it receives (url, accept-encoding, body) to
// <dir>/received.log. Behaviour from env:
//   UP_IN / UP_OUT / UP_CR / UP_CC   usage numbers it reports
//   UP_DELAY                          ms before answering
//   UP_MODE   json | sse | gzip (gzip even if not asked) | garbage | error |
//             stall (headers + first event, the rest after UP_STALL ms)
import http from 'node:http';
import fs from 'node:fs';
import zlib from 'node:zlib';

const dir = process.argv[2];
const port = Number(process.argv[3]);
const n = (k, d) => Number(process.env[k] ?? d);
const IN = n('UP_IN', 100), OUT = n('UP_OUT', 50), CR = n('UP_CR', 0), CC = n('UP_CC', 0), DELAY = n('UP_DELAY', 0);
const MODE = process.env.UP_MODE || 'json';
http.createServer((req, res) => {
  const c = [];
  req.on('data', (d) => c.push(d));
  req.on('end', () => {
    const body = Buffer.concat(c).toString('utf8');
    fs.appendFileSync(`${dir}/received.log`, JSON.stringify({ url: req.url, ae: req.headers['accept-encoding'] || null, body }) + '\n');
    setTimeout(() => {
      const usage = { input_tokens: IN, output_tokens: OUT, cache_read_input_tokens: CR, cache_creation_input_tokens: CC };
      if (MODE === 'stall') {
        // Headers and the first SSE event now, the rest after UP_STALL ms.
        res.writeHead(200, { 'content-type': 'text/event-stream' });
        res.write(`data: ${JSON.stringify({ type: 'message_start', message: { usage: { input_tokens: IN, output_tokens: 1 } } })}\n\n`);
        return setTimeout(() => { res.write(`data: ${JSON.stringify({ type: 'message_delta', usage: { output_tokens: OUT } })}\n\n`); res.end(); }, n('UP_STALL', 3000));
      }
      if (MODE === 'garbage') { res.writeHead(200, { 'content-type': 'application/json' }); return res.end('not json at all'); }
      if (MODE === 'error') { res.writeHead(400, { 'content-type': 'application/json' }); return res.end('{"type":"error","error":{"type":"invalid_request_error"}}'); }
      if (MODE === 'sse') {
        res.writeHead(200, { 'content-type': 'text/event-stream; charset=utf-8' });
        res.write(`event: message_start\r\ndata: ${JSON.stringify({ type: 'message_start', message: { usage: { ...usage, output_tokens: 1 } } })}\r\n\r\n`);
        res.write(`event: message_delta\r\ndata: ${JSON.stringify({ type: 'message_delta', usage })}\r\n\r\n`);
        return res.end();
      }
      let payload = JSON.stringify({ type: 'message', content: [], usage });
      const h = { 'content-type': 'application/json' };
      if (MODE === 'gzip') { h['content-encoding'] = 'gzip'; payload = zlib.gzipSync(payload); }
      res.writeHead(200, h);
      res.end(payload);
    }, DELAY);
  });
}).listen(port, '127.0.0.1', () => process.stdout.write('up\n'));
