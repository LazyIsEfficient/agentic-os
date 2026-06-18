#!/usr/bin/env bash
#
# run-dogfood.sh — the v2 dogfood vertical slice.
#
# Drives ONE real pod run (technical-pm + engineer + library-reviewer) to author
# a single library skill, then GATES the emitted skill with the deterministic
# validator (`scripts/validate.sh`). This is the only script in the slice that
# spends subscription tokens — `cargo test` exercises the plumbing for free.
#
# Pipeline:
#   1. cargo build (the runtime bin).
#   2. runtime run    --task tasks/author-skill.md --run <RUN_ID>   (the pod loop)
#   3. runtime inspect <RUN_ID>                  -> captured to a transcript file
#   4. runtime materialize <RUN_ID> --out <SKILL_DIR>   (fail-closed path sanitize)
#   5. bash scripts/validate.sh <STAGE_ROOT>     (Tier 0 gate on the emitted skill)
#   6. print PASS / FAIL.
#
# Overridable via env:
#   RUN_ID      run id (default: dogfood-<unix-seconds>)
#   SKILL_NAME  emitted skill dir name (default: commit-message-conventions)
#   STAGE_ROOT  isolated REPO_ROOT the validator runs against
#               (default: a fresh temp dir; the emitted skill is staged at
#                $STAGE_ROOT/.claude/skills/$SKILL_NAME so the gate scores ONLY
#                this skill and never mutates the real library)
#   OUT_DIR     materialize target (default: $STAGE_ROOT/.claude/skills/$SKILL_NAME)
#
# Usage:
#   bash runtime/run-dogfood.sh
#   RUN_ID=demo SKILL_NAME=pull-request-descriptions bash runtime/run-dogfood.sh

set -euo pipefail

# ── Resolve paths from this script's location (works from any CWD) ─────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../runtime
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"                    # repo root
VALIDATE="$REPO_ROOT/scripts/validate.sh"
TASK="$SCRIPT_DIR/tasks/author-skill.md"

if [[ ! -f "$VALIDATE" ]]; then
  echo "FATAL: validator not found at $VALIDATE" >&2
  exit 2
fi
if [[ ! -f "$TASK" ]]; then
  echo "FATAL: task file not found at $TASK" >&2
  exit 2
fi

# ── Config (env-overridable) ───────────────────────────────────────────────────
RUN_ID="${RUN_ID:-dogfood-$(date +%s)}"
SKILL_NAME="${SKILL_NAME:-commit-message-conventions}"
STAGE_ROOT="${STAGE_ROOT:-$(mktemp -d "${TMPDIR:-/tmp}/dogfood-stage.XXXXXX")}"
OUT_DIR="${OUT_DIR:-$STAGE_ROOT/.claude/skills/$SKILL_NAME}"
TRANSCRIPT="$SCRIPT_DIR/target/dogfood-$RUN_ID.transcript.txt"

# validate.sh requires $STAGE_ROOT/.claude to exist (exit 2 otherwise).
mkdir -p "$STAGE_ROOT/.claude/skills"
mkdir -p "$OUT_DIR"
mkdir -p "$SCRIPT_DIR/target"

BIN="$SCRIPT_DIR/target/debug/v2-runtime"

echo "== dogfood vertical slice =="
echo "  run id     : $RUN_ID"
echo "  skill name : $SKILL_NAME"
echo "  task       : $TASK"
echo "  out dir    : $OUT_DIR"
echo "  stage root : $STAGE_ROOT"
echo "  transcript : $TRANSCRIPT"
echo

# ── 1. Build ───────────────────────────────────────────────────────────────────
echo "[1/5] cargo build"
( cd "$SCRIPT_DIR" && cargo build )

# ── 2. Run the pod loop (SPENDS TOKENS) ────────────────────────────────────────
echo "[2/5] runtime run --task <task> --run $RUN_ID"
"$BIN" run --task "$TASK" --run "$RUN_ID"

# ── 3. Capture the blackboard transcript ───────────────────────────────────────
echo "[3/5] runtime inspect $RUN_ID -> $TRANSCRIPT"
"$BIN" inspect "$RUN_ID" | tee "$TRANSCRIPT"

# ── 4. Materialize the artifact (fail-closed path sanitizer) ───────────────────
echo "[4/5] runtime materialize $RUN_ID --out $OUT_DIR"
"$BIN" materialize "$RUN_ID" --out "$OUT_DIR"

# ── 5. Gate the emitted skill with the deterministic validator ─────────────────
# Contract (scripts/validate.sh header): `bash scripts/validate.sh [REPO_ROOT]`.
# It validates the WHOLE library under <REPO_ROOT>/.claude. We point it at the
# isolated STAGE_ROOT so only the freshly emitted skill is scored.
echo "[5/5] bash scripts/validate.sh $STAGE_ROOT"
if bash "$VALIDATE" "$STAGE_ROOT"; then
  echo
  echo "DOGFOOD: PASS — emitted skill '$SKILL_NAME' passes scripts/validate.sh"
  exit 0
else
  echo
  echo "DOGFOOD: FAIL — emitted skill '$SKILL_NAME' did not pass scripts/validate.sh"
  exit 1
fi
