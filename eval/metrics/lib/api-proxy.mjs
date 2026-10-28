#!/usr/bin/env node
// api-proxy.mjs — the sample container's ONLY route out (docker sandbox), and
// the AUTHORITATIVE record of what a sample spent. It runs in its own
// container, outside the model's reach. The sample's claude is pointed here
// with ANTHROPIC_BASE_URL and a placeholder key; this proxy strips any client
// credential and injects the real ANTHROPIC_API_KEY, which only this container
// holds.
//
// Request validation (body fully buffered and parsed; never streamed through):
//   - exact path + method allowlist; absolute/authority-form targets rejected
//   - `model` allowlist (PROXY_MODELS, space-separated)
//   - `max_tokens` in 1..PROXY_MAX_TOKENS on /v1/messages
//   - tools: ALLOWLIST of plain client-side tools only ({name, description?,
//     input_schema, cache_control?}, `type` absent or "custom"); any other
//     tool `type` (server tools such as web_search / web_fetch / code
//     execution) and any `mcp_servers` are rejected. UNVERIFIED that Claude
//     Code 2.1.311 sends only such tools; every rejection is logged.
//   - `anthropic-beta` value allowlist (PROXY_BETAS); x-forwarded-*, hop-by-hop
//     and credential headers dropped
//   - the body FORWARDED is the re-serialized validated object, so a duplicated
//     JSON key cannot validate one value and send another
//
// Spend accounting (per proxy = per sample):
//   - ONE request at a time (later ones queue), so the cap cannot be raced.
//   - Before forwarding, each /v1/messages request RESERVES its worst case:
//     body bytes + PROXY_RESERVE_OVERHEAD + max_tokens, in cap units (a token
//     covers at least one byte of the request, so this bounds its input).
//     Admission requires committed + reservation <= PROXY_MAX_UNITS; else 429.
//   - On the response the reservation is replaced by the parsed usage. Cap
//     units = input + cache_creation + output + cache_read * PROXY_CACHE_READ_WEIGHT
//     (default 0.1): cached reads are cheap to bill (UNVERIFIED multiplier) and
//     a large cached context would otherwise trip the cap early, while still
//     being bounded.
//   - Upstream is asked for `accept-encoding: identity`; a compressed reply is
//     decompressed for parsing anyway. FAIL CLOSED: a 2xx response whose usage
//     cannot be parsed is charged its full reservation and flagged. Upstream
//     4xx/5xx error bodies are charged 0 (not billed; UNVERIFIED).
//   - count_tokens requests reserve and charge 0 (UNVERIFIED that they are free).
//
// Log (stdout, one JSON line each; never the key, headers or bodies):
//   {phase:"start", id, model, reserved, committed}   when forwarding begins
//   {phase:"end", id, model, status, usage, units, usage_parsed, committed}
//   {denied, status, ...}                              every rejection
//   {summary:true, requests, denials, committed_units, unparsed, unfinished,
//    by_model:{<model>:{input, cache_read, cache_creation, output}}}
// On SIGTERM it stops accepting, rejects queued requests, lets the in-flight
// one finish (up to PROXY_DRAIN_MS), charges any still unfinished at its
// reservation, then writes the summary.
//
//   upstream  PROXY_UPSTREAM (default https://api.anthropic.com). TEST HOOKS:
//             "echo" answers locally; an http:// URL is used for the proxy's
//             own tests (the harness only ever passes echo or the real API).
import http from 'node:http';
import https from 'node:https';
import zlib from 'node:zlib';
import { createHash } from 'node:crypto';

const env = process.env;
const KEY = env.ANTHROPIC_API_KEY || '';
const UPSTREAM = env.PROXY_UPSTREAM || 'https://api.anthropic.com';
const MAX_REQUESTS = Number(env.PROXY_MAX_REQUESTS) || 400;
const MAX_TOKENS = Number(env.PROXY_MAX_TOKENS) || 32000;
const MAX_UNITS = Number(env.PROXY_MAX_UNITS) || 2_000_000;
const OVERHEAD = Number(env.PROXY_RESERVE_OVERHEAD) || 4096;
const CR_WEIGHT = env.PROXY_CACHE_READ_WEIGHT === undefined ? 0.1 : (w => (Number.isFinite(w) && w >= 0 && w <= 1 ? w : 1))(Number(env.PROXY_CACHE_READ_WEIGHT)); // invalid -> 1 (fail closed)
const DRAIN_MS = Number(env.PROXY_DRAIN_MS) || 25000;
const MAX_BODY = 32 * 1024 * 1024;
const MODELS = new Set((env.PROXY_MODELS || '').split(/\s+/).filter(Boolean));
const BETAS = new Set((env.PROXY_BETAS || '').split(/\s+/).filter(Boolean));
const ROUTES = [
  ['POST', '/v1/messages', 'messages'],
  ['POST', '/v1/messages/count_tokens', 'count'],
  ['GET', '/v1/models', 'models'],
];
const TOOL_KEYS = new Set(['name', 'description', 'input_schema', 'cache_control', 'type']);
const DROP = new Set(['host', 'x-api-key', 'authorization', 'connection', 'keep-alive', 'proxy-authorization',
  'proxy-connection', 'te', 'trailer', 'upgrade', 'transfer-encoding', 'content-length', 'accept-encoding',
  'x-forwarded-for', 'x-forwarded-host', 'x-forwarded-proto', 'forwarded']);

const S = { count: 0, requests: 0, denials: 0, committed: 0, unparsed: 0, unfinished: 0, by_model: {}, nextId: 1, draining: false };
let inflight = null;      // { id, model, reserved }
const queue = [];         // pending run() closures
const log = (o) => process.stdout.write(JSON.stringify({ t: new Date().toISOString(), ...o }) + '\n');
const safePath = (u) => { try { return new URL(u, 'http://p').pathname.slice(0, 200); } catch { return '/?'; } };
const units = (u) => u.input + u.cache_creation + u.output + Math.ceil(u.cache_read * CR_WEIGHT);

function deny(req, res, status, why) {
  S.denials++;
  log({ method: req.method, path: safePath(req.url), status, denied: why });
  if (!res.headersSent) res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ type: 'error', error: { type: 'proxy_denied', message: why } }));
}
function routeFor(req) {
  if (/^[a-z]+:\/\//i.test(req.url) || req.url.startsWith('//') || !req.url.startsWith('/')) return null;
  let u;
  try { u = new URL(req.url, 'http://proxy'); } catch { return null; }
  if (u.pathname.includes('..') || /%2/i.test(u.pathname)) return null;
  return ROUTES.find(([m, p]) => m === req.method && p === u.pathname) || null;
}

function validate(route, buf) {
  if (route[2] === 'models') return { ok: true, body: buf, model: null, maxTokens: 0 };
  let o;
  try { o = JSON.parse(buf.toString('utf8')); } catch { return { ok: false, why: 'body is not JSON' }; }
  if (!o || typeof o !== 'object' || Array.isArray(o)) return { ok: false, why: 'body is not an object' };
  if (!MODELS.has(String(o.model))) return { ok: false, why: `model not on the allowlist: ${String(o.model).slice(0, 60)}` };
  if (route[2] === 'messages' && !(Number.isInteger(o.max_tokens) && o.max_tokens > 0 && o.max_tokens <= MAX_TOKENS)) {
    return { ok: false, why: `max_tokens must be 1..${MAX_TOKENS}` };
  }
  if (o.mcp_servers !== undefined) return { ok: false, why: 'mcp_servers not allowed' };
  if (o.tools !== undefined) {
    if (!Array.isArray(o.tools)) return { ok: false, why: 'tools must be an array' };
    for (const t of o.tools) {
      if (!t || typeof t !== 'object') return { ok: false, why: 'tool is not an object' };
      if (t.type !== undefined && t.type !== 'custom') return { ok: false, why: `tool type not allowed: ${String(t.type).slice(0, 60)}` };
      for (const k of Object.keys(t)) if (!TOOL_KEYS.has(k)) return { ok: false, why: `tool key not allowed: ${k.slice(0, 40)}` };
      if (typeof t.name !== 'string' || !t.input_schema || typeof t.input_schema !== 'object') return { ok: false, why: 'tool needs name and input_schema' };
    }
  }
  // Forward exactly what was validated (duplicate keys collapse here).
  return { ok: true, body: Buffer.from(JSON.stringify(o)), model: String(o.model), maxTokens: route[2] === 'messages' ? o.max_tokens : 0 };
}

// Usage from a (possibly compressed) JSON body or SSE stream; null if absent.
function parseUsage(raw, headers) {
  let buf = raw;
  const enc = String(headers['content-encoding'] || '').toLowerCase();
  try {
    if (enc.includes('gzip')) buf = zlib.gunzipSync(raw);
    else if (enc.includes('br')) buf = zlib.brotliDecompressSync(raw);
    else if (enc.includes('deflate')) buf = zlib.inflateSync(raw);
  } catch { return null; }
  const text = buf.toString('utf8');
  const u = { input: 0, cache_read: 0, cache_creation: 0, output: 0 };
  let seen = false;
  const take = (x) => {
    if (!x || typeof x !== 'object') return;
    const f = (k) => (Number.isFinite(x[k]) && x[k] >= 0 ? x[k] : null);
    // Usage fields are cumulative in a stream; keep the largest seen.
    if (f('input_tokens') !== null) { u.input = Math.max(u.input, f('input_tokens')); seen = true; }
    if (f('cache_read_input_tokens') !== null) { u.cache_read = Math.max(u.cache_read, f('cache_read_input_tokens')); seen = true; }
    if (f('cache_creation_input_tokens') !== null) { u.cache_creation = Math.max(u.cache_creation, f('cache_creation_input_tokens')); seen = true; }
    if (f('output_tokens') !== null) { u.output = Math.max(u.output, f('output_tokens')); seen = true; }
  };
  if (/text\/event-stream/i.test(String(headers['content-type'] || ''))) {
    for (const line of text.split(/\r?\n/)) {
      if (!line.startsWith('data:')) continue;
      let o; try { o = JSON.parse(line.slice(5).trim()); } catch { continue; }
      if (o && o.type === 'message_start' && o.message) take(o.message.usage);
      if (o && o.type === 'message_delta') take(o.usage);
    }
  } else {
    let o; try { o = JSON.parse(text); } catch { o = null; }
    if (o) take(o.usage);
  }
  return seen ? u : null;
}

function charge(model, u) {
  const m = S.by_model[model] || (S.by_model[model] = { input: 0, cache_read: 0, cache_creation: 0, output: 0 });
  for (const k of Object.keys(m)) m[k] += u[k];
  const n = units(u);
  S.committed += n;
  return n;
}

function forward(req, res, v, headers, route, done) {
  const id = S.nextId++;
  const reserved = route[2] === 'messages' ? v.body.length + OVERHEAD + v.maxTokens : 0;
  if (S.committed + reserved > MAX_UNITS) { deny(req, res, 429, `token cap ${MAX_UNITS} units reached (committed ${S.committed} + reserved ${reserved})`); return done(); }
  S.requests++;
  inflight = { id, model: v.model, reserved };
  log({ phase: 'start', id, path: safePath(req.url), model: v.model, reserved, committed: S.committed });
  const finish = (status, u, parsed) => {
    if (!inflight || inflight.id !== id) return;
    inflight = null;
    let n = 0;
    if (route[2] !== 'messages') n = 0;
    else if (parsed) n = charge(v.model, u);
    else if (status === 0 || (status >= 200 && status < 300)) { S.unparsed++; n = charge(v.model, { input: reserved - v.maxTokens, cache_read: 0, cache_creation: 0, output: v.maxTokens }); } // 0 = network error/timeout: may have been billed, so fail closed
    log({ phase: 'end', id, model: v.model, status, usage: parsed ? u : null, units: n, usage_parsed: Boolean(parsed), committed: S.committed });
    done();
  };
  if (UPSTREAM === 'echo') {
    const u = { input: 7, cache_read: 0, cache_creation: 0, output: 11 };
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({
      echo: true, method: req.method, path: safePath(req.url), forwarded_header_names: Object.keys(headers).sort(),
      x_api_key_sha256: createHash('sha256').update(KEY).digest('hex'),
      usage: { input_tokens: u.input, output_tokens: u.output },
    }));
    return finish(200, u, true);
  }
  const target = new URL(safePath(req.url) + (req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : ''), UPSTREAM);
  const mod = target.protocol === 'http:' ? http : https;
  const up = mod.request(target, { method: req.method, headers }, (ur) => {
    const chunks = []; let bytes = 0;
    ur.on('data', (c) => { bytes += c.length; if (bytes <= MAX_BODY) chunks.push(c); });
    ur.on('end', () => {
      const status = ur.statusCode || 0;
      const u = parseUsage(Buffer.concat(chunks), ur.headers);
      finish(status, u || { input: 0, cache_read: 0, cache_creation: 0, output: 0 }, Boolean(u));
    });
    ur.on('error', () => finish(0, null, false));
    res.writeHead(ur.statusCode || 502, ur.headers);
    ur.pipe(res);
  });
  // A hung upstream must not hold the single slot forever.
  up.setTimeout(Number(env.PROXY_UPSTREAM_TIMEOUT_MS) || 600000, () => up.destroy(new Error('upstream timeout')));
  up.on('error', (e) => {
    log({ phase: 'error', id, error: e.code || e.message || 'upstream error' });
    if (!res.headersSent) res.writeHead(502, { 'content-type': 'application/json' });
    res.end();
    finish(0, null, false);
  });
  up.end(v.body);
}

function pump() {
  if (inflight || !queue.length) return;
  queue.shift()();
}

const server = http.createServer((req, res) => {
  if (S.draining) return deny(req, res, 503, 'proxy is shutting down');
  const route = routeFor(req);
  if (!route) return deny(req, res, 403, 'not on the allowlist');
  if (!KEY) return deny(req, res, 503, 'proxy has no ANTHROPIC_API_KEY');
  if (++S.count > MAX_REQUESTS) return deny(req, res, 429, `request cap ${MAX_REQUESTS} reached`);
  const bad = [];
  for (const [k, v] of Object.entries(req.headers)) {
    if (k.toLowerCase() !== 'anthropic-beta') continue;
    for (const b of String(v).split(',').map((s) => s.trim()).filter(Boolean)) if (!BETAS.has(b)) bad.push(b);
  }
  if (bad.length) return deny(req, res, 400, `anthropic-beta value(s) not allowed: ${bad.join(',').slice(0, 120)}`);

  const chunks = []; let sent = 0, aborted = false;
  req.on('data', (c) => { sent += c.length; if (sent > MAX_BODY) { aborted = true; deny(req, res, 413, 'body too large'); req.destroy(); } else chunks.push(c); });
  req.on('end', () => {
    if (aborted) return;
    const v = validate(route, Buffer.concat(chunks));
    if (!v.ok) return deny(req, res, 400, v.why);
    const headers = { 'content-length': String(v.body.length), 'accept-encoding': 'identity' };
    for (const [k, val] of Object.entries(req.headers)) if (!DROP.has(k.toLowerCase())) headers[k] = val;
    headers['x-api-key'] = KEY;
    // One at a time: queue behind the in-flight request.
    queue.push(() => {
      if (S.draining) { deny(req, res, 503, 'proxy is shutting down'); return pump(); }
      forward(req, res, v, headers, route, pump);
    });
    pump();
  });
});
server.listen(Number(env.PROXY_PORT) || 8080, env.PROXY_HOST || '0.0.0.0', () => log({
  listening: Number(env.PROXY_PORT) || 8080, upstream: UPSTREAM === 'echo' ? 'echo' : new URL(UPSTREAM).host,
  max_units: MAX_UNITS, max_tokens: MAX_TOKENS, cache_read_weight: CR_WEIGHT, models: [...MODELS],
}));

function summary(sig) {
  if (S.draining) return;
  S.draining = true;
  server.close();
  const t0 = Date.now();
  const wait = () => {
    if (inflight && Date.now() - t0 < DRAIN_MS) return setTimeout(wait, 50);
    if (inflight) {
      // Still unfinished: charge the full reservation (fail closed).
      S.unfinished++;
      const r = inflight; inflight = null;
      if (r.reserved) charge(r.model, { input: r.reserved, cache_read: 0, cache_creation: 0, output: 0 });
      log({ phase: 'unfinished', id: r.id, model: r.model, units: r.reserved });
    }
    while (queue.length) queue.shift()();
    log({ summary: true, signal: sig, requests: S.requests, denials: S.denials, committed_units: S.committed,
      unparsed: S.unparsed, unfinished: S.unfinished, by_model: S.by_model, cache_read_weight: CR_WEIGHT });
    process.exit(0);
  };
  wait();
}
process.on('SIGTERM', () => summary('SIGTERM'));
process.on('SIGINT', () => summary('SIGINT'));
