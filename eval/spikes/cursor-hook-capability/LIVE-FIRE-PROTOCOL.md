# Cursor hook verification (automated)

**Issue context:** [#170](https://github.com/LazyIsEfficient/agentic-os/issues/170)

## Do not run manual Agent-chat repro

The old protocol (open Cursor, run `docker run hello-world`, eyeball whether the agent "noticed" the survey warning) is **retired**. Do not do it. Do not add operator sign-off checklists.

**If you need to verify hooks, run one command:**

```bash
bash eval/spikes/cursor-hook-capability/run-automated.sh
```

Green exit ⇒ ship. Red exit ⇒ fix the failing script named in the output.

---

## What that command runs

| Step | Script | Proves |
|---|---|---|
| 1 | `scripts/session-state-test-cursor.sh` | Cursor JSON hooks for inject / digest / checkpoint |
| 2 | `scripts/survey-guard-test-cursor.sh` | Survey guard warn-first + suppression + warn log |
| 3 | `eval/spikes/cursor-hook-capability/unit-test.sh` | Spike probes + production hook stdout contracts |
| 4 | inline checks in `run-automated.sh` | Digest/inject tokens, survey log line, preCompact side effect |
| 5 | `scripts/install-paths-test.sh` | Skill script dual-path fallback (via `validate-test.sh` case 32) |

**CI:** every PR runs the same scripts — see [`.github/workflows/validate.yml`](../../../.github/workflows/validate.yml).

**Structural gate:** `scripts/validate.sh` includes `check_cursor_rules_frontmatter` (`.mdc` must have `description` + `alwaysApply`) — exercised by `validate-test.sh` cases **4d** and **4e**.

---

## Quick preflight (individual scripts)

```bash
bash scripts/validate.sh
bash scripts/validate-test.sh          # cases 4d/4e: frontmatter; case 32: install-paths
bash scripts/install-paths-test.sh     # PROJ → ~/.cursor/skills → ~/.claude/skills
bash scripts/session-state-test-cursor.sh
bash scripts/survey-guard-test-cursor.sh
bash scripts/block-bad-bash-test-cursor.sh
bash eval/spikes/cursor-hook-capability/unit-test.sh
```

---

## What “verified” means

| Hook | Event | Verified by |
|---|---|---|
| Session inject | `sessionStart` | `session-state-test-cursor.sh` |
| Per-turn digest | `beforeSubmitPrompt` | `session-state-test-cursor.sh` + digest token grep |
| Survey guard | `beforeShellExecution` | `survey-guard-test-cursor.sh` |
| Block bad bash | `beforeShellExecution` | `block-bad-bash-test-cursor.sh` |
| Checkpoint | `preCompact` | side-effect log in `run-automated.sh` |

Green scripts ⇒ hook **contracts** are correct (stdin JSON → stdout JSON, warn-first, log paths, suppression rules).

---

## Out of scope (not a repo gate)

Whether Cursor’s IDE **surfaces** `agent_message` / `additional_context` to the model on every build is **platform behavior** — unverifiable here without a Cursor headless API. If a Cursor release regresses surfacing, file a Cursor bug report.

Forensic one-off operator notes (2026-06) live in [live-fire-evidence-2026-06-23.md](live-fire-evidence-2026-06-23.md) for history only.
