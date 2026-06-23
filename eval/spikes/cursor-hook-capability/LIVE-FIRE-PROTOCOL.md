# Cursor hook verification (automated)

**Issue context:** [#170](https://github.com/LazyIsEfficient/agentic-os/issues/170)

**This repo does not gate on manual Cursor UI repro.** Cursor has no headless hook runner for model surfacing; acceptance is **deterministic contract tests only** (Tier 0). Run them locally or rely on CI — never an operator checklist in Agent chat.

---

## Gate (required)

From repo root:

```bash
bash eval/spikes/cursor-hook-capability/run-automated.sh
```

That runs:

| Check | Script |
|---|---|
| Session-state hooks (Cursor JSON) | `scripts/session-state-test-cursor.sh` |
| Survey guard (Cursor JSON) | `scripts/survey-guard-test-cursor.sh` |
| Spike probes + production hooks | `eval/spikes/cursor-hook-capability/unit-test.sh` |
| Digest / inject token emission | inline in `run-automated.sh` |
| Survey warn-log side effect | inline in `run-automated.sh` |
| PreCompact checkpoint side effect | inline in `run-automated.sh` |

**CI:** same scripts run on every PR in [`.github/workflows/validate.yml`](../../../.github/workflows/validate.yml).

---

## What “verified” means

| Hook | Event | Verified by |
|---|---|---|
| Session inject | `sessionStart` | `session-state-test-cursor.sh` + `run-automated.sh` |
| Per-turn digest | `beforeSubmitPrompt` | `session-state-test-cursor.sh` + digest token grep |
| Survey guard | `beforeShellExecution` | `survey-guard-test-cursor.sh` + warn-log assertion |
| Block bad bash | `beforeShellExecution` | `scripts/block-bad-bash-test-cursor.sh` |
| Checkpoint | `preCompact` | side-effect log in `run-automated.sh` |

Green scripts ⇒ hook **contracts** are correct (stdin JSON → stdout JSON, warn-first, log paths, suppression rules).

---

## Out of scope (not a repo gate)

Whether Cursor’s IDE **surfaces** `agent_message` / `additional_context` to the model on every build is **platform behavior** — unverifiable here without a Cursor headless API. We ship correct hooks; CI proves they behave when invoked. If a Cursor release regresses surfacing, that is a Cursor bug report, not a maintainer manual test.

Forensic one-off operator notes (2026-06) live in [live-fire-evidence-2026-06-23.md](live-fire-evidence-2026-06-23.md) for history only — **not** required to merge or release.

---

## Quick preflight (individual scripts)

```bash
bash scripts/validate.sh
bash scripts/session-state-test-cursor.sh
bash scripts/survey-guard-test-cursor.sh
bash scripts/block-bad-bash-test-cursor.sh
bash eval/spikes/cursor-hook-capability/unit-test.sh
```
