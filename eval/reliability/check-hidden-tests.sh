#!/usr/bin/env bash
#
# check-hidden-tests.sh — run a HIDDEN integration-test suite against a producer
# crate and emit a machine-readable score.
#
# Usage:
#   check-hidden-tests.sh <crate_dir> <hidden_rs_path>
#
# What it does:
#   1. Copies <crate_dir> into a throwaway stage.
#   2. Injects <hidden_rs_path> as <stage>/tests/hidden.rs (producers never see
#      this file — it is the held-out suite).
#   3. Runs `cargo test --test hidden` under best-effort containment.
#   4. Emits exactly ONE JSON line on stdout:
#        {"total":N,"passed":P,"failed":F,"failures":["test_name",...]}
#
# Scoring:
#   - Tests ran: total/passed/failed parsed from cargo's summary line; failures
#     are the named failing tests.
#   - COMPILE FAILURE (crate does not build with the hidden tests injected — e.g.
#     wrong signature, missing fn) is a DEFECT, not an environment skip:
#        total = <count of #[test] in the injected hidden file>, passed = 0,
#        failures = ["compile-error"].
#
# Exit codes (the JSON is the verdict, NOT the exit code):
#   0  -> the suite RAN (green or red — score is in the JSON), OR a compile
#         defect was scored.
#   2  -> environment-skip: cargo missing, EVAL_ALLOW_CODE_EXEC unset, or the
#         run timed out. No JSON score line is emitted in this case.
#
# !! SECURITY — UNTRUSTED CODE EXECUTION !!
# `cargo test` builds and runs model-GENERATED Rust: build.rs, proc-macros, and
# test bodies are ARBITRARY CODE executed with this process's network, fs, and
# user privileges. Flags alone cannot make cargo/rustc safe. Real isolation
# needs an OS-level sandbox (macOS `sandbox-exec`, Linux `bwrap --unshare-net`,
# or a container with `--network none`). The containment here — offline,
# throwaway CARGO_HOME + CARGO_TARGET_DIR, a hard timeout — is BEST-EFFORT and
# gated behind an explicit opt-in (EVAL_ALLOW_CODE_EXEC=1). To genuinely contain
# arbitrary code execution, run this whole script under such a sandbox.

set -euo pipefail

die_usage() {
  echo "usage: check-hidden-tests.sh <crate_dir> <hidden_rs_path>" >&2
  exit 2
}

[[ $# -eq 2 ]] || die_usage
CRATE_DIR="$1"
HIDDEN_RS="$2"

# --- environment-skip gate (exit 2, no JSON) ---------------------------------
if [[ "${EVAL_ALLOW_CODE_EXEC:-}" != "1" ]]; then
  echo "SKIP check-hidden-tests: code execution disabled; set EVAL_ALLOW_CODE_EXEC=1 to run (builds/tests untrusted model code — best-effort containment only; prefer an OS sandbox)" >&2
  exit 2
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "SKIP check-hidden-tests: cargo not found on PATH" >&2
  exit 2
fi

if [[ ! -d "$CRATE_DIR" ]]; then
  echo "SKIP check-hidden-tests: crate dir not found: $CRATE_DIR" >&2
  exit 2
fi
if [[ ! -f "$HIDDEN_RS" ]]; then
  echo "SKIP check-hidden-tests: hidden test file not found: $HIDDEN_RS" >&2
  exit 2
fi

# `timeout` (GNU) or `gtimeout` (homebrew coreutils on macOS).
TIMEOUT_BIN=""
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
else
  echo "SKIP check-hidden-tests: neither timeout nor gtimeout found" >&2
  exit 2
fi
TIMEOUT_SECS=180

# --- derive the hidden test count (for compile-defect scoring) ---------------
# Count `#[test]` attributes in the injected file. Tolerant of leading
# whitespace; ignores other attributes. This is the DEFECT total when the crate
# fails to compile (so a wrong signature scores total/0/compile-error, not 0/0).
HIDDEN_TEST_COUNT="$(grep -cE '^[[:space:]]*#\[test\]' "$HIDDEN_RS" || true)"
if [[ -z "$HIDDEN_TEST_COUNT" || "$HIDDEN_TEST_COUNT" -eq 0 ]]; then
  echo "SKIP check-hidden-tests: no #[test] found in $HIDDEN_RS (cannot score)" >&2
  exit 2
fi

# --- throwaway stage + cargo scratch -----------------------------------------
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/hidcheck.stage.XXXXXX")"
SCRATCH_CARGO_HOME="$(mktemp -d "${TMPDIR:-/tmp}/hidcheck.cargohome.XXXXXX")"
SCRATCH_TARGET="$(mktemp -d "${TMPDIR:-/tmp}/hidcheck.target.XXXXXX")"
cleanup() { rm -rf "$STAGE" "$SCRATCH_CARGO_HOME" "$SCRATCH_TARGET"; }
trap cleanup EXIT

# Copy the producer crate into the stage. Reject symlinks in the source tree —
# a symlink could let the copy or the build reach outside the stage.
if find "$CRATE_DIR" -type l | grep -q .; then
  echo "SKIP check-hidden-tests: crate dir contains a symlink (rejected): $CRATE_DIR" >&2
  exit 2
fi
cp -R "$CRATE_DIR/." "$STAGE/"

# Inject the hidden suite. Overwrite any same-named file a producer might have
# planted; their tests/ dir is irrelevant to the hidden run.
mkdir -p "$STAGE/tests"
cp "$HIDDEN_RS" "$STAGE/tests/hidden.rs"

# --- run the hidden suite under containment ----------------------------------
RAW_OUT="$STAGE/.cargo_test_output.txt"
set +e
CARGO_NET_OFFLINE=true \
CARGO_HOME="$SCRATCH_CARGO_HOME" \
CARGO_TARGET_DIR="$SCRATCH_TARGET" \
"$TIMEOUT_BIN" "$TIMEOUT_SECS" \
  cargo test --manifest-path "$STAGE/Cargo.toml" --test hidden \
  >"$RAW_OUT" 2>&1
RC=$?
set -e

# timeout(1) exits 124 when it kills the child.
if [[ "$RC" -eq 124 ]]; then
  echo "SKIP check-hidden-tests: timed out after ${TIMEOUT_SECS}s" >&2
  exit 2
fi

# --- parse cargo output ------------------------------------------------------
# Cargo's libtest summary line looks like:
#   test result: ok. 8 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
# or                FAILED. 6 passed; 2 failed; ...
# Failing test names appear under a "failures:" section, one indented name per
# line, before the "test result:" line.

emit_json() {
  # $1=total $2=passed $3=failed $4=failures_json_array
  printf '{"total":%s,"passed":%s,"failed":%s,"failures":%s}\n' "$1" "$2" "$3" "$4"
}

# Grab the last "test result:" summary line (the integration test's summary).
SUMMARY_LINE="$(grep -E '^test result:' "$RAW_OUT" | tail -n 1 || true)"

if [[ -z "$SUMMARY_LINE" ]]; then
  # No summary line => the crate did not build/run the hidden harness. Treat as
  # a compile/link DEFECT (wrong signature, missing fn, build error, etc.).
  # This is exit 0 with a scored defect — it RAN the attempt; the score is the
  # verdict.
  emit_json "$HIDDEN_TEST_COUNT" 0 0 '["compile-error"]'
  # Note: failed is 0 here and failures=["compile-error"]; total>0,passed=0
  # signals every hidden test is unsatisfied. (Defect, not env-skip.)
  exit 0
fi

PASSED="$(printf '%s\n' "$SUMMARY_LINE" | sed -nE 's/.*[[:space:]]([0-9]+) passed;.*/\1/p')"
FAILED="$(printf '%s\n' "$SUMMARY_LINE" | sed -nE 's/.*;[[:space:]]([0-9]+) failed;.*/\1/p')"
PASSED="${PASSED:-0}"
FAILED="${FAILED:-0}"
TOTAL=$((PASSED + FAILED))

# Collect failing test names from the "failures:" listing. libtest prints the
# names twice (once with details, once as a plain bulleted list near the end);
# we take the final plain list block.
#   failures:
#       module::test_name
#       module::other
#
# test result: FAILED. ...
FAILURES_JSON='[]'
if [[ "$FAILED" -gt 0 ]]; then
  # Extract lines that are indented test paths appearing after the LAST
  # "failures:" header and before the summary line.
  NAMES="$(awk '
    /^failures:$/ { inblock=1; delete seen_block; lastblock=NR; buf=""; next }
    inblock {
      if ($0 ~ /^test result:/) { inblock=0; next }
      # indented, non-empty, looks like a test path (contains no spaces after trim)
      line=$0
      gsub(/^[[:space:]]+/, "", line)
      gsub(/[[:space:]]+$/, "", line)
      if (line != "" && line !~ /[[:space:]]/) { print line }
    }
  ' "$RAW_OUT" | sort -u)"

  if [[ -n "$NAMES" ]]; then
    # Build a JSON array of strings. Test names are Rust idents/paths — safe
    # characters only (alnum, _, ::), so simple quoting is sufficient.
    FAILURES_JSON="$(printf '%s\n' "$NAMES" | awk '
      BEGIN { printf "[" }
      { if (NR>1) printf ","; printf "\"%s\"", $0 }
      END { printf "]" }
    ')"
  fi
fi

emit_json "$TOTAL" "$PASSED" "$FAILED" "$FAILURES_JSON"
exit 0
