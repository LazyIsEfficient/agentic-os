# Releasing

The installers (`install.sh`, `install.ps1`, `install-cursor.sh`, `install-cursor.ps1`)
install a **pinned release asset** and verify its SHA-256 before extracting. This
document is the runbook for cutting a release and updating that pin. It is
maintainer-only and is never shipped to consumers.

## Why it works this way

- **Pinned, not `main`.** The remote install path only ever fetches a specific
  tagged release asset — never a moving branch. There is no "track `main`"
  remote path; unreleased changes are installed from a local clone
  (`./install.sh`), which copies the working tree directly and does no download.
- **Self-built, content-addressed asset.** `scripts/release.sh` builds the asset
  by archiving the *tree* with a fixed mtime (`git archive --mtime … <ref>^{tree}
  | gzip -n`), so the digest depends only on the payload bytes — identical across
  commits and rebuilds. (Archiving a *commit* would embed the commit SHA + commit
  date and produce a different digest per commit; that subtlety is what makes
  pinning non-circular — see the comment block in `scripts/release.sh`.) Requires
  **git ≥ 2.38** (for `git archive --mtime`). GitHub's auto-generated
  `archive/refs/tags/*.tar.gz` is **not** guaranteed byte-stable, so we do not
  pin its digest.
- **No self-referential hash.** The asset contains only the install *payload*
  (`.claude/` plus `scripts/validate.sh`, the validator the installer runs, and
  `.cursor/hooks/` for the Cursor installer). It excludes `install.sh` /
  `install.ps1` / `install-cursor.sh` / `install-cursor.ps1` / `README.md`, which
  embed the digest — so embedding the digest in them never changes the asset's digest.
- **What the pin defends against:** a tampered or corrupt asset download, and a
  moved/retagged release (the digest won't match). It does **not** by itself
  defend against a full repo compromise that rewrites the installer's embedded
  digest — for that, verify out-of-band (README → *Verifying the download*) or
  add signing.

## Cutting a release

From a clean checkout of the commit you want to release (usually `main`):

1. **Build the asset and get the digest.** This also runs `validate.sh` first
   and fails closed if the library is structurally invalid:

   ```bash
   bash scripts/release.sh v1.0.0
   ```

   It writes `agentic-os-v1.0.0.tar.gz` and prints its `sha256`.

2. **Pin the version + digest** in five files (keep all in sync):
   - `install.sh` — `VERSION` and `EXPECTED_SHA256`
   - `install.ps1` — `$Version` and `$ExpectedSha256`
   - `install-cursor.sh` — `VERSION` and `EXPECTED_SHA256`
   - `install-cursor.ps1` — `$Version` and `$ExpectedSha256`
   - `README.md` — the *Current release* block and the *Verifying the download*
     command, plus the `vX.Y.Z` in all one-liner URLs

3. **Commit** the pin, then **tag that commit** and push the tag:

   ```bash
   git commit -am "release: v1.0.0"
   git tag v1.0.0
   git push origin main v1.0.0
   ```

4. **Confirm the digest is unchanged when built from the tag** (it must be —
   the asset excludes the files you changed in step 2):

   ```bash
   bash scripts/release.sh v1.0.0 v1.0.0
   ```

   If the printed digest differs from what you pinned, stop — something other
   than the installers/README changed.

5. **Create the GitHub release and upload the asset:**

   ```bash
   gh release create v1.0.0 agentic-os-v1.0.0.tar.gz \
     -R LazyIsEfficient/agentic-os --title "v1.0.0" --notes "..."
   ```

6. **Smoke-test the published one-liners** on throwaway dirs:

   ```bash
   CLAUDE_DIR="$(mktemp -d)" bash -c \
     'curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v1.0.0/install.sh | bash'
   CURSOR_DIR="$(mktemp -d)" bash -c \
     'curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v1.0.0/install-cursor.sh | bash'
   ```

The built `*.tar.gz` is a release artifact, not source — do not commit it.
