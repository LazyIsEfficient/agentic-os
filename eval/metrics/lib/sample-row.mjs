#!/usr/bin/env node
// sample-row.mjs — build ONE samples.jsonl row for run-release-arms.sh. Values
// come from the environment (never from a shell-built JSON string). Scores come
// from SCORE_JSON, the output of score-sample.mjs; LOG is the sample's
// (redacted) claude log. A missing or unparseable input becomes null or an
// explicit error. The auth VALUE is never an input here.
import { existsSync, readFileSync } from 'node:fs';

const e = process.env;
const readJson = (p) => {
  if (!p || !existsSync(p)) return null;
  try { return JSON.parse(readFileSync(p, 'utf8')); } catch { return null; }
};

// One exit code per prompt that ran; the harness stops a sample at the first
// non-zero exit, so fewer codes than prompts means the sample stopped early.
const exitCodes = (e.EXIT_CODES || '').split(' ').filter(Boolean).map(Number);
const firstNonzero = exitCodes.find((c) => c !== 0);
const prompts = Number(e.PROMPTS);
const score = readJson(e.SCORE_JSON) || {};
const metrics = score.metrics && typeof score.metrics === 'object' ? score.metrics : null;

// Stop signals: an invocation can stop on a limit and still exit 0. Any of
// these marks the sample incomplete. The wording of the CLI's stop lines and
// the result-record shape are UNVERIFIED against the real CLI.
const stopSignals = [];
let costUsd = null;
if (e.LOG && existsSync(e.LOG)) {
  for (const line of readFileSync(e.LOG, 'latin1').split('\n')) {
    if (/Exceeded USD budget/i.test(line)) stopSignals.push('budget stop line in log');
    if (/Reached max turns/i.test(line)) stopSignals.push('max-turns stop line in log');
    if (!line.startsWith('{')) continue;
    let o; try { o = JSON.parse(line); } catch { continue; }
    if (!o || o.type !== 'result') continue;
    if (o.is_error === true) stopSignals.push(`error result in log: ${String(o.subtype || 'error').slice(0, 80)}`);
    if (typeof o.total_cost_usd === 'number') costUsd = (costUsd || 0) + o.total_cost_usd;
  }
}
for (const s of Array.isArray(score.transcript_error_results) ? score.transcript_error_results : []) {
  stopSignals.push(`error result in transcript: ${s}`);
}
const uniqueSignals = [...new Set(stopSignals)];

let incompleteReason = null;
if (firstNonzero !== undefined) {
  incompleteReason = `prompt ${exitCodes.indexOf(firstNonzero) + 1} of ${prompts} exited ${firstNonzero}`;
} else if (exitCodes.length !== prompts) {
  incompleteReason = `${exitCodes.length} of ${prompts} prompts ran`;
} else if (uniqueSignals.length) {
  incompleteReason = `stopped: ${uniqueSignals[0]}`;
} else if (!metrics) {
  incompleteReason = 'no transcript metrics';
}

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

// Per scanner: finding count when it ran, else its status (unavailable / error).
let scan = null;
if (score.scan) {
  const s = score.scan.json;
  scan = { exit: Number(score.scan.rc) };
  if (s && Array.isArray(s.scanners)) {
    scan.gitleaks = 'unavailable';
    scan.semgrep = 'unavailable';
    for (const sc of s.scanners) {
      scan[sc.name] = sc.status === 'ran' || sc.status === 'findings' ? (sc.findings || []).length : sc.status;
    }
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
  cost_usd: costUsd === null ? null : Math.round(costUsd * 1e6) / 1e6,
  transcript_found: score.transcript_found === true,
  metrics,
  compact_boundaries: typeof score.compact_boundaries === 'number' ? score.compact_boundaries : null,
  task_base: e.TASK_BASE || null,
  exploit,
  exploit_detail: exploitDetail,
  scan,
}) + '\n');
