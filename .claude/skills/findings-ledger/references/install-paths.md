# Resolving skill script paths (Claude Code)

## Path layout (do not conflate)

| Location | When it exists | Role |
|---|---|---|
| `.claude/skills/<name>/` | **Always in this repo** | Source of truth; use for project-first resolution |
| `~/.claude/skills/<name>/` | After `install.sh` | Global Claude Code copy |

Shipped skills and agents resolve **project-first**, then global fallback:

```sh
PROJ="${CLAUDE_PROJECT_DIR:-.}"
LEDGER="$PROJ/.claude/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.claude/skills/findings-ledger/scripts/ledger.py"
```

Use `"$LEDGER"` (or the equivalent for other skills) in place of a hardcoded `.claude/skills/…` path.

**Tests:** `bash scripts/install-paths-test.sh` (also run from `validate-test.sh`).

**Tier doctrine** lives in-repo only: `.claude/rules/review-tiers.md`.
