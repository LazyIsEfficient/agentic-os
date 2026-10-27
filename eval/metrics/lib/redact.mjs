#!/usr/bin/env node
// redact.mjs — copy stdin to stdout with the VALUES of the named environment
// variables replaced by "[REDACTED:<NAME>]", and the output capped. Every log
// run-release-arms.sh writes to its output dir goes through this.
//
//   REDACT_VARS       space-separated names (default: ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN)
//   REDACT_CAP_BYTES  output cap (default 50 MiB); the rest is dropped with a marker
//
// Bytes pass through 1:1 (latin1); a secret split across chunks is still caught
// (the last len-1 characters are held back until the next chunk).
const names = (process.env.REDACT_VARS || 'ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN').split(/\s+/).filter(Boolean);
// Values shorter than 8 characters are not secrets worth matching (and would
// shred ordinary text).
const secrets = names.map((n) => [n, process.env[n] || '']).filter(([, v]) => v.length >= 8);
const cap = Number(process.env.REDACT_CAP_BYTES) || 50 * 1024 * 1024;
const keep = secrets.reduce((m, [, v]) => Math.max(m, v.length - 1), 0);

let carry = '';
let written = 0;
let truncated = false;

function scrub(s) {
  for (const [n, v] of secrets) s = s.split(v).join(`[REDACTED:${n}]`);
  return s;
}
function emit(s) {
  if (truncated || !s) return;
  const room = cap - written;
  if (s.length > room) {
    process.stdout.write(Buffer.from(s.slice(0, room), 'latin1'));
    process.stdout.write(`\n[truncated at ${cap} bytes]\n`);
    written = cap;
    truncated = true;
    return;
  }
  process.stdout.write(Buffer.from(s, 'latin1'));
  written += s.length;
}

process.stdin.on('data', (chunk) => {
  const buf = scrub(carry + chunk.toString('latin1'));
  const cut = Math.max(0, buf.length - keep);
  emit(buf.slice(0, cut));
  carry = buf.slice(cut);
});
process.stdin.on('end', () => emit(scrub(carry)));
