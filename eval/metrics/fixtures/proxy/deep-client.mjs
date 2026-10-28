// Client for api-proxy-test.sh: POSTs a /v1/messages body whose content is
// tool_result blocks nested <depth> deep (the crash.sh PoC shape), and prints
// the HTTP status. Usage: node deep-client.mjs <port> <model> <depth>
import http from 'node:http';

const [port, model, depth] = [Number(process.argv[2]), process.argv[3], Number(process.argv[4])];
// Built as a string: JSON.stringify itself overflows the stack at this depth.
const open = '[{"type":"tool_result","tool_use_id":"t","content":';
const body = `{"model":${JSON.stringify(model)},"max_tokens":10,"messages":[{"role":"user","content":`
  + open.repeat(depth) + '[{"type":"text","text":"x"}]' + '}]'.repeat(depth) + '}]}';
const r = http.request({ host: '127.0.0.1', port, path: '/v1/messages', method: 'POST',
  headers: { 'content-type': 'application/json', 'content-length': Buffer.byteLength(body) } }, (res) => {
  res.resume();
  res.on('end', () => process.stdout.write(`${res.statusCode}\n`));
});
r.on('error', (e) => process.stdout.write(`ERR ${e.code}\n`));
r.end(body);
