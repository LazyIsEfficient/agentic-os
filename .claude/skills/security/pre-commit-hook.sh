#!/usr/bin/env bash
# Pre-commit hook: scan staged files for PII / sensitive data.
#
# Install:
#   cp security/pre-commit-hook.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Bypass (emergency only):
#   git commit --no-verify

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SANITIZER="$REPO_ROOT/security/sanitizer.py"

if [ ! -f "$SANITIZER" ]; then
    echo "⚠️  Sanitizer not found at $SANITIZER — skipping PII check."
    exit 0
fi

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

FOUND_PII=0
TEMP_REPORT=$(mktemp)

for FILE in $STAGED_FILES; do
    FULL_PATH="$REPO_ROOT/$FILE"

    # Only check supported extensions
    case "$FILE" in
        *.py|*.md|*.txt|*.json|*.yaml|*.yml|*.env)
            ;;
        *)
            continue
            ;;
    esac

    if [ ! -f "$FULL_PATH" ]; then
        continue
    fi

    OUTPUT=$(python3 "$SANITIZER" --scan --file "$FULL_PATH" --quiet 2>&1) || true

    if [ -n "$OUTPUT" ] && echo "$OUTPUT" | grep -q "issue"; then
        echo "$FILE: $OUTPUT" >> "$TEMP_REPORT"
        FOUND_PII=1
    fi
done

if [ "$FOUND_PII" -eq 1 ]; then
    echo ""
    echo "🚫 COMMIT BLOCKED — PII / sensitive data detected in staged files:"
    echo ""
    cat "$TEMP_REPORT"
    echo ""
    echo "To fix:"
    echo "  1. Run: python3 security/sanitizer.py --scan --dir . --recursive"
    echo "  2. Review findings and redact manually, or run with --sanitize"
    echo "  3. Stage the fixed files and commit again"
    echo ""
    echo "To bypass (emergency): git commit --no-verify"
    rm -f "$TEMP_REPORT"
    exit 1
fi

rm -f "$TEMP_REPORT"
exit 0
