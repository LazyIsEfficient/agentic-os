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

Folder name = `name` field in frontmatter. Tags help with discovery and routing — they describe the *domain*, the *phase of work*, and the *technologies or concepts* the skill covers.

| Skill | Focus | Tags |
|---|---|---|
| `cloud-infrastructure` | Cloud resources via IaC (AWS, GCP, Cloudflare); reference impl Pulumi/TypeScript | `infrastructure` `provisioning` `iac` `pulumi` `terraform` `aws` `gcp` `cloudflare` `vpc` `rds` `ecs` `messaging` |
| `deployment-pipelines` | CI/CD pipelines (GitHub Actions, OIDC, caching, hardening) | `cicd` `devops` `github-actions` `oidc` `release` `deploy` `caching` `pipeline-security` |
| `documentation-writer` | Docs under `docs/`, Mermaid diagrams, incremental PR-scoped updates | `documentation` `technical-writing` `markdown` `mermaid` `docs-as-code` `pr-scoped` |
| `prompt-shaper` | Interactive intake: turns vague requests into a structured task brief (multi-repo feature, single-repo change, investigation, or bugfix). Invoke as `/shape`. | `intake` `prompt-engineering` `task-scoping` `planning` `briefing` `slash-command` |
| `godot-engineer` | Godot 4 + C# game development: scenes, nodes, physics, animation, UI, save, performance, WebSocket multiplayer, exporting | `game-development` `godot` `godot4` `csharp` `dotnet` `game-engine` `2d` `3d` `physics` `animation` `tween` `shader` `gameplay` `multiplayer` `websocket` `gamedev` |
| `security-engineering` | OWASP, auth, infra hardening, Web3 security, agentic AI security, CI review | `security` `owasp` `asvs` `auth` `appsec` `infra-security` `web3-security` `agentic-ai-security` `code-review` |
| `site-reliability-engineering` | SLOs/error budgets, alerting, on-call, incident response, postmortems, runbooks, toil reduction, chaos | `sre` `operate` `slo` `error-budget` `alerting` `on-call` `incident-response` `postmortem` `runbook` `chaos` `observability` |
| `software-design` | SOLID, cohesion/coupling, separation of concerns, hexagonal architecture, DDD, code review, refactoring | `code-quality` `code-review` `refactoring` `solid` `ddd` `hexagonal` `clean-architecture` `domain-modeling` `cohesion` `coupling` |
| `standards-enforcer` | Engineering standards enforcement at gates: kickoff, pre-merge, pre-release, post-release; security/quality/operational baselines; strategic alignment; exceptions and waivers | `enforcement` `review` `code-review` `pr-review` `compliance` `gate` `quality-gate` `security-baseline` `exceptions` `waivers` `dad-compliance` `adr-compliance` |
| `system-architect` | System design, distributed patterns, fault tolerance, observability, RFCs, capacity planning | `architecture` `system-design` `distributed-systems` `fault-tolerance` `observability` `capacity-planning` `caching-strategy` `rfc` `design-doc` |
| `team-lead` | Linear/Jira ticket policing, ADRs (deviations), DADs (defaults) | `leadership` `process` `tickets` `linear` `jira` `adr` `dad` `decisions` `grooming` `triage` |
| `technical-product-management` | Product strategy, prioritization, roadmaps, PRDs, stakeholder management, launches, metrics, saying no | `product` `tpm` `pm` `product-strategy` `prioritization` `roadmap` `prd` `okrs` `north-star-metric` `mvp` `stakeholders` `launch` `rollout` `discovery-to-delivery` `build-vs-buy` |
| `technical-strategist` | Technical strategy: diagnosis, guiding policy, actions, non-goals, kill criteria; load-bearing DADs; build/buy/adopt; platform-vs-product; tech bets; strategy evolution | `technical-strategy` `tech-strategy` `vision` `principles` `tech-bet` `build-vs-buy` `platform-investment` `load-bearing-dad` `north-star-architecture` `strategy-evolution` |
| `typescript-analytics` | PostHog events, feature flags, client/server analytics in TypeScript | `analytics` `telemetry` `posthog` `feature-flags` `event-tracking` `error-tracking` `typescript` |
| `typescript-data-engineering` | PostgreSQL, BigQuery, ETL, event sourcing, message brokers, caching, in TypeScript | `data-engineering` `etl` `postgres` `bigquery` `prisma` `drizzle` `event-sourcing` `message-brokers` `rabbitmq` `kafka` `sqs` `bullmq` `caching` `redis` `typescript` |
| `typescript-quality-engineering` | Umbrella QE: cross-layer test policy, E2E (Playwright), contract tests, CI | `qa` `testing` `test-strategy` `e2e` `playwright` `test-pyramid` `coverage-policy` `typescript` |
| `typescript-testing-backend` | Jest unit + Supertest integration tests for TypeScript backends | `testing` `backend` `jest` `supertest` `unit-tests` `integration-tests` `typescript` |
| `typescript-testing-frontend` | Jest + RTL tests for React components and hooks | `testing` `frontend` `react` `jest` `react-testing-library` `chakra` `nextjs` `typescript` |
| `ux-design` | UX/UI design: IA, interaction, visual fundamentals, design systems, accessibility, UX writing, critique, handoff | `ux` `ui` `design` `interaction-design` `information-architecture` `design-systems` `accessibility` `wcag` `ux-writing` `figma` `design-critique` `handoff` |
| `ux-research` | User research: methods, discovery, interviews, usability testing, synthesis, personas/JTBD, ethics | `ux` `research` `discovery` `interviews` `usability-testing` `jtbd` `personas` `synthesis` `research-ethics` |
| `web3-smart-contract-engineering` | Solidity contracts with Hardhat + Foundry across EVM chains | `web3` `smart-contracts` `solidity` `hardhat` `foundry` `evm` `erc20` `erc721` `erc1155` `merkle` `signature-verification` `staking` |

### Skill relationships

Skills cross-reference each other where their concerns overlap:

- `cloud-infrastructure` ↔ `deployment-pipelines` ↔ `security-engineering` (provision, deploy, harden)
- `system-architect` ↔ `team-lead` ↔ `documentation-writer` (design, decide, document)
- `system-architect` ↔ `software-design` (macro service boundaries vs micro module structure inside a service)
- `software-design` ↔ `team-lead` (significant module-design choices become ADRs; everyday defaults become DADs)
- `system-architect` ↔ `site-reliability-engineering` (designs SLOs and fault tolerance vs operates them at runtime)
- `site-reliability-engineering` ↔ `deployment-pipelines` (release safety nets, error-budget gating, rollback automation)
- `site-reliability-engineering` ↔ `security-engineering` (security incidents follow the same incident-response process)
- `ux-research` ↔ `ux-design` (research produces evidence; design consumes it; pair early and often)
- `ux-design` ↔ `typescript-testing-frontend` (accessibility testing as a shared concern)
- `ux-design` / `ux-research` ↔ `system-architect` (UX surfaces non-functional requirements that constrain architecture)
- `ux-design` ↔ `software-design` (the design's vocabulary should match the domain model's ubiquitous language)
- `technical-product-management` ↔ `team-lead` (**tightly paired**: TPM owns *what and why*; team-lead owns *how to track and document*)
- `technical-product-management` ↔ `ux-research` (research feeds prioritization; close handoff)
- `technical-product-management` ↔ `ux-design` (TPM picks problems; design solves them)
- `technical-product-management` ↔ `system-architect` (product framing and technical design serve each other; pair on big bets)
- `technical-product-management` ↔ `site-reliability-engineering` (the two halves of the error-budget-policy negotiation)
- `godot-engineer` ↔ `software-design` (Godot scenes are software too; SOLID and cohesion principles apply)
- `godot-engineer` ↔ `ux-research` / `ux-design` (game UX overlaps with web/app UX; playtesting is usability testing)
- `godot-engineer` ↔ `security-engineering` (multiplayer games need server-side validation, anti-cheat, save tamper resistance)
- `godot-engineer` ↔ `cloud-infrastructure` / `deployment-pipelines` / `site-reliability-engineering` (only when running multiplayer game servers)
- `technical-strategist` ↔ `standards-enforcer` (**tightly paired**: the strategist writes the constraints; the enforcer applies them at gates)
- `technical-strategist` ↔ `team-lead` (load-bearing DADs are the strategy in everyday clothing; team-lead maintains the DAD/ADR machinery)
- `technical-strategist` ↔ `technical-product-management` (technical strategy serves the product strategy; pair on quarterly planning)
- `technical-strategist` ↔ `system-architect` (the strategy sets direction; the architect implements specific systems within it)
- `standards-enforcer` ↔ *all skills* (the enforcer cites every other skill at the relevant gates; every skill has an Enforcement note routing to it)
- `typescript-quality-engineering` is the umbrella for QE; defers to `typescript-testing-backend` and `typescript-testing-frontend` for layer-specific unit/integration tests, and to `web3-smart-contract-engineering` for contract tests
- `web3-smart-contract-engineering` ↔ `security-engineering` (authoring vs. adversarial review)

## Using `prompt-shaper`

`prompt-shaper` is the intake skill for turning a half-formed idea into a task brief that downstream skills and subagents can act on. Use it at the *start* of a session, before any code is touched.

**Invoke it two ways:**

- As a slash command: `/shape <your rough description>`
- By describing your intent in natural language — phrases like "help me plan", "shape this", "scope this out", "I want to build…", "new initiative" trigger it automatically.

**What it does:**

1. Picks a template based on the kind of work — multi-repo feature, single-repo change, investigation, or bugfix.
2. Asks **one batched round** of 3–6 focused questions (via `AskUserQuestion`) to fill the gaps in your description. It will not interrogate you one question at a time.
3. Outputs a filled task brief in a fenced markdown block, ready to copy into a fresh session.
4. **Stops there.** It does not start the work. Say `go` after seeing the brief if you want it to execute immediately, or paste the brief into a clean session for best results.

**What it deliberately does *not* do:**

- It does not assign skills to subtasks. Skill auto-selection works on description matching — naming skills explicitly suppresses better matches. The brief describes *concerns* ("schema design", "security review"), and the right skills load themselves when the work begins.
- It does not invent constraints. Sections you didn't supply and weren't asked about are left as `<unknown — to investigate>`.

**Skip it when** the request is already well-scoped (one file, obvious change, clear done criteria). Going straight to the work is faster.

### The recommended workflow

The point of `prompt-shaper` is to **separate thinking from doing**. The shaping conversation is messy and exploratory; the execution should start from a clean, well-scoped brief. Don't conflate the two.

**1. Shape in one session, execute in another.**
The shaping conversation accumulates back-and-forth, half-answers, abandoned tangents, and your own rethinking. None of that helps the executing agent — in fact it confuses skill selection and dilutes attention on the final brief. Run `/shape` in one session, copy the emitted brief, then paste it into a *fresh* session as the very first message. The new session has zero baggage and the brief is the entire context.

**2. Answer the questions concretely.**
The questions are not a quiz — they're the gaps the agent will otherwise fill with assumptions. If you don't know an answer, say so explicitly ("don't know yet — investigate") rather than guessing. The brief will mark it as `<unknown>` and the executor will treat it as the first thing to figure out, instead of silently inventing a value.

**3. Read the brief before you act on it.**
Treat the emitted brief like a PR description you're reviewing. If a section is wrong, vague, or missing the constraint you care most about, **edit it directly** before pasting it into the next session. The brief is a markdown document, not a contract — five seconds of editing here saves a wrong implementation later.

**4. Use the right template for the shape of the work.**
The shaper picks one automatically, but if you know the work doesn't fit (e.g. "this is really an investigation, not a feature"), say so in your initial message. The four templates exist because they prompt for different things:
- **Investigation** asks for the *one question* and the *decision it unblocks* — forces you to commit to a falsifiable goal instead of "look into X".
- **Bugfix** asks for repro steps and explicit out-of-scope — the #1 cause of bugfix sprawl is "while we're in there".
- **Single-repo feature** keeps scope narrow and assumes one PR.
- **Multi-repo feature** assumes a per-repo Explore phase and a stop-for-approval gate before any edits.

**5. Honor the approval gate for multi-repo work.**
The multi-repo template explicitly tells the executor to *stop after producing an integrated plan and wait for your approval* before touching any code. Don't override this. Cross-repo edits are the most expensive thing to undo — the gate is the cheapest place to catch a wrong assumption.

**6. Don't pre-pick skills.**
You may be tempted to write "use the security-engineering skill for the auth review". Don't. Skills auto-load on description matching, and naming them in the brief actively suppresses better matches. Instead, describe the *concern* in plain language ("the auth flow needs a security review before merge") — the right skills will load themselves when the executor reaches that part.

**7. When to skip the shaper entirely.**
If the task is one file, one obvious change, and you can describe done criteria in a sentence — just do it. Shaping a trivial task is overhead. The shaper earns its keep on work that spans more than one file, more than one repo, or more than one session.

**Example session:**

```
You: /shape add rate limiting across our API gateway and the two services behind it
prompt-shaper: <asks 4 questions: which repos, per-user vs per-IP, limit values, deadline>
You: <answers — including "don't know the limit values yet, investigate current traffic first">
prompt-shaper: <emits a filled feature-rollout brief with the limit-values section as <unknown>>
You: <copies the brief, opens a new Claude Code session, pastes it as message 1>
new session: <Explore subagents map each repo, integrated plan emitted, waits for approval>
You: <reviews plan, approves>
new session: <implements repo-by-repo, one PR each>
```

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
