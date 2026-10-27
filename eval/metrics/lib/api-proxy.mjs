#!/usr/bin/env node
// api-proxy.mjs — the sample container's ONLY route out (docker sandbox), and
// the AUTHORITATIVE record of what a sample spent. It runs in its own
// container, outside the model's reach. The sample's claude is pointed here
// with ANTHROPIC_BASE_URL and a placeholder key; this proxy strips any client
// credential and injects the real ANTHROPIC_API_KEY, which only this container
// holds. The model never sees the key and can reach nothing else.
//
// It fully buffers and parses each request body (never streams an unparsed
// body through), so it can enforce:
//   - path + method allowlist (exact, after URL parse; absolute-form and
//     authority-form request targets are rejected);
//   - a `model` allowlist (PROXY_MODELS, space-separated; default is the
//     Claude Code 2.1.311 default model, see run-release-arms.sh);
//   - a `max_tokens` cap (PROXY_MAX_TOKENS, default 32000);
//   - no server-side tools: a request naming web_search / web_fetch / bash /
//     code_execution / computer tools, or `mcp_servers`, is rejected, so the
//     model gets no internet or tool egress through the API;
//   - an `anthropic-beta` value allowlist (PROXY_BETAS; UNVERIFIED what Claude
//     Code 2.1.311 needs — rejections are logged so the smoke run reveals it);
//   - x-forwarded-* and hop-by-hop / credential headers dropped;
//   - a request-count cap (PROXY_MAX_REQUESTS, default 400) and a per-sample
//     cumulative input+output TOKEN cap (PROXY_MAX_TOKENS_TOTAL, default
//     2_000_000) enforced from upstream usage; both return 429.
//
// Usage is parsed from each upstream response, including streaming SSE
// (message_start + message_delta usage events), and accumulated. The running
// totals are the sample's PRIMARY tokens/cost; the summary flags any
// disagreement with the CLI's own result record.
//
//   upstream  PROXY_UPSTREAM (default https://api.anthropic.com). TEST HOOK:
//             "echo" answers locally (forwarded header names, the sha256 of the
//             injected key, and a synthetic usage block), no network.
//   log       one JSON line per request on stdout: method, path, status, bytes,
//             usage and the running totals. Never the key, headers or bodies.
//             On SIGTERM it writes a final {summary:true,...} line.
import http from 'node:http';
import https from 'node:https';
import { createHash } from 'node:crypto';

const KEY = process.env.ANTHROPIC_API_KEY || '';
const UPSTREAM = process.env.PROXY_UPSTREAM || 'https://api.anthropic.com';
const MAX_REQUESTS = Number(process.env.PROXY_MAX_REQUESTS) || 400;
const MAX_TOKENS = Number(process.env.PROXY_MAX_TOKENS) || 32000;
const MAX_TOKENS_TOTAL = Number(process.env.PROXY_MAX_TOKENS_TOTAL) || 2_000_000;
const MAX_BODY = 32 * 1024 * 1024;
const MODELS = new Set((process.env.PROXY_MODELS || '').split(/\s+/).filter(Boolean));
const BETAS = new Set((process.env.PROXY_BETAS || '').split(/\s+/).filter(Boolean));
// Each entry: method, exact pathname, whether the body is parsed+validated.
const ROUTES = [
  ['POST', '/v1/messages', true],
  ['POST', '/v1/messages/count_tokens', true],
  ['GET', '/v1/models', false],
];
const SERVER_TOOL_TYPES = /^(web_search|web_fetch|bash|code_execution|computer)(_|$)/;
// Hop-by-hop, credential and spoofable headers never pass through.
const DROP = new Set(['host', 'x-api-key', 'authorization', 'connection', 'keep-alive', 'proxy-authorization',
  'proxy-connection', 'te', 'trailer', 'upgrade', 'transfer-encoding', 'content-length',
  'x-forwarded-for', 'x-forwarded-host', 'x-forwarded-proto', 'forwarded']);

let count = 0;
let tokensIn = 0, tokensOut = 0, requests = 0, denials = 0;
const log = (o) => process.stdout.write(JSON.stringify({ t: new Date().toISOString(), ...o }) + '\n');

function deny(req, res, status, why) {
  denials++;
  log({ method: req.method, path: safePath(req.url), status, denied: why });
  if (!res.headersSent) res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ type: 'error', error: { type: 'proxy_denied', message: why } }));
}
// Parse the request target ourselves; reject absolute-form / authority-form and
// anything whose pathname is not an exact route. No normalization games.
function routeFor(req) {
  if (/^[a-z]+:\/\//i.test(req.url) || req.url.startsWith('//')) return null;
  if (!req.url.startsWith('/')) return null;
  let u;
  try { u = new URL(req.url, 'http://proxy'); } catch { return null; }
  if (u.pathname.includes('..') || u.pathname.includes('%2')) return null;
  return ROUTES.find(([m, p]) => m === req.method && p === u.pathname) || null;
}
const safePath = (u) => { try { return new URL(u, 'http://p').pathname.slice(0, 200); } catch { return '/?'; } };

function validateBody(route, buf) {
  if (!route[2]) return { ok: true, body: buf };
  let o;
  try { o = JSON.parse(buf.toString('utf8')); } catch { return { ok: false, why: 'body is not JSON' }; }
  if (o === null || typeof o !== 'object') return { ok: false, why: 'body is not an object' };
  if (MODELS.size && !MODELS.has(String(o.model))) return { ok: false, why: `model not on the allowlist: ${String(o.model).slice(0, 60)}` };
  if (route[1] === '/v1/messages' && !(Number.isInteger(o.max_tokens) && o.max_tokens > 0 && o.max_tokens <= MAX_TOKENS)) {
    return { ok: false, why: `max_tokens must be 1..${MAX_TOKENS}` };
  }
  if (o.mcp_servers !== undefined) return { ok: false, why: 'mcp_servers not allowed' };
  const tools = Array.isArray(o.tools) ? o.tools : [];
  for (const t of tools) {
    const type = t && typeof t === 'object' ? String(t.type || '') : '';
    if (SERVER_TOOL_TYPES.test(type)) return { ok: false, why: `server-side tool not allowed: ${type}` };
  }
  return { ok: true, body: buf };
}

// Pull token usage out of a buffered JSON body or an SSE stream.
function usageFrom(buf, contentType) {
  const text = buf.toString('utf8');
  let inc = 0, out = 0, seen = false;
  const take = (u) => {
    if (!u || typeof u !== 'object') return;
    seen = true;
    if (Number.isFinite(u.input_tokens)) inc = u.input_tokens;
    if (Number.isFinite(u.cache_creation_input_tokens)) inc += u.cache_creation_input_tokens;
    if (Number.isFinite(u.cache_read_input_tokens)) inc += u.cache_read_input_tokens;
    if (Number.isFinite(u.output_tokens)) out = u.output_tokens;
  };
  if (/text\/event-stream/.test(contentType || '')) {
    for (const line of text.split('\n')) {
      if (!line.startsWith('data:')) continue;
      let o; try { o = JSON.parse(line.slice(5).trim()); } catch { continue; }
      if (o && o.type === 'message_start' && o.message) take(o.message.usage);
      if (o && o.type === 'message_delta' && o.usage) {
        // message_delta carries only output_tokens; keep input from message_start.
        if (Number.isFinite(o.usage.output_tokens)) out = o.usage.output_tokens;
        seen = true;
      }
    }
  } else {
    let o; try { o = JSON.parse(text); } catch { o = null; }
    if (o) take(o.usage);
  }
  return seen ? { input: inc, output: out } : null;
}

function forward(req, res, buf, headers) {
  if (UPSTREAM === 'echo') {
    const u = { input: 7, output: 11 };
    tokensIn += u.input; tokensOut += u.output; requests++;
    log({ method: req.method, path: safePath(req.url), status: 200, echo: true, usage: u, total_input: tokensIn, total_output: tokensOut });
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({
      echo: true, method: req.method, path: safePath(req.url),
      forwarded_header_names: Object.keys(headers).sort(),
      x_api_key_sha256: createHash('sha256').update(KEY).digest('hex'),
      usage: { input_tokens: u.input, output_tokens: u.output },
    }));
    return;
  }
  const target = new URL(safePath(req.url) + (req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : ''), UPSTREAM);
  const up = https.request(target, { method: req.method, headers }, (ur) => {
    const chunks = []; let bytes = 0;
    ur.on('data', (c) => { bytes += c.length; if (bytes <= MAX_BODY) chunks.push(c); });
    ur.on('end', () => {
      const u = usageFrom(Buffer.concat(chunks), ur.headers['content-type']);
      if (u) { tokensIn += u.input; tokensOut += u.output; }
      requests++;
      log({ method: req.method, path: safePath(req.url), status: ur.statusCode, bytes, usage: u, total_input: tokensIn, total_output: tokensOut });
    });
    res.writeHead(ur.statusCode || 502, ur.headers);
    ur.pipe(res);
  });
  up.on('error', (e) => {
    log({ method: req.method, path: safePath(req.url), status: 502, error: e.code || 'upstream error' });
    if (!res.headersSent) res.writeHead(502, { 'content-type': 'application/json' });
    res.end();
  });
  up.end(buf);
}

http.createServer((req, res) => {
  const route = routeFor(req);
  if (!route) return deny(req, res, 403, 'not on the allowlist');
  if (!KEY) return deny(req, res, 503, 'proxy has no ANTHROPIC_API_KEY');
  if (++count > MAX_REQUESTS) return deny(req, res, 429, `request cap ${MAX_REQUESTS} reached`);
  if (tokensIn + tokensOut > MAX_TOKENS_TOTAL) return deny(req, res, 429, `token cap ${MAX_TOKENS_TOTAL} reached`);

  const bad = [];
  for (const [k, v] of Object.entries(req.headers)) {
    const lk = k.toLowerCase();
    if (lk === 'anthropic-beta') {
      for (const b of String(v).split(',').map((s) => s.trim()).filter(Boolean)) if (!BETAS.has(b)) bad.push(b);
    }
  }
  if (bad.length) return deny(req, res, 400, `anthropic-beta value(s) not allowed: ${bad.join(',').slice(0, 120)}`);

  const chunks = []; let sent = 0, aborted = false;
  req.on('data', (c) => { sent += c.length; if (sent > MAX_BODY) { aborted = true; req.destroy(); } else chunks.push(c); });
  req.on('aborted', () => { if (!res.headersSent) deny(req, res, 413, 'body too large'); });
  req.on('end', () => {
    if (aborted) return;
    const buf = Buffer.concat(chunks);
    const v = validateBody(route, buf);
    if (!v.ok) return deny(req, res, 400, v.why);
    const headers = { 'content-length': String(buf.length) };
    for (const [k, val] of Object.entries(req.headers)) if (!DROP.has(k.toLowerCase())) headers[k] = val;
    headers['x-api-key'] = KEY;
    forward(req, res, buf, headers);
  });
}).listen(8080, '0.0.0.0', () => log({ listening: 8080, upstream: UPSTREAM === 'echo' ? 'echo' : new URL(UPSTREAM).host, max_tokens_total: MAX_TOKENS_TOTAL }));

function summary(sig) {
  log({ summary: true, signal: sig, requests, denials, total_input_tokens: tokensIn, total_output_tokens: tokensOut });
  process.exit(0);
}
process.on('SIGTERM', () => summary('SIGTERM'));
process.on('SIGINT', () => summary('SIGINT'));
