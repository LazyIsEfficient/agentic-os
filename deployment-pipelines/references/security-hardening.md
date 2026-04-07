# Pipeline Security Hardening

CI runners execute privileged code on every push. Treat workflows as a supply-chain attack surface.

## Pin Actions to Commit SHAs

```yaml
# ❌ tag — mutable, can be force-pushed
- uses: some/action@v3

# ✅ full commit SHA — immutable
- uses: some/action@a1b2c3d4e5f6789012345678901234567890abcd
```

- Tags are pointers; a compromised maintainer can re-point them.
- SHAs are content-addressed; can't be silently changed.
- Exception: `actions/*` from GitHub itself — major-version tags are acceptable but SHAs are still preferred.
- Use Dependabot to keep SHAs current — it opens PRs with the new SHA so you review the diff.

## Permissions: Default Deny

```yaml
permissions: {}                    # workflow-level: nothing

jobs:
  build:
    permissions:                   # job-level: minimum needed
      contents: read
    ...
  publish:
    permissions:
      contents: read
      packages: write
    ...
```

Never rely on the org / repo default. Be explicit.

Common scopes:
| Scope | Use for |
|---|---|
| `contents: read` | Checkout, read repo |
| `contents: write` | Push commits, create releases |
| `pull-requests: write` | Comment on PRs, label, merge |
| `id-token: write` | OIDC federation |
| `packages: write` | Push container images / npm packages |
| `actions: read` | Read other workflow runs |

## Untrusted Input Handling

`${{ github.event.* }}` fields from PRs, issues, comments are **attacker-controlled**.

### ❌ Vulnerable to script injection

```yaml
- run: echo "Title: ${{ github.event.pull_request.title }}"
```

A PR title of `"; rm -rf $HOME; #` becomes shell code.

### ✅ Pass through env var

```yaml
- env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "Title: $PR_TITLE"
```

Env vars are not interpolated by the shell parser; the value is treated as data.

Apply the same pattern for any untrusted field: `head_ref`, `body`, `commit.message`, label names, comment bodies.

## `pull_request` vs `pull_request_target`

| | `pull_request` | `pull_request_target` |
|---|---|---|
| Checkout context | PR's head SHA | Base branch (target) |
| Repository token | Read-only on forks | **Read-write**, even on forks |
| Has secrets on forks | No | **Yes** |
| Safe by default | ✅ | ❌ |

`pull_request_target` is required for some legitimate cases (labeling, automation that needs write tokens on PRs from forks). When using it:
- **Never** check out the PR's head code.
- If you must, check out the base, then run only **trusted** logic against PR metadata — never PR scripts, never `npm install`.

## Third-Party Action Review

Before adding a new third-party action:
1. Check the publisher — verified org? Active maintenance?
2. Read the source — what does it do at runtime? Network calls?
3. Check for `node_modules/` committed at the SHA you're pinning — vendored code is what actually runs.
4. Pin to SHA.
5. Add to Dependabot grouping.

Prefer first-party (`actions/*`, `aws-actions/*`, `google-github-actions/*`) when an equivalent exists.

## Runner Hardening

- Use **GitHub-hosted runners** for untrusted code (PRs from forks). Self-hosted runners that handle PR code are an account-takeover vector.
- If you need self-hosted: **ephemeral runners only** (one job per runner, then destroyed). Never persistent runners for public repos.
- Keep runner images patched — re-pin Ubuntu version when GitHub updates the image.

## Supply Chain Hygiene

- **Lockfile-only installs**: `npm ci`, `pnpm install --frozen-lockfile`, `yarn install --immutable`. Never `npm install` in CI.
- **Verify package signatures** where supported (npm provenance, sigstore).
- **Provenance attestation** on artifacts you publish (`actions/attest-build-provenance`).
- **No `curl | sh`** in workflows. Pin tools via setup actions or download verified releases with checksum verification.

## Audit Checklist

For any workflow that deploys, publishes, or has write tokens:
- [ ] All third-party actions pinned to SHA
- [ ] `permissions:` explicitly set, default `{}`
- [ ] No `${{ ... }}` interpolation of untrusted input in `run:` blocks
- [ ] No `pull_request_target` checking out PR code
- [ ] OIDC instead of static credentials
- [ ] Secrets scoped to environment, not repo
- [ ] Lockfile-only installs
- [ ] Runner OS pinned
