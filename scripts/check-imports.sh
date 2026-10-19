#!/usr/bin/env bash
# check-imports.sh — wrapper. The check lives in
# .claude/skills/code-review-and-quality/scripts/ so it ships to consumers with
# the skills; see that file for usage and exit codes.
exec bash "$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/.claude/skills/code-review-and-quality/scripts/check-imports.sh" "$@"
