# Adversarial claims review — full protocol

The long-form version of the seven-step protocol in [SKILL.md](../SKILL.md), with the
motivating case study and per-step guidance.

## The motivating failure

(This case and the diagnostic example in Step 5 are deliberately uncited — treat the
narratives as illustrative, not as checkable historical claims. The mathematical
content, which is what matters, is independently proven by
[scripts/verify_claim_example.py](../scripts/verify_claim_example.py).)

A paper's central equation was labeled:

> "the commutator C[f] = ∂²(Af) − A(∂²f)"

but the formula actually written and computed throughout was a different quantity:

> ∂²(Af) − ∂²f

The first (the genuine commutator with Gaussian smoothing A) is identically zero —
differentiation commutes with convolution. The second (smoothed-minus-raw curvature)
is generically nonzero. The paper's appendix then symbolically "verified" a
NEIGHBORING true statement — that the single-mode commutator vanishes — while the
body asserted conclusions about the false labeling. Polished LaTeX hid an unchecked
core. Every step below exists to make that failure impossible to miss.
[scripts/verify_claim_example.py](../scripts/verify_claim_example.py) proves the two
quantities differ.

## Step 1 — INVENTORY

Enumerate **every** displayed equation, quantitative claim (numbers, bounds, rates,
percentages, benchmark figures), and named theorem-use ("by Plancherel", "by the
central limit theorem"). Assign stable IDs: C1, C2, …

- No skipping. "Obviously true" claims get IDs too — those are where conflations hide.
- Include claims made only in captions, footnotes, and appendices.
- The total count is part of the report headline. A reviewer who inventories 6 claims
  in a 30-equation paper has not reviewed the paper.

## Step 2 — RESTATE

For each ID, write a single precise, self-contained proposition: every symbol defined,
every quantifier explicit, the domain stated.

**The critical rule: verify the proposition AS NAMED IN THE TEXT.** Never a paraphrase,
a simplification, or an adjacent claim. Two distinct checks when the text names an object:

1. Is the formula given actually that named object? ("Is ∂²(Af) − ∂²f the commutator?" — no.)
2. Does the asserted property hold for the formula as written?

A restatement that quietly fixes the paper's error ("they obviously meant…") is itself
a review failure: you verified the paper the author wished they had written.

## Step 3 — VERIFY

Prefer deterministic means, in this order:

1. **Symbolic computation** (SymPy): prove identities, expand both sides, simplify the
   difference to zero.
2. **Numerical spot-checks** at multiple **fixed** parameter values (never random — a
   failure must be reproducible). Three or more points across different regimes.
3. **Known identities** — cite the identity by name and show the substitution.
4. **Dimensional analysis** — units must balance on every displayed equation.

Persist reusable verifiers as scripts that **exit nonzero on failure** so they compose
with CI. Pattern: exit 0 = all checks pass, exit 1 = a claim refuted, exit 2 = setup
error (distinct from refutation). See
[scripts/verify_claim_example.py](../scripts/verify_claim_example.py). When invoked as
a read-only review agent, write throwaway scripts to `/tmp` and run them from there;
only persist into a skill's `scripts/` when working with write access in the main thread.

## Step 4 — CLASSIFY

| Verdict | Meaning | Requirement |
|---|---|---|
| VERIFIED | Reproduced by script, identity, or independent computation | Cite the evidence / script path |
| REFUTED | Shown false as stated | Counterexample or failing script |
| UNVERIFIABLE | Could not be checked with available means | Say exactly what blocked verification |
| VACUOUS | True but trivial, dressed as a result | Show the trivial reduction |

The report headline is the four counts. **A document's status equals its
UNVERIFIABLE + REFUTED count**, regardless of polish. UNVERIFIABLE counts against the
document: a claim that cannot be checked is a liability, not a benefit of the doubt.

## Step 5 — REGIME SANITY

For every formula and diagnostic, evaluate it in at least one regime where the correct
answer is independently known, and check **sign, direction, and magnitude**.

Motivating example (uncited — illustrative): a "calculus
breakdown" diagnostic that turned out to be **maximal in flat space and minimal at
the horizon** — exactly backwards from the physics it claimed to measure. The formula
was internally consistent; only a regime check exposed that it measured the opposite
of its label.

Standard regimes: limits (0, ∞, identity operator), flat/trivial cases, known exact
solutions, degenerate parameters, symmetry points.

## Step 6 — SELF-CONSISTENCY SWEEP

Cross-check the document against itself:

- Do the appendices verify the **same statements** the body asserts — or neighboring ones?
- Do conclusions cite results actually established earlier (by ID), or merely gestured at?
- Are symbols used consistently between sections? Silent redefinition is a finding.
- Do stated numbers match the tables/plots they summarize?

Flag every mismatch explicitly. The motivating paper would have been caught here alone:
its appendix verified single-mode commutation while its body asserted properties of a
formula that was not the commutator.

## Step 7 — REPORT

Fill [assets/report-template.md](../assets/report-template.md). Ordering is mandatory:

1. The four counts (the headline).
2. The single most damaging finding, stated first and plainly.
3. Inventory table with per-claim verdicts, one-line justifications, script paths.
4. "What would need to be true" for each REFUTED claim — the exact propositions that
   would have to hold for the claim to be rescued, so the author knows the repair cost.
5. Regime-sanity and self-consistency findings.
6. Optional second-opinion section: verdicts from an independent model, with
   disagreements surfaced side by side — never averaged.

## Stance reminders

- Assume at least one fatal flaw exists; the review is the hunt for it.
- Formatting, citation density, and LaTeX polish are non-evidence.
- Rigor-signaling phrases ("it is easy to see", "standard results imply") mandate
  verification of the decorated step.
- No softened language: "may warrant a closer look" is forbidden where "is false" is true.
