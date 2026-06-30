# Cursor orchestrator gap — activation guide

**Problem:** `.cursor/rules/subagent-dispatch.mdc` loads with `alwaysApply: true` when this repo is the Cursor workspace, and Agent mode exposes the `Task` tool — yet the main agent often implements and debugs **inline** anyway. Rules alone are **Tier 2** (steer); a rule does not, by itself, hard-block main-thread `Write`/`StrReplace`. The result is context bloat, repeat reads, and token burn from bug-hunter loops on the parent thread.

**This guide closes the gap** with layered reinforcement: rules + User Rules + session-state constraints + measurement, plus the optional Tier 0/1 dispatch-gate hooks. Full activation checklist below.

**Related:** [subagent-dispatch.mdc](../.cursor/rules/subagent-dispatch.mdc) · [dispatch-enforcement.md](dispatch-enforcement.md) · [awareness harness](awareness-harness-activation.md) · [session-state skill](../.claude/skills/session-state/SKILL.md) · [eval/metrics orchestration signals](../eval/metrics/README.md)

---

## Why rules are not enough

| Layer | What it does | Tier |
|---|---|---|
| Project `.cursor/rules/subagent-dispatch.mdc` | Steers orchestrator behavior (project-local; `alwaysApply: true`) | Tier 2 — advisory |
| Cursor **User Rules** (Skills + Orchestration blocks) | Global stickiness across projects — paste rule text into Cursor settings | Tier 2 |
| Project `AGENTS.md` | Short reinforcement when present | Tier 2 |
| **SESSION-STATE constraints** | Re-injected **every turn** via digest hook | Tier 2 — higher salience |
| `session-metrics-cursor.mjs` `orchestration_signals` | Count `Task` vs edit tools in transcripts | Tier 0 — measurement |
| **Dispatch-gate hooks** (`docs/dispatch-enforcement.md`) | Block/warn on inline impl, research, and stop without dispatch | Tier 0/1 — **available, ships disabled** |

Dispatch doctrine is real; **compliance is stochastic** unless the Tier 0/1 dispatch-gate hooks are enabled (they ship **disabled** by default — see [dispatch-enforcement.md](dispatch-enforcement.md) and the [review-tiers](../.cursor/rules/review-tiers.mdc) ratchet).

---

## Activation checklist (Cursor)

### 1. Rules: project-local or User Rules

Rules in this repo are **project-local**: when this repo is your Cursor workspace, `.cursor/rules/subagent-dispatch.mdc` loads automatically (`alwaysApply: true`). No install step copies rules into `~/.cursor/rules/`.

For **global stickiness** across other projects, paste the rule text into **Cursor Settings → Rules → User Rules** (see step 2). Custom agents and skills are a separate concern: a global install (`./install-cursor.sh --force`) ships agents/skills, and you should **restart Cursor** afterward so custom agents appear in `Task` `subagent_type`.

### 2. User Rules (every machine)

Add **both** blocks to **Cursor Settings → Rules → User Rules** (from [README § Configure Cursor rules](../README.md#configure-cursor-rules--skill-discipline)):

- **Skills + orchestration** — resolve the skills-vs-dispatch conflict (identify skill → brief subagent; do not run multi-step workflows inline).
- Use **Agent mode** for work that should fan out — Ask mode typically lacks `Task`.

### 3. Session-state orchestrator constraints (per long session / project)

Hooks inject Constraints + Decisions + Open threads **each turn** — stronger than a static rule file.

```bash
PROJ="${CURSOR_PROJECT_DIR:-.}"
SS="$PROJ/.claude/skills/session-state/scripts/session-state.sh"
[ -f "$SS" ] || SS="$HOME/.cursor/skills/session-state/scripts/session-state.sh"
bash "$SS" init-orchestrator
```

Or add constraints manually via `bash "$SS" constraint "…"`. Never hand-edit `SESSION-STATE.md`.

### 4. Session-opening prompt (optional, high impact)

First message in a heavy session:

```text
Orchestrator mode only. Do not implement or research on this thread.
First action: Task(prompt-shaper) or Task(engineer) with full brief.
Report subagent IDs and summaries only.
```

### 5. Measure compliance (after a session)

```bash
node eval/metrics/session-metrics-cursor.mjs \
  ~/.cursor/projects/<workspace-slug>/agent-transcripts/<session-id>/<session-id>.jsonl --json
```

Inspect `orchestration_signals`: low `task_dispatches` + high `main_thread_edit_tools` ⇒ orchestrator collapse. Subagent runs live under `.../subagents/<id>.jsonl` (parent transcript may still show zero `Task` if tooling names differ — check both).

### 6. Mechanical enforcement (optional, Tier 0/1)

The dispatch-gate hooks enforce the orchestrator contract mechanically — blocking or warning when the main thread reads/edits/stops without dispatching. They **ship disabled** by default; enable them per the toggles in [dispatch-enforcement.md](dispatch-enforcement.md).

---

## Skills vs dispatch (the conflict)

A common failure mode: User Rules say "load the skill first on the main thread"; the model reads the skill and **executes the whole playbook inline**.

**Correct pattern:**

1. Main thread: identify whether a skill applies (name + one-line routing).
2. Main thread: optional single `Read` of `SKILL.md` for routing only.
3. Dispatch `Task` with the skill procedure copied into the subagent brief.
4. Main thread: integrate subagent summary; run gate DAG reviewers via `Task`.

---

## Trivial-work exception

One-line typo fixes, single-file comment edits, and direct answers to narrow questions may stay on the main thread. Everything else — multi-step implementation, >2–3 reads/greps, library edits — must dispatch.

---

## Ratchet path (contributors)

1. Log recurring "zero Task on multi-step impl session" to [findings-ledger](../.claude/skills/findings-ledger/SKILL.md).
2. On recurrence → investigate.
3. Encode: extend `session-metrics-cursor.mjs` thresholds, or enable/extend the dispatch-gate hooks ([dispatch-enforcement.md](dispatch-enforcement.md)).

See [NORTH_STAR.md](../NORTH_STAR.md) lever #1 — token-aware mediator enforcement is on the roadmap; the dispatch-gate hooks are the Tier 0/1 enforcement layer (shipping disabled), and this guide is the **operator layer** that activates it.
