// Client for api-proxy-test.sh. Sends N POST /v1/messages requests in parallel
// to the proxy and prints a JSON summary of status codes.
// Usage: node client.mjs <port> <n> '<json body>' [anthropic-beta]
import http from 'node:http';

const [port, n, body, beta] = [Number(process.argv[2]), Number(process.argv[3]), process.argv[4], process.argv[5]];
const one = () => new Promise((resolve) => {
  const headers = { 'content-type': 'application/json', 'content-length': Buffer.byteLength(body), 'accept-encoding': 'gzip' };
  if (beta) headers['anthropic-beta'] = beta;
  const r = http.request({ host: '127.0.0.1', port, path: '/v1/messages', method: 'POST', headers }, (res) => {
    res.resume();
    res.on('end', () => resolve(res.statusCode));
  });
  r.on('error', () => resolve(0));
  r.end(body);
});
const codes = await Promise.all(Array.from({ length: n }, one));
const tally = {};
for (const c of codes) tally[c] = (tally[c] || 0) + 1;
process.stdout.write(JSON.stringify(tally) + '\n');
