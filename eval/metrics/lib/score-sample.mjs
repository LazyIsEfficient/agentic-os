#!/usr/bin/env node
// score-sample.mjs — score ONE finished sample: transcript metrics, the
// scenario's exploit check and security-scan. Prints one JSON object.
//
// All scoring code comes from <harness> (a copy staged from the HEAD export;
// in the docker sandbox it is baked into the image, root-owned, on a read-only
// root fs). From the sample it reads only two things, as DATA: the task tree
// and the session transcript. Neither is executed by this process; the exploit
// check runs the task's app in a child process (as --app-uid when given, so it
// cannot touch this process or its files).
//
// Usage: node score-sample.mjs --root <sample root> --sid <session id>
//          --scenario <name> --harness <dir> --work <empty dir>
//          [--app-uid N] [--emit-transcript]
// <sample root> has home/.claude/projects/*/<sid>.jsonl and task/.
import { spawnSync } from 'node:child_process';
import { closeSync, constants as C, existsSync, fstatSync, lstatSync, mkdirSync, openSync, readdirSync, readFileSync, readSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const arg = (k) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : undefined; };
const root = arg('--root'), sid = arg('--sid'), scenario = arg('--scenario'), harness = arg('--harness'), work = arg('--work');
const appUid = arg('--app-uid');
const emitTranscript = process.argv.includes('--emit-transcript');
if (!root || !sid || !scenario || !harness || !work) {
  console.error('usage: score-sample.mjs --root R --sid S --scenario NAME --harness H --work W [--app-uid N] [--emit-transcript]');
  process.exit(2);
}
if (!/^[0-9a-f-]{36}$/.test(sid) || !/^[a-z0-9][a-z0-9_-]*$/.test(scenario)) { console.error('bad sid or scenario'); process.exit(2); }

const TRANSCRIPT_CAP = 50 * 1024 * 1024;
const out = {
  transcript_found: false, transcript_truncated: false, metrics: null, compact_boundaries: null,
  transcript_error_results: [], exploit: null, scan: null,
};

// Transcript: <root>/home/.claude/projects/<dir>/<sid>.jsonl, every component
// a real dir / regular file (no symlinks), read through O_NOFOLLOW, capped.
function findTranscript() {
  const projects = path.join(root, 'home', '.claude', 'projects');
  for (const p of [path.join(root, 'home'), path.join(root, 'home', '.claude'), projects]) {
    try { if (!lstatSync(p).isDirectory()) return null; } catch { return null; }
  }
  for (const d of readdirSync(projects).sort()) {
    const dir = path.join(projects, d);
    if (!lstatSync(dir).isDirectory()) continue;
    const f = path.join(dir, `${sid}.jsonl`);
    try { if (lstatSync(f).isFile()) return f; } catch { /* absent */ }
  }
  return null;
}
mkdirSync(work, { recursive: true });
const src = findTranscript();
const tx = path.join(work, 'transcript.jsonl');
if (src) {
  const fd = openSync(src, C.O_RDONLY | C.O_NOFOLLOW);
  try {
    const size = fstatSync(fd).size;
    const buf = Buffer.alloc(Math.min(size, TRANSCRIPT_CAP));
    let off = 0;
    while (off < buf.length) {
      const n = readSync(fd, buf, off, buf.length - off, off);
      if (n <= 0) break;
      off += n;
    }
    writeFileSync(tx, buf.subarray(0, off));
    out.transcript_found = true;
    out.transcript_truncated = size > TRANSCRIPT_CAP;
  } finally { closeSync(fd); }
}

if (out.transcript_found) {
  const { computeMetrics } = await import(pathToFileURL(path.join(harness, 'session-metrics.mjs')).href);
  out.metrics = computeMetrics(tx);
  out.compact_boundaries = 0;
  for (const line of readFileSync(tx, 'utf8').split('\n')) {
    if (!line) continue;
    let o; try { o = JSON.parse(line); } catch { continue; }
    // UNVERIFIED record shapes: compaction boundary, and an error result record.
    if (o && o.subtype === 'compact_boundary') out.compact_boundaries++;
    if (o && o.type === 'result' && o.is_error === true) out.transcript_error_results.push(String(o.subtype || 'error').slice(0, 80));
  }
  if (emitTranscript) out.transcript = readFileSync(tx, 'latin1');
}

const check = path.join(harness, 'scenarios', scenario, 'exploit-check.mjs');
if (existsSync(check)) {
  // Copy the task as data: owned by this process (--no-same-owner), every .git
  // dropped, links kept as links (the exploit check rejects them).
  const task = path.join(work, 'task');
  mkdirSync(task);
  const cp = spawnSync('sh', ['-c', 'cd "$1" && tar -cf - --exclude=.git . | (cd "$2" && tar -xf - --no-same-owner)', 'sh', path.join(root, 'task'), task], { stdio: ['ignore', 'ignore', 'pipe'] });
  if (cp.status !== 0) {
    out.exploit = { rc: 2, json: { exploit: 'error', reason: 'could not copy the task dir' } };
    out.scan = { rc: 2, json: null };
  } else {
    const xtmp = path.join(work, 'xtmp'); mkdirSync(xtmp);
    const env = { PATH: process.env.PATH, HOME: xtmp, TMPDIR: xtmp };
    if (appUid) env.EXPLOIT_APP_UID = appUid;
    const x = spawnSync(process.execPath, [check, task, '--json'], { env, encoding: 'utf8', timeout: 180000, maxBuffer: 1 << 20 });
    let xj = null;
    try { xj = JSON.parse(String(x.stdout).trim().split('\n').pop()); } catch { xj = null; }
    out.exploit = { rc: x.status === null ? 2 : x.status, json: xj };

    const s = spawnSync('bash', [path.join(harness, 'lib', 'scan-task.sh'), task, path.join(harness, 'scenarios', scenario, 'app'), path.join(work, 'scan'), path.join(harness, 'scanner')],
      { env: { PATH: process.env.PATH }, encoding: 'utf8', timeout: 900000, maxBuffer: 64 << 20 });
    let sj = null;
    try { sj = JSON.parse(String(s.stdout).trim()); } catch { sj = null; }
    out.scan = { rc: s.status === null ? 2 : s.status, json: sj, stderr: String(s.stderr || '').slice(-2000) };
  }
}

process.stdout.write(JSON.stringify(out) + '\n');
