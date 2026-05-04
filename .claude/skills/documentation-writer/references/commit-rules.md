# Commit Rules

- **One commit maximum** per run.
- Commit message: `docs: update documentation for <short-scope>`
- Commit body: bullet list of key doc files changed and **why** each was updated.
- Configure git identity for automated runs:
  ```bash
  git config user.name "Cursor Agent"
  git config user.email "cursoragent@cursor.com"
  ```
- Stage only files under `docs/` (and root `README.md` if touched). Never `git add -A`.

## Idempotency

- Running this skill twice on the same commit must produce **no further changes**.
- If no meaningful doc updates are required, do not commit and do not create empty placeholder files.
