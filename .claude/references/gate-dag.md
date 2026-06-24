# Gate DAG — ship-gate orchestration

Canonical dependency graph for **Pattern 3 — Build + review pairing**. Orchestrators and maintainer commands (`review-gate`) execute this DAG; CI checkbox rules are computed by **`scripts/gate-plan.sh`** and enforced by **`scripts/check-pr-ship-gates.sh`**.

**Epic:** [#189](https://github.com/LazyIsEfficient/agentic-os/issues/189)

This graph is **fixed** (not per-feature). Feature implementation DAGs use [`planning-and-task-breakdown`](../skills/planning-and-task-breakdown/SKILL.md); this DAG runs **after** each implementation task completes.

---

## Execution DAG

```yaml
dag:
  - checkpoint:impl-verified after [local verification]

  # Implementation close — engineer (or stack specialist) dispatches before return
  - T-impl → G-data-document?          # when implementation agent ran; see § Implementation close

  # Wave 1 — parallel reviewers (disjoint artifacts; wait for all before Wave 2)
  - checkpoint:impl-verified → G-code-review?
  - checkpoint:impl-verified → G-security-review
  - checkpoint:impl-verified → G-data-document?   # orchestrator only when T-impl did not run G-data-document
  - checkpoint:impl-verified → G-library-review?

  # Wave 2 — conditional (depends on documenter output)
  - G-data-document → G-data-verify?

  # Barrier — all required nodes from Waves 1–2 must complete
  - G-code-review?, G-security-review, G-data-document, G-library-review?, G-data-verify? → checkpoint:ship-ready
```

**Syntax:** `→` = must finish before; `||` = may run in parallel; `?` = include only when trigger matches (see below).

---

## Implementation close (`G-data-document`)

When implementation runs through an **implementation agent** (`engineer`, `rust-engineer`, `web3-engineer`, `godot-engineer`, `devops-engineer`, `phaser-engineer`), that agent **must dispatch `data-model-documenter` before returning** — not the orchestrator.

Canonical contract: [implementation-close.md](../skills/data-model-documentation/references/implementation-close.md)

| Who | When | Action |
|---|---|---|
| **Implementation agents** (see above) | After local verification, before completion report | Foreground `Agent` / `Task` → `data-model-documenter` with changed paths + brief |
| **Orchestrator** | Wave 1 | Include `G-data-document` **only if** no implementation agent ran it (main-thread impl, or completion report lacks `G-data-document:` status) |
| **Orchestrator** | Wave 2 | `G-data-verify` when `DATA_MODEL.md` changed — always orchestrator-owned |

**Skip** `G-data-document` when the diff is docs-only (same allowlist as path triggers below).

This keeps catalog authoring at the end of the implementation session while reviewers stay in orchestrator Wave 1.

---

## Checkpoints

### `checkpoint:impl-verified`

Run before any gate agent. Minimum:

- [ ] `bash scripts/validate.sh` on any non-docs-only diff (matches ship-gate entry — not only library paths)
- [ ] Task-specific verification from the implementation brief (tests, build, etc.)

If verification fails, do not dispatch gate agents.

### `checkpoint:ship-ready`

Clears when:

- [ ] Every **required** node (non-`?` or triggered `?`) has returned
- [ ] Tier 0/1 findings from gate agents are fixed or explicitly waived
- [ ] Tier 2 findings logged to findings ledger (advisory — do not block alone)
- [ ] PR description checkboxes match dispatched agents (see `.github/pull_request_template.md`)

Only after this checkpoint: mark work **complete**, open/ready PR, merge, tag, release.

---

## Gate nodes

| Node ID | Agent | Read-only | Wave | Trigger (`gate-plan.sh` flags) |
|---|---|---|---|---|
| `G-code-review` | `code-reviewer` | yes | 1 | **?** `is_code_change \|\| is_library` |
| `G-security-review` | `security-reviewer` | yes | 1 | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-data-document` | `data-model-documenter` | **no** (writes `DATA_MODEL.md` only) | impl close / 1 | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-library-review` | `library-reviewer` | yes | 1 | **?** `is_library` (paths under `.claude/skills/` or `.claude/agents/`) |
| `G-data-verify` | `data-model-verifier` | yes | 2 | **?** `DATA_MODEL.md` changed this run (Wave 2 — after `G-data-document`) |

**Always require `G-security-review` on any non-docs-only PR** ([#566530c](https://github.com/LazyIsEfficient/agentic-os/commit/566530c)). **`G-data-document`** runs at **implementation close** when an implementation agent implemented; otherwise include it in orchestrator Wave 1.

### Wave 2 — `G-data-verify`

When `DATA_MODEL.md` changed after Wave 1, dispatch **`data-model-verifier`** read-only. It inventories property rows in changed catalog sections and verifies against **Source** files ([data-model-verification](../skills/data-model-verification/SKILL.md)). **hold** when REFUTED > 0; fix catalog or source before `checkpoint:ship-ready`.

---

## Wave dispatch contract

Orchestrators MUST NOT dispatch all nodes in a single message if Wave 2 applies.

| Wave | Dispatch | Wait |
|---|---|---|
| **1** | Single message, multiple `Task` / `Agent` calls: all triggered Wave 1 nodes | All Wave 1 agents return |
| **2** | `data-model-verifier` (`readonly: true`) if `DATA_MODEL.md` changed | Verifier returns **pass** |
| **Barrier** | Orchestrator synthesizes; address Tier 0/1 | `checkpoint:ship-ready` |

**Why Wave 2 follows Wave 1:** `G-data-document` is the author; `G-data-verify` is the independent verifier. Running them in parallel would verify before the catalog exists or re-verify stale content.

**Why Wave 1 parallel is safe:** `code-reviewer`, `security-reviewer`, and `library-reviewer` read the **code diff**. When `G-data-document` runs in Wave 1 (orchestrator fallback), it writes **`DATA_MODEL.md`** only — no conflict with reviewers. Documenter → verifier ordering is Wave 2.

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
| `is_sensitive` only (e.g. `SECURITY.md`, `install.sh`, hooks) | `G-security-review`, `G-data-document` |
| `is_code_change` and/or `is_library` | `G-code-review`, `G-security-review`, `G-data-document` |
| `is_library` | + `G-library-review` |
| `DATA_MODEL.md` in diff after Wave 1 | + `G-data-verify` (`data-model-verifier`) |

`DATA_MODEL.md` is **not** docs-only — agent-maintained catalog changes require full gates.

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
| `.cursor/rules/subagent-dispatch.mdc` | Cursor orchestrator rule — points here for Pattern 3 |
| `.claude/rules/subagent-dispatch.md` | Claude Code orchestrator rule — same gate DAG |
| `.github/pull_request_template.md` | PR checkboxes (CI enforced) |
| `scripts/gate-plan.sh` | Tier 0 planner — waves + checkboxes from diff |
| `scripts/check-pr-ship-gates.sh` | Tier 0 PR checkbox gate (uses gate-plan-lib) |
| `scripts/implementation-close-test.sh` | Tier 0 — implementation agents declare `G-data-document` close |
| `data-model-documentation/references/implementation-close.md` | Session-close contract for implementation agents (shipped with skill) |
