# Gate DAG — ship-gate orchestration

Canonical dependency graph for **Pattern 3 — Build + review pairing**. Orchestrators and maintainer commands (`review-gate`) execute this DAG; CI checkbox rules are computed by **`scripts/gate-plan.sh`** and enforced by **`scripts/check-pr-ship-gates.sh`**.

**Epic:** [#189](https://github.com/LazyIsEfficient/agentic-os/issues/189)

This graph is **fixed** (not per-feature). Feature implementation DAGs use [`planning-and-task-breakdown`](../skills/planning-and-task-breakdown/SKILL.md); this DAG runs **after** each implementation task completes.

---

## Execution DAG

```yaml
dag:
  - checkpoint:impl-verified after [local verification]

  # Wave 0 — catalog authoring, then COMMIT (verdicts bind to HEAD; any later
  # commit discards earlier verdicts, so DATA_MODEL.md must land first)
  - T-impl → G-data-document?          # when implementation agent ran; see § Implementation close
  - checkpoint:impl-verified → G-data-document?   # orchestrator only when T-impl did not run G-data-document
  - G-data-document → checkpoint:committed

  # Wave 1 — parallel reviewers on the committed HEAD (wait for all before Wave 2)
  - checkpoint:committed → G-code-review?
  - checkpoint:committed → G-security-review
  - checkpoint:committed → G-library-review?

  # Wave 2 — conditional (DATA_MODEL.md in the committed diff)
  - checkpoint:committed → G-data-verify?

  # Barrier — all required nodes from Waves 0–2 must complete
  - G-code-review?, G-security-review, G-data-document, G-library-review?, G-data-verify? → checkpoint:ship-ready
```

**Syntax:** `→` = must finish before; `||` = may run in parallel; `?` = include only when trigger matches (see below).

---

## Implementation close (`G-data-document`)

When implementation runs through an **implementation agent** (`engineer`, `rust-engineer`, `web3-engineer`, `godot-engineer`, `devops-engineer`, `phaser-engineer`), that agent **must dispatch `data-model-documenter` before returning** — not the orchestrator.

Canonical contract: [implementation-close.md](../skills/data-model-documentation/references/implementation-close.md)

| Who | When | Action |
|---|---|---|
| **Implementation agents** (see above) | After local verification, before completion report | Foreground `Agent` → `data-model-documenter` with changed paths + brief |
| **Orchestrator** | Wave 0 | Run `G-data-document` **only if** no implementation agent ran it (main-thread impl, or completion report lacks `G-data-document:` status) |
| **Orchestrator** | Before Wave 1 | Commit the implementation **and** the documenter's `DATA_MODEL.md` changes |
| **Orchestrator** | Wave 2 | `G-data-verify` when `DATA_MODEL.md` is in the committed diff — always orchestrator-owned |

**Skip** `G-data-document` when the diff is docs-only (same allowlist as path triggers below).

This keeps catalog authoring at the end of the implementation session, committed before any reviewer reads the tree. A reviewer verdict names one HEAD sha. A `DATA_MODEL.md` write after Wave 1 would need a new commit, and that commit discards every Wave 1 verdict (the [Stop gate](#stop-gate-tier-0) only accepts verdicts for the current HEAD).

---

## Checkpoints

### `checkpoint:impl-verified`

Run before any gate agent. Minimum:

- [ ] `bash scripts/validate.sh` on any non-docs-only diff (matches ship-gate entry — not only library paths)
- [ ] Task-specific verification from the implementation brief (tests, build, etc.)

If verification fails, do not dispatch gate agents.

### `checkpoint:ship-ready`

Clears when:

- [ ] Every **required** node (non-`?` or triggered `?`) has returned — for the four verdict-emitting reviewers this is checked mechanically by the [Stop gate](#stop-gate-tier-0) from captured artifacts, not by hand
- [ ] Tier 0/1 findings from gate agents are fixed or explicitly waived
- [ ] Tier 2 findings logged to findings ledger (advisory — do not block alone)
- [ ] PR description checkboxes match dispatched agents (see `.github/pull_request_template.md`)

Only after this checkpoint: mark work **complete**, open/ready PR, merge, tag, release.

---

## Stop gate (Tier 0)

Pattern 3 is enforced by two hooks ([#258](https://github.com/LazyIsEfficient/agentic-os/issues/258)), so an unreviewed qualifying diff cannot silently end a session. The orchestrator **does not hand-record verdicts**.

1. **Capture — `SubagentStop` → `.claude/hooks/review-verdict-capture.sh`.** When `code-reviewer`, `security-reviewer`, `library-reviewer` or `data-model-verifier` finishes, the hook runs `parse-verdict.sh --expect-head "$(git rev-parse HEAD)"` on its `last_assistant_message` and writes the normalized verdict to `.claude/reviews/<HEAD-sha>-<agent>.json` (exits 0/2/3 only). Reviewers stay read-only; the hook writes the artifact.
2. **Gate — `Stop` → `.claude/hooks/review-gate-stop.sh`.** It computes changed paths: the merge-base with the first of `origin/HEAD`, `origin/main`, `origin/master`, `main`, `master`, plus uncommitted files and untracked files that are not ignored. `.claude/reviews/`, `.claude/worktrees/` and untracked nested repos/worktrees are excluded. It then asks the planner which reviewers are required and returns `{"decision":"block","reason":…}` when:
   - qualifying changes are **uncommitted or untracked** (verdicts bind to a SHA). The reason says to commit only the changes meant to ship, and to tell the user instead of committing files the agent did not create.
   - a required reviewer has **no artifact for the current HEAD**, or its verdict is **`hold`**.

   `fix-before-merge` does not block (a proposal, per [review-tiers](../rules/review-tiers.md)); it is listed as info. `data-model-documenter` emits no verdict and is not checked. `stop_hook_active` true → allow, so each stop attempt blocks at most once.

Both hooks locate the git root from the payload's `cwd` (falling back to `CLAUDE_PROJECT_DIR`), so a review or session in a git worktree binds to that worktree's HEAD.

| Concern | Behavior |
|---|---|
| Planner | `scripts/gate-plan.sh` of the checkout the hook lives in, only when that checkout is the same repository (same git common dir, so worktrees count); otherwise, including consumer installs, any non-docs path (not `*.md` other than `DATA_MODEL.md`, `LICENSE`, `NOTICE`, `docs/**`) requires `code-reviewer` + `security-reviewer` |
| Moved base | If HEAD has no commits beyond the chosen base but does beyond another candidate (e.g. `origin/HEAD` was moved onto HEAD), the user gets a `systemMessage` warning |
| Fail-open | Missing `jq`/`git`, unparseable payload, no HEAD, no default branch, git or planner error → allow, with a stderr + `systemMessage` note once per session |
| Opt-out | `AGENTIC_OS_REVIEW_GATE=off` in Claude Code's environment |
| Re-review | After any new commit, HEAD changes and old artifacts no longer count — re-dispatch the required reviewers |
| Untracked noise | An untracked file that is not ignored (e.g. `build.log`) counts as an uncommitted change. It forces one continuation per turn, though never a loop. Fix: add it to `.gitignore`, or set `AGENTIC_OS_REVIEW_GATE=off` |
| Consumers | Add `.claude/reviews/` and `.claude/worktrees/` to your `.gitignore`. The installer does not edit project ignore files. The capture hook's own `*` `.gitignore` and the gate's exclusions already keep both out of the change set |

**Threat model — a process gate, not an adversarial control.** It stops a session from *forgetting* to run reviewers. It does not stop anything determined to skip them:
- Artifacts are unauthenticated. Any process with write access to the repo, including the model's own Bash tool, can write a `pass` file.
- A diff can edit `scripts/gate-plan.sh` to choose its own reviewers, or `.claude/agents/*-reviewer.md` to redefine them.
- Moving the default-branch refs produces at most a warning. If every candidate ref is moved, a single-ref repo's only ref is moved, or commits land directly on the default branch, the gate allows with no warning at all.

Treat it as a guard against omission. Human review of the PR is still the control for the adversarial case ([SECURITY.md](../../SECURITY.md)).

CI does not read these artifacts yet (committing a verdict file would change HEAD); `check-pr-ship-gates.sh` still checks PR checkboxes.

---

## Gate nodes

| Node ID | Agent | Read-only | Wave | Trigger (`gate-plan.sh` flags) |
|---|---|---|---|---|
| `G-code-review` | `code-reviewer` | yes | 1 | **?** `is_code_change \|\| is_library` |
| `G-security-review` | `security-reviewer` | yes | 1 | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-data-document` | `data-model-documenter` | **no** (writes `DATA_MODEL.md` only) | impl close / 0 | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-library-review` | `library-reviewer` | yes | 1 | **?** `is_library` (paths under `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, `.claude/rules/`, `.claude/references/`, `.claude/workflows/`, or root `CLAUDE.md` / `AGENTS.md`) |
| `G-data-verify` | `data-model-verifier` | yes | 2 | **?** `DATA_MODEL.md` in the committed diff (Wave 2 — after `G-data-document` was committed) |

**Always require `G-security-review` on any non-docs-only PR** ([#566530c](https://github.com/LazyIsEfficient/agentic-os/commit/566530c)). **`G-data-document`** runs at **implementation close** when an implementation agent implemented; otherwise the orchestrator runs it in Wave 0. Either way it is committed before Wave 1. `gate-plan.sh` still prints `data-model-documenter` under `wave_1=` for PR-checkbox purposes; dispatch order is this document's.

### Wave 2 — `G-data-verify`

When `DATA_MODEL.md` is in the committed diff, dispatch **`data-model-verifier`** read-only. It inventories property rows in changed catalog sections and verifies against **Source** files ([data-model-verification](../skills/data-model-verification/SKILL.md)). **hold** when REFUTED > 0; fix catalog or source before `checkpoint:ship-ready`.

---

## Wave dispatch contract

Orchestrators MUST NOT dispatch all nodes in a single message if Wave 2 applies.

| Wave | Dispatch | Wait |
|---|---|---|
| **0** | `data-model-documenter` if not run at implementation close; then **commit** | Commit lands; `git status --porcelain` clean for qualifying paths |
| **1** | Single message, multiple `Agent` calls: all triggered Wave 1 reviewers | All Wave 1 agents return |
| **2** | `data-model-verifier` (`readonly: true`) if `DATA_MODEL.md` is in the committed diff | Verifier returns **pass** |
| **Barrier** | Orchestrator synthesizes; address Tier 0/1 | `checkpoint:ship-ready` |

**Why the documenter runs before Wave 1:** it is the only gate node that writes. Its `DATA_MODEL.md` edit has to be committed, and a commit moves HEAD. Any verdict captured before that commit names a stale sha, and the Stop gate rejects it. So the catalog lands first and every reviewer reads the final HEAD.

**Why Wave 2 follows the documenter:** `G-data-document` is the author and `G-data-verify` is the independent verifier. The verifier must read the committed catalog.

**Fixes restart the waves:** fixing a Tier 0/1 finding means a new commit, which means a new HEAD. Re-dispatch every required reviewer for the new HEAD.

---

## Path triggers (reference)

Aligned with **`scripts/gate-plan.sh`** (shared lib: `scripts/lib/gate-plan-lib.sh`). Run locally:

```bash
bash scripts/gate-plan.sh
SHIP_GATES_CHANGED_FILES="path/to/changed" bash scripts/gate-plan.sh --json
```

| Condition | Gates required |
|---|---|
| Docs-only (`*.md` allowlist, no `is_library` / `is_sensitive`) | **None** — skip entire DAG |
| `is_sensitive` only (e.g. `SECURITY.md`, `install.sh`, hooks, gate scripts `scripts/gate-plan.sh` / `scripts/lib/gate-plan-lib.sh` / `scripts/check-pr-ship-gates.sh` / `scripts/parse-verdict.sh` and their tests `scripts/gate-plan-test.sh` / `scripts/check-pr-ship-gates-test.sh`) | `G-security-review`, `G-data-document` |
| `is_code_change` and/or `is_library` | `G-code-review`, `G-security-review`, `G-data-document` |
| `is_library` | + `G-library-review` |
| `DATA_MODEL.md` in the committed diff (documenter ran and was committed before Wave 1) | + `G-data-verify` (`data-model-verifier`) |

`DATA_MODEL.md` is **not** docs-only — agent-maintained catalog changes require full gates.

Files under `.claude/commands/`, `.claude/rules/`, `.claude/references/`, and `.claude/workflows/`, plus root `CLAUDE.md` and `AGENTS.md`, are **not** docs-only either — they define the gates and are prompt-injection surfaces, so they classify as `is_library`. `CLAUDE.md`, `AGENTS.md`, `review-tiers.md`, `subagent-dispatch.md`, `gate-dag.md`, `review-gate.md`, and `review-verdict.md` are additionally `is_sensitive`. A leading `./` is stripped before classification.

---

## Tier discipline

Gate agents follow [review-tiers](../rules/review-tiers.md):

- **Tier 0** — `validate.sh`, tests; hard block
- **Tier 1** — blocking only with evidence artifact (failing command, quoted counterexample)
- **Tier 2** — advisory; findings ledger, not blocking language

`G-data-verify` inventories property rows in `DATA_MODEL.md` and classifies VERIFIED / REFUTED / UNVERIFIABLE per cited **Source** file — REFUTED requires quoted counterexample (Tier 1) or failing `scripts/extract-data-model/*` (Tier 0 when Source is JSON Schema).

---

## Related artifacts

| Artifact | Role |
|---|---|
| `.claude/commands/review-gate.md` | Maintainer command — executes this DAG on working-tree diff |
| `.claude/rules/subagent-dispatch.md` | Claude Code orchestrator rule — same gate DAG |
| `.github/pull_request_template.md` | PR checkboxes (CI enforced) |
| `scripts/gate-plan.sh` | Tier 0 planner — waves + checkboxes from diff |
| `scripts/check-pr-ship-gates.sh` | Tier 0 PR checkbox gate (uses gate-plan-lib) |
| `scripts/implementation-close-test.sh` | Tier 0 — implementation agents declare `G-data-document` close |
| [review-verdict.md](review-verdict.md) | Gate reviewer brief (base ref + paths only) and `agentic-os/review-verdict@1` output contract |
| `scripts/parse-verdict.sh` | Tier 0 — validates and normalizes a reviewer's verdict block (exit 0 pass / 1 invalid / 2 hold / 3 fix-before-merge); wrapper for the shipped `.claude/hooks/lib/parse-verdict.sh` |
| `.claude/hooks/review-verdict-capture.sh` | SubagentStop — writes `.claude/reviews/<HEAD>-<agent>.json` from a reviewer's verdict block |
| `.claude/hooks/review-gate-stop.sh` | Stop — Tier 0 gate on captured verdicts for the current HEAD |
| `data-model-documentation/references/implementation-close.md` | Session-close contract for implementation agents (shipped with skill) |
