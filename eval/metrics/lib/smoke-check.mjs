#!/usr/bin/env node
// smoke-check.mjs — the --smoke plumbing checklist for one sample. Everything
// it prints passes through esc() (C0/C1 controls shown as \xNN), because the
// proxy log, CLI log and transcript are partly model-written. The raw key is
// read from the environment and searched for, never printed.
//
//   OUT, TAG, PROMPTS_DIR (the scenario's 1.txt..N.txt), PROMPTS (N),
//   PROBE (smoke_probe result), ANTHROPIC_API_KEY
import { createHash } from 'node:crypto';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import path from 'node:path';

const e = process.env;
const esc = (s) => String(s).replace(/[\u0000-\u0008\u000b-\u001f\u007f-\u009f]/g, (c) => `\\x${c.charCodeAt(0).toString(16).padStart(2, '0')}`);
const say = (s) => process.stdout.write(esc(s) + '\n');
const lines = (p) => (existsSync(p) ? readFileSync(p, 'latin1').split('\n') : []);
const json = (l) => { const s = l.trim(); if (!s.startsWith('{')) return null; try { return JSON.parse(s); } catch { return null; } };
const OUT = e.OUT, TAG = e.TAG;
const proxyLog = path.join(OUT, `proxy-${TAG}.log`), cliLog = path.join(OUT, `claude-${TAG}.log`);
const tx = path.join(OUT, 'transcripts', `${TAG}.jsonl`), samples = path.join(OUT, 'samples.jsonl');
const row = json(lines(samples)[0] || '') || {};

say(`smoke checklist (${TAG}):`);

// 1 — no proxy denial (403 path, 400 beta/model/tool, 429 cap).
const denied = lines(proxyLog).map(json).filter((o) => o && o.denied !== undefined && (!o.cause || o.cause === 'budget')); // model denials and a spent unit budget fail; drain 503s and transient inflight 429s do not
if (!existsSync(proxyLog)) say('  1. proxy log: n/a (sandbox none)');
else if (denied.length) { say(`  1. proxy denials: ${denied.length} — FAIL; add any missing beta/endpoint and re-run:`); for (const o of denied.slice(0, 5)) say(`       ${o.status} ${o.denied}`); }
else say('  1. no proxy denials (no 403, no rejected beta/model/tool): PASS');

// 2 — a parsed CLI result object (not just any metrics).
say(`  2. CLI result record parsed: ${Number(row.cli_results) > 0 ? `PASS (${row.cli_results})` : 'FAIL (no {"type":"result"} object in the log)'}`);

// 3 — the transcript holds a user turn for every prompt sent.
const userText = [];
for (const o of lines(tx).map(json)) {
  if (!o || o.type !== 'user' || !o.message) continue;
  const c = o.message.content;
  if (typeof c === 'string') userText.push(c);
  else if (Array.isArray(c)) for (const b of c) if (b && typeof b.text === 'string') userText.push(b.text);
}
const n = Number(e.PROMPTS) || 0;
const found = [];
for (let i = 1; i <= n; i++) {
  const p = path.join(e.PROMPTS_DIR || '', `${i}.txt`);
  const head = existsSync(p) ? readFileSync(p, 'utf8').trim().slice(0, 40) : '';
  found.push(Boolean(head) && userText.some((t) => t.includes(head)));
}
if (!existsSync(tx)) say('  3. transcript NOT saved: FAIL');
else say(`  3. transcript holds a user turn for each prompt (${found.filter(Boolean).length}/${n}): ${n && found.every(Boolean) ? 'PASS' : 'FAIL'}`);

// 4 — CLI cost vs proxy, per call and cumulative.
const cliCosts = lines(cliLog).map(json).filter((o) => o && o.type === 'result').map((o) => o.total_cost_usd);
const ends = lines(proxyLog).map(json).filter((o) => o && o.phase === 'end');
say(`  4. CLI total_cost_usd per call: [${cliCosts.join(', ')}] (sum ${cliCosts.reduce((s, x) => s + (Number(x) || 0), 0)}, last ${cliCosts[cliCosts.length - 1]}; whether it is per call or a running total on --resume is UNVERIFIED — compare with the proxy)`);
say(`     proxy per call: [${ends.map((o) => `${o.model}:${JSON.stringify(o.usage)}`).join('; ')}]`);
say(`     proxy cumulative: ${JSON.stringify(row.tokens ? { input: row.tokens.input, cache_read: row.tokens.cache_read, cache_creation: row.tokens.cache_creation, output: row.tokens.output, cap_units: row.tokens.cap_units } : null)}; cost ${row.cost_usd} (${row.cost_source})`);

// 5 — neither the raw key nor its sha256 appears anywhere in OUT.
const key = e.ANTHROPIC_API_KEY || '';
const hash = key ? createHash('sha256').update(key).digest('hex') : '';
let hit = false;
const walk = (d) => {
  for (const name of readdirSync(d)) {
    const p = path.join(d, name); const st = statSync(p);
    if (st.isDirectory()) walk(p);
    else if (st.isFile()) { const s = readFileSync(p, 'latin1'); if ((key && s.includes(key)) || (hash && s.includes(hash))) hit = true; }
  }
};
if (key) walk(OUT);
say(`  5. raw key and its sha256 absent from OUT: ${!key ? 'n/a (no key)' : hit ? 'FAIL' : 'PASS'}`);

say(`  6. web_search probe through the proxy: ${e.PROBE || 'unrun'}`);
say('  7. Ctrl-C handling: MANUAL — send SIGINT mid-run; the run must stop, the running sample be marked incomplete (interrupted), and summary.json still be written.');
