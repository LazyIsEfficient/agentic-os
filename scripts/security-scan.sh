#!/usr/bin/env bash
# security-scan.sh — wrapper. The scanner lives in .claude/skills/security/scripts/
# so it ships to consumers with the skills; see that file for usage and exit codes.
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/skills/security/scripts/security-scan.sh" "$@"
