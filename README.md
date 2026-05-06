# skills-db

Central repository of agent skills and agents (compatible with Claude Code, Claude Agent SDK, and Cursor): markdown playbooks with YAML frontmatter that teach an AI agent how to follow your stack, tests, security bar, and infrastructure conventions.

## Layout

Skills are directories; agents are single files. Folder/file names must match the `name` field in frontmatter.

```
.claude/
├── skills/<skill-name>/
│   ├── SKILL.md          # required — frontmatter, universal rules, references list (target <100 lines)
│   ├── references/       # deep-dive docs loaded on demand
│   ├── assets/           # fill-in templates (ADRs, RFCs, briefs)
│   └── scripts/          # runnable helpers
└── agents/<agent-name>.md   # frontmatter, role definition, optional tools allowlist
```

Long-form content lives in `references/`, not `SKILL.md` (progressive disclosure). Templates the agent fills out belong in `assets/`.

## Install

```bash
# .claude/skills/ (default)
curl -fsSL https://raw.githubusercontent.com/YieldGuildGames/skills-directory/main/install.sh | bash

# .cursor/skills/
curl -fsSL https://raw.githubusercontent.com/YieldGuildGames/skills-directory/main/install.sh | bash -s -- --cursor

# Both
curl -fsSL https://raw.githubusercontent.com/YieldGuildGames/skills-directory/main/install.sh | bash -s -- --both
```

Re-run to update — files are overwritten with the latest version.

### Manual install

```text
<your-project>/.claude/skills/<skill-name>/        # Claude Code
<your-project>/.cursor/skills/<skill-name>/        # Cursor
```

## Skills in this repo

Folder name = `name` field in frontmatter. Tags help with discovery and routing — domain, phase of work, and technologies covered.

| Skill | Focus | Tags |
|---|---|---|
| `api-and-interface-design` | Design stable, hard-to-misuse APIs and interfaces with consistent contracts | `api-design` `interfaces` `rest` `graphql` `contracts` `validation` |
| `autoresearch` | Multi-round content optimization with expert panel scoring | `content-optimization` `conversion-testing` `copywriting` `a-b-testing` |
| `browser-testing-with-devtools` | Inspect and test browser-based code using Chrome DevTools MCP | `browser-testing` `devtools` `debugging` `ui-testing` `dom-inspection` `network-analysis` |
| `ci-cd-and-automation` | Developer-focused quality gates, GitHub Actions, feature flags, staged rollouts | `ci-cd` `automation` `github-actions` `quality-gates` `feature-flags` `deployment` |
| `cloud-infrastructure` | Cloud resources via IaC (AWS, GCP, Cloudflare); reference impl Pulumi/TypeScript | `infrastructure` `provisioning` `iac` `pulumi` `terraform` `aws` `gcp` `cloudflare` `vpc` `rds` `ecs` `messaging` |
| `code-review-and-quality` | Multi-axis code review: correctness, readability, architecture, security, performance | `code-review` `quality` `correctness` `readability` `review-process` |
| `code-simplification` | Reduce complexity and improve readability without changing behavior | `refactoring` `code-quality` `readability` `simplification` `clarity` |
| `content-ops` | Expert panel scoring and iterative improvement for any content | `content-evaluation` `quality-gates` `expert-review` `scoring` `copywriting` |
| `context-engineering` | Structure and deliver relevant context to maximize agent output quality | `context-engineering` `prompting` `agent-optimization` `knowledge-structure` |
| `conversion-ops` | Landing page audits, CRO scoring, survey segmentation, lead magnet generation | `conversion-optimization` `cro-analysis` `lead-magnets` `landing-pages` |
| `course-author` | Write lesson content from a filled lesson spec — hook, explanation, worked example, code snippets, exercises, misconception callouts, formative check | `education` `course-content` `lesson-writing` `worked-examples` `code-snippets` `exercises` `teaching` |
| `course-design` | Turn a course brief into an outline: modules, lessons, learning objectives, sequencing, assessment map — backwards design from outcomes | `education` `curriculum-design` `learning-objectives` `backwards-design` `bloom` `sequencing` `cognitive-load` `assessment` |
| `course-shaper` | Interactive intake for course work: turns vague teaching ideas into a scoped brief (full course, single module, or workshop). Invoke as `/course-shape`. | `intake` `course-planning` `task-scoping` `briefing` `slash-command` `education` |
| `debugging-and-error-recovery` | Systematically diagnose and fix root causes instead of guessing | `debugging` `error-recovery` `troubleshooting` `triage` `root-cause-analysis` |
| `deck-generator` | AI-generated presentation slides in consistent visual styles | `presentation-design` `slide-generation` `visualization` `pitch-decks` |
| `deployment-pipelines` | Infrastructure-grade CI/CD: OIDC, supply-chain hardening, caching, deploy patterns | `cicd` `devops` `github-actions` `oidc` `release` `deploy` `caching` `pipeline-security` |
| `deprecation-and-migration` | Phased deprecation, migration strategy, and zombie code removal | `deprecation` `migration` `code-removal` `technical-debt` `system-lifecycle` |
| `documentation-and-adrs` | Record architectural decisions (ADRs), API docs, inline comments, changelogs | `documentation` `adr` `architecture-decision-record` `api-docs` `knowledge-management` |
| `documentation-writer` | Docs under `docs/`, Mermaid diagrams, incremental PR-scoped updates | `documentation` `technical-writing` `markdown` `mermaid` `docs-as-code` `pr-scoped` |
| `eval` | AI output evaluation: test scenarios, scoring, regression detection | `ai-evaluation` `quality-testing` `prompt-testing` `regression-detection` |
| `finance-ops` | CFO briefings from QuickBooks exports with scenario modeling | `financial-analysis` `burn-rate` `cost-estimation` `scenario-modeling` |
| `frontend-ui-engineering` | Production-quality UIs: components, state, accessibility, responsive design | `frontend` `ui-engineering` `accessibility` `react` `design-system` `responsive-design` |
| `game-balancer` | Number tuning for games: economy curves, progression rates, difficulty pacing, drop tables, currency velocities, simulation, live re-tunes | `game-design` `game-balance` `economy-design` `progression-curves` `difficulty-tuning` `drop-tables` `simulation` `playtest` `live-ops` |
| `game-concept-creator` | Generate, evaluate, and refine pitch-quality game concepts as one-pagers (logline, fantasy, hook, verbs, comp titles, payment rails, risks) | `game-design` `concept-pitch` `ideation` `mda` `fantasy-design` `payment-rails` `pitch` |
| `game-design-shaper` | Interactive intake for game design: turns vague game ideas into a scoped brief (full game, prototype, jam, live-game update). Always asks the payment-rails question. Invoke as `/game-shape`. | `intake` `game-design` `task-scoping` `briefing` `slash-command` `payment-rails` |
| `game-marketer` | Game-specific marketing: store-page conversion, trailers, soft-launch CPI / ROAS, communities, influencers, launch comms, live-ops cadence, web3 mint comms | `marketing` `game-marketing` `store-page` `trailer` `soft-launch` `cpi` `roas` `community` `influencer` `live-ops-comms` `web3-mint` |
| `game-monetization-strategist` | Pick and shape the monetization model (premium / F2P / sub / ads / hybrid / web3); set LTV / ARPDAU / ROAS targets, segment economics, KPI floors | `game-design` `monetization` `f2p` `premium` `subscription` `ads` `web3-monetization` `ltv` `arpdau` `roas` `soft-launch-kpis` `segment-economics` |
| `game-systems-designer` | Turn a locked concept into a design doc + system specs: MDA-driven core/meta loops, player verbs, content systems, level structure, narrative integration, onboarding, failure design | `game-design` `gdd` `system-design` `core-loop` `meta-loop` `mda` `player-verbs` `level-design` `narrative-integration` `onboarding` `failure-design` |
| `git-workflow-and-versioning` | Trunk-based development, atomic commits, branching strategy, worktrees | `git` `version-control` `workflow` `branching-strategy` `commit-discipline` `trunk-based-development` |
| `godot-engineer` | Godot 4 + C# game development: scenes, nodes, physics, animation, UI, save, performance, WebSocket multiplayer, exporting | `game-development` `godot` `godot4` `csharp` `dotnet` `game-engine` `2d` `3d` `physics` `animation` `tween` `shader` `gameplay` `multiplayer` `websocket` `gamedev` |
| `growth-engine` | Multivariate experiment framework with statistical analysis and auto-playbook | `experimentation` `a-b-testing` `growth-metrics` `statistical-analysis` |
| `iap-manager` | In-app purchase catalog and store ops: SKU design, price-tier ladder, bundles, starter packs, battle pass tiering, A/B price tests, store config (App Store / Google Play / Steam / web / web3), localization | `monetization` `iap` `pricing` `bundles` `starter-pack` `battle-pass` `price-testing` `store-config` `app-store` `google-play` `steam` `web3-iap` `price-localization` |
| `idea-refine` | Refine raw ideas through divergent ideation, convergent evaluation, structured output | `ideation` `product-thinking` `idea-validation` `design-thinking` `frameworks` |
| `incremental-implementation` | Implement features in thin vertical slices with testing at each increment | `implementation` `vertical-slices` `incremental-development` `scope-discipline` |
| `marketing-shaper` | Interactive intake for marketing work: turns vague requests into scoped briefs (campaign, content, optimization, research, or pipeline). Invoke as `/mshape`. | `intake` `marketing-planning` `task-scoping` `briefing` `slash-command` |
| `outbound-engine` | Cold email sequence design with expert panel optimization | `cold-email` `sales-sequences` `outbound-strategy` `icp-definition` |
| `performance-optimization` | Measurement-first performance: Core Web Vitals, profiling, anti-pattern fixes | `performance` `optimization` `web-vitals` `profiling` `monitoring` |
| `planning-and-task-breakdown` | Decompose work into small, ordered, verifiable, implementable tasks | `planning` `task-breakdown` `scope-estimation` `work-decomposition` `parallelization` |
| `podcast-ops` | Multi-platform content repurposing from podcast episodes | `content-repurposing` `podcast-clips` `social-distribution` `viral-scoring` |
| `prompt-shaper` | Interactive intake: turns vague requests into a structured task brief (multi-repo feature, single-repo change, investigation, or bugfix). Invoke as `/shape`. | `intake` `prompt-engineering` `task-scoping` `planning` `briefing` `slash-command` |
| `revenue-intelligence` | Sales call insight extraction and content-to-revenue attribution | `sales-analytics` `call-intelligence` `revenue-attribution` `client-reporting` |
| `sales-pipeline` | Lead scoring, suppression, campaign routing, and dead deal resurrection | `lead-automation` `pipeline-management` `intent-scoring` `deal-resurrection` |
| `sales-playbook` | Value-based pricing framework with pre-call briefings and pattern library | `pricing-strategy` `deal-structure` `sales-training` `value-pricing` |
| `security` | PII detection and sanitization for files and repositories; pre-commit hook | `data-protection` `compliance` `sanitization` `pii-detection` |
| `security-and-hardening` | Developer-focused web app security: OWASP Top 10 with code examples, input validation, auth | `security` `owasp` `input-validation` `authentication` `injection-prevention` `hardening` |
| `security-engineering` | Cross-stack security review: OWASP, ASVS, Web3, agentic AI, CI/CD supply chain | `security` `owasp` `asvs` `auth` `appsec` `infra-security` `web3-security` `agentic-ai-security` `code-review` |
| `seo-ops` | Keyword research, competitor gap analysis, GSC optimization, trend detection | `seo-intelligence` `keyword-research` `competitive-analysis` `gsc` |
| `shipping-and-launch` | Pre-launch checklists, feature flags, staged rollouts, rollback plans | `shipping` `deployment` `launch` `feature-flags` `rollout` `monitoring` `rollback` |
| `site-reliability-engineering` | SLOs/error budgets, alerting, on-call, incident response, postmortems, runbooks, toil reduction, chaos | `sre` `operate` `slo` `error-budget` `alerting` `on-call` `incident-response` `postmortem` `runbook` `chaos` `observability` |
| `skill-library-review` | Audit a library of Claude Code skills and agents — frontmatter, routing quality, tool allowlists, cross-reference health, single-responsibility, anti-patterns | `meta-skill` `library-review` `agent-design` `skill-design` `frontmatter` `routing` `tool-allowlist` `cross-references` |
| `software-design` | SOLID, cohesion/coupling, separation of concerns, hexagonal architecture, DDD, code review, refactoring | `code-quality` `code-review` `refactoring` `solid` `ddd` `hexagonal` `clean-architecture` `domain-modeling` `cohesion` `coupling` |
| `source-driven-development` | Verify implementation against official docs, cite sources, avoid outdated patterns | `documentation` `source-verification` `frameworks` `best-practices` `citation` |
| `spec-driven-development` | Establish clear specifications with acceptance criteria before coding | `specification` `requirements` `acceptance-criteria` `gated-workflow` `design-before-code` |
| `standards-enforcer` | Engineering standards enforcement at gates: kickoff, pre-merge, pre-release, post-release; security/quality/operational baselines; strategic alignment; exceptions and waivers | `enforcement` `review` `code-review` `pr-review` `compliance` `gate` `quality-gate` `security-baseline` `exceptions` `waivers` `dad-compliance` `adr-compliance` |
| `system-architect` | System design, distributed patterns, fault tolerance, observability, RFCs, capacity planning | `architecture` `system-design` `distributed-systems` `fault-tolerance` `observability` `capacity-planning` `caching-strategy` `rfc` `design-doc` |
| `team-lead` | Linear/Jira ticket policing, ADRs (deviations), DADs (defaults) | `leadership` `process` `tickets` `linear` `jira` `adr` `dad` `decisions` `grooming` `triage` |
| `team-ops` | Performance audits (Elon Algorithm), stack ranking, meeting intelligence | `team-analysis` `performance-evaluation` `meeting-extraction` `stack-ranking` |
| `technical-product-management` | Product strategy, prioritization, roadmaps, PRDs, stakeholder management, launches, metrics, saying no | `product` `tpm` `pm` `product-strategy` `prioritization` `roadmap` `prd` `okrs` `north-star-metric` `mvp` `stakeholders` `launch` `rollout` `discovery-to-delivery` `build-vs-buy` |
| `technical-strategist` | Technical strategy: diagnosis, guiding policy, actions, non-goals, kill criteria; load-bearing DADs; build/buy/adopt; platform-vs-product; tech bets; strategy evolution | `technical-strategy` `tech-strategy` `vision` `principles` `tech-bet` `build-vs-buy` `platform-investment` `load-bearing-dad` `north-star-architecture` `strategy-evolution` |
| `telemetry` | Shared opt-in usage logging and version-checking library for skills | `analytics` `privacy` `version-tracking` `usage-metrics` |
| `test-driven-development` | Red-green-refactor cycle, prove-it pattern for bugs, test pyramid guidance | `testing` `tdd` `unit-tests` `integration-tests` `e2e-tests` `red-green-refactor` |
| `typescript-analytics` | PostHog events, feature flags, client/server analytics in TypeScript | `analytics` `telemetry` `posthog` `feature-flags` `event-tracking` `error-tracking` `typescript` |
| `typescript-data-engineering` | PostgreSQL, BigQuery, ETL, event sourcing, message brokers, caching, in TypeScript | `data-engineering` `etl` `postgres` `bigquery` `prisma` `drizzle` `event-sourcing` `message-brokers` `rabbitmq` `kafka` `sqs` `bullmq` `caching` `redis` `typescript` |
| `typescript-quality-engineering` | Umbrella QE: cross-layer test policy, E2E (Playwright), contract tests, CI | `qa` `testing` `test-strategy` `e2e` `playwright` `test-pyramid` `coverage-policy` `typescript` |
| `typescript-testing-backend` | Jest unit + Supertest integration tests for TypeScript backends | `testing` `backend` `jest` `supertest` `unit-tests` `integration-tests` `typescript` |
| `typescript-testing-frontend` | Jest + RTL tests for React components and hooks | `testing` `frontend` `react` `jest` `react-testing-library` `chakra` `nextjs` `typescript` |
| `using-agent-skills` | Meta-skill: discovers and invokes the right workflow skill for any task | `meta-skill` `workflow` `skill-discovery` `process-framework` `agent-guidance` |
| `ux-design` | UX/UI design: IA, interaction, visual fundamentals, design systems, accessibility, UX writing, critique, handoff | `ux` `ui` `design` `interaction-design` `information-architecture` `design-systems` `accessibility` `wcag` `ux-writing` `figma` `design-critique` `handoff` |
| `ux-research` | User research: methods, discovery, interviews, usability testing, synthesis, personas/JTBD, ethics | `ux` `research` `discovery` `interviews` `usability-testing` `jtbd` `personas` `synthesis` `research-ethics` |
| `web3-smart-contract-engineering` | Solidity contracts with Hardhat + Foundry across EVM chains | `web3` `smart-contracts` `solidity` `hardhat` `foundry` `evm` `erc20` `erc721` `erc1155` `merkle` `signature-verification` `staking` |
| `x-longform-post` | Long-form X posts with founder voice and AI humanizer validation | `social-content` `thought-leadership` `viral-writing` `x-twitter` |
| `yt-competitive-analysis` | YouTube outlier detection and packaging pattern analysis | `video-analysis` `competitive-intelligence` `viral-patterns` `youtube` |

## Agents in this repo

Agents are focused roles the parent agent delegates work to. Each pulls relevant skills on demand and returns a single response.

| Agent | Scope | Tools |
|---|---|---|
| `engineer` | Full-stack implementation: architecture, frontend, backend, infra, SRE, perf, shipping, testing | inherit |
| `web3-engineer` | Solidity smart contracts on EVM | inherit |
| `godot-engineer` | Godot 4 + C# game development | inherit |
| `code-reviewer` | Multi-axis code review with verdict + severity-tagged findings (proactive) | read-only |
| `security-reviewer` | Cross-stack security audit: app, infra, contracts, agentic AI, CI/CD, PII (proactive) | read-only |
| `library-reviewer` | Audit of skill/agent library — frontmatter, routing, allowlists, cross-refs (proactive) | read-only |
| `prompt-shaper` | Engineering intake → scoped task brief (`/shape`) | intake-only |
| `marketing-shaper` | Marketing intake → scoped brief (`/mshape`) | intake-only |
| `course-shaper` | Education pipeline: intake → outline → lesson content (`/course-shape`) | authoring |
| `game-design-shaper` | Game design pipeline: intake → concept → design → balance → monetization → catalog → marketing (`/game-shape`) | authoring |
| `technical-pm` | Product strategy, tech strategy, leadership, ADRs, DADs, roadmaps | inherit |
| `marketer` | Content, growth, sales, SEO, outbound, pipeline, attribution | inherit |
| `ux-specialist` | UX design + research as one tightly-coupled practice | inherit |
| `ops-analyst` | Finance and team operations — CFO briefings, performance audits | inherit |

**Tool conventions**

- **inherit** — full tool access from the parent agent
- **read-only** — `Read, Grep, Glob, Bash, WebFetch, WebSearch` (no Edit/Write/NotebookEdit/Agent)
- **intake-only** — read-only set + `AskUserQuestion`, no Edit/Write/Agent
- **authoring** — read-only set + `AskUserQuestion, Edit, Write`, no Agent

**Skill vs agent.** Skills carry domain rules; agents are the roles that apply them. The same name often appears in both (e.g., `prompt-shaper`, `code-reviewer`) — the skill is *how* the work is done; the agent is *who* does it.

## Skill clusters

Each `SKILL.md` lists its own related skills; the high-level map:

- **Intake → execution**: `idea-refine` → `prompt-shaper` → `planning-and-task-breakdown` → `incremental-implementation`. Four sibling shapers (`prompt-shaper`, `marketing-shaper`, `course-shaper`, `game-design-shaper`) handle engineering, marketing, teaching, and game-design intake.
- **Engineering core**: `system-architect` ↔ `software-design` ↔ `api-and-interface-design` — service boundaries, module structure, external contracts.
- **Code quality**: `code-review-and-quality` ↔ `code-simplification` ↔ `software-design` — review surfaces simplification; clarity refactor before structural refactor.
- **Process discipline**: `spec-driven-development` ↔ `planning-and-task-breakdown` ↔ `test-driven-development` ↔ `incremental-implementation` — spec defines what; planning decomposes how; TDD proves each slice.
- **Ops & reliability**: `cloud-infrastructure` ↔ `deployment-pipelines` ↔ `site-reliability-engineering` — provision, deploy, operate. `shipping-and-launch` and `performance-optimization` feed SLOs.
- **Security stack** (load all three for defense in depth): `security-and-hardening` (developer-focused) + `security-engineering` (cross-stack specialist) + `security` (PII sanitization).
- **Governance**: `technical-strategist` writes constraints → `standards-enforcer` applies at gates → `team-lead` maintains DAD/ADR machinery → `technical-product-management` owns *what and why*.
- **UX**: `ux-research` produces evidence → `ux-design` consumes it; both pair with `frontend-ui-engineering` and `software-design` (vocabulary alignment).
- **Marketing/sales pipeline**: `marketing-shaper` → `content-ops` → `outbound-engine` → `sales-pipeline` → `revenue-intelligence`. `growth-engine` runs experiments across them.
- **Education**: `course-shaper` (intake) → `course-design` (outline) → `course-author` (lessons).
- **Game design pipeline**: `game-design-shaper` (intake, captures payment rails) → `game-concept-creator` (concept one-pager) → `game-systems-designer` (design doc + system specs) → `game-balancer` (number tuning) → `game-monetization-strategist` (model + KPI floors) → `iap-manager` (catalog + store config) → `game-marketer` (store pages, trailers, soft launch, comms). Engine implementation lives in `godot-engineer` (separate skill).
- **Testing layers**: `typescript-quality-engineering` (umbrella) defers to `typescript-testing-backend` / `typescript-testing-frontend` / `web3-smart-contract-engineering`.
- **Library meta**: `using-agent-skills` governs skill discovery; `skill-library-review` keeps the library healthy; `context-engineering` shapes how skills load.
- **Game dev (engine specialty)**: `godot-engineer` ↔ `software-design`, `ux-research`/`ux-design`, `security-engineering` (multiplayer), and ops skills (only when running game servers). The game-design pipeline above feeds into the engine.

## Using the shapers

Four intake skills convert vague requests into scoped briefs:

- `/shape` — engineering work (multi-repo feature, single-repo, investigation, bugfix)
- `/mshape` — marketing work (campaign, content, optimization, research, pipeline)
- `/course-shape` — teaching work (full course, module, workshop)
- `/game-shape` — game design work (full game, prototype, jam, live-game update; payment-rails decision captured in intake)

Each picks a template by the *shape* of work, asks one batched round of 3–6 questions via `AskUserQuestion`, outputs a filled brief in a fenced markdown block, and stops there. Say `go` to execute, or paste the brief into a fresh session.

**Workflow tips that pay off:**

- **Shape in one session, execute in another.** The shaping conversation accumulates baggage that confuses execution. Paste the brief into a fresh session as message 1.
- **Answer concretely, or admit unknown.** Don't guess — say "don't know yet" and the brief marks it `<unknown — to investigate>`.
- **Edit the brief before acting on it.** Treat it like a PR description; five seconds of edits now saves a wrong implementation later.
- **Don't pre-pick skills.** Naming skills suppresses better matches. Describe the *concern* in plain language; the right skills load themselves.
- **Honor the multi-repo approval gate.** Cross-repo edits are the most expensive to undo — let the executor pause for approval after the integrated plan.

**Skip the shaper when** the request is one file, one obvious change, with done criteria in one sentence. Shaping a trivial task is overhead.

**Worked examples** of every shaper × template combination live in [`examples/`](examples/) — one per template variant, showing the user's request, the shaper's batched questions, the answers, and the final brief.

## Frontmatter and authoring

Every `SKILL.md` and agent file starts with:

```yaml
---
name: lowercase-hyphenated-id          # must match directory/file name
description: Use when <situation>. Triggers on <globs/keywords>. For <related concern> see <other-skill>.
---
```

**Description rules:**

- Third person, written for the loader (not the human reader)
- States both **WHAT** the skill/agent does and **WHEN** to load it
- Portable globs (`**/*.test.tsx`), not project-specific paths
- Cross-references adjacent skills/agents so the loader can route correctly
- Under ~1024 characters

**Authoring rules:**

- Keep `SKILL.md` under ~100 lines: frontmatter, role/context, universal rules, references list. Long content goes in `references/`.
- Progressive disclosure — never inline a 200-line code example.
- No company-specific names in `SKILL.md`. Examples in `references/` may use realistic identifiers, framed as examples.
- Templates the agent fills out (ADRs, RFCs, briefs) go in `assets/`, not `references/`.
- Cross-reference related skills both ways.

For agent definitions, use the `library-reviewer` agent or load the `skill-library-review` skill — the rubric covers frontmatter, routing quality, tool allowlists, single-responsibility, and cross-reference health.

## Syncing into projects

Copy directories/files into each repo (rsync, Taskfile, submodule, etc.):

```text
<your-project>/.claude/skills/<skill-name>/
<your-project>/.claude/agents/<agent-name>.md
<your-project>/.cursor/skills/<skill-name>/
```

Commit synced skills/agents in application repos if the team should share the same agent behavior.

## Contributing

Add or edit skills/agents here, then redeploy to downstream repos. If a `SKILL.md` approaches ~100 lines, split content into `references/`. Run `library-reviewer` after edits to catch routing-quality regressions before merge.
