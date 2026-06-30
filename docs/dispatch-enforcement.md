# Dispatch enforcement (Tier 0)

Mechanical enforcement for the [subagent-dispatch](../.cursor/rules/subagent-dispatch.mdc) rule. The rule is advisory doctrine; **these hooks block** the main agent when dispatch is skipped. State lives in a per-session JSON ledger (`.cursor/dispatch-ledger.json`, gitignored).

This is a Cursor hook layer for the agentic-os skills + agents library. It adds three gates:

- **Research gate** — after a threshold of main-thread `Read`/`Grep`/`Glob`/`SemanticSearch` ops without an `explore` Task, deny further research and demand a `Task(subagent_type=explore)`.
- **Impl gate** — deny `Write`/`StrReplace`/`Delete` on a *code path* from the main thread until an implementation `Task` (`engineer`, `rust-engineer`, …) **completes**.
- **Stop gate** — at end of turn, if the git worktree has code/library changes but the required reviewer Tasks have not completed, emit an auto follow-up demanding them (Wave 1 gate DAG), so the runtime agrees with the CI ship-gate.

## Architecture — thin hooks, fat lib

All logic lives in `scripts/lib/`. The scripts under `.cursor/hooks/` are **thin entry scripts**: each one sources the lib, reads the event JSON from stdin, and calls a single `dispatch_gate_handle_<event>` function.

```bash
#!/usr/bin/env bash
set -uo pipefail
ROOT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
source "$ROOT/scripts/lib/dispatch-gate-lib.sh"
input="$(cat)"
dispatch_gate_handle_<event> "$input"
exit 0
```

| Cursor event | Handler (`scripts/lib/dispatch-gate-lib.sh`) | Entry script (`.cursor/hooks/`) | Behavior |
| --- | --- | --- | --- |
| `sessionStart` | `dispatch_gate_handle_session_init` | `dispatch-gate-session-init.sh` | Init ledger; inject orchestrator reminder via `additional_context` |
| `preToolUse` | `dispatch_gate_handle_pre_tool` | `dispatch-gate-pre-tool.sh` (`failClosed`) | Route by `tool_name`: research tool → research gate; write tool → impl gate; else allow |
| `postToolUse` | `dispatch_gate_handle_post_tool` | `dispatch-gate-post-tool.sh` | Track research reads, `Task` dispatches, and write paths in the ledger |
| `beforeReadFile` | `dispatch_gate_handle_before_read` | `dispatch-gate-before-read.sh` (`failClosed`) | Research gate (more reliable than `preToolUse` Read); counts the read once |
| `afterFileEdit` | `dispatch_gate_handle_after_file_edit` | `dispatch-gate-after-file-edit.sh` | Safety net: record ungated main-thread code edits for the stop gate |
| `subagentStop` | `dispatch_gate_handle_subagent_stop` | `dispatch-gate-subagent-stop.sh` | Mark impl/reviewer/documenter Tasks completed |
| `stop` | `dispatch_gate_handle_stop` | `dispatch-gate-stop.sh` | Auto follow-up if code changed but required reviewer Tasks have not completed |

The handler owns ALL branching — by bash `case`/function calls, **never** by spawning a child script. `dispatch_gate_handle_pre_tool` internally calls `dispatch_gate_enforce_research` vs `dispatch_gate_enforce_impl`; `dispatch_gate_handle_post_tool` internally calls `dispatch_gate_track_research` / `dispatch_gate_track_task` / `dispatch_gate_track_write`.

## Hard constraints that shaped the port

`scripts/validate.sh` enforces these mechanically (`check_hook_safety`, `check_hook_parity`, `check_hook_registration`). The port had to satisfy all of them:

1. **No pipe-to-shell in `.cursor/hooks/*.sh` (Invariant 8a).** The hook-safety denylist scans `.cursor/hooks/` only and bans `| bash`, `| sh`, `eval`, `sh -c`, `source <(`, `sh <<`, `base64 -d`, `curl|wget|nc|ssh|…`, `python -c/-m`, `awk system()`, `/dev/tcp`, `sudo`, `chmod 777`, etc. The original implementation routed events with `printf … | bash child.sh` — **forbidden here**. The denylist does **not** scan `scripts/lib/`, so every pipe / process-substitution / `jq` invocation lives in the lib, and the entry scripts stay idiom-free (plain `source "$path"`, `input="$(cat)"`, one function call).
2. **Bare-path hook commands (Invariant 8a shape).** Commands in `.cursor/hooks.json` match `^\.cursor/hooks/<name>.sh$` — a bare path, **no `bash ` prefix**. Scripts therefore carry the `+x` bit (preserved by git and the installer). `assets/consumer/cursor-hooks.json` uses the consumer shape `^hooks/<name>.sh$`.
3. **Parity (Invariant 8c `check_hook_parity`).** `.cursor/hooks.json` and `assets/consumer/cursor-hooks.json` must declare the SAME set of (event, script-basename) pairs. The seven dispatch-gate hooks are registered in BOTH (the `sessionStart` array carries two entries: `session-state-inject` **and** `dispatch-gate-session-init`).
4. **No orphan scripts (Invariant 8c `check_hook_registration`).** Every non-`*-probe.sh` script in `.cursor/hooks/` must be registered in `.cursor/hooks.json`, and every command must resolve to a script on disk. Exactly seven dispatch-gate scripts exist; all seven are registered.

## Path classification

The runtime planner `scripts/lib/dispatch-gate-plan-lib.sh` **mirrors** the CI ship-gate planner `scripts/lib/gate-plan-lib.sh` (driven by `scripts/gate-plan.sh`), so the stop-hook's reviewer demand matches the PR checkboxes. Keep the two in sync.

| Class | Paths | Reviewers (Wave 1 / Wave 2) |
| --- | --- | --- |
| **library** | `.claude/skills/**`, `.claude/agents/**` | code-reviewer, security-reviewer, data-model-documenter, **library-reviewer** |
| **code** | everything not skipped below (e.g. non-`.md` under `scripts/`, `.claude/commands/`, `.claude/workflows/`) | code-reviewer, security-reviewer, data-model-documenter |
| **sensitive** | `install*.sh`/`install*.ps1`, `assets/consumer/**`, `.claude/hooks/**`, `.cursor/hooks/**`, `.cursor/dispatch-gate.json`, `.cursor/hooks.json`, `scripts/lib/dispatch-gate*`, `scripts/dispatch-gate*`, `SECURITY.md`, `scripts/lib/install-hook-settings.sh`, `scripts/validate.sh`, `scripts/validate-test.sh`, `scripts/release.sh`, `.github/workflows/**` | security-reviewer, data-model-documenter |
| **docs / churn (skip)** | `*.md`, `*.mdc`, `LICENSE`, `NOTICE`, `docs/**`, plus churn skipped *before* code classification: `.cursor/dispatch-ledger.json`, `.claude/memory/**`, `eval/metrics/runs/**` | — (no reviewers) |
| **DATA_MODEL.md** | `DATA_MODEL.md` | code-change + **Wave 2 `data-model-verifier`** |

The **impl gate** uses `code_path_prefixes` (`.cursor/dispatch-gate.json`): `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, `.claude/workflows/`, `scripts/`.

`harness_exempt_prefixes` (main-thread edits always allowed, so the gate can maintain itself): `.cursor/hooks/`, `.cursor/dispatch-gate.json`, `.cursor/hooks.json`, `scripts/lib/dispatch-gate`, `scripts/dispatch-gate`, `docs/dispatch-enforcement.md`, `assets/consumer/cursor-hooks.json`, `SESSION-STATE.md`, `.cursor/dispatch-ledger.json`.

## Files

| Path | Role |
| --- | --- |
| `.cursor/hooks.json` | Cursor hook registration (project-level) |
| `assets/consumer/cursor-hooks.json` | Consumer global-install registration (merged into `~/.cursor/hooks.json`) |
| `.cursor/dispatch-gate.json` | Policy (thresholds, subagent types, code/exempt prefixes) — **committed** |
| `.cursor/dispatch-ledger.json` | Per-session state — **gitignored** |
| `.cursor/hooks/dispatch-gate-*.sh` | Seven thin entry scripts (one per event) |
| `scripts/lib/dispatch-gate-lib.sh` | Ledger + policy + lock + deny/allow helpers + per-event handlers |
| `scripts/lib/dispatch-gate-plan-lib.sh` | Changed-path → reviewer-wave classifier (mirrors `gate-plan-lib.sh`) |
| `scripts/dispatch-gate-test.sh` | Tier 0 fixture tests (12 assertions; requires `jq`) |

## Preserved bug-fixes (do not regress)

- **`mkdir` advisory lock** (`dispatch_gate_lock`/`unlock`) wraps every ledger read-modify-write. macOS has no `flock(1)`; parallel `subagentStop` hooks otherwise race and silently drop `completed_reviews`, looping the stop gate forever. Guarded by the "concurrent subagentStop writes are serialized" test.
- **Clean / docs-only worktree → no reviewers.** `dispatch_gate_missing_reviewers_for_worktree` returns *false* (no demand) when nothing changed or the diff is docs-only — `return 1`, not `0`. A `0` would falsely block every clean/Q&A turn.
- **Non-reviewable churn skipped before code classification.** The classifier `continue`s on `.cursor/dispatch-ledger.json`, `.claude/memory/**`, and `eval/metrics/runs/**` *first*, so churn can never be reclassified as code (the library-repo analog of the `*/.godot/*` cache skip).
- **`..`-collapse + case-insensitive prefix matching.** `dispatch_gate_normalize_rel_path` lexically collapses `.`/`..` (so `.cursor/hooks/../../.claude/skills/foo/SKILL.md` cannot masquerade as exempt), and prefix matching is case-folded (macOS APFS is case-insensitive).
- **Documenter completion recorded into `completed_reviews`.** `data-model-documenter` lives in `documenter_subagent_types` but is a Wave 1 required node, so its completion is recorded into `completed_reviews` — otherwise the stop gate demands it forever.
- **Research read counted once.** `beforeReadFile` counts the read; `postToolUse` skips `Read` to avoid double-counting and tripping the threshold early.
- **`generalPurpose` is NOT in `impl_subagent_types`.** It is an explore type only (`explore_subagent_types`), so a `generalPurpose` Task never opens the impl gate.

## Shipping & activation

The layer ships automatically: `install-cursor.sh` vendors `.cursor/hooks/*.sh` into `~/.cursor/hooks/` and merges `assets/consumer/cursor-hooks.json` into `~/.cursor/hooks.json`. In a checkout, the project-level `.cursor/hooks.json` is picked up directly in Agent mode.

The committed policy ships **disabled** (`"enabled": false` in `.cursor/dispatch-gate.json`) so it never surprises a fresh checkout. Flip it to `true` to arm all gates. Emergency off for a single session: set `DISPATCH_GATE_DISABLED=1` in the environment.

Policy knobs (`.cursor/dispatch-gate.json`): `research_read_threshold` (default `3`), `enforce_research_gate` / `enforce_impl_gate` (warn-only when `false` — hooks still track), `stop_hook_enabled`, and the subagent-type lists.

## Tests

```bash
bash scripts/validate.sh             # Tier 0 invariants incl. hook-safety/parity/registration
bash scripts/dispatch-gate-test.sh   # 12 fixture assertions (lib + plan classifier)
```

`scripts/dispatch-gate-test.sh` runs in CI from `.github/workflows/validate.yml` (the `validate` job) and works under macOS bash 3.2 as well as bash 5. It requires `jq` (already a dependency of the session-state hooks).

## Gotcha — `failClosed` hooks must always print

A `preToolUse` / `beforeReadFile` hook with `failClosed: true` that prints **no output** blocks the tool. Every exit path in the handlers prints a `{permission:…}` object (and the entry scripts `exit 0`). When editing the lib, keep the short-circuit braced so the JSON is always emitted:

```bash
# WRONG — emits nothing when jq exists → failClosed blocks everything
dispatch_gate_require_jq || dispatch_gate_allow; return 0
# RIGHT
dispatch_gate_require_jq || { dispatch_gate_allow; return 0; }
```

If you get locked out, disable project hooks in **Cursor Settings → Hooks**, or set `DISPATCH_GATE_DISABLED=1`, then **Developer: Reload Window**.
