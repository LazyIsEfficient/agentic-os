# Prompt-cache hygiene: keep the shipped prefix byte-stable

Part of the v4 token-efficiency milestone (issue #235). This note states the
caching rules the library ships under, and points at what enforces them.

## The stable prefix (cache layer 2)

Every request Claude Code sends is assembled in layers. The **stable prefix** is
the part that does not change turn-to-turn: the system prompt, the loaded
`CLAUDE.md`, and the skill/agent prose the harness injects
(`.claude/skills/*/SKILL.md`, `.claude/agents/*.md`). The provider prompt-caches
this prefix so it is tokenized and charged once, then reused across every turn of
the session at a fraction of the cost.

The cache keys on **bytes**. A byte-identical prefix is a cache hit. If any byte
in that prefix differs from the previous request, the cache entry for everything
from the first changed byte onward is invalidated, and the model re-tokenizes the
tail of the prefix from scratch — every turn, for the whole session.

So the rule for anything that lands in the prefix:

> Shipped prose must be **byte-stable**. No value that changes per session or per
> run may be baked into `CLAUDE.md`, a `SKILL.md`, or an agent `.md`.

Volatile content to keep OUT of shipped prose:

- a hardcoded "now" **timestamp** with a time-of-day (`2026-07-16T14:30:05Z`) —
  reads as `now()`, drifts every session;
- a per-run / per-session / correlation **id** (a UUID);
- a **template placeholder** that a build step or hook fills at load time
  (`{{TODAY}}`, `$(date ...)`, `${SESSION_ID}`, `%DATE%`).

A **bare ISO date** used as a *formatting example* (`"Thursday"` -> `2026-05-14`)
is fine: it is the same bytes every session, so it never busts the cache. When you
genuinely need to *show* a timestamp or id as an example, put it in a fenced code
block or an inline `` `code` `` span — that is the byte-stable, unambiguous form.

## What is safe: the per-turn digest (append, don't mutate)

Time-sensitive state still has to reach the model each turn — but it does so by
**appending after the prefix**, never by editing the prefix.

`.claude/hooks/session-state-digest.sh` runs on `UserPromptSubmit` and injects a
compact digest (Constraints / Decisions / Open threads) with the *current* turn.
Because `UserPromptSubmit` output is attached to the user turn — downstream of the
cached prefix — it does not touch a single byte of the prefix. The prefix stays a
cache hit; the fresh, volatile context rides along after it. That is the pattern:
**volatile context is appended per turn, not embedded in the shipped prose.**

## What voids the cache: mid-session model / effort switches

The warm prefix cache is built for a specific model. Switching the **model**
mid-session (e.g. Sonnet -> Opus) forfeits the cache warmed under the previous
model — the new model starts cold and re-tokenizes the whole prefix. Changing the
**reasoning effort** mid-session can similarly force reprocessing.

Pick the model and effort for a session up front and hold them. If you must
switch, expect the first turn after the switch to pay full prefix cost.

## Enforcement

`scripts/validate.sh` — Invariant 10, tag `cache-hygiene` (Tier 0, deterministic).
It scans the shipped-prose set (`CLAUDE.md`, `.claude/skills/*/SKILL.md`,
`.claude/agents/*.md`), blanks fenced and inline code first (so examples are
exempt), and fails on a full ISO date-time, a UUID, or a volatile template marker
left in the flowing prose. Regression cases live in `scripts/validate-test.sh`
(cases 40-43) and run in CI via `.github/workflows/validate.yml`.
