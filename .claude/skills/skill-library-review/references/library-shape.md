# Library Shape

Before reviewing individual files, ask: should this even be a skill / agent? Library-shape problems are the most expensive to fix later — file-level issues are local edits; shape problems require renames, splits, merges, and cross-reference updates across the library.

## Skill vs agent vs ambient

| Form | Use when | Examples |
|---|---|---|
| **Ambient rule** (CLAUDE.md, always-loaded) | Cross-cutting policy that should apply to every interaction | "Don't add error handling for impossible scenarios", commit message format |
| **Skill** (`SKILL.md`, loaded on match) | Domain knowledge, rules, reference patterns the *current* agent should follow when working in that domain | `code-review-and-quality`, `security-engineering`, `typescript-testing-backend` |
| **Agent** (`.claude/agents/`, delegated) | Discrete deliverable produced by a focused role with its own context window | `code-reviewer`, `engineer`, `technical-pm` |

The same domain can have both: the skill carries the rules; the agent is the role that applies them. `code-reviewer` agent uses `code-review-and-quality` skill.

## When to make something a skill

- It's a *way of working* — discipline, conventions, rules
- It applies during other work, not as a standalone deliverable
- Any agent doing this kind of work should follow it
- Examples: `code-review-and-quality`, `release-manager`, `deployment-pipelines`

## When to make something an agent

- It has a clear, named deliverable (verdict, brief, design doc, lesson, campaign)
- It's commonly delegated as a complete unit
- It benefits from an isolated context window (large research, no cross-domain bleed)
- Multiple skills naturally cluster around the role
- Examples: `code-reviewer`, `engineer`, `marketer`, `prompt-shaper`

## When to make something ambient (CLAUDE.md)

- It applies to *every* turn, regardless of task
- It's about agent behavior, not domain expertise
- Skipping it would be a bug
- Examples: communication style, commit conventions, "don't introduce OWASP-class bugs"

## Single-responsibility check

Can you describe the role in one sentence without using "or"?

- ✅ "Reviews code for correctness, design, and standards" — coordinated axes of one task
- ❌ "Reviews code or designs systems or shapes ideas" — three roles in a trench coat

If "or" connects unrelated *domains* (not related axes of the same task), split.

## Consolidation candidates

Two definitions doing the same job. Consolidate when:
- Descriptions overlap by >50%
- Triggers fire on the same vocabulary
- The deliverable is the same shape

Common patterns:
- Multiple skills covering "the same testing concern from slightly different angles"
- Reviewer + auditor + checker agents that all return verdicts on the same scope
- Three "shaper" skills with overlapping question protocols

## Split candidates

One definition spanning two domains. Split when:
- Description uses "or" between unrelated concerns
- Skill has to caveat ("for X see Y, for Z stay here") more than 2–3 times
- A single `SKILL.md` grows past ~150 lines because it covers two areas
- Two unrelated user vocabularies trigger the same skill
- Two contributors keep editing the same file for unrelated reasons

## Orphaned skills

A skill with **zero inbound references** from other skills/agents is suspect:
- Maybe it's genuinely standalone (e.g., `planning-and-task-breakdown` is a discipline skill applied across many tasks — document it as such in the description)
- More often: it was renamed, superseded, or never wired in

To find orphans:

```bash
# For each skill, count inbound refs
for skill in .claude/skills/*/; do
  name=$(basename "$skill")
  count=$(grep -r "$name" .claude/ --exclude-dir="$skill" | wc -l)
  echo "$count $name"
done | sort -n
```

Zero hits = investigate.

## Skills that should be agents

Promote when:
- Commonly delegated as a complete unit ("review the changes", "shape this idea")
- Has a clear deliverable / output format
- Benefits from an isolated context window
- A natural verb ("review", "shape", "audit") fits the role

## Skills that should stay skills

Keep as skill when:
- It's a rule / policy / discipline (always applied during other work)
- No discrete "deliverable" — it's a *way of working*
- The agent's parent should follow it, not delegate to it

Keep ambient (don't make a skill at all):
- House style, tone-of-voice, or formatting conventions that should colour every response
- Any policy that should apply to every turn

## Library-shape smells

- **Too many agents** — every skill becomes an agent. Symptom: agent descriptions overlap heavily; the parent has to think hard about which to call. Fix: collapse to broader agents and keep the rest as skills.
- **Too few agents** — only one agent does everything. Symptom: agent description is a paragraph of "or"s. Fix: identify natural delegation seams (review, intake, specialized stacks).
- **Skill–agent name collision** — same name used for both, with no clear "skill carries rules, agent is the role" relationship. Fix: clarify the relationship in both descriptions, or rename one.
- **Cluster without an agent** — five skills always loaded together for the same kind of work. Fix: consider an agent that bundles them.
