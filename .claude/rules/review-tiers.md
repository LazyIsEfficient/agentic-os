## Review tiers — stochastic judgment proposes, deterministic verification disposes

Every check in this repo's review machinery belongs to exactly one tier, sorted
by a single question: **is this finding reproducible?** Run the check twice on
the same input — do you get the same finding? Tier assignment is part of a
check's *definition*, not its mood. A check does not move tiers because today's
run sounded confident.

### The three tiers

- **TIER 0 — deterministic.** `scripts/validate.sh`, linters, any script that
  exits nonzero on failure. Zero variance: same input, same verdict, every run.
  This is the ONLY tier permitted to hard-block commits, installs, or merges.
- **TIER 1 — LLM judgment with mandatory deterministic evidence.** The
  `adversarial-claims-reviewer` pattern: a REFUTED verdict requires a failing
  script or an explicit counterexample. Tier 1 may gate, because the gate is
  really the evidence artifact — the LLM only decides *which* evidence to
  produce; the artifact reproduces without it. **A Tier 1 finding without its
  evidence artifact is automatically Tier 2.** No exceptions, no "the script
  would obviously fail."
- **TIER 2 — pure LLM judgment.** Style, taste, "could be cleaner", routing
  vagueness, unevidenced concerns. NEVER gates. Advisory only. Goes to the
  findings ledger (`findings-ledger` skill) so recurrence can be measured
  instead of re-argued.

### The no-stochastic-gating rule

A gate that fires stochastically is worse than no gate: it trains operators to
ignore all gates. When an unevidenced finding blocks work, the operator learns
that blocks are noise, and the next block — the real one — gets waved through.
So: reviewer verdicts like `hold` or `blocking` are **proposals to the
operator** unless backed by Tier 0/1 evidence. Only a failing deterministic
check stops the line on its own authority.

### The RATCHET — the promotion path out of the stochastic layer

Tier 2 findings are not discarded; they are *candidates*. The path:

1. **Tier 2 finding** — logged to the ledger with a fingerprint.
2. **Recurrence** — the same fingerprint shows up across independent runs
   (threshold: 2). Recurrence is the signal that noise might be defect.
3. **Investigation** — a human (or a briefed agent) decides whether the
   recurring finding is real and mechanically checkable.
4. **Encoding** — the finding becomes a Tier 1 evidence check (a script that
   asserts the specific claim) or, better, a Tier 0 validator rule in
   `scripts/validate.sh`.
5. **It leaves the stochastic layer forever.** Once encoded, no LLM ever
   re-litigates it; the validator catches it for free on every run.

Single-occurrence findings that nobody re-reports age out as RETIRED-NOISE.
The ratchet only turns one way: checks migrate *down* the variance ladder
(Tier 2 → Tier 1 → Tier 0), never back up.

### How to apply

- Defining a new check? Answer the reproducibility question first and write the
  tier into its definition.
- Reviewing? Label each finding's tier. Attach the evidence artifact for Tier 1
  or it is Tier 2. Emit Tier 2 findings as ledger entries, not blocking language.
- Triaging? Run `/triage-findings` — it proposes promotions and retirements;
  the human disposes.
