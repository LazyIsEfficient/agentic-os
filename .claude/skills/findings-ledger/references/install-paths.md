# Resolving skill script paths (Claude Code and Codex)

## Path layout (do not conflate)

| Location | When it exists | Role |
|---|---|---|
| `.claude/skills/<name>/` | **Always in this repo** | Source of truth; use for project-first resolution |
| `.agents/skills/<name>/` | After `install.sh --codex --project` | Project-scoped Codex copy |
| `~/.claude/skills/<name>/` | After `install.sh` | Global Claude Code copy |
| `~/.agents/skills/<name>/` | After `install.sh --codex` | Global Codex copy |

Shipped skills and agents resolve **project-first**, then global fallback:

```sh
PROJ="${CLAUDE_PROJECT_DIR:-.}"
LEDGER="$PROJ/.claude/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$PROJ/.agents/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.claude/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.agents/skills/findings-ledger/scripts/ledger.py"
```

Use `"$LEDGER"` (or the equivalent for other skills) in place of a hardcoded `.claude/skills/…` path.

## Exception: reviewer agents use the installed copy only

Reviewers (`code-reviewer`, `security-reviewer`, `library-reviewer`, `data-model-verifier`, `adversarial-claims-reviewer`) read untrusted trees. A project copy lives inside that tree, and so does a `--codex --project` install. A repo could commit a fake `ledger.py` or scanner there and get the reviewer to run it. Reviewers therefore never resolve project-first:

```sh
LEDGER="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/findings-ledger/scripts/ledger.py"
[ -f "$LEDGER" ] || LEDGER="$HOME/.agents/skills/findings-ledger/scripts/ledger.py"
```

`ledger.py` writes to the current git repo's `.claude/ledger/`, not to its own install dir, so the installed copy still journals into the project. Scanners follow the same rule: [scanner-evidence.md](../../code-review-and-quality/references/scanner-evidence.md).

**Tests:** `bash scripts/install-paths-test.sh` (also run from `validate-test.sh`).

**Tier doctrine** lives in-repo only: `.claude/rules/review-tiers.md`.
