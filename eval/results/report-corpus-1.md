# Comparative eval report — library vs. baseline

_Generated 2026-06-18T19:49:36.872Z from `eval/results/corpus-1.jsonl` — 5 run(s) across 5 fixture(s)._

All judge verdicts below are **de-blinded**: each blind `A`/`B` winner has been
translated back to `library` / `baseline` through that run's `blinding_map`.
There is no single overall pass/fail verdict — read the breakdown.

## Per-dimension — judge win-rates (de-blinded)

Win-rate = share of scored verdicts for that dimension the arm won. Mean margin
is averaged over **all** scored verdicts for the dimension (ties contribute 0).

| Dimension | Library win | Baseline win | Tie | Mean margin | Verdicts |
| --- | ---: | ---: | ---: | ---: | ---: |
| frontmatter_quality | 100% | 0% | 0% | 0.275 | 2 |
| routing_clarity | 50% | 0% | 50% | 0.175 | 2 |
| body_actionability | 0% | 50% | 50% | 0.100 | 2 |
| single_responsibility | 0% | 0% | 100% | 0.000 | 2 |
| correctness | 0% | 0% | 100% | 0.000 | 1 |
| test_coverage | 100% | 0% | 0% | 0.300 | 1 |
| idiomatic_rust | 0% | 0% | 100% | 0.000 | 1 |
| simplicity | 0% | 0% | 100% | 0.000 | 1 |
| derivation_correctness | 0% | 0% | 100% | 0.000 | 1 |
| simulation_validity | 0% | 0% | 100% | 0.000 | 1 |
| statistical_rigor | 100% | 0% | 0% | 0.150 | 1 |
| reproducibility | 0% | 100% | 0% | 0.200 | 1 |
| self_containment | 0% | 100% | 0% | 1.000 | 1 |
| responsiveness | 0% | 100% | 0% | 1.000 | 1 |
| accessibility | 0% | 100% | 0% | 1.000 | 1 |
| polish | 0% | 100% | 0% | 1.000 | 1 |

## Per-output-type — judge win-rates (de-blinded)

Same breakdown, bucketed by `output_type`. Each run contributes one verdict per
rubric dimension to its output-type bucket.

| Output type | Library win | Baseline win | Tie | Mean margin | Verdicts |
| --- | ---: | ---: | ---: | ---: | ---: |
| library-skill | 38% | 13% | 50% | 0.138 | 8 |
| code | 25% | 0% | 75% | 0.075 | 4 |
| claims-doc | 25% | 25% | 50% | 0.087 | 4 |
| pod-deliverable | 0% | 100% | 0% | 1.000 | 4 |

## Deterministic — Tier-0 pass-rates

The only tier permitted to gate. Pass-rate is per arm across all runs; the delta
is `library − baseline` (positive = library passes more often).

| Arm | Pass-rate | Passed | Runs |
| --- | ---: | ---: | ---: |
| library | 40% | 2 | 5 |
| baseline | 0% | 0 | 5 |

Library − baseline pass-rate delta: **+40%**
