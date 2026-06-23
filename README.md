# Engineering Heresy — Agentic Framework

A collection of skills and agents for [Claude Code](https://claude.ai/code) that encode engineering workflows, content pipelines, game development, marketing ops, and more into reusable AI playbooks.

Install once, use in any project.

> Part of **[Engineering Heresy](https://geggleto.substack.com/)** by Glenn Eggleton — challenging conventional wisdom in AI and software engineering. **[Subscribe on Substack →](https://geggleto.substack.com/)**

---

## Install

Two consumer paths — **Cursor** and **Claude Code** — share the same skill/agent markdown from this repo but install to different global config dirs. Each section below is self-contained; you do not need to read the other platform's section.

Both remote one-liners install a **pinned release** and verify its SHA-256 before extracting anything — see [Verifying the download](#verifying-the-download).

- **Current release:** `v2.1.0`
- **Asset:** `agentic-os-v2.1.0.tar.gz`
- **SHA-256:** `44cae4fcb4b10f9def07aac5cc972a83241e6455346558521d922908604ca332`

### Cursor

Install skills, agents, and **dormant** hook scripts into `~/.cursor/`. Shared content is sourced from the repo's `.claude/` tree; Cursor-specific operating rules live in this repo under `.cursor/rules/*.mdc` (clone the repo into a project to use them — they are not copied by the global installer).

**macOS / Linux — one-liner (no clone required):**

```bash
curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.1.0/install-cursor.sh | bash
```

**Or from a local clone:**

```bash
git clone https://github.com/LazyIsEfficient/agentic-os.git
cd agentic-os
./install-cursor.sh
```

Files are copied to `~/.cursor/skills/`, `~/.cursor/agents/`, and `~/.cursor/hooks/`. Existing files are not overwritten by default. Add `--force` to update everything.

**Custom install path:**

```bash
CURSOR_DIR=/path/to/.cursor ./install-cursor.sh
```

**Windows:** use `install-cursor.ps1` for parity (or run `install-cursor.sh` from Git Bash/WSL).

**Session-state writer** (after `install-cursor.sh` — writer lands in global skills):

```bash
SS="$HOME/.cursor/skills/session-state/scripts/session-state.sh"
bash "$SS" init
```

In a **checkout of this repo**, the same writer also exists at `.claude/skills/session-state/scripts/session-state.sh`.

There is no `/state` slash command on Cursor. Invoke the `session-state` skill (or ask the agent to record a session fact) and it runs the writer via Bash — see [.claude/skills/session-state/SKILL.md](.claude/skills/session-state/SKILL.md).

Restart Cursor after install so new skills and agents load.

### Claude Code

#### macOS / Linux

**One-liner (no clone required):**

```bash
curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.1.0/install.sh | bash
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
irm https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v2.1.0/install.ps1 | iex
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
curl -fsSLO https://github.com/LazyIsEfficient/agentic-os/releases/download/v2.1.0/agentic-os-v2.1.0.tar.gz
# macOS / BSD:
echo "44cae4fcb4b10f9def07aac5cc972a83241e6455346558521d922908604ca332  agentic-os-v2.1.0.tar.gz" | shasum -a 256 -c
# Linux (coreutils):
echo "44cae4fcb4b10f9def07aac5cc972a83241e6455346558521d922908604ca332  agentic-os-v2.1.0.tar.gz" | sha256sum -c
```

There is intentionally no "track `main`" remote install path — to install
unreleased changes, clone the repo and run `./install.sh` from the clone.
Maintainers: see [RELEASING.md](RELEASING.md) for how the pin is produced.

#### Custom install path

```bash
CLAUDE_DIR=/path/to/.claude ./install.sh
```

```powershell
.\install.ps1 -Dest "C:\path\to\.claude"
```

---

## What gets installed

### Cursor (`install-cursor.sh`)

| Directory | Contents |
|---|---|
| `~/.cursor/skills/` | Skill playbooks — Cursor discovers these globally; invoke by name in Agent chat |
| `~/.cursor/agents/` | Subagent definitions — spawn by name when Cursor routes or when you request one |
| `~/.cursor/hooks/` | Cursor-native hook scripts from `.cursor/hooks/` (JSON stdout; spike `*-probe.sh` excluded; dormant until registered) — see [Awareness harness](#awareness-harness-experimental) |

> **Ship vs. in-repo-only.** The Cursor installer copies the full `skills/` and `agents/` trees from `.claude/` plus production hook scripts from `.cursor/hooks/` (spike `*-probe.sh` excluded). Slash commands do **not** ship on Cursor (no `/state`; use the `session-state` skill + writer). Maintainer-only commands and `workflows/` are repo-local. Operating doctrine for Cursor lives in this repo's `.cursor/rules/*.mdc` — clone into a project to use; it is not copied to `~/.cursor/` by `install-cursor.sh`.

### Claude Code (`install.sh`)

| Directory | Contents |
|---|---|
| `~/.claude/skills/` | Skill playbooks — invoked with the `Skill` tool or `/skill-name` |
| `~/.claude/agents/` | Subagent definitions — spawned with the `Agent` tool |
| `~/.claude/commands/` | Slash commands — `/skill-new` and `/agent-new` scaffold a new conforming skill or agent; `/state` records a durable session fact via the awareness-harness writer |
| `~/.claude/hooks/` | Hook scripts (e.g. `block-bad-bash.sh`). The awareness-harness hooks also land here but stay **dormant** until a `settings.json` registers them — see [Awareness harness](#awareness-harness-experimental) |

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

An in-development capability ([NORTH_STAR.md](NORTH_STAR.md) / [V2_ROADMAP.md](V2_ROADMAP.md)) that fights the dominant failure mode of long agent sessions: **awareness drift** — finite context compresses, so settled facts get re-derived and existing infrastructure gets rebuilt. It externalizes state and re-surfaces it deterministically via IDE hooks:

- **`SESSION-STATE.md`** — a live, gitignored constraints/decisions/infra/threads doc. Hooks inject it at session start, inject a compact digest each turn, and checkpoint before compaction. Maintained only through the deterministic writer (Claude: `/state`; Cursor: `session-state` skill + Bash), never hand-edited.
- **survey-before-act** — on a service-provisioning command, reminds you to check whether it already exists first (warn-first; logs for measurement, does not block).
- **`eval/metrics/`** — deterministic instruments (`session-metrics.mjs`, `compare.mjs`) that measure tokens-per-outcome and awareness signals, ON (hooks) vs OFF (baseline).

**Ship posture:** hook **scripts** install on both platforms but stay **dormant** until you opt in — no shipped `settings.json` (Claude) or `hooks.json` (Cursor). The writer and `session-state` skill work without hooks.

**→ [Activation guide](docs/awareness-harness-activation.md)** — prerequisites, Claude + Cursor JSON snippets (all four hooks), verify steps, dogfooding for #145.

**Cursor live-fire status** (Cursor `3.8.11` unless re-tested):

| Hook | Status |
|---|---|
| `sessionStart` inject | **PROVEN** — model receives full `SESSION-STATE.md` |
| `beforeSubmitPrompt` digest | **PROVEN** — live-fire Test A PASS (2026-06-23); per-turn Constraints + Decisions + Open threads reach the model via `additional_context` |
| `beforeShellExecution` survey | **PENDING** manual confirmation — [live-fire protocol](eval/spikes/cursor-hook-capability/LIVE-FIRE-PROTOCOL.md) |
| `preCompact` checkpoint | Side-effect log only (same deferral as Claude S0) |

See also [cursor hook capability spike](eval/spikes/cursor-hook-capability.md). Global `install-cursor.sh` copies the same production `.cursor/hooks/` scripts (excluding spike probes) to `~/.cursor/hooks/`. **v2 closeout checklist:** [eval/metrics/V2-CLOSEOUT.md](eval/metrics/V2-CLOSEOUT.md) (live-fire, long-session A/B, milestone).

Treat any hook-injected file as untrusted data — see [SECURITY.md](SECURITY.md) (dual-platform hook surface; Cursor install details in [#153](https://github.com/LazyIsEfficient/agentic-os/issues/153)).

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

### Configure Cursor rules + skill discipline

Operating doctrine for this repo lives in `.cursor/rules/*.mdc` (YAML frontmatter with `alwaysApply: true`). Cursor requires the **`.mdc`** extension — plain `.md` files in `.cursor/rules/` are not loaded. Clone the repo into a project to use them, or copy the rules into your project's `.cursor/rules/`.

`AGENTS.md` at the repo root is auto-loaded by Cursor (project-root plain markdown). Full doctrine: `.cursor/rules/*.mdc` (`alwaysApply: true`). `CURSOR.md` is the maintainer index (parallel to `CLAUDE.md`).

For orchestrator behavior **across all projects**, paste the Skills + Subagents blocks below into **Cursor Settings → Rules → User Rules** (also printed by `install-cursor.sh` on success).

To make installed skills default-invoked globally, add to **Cursor Settings → Rules → User Rules**:

```markdown
## Skills

You have a library of skills installed at `~/.cursor/skills/`. Before responding to any task,
check whether a skill applies and read its SKILL.md if so — even if the task seems simple.

If there is even a 1% chance a skill might apply, load the skill first.
```

To make subagent dispatch default globally (match Claude Code's orchestrator model), add this block to **User Rules** as well:

```markdown
## Subagents

You are the orchestrator — subagents do the work. Agent definitions live at `~/.cursor/agents/`.
For any non-trivial task, dispatch via the `Task` tool in Agent mode instead of doing multi-step
work on the main thread. Fan out independent tasks in parallel (multiple `Task` calls in one message).
After implementation, spawn `code-reviewer` before reporting done. For research needing more than
2–3 file reads, use an `explore` subagent.
```

Repo maintainers: `CURSOR.md` at the repo root `@`-imports `.cursor/rules/*` (parallel to `CLAUDE.md`).

---

## Skills

| Skill | Description |
|---|---|
| `adversarial-claims-reviewer` | Adversarially review formal/technical claims — math, stats, benchmarks, whitepapers |
| `autoresearch` | Run Karpathy-style autoresearch optimization on any conversion content |
| `browser-testing-with-devtools` | Test in real browsers via Chrome DevTools MCP |
| `code-review-and-quality` | Multi-axis code review across correctness, design, security, performance |
| `codebase-cost-estimator` | Estimate build/dev cost of a codebase by measured LOC and complexity |
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
| `review-gate` | Run the Pattern-3 review gate (code-reviewer + security/library-reviewer) on the current diff |
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
├── rules/                # operating doctrine, @-imported by CLAUDE.md
└── workflows/            # multi-agent orchestration scripts
```

> Installers copy full `skills/`, `agents/`, and `hooks/` directories (commands are file-allowlisted on Claude Code only). `CLAUDE.md`, `CURSOR.md`, and `rules/` are repo-local and never installed.

---

## Contributing

Pull requests welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for conventions and review gates. The short version: scaffold with `/skill-new` or `/agent-new`, run the `library-reviewer` agent on your diff, and make sure `bash scripts/validate.sh` passes.

---

## Validating the library

A deterministic, LLM-free validator checks structural invariants — frontmatter completeness, kebab-case names matching their file/dir, no dangling links or `@`-imports (`CLAUDE.md` and `CURSOR.md`), `MEMORY.md` length, review-tier wiring (and findings-ledger shape, if present), and that the install scripts ship exactly the expected directories and command allowlist.

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
