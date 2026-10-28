#!/usr/bin/env node
// api-proxy.mjs — the sample container's ONLY route out (docker sandbox), and
// the AUTHORITATIVE record of what a sample spent. It runs in its own
// container, outside the model's reach. The sample's claude is pointed here
// with ANTHROPIC_BASE_URL and a placeholder key; this proxy strips any client
// credential and injects the real ANTHROPIC_API_KEY, which only this container
// holds.
//
// Request validation (body fully buffered and parsed; never streamed through;
// any validator error is a 400, never a crash):
//   - exact path + method allowlist; absolute/authority-form targets rejected
//   - top-level body fields: ALLOWLIST (BODY_KEYS; UNVERIFIED that Claude Code
//     needs nothing else — every rejection is logged)
//   - `model` allowlist (PROXY_MODELS); `max_tokens` in 1..PROXY_MAX_TOKENS
//   - tools: plain client-side tools only ({name, description?, input_schema
//     object, cache_control?}, `type` absent or "custom")
//   - content blocks, recursively (messages, system, tool_result.content), at
//     most MAX_DEPTH deep: type allowlist (BLOCK_TYPES; `document` rejected —
//     a compressed PDF can tokenize past its byte count) and `source.type`
//     only `base64` (url / file sources would make the API fetch for the model)
//   - `anthropic-beta` value allowlist (PROXY_BETAS); x-forwarded-*, hop-by-hop
//     and credential headers dropped
//   - the body FORWARDED is the re-serialized validated object
//
// Spend accounting (per proxy = per sample). Requests run CONCURRENTLY, up to
// PROXY_MAX_INFLIGHT at once. Each /v1/messages request reserves its worst
// case — body bytes + PROXY_RESERVE_OVERHEAD + max_tokens + images x
// PROXY_IMAGE_RESERVE cap units (a token covers at least a byte of the
// request). It is admitted only if
//     committed + (reservations in flight) + its reservation <= PROXY_MAX_UNITS
// and fewer than PROXY_MAX_INFLIGHT are in flight; otherwise it gets an
// immediate 429 — no queue, no waiting: `cause:"inflight"` when the concurrency
// limit is full (transient; the harness's own limit, not a denial, not a
// stop), `cause:"budget"` when the unit cap would be exceeded (the sample's
// budget is spent: a stop signal downstream). Neither is a model denial. A
// request counts against PROXY_MAX_REQUESTS only once it is admitted. Those 429s are the
// harness's own limit, not a model-caused denial; they are counted apart.
//   - On the response the reservation is replaced by the parsed usage. Cap
//     units = input + cache_creation + output + cache_read x
//     PROXY_CACHE_READ_WEIGHT (0 < w <= 1, default 0.1; invalid -> 1).
//   - Upstream is asked for `accept-encoding: identity`; a compressed reply is
//     decompressed anyway. FAIL CLOSED: once the request body has been written
//     upstream the request may be billed, so a 2xx reply whose usage cannot be
//     parsed, a network error, a timeout, or a client disconnect is charged its
//     full reservation and flagged. Before the body is written, such a failure
//     is charged 0. An upstream 4xx/5xx error body is charged 0 (UNVERIFIED that
//     it is unbilled). count_tokens requests reserve and charge 0 (UNVERIFIED).
//
// Log (stdout, one JSON line each; never the key, headers or bodies):
//   {listening, upstream, max_units, max_tokens, max_inflight, cache_read_weight, models}
//   {phase:"start", id, path, model, reserved, committed, inflight}
//   {phase:"end", id, model, status, usage, units, usage_parsed, committed, note?}
//   {phase:"error", id, error}   {phase:"unfinished", id, model, units}
//   {method, path, status, denied, cause?}   cause: "inflight" | "budget" | "drain" (not denials)
//   {summary:true, requests, denials, inflight_rejected, budget_rejected, drain_rejected, client_aborted,
//    max_inflight_seen, committed_units, unparsed, unfinished, by_model, cache_read_weight}
// On SIGTERM it stops accepting, lets in-flight requests finish (up to
// PROXY_DRAIN_MS), charges any still unfinished at its reservation, then
// writes the summary.
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
// 8 in flight: the main loop plus a handful of parallel subagents / background
// (haiku) calls — enough that a fan-out arm is not throttled in practice, small
// enough that one sample cannot open a flood of concurrent paid calls. Every
// 429 from this limit is counted per arm, so if it ever binds it is visible.
const MAX_INFLIGHT = Number(env.PROXY_MAX_INFLIGHT) || 8;
const CR_WEIGHT = env.PROXY_CACHE_READ_WEIGHT === undefined ? 0.1 : (w => (Number.isFinite(w) && w > 0 && w <= 1 ? w : 1))(Number(env.PROXY_CACHE_READ_WEIGHT));
const DRAIN_MS = Number(env.PROXY_DRAIN_MS) || 25000;
const IMAGE_RESERVE = Number(env.PROXY_IMAGE_RESERVE) || 1600; // per image block; UNVERIFIED upper bound
const MAX_BODY = 32 * 1024 * 1024;
const MAX_DEPTH = 32;
const MODELS = new Set((env.PROXY_MODELS || '').split(/\s+/).filter(Boolean));
const BETAS = new Set((env.PROXY_BETAS || '').split(/\s+/).filter(Boolean));
const ROUTES = [
  ['POST', '/v1/messages', 'messages'],
  ['POST', '/v1/messages/count_tokens', 'count'],
  ['GET', '/v1/models', 'models'],
];
const BODY_KEYS = new Set(['model', 'messages', 'system', 'max_tokens', 'tools', 'tool_choice', 'stream',
  'temperature', 'thinking', 'metadata', 'stop_sequences', 'top_p', 'top_k']);
const TOOL_KEYS = new Set(['name', 'description', 'input_schema', 'cache_control', 'type']);
const BLOCK_TYPES = new Set(['text', 'image', 'tool_use', 'tool_result', 'thinking', 'redacted_thinking']);
const DROP = new Set(['host', 'x-api-key', 'authorization', 'connection', 'keep-alive', 'proxy-authorization',
  'proxy-connection', 'te', 'trailer', 'upgrade', 'transfer-encoding', 'content-length', 'accept-encoding',
  'x-forwarded-for', 'x-forwarded-host', 'x-forwarded-proto', 'forwarded']);

const S = { count: 0, requests: 0, denials: 0, inflight_rejected: 0, budget_rejected: 0, drain_rejected: 0, client_aborted: 0,
  committed: 0, unparsed: 0, unfinished: 0, max_inflight_seen: 0, by_model: {}, nextId: 1, draining: false };
const inflight = new Map();   // id -> { model, reserved }
const log = (o) => process.stdout.write(JSON.stringify({ t: new Date().toISOString(), ...o }) + '\n');
const safePath = (u) => { try { return new URL(u, 'http://p').pathname.slice(0, 200); } catch { return '/?'; } };
const units = (u) => u.input + u.cache_creation + u.output + Math.ceil(u.cache_read * CR_WEIGHT);
const reservedInFlight = () => { let n = 0; for (const r of inflight.values()) n += r.reserved; return n; };

// Every rejection is logged. causes "inflight" / "budget" (our limits) and
// "drain" (shutting down) are the harness's own limits, not model denials.
function deny(req, res, status, why, cause) {
  if (cause === 'inflight') S.inflight_rejected++;
  else if (cause === 'budget') S.budget_rejected++;
  else if (cause === 'drain') S.drain_rejected++;
  else S.denials++;
  log({ method: req.method, path: safePath(req.url), status, denied: why, ...(cause ? { cause } : {}) });
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

// Content blocks: returns an error string, or null. Counts images into ctx.
function walk(content, where, depth, ctx) {
  if (depth > MAX_DEPTH) return `content nested deeper than ${MAX_DEPTH}`;
  if (content === undefined || typeof content === 'string') return null;
  if (!Array.isArray(content)) return `${where} content must be a string or an array`;
  for (const b of content) {
    if (!b || typeof b !== 'object' || Array.isArray(b)) return `${where} block is not an object`;
    if (!BLOCK_TYPES.has(String(b.type))) return `content block type not allowed: ${String(b.type).slice(0, 40)}`;
    if (b.source !== undefined && (!b.source || typeof b.source !== 'object' || b.source.type !== 'base64')) {
      return `content source type not allowed: ${String(b.source && b.source.type).slice(0, 40)}`;
    }
    if (b.type === 'image') ctx.images++;
    if (b.type === 'tool_result') { const e = walk(b.content, 'tool_result', depth + 1, ctx); if (e) return e; }
  }
  return null;
}

function validate(route, buf) {
  if (route[2] === 'models') return { ok: true, body: buf, model: null, maxTokens: 0, images: 0 };
  let o;
  try { o = JSON.parse(buf.toString('utf8')); } catch { return { ok: false, why: 'body is not JSON' }; }
  if (!o || typeof o !== 'object' || Array.isArray(o)) return { ok: false, why: 'body is not an object' };
  for (const k of Object.keys(o)) if (!BODY_KEYS.has(k)) return { ok: false, why: `request field not allowed: ${k.slice(0, 40)}` };
  if (!MODELS.has(String(o.model))) return { ok: false, why: `model not on the allowlist: ${String(o.model).slice(0, 60)}` };
  if (route[2] === 'messages' && !(Number.isInteger(o.max_tokens) && o.max_tokens > 0 && o.max_tokens <= MAX_TOKENS)) {
    return { ok: false, why: `max_tokens must be 1..${MAX_TOKENS}` };
  }
  if (o.tools !== undefined) {
    if (!Array.isArray(o.tools)) return { ok: false, why: 'tools must be an array' };
    for (const t of o.tools) {
      if (!t || typeof t !== 'object') return { ok: false, why: 'tool is not an object' };
      if (t.type !== undefined && t.type !== 'custom') return { ok: false, why: `tool type not allowed: ${String(t.type).slice(0, 60)}` };
      for (const k of Object.keys(t)) if (!TOOL_KEYS.has(k)) return { ok: false, why: `tool key not allowed: ${k.slice(0, 40)}` };
      if (typeof t.name !== 'string' || !t.input_schema || typeof t.input_schema !== 'object' || Array.isArray(t.input_schema)) return { ok: false, why: 'tool needs name and an object input_schema' };
    }
  }
  const ctx = { images: 0 };
  if (o.messages !== undefined && !Array.isArray(o.messages)) return { ok: false, why: 'messages must be an array' };
  for (const m of o.messages || []) {
    if (!m || typeof m !== 'object') return { ok: false, why: 'message is not an object' };
    const e = walk(m.content, 'message', 1, ctx); if (e) return { ok: false, why: e };
  }
  { const e = walk(o.system, 'system', 1, ctx); if (e) return { ok: false, why: e }; }
  return { ok: true, body: Buffer.from(JSON.stringify(o)), model: String(o.model), maxTokens: route[2] === 'messages' ? o.max_tokens : 0, images: ctx.images };
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
  let seen = false, delta = false;
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
      if (o && o.type === 'message_delta') { take(o.usage); delta = true; }
    }
    // A stream that never sent message_delta has no final output count:
    // treat as unparsed (charged the reservation) rather than the start usage.
    if (!delta) return null;
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

function forward(req, res, v, headers, route) {
  const reserved = route[2] === 'messages' ? v.body.length + OVERHEAD + v.maxTokens + v.images * IMAGE_RESERVE : 0;
  if (inflight.size >= MAX_INFLIGHT) return deny(req, res, 429, `proxy concurrency: ${MAX_INFLIGHT} requests already in flight`, 'inflight');
  if (S.committed + reservedInFlight() + reserved > MAX_UNITS) {
    return deny(req, res, 429, `unit budget exhausted: cap ${MAX_UNITS} units (committed ${S.committed} + in flight ${reservedInFlight()} + this ${reserved})`, 'budget');
  }
  // Counted against the request cap only once admitted (cap-429 retries must
  // not use it up).
  if (++S.count > MAX_REQUESTS) return deny(req, res, 429, `request cap ${MAX_REQUESTS} reached`);
  const id = S.nextId++;
  S.requests++;
  inflight.set(id, { model: v.model, reserved });
  S.max_inflight_seen = Math.max(S.max_inflight_seen, inflight.size);
  log({ phase: 'start', id, path: safePath(req.url), model: v.model, reserved, committed: S.committed, inflight: inflight.size });
  let bodySent = false;   // the request body was fully written upstream
  let upRef = null;
  // One outcome per request. failed=true: no usable usage — charge the
  // reservation if the body reached upstream (it may be billed), else 0.
  const finish = (status, u, note, failed) => {
    if (!inflight.has(id)) return;
    inflight.delete(id);
    let n = 0;
    if (route[2] !== 'messages') n = 0;
    else if (u) n = charge(v.model, u);
    else if (failed ? bodySent : (status >= 200 && status < 300)) {
      S.unparsed++;
      n = charge(v.model, { input: reserved - v.maxTokens, cache_read: 0, cache_creation: 0, output: v.maxTokens });
    }
    log({ phase: 'end', id, model: v.model, status, usage: u || null, units: n, usage_parsed: Boolean(u), committed: S.committed, ...(note ? { note } : {}) });
  };
  res.on('close', () => {
    if (res.writableFinished || !inflight.has(id)) return;
    S.client_aborted++;
    finish(0, null, 'client aborted request', true);
    if (upRef) upRef.destroy(new Error('client aborted'));
  });
  if (UPSTREAM === 'echo') {
    const u = { input: 7, cache_read: 0, cache_creation: 0, output: 11 };
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({
      echo: true, method: req.method, path: safePath(req.url), forwarded_header_names: Object.keys(headers).sort(),
      x_api_key_sha256: createHash('sha256').update(KEY).digest('hex'),
      usage: { input_tokens: u.input, output_tokens: u.output },
    }));
    return finish(200, u);
  }
  const target = new URL(safePath(req.url) + (req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : ''), UPSTREAM);
  const mod = target.protocol === 'http:' ? http : https;
  const up = mod.request(target, { method: req.method, headers }, (ur) => {
    const chunks = []; let bytes = 0;
    ur.on('data', (c) => { bytes += c.length; if (bytes <= MAX_BODY) chunks.push(c); });
    ur.on('end', () => finish(ur.statusCode || 0, parseUsage(Buffer.concat(chunks), ur.headers)));
    // Mid-pipe upstream failure: charge (fail closed) and end the client's
    // response too, or it would hang waiting for the rest.
    ur.on('error', () => { finish(0, null, 'upstream response error', true); res.destroy(); });
    res.writeHead(ur.statusCode || 502, ur.headers);
    ur.pipe(res);
  });
  upRef = up;
  up.setTimeout(Number(env.PROXY_UPSTREAM_TIMEOUT_MS) || 600000, () => up.destroy(new Error('upstream timeout')));
  up.on('error', (e) => {
    log({ phase: 'error', id, error: e.code || e.message || 'upstream error' });
    finish(0, null, 'upstream request error', true);
    if (!res.headersSent) res.writeHead(502, { 'content-type': 'application/json' });
    res.end();
  });
  up.end(v.body, () => { bodySent = true; });
}

const server = http.createServer((req, res) => {
  if (S.draining) return deny(req, res, 503, 'proxy is shutting down', 'drain');
  const route = routeFor(req);
  if (!route) return deny(req, res, 403, 'not on the allowlist');
  if (!KEY) return deny(req, res, 503, 'proxy has no ANTHROPIC_API_KEY');
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
    let v;
    try { v = validate(route, Buffer.concat(chunks)); } catch { v = { ok: false, why: 'invalid request (validator error)' }; }
    if (!v.ok) return deny(req, res, 400, v.why);
    if (S.draining) return deny(req, res, 503, 'proxy is shutting down', 'drain');
    const headers = { 'content-length': String(v.body.length), 'accept-encoding': 'identity' };
    for (const [k, val] of Object.entries(req.headers)) if (!DROP.has(k.toLowerCase())) headers[k] = val;
    headers['x-api-key'] = KEY;
    forward(req, res, v, headers, route);
  });
});
server.listen(Number(env.PROXY_PORT) || 8080, env.PROXY_HOST || '0.0.0.0', () => log({
  listening: Number(env.PROXY_PORT) || 8080, upstream: UPSTREAM === 'echo' ? 'echo' : new URL(UPSTREAM).host,
  max_units: MAX_UNITS, max_tokens: MAX_TOKENS, max_inflight: MAX_INFLIGHT, cache_read_weight: CR_WEIGHT, models: [...MODELS],
}));

function summary(sig) {
  if (S.draining) return;
  S.draining = true;
  server.close();
  const t0 = Date.now();
  const wait = () => {
    if (inflight.size && Date.now() - t0 < DRAIN_MS) return setTimeout(wait, 50);
    for (const [id, r] of inflight) {
      // Still unfinished: charge the full reservation (fail closed).
      S.unfinished++;
      if (r.reserved) charge(r.model, { input: r.reserved, cache_read: 0, cache_creation: 0, output: 0 });
      log({ phase: 'unfinished', id, model: r.model, units: r.reserved });
    }
    inflight.clear();
    log({ summary: true, signal: sig, requests: S.requests, denials: S.denials, inflight_rejected: S.inflight_rejected, budget_rejected: S.budget_rejected,
      drain_rejected: S.drain_rejected, client_aborted: S.client_aborted, max_inflight_seen: S.max_inflight_seen,
      committed_units: S.committed, unparsed: S.unparsed, unfinished: S.unfinished, by_model: S.by_model, cache_read_weight: CR_WEIGHT });
    process.exit(0);
  };
  wait();
}
process.on('SIGTERM', () => summary('SIGTERM'));
process.on('SIGINT', () => summary('SIGINT'));
