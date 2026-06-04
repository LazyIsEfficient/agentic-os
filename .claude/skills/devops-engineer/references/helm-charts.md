# Helm Charts

Helm templates Kubernetes manifests, tracks release state, and gives you an upgrade/rollback primitive that Kubernetes itself doesn't provide. But Helm's power comes with a trap: the chart source and the deployed release can silently diverge. Someone ran `--set` at the command line and didn't commit it. A previous upgrade failed mid-way and left the cluster in a partial state. A CRD was manually patched. **The chart is not the truth — the release is the truth.**

## Grounding First

Before touching anything, read the deployed state. Not the chart files. The release.

```
helm status <release> -n <namespace>       # deployed / failed / pending-upgrade?
helm history <release> -n <namespace>      # every revision; know your rollback target
helm get values <release> -n <namespace>   # values ACTUALLY running, including --set flags
helm get manifest <release> -n <namespace> # rendered YAML currently in the cluster
```

If you can't read the release state — cluster access unavailable, release doesn't exist yet — prefix your analysis with `UNVERIFIED:` and state your assumptions explicitly. Assumptions made without grounding are the most expensive kind.

## Chart Structure

```
mychart/
  Chart.yaml        # chart metadata
  values.yaml       # default values — base only, no env-specific, no secrets
  templates/
    _helpers.tpl    # named template definitions (prefix _ prevents rendering)
    deployment.yaml
    service.yaml
    ingress.yaml
    NOTES.txt       # post-install stdout message
  charts/           # vendored subchart dependencies
```

**Chart.yaml required fields:**

```yaml
apiVersion: v2
name: myapp
version: 1.4.2       # chart version — bump on ANY chart change
appVersion: "3.7.1"  # application version being packaged — bump when app changes
```

`version` and `appVersion` are independent. `version` advances for template fixes, new values, dependency updates. `appVersion` advances only when the application image changes. Never skip bumping `version` — it makes `helm history` unreadable and breaks traceability.

## Templating Best Practices

**Quote string values that could be numeric.** `{{ .Values.port | quote }}` prevents YAML from coercing `"8080"` to an integer. The coercion is silent and causes confusing downstream errors.

**Default optional values.** `{{ .Values.foo | default "bar" }}` prevents empty strings in rendered manifests. If a field is required with no sane default, use `required "foo is required"` — it fails loudly at render time, not silently at apply time.

**Use `include` over `template` for named templates.** `template` outputs directly to the manifest stream and can't be piped. `include` returns a string you can pipe through `trim`, `nindent`, `quote`.

**Use `toYaml` + `nindent` for value blocks.** Resources, tolerations, env vars, and affinity rules should inject as value blocks:

```yaml
resources:
  {{- toYaml .Values.resources | nindent 10 }}
```

This works cleanly even when `.Values.resources` is empty — `toYaml` of a nil map produces `{}\n`.

**Keep template logic shallow.** An `if/else` chain deeper than three levels belongs in `_helpers.tpl` or in the values structure itself. Complex template logic is invisible to `helm diff` reviewers and untestable.

**Never put secrets in templates or values files.** Helm stores release state — including values — in Kubernetes Secrets that are base64-encoded, not encrypted. Anyone with `kubectl get secret` in the namespace can decode them. Use `secretKeyRef` to reference pre-existing Secrets, or use External Secrets Operator / Sealed Secrets for lifecycle management outside Helm.

## Values Hierarchy and Override Patterns

Helm merges values in a defined order; later values win:

1. `values.yaml` — base defaults, committed with the chart
2. `-f values-staging.yaml` / `-f values-prod.yaml` — environment overlays, passed at deploy time
3. `--set key=value` — one-off overrides at the CLI

**Environment overlays belong outside the chart repo.** Keep them in your GitOps repo or CI config. Committing environment overlays into the chart creates tight coupling: production config changes require chart releases.

**`--set` is not configuration management.** It's a debugging escape hatch. Values passed with `--set` are not tracked in files, not reviewable as diffs, and easily forgotten. The next upgrade without that flag silently reverts the value. Commit permanent config to the appropriate overlay file.

## Read Release State Before Upgrading

This step is most commonly skipped under time pressure — and skipping it causes the most botched upgrades.

```bash
helm history <release> -n <ns>                             # know your rollback target first
helm get values <release> -n <ns>                          # what's actually deployed
helm diff upgrade <release> <chart> -f values.yaml -n <ns> # requires helm-diff plugin
```

`helm-diff` is not optional: `helm plugin install https://github.com/databus23/helm-diff`. Read the diff carefully — pay particular attention to **deletions**. Helm removes resources that disappear from the chart, including PVCs if you restructure storage values carelessly.

If `helm-diff` is unavailable, use `helm upgrade --dry-run --debug` and compare against `helm get manifest`. More work, same information.

## Release Lifecycle

**Install:**
```bash
helm install <release> <chart> -f values.yaml --namespace <ns> --create-namespace
```

**Upgrade (idempotent — use in CI):**
```bash
helm upgrade --install <release> <chart> -f values.yaml \
  --namespace <ns> --atomic --wait --timeout 10m --cleanup-on-fail
```

`--atomic` rolls back automatically on failure — the difference between a release left in `pending-upgrade` (unrecoverable without manual intervention) and a clean rollback to the last good revision. Use it in CI unconditionally.

`--wait` blocks until pods, PVCs, and services are ready. Required whenever downstream CI steps depend on the release being healthy. Without it, CI reports success while pods are still starting.

`--timeout` defaults to 5 minutes — too short for slow image pulls or large clusters. Set it explicitly; `10m` is a safer default.

**Rollback:**
```bash
helm history <release> -n <ns>          # read first; know the target revision
helm rollback <release> <revision> -n <ns>
helm status <release> -n <ns>           # confirm deployed
kubectl rollout status deploy/<name> -n <ns>
```

**Uninstall:**
```bash
helm uninstall <release> -n <ns>
```

`helm uninstall` does NOT delete PersistentVolumeClaims — Helm protects data by default. Delete PVCs manually after confirming you have a backup or genuinely don't need the data.

## Upgrade and Rollback Hygiene

**CRDs are not upgraded by `helm upgrade`.** Helm installs CRDs on first install and deliberately skips them on upgrade to avoid destroying existing custom resources. If a new chart version changes CRD schemas, apply the CRD manually: `kubectl apply -f crds/`. Forgetting this causes silent incompatibility between the chart version and running CRDs.

**Rollback does not re-run hooks by default.** If your chart has pre/post hooks (migrations, config bootstraps), rollback skips them. Add `--force` if hook re-execution is required — but understand what your hooks do first. A migration hook run against an already-migrated schema may corrupt data.

**`--cleanup-on-fail` prevents resource leak.** Without it, resources created during a failed upgrade — new ConfigMaps, Secrets, CRDs — remain and can block future upgrades.

## Helm Test Patterns

```bash
helm test <release> -n <ns>
```

Test pods carry annotation `helm.sh/hook: test` and run to completion. Helm reports pass/fail on exit code. Use them for cluster-local smoke tests: can the app reach its database? Does the healthcheck return 200? Is the expected config key present? Do not use Helm tests for load tests or full integration suites — they are promotion gates, not test suites.

## Common Anti-Patterns

- **Hardcoded image tags in templates** — defeats values overrides; every update requires a chart change.
- **Secrets in values files** — base64 is not encryption; use `secretKeyRef` or an external secrets operator.
- **No resource limits** — one misbehaving pod can starve all neighbors on the node.
- **`helm upgrade` without `helm diff` or `--dry-run`** — you cannot know what will change without seeing it first.
- **Missing `--wait` when downstream depends on the release** — produces flaky failures that look like application bugs.
- **`--set` for permanent config** — not tracked, not reviewable, silently reverted on next upgrade.
- **Not bumping `version` on chart changes** — `helm history` becomes useless; multiple states share one version number.

## Related

- [kubernetes-operations.md](kubernetes-operations.md) — the k8s resources Helm renders into; use this reference to understand what a Helm release actually creates in the cluster
- [cicd-pipelines.md](cicd-pipelines.md) — Helm in CI/CD pipelines: lint/diff gates on PRs, `helm upgrade --install --atomic` on merge, environment promotion patterns
- [../security-and-hardening/SKILL.md](../security-and-hardening/SKILL.md) — External Secrets Operator, Sealed Secrets, and supply-chain security for Helm charts and container images
