# Runbook: memory longitudinal dogfood (Tier-2 live proof)

**Issue:** #217 — reliable durable-fact encoding.
**Gates:** checkpoint `ck-dogfood` in `docs/plans/reliable-memory-encoding.md` (authorizes shipping the hook to consumers in `P4`).

## Why this is a two-layer proof (read this first)

Proving "memory encoding is reliable" splits into two layers that must never be
confused, per `docs/design/memory-extraction-mechanism.md` §4:

- **Tier 0 — plumbing, deterministic, CI-gating.** The extraction hook is wired on
  the right event, fires, exits 0, fails open, self-gates its epoch, contains a
  hostile `session_id`, and emits a well-formed nudge. This is proven **offline,
  with no live model**, by `scripts/memory-extract-hook-test.sh` (run in CI via
  `.github/workflows/validate.yml`) and by the Tier-0 registration invariant
  `check_claude_hook_registration` in `scripts/validate.sh`.
- **Tier 2 — semantic capture, stochastic, dogfood-only.** "Did a live model
  recognize that a durable fact was stated and write a faithful memory that a
  cold future session then applies?" That classification **is** the stochastic
  step we are trying to make reliable. A deterministic (Bash/CLI) detector of it
  is impossible — building one would be a forbidden stochastic gate
  (`.claude/rules/review-tiers.md`). It therefore **needs a live model, runs
  manually, and NEVER gates CI.** This runbook is that Tier-2 proof.

**The boundary rule:** fixtures + no live model = Tier 0 / CI-gating; live-model
behavior = Tier 2 / dogfood, never CI. Deliverable 1
(`scripts/memory-extract-hook-test.sh`) covers the Tier-0 plumbing; this runbook
covers the Tier-2 semantic capture. Passing this runbook is a **human judgement**,
recorded here, not a script exit code.

## Preconditions

- A live Claude Code (and/or Cursor) session with the memory-extraction mechanism
  wired: `.claude/hooks/memory-extract.sh` present and registered on `Stop` in
  `.claude/settings.json` (dev tree — verify with `bash scripts/validate.sh`).
- The `memory-extraction` skill exists at
  `.claude/skills/memory-extraction/SKILL.md`.
- A clean-ish `.claude/memory/` so you can see the new file appear. `.claude/memory/`
  is gitignored; note its current contents first (`ls .claude/memory/`) so you can
  tell what the run added.

## Procedure

### Session 1 — state a convention, then end the session

1. Start a fresh session in the repo.
2. State an **arbitrary, non-derivable convention** the agent could not reconstruct
   from the repo/git/tools — for example:
   > "For this project, treat all timestamps as **epoch seconds**, never ISO-8601."
   Pick something that is genuinely a preference/decision, not a fact already
   visible in the code (non-derivability is the predicate the extractor applies).
3. Do one or two more ordinary turns (the hook re-nudges every `N=3` Stop events;
   a couple of turns guarantees the nudge epoch is reached so extraction is driven).
4. Let the turn end normally. The `Stop` hook fires; on a nudge epoch it blocks the
   stop with an instruction to run the `memory-extraction` skill as the final act.
   The agent should run the skill and write the convention to `.claude/memory/`.
5. **Observe (evidence to record):**
   - A new file appeared under `.claude/memory/` (e.g. `timestamp-convention.md`)
     with valid frontmatter (`name`, `description`, `type`).
   - `.claude/memory/MEMORY.md` gained exactly one index line pointing at it.
   - No unrelated existing memory was modified (append-or-update, never clobber).
   - The index is still ≤ 200 lines.

### Context reset — force a genuinely cold start

6. **Fully reset context.** Do NOT rely on `/compact` alone — start a brand-new
   session (new conversation) so the agent's context window does not carry the
   convention from Session 1. The whole point is that the ONLY channel from
   Session 1 to Session 2 is the written memory file, not residual context.

### Session 2 — confirm the convention is applied cold

7. In the new session, the `SessionStart` inject path surfaces memory at cold start.
   Ask a question whose correct answer **depends on** the convention without
   restating it — for example:
   > "Add a `created_at` field to the event schema. What type and units should it use?"
8. **Pass criterion:** the agent applies the convention it never saw in this
   session's context — e.g. it chooses epoch seconds and cites the captured memory,
   rather than defaulting to ISO-8601. That proves cross-session capture: the fact
   survived a real context reset because it was durably encoded, not merely held in
   a context window.

## Recording the result

Record, next to the `ck-dogfood` checkpoint, a short note:

- date, harness (Claude Code / Cursor), model,
- the convention used,
- the memory file that was written (path + one-line content),
- Session 2 verdict (applied cold: yes/no), with the agent's answer quoted.

A **yes** on Session 2, together with green CI on Deliverable 1
(`scripts/memory-extract-hook-test.sh`) and `scripts/validate.sh`, is the evidence
that clears `ck-dogfood` and authorizes `P4-ship-consumer`. A **no** is a Tier-2
finding: log it to the findings ledger and investigate the extractor's predicate
or the nudge wording — do NOT encode a Bash "did-it-capture" gate (that would be
the forbidden stochastic gate).

## What this runbook does NOT prove

- It does not prove the plumbing — that is Deliverable 1 / `validate.sh`, offline.
- It is not reproducible bit-for-bit: a live model may phrase or place the memory
  differently across runs. That variance is exactly why it is Tier 2 and advisory,
  never a CI gate.
