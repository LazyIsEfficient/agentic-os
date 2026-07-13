# Design spike (T-spike): memory-extraction mechanism, trigger, and post-check

**Status:** decided (pending operator approval at checkpoint `ck-spike`)
**Issue:** #217 — durable-fact encoding is a stochastic in-conversation self-classification step, so facts get dropped.
**Blocks:** `P2a-extractor`, `P2b-hook`, `P3-longitudinal-test`. This doc is the contract those tasks build against; they must not re-decide anything settled here.

A hook is a shell command and cannot run an LLM. This doc decides, with evidence from this repo's live hooks and the official Claude Code hooks reference, **how a deterministic hook drives an LLM extraction pass on the Claude Code harness.**

---

## TL;DR (the five decisions)

| # | Question | Decision |
|---|----------|----------|
| 1 | Transcript access to the hook | Reachable by the **hook** on Claude Code (as `transcript_path`). Irrelevant to the chosen mechanism — the transcript lives in the **agent's** context, not the hook's. |
| 2 | Mechanism | **In-session nudge.** The hook emits a steer object; the still-live main agent (which holds the transcript) runs the `memory-extraction` **skill** as its final act. Reject out-of-band spawn. |
| 3 | Trigger event | **Stop.** Reject PreCompact (cannot steer on Claude; misses short sessions) and SessionEnd (cannot steer). Requires **adding a Claude Code `Stop` hook** — fallout spelled out below. |
| 4 | Did-it-capture post-check | "A durable fact was stated but not saved" is **inherently Tier 2** (it IS the stochastic step). Tier 0 asserts the *plumbing*: hook wired on the right event, fires, exits 0, fail-open, writes land with valid shape + index ≤200 lines, idempotent, cold session surfaces them. |
| 5 | Invocation contract | Skill `memory-extraction` at `.claude/skills/memory-extraction/SKILL.md`; invoked in-session by the main agent (NOT via `Task`); reads the in-context transcript + existing memory; writes append-or-update to `.claude/memory/`. |

The mechanism and event are **not independent choices** — see §2. Given the mechanism is in-session nudge, the event is *forced* to Stop, because Stop is the only agent-steering event that exists on Claude Code.

---

## Evidence base (what was actually read)

Primary evidence is this repo's live, shipping hooks; the official docs fill exactly one gap (Claude Code wires no Stop hook today).

- `.claude/hooks/session-state-checkpoint.sh:6-7,11-14` — Claude PreCompact hook reads `event="$(cat)"`, extracts `trigger`, appends a log line. Its own comment: *"injecting from PreCompact itself depends on its output contract, confirmed as Slice 1's first follow-up"* — i.e. PreCompact injection was **never verified** in-repo.
- `.claude/hooks/session-state-inject.sh:10-12` — SessionStart on Claude: *"Plain stdout reaches Claude for SessionStart"* → prints markdown directly.
- `scripts/validate.sh:786-816` (`check_hook_safety`) — scans `.claude/hooks/` for the shell denylist; enforces command-string *shapes* in `.claude/settings.json` and the consumer manifest. Consumer Claude shape (`:807-810`): `^bash \$HOME/.claude/hooks/<name>.sh$`.
- `install.sh:182-200` — ships `skills/`, `agents/`, ship-tagged `commands/`, `hooks/`, then `merge_claude_hook_settings`. **No `rules/`, no `CLAUDE.md`.**
- **Official Claude Code hooks reference** (`https://code.claude.com/docs/en/hooks`, fetched 2026-07-13): Stop receives `session_id`, `transcript_path`, `cwd`, `last_assistant_message`, and **can block via `{"decision":"block","reason":"…"}`** (agent continues, `reason` fed back). **PreCompact can block compaction but has *no* context-injection / steering output.** SessionEnd receives `transcript_path` but **cannot block or steer** (side-effect only). See UNVERIFIED items for caveats.

---

## 1. Transcript access — what the end-of-session hook actually receives

**Claude Code:** every relevant hook (Stop, PreCompact, SessionEnd) receives `transcript_path` — a filesystem path to the session JSONL — on stdin (official reference). So on Claude the transcript *is* reachable by the hook, as a file.

**Why this settles the mechanism.** The transcript reachable *by the hook* only matters for an **out-of-band spawn** (a separate process that must be *handed* the transcript). The **in-session nudge** needs no transcript access by the hook at all: the transcript already sits in the **main agent's context window**, and the agent runs the extraction. The winning mechanism sidesteps the disk hand-off entirely.

---

## 2. Mechanism — IN-SESSION NUDGE (chosen)

**Decision:** the hook emits a small steer object; the still-live main agent — which holds the full transcript in context — invokes the `memory-extraction` skill as its final act of the turn.

Output contract for the steer — **Claude `Stop`:** `{"decision":"block","reason":"<instruction>"}` — official reference: blocks the stop, feeds `reason` back, agent continues. (`hookSpecificOutput.additionalContext` is an alternative; P2b selects the shape that reliably re-prompts — see UNVERIFIED #4.)

The Stop event fires while the agent is alive with the transcript in context, so the skill runs with full session material and no data hand-off.

**Coupling that P2a/P2b must respect:** because the extractor runs **inside the main agent's context**, it MUST be a **skill**, not a subagent/agent. A `Task(subagent_type=…)` dispatch starts a **cold** agent with none of the parent's transcript — it literally cannot see the session it is meant to extract. This is the decisive reason `P2a` authors `.claude/skills/memory-extraction/SKILL.md`, not `.claude/agents/memory-extractor.md`.

### Rejected: out-of-band spawn
The hook launches a separate `claude -p`/agent process and hands it the transcript. Rejected because:
1. **Fragility + consumer cost.** Spawning a second `claude` requires the CLI on `PATH` and model/API access on the consumer's machine, is slow, and is hard to make **fail-open** cleanly (a spawn that hangs or errors must never block the user's session). The in-session nudge fails open trivially: on any error the hook returns `{}` / allow and the turn completes.
2. **Redundant.** The agent already holds the transcript; re-reading it from disk into a fresh process throws away context we already have in the exact place we need it.

---

## 3. Trigger event — STOP (chosen)

**Decision:** register the extraction hook on **Stop** (Claude `Stop`).

Rationale, in priority order:
1. **Steer capability.** In-session nudge requires an event whose output can steer the live agent. On Claude Code, **Stop is the only such event** — PreCompact and SessionEnd have no steering output (official reference). Choosing in-session nudge (§2) therefore *forces* Stop.
2. **Coverage of short sessions.** Stop fires at the end of **every** assistant turn, so a two-turn session that states one convention and ends is covered. PreCompact only fires when compaction happens — a short session that never compacts would **never** extract (the exact gap flagged in the plan). Stop closes it.
3. **Proactive, not brink-of-loss.** Extracting at turn boundaries persists facts *before* any compaction or session end, rather than racing the context-loss event.

### Consequence to manage: Stop fires every turn
Stop is a per-turn event, not a session-end event, so a naive hook would nudge extraction after *every* turn (token cost + nagging). The hook MUST **self-gate** deterministically:
- Maintain a per-session marker/ledger (e.g. `.claude/memory/.extract/<session_id>` or a small JSON ledger).
- Emit the nudge only when extraction has not run this "epoch" **and** a cheap substance proxy is met (e.g. ≥ N user turns since the last extraction). After the skill runs (or a marker is written), subsequent Stop events return `{}` / allow — this also prevents the infinite Stop-loop.
- The extractor is idempotent (dedup against existing memory), so an occasional double-fire is harmless.

### Adding a Claude Code `Stop` hook — consumer-manifest fallout
This repo wires **no** Claude Stop hook today, so P2b introduces one. Precise fallout:

- New script `.claude/hooks/memory-extract.sh`; `install.sh:193` ships it.
- Register `Stop` in `.claude/settings.json` (dev) **and** `assets/consumer/claude-settings.json` (consumer) — the consumer command must match `^bash \$HOME/.claude/hooks/memory-extract.sh$` (`validate.sh:807-810`), merged by `merge_claude_hook_settings` (`install.sh:200`).
- **No existing validator gates the Claude hook tree for dev↔consumer registration parity.** So nothing stops a Claude Stop hook from being registered in dev but silently omitted from `assets/consumer/claude-settings.json`, shipping consumers a dead mechanism. **P3 MUST add a Tier-0 assertion** that `memory-extract` is registered on `Stop` in both `.claude/settings.json` and `assets/consumer/claude-settings.json` (a small ratchet closing this gap).

### Rejected: PreCompact
- **Cannot steer on Claude.** Official reference: PreCompact can only *block compaction*; it has no context-injection/steering output. So on Claude it literally cannot make the agent run the extraction skill — the chosen mechanism (§2) is impossible on this event. The repo's own PreCompact hook flags injection as unverified (`session-state-checkpoint.sh:6-7`), consistent with the docs.
- **Short-session gap.** Fires only on compaction; quick sessions never extract.
- **Only upside is "already wired,"** which does not outweigh a mechanism that cannot function there.

### Rejected: SessionEnd (Claude)
- Cannot block or steer (official reference: side-effect only) → cannot drive an in-session nudge; would force the rejected out-of-band spawn (§2).

---

## 4. The did-it-capture post-check — Tier-0 vs Tier-2 boundary

**Brutal honesty first:** a purely deterministic (Bash/CLI, no LLM) detector of *"the user stated a durable fact that should have been saved"* is impossible — that classification **is** the stochastic step we are trying to make reliable. Any "did we MISS a fact?" check requires an LLM and is therefore **Tier 2**, validated only by a live dogfood run, never CI-gateable. Do not build a Bash regex that pretends to detect durable facts; it would be a stochastic gate, which this repo's review-tiers rule forbids.

**What IS deterministically assertable (Tier 0 — CI, no live model):**
1. **Registration (static).** `memory-extract.sh` exists in the hook tree; registered on `Stop` in `.claude/settings.json`; present in the consumer manifest. (The **new** Claude-registration assertion from §3 covers this.)
2. **Fires + exits 0 (fixture).** Feed a canned Stop-event JSON to the hook; assert exit 0 and well-formed JSON output (either allow `{}` or a steer object naming the skill), selected by ledger state. Assert the self-gate: with a "marker present" ledger the hook allows completion (no infinite nudge).
3. **Fail-open.** Point the hook at a failing/absent extractor, or feed malformed stdin; assert it still exits 0 and never blocks. Fully deterministic; this is the fail-open guarantee.
4. **Write-shape (fixture writes, not live judgment).** Given a *fixture* set of proposed writes, assert: each `.claude/memory/<slug>.md` has valid frontmatter; `MEMORY.md` gained exactly one index line per new entry; index stayed ≤200 lines; an existing unrelated memory was **not** modified (no-clobber, append-or-update).
5. **Idempotence.** Apply the same fixture writes twice; assert no duplicate index line / no second file.
6. **Cold-session surfacing (fixture).** Given a captured-memory fixture, assert the SessionStart inject path emits that memory's content — proving a "session 2" cold start would see it.

**The line:** Tier 0 / CI proves the **plumbing** — hook wired on the right event, fires, exits 0, fail-open, lands well-formed idempotent writes that a cold session surfaces. Tier 0 / CI **cannot** prove that a live model recognized "the user stated a durable convention" and wrote a faithful memory — that **semantic** step is Tier 2, proven only by the live 2-session dogfood run in `P3`'s runbook (state convention → context reset → confirm applied). `P3`'s test therefore has exactly two layers, and the boundary rule is: **fixtures + no live model = Tier 0 / CI-gating; live-model behavior = Tier 2 / dogfood, never gates CI.**

---

## 5. Invocation contract (build against this — do not re-decide)

| Field | Value |
|-------|-------|
| **Form** | **Skill** (NOT agent/subagent — see §2 coupling). |
| **Name / path** | `memory-extraction` at `.claude/skills/memory-extraction/SKILL.md`. |
| **Invoked by** | The **main agent, in-session**, prompted by the Stop hook's steer text. Never via `Task`. |
| **Routing** | `SKILL.md` `description` must route on the phrase the hook emits (e.g. "persist durable facts from this session" / "run memory-extraction"). |
| **Implicit input** | The current session transcript, already in the invoking agent's context. No argument passing. |
| **Explicit reads** | `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/MEMORY.md` + existing `.claude/memory/*.md` (for dedup). The durable-fact predicate is **inlined** in the skill body — it must NOT depend on `.claude/rules/` or `CLAUDE.md`, which do not ship to consumers (`install.sh:182-200`). |
| **Writes** | One file per durable fact at `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/<slug>.md` with frontmatter (`name`, `description`, `type`); one index line `- [Title](slug.md) — hook` appended/updated in `.claude/memory/MEMORY.md`. |
| **Write semantics** | Append-or-update, **never clobber**; dedup against existing entries; keep `MEMORY.md` ≤200 lines; non-destructive to a consumer's existing memory. |
| **Completion signal** | On completion, refresh a per-session marker/ledger the Stop hook reads, so the hook stops nudging that epoch (loop-safety). |

**Hook contract for P2b:**
- Event: `Stop` (Claude). Script `memory-extract.sh` in `.claude/hooks/`.
- Reads stdin JSON; extracts `session_id` for the ledger key.
- Self-gates on the ledger (§3). When it decides to nudge, emits `{"decision":"block","reason":"…run the memory-extraction skill…"}`; otherwise `{}`/allow.
- **Fail-open on every path** (any error → allow completion, exit 0). Bash + standard CLI only.

---

## UNVERIFIED items for the operator to resolve

1. **`UNVERIFIED`: Claude Stop loop-prevention field.** The fetched reference summary says `stop_hook_active` is not in the current input schema (historically it existed). Design does **not** rely on it — loop-safety comes from the ledger/marker self-gate (§3). P2b should reconfirm against the live harness.
2. **`UNVERIFIED`: exact Claude Stop steer shape.** Official reference shows both `{"decision":"block","reason":…}` and `hookSpecificOutput.additionalContext`. P2b picks the shape that reliably re-prompts the agent to run a skill.
3. **`UNVERIFIED`: consumer memory location.** The extractor targets `${CLAUDE_PROJECT_DIR:-.}/.claude/memory/` (matching the session-state hooks). Whether a consumer's memory should live in their project vs `~/.claude/` is a P2a detail; the default above is consistent with existing hooks.
4. **Source caveat:** the Claude Stop/PreCompact/SessionEnd contract came from a small-model summary of `code.claude.com/docs/en/hooks` after a host redirect. The load-bearing claims (Stop steers; PreCompact cannot inject/steer; SessionEnd cannot block) are corroborated by the repo's own PreCompact comment, but field-level details should be reconfirmed by P2b against the full page / live harness.
