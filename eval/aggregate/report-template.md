<!--
  Markdown skeleton that aggregate.mjs fills. Edit headings / prose here without
  touching code. Placeholders are {{TOKEN}} (whole tables are injected, not
  templated cell-by-cell). Recognized tokens:
    {{GENERATED_AT}}    ISO timestamp of report generation
    {{SOURCE}}          path of the results JSONL
    {{RUN_COUNT}}       number of result records read
    {{FIXTURE_COUNT}}   number of distinct fixtures
    {{PER_DIMENSION_TABLE}}
    {{PER_OUTPUT_TYPE_TABLE}}
    {{DETERMINISTIC_TABLE}}
  Any recognized token not provided renders as an empty string.
-->
# Comparative eval report — library vs. baseline

_Generated {{GENERATED_AT}} from `{{SOURCE}}` — {{RUN_COUNT}} run(s) across {{FIXTURE_COUNT}} fixture(s)._

All judge verdicts below are **de-blinded**: each blind `A`/`B` winner has been
translated back to `library` / `baseline` through that run's `blinding_map`.
There is no single overall pass/fail verdict — read the breakdown.

## Per-dimension — judge win-rates (de-blinded)

Win-rate = share of scored verdicts for that dimension the arm won. Mean margin
is averaged over **all** scored verdicts for the dimension (ties contribute 0).

{{PER_DIMENSION_TABLE}}

## Per-output-type — judge win-rates (de-blinded)

Same breakdown, bucketed by `output_type`. Each run contributes one verdict per
rubric dimension to its output-type bucket.

{{PER_OUTPUT_TYPE_TABLE}}

## Deterministic — Tier-0 pass-rates

The only tier permitted to gate. Pass-rate is per arm across all runs; the delta
is `library − baseline` (positive = library passes more often).

{{DETERMINISTIC_TABLE}}
