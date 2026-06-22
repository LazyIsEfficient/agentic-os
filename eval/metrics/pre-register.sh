#!/usr/bin/env bash
# pre-register.sh — stamp a hypothesis file before long-session A/B runs.
# Usage: pre-register.sh [scenario-name]
# Writes eval/metrics/runs/<timestamp>-<scenario>/hypothesis.md from the scenario template.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIO="${1:-long-session-awareness}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$DIR/runs/${STAMP}-${SCENARIO}"
TEMPLATE="$DIR/scenarios/${SCENARIO}.md"

mkdir -p "$RUN_DIR"
SHA="$(git -C "$DIR/../.." rev-parse --short HEAD 2>/dev/null || echo unknown)"
OPERATOR="${USER:-unknown}"

cat > "$RUN_DIR/hypothesis.md" <<EOF
# Pre-registration — ${SCENARIO}

- **Date / operator:** ${STAMP} / ${OPERATOR}
- **Repo SHA:** ${SHA}
- **N per arm:** ___ (fill before runs)
- **Compaction trigger:** auto | manual \`/compact\` at prompt ___
- **Scenario:** eval/metrics/scenarios/${SCENARIO}.md

## Null prior (from effectiveness investigation)

[eval/INVESTIGATION.md](../../INVESTIGATION.md) found **null** on tractable single-task
work. For awareness, the analogous prior: compaction-boundary benefit is **not guaranteed**.

## What would CONFIRM harness benefit

- Consistent post-compaction reduction in \`repeat_read_files\` / \`repeated_tool_calls\` (ON vs OFF).
- Anchor facts used correctly on late prompts (see scenario).
- ON tokens-to-completion not worse than OFF median.

## What would DISPROVE / null

- **NULL:** no consistent re-work delta; anchor correctness noise.
- **COST-DOMINATED:** ON higher cost, no re-work win.

## Decision rule (fill before runs)

| Outcome | Condition |
|---|---|
| BENEFIT CONFIRMED | ≥ 2 of 3 confirm signals; ≤ 1 contradicting pair |
| NULL | no consistent re-work direction |
| COST-DOMINATED | ON worse tokens, no re-work reduction |

## Post-run (do not edit above)

- Verdict: ___
- Median deltas: ___
- Anchor notes: ___

---
Full scenario + template: ${TEMPLATE}
EOF

echo "Pre-registration written: $RUN_DIR/hypothesis.md"
echo "Fill N, compaction trigger, and decision rule before starting runs."
