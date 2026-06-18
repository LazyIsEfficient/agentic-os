# Engineering Heresy — Agentic Framework

A collection of skills and agents for [Claude Code](https://claude.ai/code) that encode engineering workflows, content pipelines, game development, marketing ops, and more into reusable AI playbooks.

Install once, use in any project.

> Part of **[Engineering Heresy](https://geggleto.substack.com/)** by Glenn Eggleton — challenging conventional wisdom in AI and software engineering. **[Subscribe on Substack →](https://geggleto.substack.com/)**

---

## Install

The one-liners install a **pinned release** and verify its SHA-256 before
extracting anything — see [Verifying the download](#verifying-the-download).

- **Current release:** `v1.3.0`
- **Asset:** `agentic-os-v1.3.0.tar.gz`
- **SHA-256:** `4451a0fccec8acde3be743d55e7ae464532b5b81e1ffc50a881ba8f70088fb49`

### macOS / Linux

**One-liner (no clone required):**

```bash
curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v1.3.0/install.sh | bash
```

**Or from a local clone:**

```bash
git clone https://github.com/LazyIsEfficient/agentic-os.git
cd agentic-os
./install.sh
```

Files are copied to `~/.claude/skills/`, `~/.claude/agents/`, and `~/.claude/commands/`. Existing files are not overwritten by default. Add `--force` to update everything.

### Windows (PowerShell)

**One-liner (no clone required):**

```powershell
irm https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v1.3.0/install.ps1 | iex
```

**Or from a local clone:**

```powershell
git clone https://github.com/LazyIsEfficient/agentic-os.git
cd agentic-os
.\install.ps1
```

Files are copied to `%USERPROFILE%\.claude\skills\`, `%USERPROFILE%\.claude\agents\`, and `%USERPROFILE%\.claude\commands\`. Add `-Force` to overwrite existing files. (The remote install uses `tar`, which ships with Windows 10 1803+.)

### Verifying the download

The remote install path downloads the pinned release asset and aborts if its
SHA-256 does not match the digest embedded in the installer. To verify
out-of-band before trusting the one-liner, download the asset and check it
yourself:

```bash
curl -fsSLO https://github.com/LazyIsEfficient/agentic-os/releases/download/v1.3.0/agentic-os-v1.3.0.tar.gz
# macOS / BSD:
echo "4451a0fccec8acde3be743d55e7ae464532b5b81e1ffc50a881ba8f70088fb49  agentic-os-v1.3.0.tar.gz" | shasum -a 256 -c
# Linux (coreutils):
echo "4451a0fccec8acde3be743d55e7ae464532b5b81e1ffc50a881ba8f70088fb49  agentic-os-v1.3.0.tar.gz" | sha256sum -c
```

There is intentionally no "track `main`" remote install path — to install
unreleased changes, clone the repo and run `./install.sh` from the clone.
Maintainers: see [RELEASING.md](RELEASING.md) for how the pin is produced.

### Custom install path

```bash
CLAUDE_DIR=/path/to/.claude ./install.sh
```

```powershell
.\install.ps1 -Dest "C:\path\to\.claude"
```

---

## What gets installed

| Directory | Contents |
|---|---|
| `~/.claude/skills/` | Skill playbooks — invoked with the `Skill` tool or `/skill-name` |
| `~/.claude/agents/` | Subagent definitions — spawned with the `Agent` tool |
| `~/.claude/commands/` | Slash commands — `/skill-new` and `/agent-new` scaffold a new conforming skill or agent; `/route` recommends the owning skill/agent for a task |
| `~/.claude/hooks/` | PreToolUse hooks (e.g. `block-bad-bash.sh`) |

> **Ship vs. in-repo-only.** The installer copies a curated allowlist, not whole directories. Only the author-facing commands (`skill-new`, `agent-new`, `route`) install into your global namespace. Maintainer-only tooling that lives in this repo — the `audit-library` / `review-gate` / `plan-clean` commands and the `workflows/` (sharded library audit, routing-collision sweep) — is **not** installed, to avoid polluting your command namespace.

---

## Usage

### Invoking a skill

In any Claude Code conversation, reference a skill by name:

```
Use the test-driven-development skill to write tests for this module.
```

Or use a slash command if configured:

```
/test-driven-development
```

Agents are spawned automatically when Claude Code routes a task (e.g. `engineer`, `code-reviewer`), or you can request one explicitly:

```
Use the security-reviewer agent to audit this PR.
```

### Multi-agent collaboration pod (`/v2-collab`)

Run a small **pod of agents that collaborate over several rounds** on one
deliverable: a PM frames the work, an engineer builds it, and a reviewer critiques
each round until it is approved (or a round cap is hit). Unlike a single agent or a
one-shot fan-out, the pod iterates — each round sees the previous round's artifact
and the reviewer's notes. It runs **entirely in your session** as a Workflow (no
extra services, no API keys); the produced files are written to a path you name (or
`./v2-out/`), never into your live library.

Example prompt that triggers it:

```
/v2-collab Build a single-page marketing site for an AI healthcare startup whose
service ingests your health data, has licensed nurses and doctors analyze it, and
returns personalized recommendations. Write it to pocs/sample.
```

The roster is configurable; by default it is `technical-pm → engineer →
code-reviewer`, and the **last role is the approval gate** — the run ends the moment
that reviewer approves. Pass a lower round cap for a cheaper first run.

### Skills vs Agents

**Skills** are instruction playbooks — they tell Claude *how* to do a specific type of work (TDD, debugging, API design). They are stateless and composable.

**Agents** are role definitions — they give Claude a persona, a tool allowlist, and a mandate (e.g. a full-stack engineer, a security auditor). Agents can invoke skills.

### Configure ~/.claude/CLAUDE.md

Skills are available to Claude, but Claude won't automatically reach for them unless instructed to. Add the following to `~/.claude/CLAUDE.md` to make Claude check for a relevant skill before responding to any task:

```markdown
## Skills

You have a library of skills installed at `~/.claude/skills/`. Before responding to any task,
check whether a skill applies and invoke it with the `Skill` tool if so — even if the task
seems simple. Use `using-agent-skills` to discover which skill fits when unsure.

If there is even a 1% chance a skill might apply, invoke it first.
```

This is the single most impactful configuration step — without it, Claude treats skills as
opt-in rather than default.

---

## Skills

| Skill | Description |
|---|---|
| `adversarial-claims-reviewer` | Adversarially verify formal/technical claims — math, stats, benchmarks |
| `api-and-interface-design` | Design stable APIs and interfaces that are hard to misuse |
| `autoresearch` | Run Karpathy-style autoresearch optimization on any content |
| `blog-post-author` | Draft a blog post from a filled blog-post-shaper brief |
| `blog-post-shaper` | Structure a vague blog idea into a well-scoped brief |
| `browser-testing-with-devtools` | Test in real browsers using Chrome DevTools |
| `ci-cd-and-automation` | Automate CI/CD pipeline setup and quality gates |
| `cloud-infrastructure` | Provision or modify cloud resources with infrastructure-as-code |
| `code-review-and-quality` | Multi-axis code review before merging changes |
| `code-simplification` | Simplify code for clarity without changing behavior |
| `codebase-cost-estimator` | Estimate build/dev cost of a codebase by measured LOC and complexity |
| `content-ops` | Score and evaluate content using an auto-assembled expert panel |
| `content-pipeline` | Content-production pipeline — quote mining, clip discovery, repurposing, batch gating |
| `context-engineering` | Optimize agent context setup for quality |
| `conversion-ops` | AI-powered conversion rate optimization and lead magnet generation |
| `course-author` | Write lesson content from a filled lesson spec |
| `course-design` | Turn a course brief into a concrete outline |
| `course-shaper` | Structure a vague course idea into a well-scoped brief |
| `debugging-and-error-recovery` | Systematic root-cause debugging workflow |
| `deck-generator` | Generate professional presentations with AI-generated images |
| `deployment-pipelines` | Author or review CI/CD pipelines and deployment workflows |
| `deprecation-and-migration` | Manage deprecation and migration of old systems |
| `devops-engineer` | Platform and DevOps engineering for Kubernetes, Helm, Pulumi IaC, and CI/CD mechanics |
| `documentation-and-adrs` | Record decisions and documentation as ADRs |
| `documentation-writer` | Keep repository documentation accurate and in sync |
| `elevenlabs-tts` | Convert text to speech using ElevenLabs |
| `finance-ops` | AI-powered financial analysis and CFO briefings |
| `findings-ledger` | Record and triage stochastic (Tier 2) review findings for recurrence |
| `frontend-ui-engineering` | Build production-quality UIs and components |
| `game-balancer` | Tune game economy curves, progression, and balance |
| `game-concept-creator` | Generate, evaluate, and refine pitch-quality game concepts |
| `game-design-shaper` | Structure a vague game idea into a well-scoped brief |
| `game-marketer` | Market a game via store pages, trailers, and communities |
| `game-monetization-strategist` | Pick and shape the monetization model for a game |
| `game-systems-designer` | Design game systems from a locked concept |
| `git-workflow-and-versioning` | Structure git workflow practices and version control |
| `godot-engineer` | Build games in Godot 4 with C# |
| `growth-engine` | Autonomous growth experimentation framework with analysis |
| `iap-manager` | Design and operate the in-app purchase catalog |
| `idea-refine` | Refine ideas iteratively through divergent thinking |
| `incremental-implementation` | Deliver changes incrementally in vertical slices |
| `marketing-shaper` | Structure a vague marketing request into a scoped brief |
| `meeting-intelligence` | Extract action items, decisions, and follow-ups from meeting transcripts |
| `outbound-engine` | Design and optimize cold outbound email campaigns |
| `performance-optimization` | Optimize application performance with measurement |
| `phaser-engineer` | Build games in Phaser 3 with TypeScript |
| `planning-and-task-breakdown` | Break work into ordered, parallel-dispatchable tasks |
| `podcast-ops` | Podcast-to-everything content pipeline and repurposing |
| `prompt-shaper` | Structure a vague engineering request into a task brief |
| `release-manager` | Coordinate release preparation across a monorepo |
| `revenue-intelligence` | AI-powered revenue intelligence and attribution |
| `rust-engineer` | Write, review, or architect Rust code |
| `security` | Scan and redact PII and sensitive data |
| `security-and-hardening` | Harden code against vulnerabilities and threats |
| `security-engineering` | Cross-stack security review covering all attack surfaces |
| `seo-ops` | AI-powered SEO operations and keyword intelligence |
| `shipping-and-launch` | Prepare production launches with checklists |
| `site-reliability-engineering` | Operate production systems with SLOs and runbooks |
| `skill-library-review` | Audit a library of skills and agents |
| `social-growth` | Write LinkedIn and X promo posts for content |
| `software-design` | Shape the internal structure of code |
| `source-driven-development` | Ground every implementation in official documentation |
| `spec-driven-development` | Create specs before writing code |
| `standards-enforcer` | Review work against agreed engineering standards |
| `system-architect` | Design new systems and evaluate architectural trade-offs |
| `team-lead` | Police work tickets and capture architectural decisions |
| `team-ops` | AI-powered team performance analysis and intelligence |
| `technical-product-management` | Make product decisions in a technical context |
| `technical-strategist` | Set technical direction for an engineering organization |
| `telemetry` | Opt-in, local-first, privacy-respecting usage telemetry |
| `test-driven-development` | Drive development with tests first |
| `typescript-analytics` | Implement analytics with PostHog in TypeScript |
| `typescript-data-engineering` | Build data pipelines, ETL jobs, and event processors |
| `typescript-quality-engineering` | Establish cross-cutting test strategy for TypeScript |
| `typescript-testing-backend` | Write backend tests with Jest and Supertest |
| `typescript-testing-frontend` | Write frontend tests with Jest and React Testing Library |
| `using-agent-skills` | Discover and invoke agent skills |
| `ux-design` | Design or review user interfaces and interactions |
| `ux-research` | Plan and run user research methods |
| `web3-smart-contract-engineering` | Write and review Solidity smart contracts |
| `x-longform-post` | Write long-form X posts in founder voice |
| `yt-competitive-analysis` | Analyze YouTube channels for outlier videos |
| `yt-shorts-pipeline` | End-to-end YouTube Shorts production pipeline |
| `yt-shorts-script` | Generate a YouTube Shorts script from a topic |

---

## Agents

| Agent | Description |
|---|---|
| `adversarial-claims-reviewer` | Read-only, cold-context adversarial review of formal/technical claims |
| `bigquery-ai-agent` | Expert data analyst for BigQuery — SQL generation, data interpretation, and insight delivery |
| `blog-post-shaper` | Blog pipeline — intake, draft, emit asset tasks, and fan out |
| `code-reviewer` | Read-only multi-axis code review |
| `course-shaper` | Education pipeline — intake, design, and author lessons |
| `devops-engineer` | Platform and DevOps engineering for Kubernetes, Helm, Pulumi IaC, and CI/CD mechanics |
| `engineer` | Full-stack implementation across architecture and shipping |
| `game-design-shaper` | Game design pipeline — intake through marketing end-to-end |
| `godot-engineer` | Godot 4 + C# game development |
| `library-reviewer` | Read-only audit of a skill and agent library |
| `marketer` | Full-spectrum marketing, content, and sales execution |
| `marketing-shaper` | Marketing intake — turn a vague goal into a scoped brief |
| `ops-analyst` | Finance and team operations analyst |
| `phaser-engineer` | Phaser 3 + TypeScript web game development |
| `prompt-shaper` | Engineering intake — turn a vague request into a task brief |
| `rust-engineer` | Principal-level Rust engineering — async services, APIs, workspaces |
| `security-reviewer` | Read-only cross-stack security audit |
| `technical-pm` | Product strategy, technical strategy, and engineering leadership |
| `ux-specialist` | UX design and research |
| `web3-engineer` | Solidity smart contract development on EVM chains |

---

## Commands

Slash commands in `.claude/commands/`. Only `agent-new`, `route`, and `skill-new` ship to consumers; the rest are repo-local maintainer tools.

| Command | Description |
|---|---|
| `agent-new` | Scaffold a new conforming agent definition |
| `audit-library` | Launch the sharded, adversarially-verified skill-library audit |
| `plan-clean` | Find completed plans in `.claude/plans/` and delete them after confirmation |
| `review-gate` | Run the mandatory build + review pairing gate on the current diff |
| `route` | Recommend the owning skill/agent for a task |
| `skill-new` | Scaffold a new conforming skill |
| `triage-findings` | Tally the findings ledger and propose ratchet targets (human disposes) |
| `v2-collab` | Run an in-session multi-agent collaboration pod (PM → engineer → reviewer) over rounds on one task |

---

## Repository layout

```
.claude/
├── skills/<skill-name>/
│   ├── SKILL.md          # frontmatter + rules (target <100 lines)
│   ├── references/       # deep-dive docs loaded on demand
│   ├── assets/           # fill-in templates (ADRs, RFCs, briefs)
│   └── scripts/          # runnable helpers
├── agents/<agent-name>.md
├── commands/<command>.md # slash commands (author-facing + maintainer-only)
├── hooks/                # PreToolUse hooks (e.g. block-bad-bash.sh)
├── rules/                # operating doctrine, @-imported by CLAUDE.md
└── workflows/            # multi-agent orchestration scripts
```

> Only a curated allowlist ships to consumers (see [What gets installed](#what-gets-installed)); `CLAUDE.md` and `rules/` are repo-local and are never installed.

---

## Contributing

Pull requests welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for conventions and review gates. The short version: scaffold with `/skill-new` or `/agent-new`, run the `library-reviewer` agent on your diff, and make sure `bash scripts/validate.sh` passes.

---

## Validating the library

A deterministic, LLM-free validator checks structural invariants — frontmatter completeness, kebab-case names matching their file/dir, no dangling links or `@`-imports, `MEMORY.md` length, review-tier wiring (and findings-ledger shape, if present), and that the install scripts ship exactly the curated allowlist.

Enable the pre-commit hook once per clone so the validator runs before every commit:

```sh
git config core.hooksPath .githooks
```

Run it manually any time:

```sh
bash scripts/validate.sh
```

CI enforces the same check on every pull request and push to `main`, and `install.sh` runs it before copying anything — a library that fails validation will not install.

---

## License

MIT
