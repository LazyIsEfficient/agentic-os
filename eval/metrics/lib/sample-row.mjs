#!/usr/bin/env node
// sample-row.mjs — build ONE samples.jsonl row for run-release-arms.sh. Values
// come from the environment (never a shell-built JSON string). The auth VALUE
// is never an input here.
//
// Trust model: the PROXY log is authoritative (the proxy is outside the
// model's reach) for tokens, and for the proxy-derived cost estimate. The CLI
// result record (LOG) and the transcript metrics (SCORE_JSON) are
// MODEL-WRITABLE and advisory; a disagreement with the proxy is flagged, not
// trusted. A stop is read from STRUCTURED fields only, never by regex over
// free text.
//
//   SCORE_JSON   score-sample.mjs output (metrics, exploit, scan, transcript_*)
//   LOG          the sample's redacted claude log
//   PROXY_LOG    the sample's redacted proxy log (docker sandbox; absent in none)
//   PRICE_IN_PER_MTOK / PRICE_OUT_PER_MTOK  USD per 1e6 tokens (UNVERIFIED)
import { existsSync, readFileSync } from 'node:fs';

const e = process.env;
const readJson = (p) => {
  if (!p || !existsSync(p)) return null;
  try { return JSON.parse(readFileSync(p, 'utf8')); } catch { return null; }
};
const num = (x) => (typeof x === 'number' && Number.isFinite(x) ? x : null);

const exitCodes = (e.EXIT_CODES || '').split(' ').filter(Boolean).map(Number);
const firstNonzero = exitCodes.find((c) => c !== 0);
const prompts = Number(e.PROMPTS);
const score = readJson(e.SCORE_JSON) || {};
const metrics = score.metrics && typeof score.metrics === 'object' ? score.metrics : null;

// ── CLI result records (LOG) — advisory. Parse only lines that are a single
// JSON object with type==="result"; a free-text answer is never a result. ──
const cliResults = [];
if (e.LOG && existsSync(e.LOG)) {
  for (const line of readFileSync(e.LOG, 'latin1').split('\n')) {
    const s = line.trim();
    if (!s.startsWith('{') || !s.endsWith('}')) continue;
    let o; try { o = JSON.parse(s); } catch { continue; }
    if (o && o.type === 'result') cliResults.push(o);
  }
}
let cliCost = null;
for (const r of cliResults) { const c = num(r.total_cost_usd); if (c !== null && c >= 0) cliCost = (cliCost || 0) + c; }
// ADVISORY stop indicators: the CLI log and the transcript are model-writable.
// They DO mark a row incomplete (see below), which a model can only use to drop
// its OWN sample; listed separately in advisory_stop_signals. Read from the
// LAST result's structured fields only, never by regex over free text.
const advisorySignals = [];
const last = cliResults[cliResults.length - 1];
if (last) {
  if (last.is_error === true) advisorySignals.push(`cli result is_error (${String(last.subtype || 'error').slice(0, 60)})`);
  else if (last.subtype && last.subtype !== 'success') advisorySignals.push(`cli result subtype ${String(last.subtype).slice(0, 60)}`);
}
for (const s of Array.isArray(score.transcript_error_results) ? score.transcript_error_results : []) {
  advisorySignals.push(`transcript error result (${s})`);
}
// AUTHORITATIVE stop signals: host-observed exit codes (handled below),
// interrupt, and the proxy (outside the model's reach).
const stopSignals = [];

// ── PROXY log — AUTHORITATIVE. Prefer the final {summary:true} line; else the
// max running totals seen. 429 token/request caps are a stop. ──
let proxy = null;
if (e.PROXY_LOG && existsSync(e.PROXY_LOG)) {
  let inTok = 0, outTok = 0, denied429 = null, sawSummary = false, requests = 0, denials = 0;
  for (const line of readFileSync(e.PROXY_LOG, 'latin1').split('\n')) {
    const s = line.trim();
    if (!s.startsWith('{')) continue;
    let o; try { o = JSON.parse(s); } catch { continue; }
    if (!o) continue;
    if (o.summary === true) {
      sawSummary = true;
      inTok = num(o.total_input_tokens) ?? inTok;
      outTok = num(o.total_output_tokens) ?? outTok;
      requests = num(o.requests) ?? requests;
      denials = num(o.denials) ?? denials;
    } else {
      if (num(o.total_input) !== null) inTok = Math.max(inTok, o.total_input);
      if (num(o.total_output) !== null) outTok = Math.max(outTok, o.total_output);
      if (o.status === 429) denied429 = String(o.denied || '429');
    }
  }
  proxy = { seen: true, summary: sawSummary, input_tokens: inTok, output_tokens: outTok, requests, denials };
  if (denied429) { proxy.denied_429 = denied429; stopSignals.push(`proxy 429: ${denied429}`); }
}

// ── Primary tokens + cost: proxy when present, else the CLI result (flagged). ──
const priceIn = num(Number(e.PRICE_IN_PER_MTOK));
const priceOut = num(Number(e.PRICE_OUT_PER_MTOK));
let tokens = null, cost = null, costSource = null, costMismatch = null;
if (proxy && proxy.seen) {
  tokens = { input: proxy.input_tokens, output: proxy.output_tokens, source: 'proxy' };
  if (priceIn !== null && priceOut !== null) {
    cost = Math.round((proxy.input_tokens / 1e6 * priceIn + proxy.output_tokens / 1e6 * priceOut) * 1e6) / 1e6;
    costSource = 'proxy-estimate';
    if (cliCost !== null) costMismatch = Math.round((cliCost - cost) * 1e6) / 1e6;
  } else if (cliCost !== null) {
    cost = cliCost; costSource = 'cli-fallback';
  }
} else if (cliCost !== null) {
  cost = cliCost; costSource = 'cli-only';
}

if (e.INTERRUPTED === '1') stopSignals.push('interrupted');
// Advisory CLI/transcript indicators also mark incomplete (a limit stop the
// operator must exclude). A model forging them can only drop its OWN sample;
// it cannot forge "complete" (exit codes are host-observed) or forge low
// tokens/cost (proxy-authoritative).
const allSignals = [...new Set([...stopSignals, ...advisorySignals])];
let incompleteReason = null;
if (stopSignals.includes('interrupted')) incompleteReason = `interrupted (${exitCodes.length} of ${prompts} prompts ran)`;
else if (firstNonzero !== undefined) incompleteReason = `prompt ${exitCodes.indexOf(firstNonzero) + 1} of ${prompts} exited ${firstNonzero}`;
else if (exitCodes.length !== prompts) incompleteReason = `${exitCodes.length} of ${prompts} prompts ran`;
else if (allSignals.length) incompleteReason = `stopped: ${allSignals[0]}`;
else if (!metrics) incompleteReason = 'no transcript metrics';
const uniqueSignals = allSignals;

let exploit = null, exploitDetail = null;
if (score.exploit) {
  const x = score.exploit.json;
  if (x && ['pass', 'fail', 'error'].includes(x.exploit)) {
    exploit = x.exploit;
    const { exploit: _, ...rest } = x;
    exploitDetail = { exit: Number(score.exploit.rc), ...rest };
  } else {
    exploit = 'error';
    exploitDetail = { exit: Number(score.exploit.rc), reason: 'exploit check produced no verdict' };
  }
}

let scan = null;
if (score.scan) {
  const s = score.scan.json;
  scan = { exit: Number(score.scan.rc) };
  if (s && Array.isArray(s.scanners)) {
    scan.gitleaks = 'unavailable';
    scan.semgrep = 'unavailable';
    for (const sc of s.scanners) scan[sc.name] = sc.status === 'ran' || sc.status === 'findings' ? (sc.findings || []).length : sc.status;
  } else {
    scan.error = 'security-scan.sh produced no JSON report';
  }
}

process.stdout.write(JSON.stringify({
  run_id: e.RUN_ID,
  recorded_utc: new Date().toISOString(),
  harness_sha: e.HARNESS_SHA,
  harness_dirty: e.HARNESS_DIRTY === 'true',
  sandbox: e.SANDBOX,
  arm: e.ARM,
  ref: e.REF,
  flags: (e.FLAGS || '').split(',').filter(Boolean),
  repo_sha: e.REPO_SHA,
  scenario: e.SCENARIO,
  prompts,
  prompts_run: exitCodes.length,
  status: incompleteReason ? 'incomplete' : 'complete',
  incomplete_reason: incompleteReason,
  stop_signals: uniqueSignals,
  sample: Number(e.SAMPLE),
  order: Number(e.ORDER),
  session_id: e.SID,
  exit_code: firstNonzero === undefined ? 0 : firstNonzero,
  exit_codes: exitCodes,
  tokens,
  cost_usd: cost,
  cost_source: costSource,
  cli_cost_usd: cliCost,
  cost_mismatch_usd: costMismatch,
  proxy,
  transcript_found: score.transcript_found === true,
  metrics,
  metrics_trust: 'model-writable (advisory)',
  compact_boundaries: typeof score.compact_boundaries === 'number' ? score.compact_boundaries : null,
  advisory_stop_signals: [...new Set(advisorySignals)],
  task_base: e.TASK_BASE || null,
  exploit,
  exploit_detail: exploitDetail,
  scan,
}) + '\n');
