#!/usr/bin/env bash
# extract-data-model-test.sh — Tier 0 tests for JSON Schema extract + verify.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EDM="$REPO/scripts/extract-data-model"
FIX="$EDM/fixtures"

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

golden="$(bash "$EDM/json-schema.sh" "$FIX/order-created.schema.json")"
if printf '%s' "$golden" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['extractor']=='json-schema' and len(d['properties'])==3"; then
  pass "extract-json-schema output"
else
  fail "extract-json-schema output"
fi

run1="$(bash "$EDM/json-schema.sh" "$FIX/order-created.schema.json")"
run2="$(bash "$EDM/json-schema.sh" "$FIX/order-created.schema.json")"
if [[ "$run1" == "$run2" ]]; then
  pass "extract deterministic"
else
  fail "extract deterministic"
fi

if bash "$EDM/verify-data-model-section.sh" \
  --source "$FIX/order-created.schema.json" \
  --catalog "$FIX/DATA_MODEL-order-created.md" \
  --section OrderCreated \
  --fail-on-warn; then
  pass "verify matching fixture with fail-on-warn"
else
  fail "verify matching fixture with fail-on-warn"
fi

bad_catalog="$(mktemp)"
trap 'rm -f "$bad_catalog"' EXIT
sed 's/`lineItems` | `array<object>`/`phantom` | `string`/' "$FIX/DATA_MODEL-order-created.md" > "$bad_catalog"
if bash "$EDM/verify-data-model-section.sh" \
  --source "$FIX/order-created.schema.json" \
  --catalog "$bad_catalog" \
  --section OrderCreated 2>/dev/null; then
  fail "verify should trip on phantom property"
else
  pass "verify trips on phantom property"
fi

echo "extract-data-model-test: OK"
