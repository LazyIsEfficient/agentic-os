# Engineering Heresy — Agentic Framework

A collection of skills and agents for [Claude Code](https://claude.ai/code) that encode engineering workflows, content pipelines, game development, marketing ops, and more into reusable AI playbooks.

Install once, use in any project.

> Part of **[Engineering Heresy](https://geggleto.substack.com/)** by Glenn Eggleton — challenging conventional wisdom in AI and software engineering. **[Subscribe on Substack →](https://geggleto.substack.com/)**

---

## Features

AgenticOS (this repository) is a **curated library of AI playbooks** for serious, long-running work in software engineering, game development, marketing, and operations. You install it once into Claude Code; from then on, your agent can follow proven workflows instead of improvising every task from scratch.

The product is not "more agents for the sake of agents." It is a **harness** — structure, guardrails, and reusable expertise wrapped around frontier models so you get **predictable quality at lower token cost**, especially across multi-step sessions where context compression would otherwise cause drift and rework. See [NORTH_STAR.md](NORTH_STAR.md) for the design thesis.

### What you get

| Piece | What it is | How you use it |
|---|---|---|
| **Skills** (38) | Step-by-step playbooks for a kind of work — code review, Rust engineering, SEO ops, game balancing, etc. | Ask the agent to use a skill by name, or configure your IDE so skills are checked before every task (see [Usage](#usage)). |
| **Agents** (16) | Role definitions with a mandate and tool allowlist — engineer, security-reviewer, marketer, rust-engineer, etc. | Spawn explicitly ("use the code-reviewer agent") or let the orchestrator dispatch subagents for multi-step work. |
| **Commands** (3 ship to consumers) | Slash shortcuts — scaffold new skills/agents, record session facts. | `/skill-new`, `/agent-new`, `/state`. |
| **Hooks** | Small shell scripts that run on IDE events (session start, before shell, before compaction). | Installed and registered automatically; power the [awareness harness](#awareness-harness-experimental). Disable by editing your global hook config. |
| **Operating rules** | Always-on doctrine for orchestration, memory, grounding, and review tiers. | Clone this repo into a project to use the flat `CLAUDE.md` (generated from `.claude/rules/` by `scripts/build-claude-md.sh`). Not copied by the global installer. |

### Supported platform

- **[Claude Code](https://claude.ai/code)** — full install: skills, agents, hooks, and three consumer commands. Remote one-liner installs a **pinned, SHA-256–verified release** (`install.sh` / `install.ps1`).

### Workflow domains

Skills and agents are grouped by the work they cover. Invoke the one that matches your task; shaper skills (`prompt-shaper`, `marketing-shaper`, `game-design-shaper`) turn vague requests into scoped briefs first.

**Software engineering**

- Full-stack implementation (`engineer`, `devops-engineer`)
- Language specialists: Rust (`rust-engineer`), TypeScript testing (frontend/backend), data pipelines and analytics
- Smart contracts and EVM development (`web3-engineer`, `web3-smart-contract-engineering`)
- CI/CD and deployment pipelines
- Planning and task breakdown for parallel subagent dispatch
- Release coordination across a monorepo
- Codebase cost estimation (LOC/complexity → build cost)

**Quality, security, and review**

- Multi-axis code review (`code-reviewer`, `code-review-and-quality`)
- Cross-stack security audit (`security-reviewer`, `security-engineering`)
- PII scan and redaction (`security`)
- Adversarial review of formal claims — math, stats, benchmarks (`adversarial-claims-reviewer`)
- API/persistence cataloging into `DATA_MODEL.md` (`data-model-documenter`, `data-model-documentation`) with adversarial verification (`data-model-verifier`)

**Game development**

- Godot 4 + C# (`godot-engineer`)
- Phaser 3 + TypeScript (`phaser-engineer`)
- Systems design, economy balancing, IAP catalog design (`game-systems-designer`, `game-balancer`, `iap-manager`)
- End-to-end game design pipeline (`game-design-shaper`)

**Marketing, growth, and revenue**

- Marketing intake and full-spectrum execution (`marketing-shaper`, `marketer`)
- Content scoring with an expert panel (`content-ops`)
- Content production pipeline — quotes, clips, repurposing (`content-pipeline`)
- SEO, CRO, growth experiments, cold outbound, revenue attribution (`seo-ops`, `conversion-ops`, `growth-engine`, `outbound-engine`, `revenue-intelligence`)
- Karpathy-style autoresearch on conversion content (`autoresearch`)

**Browser and tooling**

- Real-browser testing via Chrome DevTools MCP (`browser-testing-with-devtools`)

**Library maintenance** (for contributors and fork maintainers)

- Scaffold conforming skills and agents (`/skill-new`, `/agent-new`)
- Structural audit of the library (`library-reviewer`, `library-investigator`, `skill-library-review`)
- Sharded full-library audit workflow (`/audit-library` — repo-local)
- Stochastic finding triage and ratchet promotion (`findings-ledger`, `/triage-findings`)

### Harness capabilities

These are features of the **framework itself**, not individual skills:

**Awareness harness (experimental)** — Fights the dominant failure mode of long agent sessions: losing track of settled decisions and existing infrastructure. Externalizes live session state in `SESSION-STATE.md`, re-injects it via hooks at session start and each turn, checkpoints before compaction, and nudges "survey before you provision." Includes deterministic metrics to compare hook-ON vs hook-OFF sessions.

**Orchestrator + ship gates** — Operating doctrine treats the main agent as an orchestrator that dispatches specialists (the `Agent` tool) instead of doing multi-step work inline. After implementation, a fixed review DAG runs: code review, security review, optional library review, and conditional data-model documentation/verification. PR checkboxes and CI (`check-pr-ship-gates`) enforce the gate. Canonical graph: [gate-dag.md](.claude/references/gate-dag.md).

**Review tiers** — Findings are sorted by reproducibility: Tier 0 deterministic checks hard-block; Tier 1 LLM findings need an evidence artifact; Tier 2 is advisory and logged to the findings ledger for recurrence-based promotion into deterministic checks.

**Persistent memory** — Two layers: within-session facts in `SESSION-STATE.md` (hook-driven, gitignored); cross-session personal/project memory in `.claude/memory/` (gitignored, in-repo when you clone). Never hand-edit session state — use `/state` or the `session-state` writer script.

**Deterministic validation** — `scripts/validate.sh` is an LLM-free gate on every PR: frontmatter, naming, dangling links, ship manifest, hook safety, tombstones for removed skills, and more. Install scripts refuse to copy a library that fails validation. Enable `.githooks` pre-commit for local enforcement.

**Pinned, verified releases** — Remote installs download a tagged tarball and abort on SHA-256 mismatch. No "track main" remote path — unreleased work installs from a local clone. Maintainer runbook: [RELEASING.md](RELEASING.md).

**Telemetry (opt-in)** — Local-first usage telemetry skill; privacy-respecting, not shipped as silent analytics.

**Security model for hooks** — Shipped hook scripts are auditable shell, no runtime network, human-reviewed before merge, and scanned by validator Invariant 8. Injected session files are treated as untrusted data. Details: [SECURITY.md](SECURITY.md).

### How to get started

1. **Install** — see the [Claude Code](#claude-code) section below.
2. **Configure skill discipline** — add the Skills block from [Usage](#usage) to `~/.claude/CLAUDE.md` so agents reach for skills by default.
3. **Initialize session state** (optional but recommended for long sessions) — `/state init`.
4. **Pick a workflow** — e.g. "Use `prompt-shaper` to scope this feature, then dispatch `engineer` to implement."
5. **Contributing?** — scaffold with `/skill-new` or `/agent-new`, run `library-reviewer` on your diff, ensure `bash scripts/validate.sh` passes. See [CONTRIBUTING.md](CONTRIBUTING.md).

### Maintainer-only (not installed globally)

Cloned-repo tooling for library authors: `/audit-library`, `/review-gate`, `/eval-harness`, `/triage-findings`, `workflows/`, `eval/` comparative harness, `scripts/release.sh`, and full CI workflow in `.github/workflows/`. Consumers get the skills, agents, hooks, and three commands only.

---

## Install

Install skills, agents, hooks, and three consumer commands into `~/.claude/`. The remote one-liner installs a **pinned release** and verifies its SHA-256 before extracting anything — see [Verifying the download](#verifying-the-download).

- **Current release:** `v2.6.0`
- **Asset:** `agentic-os-v2.6.0.tar.gz`
- **SHA-256:** `9edd168cd78b40314131b59785e7ae76888beea575296a1ff4b7c4dd086798a6`

**Persistent memory:** `.claude/memory/` is gitignored (machine-local). `validate.sh` scans it when present on your machine — fix dangling wikilinks locally; CI does not see memory files.

### Claude Code

#### macOS / Linux

**One-liner (no clone required):**

```bash
curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.6.0/install.sh | bash
```

**Or from a local clone:**

```bash
git clone https://github.com/LazyIsEfficient/agentic-os.git
cd agentic-os
./install.sh
```

Files are copied to `~/.claude/skills/`, `~/.claude/agents/`, and `~/.claude/commands/`. Existing files are not overwritten by default. Add `--force` to update everything.

#### Windows (PowerShell)

**One-liner (no clone required):**

```powershell
irm https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.6.0/install.ps1 | iex
```

**Or from a local clone:**

```powershell
git clone https://github.com/LazyIsEfficient/agentic-os.git
cd agentic-os
.\install.ps1
```

Files are copied to `%USERPROFILE%\.claude\skills\`, `%USERPROFILE%\.claude\agents\`, and `%USERPROFILE%\.claude\commands\`. Add `-Force` to overwrite existing files. (The remote install uses `tar`, which ships with Windows 10 1803+.)

#### Verifying the download

The remote install path downloads the pinned release asset and aborts if its
SHA-256 does not match the digest embedded in the installer. To verify
out-of-band before trusting the one-liner, download the asset and check it
yourself:

```bash
curl -fsSLO https://github.com/LazyIsEfficient/agentic-os/releases/download/v2.6.0/agentic-os-v2.6.0.tar.gz
# macOS / BSD:
echo "9edd168cd78b40314131b59785e7ae76888beea575296a1ff4b7c4dd086798a6  agentic-os-v2.6.0.tar.gz" | shasum -a 256 -c
# Linux (coreutils):
echo "9edd168cd78b40314131b59785e7ae76888beea575296a1ff4b7c4dd086798a6  agentic-os-v2.6.0.tar.gz" | sha256sum -c
```

There is intentionally no "track `main`" remote install path — to install
unreleased changes, clone the repo and run `./install.sh` from the clone.
Maintainers: see [RELEASING.md](RELEASING.md) for how the pin is produced.

#### Custom install path

Hook registration paths are rewritten to match `CLAUDE_DIR` / `-Dest` at install. The macOS/Linux installer uses `jq` for this; the Windows installer does it natively in PowerShell (no `jq` needed).

```bash
CLAUDE_DIR=/path/to/.claude ./install.sh
```

```powershell
.\install.ps1 -Dest "C:\path\to\.claude"
```

---

## What gets installed

### Claude Code (`install.sh`)

| Directory | Contents |
|---|---|
| `~/.claude/skills/` | Skill playbooks — invoked with the `Skill` tool or `/skill-name` |
| `~/.claude/agents/` | Subagent definitions — spawned with the `Agent` tool |
| `~/.claude/commands/` | Slash commands — `/skill-new` and `/agent-new` scaffold a new conforming skill or agent; `/state` records a durable session fact via the awareness-harness writer |
| `~/.claude/hooks/` | Hook scripts — registered globally in `~/.claude/settings.json` on install (awareness harness + `block-bad-bash`) — see [Awareness harness](#awareness-harness-experimental) |

> **Ship vs. in-repo-only.** The installer copies the full `skills/`, `agents/`, and `hooks/` directories; only **commands** are file-allowlisted (`skill-new`, `agent-new`, `state`). Maintainer-only tooling that lives in this repo — the `audit-library` / `review-gate` / `triage-findings` / `eval-harness` commands and the `workflows/` (the sharded library audit) — is **not** installed, to avoid polluting your command namespace.

---

## Usage

### Invoking a skill

In any Claude Code conversation, reference a skill by name:

```
Use the code-review-and-quality skill to review this diff before merge.
```

Or use a slash command if configured:

```
/rust-engineer
```

Agents are spawned automatically when Claude Code routes a task (e.g. `engineer`, `code-reviewer`), or you can request one explicitly:

```
Use the security-reviewer agent to audit this PR.
```

### Skills vs Agents

**Skills** are instruction playbooks — they tell Claude *how* to do a specific type of work (code review, Rust engineering, smart-contract development). They are stateless and composable.

**Agents** are role definitions — they give Claude a persona, a tool allowlist, and a mandate (e.g. a full-stack engineer, a security auditor). Agents can invoke skills.

### Awareness harness (experimental)

An in-development capability ([NORTH_STAR.md](NORTH_STAR.md)) that fights the dominant failure mode of long agent sessions: **awareness drift** — finite context compresses, so settled facts get re-derived and existing infrastructure gets rebuilt. It externalizes state and re-surfaces it deterministically via IDE hooks:

- **`SESSION-STATE.md`** — a live, gitignored constraints/decisions/infra/threads doc. Hooks inject it at session start, inject a compact digest each turn, and checkpoint before compaction. Maintained only through the deterministic writer (`/state`), never hand-edited.
- **survey-before-act** — on a service-provisioning command, reminds you to check whether it already exists first (warn-first; logs for measurement, does not block).
- **block-bad-bash** — nudges away from `cd && git` and long `&&` shell chains (ergonomics, not security; can block routine agent shell — remove the hook entry if annoying).
- **`eval/metrics/`** — deterministic instruments (`session-metrics.mjs`, `compare.mjs`) that measure tokens-per-outcome and awareness signals, ON (hooks) vs OFF (baseline).

**Ship posture:** hooks are **on by default** after install — `install.sh` merges hook registration into `~/.claude/settings.json`. Re-install **replaces the whole `hooks` block**. Remove the `hooks` key to disable.

**→ [Activation guide](docs/awareness-harness-activation.md)** — what gets registered, how to verify it fired, and how to turn hooks off.

Treat any hook-injected file as untrusted data — see [SECURITY.md](SECURITY.md).

### Configure ~/.claude/CLAUDE.md

Skills are available to Claude, but Claude won't automatically reach for them unless instructed to. Add the following to `~/.claude/CLAUDE.md` to make Claude check for a relevant skill before responding to any task:

```markdown
## Skills

You have a library of skills installed at `~/.claude/skills/`. Before responding to any task,
check whether a skill applies and invoke it with the `Skill` tool if so — even if the task
seems simple.

If there is even a 1% chance a skill might apply, invoke it first.
```

This is the single most impactful configuration step — without it, Claude treats skills as
opt-in rather than default.

---

## Skills

| Skill | Description |
|---|---|
| `adversarial-claims-reviewer` | Adversarially review formal/technical claims — math, stats, benchmarks, whitepapers |
| `autoresearch` | Run Karpathy-style autoresearch optimization on any conversion content |
| `browser-testing-with-devtools` | Test in real browsers via Chrome DevTools MCP |
| `code-review-and-quality` | Multi-axis code review across correctness, design, security, performance |
| `codebase-cost-estimator` | Estimate build/dev cost of a codebase by measured LOC and complexity |
| `data-model-documentation` | Catalog APIs, persistence, and message shapes into `DATA_MODEL.md` |
| `data-model-verification` | Adversarially verify DATA_MODEL.md property rows against Source files |
| `content-ops` | Score content with an auto-assembled expert panel until it hits 90+ |
| `content-pipeline` | Non-interactive content production — quote mining, clip discovery, repurposing, gating |
| `conversion-ops` | AI-powered CRO — landing-page audits, survey segmentation, lead magnets |
| `deployment-pipelines` | Author or review CI/CD pipelines and deployment workflows |
| `findings-ledger` | Record and triage stochastic (Tier 2) review findings for recurrence |
| `game-balancer` | Tune game economy curves, progression, drop tables, and balance |
| `game-systems-designer` | Design game systems from a locked concept |
| `godot-engineer` | Build games in Godot 4 with C# |
| `growth-engine` | Autonomous growth experimentation with statistical analysis |
| `iap-manager` | Design and operate the in-app purchase catalog |
| `library-investigator` | Forensic, evidence-only library audit against RULESET.md |
| `marketing-shaper` | Structure a vague marketing request into a scoped brief |
| `memory-extraction` | Extract durable memories from a session into `.claude/memory/` at session close |
| `outbound-engine` | Design and optimize cold outbound email campaigns on Instantly |
| `phaser-engineer` | Build games in Phaser 3 with TypeScript |
| `planning-and-task-breakdown` | Break work into ordered, parallel-dispatchable tasks |
| `prompt-shaper` | Structure a vague engineering request into a task brief |
| `release-manager` | Coordinate release preparation across a monorepo |
| `revenue-intelligence` | AI-powered revenue intelligence and content-to-revenue attribution |
| `rust-engineer` | Write, review, or architect Rust code |
| `security` | Scan and redact PII and sensitive data |
| `security-engineering` | Cross-stack security review covering all attack surfaces |
| `seo-ops` | AI-powered SEO operations and keyword intelligence |
| `session-state` | Maintain SESSION-STATE.md — durable within-session memory that survives compaction |
| `skill-library-review` | Audit a library of skills, agents, commands, and workflows |
| `telemetry` | Opt-in, local-first, privacy-respecting usage telemetry |
| `typescript-analytics` | Implement analytics with PostHog in TypeScript |
| `typescript-data-engineering` | Build data pipelines, ETL jobs, and event processors |
| `typescript-testing-backend` | Write backend tests with Jest and Supertest |
| `typescript-testing-frontend` | Write frontend tests with Jest and React Testing Library |
| `web3-smart-contract-engineering` | Write and review Solidity smart contracts |

---

## Agents

| Agent | Description |
|---|---|
| `adversarial-claims-reviewer` | Read-only, cold-context adversarial review of formal/technical claims |
| `code-reviewer` | Read-only multi-axis code review |
| `data-model-documenter` | Catalog APIs, models, and message shapes into `DATA_MODEL.md` at project root |
| `data-model-verifier` | Read-only verification of DATA_MODEL.md property rows against Source files |
| `devops-engineer` | Platform and DevOps engineering for Kubernetes, Helm, Pulumi IaC, and CI/CD mechanics |
| `engineer` | Full-stack implementation across architecture and shipping |
| `game-design-shaper` | Game design pipeline — intake → design → balance → catalog; marketing → marketer agent |
| `godot-engineer` | Godot 4 + C# game development |
| `library-investigator` | Read-only forensic library audit against RULESET.md — evidence-only counts, no verdict |
| `library-reviewer` | Read-only audit of a skill and agent library |
| `marketer` | Full-spectrum marketing, content, and sales execution |
| `phaser-engineer` | Phaser 3 + TypeScript web game development |
| `rust-engineer` | Principal-level Rust engineering — async services, APIs, workspaces |
| `security-reviewer` | Read-only cross-stack security audit |
| `technical-pm` | Product strategy, technical strategy, and engineering leadership |
| `web3-engineer` | Solidity smart contract development on EVM chains |

---

## Commands

Slash commands in `.claude/commands/`. Only `agent-new`, `skill-new`, and `state` (the awareness-harness writer) ship to consumers; the rest are repo-local maintainer tools.

| Command | Description |
|---|---|
| `agent-new` | Scaffold a new conforming agent definition |
| `audit-library` | Launch the sharded, adversarially-verified skill-library audit |
| `eval-harness` | Run the comparative eval harness over fixtures with a blind pairwise judge panel |
| `review-gate` | Run the Pattern-3 gate DAG (waves per `.claude/references/gate-dag.md`); `scripts/gate-plan.sh` lists required PR checkboxes |
| `skill-new` | Scaffold a new conforming skill |
| `state` | Record a durable session fact to SESSION-STATE.md via the deterministic writer |
| `triage-findings` | Tally the findings ledger and propose ratchet targets (human disposes) |

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
├── rules/                # operating doctrine, flattened into CLAUDE.md (build-claude-md.sh)
└── workflows/            # multi-agent orchestration scripts
```

> Installers copy full `skills/`, `agents/`, and `hooks/` directories (commands are file-allowlisted). `CLAUDE.md` and `rules/` are repo-local and never installed.

---

## Contributing

Pull requests welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for conventions and review gates. The short version: scaffold with `/skill-new` or `/agent-new`, run the `library-reviewer` agent on your diff, and make sure `bash scripts/validate.sh` passes.

---

## Validating the library

A deterministic, LLM-free validator checks structural invariants — frontmatter completeness, kebab-case names matching their file/dir, no dangling links or `@`-imports, `CLAUDE.md` flat-sync with `.claude/rules/` (`claude-flat-sync`, rebuilt by `scripts/build-claude-md.sh`), `MEMORY.md` length, review-tier wiring (and findings-ledger shape, if present), and that the install scripts ship exactly the expected directories and command allowlist.

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
