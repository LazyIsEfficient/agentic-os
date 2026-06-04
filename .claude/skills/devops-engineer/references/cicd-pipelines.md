# CI/CD Pipelines — Helm and Pulumi Deployment Reference

> **This reference covers Helm and Pulumi deployment mechanics in pipelines, safe promotion patterns, and environment gates. For general CI quality gates, pipeline structure, and GitHub Actions YAML, see `ci-cd-and-automation`.**

---

## 1. Grounding First — Read Before You Mutate

A pipeline that only mutates is deploying blind. Every deploy pipeline must include a **read/diff/preview step before any mutation step**, visible on the PR so a human can review it:

- **Helm:** `helm diff upgrade` runs on every PR against the target environment. `helm upgrade` runs only after the diff has been reviewed.
- **Pulumi:** `pulumi preview --diff` runs on every PR. `pulumi up` runs only on merge, after the preview was the gate.

If the diff step is absent, the pipeline is a hallucination risk — you only discover what changed after it changed in production.

---

## 2. Helm in CI

### Validation (every PR)

```bash
helm lint <chart>                                             # catches syntax and schema errors
helm template <chart> -f values-<env>.yaml \
  | kubectl apply --dry-run=client -f -                      # confirms manifests are accepted by the API server
```

`helm lint` catches templating errors; the `--dry-run` step catches API compatibility issues that lint misses.

### Diff gate (every PR, against target environment)

```bash
helm diff upgrade <release> <chart> \
  -f values-<env>.yaml \
  -n <namespace>
```

Post the output as a PR comment (use `helm-diff` GitHub Action or pipe to a comment step). Gate promotion on review — do not auto-merge if the diff shows unexpected resource replacements or deletions.

Always pin chart versions in CI. Never use a floating reference like `latest` or an unversioned OCI reference — a chart update mid-pipeline breaks reproducibility.

### Deploy (on merge to main)

```bash
helm upgrade --install <release> <chart> \
  -f values-<env>.yaml \
  --namespace <ns> \
  --atomic \
  --wait \
  --timeout 5m
```

- `--atomic`: if the upgrade fails, Helm automatically rolls back to the previous revision, preventing a broken release from sitting in a failed state.
- `--wait`: blocks until all pods are ready, not just until the API server accepted the manifest.
- `--timeout 5m`: bounds the wait so the pipeline doesn't hang indefinitely.

Add alerting on rollback events (`helm history <release>` or Helm hook `post-rollback`) — silent auto-rollbacks are invisible failures.

---

## 3. Pulumi in CI

### PR check

```bash
pulumi stack select <env>                                     # always explicit; never assume the active stack
pulumi preview --diff
```

Post the preview output as a PR comment. Block merge if the preview shows unexpected destroys or replacements — a destroy in a preview is a required human decision, not an auto-approve.

### Merge to main

```bash
pulumi stack select <env>
pulumi up --yes --skip-preview
```

`--skip-preview` is safe here **because the preview was the gate on the PR**. Running a second preview on merge adds latency without adding safety — the state may have drifted slightly, but the diff reviewed on the PR is the authoritative intent signal. **This exception applies only to this CI merge path — it does not relax the preview requirement in any other context.** Any `pulumi up` outside of a pipeline where a PR preview was the explicit gate must run `pulumi preview` first per SKILL.md Universal Rule 3.

### Drift detection (scheduled job)

```bash
pulumi stack select <env>
pulumi preview --expect-no-changes
```

Run this on a schedule (e.g., daily). A non-zero exit means something outside Pulumi mutated the stack. Treat drift as an incident — it means the live state no longer matches the declared state.

### Auth in CI

- Use `PULUMI_ACCESS_TOKEN` as a CI secret — never a personal token.
- For cloud auth (AWS, GCP, Azure), use **OIDC** instead of long-lived access keys. Configure the trust relationship between the CI provider (e.g., GitHub Actions OIDC) and the cloud IAM role; the pipeline gets a short-lived token per run with no stored secret.

---

## 4. Safe Deployment Patterns

### Environment promotion order

```
dev → staging → prod
```

Never skip staging for production. Staging is the last cheap failure point.

Gate between environments: smoke tests must pass **and** a diff review must have occurred. Green tests alone are not sufficient — a test suite that doesn't cover a schema migration will pass while production burns.

### Blue-green with Helm

Maintain two releases: `app-blue` and `app-green`. Deploy the new version to the inactive release. Switch traffic by updating the service selector label (`version: blue` → `version: green`). Instant rollback: re-point the selector. No pod restarts on rollback.

### Canary with Helm

Use weighted ingress annotations (nginx: `nginx.ingress.kubernetes.io/canary-weight`, traefik: `traefik.ingress.kubernetes.io/service-weights`). Start the canary at **5%** of traffic. Monitor error rate and p99 latency. Ramp up in steps (5% → 20% → 50% → 100%) only if gates pass at each step.

### Rollout gates

Define success criteria before deploying: error rate < 0.1%, p99 latency < 500ms, no increase in OOMKill events. Automate rollback if a gate fails within the observation window (typically 10–15 min). A deployment without pre-defined success criteria has no meaningful rollback trigger.

---

## 5. Deployment Verification

Helm or Pulumi reporting success means the API server accepted the manifests. It does not mean the application is healthy.

After every deploy:

```bash
kubectl rollout status deployment/<name> -n <ns> --timeout=5m   # pods ready, not just accepted
helm test <release> -n <ns>                                      # Helm test hooks if defined
```

A deployment is complete only when:
- All pods are `Running` with readiness probes passing
- No recent `OOMKill` events (`kubectl get events`)
- Application error rate is at baseline (check your metrics)

A pipeline that marks a deploy complete at `helm upgrade` exit code 0 without these checks produces false confidence.

---

## 6. Secrets in Pipelines

- No credentials in pipeline YAML — use CI secret management (GitHub Actions encrypted secrets, Vault, etc.).
- Use OIDC for cloud auth; document the trust relationship (`repo:org/repo:ref:refs/heads/main` → IAM role ARN).
- Never `echo` or `print` secret values in pipeline steps — they appear in logs and are captured in run artifacts.
- `helm upgrade --set dbPassword=$SECRET` is acceptable when `$SECRET` comes from CI secrets, but prefer values files with secrets injected from the vault at deploy time.
- Rotate secrets immediately on suspected breach — do not wait for confirmation.

---

## 7. Common Anti-Patterns

- `pulumi up` without a preview gate on the PR — destroys and replacements are invisible until they hit prod.
- `helm upgrade` without `helm diff` in the pipeline — same; you only see what changed after it changed.
- Promoting to prod without a staging deploy — staging is the last cheap failure point.
- Long-lived cloud credentials in CI — use OIDC; a compromised runner should yield an expiring token, not persistent access.
- Auto-promoting on green tests without a human diff review for prod — tests don't cover what tests don't cover.
- No rollback plan before deploying — define the rollback path before the upgrade runs, not after it fails.
- `kubectl apply` directly in CI, bypassing Helm/Pulumi — state tracking breaks; drift becomes undetectable.
- Missing `--atomic` / `--wait` — Helm reports success, pods aren't ready, the failure surface shifts to the next check window.
