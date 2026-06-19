# Comparative eval report — library vs. baseline

_Generated 2026-06-18T20:08:16.918Z from `eval/results/corpus-2.jsonl` — 5 run(s) across 5 fixture(s)._

All judge verdicts below are **de-blinded**: each blind `A`/`B` winner has been
translated back to `library` / `baseline` through that run's `blinding_map`.
There is no single overall pass/fail verdict — read the breakdown.

## Per-dimension — judge win-rates (de-blinded)

Win-rate = share of scored verdicts for that dimension the arm won. Mean margin
is averaged over **all** scored verdicts for the dimension (ties contribute 0).

| Dimension | Library win | Baseline win | Tie | Mean margin | Verdicts |
| --- | ---: | ---: | ---: | ---: | ---: |
| frontmatter_quality | 50% | 50% | 0% | 0.363 | 2 |
| routing_clarity | 50% | 50% | 0% | 0.313 | 2 |
| body_actionability | 50% | 0% | 50% | 0.138 | 2 |
| single_responsibility | 0% | 0% | 100% | 0.000 | 2 |
| correctness | 0% | 0% | 100% | 0.000 | 1 |
| test_coverage | 100% | 0% | 0% | 0.350 | 1 |
| idiomatic_rust | 100% | 0% | 0% | 0.150 | 1 |
| simplicity | 0% | 0% | 100% | 0.000 | 1 |
| derivation_correctness | 0% | 0% | 100% | 0.000 | 1 |
| simulation_validity | 100% | 0% | 0% | 0.175 | 1 |
| statistical_rigor | 0% | 100% | 0% | 0.250 | 1 |
| reproducibility | 100% | 0% | 0% | 0.200 | 1 |
| self_containment | 0% | 0% | 100% | 0.000 | 1 |
| responsiveness | 100% | 0% | 0% | 0.150 | 1 |
| accessibility | 100% | 0% | 0% | 0.300 | 1 |
| polish | 100% | 0% | 0% | 0.200 | 1 |

## Per-output-type — judge win-rates (de-blinded)

Same breakdown, bucketed by `output_type`. Each run contributes one verdict per
rubric dimension to its output-type bucket.

| Output type | Library win | Baseline win | Tie | Mean margin | Verdicts |
| --- | ---: | ---: | ---: | ---: | ---: |
| library-skill | 38% | 25% | 38% | 0.203 | 8 |
| code | 50% | 0% | 50% | 0.125 | 4 |
| claims-doc | 50% | 25% | 25% | 0.156 | 4 |
| pod-deliverable | 75% | 0% | 25% | 0.162 | 4 |

## Deterministic — Tier-0 pass-rates

The only tier permitted to gate. Pass-rate is per arm across all runs; the delta
is `library − baseline` (positive = library passes more often).

| Arm | Pass-rate | Passed | Runs |
| --- | ---: | ---: | ---: |
| library | 100% | 5 | 5 |
| baseline | 60% | 3 | 5 |

Library − baseline pass-rate delta: **+40%**
