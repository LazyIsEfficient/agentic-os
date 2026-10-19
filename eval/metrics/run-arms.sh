#!/usr/bin/env bash
# run-arms.sh — run one scenario under the ON arm (agentic-os installed) and the
# OFF arm (nothing installed), then compare their metrics.
#
# ISOLATION: each arm runs in its own `mktemp -d` root with its own HOME and
# CLAUDE_CONFIG_DIR, an allowlisted environment, and a scrubbed export of the
# repo as its working directory. The ON arm gets the library via install.sh
# into that temp config only; the real ~/.claude is never read or written. A
# Tier 0 preflight (lib/arm-isolation.sh) aborts the run if an arm's effective
# config is not what it should be, and records the result in
# <out>/isolation.jsonl. See README.md "Arm isolation".
#
# AUTH: a fresh config dir has no login. Export ANTHROPIC_API_KEY (or
# CLAUDE_CODE_OAUTH_TOKEN) yourself; it is passed to the child env only.
#
# Produces ONE STOCHASTIC SAMPLE, not a reproducible number (LLM runs vary). To
# actually exercise the awareness BENEFIT, the scenario must be long / multi-step
# enough to cross a compaction boundary — a short prompt only smoke-tests the
# plumbing. See README.md.
#
# Usage: run-arms.sh [--keep] [--out DIR] "<scenario prompt>"
#   --keep     keep the per-arm temp roots (they may contain transcripts)
#   --out DIR  where isolation.jsonl and logs go (default: runs/<stamp>-arms)
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd)"
# shellcheck source=lib/arm-isolation.sh
source "$DIR/lib/arm-isolation.sh"

KEEP=0
OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --out) OUT="${2:?--out needs a directory}"; shift 2 ;;
    --) shift; break ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done
PROMPT="${1:?usage: run-arms.sh [--keep] [--out DIR] \"<scenario prompt>\"}"

command -v claude >/dev/null 2>&1 || { echo "claude CLI not found"; exit 1; }
command -v node   >/dev/null 2>&1 || { echo "node not found"; exit 1; }
command -v jq     >/dev/null 2>&1 || { echo "jq not found (install.sh needs it to register ON-arm hooks)"; exit 1; }
AUTH_VAR="$(iso_auth_var)" || { iso_auth_help; exit 1; }

# node is already required (compare.mjs); use its UUID rather than depend on uuidgen.
gen_id() { node -e 'console.log(crypto.randomUUID())'; }
RUN_ID="$(gen_id)"
REPO_SHA="$(git -C "$REPO" rev-parse --short HEAD 2>/dev/null || echo unknown)"
OUT="${OUT:-$DIR/runs/$(date -u +%Y%m%dT%H%M%SZ)-arms}"
mkdir -p "$OUT"
LEDGER="$OUT/isolation.jsonl"

ROOTS=()
cleanup() {
  local r
  [ "${#ROOTS[@]}" -gt 0 ] || return 0
  if [ "$KEEP" = 1 ]; then
    for r in "${ROOTS[@]}"; do [ -e "$r" ] && echo "kept arm root: $r"; done
  else
    for r in "${ROOTS[@]}"; do rm -rf "$r"; done
  fi
}
trap cleanup EXIT

# Both arms are built from a HEAD export, never the working tree, so
# REPO_SHA is exactly what ran.
if [ -n "$(git -C "$REPO" status --porcelain 2>/dev/null)" ]; then
  echo "note: working tree is dirty; arms use committed HEAD ($REPO_SHA) only, uncommitted changes are NOT tested." >&2
fi
SRC="$(mktemp -d "${TMPDIR:-/tmp}/run-arms-src.XXXXXX")" || { echo "mktemp failed" >&2; exit 1; }
ROOTS+=("$SRC")
iso_export_src "$REPO" "$SRC" || { echo "export of HEAD failed" >&2; exit 1; }

# setup_arm <on|off>: appends the arm root to ROOTS; aborts the run on failure.
setup_arm() {
  local arm="$1" root
  root="$(iso_make_root)" || { echo "mktemp failed" >&2; exit 1; }
  ROOTS+=("$root")
  iso_export_task "$SRC" "$root/task" || { echo "task export failed ($arm)" >&2; exit 1; }
  if [ "$arm" = on ]; then
    iso_install_library "$SRC" "$root" "$OUT/install-on.log" \
      || { echo "install.sh into the ON temp config failed; see $OUT/install-on.log" >&2; exit 1; }
  fi
}

# preflight_arm <on|off> <root> <session_id>: Tier 0, blocking.
preflight_arm() {
  local arm="$1" root="$2" sid="$3" ok=0 f
  iso_preflight "$arm" "$root" "$SRC" || ok=1
  iso_record "$LEDGER" "$arm" "$sid" "$RUN_ID" "$REPO_SHA" "$AUTH_VAR"
  [ "$ok" = 0 ] && return 0
  echo "PREFLIGHT FAILED ($arm arm) — aborting; nothing was sent to claude:" >&2
  for f in "${ISO_FAILS[@]}"; do echo "  - $f" >&2; done
  exit 1
}

# run_arm <on|off> <root> <session_id>
run_arm() {
  local arm="$1" root="$2" sid="$3"
  iso_exec "$root" "$AUTH_VAR" -- claude -p "$PROMPT" --session-id "$sid" \
    --dangerously-skip-permissions >"$OUT/claude-$arm.log" 2>&1 \
    || echo "  ($arm arm exited non-zero; see $OUT/claude-$arm.log)"
}

ON_ID="$(gen_id)"; OFF_ID="$(gen_id)"
setup_arm on;  ON_ROOT="${ROOTS[1]}"
setup_arm off; OFF_ROOT="${ROOTS[2]}"
# Both arms pass preflight before either one sends a prompt.
preflight_arm on "$ON_ROOT" "$ON_ID"
preflight_arm off "$OFF_ROOT" "$OFF_ID"
# The pristine export holds the full library; drop it before any arm runs.
rm -rf "$SRC"

echo "ON arm  (agentic-os installed into a temp CLAUDE_CONFIG_DIR) …"
run_arm on "$ON_ROOT" "$ON_ID"
echo "OFF arm (fresh, empty CLAUDE_CONFIG_DIR) …"
run_arm off "$OFF_ROOT" "$OFF_ID"
echo "isolation record: $LEDGER"

ON_TX="$(ls "$ON_ROOT"/home/.claude/projects/*/"$ON_ID".jsonl 2>/dev/null | head -1)"
OFF_TX="$(ls "$OFF_ROOT"/home/.claude/projects/*/"$OFF_ID".jsonl 2>/dev/null | head -1)"
if [ ! -f "${ON_TX:-}" ] || [ ! -f "${OFF_TX:-}" ]; then
  echo "could not locate arm transcripts (ON=$ON_ID OFF=$OFF_ID)"; exit 1
fi

echo ""
node "$DIR/compare.mjs" "$ON_TX" "$OFF_TX"
echo ""
echo "NOTE: one sample. For a real result use a long multi-step scenario; repeat N times and look at the distribution, not a single delta."
