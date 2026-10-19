#!/usr/bin/env bash
# parse-verdict.sh — wrapper. The parser lives in .claude/hooks/lib/ so it ships
# to consumers with the hooks; see that file for usage and exit codes.
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/hooks/lib/parse-verdict.sh" "$@"
