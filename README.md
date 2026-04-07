# skills-db

Central repository of agent skills (compatible with Claude Code, Claude Agent SDK, and Cursor): markdown playbooks with YAML frontmatter that teach an AI agent how to follow your stack, tests, security bar, and infrastructure conventions.

Each skill is a directory containing a `SKILL.md` file plus optional `references/`, `assets/`, and `scripts/` subdirectories.

## Layout

Each skill is a folder whose name matches the `name` field in the skill frontmatter:

```
<skill-name>/
├── SKILL.md          # required — entry point with frontmatter + universal rules
├── references/       # optional — deep-dive docs the agent loads on demand
├── assets/           # optional — fill-in templates the agent copies (ADRs, RFCs, etc.)
└── scripts/          # optional — runnable helper scripts
```

`SKILL.md` should stay concise (target <100 lines): frontmatter, role/context, universal rules, and a list of references. All long-form details belong in `references/` (progressive disclosure). Templates that the agent fills out belong in `assets/`, not `references/`.

Copy or sync entire folders into a project:

```text
<your-project>/.claude/skills/<skill-name>/        # Claude Code
<your-project>/.cursor/skills/<skill-name>/        # Cursor
```

## Skills in this repo

| Folder | `name` (frontmatter) | Focus |
|--------|----------------------|--------|
| `cloud-infrastructure` | Cloud resources via IaC (AWS, GCP, Cloudflare); reference impl Pulumi/TypeScript |
| `deployment-pipelines` | CI/CD pipelines (GitHub Actions, OIDC, caching, hardening) |
| `documentation-writer` | Docs under `docs/`, Mermaid diagrams, incremental PR-scoped updates |
| `security-engineering` | OWASP, auth, infra hardening, Web3 security, agentic AI security, CI review |
| `system-architect` | System design, distributed patterns, fault tolerance, observability, RFCs |
| `team-lead` | Linear/Jira ticket policing, ADRs (deviations), DADs (defaults) |
| `typescript-analytics` | PostHog events, feature flags, client/server analytics in TypeScript |
| `typescript-data-engineering` | PostgreSQL, BigQuery, ETL, event sourcing in TypeScript |
| `typescript-quality-engineering` | Umbrella QE: cross-layer test policy, E2E (Playwright), contract tests, CI |
| `typescript-testing-backend` | Jest unit + Supertest integration tests for TypeScript backends |
| `typescript-testing-frontend` | Jest + RTL tests for React components and hooks |
| `web3-smart-contract-engineering` | Solidity contracts with Hardhat + Foundry across EVM chains |

### Skill relationships

Skills cross-reference each other where their concerns overlap:

- `cloud-infrastructure` ↔ `deployment-pipelines` ↔ `security-engineering` (provision, deploy, harden)
- `system-architect` ↔ `team-lead` ↔ `documentation-writer` (design, decide, document)
- `typescript-quality-engineering` is the umbrella for QE; defers to `typescript-testing-backend` and `typescript-testing-frontend` for layer-specific unit/integration tests, and to `web3-smart-contract-engineering` for contract tests
- `web3-smart-contract-engineering` ↔ `security-engineering` (authoring vs. adversarial review)

## Frontmatter conventions

Every `SKILL.md` starts with:

```yaml
---
name: lowercase-hyphenated-id          # must match the directory name
description: Use when <situation>. Triggers on <file globs> or mentions of "<keyword>", "<keyword>", ... For <related concern> see <other-skill>.
---
```

Rules for the `description`:

- Third person, written for the agent's loader, not the human reader.
- State **WHAT** the skill does and **WHEN** to load it (situation + trigger globs/keywords).
- Use **portable globs** (`**/*.test.tsx`, `**/__tests__/`), not project-specific paths (`apps/foo/...`).
- Cross-reference adjacent skills at the end ("For X see other-skill") so the loader can route correctly.
- Keep it under ~1024 characters.

## Authoring rules

- **Keep `SKILL.md` short** — frontmatter, 1–2 paragraphs of context, a "Universal Rules" list, and a references list. Long-form content goes in `references/`.
- **Progressive disclosure** — never inline a 200-line code example in `SKILL.md`; link to a reference file instead.
- **No company-specific names in `SKILL.md`** — descriptions especially must be portable. Concrete code examples in `references/` may use realistic identifiers, but frame them as examples, not as the only valid pattern.
- **Templates go in `assets/`** — anything the agent fills out and copies (ADRs, RFCs, design docs) lives in `assets/`, not `references/`.
- **Cross-reference related skills** — when a topic spans skills, link both ways in a "Related skills" section.

## Syncing into projects

Copy the skill directories you need into each repo (rsync, Taskfile, submodule, etc.):

```text
<your-project>/.claude/skills/<skill-name>/        # Claude Code
<your-project>/.cursor/skills/<skill-name>/        # Cursor
```

Commit the synced skills in application repos if the whole team should share the same agent behavior.

## Contributing

Add or edit skills here, then redeploy copies to downstream repos. If a `SKILL.md` is approaching ~100 lines, split content into `references/` files and link them — the agent loads references on demand.
