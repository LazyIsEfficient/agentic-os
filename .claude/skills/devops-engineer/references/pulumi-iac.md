# Pulumi IaC Reference

> **Grounding rule (read first):** Before every `pulumi up`, run `pulumi preview` and read the output in full. Before touching an existing stack, run `pulumi stack output` and `pulumi state export` to understand what is deployed. Mark any stack state you have not personally read as `UNVERIFIED:`. This is not optional hygiene — it is the only way to know what you are about to change.

For resource-specific patterns (VPC, RDS, ECS, secrets, IAM, Cloudflare) see the [cloud-infrastructure skill](../../cloud-infrastructure/SKILL.md). This reference covers Pulumi workflow, state, and TypeScript mechanics.

---

## 1. Project Structure [Assumed: TypeScript — say if wrong]

```
my-stack/
├── Pulumi.yaml            # project name, runtime: nodejs, description
├── Pulumi.dev.yaml        # stack-specific config for dev (non-secret values)
├── Pulumi.prod.yaml       # stack-specific config for prod
├── index.ts               # entry point — keep thin; delegate to modules/
├── package.json           # pin @pulumi/pulumi and every provider version explicitly
└── tsconfig.json          # strict: true recommended; moduleResolution: node
```

`pulumi new typescript` for a bare scaffold; `pulumi new aws-typescript` for an AWS-wired scaffold. Pin provider versions — `"@pulumi/aws": "*"` will silently break on the next major provider release. `index.ts` should read config and export outputs only; resource logic belongs in `./modules/`.

---

## 2. Stack Management

```bash
pulumi stack init dev          # create a stack; one per environment
pulumi stack select prod       # switch stacks — verify the asterisk before preview/up
pulumi stack ls                # list stacks; confirm active stack
pulumi stack output            # read exported outputs from current stack
pulumi config get <key>        # read a config value for the active stack
pulumi config set <key> <val>  # write into Pulumi.<stack>.yaml
```

**One stack = one environment.** Sharing a stack between dev and prod collapses the isolation boundary. A misconfigured `stack select` is then the only thing standing between a dev change and production — that is not a guard, it is a trap.

---

## 3. Preview Discipline

**`pulumi preview` is required before every `pulumi up` — no exceptions.**

```bash
pulumi preview                       # always
pulumi preview --diff                # property-level diff when output is ambiguous
pulumi preview --expect-no-changes   # assert no drift in CI
```

| Symbol | Meaning | Risk |
|--------|---------|------|
| `+`    | Create  | Low |
| `~`    | Update  | Medium — verify the property changing |
| `+-`   | Replace | **High — destroyed and recreated** |
| `-`    | Destroy | **High — deleted** |

Pulumi replaces a resource when an immutable property changes — an RDS `identifier`, an ECS task `family`, a Cloudflare `zone_id`. When you see `+-`, use `pulumi preview --diff` to find the offending property and confirm recreation is intentional. Replacements of stateful resources cause downtime.

**Never skip preview because "it's a small change."** A one-line rename of an RDS instance triggers a replace that destroys the database. The blast radius of an unexpected replacement does not scale with the size of the diff.

For existing stacks, read current state before writing new resources:
```bash
pulumi stack output && pulumi state export > state.json
```
If you cannot read the stack state, mark every assumption `UNVERIFIED:`.

---

## 4. State Hygiene

Pulumi state is the authoritative record of what the program believes is deployed. Treat it as sacred.

```bash
pulumi refresh                          # sync state with actual cloud reality
pulumi state export > state.json        # backup before any risky operation
pulumi import <type> <name> <cloud-id>  # adopt existing resources into state
pulumi state move <urn> <dest-stack>    # move resource between stacks (advanced)
pulumi state delete <urn>               # remove from state only; does not destroy in cloud
```

Run `pulumi refresh` before risky operations — out-of-band changes (console, CLI, another tool) leave state stale and produce phantom diffs. `pulumi state delete` is a last resort for resources already gone from the cloud; using it on a live resource orphans it permanently. Never recreate an existing database to bring it under Pulumi — use `pulumi import`. Never manually edit state JSON; the format has internal consistency requirements that manual edits silently violate.

---

## 5. Resource Protection

```typescript
const db = new aws.rds.Instance("prod-db", { ... }, {
  protect: true,        // pulumi up errors on any attempted destroy
  retainOnDelete: true, // removed from state but not deleted in cloud
});

const svc = new aws.ecs.Service("api", { ... }, {
  ignoreChanges: ["desiredCount"], // autoscaler manages this field externally
});
```

Always comment why a protection flag is set. `protect: true` without context reads as a mistake and will be removed. Write: `// protect: true — prod RDS; accidental replace = data loss + downtime`.

---

## 6. Secret Management

```bash
pulumi config set --secret DB_PASSWORD <value>  # encrypted in Pulumi.<stack>.yaml
```

```typescript
const config = new pulumi.Config();
const pwd = config.requireSecret("DB_PASSWORD"); // Output<string>, redacted in logs
const marked = pulumi.secret(computedValue);     // mark any Output as secret
```

Never hardcode secrets in `index.ts` or committed config files. Never `console.log` a secret Output — it appears verbatim in CI logs. Use `.requireSecret()`, not `.require()` — the former returns a redacted `Output<string>`; the latter leaks the value as a plain string.

---

## 7. TypeScript Patterns [Assumed: TypeScript]

`pulumi.Output<T>` resolves at deployment time, not at program evaluation time. Treating it as a plain value is the most common Pulumi TypeScript mistake.

```typescript
// WRONG — produces "[Output<string>]"
const url = `https://${bucket.bucketName}/path`;

// RIGHT
const url = pulumi.interpolate`https://${bucket.bucketName}/path`;
const upper = bucket.bucketName.apply(n => n.toUpperCase());
const combined = pulumi.all([a.id, b.arn]).apply(([id, arn]) => `${id}:${arn}`);
```

Never call `.toString()` on an Output — TypeScript permits it but the result is always the object's internal string, never the cloud value.

`ComponentResource` is the abstraction for reusable modules. Child resources declared with `{ parent: this }` appear nested in `pulumi preview` and inherit `protect: true` from the parent — use this for logical groupings like "an ECS service plus its task definition plus its IAM role."

---

## 8. Anti-Patterns

| Anti-pattern | Failure mode |
|---|---|
| `pulumi up` without preview | Blind replacements and destroys |
| Hardcoded secrets in code | Credentials in git history forever |
| Shared stack across environments | Wrong-env deploy on `stack select` mistake |
| Unpinned provider versions | Silent breaking changes on `npm install` |
| Manual state JSON edits | Corrupted state, phantom resources |
| Ignoring `+-` replacements | Unplanned downtime for stateful resources |
| `.toString()` on Output | Silently wrong config passed to resources |
| No `protect: true` on databases | A single typo deletes production data |
| Skipping `pulumi refresh` | Phantom diffs from out-of-band changes |
