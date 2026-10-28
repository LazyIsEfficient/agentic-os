// Client for api-proxy-test.sh: sends one POST /v1/messages per argument, in
// parallel; each argument is the ms after which that client aborts its
// request (0 = never). Prints the status codes ("aborted" for aborted ones).
// Usage: node abort-client.mjs <port> '<json body>' <abortMs>...
import http from 'node:http';

const [port, body, ...aborts] = [Number(process.argv[2]), process.argv[3], ...process.argv.slice(4).map(Number)];
const one = (abortMs) => new Promise((resolve) => {
  const r = http.request({ host: '127.0.0.1', port, path: '/v1/messages', method: 'POST',
    headers: { 'content-type': 'application/json', 'content-length': Buffer.byteLength(body) } }, (res) => {
    res.resume();
    res.on('end', () => resolve(res.statusCode));
    res.on('error', () => resolve('aborted'));
  });
  r.on('error', () => resolve('aborted'));
  r.end(body);
  if (abortMs) setTimeout(() => r.destroy(), abortMs);
});
process.stdout.write(JSON.stringify(await Promise.all(aborts.map(one))) + '\n');
