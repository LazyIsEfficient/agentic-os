# Gate DAG — ship-gate orchestration

Canonical dependency graph for **Pattern 3 — Build + review pairing**. Orchestrators and maintainer commands (`review-gate`) execute this DAG; CI checkbox rules live in `scripts/check-pr-ship-gates.sh` today and will converge on `scripts/gate-plan.sh` ([#192](https://github.com/LazyIsEfficient/agentic-os/issues/192)).

**Epic:** [#189](https://github.com/LazyIsEfficient/agentic-os/issues/189)

This graph is **fixed** (not per-feature). Feature implementation DAGs use [`planning-and-task-breakdown`](../skills/planning-and-task-breakdown/SKILL.md); this DAG runs **after** each implementation task completes.

---

## Execution DAG

```yaml
dag:
  - checkpoint:impl-verified after [local verification]

  # Wave 1 — parallel (disjoint artifacts; wait for all before Wave 2)
  - checkpoint:impl-verified → G-code-review?
  - checkpoint:impl-verified → G-security-review || G-data-document
  - checkpoint:impl-verified → G-library-review?

  # Wave 2 — conditional (depends on documenter output)
  - G-data-document → G-data-verify?

  # Barrier — all required nodes from Waves 1–2 must complete
  - G-code-review?, G-security-review, G-data-document, G-library-review?, G-data-verify? → checkpoint:ship-ready
```

**Syntax:** `→` = must finish before; `||` = may run in parallel; `?` = include only when trigger matches (see below).

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

| Node ID | Agent | Read-only | Wave | Trigger (`check-pr-ship-gates.sh` flags) |
|---|---|---|---|---|
| `G-code-review` | `code-reviewer` | yes | 1 | **?** `is_code_change \|\| is_library` |
| `G-security-review` | `security-reviewer` | yes | 1 | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-data-document` | `data-model-documenter` | **no** (writes `DATA_MODEL.md` only) | 1 | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-library-review` | `library-reviewer` | yes | 1 | **?** `is_library` (paths under `.claude/skills/` or `.claude/agents/`) |
| `G-data-verify` | `data-model-verifier` | yes | 2 | **?** `DATA_MODEL.md` changed this run ([#191](https://github.com/LazyIsEfficient/agentic-os/issues/191)) |

**Always dispatch `G-security-review` and `G-data-document` on any non-docs-only PR** — not path-conditioned to “sensitive only” ([#566530c](https://github.com/LazyIsEfficient/agentic-os/commit/566530c)).

### `G-data-verify` (stub until #191)

When the verifier agent does not exist yet, orchestrators **skip** Wave 2 but must still:

1. Run `G-data-document` in Wave 1
2. If `DATA_MODEL.md` is in the working tree diff, **human-review** the catalog diff in the PR until #191 lands

After #191 ships: Wave 2 is mandatory whenever `DATA_MODEL.md` changes.

---

## Wave dispatch contract

Orchestrators MUST NOT dispatch all nodes in a single message if Wave 2 applies.

| Wave | Dispatch | Wait |
|---|---|---|
| **1** | Single message, multiple `Task` / `Agent` calls: all triggered Wave 1 nodes | All Wave 1 agents return |
| **2** | `data-model-verifier` if `DATA_MODEL.md` changed | Verifier returns |
| **Barrier** | Orchestrator synthesizes; address Tier 0/1 | `checkpoint:ship-ready` |

**Why Wave 2 follows Wave 1:** `G-data-document` is the author; `G-data-verify` is the independent verifier. Running them in parallel would verify before the catalog exists or re-verify stale content.

**Why Wave 1 parallel is safe:** `code-reviewer` and `security-reviewer` read the **code diff**; `data-model-documenter` writes **`DATA_MODEL.md`**; `library-reviewer` reads library paths. No write/read conflict except documenter → verifier (handled in Wave 2).

---

## Path triggers (reference)

Aligned with `scripts/check-pr-ship-gates.sh` today. Future: `scripts/gate-plan.sh` ([#192](https://github.com/LazyIsEfficient/agentic-os/issues/192)) emits this table from a diff.

| Condition | Gates required |
|---|---|
| Docs-only (`*.md` allowlist, no `is_library` / `is_sensitive`) | **None** — skip entire DAG |
| `is_sensitive` only (e.g. `SECURITY.md`, `install.sh`, hooks) | `G-security-review`, `G-data-document` |
| `is_code_change` and/or `is_library` | `G-code-review`, `G-security-review`, `G-data-document` |
| `is_library` | + `G-library-review` |
| `DATA_MODEL.md` in diff after Wave 1 | + `G-data-verify` (when [#191](https://github.com/LazyIsEfficient/agentic-os/issues/191) shipped) |

`DATA_MODEL.md` is **not** docs-only — agent-maintained catalog changes require full gates.

---

## Tier discipline

Gate agents follow [review-tiers](../rules/review-tiers.md):

- **Tier 0** — `validate.sh`, tests; hard block
- **Tier 1** — blocking only with evidence artifact (failing command, quoted counterexample)
- **Tier 2** — advisory; findings ledger, not blocking language

`G-data-verify` (when shipped) inventories property rows in `DATA_MODEL.md` and classifies VERIFIED / REFUTED / UNVERIFIABLE per cited **Source** file — REFUTED requires quoted counterexample (Tier 1).

---

## Related artifacts

| Artifact | Role |
|---|---|
| `.claude/commands/review-gate.md` | Maintainer command — executes this DAG on working-tree diff |
| `.cursor/rules/subagent-dispatch.mdc` | Cursor orchestrator rule — points here for Pattern 3 |
| `.claude/rules/subagent-dispatch.md` | Claude Code orchestrator rule — same gate DAG |
| `.github/pull_request_template.md` | PR checkboxes (CI enforced) |
| `scripts/check-pr-ship-gates.sh` | Tier 0 checkbox gate (planner integration: #193) |
