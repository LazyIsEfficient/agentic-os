# Releasing

The installers (`install.sh`, `install.ps1`)
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
- **No self-referential hash.** The asset contains only the install *payload* —
  `.claude/`, `assets/consumer/`, `docs/awareness-harness-activation.md`, and the
  two scripts the installer runs (`scripts/validate.sh` and
  `scripts/lib/install-hook-settings.sh`). It excludes `install.sh` /
  `install.ps1` / `README.md`, which embed the digest — so embedding the digest
  in them never changes the asset's digest. (The authoritative list is
  `ARCHIVE_PATHS` in `scripts/release.sh`.)
- **What the pin defends against:** a tampered or corrupt asset download, and a
  moved/retagged release (the digest won't match). It does **not** by itself
  defend against a full repo compromise that rewrites the installer's embedded
  digest — for that, verify out-of-band (README → *Verifying the download*) or
  add signing.

## Cutting a release

**PR first.** Merge your feature PR to `main` before tagging. Tags must point at commits on `origin/main` (CI: `tag-from-main.yml`). Do not tag feature branches.

From a clean checkout of **`main`** at the commit you want to release:

0. **Refresh the earlier-release hash list** (needs the tags locally:
   `git fetch --tags`), and commit it if it changed:

   ```bash
   bash scripts/gen-release-hashes.sh
   ```

   `assets/release-hashes.txt` lists the SHA-256 of every file in every
   earlier `vX.Y.Z` tag. When the installer adopts an install that predates the
   manifest, it uses this list to tell an untouched earlier-release file (which
   it updates) from a user edit (which it keeps). `release.sh` runs
   `gen-release-hashes.sh --check --exclude <version>` and refuses to build
   while the list is stale. The list ships in the release asset.

1. **Build the asset and get the digest.** This also runs `validate.sh` first
   and fails closed if the library is structurally invalid:

   ```bash
   bash scripts/release.sh v1.0.0
   ```

   It writes `agentic-os-v1.0.0.tar.gz` and prints its `sha256`.

2. **Pin the version + digest.** `install.sh` is the canonical source:
   set `VERSION` and `EXPECTED_SHA256` there first, then make every other pin
   match it:
   - `install.sh` — the `vX.Y.Z` in the header one-liner URL
   - `install.ps1` — `$Version`, `$ExpectedSha256`, and the header one-liner URL
   - `README.md` — the *Current release* block (version, asset, SHA-256), the
     *Verifying the download* commands, the `vX.Y.Z` in all one-liner URLs, and
     the Codex `<release-tag>` placeholder

   `bash scripts/validate.sh` enforces this (`install-pins`): any pin that
   disagrees with `install.sh` fails, as does a `VERSION` that is not a
   `vX.Y.Z` tag. Release tags are not the anchor because the tag is cut
   *after* this commit (step 3), and CI's shallow checkout has no tags.

   **If the release removes a hook** from `assets/consumer/claude-settings.json`,
   add its script basename to `RETIRED_HOOKS` in `install.sh` *and*
   `$RetiredHooks` in `install.ps1` (validate checks they match). Existing
   installs then unregister it from `settings.json` on update and uninstall.
   Removed skills need no installer change: add the slug to `TOMBSTONES` in
   `scripts/validate.sh` as usual. The manifest prunes the removed files, and
   `--prune-legacy` reads that list for installs that predate the manifest.

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

   CODEX_HOME="$(mktemp -d)/.codex" CODEX_SKILLS_DIR="$(mktemp -d)/.agents/skills" bash -c \
     'curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v1.0.0/install.sh | bash -s -- --codex'
   ```

   Then smoke-test the lifecycle against the previous release on a throwaway
   dir. Install the previous tag, re-run the new one (unmodified files update,
   hooks refresh), then `--uninstall --dry-run` and `--uninstall`.
   `scripts/install-lifecycle-test.sh` covers this from a local tree. It has no
   PowerShell counterpart, so on Windows, run `.\install.ps1 -Dest <tmp>`
   twice, then `-Uninstall -Dest <tmp>`. Confirm `settings.json` stays valid
   JSON and that `hooks.PreToolUse` is still an array on an *existing*
   settings file (the Windows PowerShell 5.1 single-element-array unwrap).

The built `*.tar.gz` is a release artifact, not source — do not commit it.
