# Findings: Cursor two-hook `stop` merge semantics (de-risks P2b, UNVERIFIED #2)

**Status:** decided. This resolves the "biggest integration risk" flagged in
`reliable-memory-encoding.md` (P2b acceptance criterion) and
`memory-extraction-mechanism.md` UNVERIFIED #2, **without wiring anything**.

**Question:** when Cursor's `stop` array holds TWO hooks (`dispatch-gate-stop.sh` +
`memory-extract.sh`), how are their `followup_message` outputs merged, and are `loop_limit`/`timeout`
per-hook or shared? A collision could starve the dispatch-gate reviewer followup or loop.

**Bottom line:** the merge of two same-source `followup_message` scalars is **genuinely undocumented**
and stays `UNVERIFIED`. But it does **not need to be resolved** to ship P2b safely — the recommended
design makes the two hooks **mutually exclusive per turn**, so there is never anything to merge. A live
probe (`cursor-stop-merge-experiment.md`) is confirmatory, not blocking.

---

## What is PROVEN

### From authoritative Cursor docs (`https://cursor.com/docs/agent/hooks`, fetched 2026-07-13)

1. **Both hooks run.** *"All matching hooks from every source run; when responses conflict,
   higher-priority sources take precedence during merge."* → all entries in a `stop` array execute;
   neither is skipped.
2. **`loop_limit` and `timeout` are PER-HOOK-ENTRY, not shared.** Both are listed under
   *"Per-Script Configuration Options"*; `loop_limit` = *"Per-script loop limit for stop/subagentStop
   hooks."* Corroborated by the community-documented `loop_count` input field: *"how many times the
   stop hook has already triggered an automatic follow-up for this conversation … default limit is 5
   auto follow-ups per script, configurable via `loop_limit`."* → `memory-extract.sh` gets its **own
   independent loop budget**; it cannot burn or starve dispatch-gate's `loop_limit: 8`.
3. **`followup_message` is a single scalar slot.** *"When provided and non-empty, Cursor will
   automatically submit it as the next user message."* One event → one "next user message". Two hooks
   emitting `followup_message` therefore contend for **one scalar slot** (this is why the merge rule
   matters, and why it can't be a clean concatenation of two independent values).

### From this repo's shipping, load-bearing precedent

The repo **already runs two hooks on one event, twice**, and depends on both being honored:

- **`sessionStart` ×2** (`.cursor/hooks.json:4-7`): `session-state-inject.sh` emits
  `{additional_context: …}` (`session-state-inject.sh:17,22`) **and** `dispatch-gate-session-init.sh`
  emits `{additional_context: …}` (`dispatch-gate-lib.sh:488`). Both payloads are load-bearing shipping
  features (session-state doc injection + orchestrator reminder). The repo's design **assumes both
  `additional_context` outputs reach the agent** — i.e. for the *data* field, multi-hook output is
  additive, not last-wins.
- **`beforeShellExecution` ×2** (`.cursor/hooks.json:14-17`): `block-bad-bash.sh` returns
  `{permission: allow|deny}` (`block-bad-bash.sh:14-27`); `survey-before-act.sh` is **WARN-FIRST —
  always `allow`**, carrying only an `agent_message` advisory (`survey-before-act.sh:9,42`). The design
  deliberately makes `survey` never deny, so it can never fight `block-bad-bash` on the decision axis.
  This is a **decision-aggregation** assumption (any-deny-wins) executed by *never producing a
  conflicting decision* — not by relying on a documented aggregation rule.

**Precedent limit:** neither precedent is a `followup_message` scalar. They prove *both hooks run* and
show the repo's pattern is *"design so outputs don't collide,"* but they do **not** prove how Cursor
reconciles two `followup_message` values. So the precedent guides the fix; it does not answer the raw
merge question.

---

## What stays UNVERIFIED

- **`UNVERIFIED`: same-source, same-`stop`-array reconciliation of two `followup_message` scalars.**
  The docs' merge rule (*"higher-priority sources take precedence"*) is scoped to **config SOURCES**
  (Enterprise → Team → Project → User), explicitly targeted with `WebFetch` and returned
  `NOT DOCUMENTED` for: within-array order, array-order-as-priority, any per-entry `priority` field,
  and permission-conflict resolution. Both our hooks live in the **same source** (project
  `.cursor/hooks.json`), so the source-priority rule does not disambiguate them. Whether it is
  first-wins, last-wins, or concatenated is unknown.
- **`UNVERIFIED`: runtime confirmation** that both `stop` hooks actually fire and that `loop_limit` is
  independent in practice (doc-supported at high confidence; never observed in this repo, which has
  only ever registered one `stop` hook).

Both are answered by the delivered probe if the operator wants runtime certainty — but the design below
makes neither a prerequisite.

---

## Recommended P2b design — the one change that removes the risk

**Make the two `stop` hooks mutually exclusive per turn, so the undocumented merge rule never fires.**

`dispatch-gate-stop.sh` emits a `followup_message` **only** when reviewers are missing for a dirty
code/library worktree **or** ungated main-thread code edits exist; otherwise it emits `{}`
(`dispatch-gate-lib.sh:744-763`; and it is silent on clean/docs-only worktrees by design,
`dispatch-enforcement.md:78`). It is also silent whenever the gate is disabled — which it ships as
(`.cursor/dispatch-gate.json` `enabled: false`; short-circuit at `dispatch-gate-lib.sh:732`).

So: **`memory-extract.sh` must yield (emit `{}`) on exactly the turns where `dispatch-gate-stop` would
speak.** Concretely, in its fat lib, before deciding to nudge:

1. **Yield to the reviewer gate.** Reuse dispatch-gate's own stop decision as the guard — source
   `scripts/lib/dispatch-gate-lib.sh` and, when `dispatch_gate_is_enabled`, return `{}` if
   `dispatch_gate_missing_reviewers_for_worktree` is true or the ledger's `ungated_code_edits` is
   non-empty (the two conditions at `dispatch-gate-lib.sh:744-761` — **read those lines before wiring**).
   Reusing the predicate keeps memory-extract in lock-step with the gate and self-syncing if the gate's
   rule changes. (Decoupled fallback if lib-reuse is undesirable: yield while `git status --porcelain`
   shows uncommitted changes under the code/library prefixes.)
2. **Self-gate on a per-session ledger/marker** (mirror `dispatch-gate-lib.sh:76-122`): nudge at most
   once per epoch; after the `memory-extraction` skill runs (or the marker is written), subsequent Stop
   events return `{}`. This is the intra-hook loop-safety already required by
   `memory-extraction-mechanism.md` §3.
3. **Register memory-extract SECOND in the `stop` array**, and give it its own low `loop_limit`
   (e.g. `2`) + short `timeout`. Ordering is **defensive belt-and-suspenders**: the yield rule already
   guarantees at most one followup per turn, so first-wins vs last-wins becomes irrelevant. The
   independent per-hook `loop_limit` (PROVEN) means memory-extract can never consume dispatch-gate's
   budget.

**Why this is disjoint, grounded in the ledger:** memory extraction is not time-critical within a
session, so deferring its nudge to the next Stop where the worktree is settled (reviewers done /
committed / docs-only) costs nothing — and that settled state is *precisely* when dispatch-gate is
silent. The reviewer gate is therefore **never starved**: on any collision-eligible turn, dispatch-gate
speaks and memory-extract stays silent; on a settled turn, dispatch-gate is silent and memory-extract
may speak. At most one `followup_message` exists per turn ⇒ the merge rule is moot.

**Net effect on the three sub-risks:**

| Sub-risk | Verdict |
|---|---|
| Two `followup_message` collide / starve reviewer gate | **Removed by design** (yield rule → never two at once). Merge rule never exercised. |
| `loop_limit` shared → cross-starvation | **Not a risk** — PROVEN per-hook; independent budgets. |
| Infinite Stop-loop | **Handled** — per-session ledger self-gate + memory-extract's own low `loop_limit`. |

---

## Does the operator still need a live Cursor turn?

**Not to unblock P2b.** The mutual-exclusion design does not depend on the undocumented merge rule, and
the two facts it *does* lean on (both hooks fire; independent `loop_limit`) are supported by authoritative
docs. P2b can be built and its Tier-0 fixtures (fires, exits 0, fail-open, ledger self-gate) all run
offline.

**Recommended once, before P4 (ship-to-consumers):** run the delivered probe
(`cursor-stop-merge-experiment.md`, ~5 min, keeps `validate.sh` green) to convert the two doc-sourced
assumptions into observed fact and to learn Cursor's actual first/last-wins behavior — useful defense
in depth even though the design no longer needs it. It is a confirmation, not a gate.
