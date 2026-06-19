---
description: Scaffold a new agent (.md with frontmatter + tool allowlist + Skills-available block) and hand to library-reviewer
argument-hint: <agent-name>
allowed-tools: Glob, Write, Agent
---

You are scaffolding a new agent definition for this skills+agents library so a maintainer gets a conforming starting point in one step. A conforming agent file matches the shape used by `.claude/agents/code-reviewer.md` and `.claude/agents/engineer.md`: YAML frontmatter with `name`, `description` (trigger vocabulary + "For X see Y" cross-refs), and `tools` (comma-separated allowlist), then a body, ending with a "## Skills available" link section.

## Step 1 — resolve the agent name

The agent name is `$1`. If `$ARGUMENTS` is empty, STOP and ask the user: "What is the agent name? (kebab-case, e.g. `incident-responder`)". Do not invent a name.

Use the resolved name (call it `<name>`) verbatim for both the `name:` field and the filename. It must be kebab-case and must match the file stem. If `$1` is not kebab-case (lowercase, hyphen-separated, no spaces/underscores/capitals), STOP and report the violation — do not auto-correct silently.

## Step 1.5 — check for collision

Before writing anything, use `Glob` to check whether `.claude/agents/$1.md` already exists (glob `.claude/agents/$1.md`). If it exists, STOP and report the collision — do NOT overwrite. Tell the maintainer the agent `$1` already exists and they must pick a different name or edit the existing file directly.

## Step 2 — choose a minimal, coherent tool allowlist

Before writing `tools:`, pick the allowlist from the role implied by the name, using `.claude/skills/skill-library-review/references/tool-allowlists.md` as the rule:

- **Read-only reviewer / auditor** → `Read, Grep, Glob, Bash, WebFetch, WebSearch` (no `Edit`/`Write`/`NotebookEdit`, no `Agent`).
- **Intake / shaper** → `Read, Grep, Glob, Bash, WebFetch, WebSearch, AskUserQuestion` (no `Agent`, no `Edit`/`Write`).
- **Authoring** → reviewer set + `Edit, Write, AskUserQuestion` (still no `Agent`).
- **Orchestrator** → omit `tools:` to inherit (the only role that gets `Agent`).
- **Build / implement** → omit `tools:` to inherit.

If the role is genuinely unknown from the name, do NOT guess: emit the placeholder allowlist `Read, Grep, Glob` and a `TODO` (see template). Order tools read-first, then write, then specialty. Drop `Bash`/`Agent` unless the role clearly needs them.

## Step 3 — write the file

Create `.claude/agents/<name>.md` with EXACTLY this structure (substitute `<name>`; leave every `TODO` literal — do not fabricate triggers or tools):

```
---
name: <name>
description: TODO one-line role summary. Use when TODO trigger conditions. Triggers on TODO "phrase", TODO "phrase". For TODO related-task see TODO other-agent.
tools: TODO minimal allowlist from Step 2 — e.g. Read, Grep, Glob (or omit this line entirely to inherit for build/orchestrator roles)
---

You are TODO one-sentence identity and primary goal.

## Operating principles

- TODO core rule 1
- TODO core rule 2
- TODO core rule 3

## What this agent handles

- TODO scenario 1
- TODO scenario 2

## Skills available

- TODO skill-name — TODO what it provides
- TODO skill-name — TODO what it provides

## Delegate

This agent does not delegate — it reports back to the caller.
```

If the chosen role is **build or orchestrator**, omit the `tools:` line entirely (do not write `tools: TODO`, and do NOT put any comment inside the `---` fences — an HTML comment between the fences is invalid YAML and breaks the generated file). The omission is self-explanatory; if you want to record why, add a single line in the body *below* the closing `---`, e.g. `<!-- tools omitted: inherits the full toolset -->`.

If the chosen role is an **orchestrator** (it delegates to subagents via the `Agent` tool), replace the `## Delegate` body with a delegation-enabled note instead of the no-delegate stub:

```
## Delegate

This agent is an orchestrator: it decomposes work and dispatches subagents via the `Agent` tool, then reviews and integrates their results.
```

For all non-orchestrator roles, keep the `## Delegate` "does not delegate — it reports back to the caller" body shown in the template.

## Step 4 — hand to library-reviewer

After the file is written, dispatch a `library-reviewer` agent via the Agent tool. Brief it: "Review the newly scaffolded agent definition at `.claude/agents/<name>.md` for frontmatter correctness, tool-allowlist coherence, routing/trigger quality, and the Skills-available block. It is a scaffold with intentional `TODO` placeholders — flag those as expected-incomplete, not errors, and focus your verdict on whether the *structure* conforms. Respond under 150 words." Then report the file path, the allowlist you chose (and why), and the reviewer's verdict to the user.
