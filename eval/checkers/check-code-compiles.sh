#!/usr/bin/env bash
#
# check-code-compiles.sh — Tier-0 checker for kind=cargo-test.
#
# For a Rust code artifact, the build+test IS the deterministic check. Given a
# directory:
#   - if it contains a Cargo.toml -> run `cargo test` in it; PASS iff green.
#   - else fall back to a `rustc` compile of the discovered .rs files; PASS iff
#     it compiles (no test run — there is no Cargo harness to run).
# Given a single .rs file -> `rustc` compile of that file.
#
# If the required toolchain is unavailable, exit 2 (environment-skip) and say so.
# We NEVER silently pass when we could not actually build.
#
# !! SECURITY — UNTRUSTED CODE EXECUTION !!
# This checker can build+test model-GENERATED Rust. `cargo test` runs build.rs,
# proc-macro expansion, and test bodies — i.e. ARBITRARY CODE from an untrusted
# artifact, with this process's network, filesystem, and user privileges. There
# is no way to make `cargo`/`rustc` safe by flags alone. Real isolation requires
# an OS-level sandbox: macOS `sandbox-exec`, Linux `bwrap --unshare-net`, or a
# container with `--network none`. The containment below (offline, throwaway
# CARGO_HOME/target, timeout) is BEST-EFFORT for a local harness and is gated
# behind an explicit opt-in (EVAL_ALLOW_CODE_EXEC=1) so execution is never the
# silent default. To genuinely contain ACE, run this whole script under such a
# sandbox.
#
# Usage:
#   check-code-compiles.sh <artifact_dir_or_rs_file>
#
# Contract: exit 0 = PASS (builds + tests green), 1 = FAIL (build/test failed),
#           2 = could-not-run (missing artifact / toolchain unavailable /
#               code-exec opt-in absent).

set -euo pipefail

# Code execution (cargo/rustc on untrusted source) is OFF unless explicitly
# opted into. Skip (exit 2) rather than silently pass — a could-not-run, not a
# verdict on the artifact.
if [[ "${EVAL_ALLOW_CODE_EXEC:-}" != "1" ]]; then
  echo "SKIP check-code-compiles: code execution disabled; set EVAL_ALLOW_CODE_EXEC=1 to run (builds/tests untrusted model code — best-effort containment only; prefer an OS sandbox)"
  exit 2
fi

# Bound any single cargo/rustc invocation. `timeout` (coreutils / gtimeout on
# macOS via brew) is optional; degrade to running the command unwrapped if
# absent. Use `env` (not an empty array) as the no-op prefix: expanding an empty
# array under `set -u` is an "unbound variable" error on bash 3.2 (macOS).
CODE_EXEC_TIMEOUT="${EVAL_CODE_EXEC_TIMEOUT:-120}"
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT=(timeout "$CODE_EXEC_TIMEOUT")
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT=(gtimeout "$CODE_EXEC_TIMEOUT")
else
  TIMEOUT=(env)
fi

if [[ $# -lt 1 ]]; then
  echo "SKIP check-code-compiles: no artifact path given"
  exit 2
fi
ARTIFACT="$1"

if [[ ! -e "$ARTIFACT" ]]; then
  echo "SKIP check-code-compiles: artifact '$ARTIFACT' does not exist"
  exit 2
fi

have() { command -v "$1" >/dev/null 2>&1; }

# ── Single .rs file: rustc compile-only ──────────────────────────────────────
if [[ -f "$ARTIFACT" ]]; then
  case "$ARTIFACT" in
    *.rs) : ;;
    *) echo "SKIP check-code-compiles: '$ARTIFACT' is a file but not a .rs source"; exit 2 ;;
  esac
  if ! have rustc; then
    echo "SKIP check-code-compiles: rustc not on PATH — cannot build (environment-skip)"
    exit 2
  fi
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/check-rustc.XXXXXX")"
  trap 'rm -rf "$tmp"' EXIT
  if "${TIMEOUT[@]}" rustc --edition 2021 --crate-type lib -o "$tmp/out" "$ARTIFACT" >"$tmp/log" 2>&1; then
    echo "PASS check-code-compiles: rustc compiled $(basename "$ARTIFACT")"
    exit 0
  fi
  echo "FAIL check-code-compiles: rustc failed on $(basename "$ARTIFACT") — $(grep -m1 '^error' "$tmp/log" || echo 'see compiler output')"
  exit 1
fi

# ── Directory ────────────────────────────────────────────────────────────────
if [[ -f "$ARTIFACT/Cargo.toml" ]]; then
  if ! have cargo; then
    echo "SKIP check-code-compiles: cargo not on PATH — cannot build Cargo project (environment-skip)"
    exit 2
  fi
  # Containment: throwaway CARGO_HOME + target dir + build log under mktemp (NOT
  # inside the artifact — writing there mutates the artifact under test and races
  # concurrent arms), offline (no registry/git fetches from untrusted manifests),
  # and a hard timeout. This bounds blast radius; it does NOT sandbox ACE — see
  # the security header. Run under an OS sandbox for real isolation.
  cargo_tmp="$(mktemp -d "${TMPDIR:-/tmp}/check-cargo.XXXXXX")"
  trap 'rm -rf "$cargo_tmp"' EXIT
  if ( cd "$ARTIFACT" \
        && CARGO_NET_OFFLINE=true \
           CARGO_HOME="$cargo_tmp/cargo-home" \
           CARGO_TARGET_DIR="$cargo_tmp/target" \
           "${TIMEOUT[@]}" cargo test --quiet ) >/dev/null 2>"$cargo_tmp/log"; then
    echo "PASS check-code-compiles: cargo test green in $(basename "$ARTIFACT")"
    exit 0
  fi
  msg="$(grep -m1 -E '^(error|test result:)' "$cargo_tmp/log" 2>/dev/null || echo 'see cargo output')"
  echo "FAIL check-code-compiles: cargo test failed in $(basename "$ARTIFACT") — $msg"
  exit 1
fi

# No Cargo project — fall back to compiling discovered .rs files with rustc.
mapfile -t RS < <(find "$ARTIFACT" -name '*.rs' -type f | sort)
if [[ ${#RS[@]} -eq 0 ]]; then
  echo "SKIP check-code-compiles: no Cargo.toml and no .rs files under '$ARTIFACT'"
  exit 2
fi
if ! have rustc; then
  echo "SKIP check-code-compiles: rustc not on PATH — cannot build (environment-skip)"
  exit 2
fi
tmp="$(mktemp -d "${TMPDIR:-/tmp}/check-rustc.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
for f in "${RS[@]}"; do
  if ! "${TIMEOUT[@]}" rustc --edition 2021 --crate-type lib -o "$tmp/out" "$f" >"$tmp/log" 2>&1; then
    echo "FAIL check-code-compiles: rustc failed on $f — $(grep -m1 '^error' "$tmp/log" || echo 'see compiler output')"
    exit 1
  fi
done
echo "PASS check-code-compiles: rustc compiled ${#RS[@]} .rs file(s) (no Cargo project — compile-only)"
exit 0
