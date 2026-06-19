# Reliability breakdown — run `rel-1`

Fixtures: 3 · Arms: baseline, self-review, pod · Total unit records: 45

## 1. Headline — per arm, averaged across fixtures

Each metric is the mean over fixtures of that fixture's (fixture, arm) cell. Lower `defect_rate` and higher `clean_rate` / `floor` mean more reliable.

| arm | mean defect_rate | mean clean_rate | mean floor |
| --- | --- | --- | --- |
| baseline | 0.0% | 100.0% | 1.000 |
| self-review | 6.7% | 93.3% | 0.857 |
| pod | 0.0% | 100.0% | 1.000 |

## 2. Per fixture × arm

| fixture | arm | defect_rate | clean_rate | floor | mean_score | runs |
| --- | --- | --- | --- | --- | --- | --- |
| chunk-utf8 | baseline | 0.0% | 100.0% | 1.000 | 1.000 | 5 |
| chunk-utf8 | self-review | 20.0% | 80.0% | 0.571 | 0.914 | 5 |
| chunk-utf8 | pod | 0.0% | 100.0% | 1.000 | 1.000 | 5 |
| merge-intervals | baseline | 0.0% | 100.0% | 1.000 | 1.000 | 5 |
| merge-intervals | self-review | 0.0% | 100.0% | 1.000 | 1.000 | 5 |
| merge-intervals | pod | 0.0% | 100.0% | 1.000 | 1.000 | 5 |
| read-under-base | baseline | 0.0% | 100.0% | 1.000 | 1.000 | 5 |
| read-under-base | self-review | 0.0% | 100.0% | 1.000 | 1.000 | 5 |
| read-under-base | pod | 0.0% | 100.0% | 1.000 | 1.000 | 5 |

## 3. Per-trap attribution — which edge each arm misses

For each fixture, each row is a hidden-test name that failed in at least one run. The cell is how many of that arm's runs MISSED that test (out of the arm's run count, shown in the header). `compile-error` / `no-artifact` / `env-skip` are whole-suite misses.

### chunk-utf8

| test | baseline (n=5) | self-review (n=5) | pod (n=5) |
| --- | --- | --- | --- |
| even_split_ascii | 0 | 1 | 0 |
| never_splits_two_byte_char | 0 | 1 | 0 |
| ragged_last_chunk_ascii | 0 | 1 | 0 |

### merge-intervals

_No hidden test ever failed for this fixture — every run clean._

### read-under-base

_No hidden test ever failed for this fixture — every run clean._
