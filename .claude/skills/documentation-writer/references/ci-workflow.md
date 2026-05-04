# CI/CD Workflow Reference

This skill is the local-authoring counterpart to a GitHub Actions workflow that runs on PR events.

## Workflow Pattern

```yaml
name: Update Docs
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  contents: write
  pull-requests: write

jobs:
  docs:
    if: ${{ !startsWith(github.head_ref, 'docs/') }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.head_ref }}
          token: ${{ secrets.GITHUB_TOKEN }}
          fetch-depth: 0
      - name: Resolve docs diff merge base
        run: |
          BR="${GITHUB_BASE_REF:-main}"
          git fetch origin "$BR"
          echo "DOCS_PR_BASE_REF=$BR" >> "$GITHUB_ENV"
          echo "DOCS_PR_MERGE_BASE=$(git merge-base "origin/$BR" HEAD)" >> "$GITHUB_ENV"
      - name: Configure git
        run: |
          git config user.name "Cursor Agent"
          git config user.email "cursoragent@cursor.com"
      # ...invoke docs agent here...
```

## Rules

- Skip the job when the PR branch already starts with `docs/` (avoid loops).
- Always fetch with `fetch-depth: 0` so merge-base resolution works.
- Pass `DOCS_PR_MERGE_BASE` and `DOCS_PR_BASE_REF` into the agent environment.
- Grant only `contents: write` and `pull-requests: write` — nothing more.
