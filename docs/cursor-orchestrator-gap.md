# Cursor orchestrator gap — activation guide

**Problem:** `install-cursor.sh` ships `subagent-dispatch.mdc` with `alwaysApply: true`, and Agent mode exposes the `Task` tool — yet the main agent often implements and debugs **inline** anyway. Rules alone are **Tier 2** (steer); nothing hard-blocks main-thread `Write`/`StrReplace`. The result is context bloat, repeat reads, and token burn from bug-hunter loops on the parent thread.

**This guide closes the gap** with layered reinforcement: rules + User Rules + session-state constraints + measurement. Full activation checklist below.

**Related:** [subagent-dispatch.mdc](../.cursor/rules/subagent-dispatch.mdc) · [awareness harness](awareness-harness-activation.md) · [session-state skill](../.claude/skills/session-state/SKILL.md) · [eval/metrics orchestration signals](../eval/metrics/README.md)

---

## Why rules are not enough

| Layer | What it does | Tier |
|---|---|---|
| `~/.cursor/rules/subagent-dispatch.mdc` | Steers orchestrator behavior | Tier 2 — advisory |
| Project `AGENTS.md` | Short reinforcement when present | Tier 2 |
| Cursor **User Rules** (Skills + Orchestration blocks) | Global stickiness across projects | Tier 2 |
| **SESSION-STATE constraints** | Re-injected **every turn** via digest hook | Tier 2 — higher salience |
| `session-metrics-cursor.mjs` `orchestration_signals` | Count `Task` vs edit tools in transcripts | Tier 0 — measurement |
| Future: `PreToolUse` / transcript lint gate | Block or warn on inline impl | Tier 0/1 — not shipped yet |

Dispatch doctrine is real; **compliance is stochastic** until encoded in Tier 0/1 checks (see [review-tiers](../.cursor/rules/review-tiers.mdc) ratchet).

---

## Activation checklist (Cursor)

### 1. Global install (once)

```bash
curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.4.0/install-cursor.sh | bash
# or from clone:
./install-cursor.sh --force
```

Confirm `~/.cursor/rules/subagent-dispatch.mdc` exists. **Restart Cursor** after install so custom agents appear in `Task` `subagent_type`.

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
3. Encode: extend `session-metrics-cursor.mjs` thresholds, or add a `PreToolUse` warn hook (future).

See [NORTH_STAR.md](../NORTH_STAR.md) lever #1 — token-aware mediator enforcement is on the roadmap; this doc ships the **operator layer** until Tier 0 exists.
