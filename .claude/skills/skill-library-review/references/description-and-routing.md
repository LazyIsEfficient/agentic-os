# Description and Routing

The loader matches user intent against descriptions. Routing quality lives or dies in this field.

## The structure

```
Use when <situation>. Triggers on <globs/keywords>. For <adjacent concern> see <other-skill>.
```

Three jobs:
1. **WHAT** — situation that calls for this skill/agent
2. **WHEN** — concrete triggers (file patterns, user vocabulary, slash commands)
3. **WHERE NOT** — cross-references to siblings that handle adjacent concerns

The third job is the most under-used. Without it, the loader has no way to deflect to a better match — it just picks the first description that fires.

## Specificity for routing

A description that could match anything matches nothing well.

| Bad | Better |
|---|---|
| "Use for code-related tasks" | "Use when implementing TypeScript backend features — APIs, services, database queries" |
| "Triggers on coding keywords" | `Triggers on edits to ".ts" files, mentions of "API endpoint", "Prisma", "migration"` |
| "Use for any review" | "Use proactively after non-trivial code changes for multi-axis review (correctness, design, perf)" |
| "Helps with marketing" | "Use when the deliverable is content, an experiment, or an outbound sequence" |

The test: read the description aloud. If it could equally well describe three other skills in the library, it's not specific enough.

## Trigger vocabulary

Match real user phrasing, not internal jargon.

Users say:
- "fix this bug" — not "remediate this defect"
- "make it faster" — not "optimize the critical path"
- "review my PR" — not "audit the changeset"
- "design a course" — not "produce instructional materials"

If you're unsure what users say, scan recent conversation history for the actual phrasing.

### Keyword density

- 5–12 keywords is healthy
- 15+ keywords signals weak description — the loader can't discriminate
- Single-word triggers ("design", "test") are too broad alone; pair with context ("system design", "test strategy")
- File globs (`**/*.test.ts`) are concrete and discriminating — prefer them when the skill is file-scoped

## Proactive markers

Phrases like "Use proactively after X" or "MUST BE USED before Y" tell the loader to fire the agent without an explicit user request.

When to use them:
- **Reviewers**: yes — "Use proactively after non-trivial code changes"
- **Security gates**: yes — "Use proactively before merging changes that touch auth, sessions, crypto"
- **Performance / quality gates**: case by case — only if the cost of skipping is high
- **Builders**: rarely — they fire on explicit work; auto-firing causes noise
- **Intake / shapers**: never — they're explicitly user-invoked

A proactive marker without a precise trigger condition is worse than no marker — the agent fires every turn and either becomes noise or gets ignored.

```
Bad:  Use proactively when reviewing code.
Good: Use proactively after any non-trivial code change before reporting work as done.
Bad:  MUST BE USED for security.
Good: Use proactively before merging changes that touch auth, sessions, crypto, or input validation.
```

## Cross-references

Every adjacent skill/agent should be named in the description so the loader can route correctly when the request lands closer to a sibling:

```
For Solidity contracts see web3-smart-contract-engineering. For Godot games see godot-engineer.
For read-only review verdicts see code-reviewer.
```

### Bidirectional refs

If A says "see B for X", does B's description (or related-skills section) name A? Asymmetric refs leave dead ends.

To find inbound refs:

```bash
grep -r "<skill-name>" .claude/skills/ .claude/agents/
```

Zero hits = orphan; investigate.

## Verifying a collision before you report it

A shared trigger keyword between two skills is **not** automatically a routing collision. Deliberately shared keywords, disambiguated by reciprocal "not when" clauses, are the intended pattern — the loader reads the deflection and routes correctly.

Before reporting a collision, run this check:

0. **Confirm the two skills actually contend.** A collision requires a *real* overlap: a shared trigger keyword, or two file-globs that both match the same file/request. Two skills that don't compete for the same request are not colliding just because neither names the other — that is expected, not a finding. (A general code-review skill and a test-strategy skill don't contend merely because neither cites the other.) No genuine overlap → stop here, no finding.
1. Read **both** skills' `description` and `when_to_use`, including every `Not when … use <other>` clause.
2. Ask: does each side already deflect to the other on the shared trigger?

| Both sides deflect (reciprocal "not when") | Only one side deflects | Neither side deflects |
|---|---|---|
| **Not a finding.** Resolved — do not report. | Should-fix: add the missing reverse tiebreaker. | Blocking/should-fix: real collision, no disambiguation. |

Quote the actual "not when" line from each side as evidence (or, for the "neither" column, paste the `grep` that shows the tiebreaker is absent). "These two share a keyword" *without* checking both tiebreakers is not a finding — it is half a check, and it is the single biggest source of false-positive collision reports.

Example: `marketing-shaper` and `outbound-engine` both trigger on "outbound campaign", but `marketing-shaper`'s description says "see outbound-engine" and the reverse says "see marketing-shaper". Reciprocal — resolved — not a finding.

## Description anti-patterns

- Starts with "I" or "We" (first-person)
- Doesn't include "Use when…" — pure WHAT, no WHEN
- Lists 20+ keywords (signal of "I couldn't decide what this is")
- Includes "etc." or "and more" (vague hedge that signals incomplete thinking)
- Uses company or project names that won't transfer to other repos
- "Use proactively" without specifying *when* — fires unconditionally
- No trailing cross-references when adjacent skills clearly exist
- Triggers list contains only generic keywords ("code", "design", "test") with no discriminators
