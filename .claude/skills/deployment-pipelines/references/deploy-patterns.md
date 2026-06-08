# Deploy Patterns

How code goes from merged PR to running in production.

## Environment Promotion

```
PR merged → staging (auto) → production (manual approval / tag)
```

Each environment is a GitHub **Environment** with:
- Required reviewers (for prod)
- Wait timer (for prod, optional cool-off)
- Branch / tag restrictions
- Environment-scoped secrets and OIDC roles

```yaml
jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/main'
    environment: staging
    ...

  deploy-production:
    needs: deploy-staging
    environment: production    # gated by reviewers
    ...
```

## Preview vs Apply (IaC pattern)

For Pulumi / Terraform:

```yaml
preview:
  if: github.event_name == 'pull_request'
  steps:
    - uses: pulumi/actions@<sha>
      with:
        command: preview
        stack-name: org/staging
        comment-on-pr: true        # diff posted as PR comment

deploy:
  if: github.ref == 'refs/heads/main'
  environment: staging
  steps:
    - uses: pulumi/actions@<sha>
      with:
        command: up
        stack-name: org/staging
```

The PR sees the diff before merging. The deploy on main applies it. **Never `up` without a `preview` somewhere upstream.**

## Deploy Gates

Things that should block a deploy:
- All required checks green
- Required reviewers approved
- Linked tickets in the right state (optional, via custom check)
- Recent incident on the target environment (optional, via status page check)
- Off-hours window for high-risk deploys (optional, via wait timer)

## Rollback Strategy

Pick **one** rollback story per system and document it:

| Strategy | When |
|---|---|
| **Re-deploy previous tag** | Stateless services. Fast, clear. |
| **Forward fix only** | Database migrations, schema changes. Roll forward to a hotfix. |
| **Blue/green swap** | Zero-downtime infra. Most expensive operationally. |
| **Feature flag off** | When the change is gated. Fastest rollback. |

The workflow that deploys must also support the rollback. A deploy you can't undo is a bug.

## OIDC Role Per Environment

```yaml
deploy:
  environment: production
  permissions:
    id-token: write
    contents: read
  steps:
    - uses: aws-actions/configure-aws-credentials@<sha>
      with:
        role-to-assume: arn:aws:iam::ACCOUNT:role/gh-deploy-prod
        role-session-name: gh-${{ github.run_id }}
        aws-region: us-east-1
```

Each environment uses a separate IAM role with separate trust policies. A bug in the staging workflow cannot deploy to production.

## Idempotency

Re-running the same deploy on the same SHA must be safe:
- IaC tools (Pulumi/Terraform) are idempotent by design.
- Container deploys: tag images by commit SHA, not `latest`. Re-deploying = re-applying the same task definition.
- Migrations: always forward, idempotent (`CREATE IF NOT EXISTS`, transactional, versioned).

## Anti-Patterns

- **Auto-deploy to production on merge to main.** No protection rules, no human gate. One merged bad PR = one outage.
- **Deploy step that builds the artifact.** Build once in CI, deploy the same artifact to staging and prod. Building per-environment introduces drift.
- **Manual deploy steps in a runbook.** If it can be scripted, script it. Runbooks are for incidents, not normal deploys.
- **No rollback path.** "We'll figure it out if it breaks" is how 2-hour outages become 8-hour outages.
- **Same role for all environments.** A staging compromise should not pivot to prod.
- **Tag-mutable image references** (`myapp:latest`). Pin to immutable digests or commit SHAs.

## Health Checks Post-Deploy

Every deploy workflow should:
1. Apply the change
2. Wait for the new version to come up (rolling, blue/green, etc.)
3. Hit a health endpoint or run a smoke test
4. Roll back automatically on failure (or alert the deployer)
5. Post status to the team channel

A deploy that "succeeded" but left the service unhealthy is worse than a deploy that failed loudly.
