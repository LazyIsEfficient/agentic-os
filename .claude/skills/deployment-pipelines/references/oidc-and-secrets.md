# OIDC and Secrets

Long-lived cloud credentials in CI are a liability. OIDC federation lets a workflow assume a cloud role for the duration of a single run, with claims about the repo, branch, and environment baked into the trust policy.

## OIDC to AWS

### Trust Policy (provisioned by the `devops-engineer` agent)

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:org/repo:environment:production"
      }
    }
  }]
}
```

Critical: scope `sub` as **narrowly as possible**:
- `repo:org/repo:ref:refs/heads/main` — only main branch
- `repo:org/repo:environment:production` — only when the prod environment is in use
- `repo:org/repo:pull_request` — for PR validation
- **Avoid** `repo:org/repo:*` — that grants any branch / PR / tag.

### Workflow Side

```yaml
permissions:
  id-token: write       # required to mint the OIDC token
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-24.04
    environment: production    # gates the run AND binds OIDC sub
    steps:
      - uses: actions/checkout@<sha>
      - uses: aws-actions/configure-aws-credentials@<sha>
        with:
          role-to-assume: arn:aws:iam::ACCOUNT:role/gh-deploy-prod
          aws-region: us-east-1
      - run: aws sts get-caller-identity
```

## OIDC to GCP (Workload Identity Federation)

```yaml
- uses: google-github-actions/auth@<sha>
  with:
    workload_identity_provider: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER
    service_account: deploy@PROJECT.iam.gserviceaccount.com
```

Same rules apply: scope the provider's attribute condition to specific repos / branches / environments.

## Repository / Environment Secrets

When you genuinely need a secret (third-party API key, signing key):

- **Environment secrets** > repo secrets > org secrets. Smaller scope = smaller blast radius.
- **Environment protection rules**: required reviewers, wait timers, branch restrictions.
- **Never read secrets in `pull_request` workflows from forks** — GitHub correctly withholds them, but be sure your workflow doesn't `pull_request_target` around it.
- **Rotate on a schedule** and on every contributor offboarding.

## Anti-Patterns

- **AWS access keys in repo secrets** for any account that can touch production.
- **`AWS_*` env vars set at the workflow level** — they leak into every step, including ones that run untrusted code.
- **Re-using one IAM role for all environments** — a bug in dev should not be able to touch prod.
- **`if: github.actor == 'someone'`** as an authz check — actor is spoofable in some contexts; use environment protection rules.
- **Echoing the OIDC token** for "debugging". It's a credential.
- **Wide `sub` claims** like `repo:org/repo:*` — defeats the point of OIDC.

## Verification Checklist

Before merging a workflow that touches cloud:
- [ ] Uses OIDC, not access keys
- [ ] `sub` claim scoped to exact ref / environment
- [ ] `id-token: write` granted at job level, not workflow level
- [ ] `environment:` set on deploy jobs with protection rules
- [ ] Role grants least-privilege IAM (not `*`)
- [ ] No secrets logged or echoed
