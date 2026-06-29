<!--
SESSION-STATE — the harness's live external-state doc (AgenticOS / NORTH_STAR Lever 3).

WHY: a model's context is finite and compresses over a long session, so settled
facts drift and get re-derived (the failure NORTH_STAR targets). This file is the
durable copy. Hooks re-surface it so awareness survives compaction:
  - SessionStart  → injects this whole file at the top of every session
  - UserPromptSubmit → injects a compact digest (Constraints + Decisions + Open threads) each turn
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
<!-- Hard rules in force this session. Highest-value: re-injected EVERY turn.
     Quick start (Cursor): session-state.sh init-orchestrator — see docs/cursor-orchestrator-gap.md -->
- <!-- e.g. No Python in generated code — Rust only -->
- <!-- Orchestrator (init-orchestrator): main thread must not Write/StrReplace/Delete for implementation — dispatch Task(engineer|domain specialist) -->
- <!-- Orchestrator: research >2 reads/greps on main thread forbidden — dispatch Task(explore|generalPurpose) -->
- <!-- Orchestrator: skills identified on main thread; multi-step skill workflows run in dispatched subagents only -->
- <!-- Orchestrator: complete = Task(code-reviewer) + Task(security-reviewer) parallel readonly on diff before saying done; library-reviewer when skills/agents change -->

## Decisions
<!-- Settled decisions, so they are not re-litigated. Helper stamps the date. Re-injected each turn alongside Constraints. -->
- <!-- e.g. [2026-06-19] Awareness mechanisms use deterministic hooks, not prompt rules -->

## Existing infrastructure
<!-- Survey-before-act results: what already exists, so it is reused not rebuilt.
     Entries use [surveyed:name] — the writer auto-prefixes from the first token
     of /state infra text. The guard suppresses only when a command names that exact
     surveyed subject as a whole token. Plain [name] or free-text does NOT suppress. -->
- <!-- e.g. [surveyed:rabbitmq] broker already running on :5552 (docker-compose at repo root) -->

## Open threads
<!-- In-flight items / next steps. Re-injected each turn alongside Constraints. -->
- <!-- e.g. Confirm PreCompact live-fire as Slice 1's first task -->
