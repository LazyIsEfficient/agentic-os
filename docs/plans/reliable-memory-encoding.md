# Plan: Reliable memory encoding (issue #217, entire-problem redesign)

**Status:** in-progress (T-spike decided — see `docs/design/memory-extraction-mechanism.md`; at checkpoint `ck-spike`)

**Spike outcome (verified):** mechanism = **in-session nudge → `memory-extraction` SKILL** (a subagent
can't see the transcript, so it must be a skill run in the main agent's context); event = **Stop**
(PreCompact can't steer on Claude and misses short sessions). One finding amends the plan
below: the Claude hook tree has NO dev↔consumer registration validator — P3 must add a Tier-0 assertion
that `memory-extract` is registered on `Stop` in BOTH `.claude/settings.json` and
`assets/consumer/claude-settings.json`, or consumers ship a dead mechanism.

Make durable-fact **encoding** reliable instead of best-effort. Today memory-writing is a
stochastic in-conversation self-classification step, so it under-fires (issue #217: a firmly-stated
convention was dropped) and silently gaps on un-enumerated fact-types. This plan (1) reframes the
write RULE around a predicate, (2) moves encoding into a deterministically-triggered end-of-session
extraction pass, and (3) proves it with a permanent in-repo test. Phase 1 is dev-loop dogfood;
Phase 2 ships the hook to consumers (HELD pending dogfood).

Scope locked by shaping: **Both/staged** ship · **Encoding-reliability** only (retrieval/consolidation
deferred) · **In-repo longitudinal test** as proof.

---

## Execution DAG

```
T-spike ─┐
         ├─(ck-spike)─→ P2a-extractor ─→ P2b-hook ─┬─→ P3-longitudinal-test ──┐
P1-rule ─┘  (day 0, ‖ T-spike)                     └─→ T-rule-integrate ──────┴─(ck-dogfood)─→ P4-ship-consumer [HELD]

Day-zero ready set:  T-spike  ‖  P1-rule
Wave 1:  T-spike  ‖  P1-rule
── ck-spike (mechanism decided + reviewed) ──
Wave 2:  P2a-extractor
Wave 3:  P2b-hook
Wave 4:  P3-longitudinal-test  ‖  T-rule-integrate      (no file overlap → worktree-isolate the pair)
── ck-dogfood (PR-B merged + real 2-session longitudinal run passes) ──
Wave 5:  P4-ship-consumer  [HELD]
```

**Serialization drivers**
- `T-spike` gates `P2a`/`P2b`/`P3` — the extraction *mechanism* (in-session skill vs out-of-band
  spawn) and *trigger event* (PreCompact vs Stop) are unresolved; the extractor's very form
  (skill vs agent) and the post-check design depend on the decision.
- `P1-rule` and `T-rule-integrate` both rewrite `memory-discipline.md` + regenerate
  `CLAUDE.md` → **conflict edge**; they are in different waves so never run concurrently.
- `P2b` is the sole writer of `.claude/settings.json`; `P4` is the sole
  writer of `assets/consumer/*.json`; `P3` is the sole writer of the test/CI files. No shared-write
  hotspot is touched by two concurrent tasks.

**PR packaging:** PR-A = `P1-rule` (fast, independent). PR-B = `P2a`+`P2b`+`P3`+`T-rule-integrate`
(the mechanism + evidence). PR-C = `P4` (HELD, post-dogfood).

---

## Task: Design spike — extraction mechanism + trigger + post-check

```yaml
id: T-spike
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - docs/design/memory-extraction-mechanism.md
files_read:
  - .claude/settings.json
  - .claude/hooks/session-state-checkpoint.sh
  - scripts/lib/install-hook-settings.sh
branch_suffix: spike-memory-extraction
scope: S
```

**Description:** A hook is a shell command and cannot run an LLM. Decide, with evidence, HOW a
deterministic hook drives an LLM extraction pass, and produce a short decision doc that the
implementation tasks execute against. Resolve three things: (1) **mechanism** — in-session nudge
(hook injects an instruction so the *main* agent, which still holds the transcript, runs a dedicated
extraction skill as its final act) vs out-of-band spawn (hook launches a separate process; must
solve transcript-passing and fragility); (2) **trigger event** — PreCompact (already
wired; fires at context-loss = the #217 failure moment) vs Stop (Claude Code supports Stop but this
repo wires none yet — adding one has consumer-manifest consequences); (3) **the deterministic "did-it-capture" post-check** — how a Tier-0
check decides a session *should* have written memory (what signal marks "a durable fact was stated")
and asserts it did, WITHOUT an LLM in the CI loop. Explicitly separate the CI-gateable deterministic
scaffolding from the inherently-Tier-2 extraction content.

**Acceptance criteria:**
- [ ] `docs/design/memory-extraction-mechanism.md` names the chosen mechanism + event + post-check design, with the rejected alternative and why.
- [ ] States whether a new Claude Code `Stop` hook is introduced (and the resulting `.claude` hook + consumer-manifest implications).
- [ ] Defines the extractor's invocation contract (skill name / agent name, inputs, where it writes) so `P2a`/`P2b` can build against it.
- [ ] Draws the Tier-0 / Tier-2 line: exactly what the in-repo test can assert deterministically vs what only a live dogfood run can show.

**Verification:**
- [ ] Manual: doc reviewed by the operator; the mechanism is compatible with the Claude Code harness.
- [ ] No code written (read-only investigation + doc).

---

## Task: Predicate reframe of the write rule

```yaml
id: P1-rule
depends_on: []
parallel_safe: true
conflicts_with: [T-rule-integrate]
files_write:
  - .claude/rules/memory-discipline.md
  - CLAUDE.md
files_read:
  - scripts/build-claude-md.sh
  - scripts/validate.sh
branch_suffix: rule-predicate-reframe
scope: S
```

**Description:** Rewrite the "Write memory whenever you learn something durable" section so a
two-clause **predicate leads** — save iff (a) **decision-relevance**: a cold future session would
act differently without this fact, AND (b) **non-derivability**: it can't be reconstructed from
repo / git / tools. Demote the enumerated categories (Feedback/Project/User/Reference, plus #218's
Convention) to a *few* illustrative examples chosen to span the axes the model drops —
procedural-vs-representational and about-you-vs-about-data — so the list stops growing per-defect.
Assume PR #218 has merged; fold its "Convention memories" category into an example. Regenerate
`CLAUDE.md` via `bash scripts/build-claude-md.sh`
(never hand-edit). **Net-neutral-or-shorter** — this text is re-injected every turn.

**Acceptance criteria:**
- [ ] Predicate is the operative rule; categories appear only as ≤4 examples spanning both axes.
- [ ] New section is ≤ the old section's line count (token-tax neutral-or-better).
- [ ] Does NOT reference the extraction pass yet (that's `T-rule-integrate`, to keep this task mechanism-independent and day-zero).

**Verification:**
- [ ] `bash scripts/build-claude-md.sh` then `bash scripts/validate.sh` → OK (claude-flat-sync + rules-parity green).
- [ ] `bash scripts/validate-test.sh` → passes.

---

## Task: Dedicated extraction skill/agent

```yaml
id: P2a-extractor
depends_on: [T-spike]
parallel_safe: true
conflicts_with: []
files_write:
  - .claude/skills/memory-extraction/SKILL.md      # SKILL (spike-locked): a subagent starts cold without the transcript
files_read:
  - docs/design/memory-extraction-mechanism.md
  - .claude/rules/memory-discipline.md
  - .claude/memory/MEMORY.md
branch_suffix: extractor-skill
scope: M
```

**Description:** Author the dedicated pass whose ONLY job is: read the just-ended session, apply the
predicate (from `P1-rule`), and write durable facts to `.claude/memory/` — one file per fact with
frontmatter, plus a one-line `MEMORY.md` index entry — using **append-or-update, never clobber**,
keeping the index ≤200 lines. Form (skill invoked in-session vs subagent) follows the spike's chosen
mechanism. It must embody the predicate rather than an enumerated category list, and dedup against
existing memory before writing. This is the surface that also reaches consumers in Phase 2, so it
must be self-contained (no dependency on the un-shipped rule file — inline the predicate).

**Acceptance criteria:**
- [ ] Extractor applies the (a)+(b) predicate, not a category whitelist; inlines the predicate so it works where `rules/` isn't installed.
- [ ] Append-or-update semantics specified; never overwrites an unrelated memory; index kept ≤200 lines.
- [ ] Matches the spike's invocation contract (name, inputs, write target).

**Verification:**
- [ ] `bash scripts/validate.sh` → OK (skill/agent frontmatter + naming invariants pass).
- [ ] Library review clean (routing, single-responsibility, tool allowlist).

---

## Task: Extraction hook + wiring + did-it-capture post-check

```yaml
id: P2b-hook
depends_on: [T-spike, P2a-extractor]
parallel_safe: false
conflicts_with: []
files_write:
  - .claude/hooks/memory-extract.sh
  - .claude/settings.json
files_read:
  - docs/design/memory-extraction-mechanism.md
  - .claude/hooks/session-state-checkpoint.sh
  - scripts/validate.sh
branch_suffix: extract-hook
scope: M
```

**Description:** Implement the deterministic trigger. Add the hook script in
`.claude/hooks/`, register it on the chosen
event in `.claude/settings.json`, and implement the deterministic
"did-it-capture" post-check per the spike (fires the extractor; on the completing turn, verifies
memory was touched when the session carried a durable-fact signal). Bash + standard CLI only, matching
the existing hooks. Do NOT touch `rules/` or `CLAUDE.md` (kept in `P1`/`T-rule-integrate` to avoid a
conflict edge). Do NOT touch `assets/consumer/*` (that's `P4`).

**Acceptance criteria:**
- [ ] Hook script present in `.claude/hooks/`.
- [ ] Registered on **Stop** in `.claude/settings.json` (new — Claude has no Stop hook today).
- [ ] Stop fires every turn → hook MUST self-gate on a per-session ledger/marker so it nudges once per epoch and can't infinite-loop.
- [ ] Emits `{"decision":"block","reason":…}` (Claude); otherwise `{}`/allow.
- [ ] Fail-open on every path (any error → allow completion, exit 0). Pure Bash/CLI, no Python.

**Verification:**
- [ ] `bash scripts/validate.sh` → OK.
- [ ] `bash scripts/validate-test.sh` → passes.
- [ ] Manual: trigger fires in a scratch session; post-check flags a synthetic durable-fact transcript.

---

## Task: In-repo longitudinal test + CI gate + dogfood runbook

```yaml
id: P3-longitudinal-test
depends_on: [P2b-hook]
parallel_safe: true
conflicts_with: []
files_write:
  - scripts/memory-longitudinal-test.sh
  - scripts/validate.sh          # NEW Tier-0 invariant: Claude Stop registration parity (dev ↔ consumer)
  - scripts/validate-test.sh     # meta-test case for the new invariant
  - .github/workflows/validate.yml
  - docs/runbooks/memory-longitudinal-dogfood.md
files_read:
  - .claude/hooks/memory-extract.sh
  - .claude/settings.json
  - assets/consumer/claude-settings.json
branch_suffix: longitudinal-test
scope: M
```

**Spike-added requirement:** because no existing validator gates the Claude hook tree for dev↔consumer
registration parity, this task MUST add a
Tier-0 invariant asserting `memory-extract` is registered on `Stop` in BOTH `.claude/settings.json` and
`assets/consumer/claude-settings.json` — else Phase 2 could ship consumers a dead mechanism. This is the
ratchet that closes the gap the spike found.

**Description:** Build the ratchet evidence artifact. Two layers per the spike's Tier-0/Tier-2 line:
(1) **Deterministic CI gate** — a fixture-driven test that feeds a canned "session 1" transcript
stating a convention, runs the hook's deterministic scaffolding + the did-it-capture post-check, and
asserts the post-check correctly flags "memory should have been written" (and, given a captured memory
fixture, that "session 2" would surface it). No live model in CI. Wire it into `validate.yml`.
(2) **Dogfood runbook** — a documented manual procedure for the real two-session run (state convention
→ context reset → confirm applied), which is the Phase-1 → Phase-2 gating evidence. Be explicit in
the runbook that the end-to-end LLM behavior is Tier 2 and validated by this manual run, not CI.

**Acceptance criteria:**
- [ ] `scripts/memory-longitudinal-test.sh` runs offline, deterministically, exits nonzero on regression.
- [ ] Added to `validate.yml` so CI runs it; passes there.
- [ ] Runbook documents the live 2-session dogfood and states the Tier-0/Tier-2 boundary honestly.

**Verification:**
- [ ] `bash scripts/memory-longitudinal-test.sh` → exit 0 locally.
- [ ] `bash scripts/validate.sh` + `bash scripts/validate-test.sh` → pass (no regression).
- [ ] CI `validate` job green on the PR.

---

## Task: Doctrine coherence — rule references the extraction pass

```yaml
id: T-rule-integrate
depends_on: [P2b-hook]
parallel_safe: true
conflicts_with: [P1-rule]
files_write:
  - .claude/rules/memory-discipline.md
  - CLAUDE.md
files_read:
  - docs/design/memory-extraction-mechanism.md
branch_suffix: rule-integrate-extraction
scope: XS
```

**Description:** Now that the extraction pass exists, add the one coherence line to the memory rule:
encoding happens primarily via the deterministic end-of-session extraction pass; in-conversation
writes are the exception, not the mechanism to rely on. Regenerate `CLAUDE.md`.
Keep it to a sentence — token-tax. Shares files with `P1-rule` (conflict edge); runs in a later wave
so never concurrent.

**Acceptance criteria:**
- [ ] One sentence added pointing to the extraction pass as the primary encoding path.
- [ ] `CLAUDE.md` regenerated by the script.

**Verification:**
- [ ] `bash scripts/build-claude-md.sh` + `bash scripts/validate.sh` → OK.

---

## Checkpoint: ck-spike — mechanism decided

Barrier after `T-spike`. Dispatch of `P2a`/`P2b`/`P3` pauses until the operator approves
`docs/design/memory-extraction-mechanism.md` (mechanism + event + post-check + Tier line). `P1-rule`
does not wait on this checkpoint.

## Checkpoint: ck-dogfood — Phase 1 proven

Barrier after `P3-longitudinal-test` + `T-rule-integrate` (i.e. PR-B merged). Gates `P4`. Clears only
when: CI longitudinal gate green AND the live 2-session dogfood run (per the runbook) shows a stated
convention captured across a real context reset. This is the evidence that authorizes shipping to
consumers.

---

## Task: Ship extraction hook to consumers  [HELD — pending ck-dogfood]

```yaml
id: P4-ship-consumer
depends_on: [ck-dogfood]
parallel_safe: true
conflicts_with: []
files_write:
  - assets/consumer/claude-settings.json
  - scripts/install-paths-test.sh
files_read:
  - install.sh
  - scripts/lib/install-hook-settings.sh
branch_suffix: ship-memory-extract
scope: S
```

**Description:** **HELD** until `ck-dogfood` clears. Register the extraction hook in the consumer
manifest (`assets/consumer/claude-settings.json`) so `install_dir "hooks"` +
`merge_claude_hook_settings` wire it on a fresh install. Extraction on consumer machines must be strictly
**append-or-update / non-destructive** to a user's `.claude/memory/` and fail-open. Extend the install
smoke test to assert the hook is wired post-install. The extraction skill/agent already ships (it's
under `.claude/skills` or `.claude/agents`, which `install.sh` copies); this task only adds the hook
registration + install proof.

**Acceptance criteria:**
- [ ] Hook registered in the consumer manifest; a fresh install wires it.
- [ ] Consumer-side extraction is non-destructive and fail-open (documented + asserted).
- [ ] `scripts/install-paths-test.sh` (or the install smoke test) asserts the hook is present after install.

**Verification:**
- [ ] `bash scripts/install-paths-test.sh` → pass.
- [ ] Fresh `install.sh` into a scratch `CLAUDE_DIR` shows the hook registered; `validate.sh` green.

---

## Verification checklist (plan-level)

- [x] `**Status:**` line present (`proposed`).
- [x] Every task has a stable slug id, acceptance, and verification.
- [x] Every task declares `depends_on`, `parallel_safe`, `files_write`.
- [x] Overlapping-write pair `P1-rule` ↔ `T-rule-integrate` are in each other's `conflicts_with`.
- [x] Non-empty day-zero ready set: `T-spike`, `P1-rule` (`depends_on: []`).
- [x] No `scope: L`; no task writes >5 files.
- [x] DAG edges match per-task `depends_on`; no orphan IDs.
- [x] Checkpoints (`ck-spike`, `ck-dogfood`) sit between phases and are referenced in the DAG.
- [ ] **Operator review + approval** — pending.
