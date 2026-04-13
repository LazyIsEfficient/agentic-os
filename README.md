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
| `debugging-and-error-recovery` | Systematically diagnose and fix root causes instead of guessing | `debugging` `error-recovery` `troubleshooting` `triage` `root-cause-analysis` |
| `deck-generator` | AI-generated presentation slides in consistent visual styles | `presentation-design` `slide-generation` `visualization` `pitch-decks` |
| `deployment-pipelines` | Infrastructure-grade CI/CD: OIDC, supply-chain hardening, caching, deploy patterns | `cicd` `devops` `github-actions` `oidc` `release` `deploy` `caching` `pipeline-security` |
| `deprecation-and-migration` | Phased deprecation, migration strategy, and zombie code removal | `deprecation` `migration` `code-removal` `technical-debt` `system-lifecycle` |
| `documentation-and-adrs` | Record architectural decisions (ADRs), API docs, inline comments, changelogs | `documentation` `adr` `architecture-decision-record` `api-docs` `knowledge-management` |
| `documentation-writer` | Docs under `docs/`, Mermaid diagrams, incremental PR-scoped updates | `documentation` `technical-writing` `markdown` `mermaid` `docs-as-code` `pr-scoped` |
| `eval` | AI output evaluation: test scenarios, scoring, regression detection | `ai-evaluation` `quality-testing` `prompt-testing` `regression-detection` |
| `finance-ops` | CFO briefings from QuickBooks exports with scenario modeling | `financial-analysis` `burn-rate` `cost-estimation` `scenario-modeling` |
| `frontend-ui-engineering` | Production-quality UIs: components, state, accessibility, responsive design | `frontend` `ui-engineering` `accessibility` `react` `design-system` `responsive-design` |
| `git-workflow-and-versioning` | Trunk-based development, atomic commits, branching strategy, worktrees | `git` `version-control` `workflow` `branching-strategy` `commit-discipline` `trunk-based-development` |
| `godot-engineer` | Godot 4 + C# game development: scenes, nodes, physics, animation, UI, save, performance, WebSocket multiplayer, exporting | `game-development` `godot` `godot4` `csharp` `dotnet` `game-engine` `2d` `3d` `physics` `animation` `tween` `shader` `gameplay` `multiplayer` `websocket` `gamedev` |
| `growth-engine` | Multivariate experiment framework with statistical analysis and auto-playbook | `experimentation` `a-b-testing` `growth-metrics` `statistical-analysis` |
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
- `autoresearch` ↔ `content-ops` (autoresearch optimizes content; content-ops scores and iterates it via expert panels)
- `autoresearch` ↔ `growth-engine` (autoresearch generates variants; growth-engine runs the experiments)
- `content-ops` ↔ `outbound-engine` (content-ops scores copy quality; outbound-engine uses scores for cold email sequences)
- `content-ops` ↔ `eval` (content-ops scores human-facing content; eval scores AI system output)
- `conversion-ops` ↔ `content-ops` (CRO audits surface copy issues; content-ops iterates the fixes)
- `conversion-ops` ↔ `sales-pipeline` (conversion-ops optimizes landing pages that feed the sales pipeline)
- `growth-engine` ↔ `seo-ops` (SEO experiments are a subset of growth experiments)
- `outbound-engine` ↔ `sales-pipeline` (outbound sequences feed leads into the pipeline)
- `revenue-intelligence` ↔ `sales-pipeline` (revenue attribution closes the loop on pipeline performance)
- `revenue-intelligence` ↔ `sales-playbook` (call analysis feeds pricing pattern insights)
- `sales-pipeline` ↔ `sales-playbook` (pipeline automates lead flow; playbook handles deal pricing)
- `podcast-ops` ↔ `content-ops` ↔ `x-longform-post` (podcast content repurposed through content-ops scoring into long-form posts)
- `seo-ops` ↔ `yt-competitive-analysis` (SEO keyword research and YouTube packaging patterns inform each other)
- `security` ↔ `security-engineering` (PII sanitization tool vs. application security practices)
- `team-ops` ↔ `team-lead` (team-ops provides data-driven analysis; team-lead owns process and decisions)
- `team-ops` ↔ `finance-ops` (team performance data feeds financial team-cost analysis)
- `telemetry` is a shared library imported by all marketing/sales skills via their preamble blocks
- `deck-generator` ↔ `content-ops` (deck content quality can be scored by expert panels)
- `security-and-hardening` ↔ `security-engineering` (**layered**: developer-focused hardening vs cross-stack security specialist review; load both for defense in depth)
- `security-and-hardening` ↔ `code-review-and-quality` (security is one of five review axes)
- `ci-cd-and-automation` ↔ `deployment-pipelines` (**complementary**: developer quality gates vs infrastructure-grade pipeline hardening)
- `ci-cd-and-automation` ↔ `shipping-and-launch` (CI gates feed launch readiness; rollback strategies span both)
- `documentation-and-adrs` ↔ `documentation-writer` ↔ `team-lead` (decision capture, docs maintenance, and team governance — three distinct functions)
- `code-review-and-quality` ↔ `software-design` (review includes design axis; software-design goes deeper on structure)
- `code-simplification` ↔ `software-design` (clarity refactor first, then structural refactor — sequential)
- `code-simplification` ↔ `code-review-and-quality` (simplification opportunities surface during review)
- `idea-refine` → `prompt-shaper` → `planning-and-task-breakdown` → `incremental-implementation` (ideation → scoping → decomposition → execution pipeline)
- `idea-refine` → `marketing-shaper` (for marketing ideas, the brief flows to marketing-shaper instead of prompt-shaper)
- `spec-driven-development` ↔ `planning-and-task-breakdown` (spec defines *what*; planning decomposes *how*)
- `test-driven-development` ↔ `debugging-and-error-recovery` (TDD's prove-it pattern is the first step in debugging)
- `test-driven-development` ↔ `incremental-implementation` (each vertical slice gets tests before implementation)
- `browser-testing-with-devtools` ↔ `frontend-ui-engineering` (DevTools verifies what frontend-ui builds)
- `browser-testing-with-devtools` ↔ `test-driven-development` (browser testing is the E2E layer of the test pyramid)
- `frontend-ui-engineering` ↔ `ux-design` (**complementary roles**: design defines *what*; frontend implements *how*)
- `api-and-interface-design` ↔ `deprecation-and-migration` (API design includes versioning; deprecation manages the lifecycle)
- `api-and-interface-design` ↔ `software-design` (API boundaries are the external face of internal module structure)
- `source-driven-development` ↔ `debugging-and-error-recovery` (official docs are the first source of truth when diagnosing framework issues)
- `performance-optimization` ↔ `frontend-ui-engineering` (Core Web Vitals and re-render prevention)
- `performance-optimization` ↔ `site-reliability-engineering` (performance targets feed SLOs)
- `shipping-and-launch` ↔ `site-reliability-engineering` (launch readiness, monitoring, rollback)
- `git-workflow-and-versioning` ↔ `incremental-implementation` (atomic commits support vertical-slice delivery)
- `context-engineering` ↔ `using-agent-skills` (context setup determines which skills load and how effectively)
- `using-agent-skills` ↔ *all skills* (the meta-skill that governs skill discovery and invocation)
- `marketing-shaper` ↔ `prompt-shaper` (**siblings**: marketing-shaper scopes marketing work; prompt-shaper scopes engineering work)
- `marketing-shaper` → all marketing/sales skills (the shaper produces briefs that downstream marketing skills execute)

## Using `marketing-shaper`

`marketing-shaper` is the intake skill for marketing work — the marketing-specific sibling of `prompt-shaper`. Use it at the *start* of a session when you have a marketing goal but haven't fully scoped it.

**Invoke it two ways:**

- As a slash command: `/mshape <your rough description>`
- By describing your intent in natural language — phrases like "plan this campaign", "scope this content", "marketing plan", "growth plan", "outbound plan" trigger it automatically.

**What it does:**

1. Picks a template based on the kind of marketing work — campaign, content, optimization, research, or pipeline.
2. Asks **one batched round** of 3–6 focused questions (via `AskUserQuestion`) to fill the gaps.
3. Outputs a filled marketing brief in a fenced markdown block, ready to copy into a fresh session.
4. **Stops there.** Say `go` to execute immediately, or paste the brief into a clean session.

**The five work types:**

| Type | Use when... | Key sections |
|---|---|---|
| **Campaign** | Multi-channel initiative (3+ surfaces) | Channels, content calendar, attribution |
| **Content** | Single deliverable (post, deck, sequence) | Format, voice, source material |
| **Optimization** | Improving existing assets (CRO, A/B) | Current metrics, variants, experiment design |
| **Research** | Answering a question, no deliverables | One question, decision it unblocks |
| **Pipeline** | Building or tuning sales motion | Tools, ICP, bottleneck, compliance |

**Skip it when** the request is already well-scoped (specific deliverable, clear audience, known metric). Going straight to the work is faster.

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
