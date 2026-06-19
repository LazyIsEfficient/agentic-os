# v2 razor — classified cut-list (for approval)

**Non-destructive.** This classifies all 132 artifacts against the v2 rubric (default-cut:
keep only if it encodes project knowledge, is real automation, or enforces a behavior-changing
discipline). Nothing is deleted until you approve. Produced by a 7-auditor fan-out reading
every body + the token-tax inventory.

## Headline — FINAL (decisions applied)
Decisions: **keep verticals Game + Marketing; cut Video/audio + Ops/CRM; cut the v2-collab pod
(+ pod-architect).** Net:

| | KEEP | CUT | MERGE | total |
|---|---:|---:|---:|---:|
| skills | 34 | 51 | 4 | 89 |
| agents | 14 | 8 | 0 | 22 |
| commands | 6 | 3 | 0 | 9 |
| workflows | 1 | 1 | 1 | 3 |
| rules | 7 | 1 | 1 | 9 |
| **total** | **62** | **64** | **6** | **132** |

**53% of artifacts removed. Always-on token tax −47% (~9.3K of ~20K tokens removed every turn).**

> The KEEP/CUT/MERGE *lists* below are the raw audit (pre-vertical-decision). Apply the decisions
> above: everything under "Video/audio/deck" + "Ops/CRM" in the KEEP section, plus `pod-architect`,
> `documentation-and-adrs`, and `yt-shorts-script`, moves to CUT.

---

## Three decisions only you can make

### 1. The biggest lever isn't quality — it's VERTICALS you don't use
The auditors kept skills that are **genuine tools** (real scripts/APIs). But a real tool you
never use is still dead weight. Of the 44 KEEP skills, ~20 are non-engineering verticals:

- **Marketing/content/growth (10):** autoresearch, content-ops, content-pipeline, conversion-ops,
  growth-engine, marketing-shaper, outbound-engine, revenue-intelligence, seo-ops (+ `marketer` agent)
- **Game (3 + agent):** game-balancer, game-systems-designer, iap-manager (+ `game-design-shaper`)
- **Video/audio/deck (6):** deck-generator, elevenlabs-tts, podcast-ops, x-longform-post,
  yt-competitive-analysis, yt-shorts-pipeline
- **Ops/CRM (4 + agents):** finance-ops, team-ops, team-lead, meeting-intelligence (+ `ops-analyst`)

**If skills-db is an engineering library for you, cutting the verticals you don't actually work
in is the path to the ">50% minimal core" you asked for** — independent of the quality verdicts.
*Which verticals do you keep?*

### 2. The v2-collab pod — cut it? (it's coupled)
Both auditors flagged **`v2-collab` (command + workflow) for CUT on the investigation's own
evidence**: the pod measured == a single-pass baseline (no correctness lift) on every task we
tested. If you cut it, **`pod-architect` (v1.5, which only exists to compose pod rosters) is
orphaned and goes too.** That removes the entire multi-agent-collaboration concept you shipped in
1.4/1.5. *Keep it as an occasional tool, or cut the unproven machinery?*

### 3. Trim the rules even where kept
The 7 KEEP rules are ~4K always-on tokens **every session**. `subagent-dispatch` (4.7KB) and
`review-tiers` (3.3KB) are the biggest. They steer behavior usefully but can be cut ~40% without
losing the steer. *Approve a trim pass on kept rules?*

---

## KEEP — the proposed v2 core (76)

**Engineering + specialist stacks** — code-review-and-quality, adversarial-claims-reviewer,
codebase-cost-estimator, deployment-pipelines, release-manager, security, security-engineering,
prompt-shaper, godot-engineer, phaser-engineer, rust-engineer, web3-smart-contract-engineering,
browser-testing-with-devtools, telemetry, typescript-analytics, typescript-data-engineering,
typescript-testing-backend, typescript-testing-frontend · agents: engineer, code-reviewer,
security-reviewer, adversarial-claims-reviewer, library-reviewer, library-investigator,
devops-engineer, godot-engineer, phaser-engineer, rust-engineer, web3-engineer, technical-pm

**Library/meta machinery** — findings-ledger, planning-and-task-breakdown, skill-library-review
· commands: agent-new, skill-new, audit-library, eval-harness, review-gate, triage-findings ·
workflow: audit-skill-library · agent: pod-architect *(see decision 2)*

**Ops/analysis (vertical)** — finance-ops, team-ops, team-lead, meeting-intelligence · agents:
ops-analyst, bigquery-ai-agent

**Marketing/content (vertical)** — autoresearch, content-ops, content-pipeline, conversion-ops,
growth-engine, marketing-shaper, outbound-engine, revenue-intelligence, seo-ops · agent: marketer

**Game (vertical)** — game-balancer, game-systems-designer, iap-manager · agent: game-design-shaper

**Video/audio/deck (vertical)** — deck-generator, elevenlabs-tts, podcast-ops, x-longform-post,
yt-competitive-analysis, yt-shorts-pipeline · agent: ux-specialist

**Rules (trim)** — grounding, verification, factual-correctness, subagent-dispatch, review-tiers,
memory-discipline, communication

---

## CUT (48)

**Generic engineering best-practice essays** (Opus does these unprompted, no project specifics):
ci-cd-and-automation, cloud-infrastructure, debugging-and-error-recovery, devops-engineer (skill),
frontend-ui-engineering, git-workflow-and-versioning, incremental-implementation,
performance-optimization, shipping-and-launch, site-reliability-engineering, test-driven-development,
api-and-interface-design, software-design, system-architect, spec-driven-development,
source-driven-development, deprecation-and-migration

**Generic strategy/PM/advice essays:** competitive-positioning, icp-validation, market-sizing,
pricing-and-packaging, technical-product-management, technical-strategist, idea-refine,
documentation-writer

**Meta/doctrine that restates default or only routes:** context-engineering, standards-enforcer,
using-agent-skills

**Whole cut verticals (course/blog/ux-advice/social/game-advice):** blog-post-author,
blog-post-shaper (skill), course-author, course-design, course-shaper (skill), ux-design,
ux-research, social-growth, game-design-shaper (skill), game-marketer, game-monetization-strategist

**Duplicate shaper agents (the skill already carries the intake):** blog-post-shaper,
course-shaper, marketing-shaper, prompt-shaper

**Commands:** plan-clean (trivial chore), route (default behavior), v2-collab *(decision 2)*
**Workflow:** v2-collab *(decision 2)* · **Rule:** anti-patterns (restates the other rules)

## MERGE (8)
- code-simplification → code-review-and-quality
- security-and-hardening → security-engineering
- typescript-quality-engineering → typescript-testing-backend
- documentation-and-adrs → team-lead
- game-concept-creator → game-systems-designer
- yt-shorts-script → yt-shorts-pipeline
- workflow routing-collision-sweep → audit-skill-library
- rule briefing → subagent-dispatch

---

## Caveats before any deletion (the destructive pass)
- Cutting commands/skills changes `install.sh`'s ship-manifest — the prune must keep
  `validate.sh` green (update the manifest); CI runs validate-test.sh.
- Don't cut machinery the prune itself relies on (validate.sh, the eval harness, the shapers/planner).
- Deletion happens on a branch, hard-delete; this list is the safety gate.
