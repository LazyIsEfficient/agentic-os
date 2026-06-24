#!/usr/bin/env bash
# verify-data-model-section.sh — Tier 0 compare DATA_MODEL.md section to schema extract.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$DIR/verify-section.py" "$@"
