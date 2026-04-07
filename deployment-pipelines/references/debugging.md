# Debugging Workflows

Workflows fail in ways local code doesn't. Reach for these in order.

## 1. Read the Failed Step

Click into the failing job → expand the failed step. 80% of failures are obvious here:
- Exit code + stderr
- Last command run
- Environment context (the YAML block at the top of each step)

Don't skip this and re-run blindly. Re-running the same flake five times wastes minutes and teaches nothing.

## 2. Re-run with Debug Logging

Re-run jobs → "Enable debug logging" checkbox. Or set repo secrets:
- `ACTIONS_RUNNER_DEBUG: true` — runner-level logs
- `ACTIONS_STEP_DEBUG: true` — per-step verbose

Use sparingly — debug logs are noisy and persist with the run.

## 3. Re-run Failed Jobs Only

When only some jobs failed, use **"Re-run failed jobs"** to keep successful job results. Saves minutes, preserves matrix shard data.

## 4. tmate Session (interactive shell)

For stubborn failures, drop into the runner:

```yaml
- name: Setup tmate session
  if: failure()
  uses: mxschmitt/action-tmate@<sha>
  with:
    limit-access-to-actor: true
```

Rules:
- **Only on private repos or trusted forks.** A tmate session on a public PR is RCE.
- **Always `limit-access-to-actor`** — restricts to the user who triggered the run.
- **Timeout the job** so a forgotten tmate doesn't burn your minutes.
- Remove the step after debugging. Don't leave tmate in main.

## 5. Local Reproduction with `act`

[`act`](https://github.com/nektos/act) runs workflows locally in Docker:

```bash
act pull_request                    # simulate a PR event
act -j test                         # run a specific job
act -j test -P ubuntu-24.04=...     # use a specific runner image
```

Caveats:
- Not 100% faithful to GitHub's runner image — some actions behave differently.
- No OIDC, no GitHub-hosted secrets unless you provide them locally.
- Best for syntax validation, step-level debugging, fast iteration on shell commands.

## 6. Branch-Based Iteration

When you can't reproduce locally:
1. Create a `debug/...` branch.
2. Add diagnostic steps (`env | sort`, `ls -la`, `which node`, `cat /etc/os-release`).
3. Push, observe, refine.
4. Squash debug commits before merging — never merge `console.log`-equivalents.

## Common Failure Modes

### "Permission denied" on a token operation
- `permissions:` block too restrictive. Check the job-level scope.
- For OIDC: missing `id-token: write`.
- For pushing commits: missing `contents: write`.

### Action behaves differently than docs
- You're pinned to an old SHA. Check the action's release notes since your pin.
- Tag drift: you pinned to `@v3` and it changed under you. Re-pin to a SHA.

### Cache miss every run
- Key includes a value that changes every run (`${{ github.sha }}`, timestamps).
- Lockfile not committed.
- `hashFiles()` glob doesn't match anything.

### "Resource not accessible by integration"
- The default `GITHUB_TOKEN` doesn't have permission for that API. Either grant it, or use a PAT / GitHub App token.

### Works on `pull_request` but fails on `push`
- Different `github.ref` shape, different secrets availability, different `github.event.*` payload.

### Flaky test only in CI
- Timing differences (slower runner, no GPU, different timezone).
- Filesystem case sensitivity (Linux runner vs macOS dev).
- Environment variables that exist locally but not in CI (or vice versa).

### "Composite action not found"
- Composite actions referenced as `./.github/actions/foo` require a checkout step **before** the action call.

## Debugging Etiquette

- Don't `continue-on-error: true` to "fix" a failing step.
- Don't disable a flaky test in CI without a follow-up ticket.
- Don't merge debug logging into main.
- When you fix a CI bug, leave a comment in the workflow YAML explaining the fix — your future self will hit the same issue.
