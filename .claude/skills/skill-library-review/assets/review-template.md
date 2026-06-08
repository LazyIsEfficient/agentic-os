# Skill Library Review

**Verdict**: <pass | fix-before-merge | hold>
**Reason**: <one line — the highest-severity finding or the overall posture>

## Grounding certification
> Confirm before submitting; an unchecked box invalidates the related findings.
- [ ] Every finding quotes the exact text at its cited `file:line` from the current file.
- [ ] Every routing-collision finding confirms **both** skills lack a reciprocal "not when" tiebreaker (else it is resolved and omitted).

## Scope reviewed
- <files / directories audited>
- <total skills, total agents>

## Library-shape observations
> Most expensive to fix later — surface here even if individual files are clean.

- <consolidation candidates: definitions doing the same job>
- <split candidates: definitions spanning two domains>
- <orphaned skills with zero inbound references>
- <missing agents for natural delegation seams>
- <skills that should be ambient (CLAUDE.md) instead>

## Blocking
> Must fix before merge. Frontmatter errors causing misroute, contradictions between declared role and tool allowlist, dangling cross-references.

- `<file:line>` — <issue> — <why blocking>

## Should-fix
> Real quality issues that don't block but shouldn't ship as-is.

- `<file:line>` — <issue>

## Nits
> Style / consistency / minor polish.

- `<file:line>` — <issue>

## Cross-reference health
- <broken refs to non-existent skills/agents>
- <missing bidirectional links>
- <orphaned skills>
- <stale refs to renamed skills>

## Routing quality
- <descriptions likely to misroute and why>
- <missing or imprecise proactive markers>
- <keyword density issues — too vague or too bloated>
- <keyword collisions — only after confirming neither side already deflects via "not when">

## Tool allowlist coherence
- <agents whose tool list contradicts their declared role>
- <intake agents with `Agent` tool (allows nested spawn)>
- <reviewers with write tools>

## Recommended order of fixes
1. <blocking item — start here>
2. <next blocking>
3. <should-fix priority>
