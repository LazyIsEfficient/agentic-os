#!/usr/bin/env bash
#
# run-checker.sh — the dispatch entrypoint for the Tier-0 deterministic checker
# library. The eval runner calls this IDENTICALLY for both arms (library-ON and
# baseline) of a fixture: it maps a frozen `kind` to a concrete checker script,
# runs it, and passes the checker's exit code and stdout straight through.
#
# Usage:
#   run-checker.sh <kind> <artifact_path_or_dir> [extra checker args...]
#
# Frozen kind vocabulary (do NOT extend — pinned across the parallel eval tasks):
#   validate-library-artifact   stage SKILL.md/agent into .claude + run validate.sh
#   cargo-test                  build + test a Rust artifact dir
#   schema-match                assert required patterns in a text/HTML/md artifact
#
# Legacy alias accepted for back-compat with existing fixtures:
#   validate.sh  ->  validate-library-artifact
#
# Uniform contract (see README.md):
#   exit 0 = PASS, 1 = FAIL, 2 = could-not-run / environment-skip.
# One-line verdict is printed by the dispatched checker on stdout.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "usage: run-checker.sh <kind> <artifact_path_or_dir> [args...]" >&2
  echo "  kind: validate-library-artifact | cargo-test | schema-match" >&2
}

if [[ $# -lt 2 ]]; then
  echo "RUN-CHECKER ERROR: expected <kind> <artifact_path_or_dir>" >&2
  usage
  exit 2
fi

KIND="$1"
ARTIFACT="$2"
shift 2

case "$KIND" in
  validate-library-artifact|validate.sh)
    exec bash "$SCRIPT_DIR/check-library-artifact.sh" "$ARTIFACT" "$@"
    ;;
  cargo-test)
    exec bash "$SCRIPT_DIR/check-code-compiles.sh" "$ARTIFACT" "$@"
    ;;
  schema-match)
    exec bash "$SCRIPT_DIR/check-schema-match.sh" "$ARTIFACT" "$@"
    ;;
  *)
    echo "RUN-CHECKER ERROR: unknown kind '$KIND' (want: validate-library-artifact | cargo-test | schema-match)" >&2
    exit 2
    ;;
esac
