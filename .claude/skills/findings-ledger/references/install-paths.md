# Resolving skill script paths (Claude Code + Cursor)

## Path layout (do not conflate)

| Location | When it exists | Role |
|---|---|---|
| `.claude/skills/<name>/` | **Always in this repo** | Source of truth; use for project-first resolution |
| `~/.cursor/skills/<name>/` | After `install-cursor.sh` | Global Cursor copy (from `.claude/skills/`) |
| `~/.claude/skills/<name>/` | After `install.sh` | Global Claude Code copy |

**Common mistake:** writing `$PROJ/.cursor/skills/…` for a repo checkout. The repo ships skills under **`.claude/skills/`**, not `.cursor/skills/`. Only `~/.cursor/skills/` is valid (global install destination).

Shipped skills and agents resolve **project-first**, then global fallbacks:

```sh
PROJ="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
LEDGER="$PROJ/.claude/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.cursor/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.claude/skills/findings-ledger/scripts/ledger.py"
```

Use `"$LEDGER"` (or the equivalent for other skills) in place of a hardcoded `.claude/skills/…` path.

**Tests:** `bash scripts/install-paths-test.sh` (also run from `validate-test.sh`).

**Tier doctrine** lives in-repo only: `.claude/rules/review-tiers.md` (Claude Code checkout) or `.cursor/rules/review-tiers.mdc` (Cursor checkout).
