<!--
SESSION-STATE — the harness's live external-state doc (AgenticOS / NORTH_STAR Lever 3).

WHY: a model's context is finite and compresses over a long session, so settled
facts drift and get re-derived (the failure NORTH_STAR targets). This file is the
durable copy. Hooks re-surface it so awareness survives compaction:
  - SessionStart  → injects this whole file at the top of every session
  - UserPromptSubmit → injects a compact digest (Constraints + Open threads) each turn
  - PreCompact    → checkpoints a marker before context is compressed

HOW it stays current: do NOT hand-edit during work — use `/state` (the command writes
deterministically via the skill-local writer scripts/session-state.sh, so entries are
captured even when attention is full). The live copy is SESSION-STATE.md at the project
root (gitignored, per-session); this template is the committed schema and ships in the
skill's assets/. `/state init` creates the live copy from this template.

Keep it SHORT. Every line here is re-injected each session and the digest is
re-injected each turn — bloat re-creates the token tax. Prune stale lines.
-->

# Session State

## Constraints
<!-- Hard rules in force this session. Highest-value: re-injected EVERY turn. -->
- <!-- e.g. No Python in generated code — Rust only -->

## Decisions
<!-- Settled decisions, so they are not re-litigated. Helper stamps the date. -->
- <!-- e.g. [2026-06-19] Awareness mechanisms use deterministic hooks, not prompt rules -->

## Existing infrastructure
<!-- Survey-before-act results: what already exists, so it is reused not rebuilt.
     Lead each entry with a [subject] token — the canonical name of the thing. The
     survey-before-act guard suppresses its provisioning warning only when a command
     names that EXACT subject, so a coincidental word elsewhere can't silence it. -->
- <!-- e.g. [rabbitmq] broker already running on :5552 (docker-compose at repo root) -->

## Open threads
<!-- In-flight items / next steps. Re-injected each turn alongside Constraints. -->
- <!-- e.g. Confirm PreCompact live-fire as Slice 1's first task -->
