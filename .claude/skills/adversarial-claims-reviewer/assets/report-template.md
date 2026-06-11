# Adversarial claims review — <document title>

**Reviewed:** <file/path or citation> · **Reviewer:** <model/agent> · **Date:** <YYYY-MM-DD>
**Cold context:** <yes/no — was the reviewer given only the document, with no authoring context?>

## Headline

| VERIFIED | REFUTED | UNVERIFIABLE | VACUOUS | Total inventoried |
|---:|---:|---:|---:|---:|
| n | n | n | n | n |

**Document status = REFUTED + UNVERIFIABLE = n.** Polish, formatting, and citation
density were not considered evidence.

## Most damaging finding

<State it first, plainly, in one short paragraph: which claim ID, what the text
asserts, what is actually true, and what it breaks downstream. No hedging.>

## Claim inventory and verdicts

| ID | Location | Claim as named in the text | Verdict | Justification (one line) | Evidence / script |
|---|---|---|---|---|---|
| C1 | §2, eq. (3) | … | REFUTED | … | `scripts/verify_c1.py` (exit 1) |
| C2 | §3.1 | … | VERIFIED | … | `scripts/verify_c2.py` (exit 0) |
| C3 | App. B | … | VACUOUS | true but reduces to <trivial restatement> | identity |
| C4 | §4 | … | UNVERIFIABLE | blocked by: <missing data/definition> | — |

## What would need to be true (per REFUTED claim)

### C1
- <Exact proposition 1 that would have to hold for the claim to be rescued>
- <Exact proposition 2>
- <Cost of the repair: which downstream results survive, which fall>

## Regime sanity checks

| ID | Regime tested | Independently known answer | Document's formula gives | Sign/direction/magnitude OK? |
|---|---|---|---|---|
| C1 | <e.g. flat space, δ→0> | … | … | <yes / NO — backwards> |

## Self-consistency findings

- <Mismatch 1: e.g. "Appendix B verifies single-mode commutation; body §2 asserts a
  property of a formula that is not the commutator.">
- <Symbol redefinitions, conclusion–evidence gaps, number/table mismatches>

## Costume check log

| Phrase in text | Location | Step it decorates | Verified? | Result |
|---|---|---|---|---|
| "it is easy to see" | §3 | <step> | yes | <holds / fails> |

## Second opinion (optional — independent model)

**Model:** <name> · **Context:** cold, same inventory

| ID | This review | Second model | Agreement |
|---|---|---|---|
| C1 | REFUTED | REFUTED | ✓ |
| C2 | VERIFIED | UNVERIFIABLE | **DISAGREE — see below** |

### Disagreements (surfaced, never averaged)

- C2: <each side's evidence, stated side by side; what additional check would settle it>
