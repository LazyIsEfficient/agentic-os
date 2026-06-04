# Implementation Plan: devops-engineer skill + agent

## Overview

Build a general-purpose, reusable `devops-engineer` skill and agent for the skills-db. The skill gives any agent best-practice grounding for Kubernetes operations, Helm chart authoring, Pulumi IaC, CI/CD pipeline automation, and cluster administration — cloud-agnostic. The agent definition makes it callable as a named agent type. Grounding discipline (read state before acting, quote before changing, UNVERIFIED: flag) is embedded throughout — this is the primary mechanism for preventing hallucination of cluster/manifest state.

## Architecture Decisions

- **One SKILL.md + four reference docs**: Single entry point with deep domain references per tool (k8s, helm, pulumi, cicd). Matches the calibration of `site-reliability-engineering` and other reference-heavy skills.
- **Grounding discipline embedded in Universal Rules**: Read cluster state before suggesting changes (kubectl get/describe); quote manifests before modifying; `UNVERIFIED:` flag for state not read. Non-negotiable per CLAUDE.md.
- **Cloud-agnostic**: No AWS/GCP/Azure-specific examples. Standard k8s API, Helm, and Pulumi only.
- **TypeScript for Pulumi examples**: Default language assumption. Tag as `[Assumed — say if wrong]`.
- **Agent tool allowlist**: Bash (kubectl, helm, pulumi CLIs), Read, Write, Edit, WebFetch (for docs lookup).

## Execution DAG

```yaml
dag:
  - T-skill-md || T-ref-k8s || T-ref-helm || T-ref-pulumi || T-ref-cicd
  - T-skill-md → T-agent
  - checkpoint: Content after [T-skill-md, T-ref-k8s, T-ref-helm, T-ref-pulumi, T-ref-cicd, T-agent]
  - T-skill-md, T-ref-k8s, T-ref-helm, T-ref-pulumi, T-ref-cicd, T-agent → T-review
  - checkpoint: Complete after [T-review]
```

## Task List (presentational)

### Phase 1: Content (all parallel — no file conflicts)
- [ ] T-skill-md — devops-engineer SKILL.md
- [ ] T-ref-k8s — kubernetes-operations reference
- [ ] T-ref-helm — helm-charts reference
- [ ] T-ref-pulumi — pulumi-iac reference
- [ ] T-ref-cicd — cicd-pipelines reference

### After T-skill-md clears:
- [ ] T-agent — agent definition (depends on SKILL.md for trigger phrases)

### Checkpoint: Content
- [ ] All 6 files written
- [ ] SKILL.md has valid frontmatter, universal rules, red flags, verification, references
- [ ] Grounding rules visible in SKILL.md Universal Rules

### Phase 2: Review
- [ ] T-review — library-reviewer on full diff

### Checkpoint: Complete
- [ ] library-reviewer passes with no blocking findings
- [ ] All findings resolved

---

## Task Details

---

### Task: Write devops-engineer SKILL.md

```yaml
id: T-skill-md
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - .claude/skills/devops-engineer/SKILL.md
files_read:
  - .claude/skills/site-reliability-engineering/SKILL.md
  - .claude/skills/ci-cd-and-automation/SKILL.md
  - CLAUDE.md
branch_suffix: skill-md
scope: M
```

**Description:** Author the primary `SKILL.md` for the new `devops-engineer` skill. Working directory is `/Users/glenneggleton/Documents/Clients/YGG/skills-db`.

Before writing, read `.claude/skills/site-reliability-engineering/SKILL.md` and `.claude/skills/ci-cd-and-automation/SKILL.md` to calibrate depth, tone, and structure. Read `CLAUDE.md` for the grounding discipline rules that must appear in Universal Rules.

**File to create:** `.claude/skills/devops-engineer/SKILL.md`

**Required frontmatter** (YAML between `---` delimiters):
- `name: devops-engineer`
- `description:` one-line with trigger phrases including: kubectl, Kubernetes, k8s, Helm, helm chart, Pulumi, pulumi stack, IaC, infrastructure as code, cluster, deployment, rollout, namespace, RBAC, DevOps, platform engineering
- `when_to_use:` multi-line block — use cases (IaC authoring, k8s operations, Helm chart work, Pulumi stacks, CI/CD pipelines, cluster admin) AND explicit not-when cases (service mesh, monitoring stack setup, Terraform, cloud-provider-specific work)

**Required body sections:**

1. **Persona paragraph** (before Universal Rules) — experienced platform/DevOps engineer. Cloud-agnostic. Grounding-first: reads actual cluster/manifest state before acting, never from memory or training data.

2. **Universal Rules** (~10 rules). Must include:
   - Read cluster state before suggesting changes: run `kubectl get`/`kubectl describe` to read current state; do not infer from memory
   - Quote manifests before modifying: copy the relevant YAML before proposing a change; if you can't quote it, you haven't read it
   - Dry-run before apply: `helm diff upgrade`, `pulumi preview`, `kubectl diff` are required before any mutation
   - Never mutate production state without explicit user confirmation
   - `UNVERIFIED:` flag for any state you could not read — do not invent cluster state
   - Pin versions: container image tags, chart versions, Pulumi provider versions — never `latest` in manifests
   - Least-privilege RBAC: prefer namespace-scoped roles; justify any ClusterRole
   - Prefer additive changes; understand rollback path before applying
   - Validate manifests before applying (`kubectl --dry-run=client` or `helm lint`)
   - Treat `kubectl exec` and direct pod mutations as last resort, not first response

3. **Red Flags** — anti-patterns to watch for (e.g. `latest` tags, `cluster-admin` for app workloads, `kubectl apply` without preview, secrets in manifests, no resource limits)

4. **Verification** — checklist for completed DevOps work (state read before changes, diff reviewed, dry-run passed, rollback understood, no secrets in manifests)

5. **References** section linking to the four docs:
   - `[references/kubernetes-operations.md](references/kubernetes-operations.md)` — Day-2 ops, kubectl patterns, pod debugging, rollouts, cluster administration
   - `[references/helm-charts.md](references/helm-charts.md)` — chart authoring, templating, values, upgrade/rollback hygiene
   - `[references/pulumi-iac.md](references/pulumi-iac.md)` — program structure, stack management, state hygiene, preview discipline
   - `[references/cicd-pipelines.md](references/cicd-pipelines.md)` — Helm/Pulumi in pipelines, safe deployment patterns

**Acceptance criteria:**
- [ ] File exists at `.claude/skills/devops-engineer/SKILL.md`
- [ ] Valid YAML frontmatter with `name`, `description`, `when_to_use`
- [ ] Universal Rules include read-before-act and quote-before-change grounding rules explicitly
- [ ] `UNVERIFIED:` flag convention documented
- [ ] Red Flags and Verification checklist sections present
- [ ] References section links to all four reference docs

**Verification:**
- [ ] `head -5 .claude/skills/devops-engineer/SKILL.md` shows valid frontmatter
- [ ] File is ≥ 60 lines (calibrate against SRE skill which is ~90 lines)

---

### Task: Write kubernetes-operations reference

```yaml
id: T-ref-k8s
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - .claude/skills/devops-engineer/references/kubernetes-operations.md
files_read:
  - .claude/skills/site-reliability-engineering/references/incident-response.md
branch_suffix: ref-k8s
scope: M
```

**Description:** Author the Kubernetes operations deep-reference for the `devops-engineer` skill. Working directory is `/Users/glenneggleton/Documents/Clients/YGG/skills-db`.

Read `.claude/skills/site-reliability-engineering/references/incident-response.md` to calibrate depth and structure for a reference doc.

**File to create:** `.claude/skills/devops-engineer/references/kubernetes-operations.md`

**Required sections:**

1. **Grounding first** — open with: before any kubectl command that mutates, read current state first (`kubectl get`, `kubectl describe`). Quote the resource YAML before suggesting a patch. Never infer cluster state from memory.

2. **kubectl command patterns** — essential read commands (get, describe, logs, exec, port-forward, top); flags worth knowing (`-o yaml`, `-o wide`, `--previous`, `--all-namespaces`); when to use each

3. **Pod debugging workflow** — step-by-step: check pod status → describe pod (events section) → check logs → check previous container logs → exec for live inspection → check node events. Grounding at each step: read before diagnosing.

4. **Rollout management** — `rollout status`, `rollout history`, `rollout undo`; how to check that a rollout has actually converged (not just "completed"); reading deployment conditions

5. **Resource inspection before mutation** — `kubectl diff -f` before apply; dry-run patterns; how to get the current live manifest (`kubectl get -o yaml`) before patching

6. **RBAC patterns** — least-privilege: prefer `Role`/`RoleBinding` over `ClusterRole`/`ClusterRoleBinding`; common role templates (read-only, deploy, namespace-admin); how to audit current permissions (`kubectl auth can-i --list`)

7. **Namespace and resource management** — namespace isolation; `ResourceQuota` and `LimitRange` patterns; label/selector hygiene

8. **Network policies** — default-deny-all baseline; explicit allow patterns; how to test connectivity without bypassing policies

9. **Common anti-patterns** — no resource limits/requests, `latest` image tags, `cluster-admin` for app serviceaccounts, `kubectl apply` without reading current state, secrets in ConfigMaps

**Acceptance criteria:**
- [ ] File exists at `.claude/skills/devops-engineer/references/kubernetes-operations.md`
- [ ] Grounding discipline (read before act, quote before change) visible in opening and per-section
- [ ] Pod debugging workflow is step-by-step with read-first discipline
- [ ] RBAC section covers least-privilege and `kubectl auth can-i --list`
- [ ] Anti-patterns section present

**Verification:**
- [ ] File is ≥ 100 lines
- [ ] "UNVERIFIED" or grounding language appears in the read-before-act sections

---

### Task: Write helm-charts reference

```yaml
id: T-ref-helm
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - .claude/skills/devops-engineer/references/helm-charts.md
files_read:
  - .claude/skills/site-reliability-engineering/references/runbooks.md
branch_suffix: ref-helm
scope: M
```

**Description:** Author the Helm chart deep-reference for the `devops-engineer` skill. Working directory is `/Users/glenneggleton/Documents/Clients/YGG/skills-db`.

Read `.claude/skills/site-reliability-engineering/references/runbooks.md` to calibrate reference doc depth and structure.

**File to create:** `.claude/skills/devops-engineer/references/helm-charts.md`

**Required sections:**

1. **Grounding first** — before suggesting chart changes, run `helm get values <release>` and `helm get manifest <release>` to read current deployed state. Never infer what's deployed from the chart source alone.

2. **Chart structure** — `Chart.yaml` (required fields: apiVersion, name, version, appVersion), `values.yaml` (defaults only, no secrets), `templates/` layout, `_helpers.tpl` conventions

3. **Templating best practices** — `{{ .Values }}` vs `{{ .Release }}` vs `{{ .Chart }}`; named templates and `include` vs `template`; quote strings in values; use `default` for optional values; avoid logic-heavy templates

4. **Values hierarchy and override patterns** — base values.yaml → environment overlays → `--set` overrides; when to use each; `--values` file composition; never hardcode environment-specific values in chart defaults

5. **Read release state before upgrading** — `helm status`, `helm history`, `helm get values --revision` to understand current deployed state; `helm diff upgrade` (requires helm-diff plugin) before any upgrade

6. **Release lifecycle** — `helm install` vs `helm upgrade --install`; `--atomic` flag behavior; `--wait` and its caveats; `helm rollback`; `helm uninstall` and PVC/PV lifecycle

7. **Upgrade/rollback hygiene** — always read `helm history` before upgrade; know the rollback target; `--cleanup-on-fail`; CRD upgrade caveats

8. **Helm test patterns** — `helm test` convention; test pod naming; what to verify in tests

9. **Common anti-patterns** — hardcoded image tags, secrets in values.yaml, no resource limits in templates, `helm upgrade` without `helm diff` first, missing `--wait` on install when downstream depends on it

**Acceptance criteria:**
- [ ] File exists at `.claude/skills/devops-engineer/references/helm-charts.md`
- [ ] Grounding (read release state before upgrading) is explicit and prominent
- [ ] Values hierarchy section covers override patterns
- [ ] Rollback hygiene covered
- [ ] Anti-patterns section present

**Verification:**
- [ ] File is ≥ 100 lines
- [ ] `helm get` / `helm diff` commands appear in the grounding section

---

### Task: Write pulumi-iac reference

```yaml
id: T-ref-pulumi
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - .claude/skills/devops-engineer/references/pulumi-iac.md
files_read:
  - .claude/skills/cloud-infrastructure/SKILL.md
branch_suffix: ref-pulumi
scope: M
```

**Description:** Author the Pulumi IaC deep-reference for the `devops-engineer` skill. Working directory is `/Users/glenneggleton/Documents/Clients/YGG/skills-db`.

Read `.claude/skills/cloud-infrastructure/SKILL.md` for context on how IaC discipline is handled elsewhere in this library.

**File to create:** `.claude/skills/devops-engineer/references/pulumi-iac.md`

Primary language assumption: TypeScript. Tag inline as `[Assumed: TypeScript — say if wrong]`.

**Required sections:**

1. **Grounding first** — `pulumi preview` is mandatory before `pulumi up`. Read the planned diff carefully — especially destroys and replacements. Never run `pulumi up` without reviewing preview output. For existing stacks, run `pulumi stack output` and `pulumi state` to read current state before writing new resources.

2. **Project structure** — `Pulumi.yaml` (name, runtime, description), `Pulumi.<stack>.yaml` (stack config), `index.ts` entry point; package.json/tsconfig for TypeScript projects; `@pulumi/pulumi` version pinning

3. **Stack management** — `pulumi stack init`, `pulumi stack select`, `pulumi stack ls`; stack-per-environment pattern (dev/staging/prod); `pulumi stack output` for reading outputs; never share stacks across environments

4. **Preview discipline** — read preview output before up: understand creates, updates, replacements, and destroys; replacements often cause downtime — understand why before proceeding; `--diff` flag for detailed change view; never skip preview in automation

5. **State hygiene** — Pulumi state is the source of truth for deployed resources; `pulumi state` commands for inspection; `pulumi import` for importing existing resources; avoid manual state edits; `pulumi refresh` to sync state with reality; `pulumi state delete` only as last resort with user confirmation

6. **Resource protection** — `protect: true` for production resources (databases, stateful workloads); `ignoreChanges` for externally-managed fields; `retainOnDelete` for data persistence; document why each protection is set

7. **Secret management** — `pulumi config set --secret` for sensitive values; never hardcode secrets in code or `Pulumi.<stack>.yaml`; use `pulumi.secret()` to mark outputs as secret; avoid logging secret values

8. **TypeScript patterns** — `ComponentResource` for reusable abstractions; async resource creation patterns; `pulumi.Output<T>` and `apply()` for dependent values; `pulumi.all()` for multiple outputs; avoid `toString()` on Output values

9. **Common anti-patterns** — `pulumi up` without preview, hardcoded secrets, no stack-per-environment, `latest` provider versions, manual state edits, ignoring destroys in preview output

**Acceptance criteria:**
- [ ] File exists at `.claude/skills/devops-engineer/references/pulumi-iac.md`
- [ ] Preview-before-up is the prominent opening grounding rule
- [ ] State hygiene section covers `pulumi refresh` and `pulumi import`
- [ ] Resource protection patterns documented
- [ ] TypeScript assumption tagged inline

**Verification:**
- [ ] File is ≥ 100 lines
- [ ] `pulumi preview` and state hygiene sections present

---

### Task: Write cicd-pipelines reference

```yaml
id: T-ref-cicd
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - .claude/skills/devops-engineer/references/cicd-pipelines.md
files_read:
  - .claude/skills/ci-cd-and-automation/SKILL.md
branch_suffix: ref-cicd
scope: S
```

**Description:** Author the CI/CD pipelines deep-reference for the `devops-engineer` skill. Working directory is `/Users/glenneggleton/Documents/Clients/YGG/skills-db`.

Read `.claude/skills/ci-cd-and-automation/SKILL.md` for calibration — understand what that skill already covers so this reference complements rather than duplicates it. This reference focuses on the Helm and Pulumi deployment mechanics specifically.

**File to create:** `.claude/skills/devops-engineer/references/cicd-pipelines.md`

**Required sections:**

1. **Grounding first** — pipelines must read current state before deploying: `helm diff upgrade` in PR pipelines (not just lint); `pulumi preview` on PRs (not just `pulumi up` on merge). Pipelines that only mutate without reading are a hallucination risk.

2. **Helm in CI** — `helm lint` + `helm template | kubectl --dry-run` for validation; `helm diff upgrade` on PRs as a gate; `helm upgrade --install --atomic --wait` for production deploys; chart version pinning in CI

3. **Pulumi in CI** — `pulumi preview` on PRs (comment results to PR); `pulumi up --yes` on merge to main; stack selection in CI (`pulumi stack select`); CI token vs personal token; `PULUMI_ACCESS_TOKEN` as a secret

4. **Safe deployment patterns** — environment promotion (dev → staging → prod) with gates between each; smoke tests after deploy before promoting; rollback trigger conditions; never skip staging

5. **Deployment gates** — what to check before promoting: health checks, smoke test pass, no error spike in metrics, rollback plan confirmed; who approves production promotion

6. **Secrets in pipelines** — no hardcoded credentials; use CI secret management (GitHub Actions secrets, etc.); OIDC for cloud auth where available; rotate secrets on breach; never `echo` secrets in pipeline output

7. **Common anti-patterns** — `pulumi up` without preview in pipeline, `helm upgrade` without diff gate, no smoke tests, promoting to prod without staging, secrets in pipeline YAML

**Acceptance criteria:**
- [ ] File exists at `.claude/skills/devops-engineer/references/cicd-pipelines.md`
- [ ] Preview/diff gates for both Helm and Pulumi are prominent
- [ ] Environment promotion pattern documented
- [ ] Secrets section covers OIDC and secret management

**Verification:**
- [ ] File is ≥ 80 lines
- [ ] Both `helm diff` and `pulumi preview` appear as CI gates

---

### Task: Write devops-engineer agent definition

```yaml
id: T-agent
depends_on: [T-skill-md]
parallel_safe: true
conflicts_with: []
files_write:
  - .claude/agents/devops-engineer.md
files_read:
  - .claude/skills/devops-engineer/SKILL.md
  - .claude/agents/engineer.md
branch_suffix: agent
scope: S
```

**Description:** Author the agent definition for `devops-engineer`. Working directory is `/Users/glenneggleton/Documents/Clients/YGG/skills-db`.

**Wait for T-skill-md to complete first** — this task must read the finished `SKILL.md` to align trigger phrases and description.

Read `.claude/agents/engineer.md` to understand the agent file format (frontmatter + persona paragraph + skills sections + operating principles + delegation). Match that depth and structure.

**File to create:** `.claude/agents/devops-engineer.md`

**Required frontmatter:**
- `name: devops-engineer`
- `description:` one-line trigger-phrase-rich description. Must match the skill's trigger phrases. Include: kubectl, Kubernetes, k8s, Helm, helm chart, Pulumi, pulumi stack, IaC, cluster, deployment, rollout, namespace, RBAC, DevOps, platform engineering, infrastructure. Also include "For Solidity see web3-engineer. For SRE/on-call work see site-reliability-engineering."

**Required body:**

1. **Persona paragraph** — experienced platform/DevOps engineer. Cloud-agnostic. Grounding-first: reads cluster state and manifests before suggesting changes. Never invents state from training data — uses kubectl/helm/pulumi commands to read actual state first.

2. **Skills to load** — load `devops-engineer` skill for all tasks. Load adjacent skills when relevant:
   - [devops-engineer](../skills/devops-engineer/SKILL.md) — primary skill: grounding rules, k8s/helm/pulumi/cicd best practices
   - [site-reliability-engineering](../skills/site-reliability-engineering/SKILL.md) — production operations, SLOs, incidents
   - [cloud-infrastructure](../skills/cloud-infrastructure/SKILL.md) — IaC across clouds
   - [security-and-hardening](../skills/security-and-hardening/SKILL.md) — secrets, RBAC, network policies
   - [ci-cd-and-automation](../skills/ci-cd-and-automation/SKILL.md) — pipeline quality gates
   - [deployment-pipelines](../skills/deployment-pipelines/SKILL.md) — release mechanics, rollback automation

3. **Operating principles** (5–7 bullet points):
   - Read actual state before suggesting changes (kubectl/helm/pulumi commands first)
   - Quote manifests and config before modifying them
   - Dry-run / preview before every apply or up
   - Never mutate production without explicit user confirmation
   - Pin all versions — images, charts, providers
   - Prefer namespace-scoped RBAC; justify any cluster-wide permission

4. **Delegate to other agents:**
   - **code-reviewer** — review infrastructure code changes
   - **security-reviewer** — RBAC, secrets, network policy review
   - **prompt-shaper** — when the DevOps task is still vague

**Acceptance criteria:**
- [ ] File exists at `.claude/agents/devops-engineer.md`
- [ ] Frontmatter has `name` and `description` with rich trigger phrases
- [ ] Persona paragraph establishes grounding-first discipline
- [ ] Skills section links to `devops-engineer` skill and adjacent skills
- [ ] Operating principles include read-before-act and dry-run-before-apply

**Verification:**
- [ ] `head -5 .claude/agents/devops-engineer.md` shows valid frontmatter
- [ ] "kubectl" and "Pulumi" appear in description trigger phrases

---

### Task: Library review

```yaml
id: T-review
depends_on: [T-skill-md, T-ref-k8s, T-ref-helm, T-ref-pulumi, T-ref-cicd, T-agent]
parallel_safe: false
conflicts_with: []
files_write: []
files_read:
  - .claude/skills/devops-engineer/SKILL.md
  - .claude/skills/devops-engineer/references/kubernetes-operations.md
  - .claude/skills/devops-engineer/references/helm-charts.md
  - .claude/skills/devops-engineer/references/pulumi-iac.md
  - .claude/skills/devops-engineer/references/cicd-pipelines.md
  - .claude/agents/devops-engineer.md
branch_suffix: review
scope: S
```

**Description:** Run `library-reviewer` agent type on the full diff of the `devops-engineer` skill and agent. Working directory is `/Users/glenneggleton/Documents/Clients/YGG/skills-db`.

Spawn a `library-reviewer` agent on these 6 files:
- `.claude/skills/devops-engineer/SKILL.md`
- `.claude/skills/devops-engineer/references/kubernetes-operations.md`
- `.claude/skills/devops-engineer/references/helm-charts.md`
- `.claude/skills/devops-engineer/references/pulumi-iac.md`
- `.claude/skills/devops-engineer/references/cicd-pipelines.md`
- `.claude/agents/devops-engineer.md`

Resolve all blocking findings before marking complete.

**Acceptance criteria:**
- [ ] library-reviewer spawned and reviewed all 6 files
- [ ] All blocking findings resolved
- [ ] No Critical or Important unresolved issues

**Verification:**
- [ ] library-reviewer verdict is pass or pass-with-nits
- [ ] git diff shows only devops-engineer files added

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Reference docs too shallow (list of commands, not opinionated guidance) | Med | Calibrate against SRE/incident-response.md depth — each section should have a "why" and a "when to use" |
| SKILL.md trigger phrases don't match agent description | Med | T-agent reads SKILL.md before writing — must copy trigger vocabulary |
| Grounding rules sound generic and get ignored | High | Make them specific: name the exact kubectl/helm/pulumi commands to run. "Read state" is too vague; "`kubectl describe pod <name>` before diagnosing" is actionable |
| library-reviewer flags frontmatter issues | Low | Follow exact format from existing skills: name, description, when_to_use |

## Open Questions

- None — all load-bearing items answered. TypeScript as Pulumi language is assumed; override if wrong.
