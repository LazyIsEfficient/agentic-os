# Kubernetes Operations

Before you touch anything, read the current state. This is the single most important rule in this document. Kubernetes clusters are shared, live infrastructure — what you think is true about a resource and what is actually deployed are frequently different. Every mutation proposed in this guide starts with a read. If you cannot quote the current resource YAML, you have not read it. Mark any proposed change `UNVERIFIED:` and go read it first.

The two most common mistakes in Kubernetes day-2 work:

1. **Patching from memory.** You remember what the Deployment looked like last week. The cluster has had three hotfixes since then. Patch from memory, break something new.
2. **Skipping Events.** The answer to most pod failures is in `kubectl describe`'s Events section. Engineers who skip straight to `kubectl exec` waste 20 minutes getting to the same conclusion.

Both are habits. Both are fixable.

## kubectl Command Patterns

### Read-first commands (reach for these before anything else)

**`kubectl get <resource> -o yaml`** — The canonical read. Use this before any patch, apply, or edit. The output is the actual server-side state, not the manifest you think you applied. Look for `status` fields alongside `spec` — the cluster's view of convergence lives there.

```bash
kubectl get deployment my-app -n production -o yaml
```

Save it before mutating: `kubectl get deployment my-app -n production -o yaml > current.yaml`

**`kubectl describe <resource>`** — Human-readable summary plus the **Events** section. Read Events every time. Events show scheduling failures, image pull errors, OOMKills, readiness probe failures, and volume mount problems — the actual failure mode, not just "pod is Pending." Events age off after ~1 hour; if the pod is old and Events are empty, use logs.

**`kubectl logs <pod> -n <ns>`** — Current container output. If the container is crashing, this may be empty or truncated because the crash happened fast.

**`kubectl logs <pod> -n <ns> --previous`** — The last container's output before the most recent restart. This is almost always more useful than current logs when a pod is in `CrashLoopBackOff`. Run `--previous` first; if it's empty, then read current.

**`kubectl exec -it <pod> -n <ns> -- <cmd>`** — Live shell into a running container. This is a **last resort**, not a first response. Exec is destructive to reproducibility: you change runtime state, potentially mask the bug, and leave no audit trail. Document what you found in steps 1–5 before going interactive. Never exec into a pod to "just check something" before reading its logs.

**`kubectl port-forward <pod> 8080:8080 -n <ns>`** — Local debugging without exposing a Service. Use when you need to hit an application endpoint or pprof handler from your workstation without touching Ingress or LoadBalancer config. Safe; read-only from the cluster's perspective.

**`kubectl top pod -n <ns>` / `kubectl top node`** — Point-in-time resource consumption. Look for pods consuming near their limit (imminent OOMKill) or nodes above 80% memory (imminent eviction pressure). A snapshot, not a trend — open your metrics dashboard for trends.

### Useful flags

- `-n <namespace>` — always specify; defaulting to `default` in production is an incident waiting to happen
- `--all-namespaces` / `-A` — cluster-wide surveys; slow on large clusters
- `-o wide` — adds Node, IP, nominated-node to pod listings; essential for placement debugging
- `-o jsonpath='{.spec.containers[*].image}'` — surgical field extraction; use when you need one value without parsing full YAML
- `-l app=my-app,version=v2` — label selector filtering; faster and more reliable than grepping output

## Pod Debugging Workflow

Work through these steps in order. Each step reads before acting. Do not skip ahead.

**Step 1 — Read pod status and placement.**

```bash
kubectl get pod <name> -n <ns> -o wide
```

Look at: STATUS, RESTARTS, NODE, AGE. `CrashLoopBackOff` means it has crashed and Kubernetes is throttling restarts. `Pending` means it hasn't scheduled yet — the problem is above the container level (resources, taints, node affinity). RESTARTS > 0 means `--previous` logs are essential.

**Step 2 — Read Events. This is where most failures are diagnosed.**

```bash
kubectl describe pod <name> -n <ns>
```

Scroll to Events. Common failures found here and nowhere else: `FailedScheduling` (no nodes match), `ImagePullBackOff` (wrong image tag or missing pull secret), `Readiness probe failed` (app started but isn't healthy), `OOMKilled` (memory limit too low). If Events are clean and the pod is still broken, the failure is inside the container — proceed to logs.

**Step 3 — Read current container logs.**

```bash
kubectl logs <name> -n <ns>
```

Look for stack traces, panics, config errors, "address already in use." If the container crashed before writing logs, output will be sparse.

**Step 4 — Read last container's logs if the pod restarted.**

```bash
kubectl logs <name> -n <ns> --previous
```

This is the container that crashed. The exit reason is usually at the end of this output. Always run this if RESTARTS > 0.

**Step 5 — Read resource limits.**

```bash
kubectl get pod <name> -n <ns> -o yaml | grep -A8 resources
```

Confirm `requests` and `limits` are both set. A pod with no `requests` will get the lowest scheduling priority and can be evicted under pressure. A pod with no `limits` will compete unrestricted for node memory. OOMKill is the most common silent failure mode; if the pod is restarting without clear log output, this is why.

**Step 6 — Exec only if steps 1–5 are inconclusive.**

Document what you found (or didn't find) in steps 1–5 before opening a shell. This creates a record and forces you to confirm there is no other path. Use a minimal command — `ls`, `curl localhost:8080/health`, `env` — not an open-ended shell session.

## Rollout Management

**Before rolling back, read history.**

```bash
kubectl rollout history deployment/<name> -n <ns>
```

This shows revision numbers and change causes (if `--record` was used or annotations were set). Know which revision you're rolling back to before issuing the command. `kubectl rollout undo` without `--to-revision` goes to the previous revision, which may not be the last known-good one.

**Watch rollout status.**

```bash
kubectl rollout status deployment/<name> -n <ns>
```

`"successfully rolled out"` means new pods started and passed readiness probes. It does not mean the application is healthy — a pod can pass a shallow HTTP probe and still be serving errors. After a rollout, check your actual error rate metrics. Don't declare success from rollout status alone.

**Detect a stalled rollout.** A slow rollout and a stalled one look identical for the first few minutes. Read conditions:

```bash
kubectl get deployment <name> -n <ns> -o yaml | grep -A12 conditions
```

`Progressing` condition with reason `ReplicaSetUpdated` means it's moving. `Progressing` with reason `ProgressDeadlineExceeded` means it's stalled — the rollout has not made progress in the configured `progressDeadlineSeconds`. At that point, read the new pods' Events (`kubectl describe pod`) to find what's blocking them.

**Rolling back.**

```bash
kubectl rollout undo deployment/<name> -n <ns>                  # to previous revision
kubectl rollout undo deployment/<name> -n <ns> --to-revision=4  # to specific revision
```

A rollback is a mitigation. The broken code is still in your repo. After a rollback, create a ticket, do not just redeploy the same image.

## Resource Inspection Before Mutation

This is the read-before-write discipline made concrete.

**`kubectl diff` is required before every apply.**

```bash
kubectl diff -f my-manifest.yaml
```

Read the diff carefully. Additions are `+`; removals are `-`. Pay attention to: image tags changing, replica counts, resource limits, environment variables, and volume mounts. If the diff shows nothing you intended to change, stop — you have a stale manifest or you're applying to the wrong namespace.

**Dry run for manifest validation.**

```bash
kubectl apply --dry-run=server -f my-manifest.yaml
```

Prefer `--dry-run=server` over `--dry-run=client`. Server-side dry run runs admission webhooks (OPA, Kyverno, pod security admission) and catches more classes of error. Client-side only validates schema.

**Save state before patching.**

```bash
kubectl get deployment <name> -n <ns> -o yaml > current-$(date +%Y%m%d-%H%M%S).yaml
```

Keep this file until you've confirmed the change is working. It's your rollback target if `kubectl rollout undo` isn't sufficient.

**`kubectl patch` vs `kubectl apply`.**

`kubectl apply` is declarative: it reconciles the full resource spec from your manifest, including removing fields you omit. Use it for normal GitOps-style delivery. `kubectl patch` is surgical: it modifies one or a few fields without touching the rest. Use patch for emergency changes when you cannot wait for a full manifest apply cycle — but write the change back to the source manifest before the shift ends, or the cluster will drift from your repo. Never use `kubectl edit` in production without saving the current resource first — `kubectl edit` opens a live YAML in your editor and applies on save; if the editor exits unexpectedly, the state is unclear.

## RBAC Patterns

**Default to namespace scope.** A `Role` + `RoleBinding` scopes permissions to one namespace. A `ClusterRole` + `ClusterRoleBinding` grants those permissions cluster-wide. There is almost never a reason an application service account needs cluster-wide access. Start narrow; expand only when a specific cross-namespace need is proven.

**Common role templates.** Read-only (audit, dashboards): `verbs: ["get", "list", "watch"]` on pods/deployments/services/configmaps. Deployer (CD pipeline): `verbs: ["get", "list", "patch", "update"]` on deployments only, plus read-only on pods. Namespace-admin: all verbs on all resources in one namespace — no cluster-scoped resources.

**Audit permissions before assuming them.**

```bash
kubectl auth can-i --list -n production
```

Shows everything the current identity can do in that namespace. Run this before assuming you have (or don't have) access — and before creating new roles, confirm the capability doesn't already exist.

**Test service account permissions by impersonating.**

```bash
kubectl auth can-i create deployments \
  --as=system:serviceaccount:production:my-app-sa \
  -n production
```

Use this to verify that a service account has exactly the permissions it needs and no more. Run both the allow cases (should return `yes`) and the deny cases (should return `no`).

**Never bind `cluster-admin` to application service accounts.** `cluster-admin` grants full control of the cluster including reading secrets, deleting namespaces, and modifying RBAC. An application service account with `cluster-admin` is a full cluster compromise if the application is exploited. If someone asks for `cluster-admin` for an app, the ask is wrong — find the specific verb/resource it actually needs.

## Namespace and Resource Management

**One namespace per trust boundary.** Team A's workloads and Team B's workloads do not belong in the same namespace unless they have the same RBAC, quota, and network trust level. Sharing namespaces to "keep things simple" means any escalation in one team's service affects the other.

**`ResourceQuota` prevents blast radius.** Apply a quota to every production namespace. Without it, a runaway deployment consumes all cluster CPU and memory, evicting unrelated workloads. At minimum: set `requests.cpu`, `requests.memory`, `limits.cpu`, `limits.memory`, and `count/pods`. The exact values depend on your cluster size — the point is to have a ceiling, not to pick the right number.

**`LimitRange` forces resource hygiene.** Without a LimitRange, pods with no resource spec run successfully. With one, pods missing requests/limits get defaults applied — or are rejected. Prefer the rejection model in production: a pod without resource spec is a pod you cannot reason about for capacity or eviction.

**Label discipline.** Consistent labels across all resources make selectors, dashboards, and alert routing work. Minimum set: `app`, `version`, `environment`. Selectors on Services and NetworkPolicies are immutable after creation — get them right the first time.

## Network Policies

**Start with default-deny.** An unconfigured namespace allows all pod-to-pod traffic. Apply a deny-all baseline (`podSelector: {}`, `policyTypes: [Ingress, Egress]`) to every namespace on creation, then add explicit allow policies. This forces every communication path to be intentional and documented.

**DNS egress must be explicitly allowed.** A deny-all Egress blocks DNS (UDP/TCP 53). Add a DNS egress allow rule to every namespace that has a deny-all — otherwise all hostname resolution breaks silently.

**Verify both sides after applying.** A NetworkPolicy that allows traffic from pod A to pod B does not automatically allow the response. Test the deny cases:

```bash
kubectl exec <source-pod> -n <ns> -- curl --connect-timeout 3 <target-ip>:8080
```

Expect success for intended paths, timeout for blocked ones. If a timeout takes 30 seconds, the NetworkPolicy is working but TCP backpressure is slow — that's correct behavior, not a hung test.

**Don't rely on namespace isolation alone.** Without NetworkPolicies, a pod in namespace A can reach any pod in namespace B by IP. Namespace isolation is an RBAC and management boundary, not a network boundary. NetworkPolicies are the network boundary.

## Common Anti-Patterns

- **No resource requests or limits.** Pods run unguarded and get evicted under node pressure, often taking down unrelated workloads alongside them.
- **`latest` image tags.** No reproducibility, no rollback, no auditability. Every deploy may pull a different image. Pin to SHA or immutable tags.
- **`cluster-admin` for app service accounts.** One compromised pod becomes full cluster compromise.
- **`kubectl apply` without `kubectl diff` first.** You are deploying a manifest you haven't confirmed matches your intent.
- **`kubectl edit` without saving current state.** If the edit goes wrong, you have no clean rollback target.
- **Debugging by `kubectl exec` before reading logs and Events.** You're skipping the two steps that solve 90% of pod failures. Exec creates runtime state changes that obscure the original failure mode.
- **Ignoring the Events section in `kubectl describe`.** The answer is usually there. Read it every time.
- **Declaring a rollout successful from `kubectl rollout status` alone.** Pass a readiness probe, still serving errors — the status is a deployment signal, not an application health signal.
- **Shared namespaces across teams.** One team's runaway quota or permissive RBAC becomes everyone's problem.
