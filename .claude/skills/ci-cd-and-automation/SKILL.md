---
name: ci-cd-and-automation
description: CI/CD strategy and quality-gate design — what to gate on, in what order, with what failure behavior. Use when designing a pipeline's gate structure, defining quality standards, configuring staged rollouts, or debugging CI gate failures. For writing or reviewing GitHub Actions YAML, OIDC configuration, or pipeline security hardening, use deployment-pipelines instead.
when_to_use: |
  Use when setting up a new project's CI pipeline, adding or modifying automated quality gates (lint, type-check, tests, build, security audit), configuring deployment pipelines (preview, staging, production), debugging CI failures, or implementing feature flags and staged rollouts.

  Not when: the task is provisioning cloud resources — use `cloud-infrastructure`. Not when hardening the supply chain, managing OIDC, or authoring GitHub Actions workflows with security focus — use `deployment-pipelines`.
---

# CI/CD and Automation

## Overview

Automate quality gates so that no change reaches production without passing tests, lint, type checking, and build. CI/CD is the enforcement mechanism for every other skill — it catches what humans and agents miss, and it does so consistently on every single change.

**Shift Left:** Catch problems as early in the pipeline as possible — static analysis before tests, tests before staging, staging before production.

**Faster is Safer:** Smaller batches and more frequent releases reduce risk. A deployment with 3 changes is easier to debug than one with 30.

## Universal Rules

1. **Gate every change.** Every PR runs lint, type check, unit tests, build, integration tests, security audit, and bundle size check before merge — no exceptions.
2. **Fix failures; don't silence them.** If lint fails, fix lint. If a test fails, fix the code. Disabling a check to make the pipeline pass is never acceptable.
3. **Shift left.** Run the cheapest checks first; fail fast before expensive steps.
4. **Secrets in the vault, never in code.** Use GitHub Secrets or a vault for all credentials; CI should never have production secrets.
5. **Every deployment is reversible.** Maintain a rollback workflow; staging must be verified before production.
6. **Keep the pipeline under 10 minutes.** When it exceeds that, apply CI optimization strategies before adding more checks.
7. **Feature flags decouple deploy from release.** Ship incomplete work behind flags; set a cleanup date at creation time.

## References

- [references/quality-gate-pipeline.md](references/quality-gate-pipeline.md) — ordered gate diagram (lint → types → tests → build → integration → E2E → audit → bundle)
- [references/github-actions-config.md](references/github-actions-config.md) — YAML for basic CI, DB integration tests, and E2E with Playwright
- [references/deployment-strategies.md](references/deployment-strategies.md) — CI failure feedback loop, preview deploys, feature flags, staged rollouts, rollback workflow, environment management, Dependabot, PR checks
- [references/ci-optimization.md](references/ci-optimization.md) — ordered optimization strategies and parallel-job YAML example
- [references/rationalizations-and-red-flags.md](references/rationalizations-and-red-flags.md) — rationalization table and red-flag checklist

## Verification

After setting up or modifying CI:

- [ ] All quality gates are present (lint, types, tests, build, audit)
- [ ] Pipeline runs on every PR and push to main
- [ ] Failures block merge (branch protection configured)
- [ ] CI results feed back into the development loop
- [ ] Secrets are stored in the secrets manager, not in code
- [ ] Deployment has a rollback mechanism
- [ ] Pipeline runs in under 10 minutes for the test suite

## Related skills

- [deployment-pipelines](../deployment-pipelines/SKILL.md) — YAML implementation of the pipeline configs this skill designs; use when the task is writing GitHub Actions or release pipeline YAML
- [cloud-infrastructure](../cloud-infrastructure/SKILL.md) — provisions the cloud primitives that CI/CD pipelines build and deploy onto
