#!/usr/bin/env bash
# run-arms.sh — run one scenario under the ON arm (awareness hooks active) and the
# OFF arm (`claude --bare`, hooks skipped), then compare their metrics.
#
# Produces ONE STOCHASTIC SAMPLE, not a reproducible number (LLM runs vary). To
# actually exercise the awareness BENEFIT, the scenario must be long / multi-step
# enough to cross a compaction boundary — a short prompt only smoke-tests the
# plumbing. See README.md.
#
# Usage: run-arms.sh "<scenario prompt>"
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd)"
PROMPT="${1:?usage: run-arms.sh \"<scenario prompt>\"}"

command -v claude >/dev/null 2>&1 || { echo "claude CLI not found"; exit 1; }
command -v node   >/dev/null 2>&1 || { echo "node not found"; exit 1; }

# node is already required (compare.mjs); use its UUID rather than depend on uuidgen.
gen_id() { node -e 'console.log(crypto.randomUUID())'; }
ON_ID="$(gen_id)"; OFF_ID="$(gen_id)"
PROJ="$HOME/.claude/projects"

echo "ON arm  (awareness hooks active) …"
( cd "$REPO" && claude -p "$PROMPT" --session-id "$ON_ID" \
    --settings "$REPO/.claude/settings.json" --dangerously-skip-permissions \
    >/dev/null 2>&1 ) || echo "  (on arm exited non-zero)"

# OFF baseline = no awareness hooks, everything else equal. Empty inline settings
# (not --bare, which also strips LSP/plugins and confounds the comparison).
echo "OFF arm (no awareness hooks; everything else equal) …"
( cd "$REPO" && claude -p "$PROMPT" --session-id "$OFF_ID" \
    --settings '{"hooks":{}}' --dangerously-skip-permissions \
    >/dev/null 2>&1 ) || echo "  (off arm exited non-zero)"

ON_TX="$(ls "$PROJ"/*/"$ON_ID".jsonl 2>/dev/null | head -1)"
OFF_TX="$(ls "$PROJ"/*/"$OFF_ID".jsonl 2>/dev/null | head -1)"
if [ ! -f "${ON_TX:-}" ] || [ ! -f "${OFF_TX:-}" ]; then
  echo "could not locate arm transcripts (ON=$ON_ID OFF=$OFF_ID under $PROJ)"; exit 1
fi

echo ""
node "$DIR/compare.mjs" "$ON_TX" "$OFF_TX"
echo ""
echo "NOTE: one sample. For a real result use a long multi-step scenario; repeat N times and look at the distribution, not a single delta."
