# Resolving skill script paths (Claude Code + Cursor)

Shipped skills and agents may run from a **repo checkout** (`.claude/skills/…`) or a **global install** (`~/.cursor/skills/…` or `~/.claude/skills/…`). Resolve project-first, then fall back:

```sh
PROJ="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
LEDGER="$PROJ/.claude/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.cursor/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.claude/skills/findings-ledger/scripts/ledger.py"
```

Use `"$LEDGER"` (or the equivalent for other skills) in place of a hardcoded `.claude/skills/…` path.

**Tier doctrine** lives in-repo only: `.claude/rules/review-tiers.md` (Claude Code checkout) or `.cursor/rules/review-tiers.mdc` (Cursor checkout).
