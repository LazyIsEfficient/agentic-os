#!/usr/bin/env node
// api-proxy.mjs — the sample container's ONLY route out (docker sandbox).
// Runs in its own container, on the sample's internal network and an egress
// network. The sample's claude is pointed here with ANTHROPIC_BASE_URL and a
// placeholder key; this proxy strips any client credential and injects the
// real ANTHROPIC_API_KEY, which only this container holds. So the model never
// sees the key, and it can reach nothing but the allowlisted API paths.
//
//   allowlist  POST /v1/messages, POST /v1/messages/count_tokens, GET /v1/models
//              (UNVERIFIED that Claude Code needs nothing else in this setup)
//   cap        PROXY_MAX_REQUESTS per proxy (one proxy per sample; default 400),
//              request bodies capped at 32 MiB
//   upstream   PROXY_UPSTREAM (default https://api.anthropic.com). TEST HOOK:
//              "echo" answers locally with what would have been forwarded
//              (header names and the sha256 of the injected key), no network.
//   log        one JSON line per request on stdout: method, path, status, bytes.
//              Never the key, never headers or bodies.
import http from 'node:http';
import https from 'node:https';
import { createHash } from 'node:crypto';

const KEY = process.env.ANTHROPIC_API_KEY || '';
const UPSTREAM = process.env.PROXY_UPSTREAM || 'https://api.anthropic.com';
const MAX_REQUESTS = Number(process.env.PROXY_MAX_REQUESTS) || 400;
const MAX_BODY = 32 * 1024 * 1024;
const ALLOW = [
  ['POST', /^\/v1\/messages(\?[^#]*)?$/],
  ['POST', /^\/v1\/messages\/count_tokens(\?[^#]*)?$/],
  ['GET', /^\/v1\/models(\?[^#]*)?$/],
];
// Hop-by-hop and credential headers never pass through.
const DROP = new Set(['host', 'x-api-key', 'authorization', 'connection', 'keep-alive', 'proxy-authorization',
  'proxy-connection', 'te', 'trailer', 'upgrade', 'transfer-encoding']);

let count = 0;
const log = (o) => process.stdout.write(JSON.stringify({ t: new Date().toISOString(), ...o }) + '\n');
const pathOnly = (u) => String(u).split('?')[0].slice(0, 200);

function deny(req, res, status, why) {
  log({ method: req.method, path: pathOnly(req.url), status, denied: why });
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ type: 'error', error: { type: 'proxy_denied', message: why } }));
}

http.createServer((req, res) => {
  if (!ALLOW.some(([m, re]) => req.method === m && re.test(req.url))) return deny(req, res, 403, 'not on the allowlist');
  if (++count > MAX_REQUESTS) return deny(req, res, 429, `request cap ${MAX_REQUESTS} reached`);
  if (!KEY) return deny(req, res, 503, 'proxy has no ANTHROPIC_API_KEY');
  if (Number(req.headers['content-length'] || 0) > MAX_BODY) return deny(req, res, 413, 'body too large');

  const headers = {};
  for (const [k, v] of Object.entries(req.headers)) if (!DROP.has(k.toLowerCase())) headers[k] = v;
  headers['x-api-key'] = KEY;

  if (UPSTREAM === 'echo') {
    req.resume();
    req.on('end', () => {
      log({ method: req.method, path: pathOnly(req.url), status: 200, echo: true });
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify({
        echo: true, method: req.method, path: pathOnly(req.url),
        forwarded_header_names: Object.keys(headers).sort(),
        x_api_key_sha256: createHash('sha256').update(headers['x-api-key']).digest('hex'),
      }));
    });
    return;
  }

  const target = new URL(req.url, UPSTREAM);
  const up = https.request(target, { method: req.method, headers }, (ur) => {
    let bytes = 0;
    ur.on('data', (c) => { bytes += c.length; });
    ur.on('end', () => log({ method: req.method, path: pathOnly(req.url), status: ur.statusCode, bytes }));
    res.writeHead(ur.statusCode || 502, ur.headers);
    ur.pipe(res);
  });
  up.on('error', (e) => {
    log({ method: req.method, path: pathOnly(req.url), status: 502, error: e.code || 'upstream error' });
    if (!res.headersSent) res.writeHead(502, { 'content-type': 'application/json' });
    res.end();
  });
  let sent = 0;
  req.on('data', (c) => {
    sent += c.length;
    if (sent > MAX_BODY) { up.destroy(); req.destroy(); }
  });
  req.pipe(up);
}).listen(8080, '0.0.0.0', () => log({ listening: 8080, upstream: UPSTREAM === 'echo' ? 'echo' : new URL(UPSTREAM).host }));
