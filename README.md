# skills-db

Central repository of [Cursor Agent Skills](https://cursor.com): markdown playbooks with YAML frontmatter that teach the agent how to follow your stack, tests, security bar, and infrastructure conventions.

Each skill is a directory containing a `SKILL.md` file (and optional supporting files). Cursor loads project skills from `.cursor/skills/<skill-folder>/SKILL.md`.

## Layout

Prefer a **flat** folder per skill, where the directory name matches the `name` field in the skill frontmatter:

```
<skill-name>/
└── SKILL.md
```

Copy or sync entire folders into a project:

```text
<your-project>/.cursor/skills/<skill-name>/SKILL.md
```

## Skills in this repo

| Folder | `name` (frontmatter) | Focus |
|--------|----------------------|--------|
| `typescript-analytics` | `typescript-analytics` | PostHog, events, feature flags, client/server analytics |
| `typescript-data-engineering` | `typescript-data-engineering` | PostgreSQL, BigQuery, ETL, event sourcing |
| `pulumi-infrastructure` | `pulumi-infrastructure` | Pulumi (AWS, GCP, Cloudflare) |
| `security-engineering` | `security-engineering` | OWASP, auth, infra hardening, Web3 security, CI review |
| `typescript-testing-backend` | `typescript-testing-backend` | Jest, Supertest, backend integration tests |
| `typescript-testing-frontend` | `typescript-testing-frontend` | Jest, RTL, Chakra, Next.js frontend tests |
| `typescript-quality-engineering` | `typescript-quality-engineering` | Broader QE: Jest, RTL, Playwright, Supertest, Hardhat |
| `web3-smart-contract-engineering` | `web3-smart-contract-engineering` | Solidity, Hardhat, Foundry, Thirdweb |

## Frontmatter

Every `SKILL.md` starts with:

```yaml
---
name: lowercase-hyphenated-id
description: Third-person summary of what the skill does and when to use it (include trigger terms).
---
```

The `description` drives when Cursor includes the skill in context; keep it specific.

## Syncing into projects

Use rsync, a Taskfile, or submodule: copy the skill directories you need into each repo’s `.cursor/skills/`. Commit `.cursor/skills/` in application repos if the whole team should share the same agent behavior.

## Contributing

Add or edit skills here, then redeploy copies to downstream repos. Split very large `SKILL.md` files with linked `reference.md` / `examples.md` in the same folder if you approach Cursor’s recommended size limits.
