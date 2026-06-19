# Comparative eval report — library vs. baseline

_Generated 2026-06-18T19:34:30.290Z from `eval/results/cp-int.jsonl` — 1 run(s) across 1 fixture(s)._

All judge verdicts below are **de-blinded**: each blind `A`/`B` winner has been
translated back to `library` / `baseline` through that run's `blinding_map`.
There is no single overall pass/fail verdict — read the breakdown.

## Per-dimension — judge win-rates (de-blinded)

Win-rate = share of scored verdicts for that dimension the arm won. Mean margin
is averaged over **all** scored verdicts for the dimension (ties contribute 0).

| Dimension | Library win | Baseline win | Tie | Mean margin | Verdicts |
| --- | ---: | ---: | ---: | ---: | ---: |
| frontmatter_quality | 0% | 100% | 0% | 0.275 | 1 |
| routing_clarity | 0% | 0% | 100% | 0.000 | 1 |
| body_actionability | 0% | 0% | 100% | 0.000 | 1 |
| single_responsibility | 0% | 0% | 100% | 0.000 | 1 |

## Per-output-type — judge win-rates (de-blinded)

Same breakdown, bucketed by `output_type`. Each run contributes one verdict per
rubric dimension to its output-type bucket.

| Output type | Library win | Baseline win | Tie | Mean margin | Verdicts |
| --- | ---: | ---: | ---: | ---: | ---: |
| library-skill | 0% | 25% | 75% | 0.069 | 4 |

## Deterministic — Tier-0 pass-rates

The only tier permitted to gate. Pass-rate is per arm across all runs; the delta
is `library − baseline` (positive = library passes more often).

| Arm | Pass-rate | Passed | Runs |
| --- | ---: | ---: | ---: |
| library | 100% | 1 | 1 |
| baseline | 0% | 0 | 1 |

Library − baseline pass-rate delta: **+100%**
