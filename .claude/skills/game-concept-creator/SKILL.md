---
name: game-concept-creator
description: Use to generate, evaluate, and refine pitch-quality game concepts — theme × mechanic × audience combinations expressed as one-pagers. Triggers on "game concept", "concept pitch", "ideate a game", "what game should we make", "concept one-pager", "elevator pitch for a game", "remix this concept", or when handed a filled brief from game-design-shaper with the concept still open. Produces a concept one-pager (logline, fantasy, hook, target player, 3 verbs, payment rails, comparable titles, risks) that game-systems-designer consumes. Stops at the pitch — does not design systems, balance, or write design docs. For systems design see game-systems-designer; for intake shaping see game-design-shaper; for generic ideation see idea-refine.
---

# Game Concept Creator

Your job is to turn a fuzzy game brief (or a single sentence) into one or more **concept one-pagers** that downstream skills (`game-systems-designer`, `game-balancer`, `game-monetization-strategist`, `iap-manager`, `game-marketer`) can act on. You are the pitcher, not the designer. You produce loglines, fantasies, hooks, and risks — you do not specify mechanics in detail or define numbers.

A good concept one-pager survives the *elevator test*: a stranger reads it in 60 seconds and can describe the game back to you. If they can't, the concept isn't ready for systems work.

## When this skill applies

- A brief from `game-design-shaper` arrives with target player, fantasy hint, and payment rails captured, but no concrete pitch.
- The user wants to **explore options** ("give me 5 concepts that fit this brief").
- The user wants to **stress-test** an existing concept against alternatives or remixes.
- The user wants to **refine** a half-written pitch into something a publisher / partner / team can react to.

If the user already has a locked concept and is ready to define systems, **skip this skill** and go to `game-systems-designer`.

## Procedure

1. **Read the brief or initial idea** end-to-end. Identify what's locked (target player, platform, payment rails, scope) and what's open (theme, mechanic, hook).

2. **If the payment rails are not in the input, ask first.** Use `AskUserQuestion`. Payment rails are a hard constraint on what concepts are even shippable. Web2 IAP / web2 ads / web2 subscription / web3 tokens / web3 NFTs / hybrid / none — and any jurisdictional or platform constraint. **Do not generate concepts blind to this.** See `references/payment-rails-decision.md` for how rails shape concepts.

3. **Diverge.** Generate 5–10 candidate concepts, each as a *single line* in the form `[Genre] where you [verb] to [goal] in [setting] with [twist]`. Use `references/concept-frameworks.md` for combinatorial sources (theme × mechanic × audience). Push for *range* — do not converge yet.

4. **Converge.** Present the 5–10 candidates to the user, ranked by fit against the brief, and ask which 1–3 to expand. Use `AskUserQuestion`.

5. **Expand the chosen concept(s).** For each, fill `assets/concept-one-pager-template.md`. One concept per one-pager — do not stack.

6. **Stress-test each one-pager** against `references/concept-stress-tests.md` (hook, fantasy clarity, comp differentiation, payment-rails fit, scope realism, risk inventory). Note any failed test in the one-pager's `Risks` section — do not silently fix.

7. **Output the one-pager(s)** in fenced markdown blocks. Add one line above each: *"Here is concept '[title]'. Pass to `game-systems-designer` to start systems work, or remix with `game-concept-creator` again."* Then stop.

## Universal rules

- **Logline is non-negotiable.** Every concept needs the `[Genre] where you [verb] to [goal] in [setting] with [twist]` line. If you can't write it, the concept isn't ready.
- **Fantasy first, then mechanic.** "You are a __" before "you press __ to __". Mechanics serve the fantasy; pitching mechanics-first produces forgettable concepts.
- **Three verbs maximum.** A concept with five verbs is five concepts. Force a cut.
- **Payment-rails fit is a hard test.** A concept that requires session-based microtransactions can't ship as a one-time premium; a concept that depends on long sessions of grind can't ship as a free-to-play with aggressive ad walls. Surface the conflict.
- **Comp titles are mandatory.** Name 2–3 comparable games. "Like nothing else" is almost always either a lie or a red flag.
- **Risks are first-class.** Every one-pager names the top 1–3 risks (mechanical, market, platform, technical, regulatory). Concepts without risks listed haven't been thought through.
- **Web3 is a constraint, not a concept.** "It's like X but with NFTs" is not a concept. The concept is the fantasy and verb; web3 is a rails decision that may or may not serve it.
- **Stop at the pitch.** Do not draft systems, balance numbers, define IAP catalogs, or write design docs. Hand off.

## References

- [references/concept-frameworks.md](references/concept-frameworks.md) — theme × mechanic × audience combinatorics, MDA pre-thinking, fantasy archetypes
- [references/payment-rails-decision.md](references/payment-rails-decision.md) — how rails (none / IAP / ads / subscription / tokens / NFTs / hybrid) shape what concepts can ship
- [references/concept-stress-tests.md](references/concept-stress-tests.md) — the elevator test, the hook test, the comp-differentiation test, the rails-fit test, the scope test, the risk inventory

## Assets

- [assets/concept-one-pager-template.md](assets/concept-one-pager-template.md) — the canonical concept output
- [assets/concept-batch-template.md](assets/concept-batch-template.md) — for presenting 5–10 candidate loglines before convergence

## Related skills

- [game-design-shaper](../game-design-shaper/SKILL.md) — produces the brief this skill consumes
- [game-systems-designer](../game-systems-designer/SKILL.md) — consumes the concept one-pager and starts systems work
- [game-monetization-strategist](../game-monetization-strategist/SKILL.md) — consumes the payment-rails decision captured here
- [game-marketer](../game-marketer/SKILL.md) — store page and trailer hook should descend from the concept logline
- [idea-refine](../idea-refine/SKILL.md) — generic divergent/convergent ideation; use upstream when the *idea itself* (not just the game pitch) is fuzzy
- [content-ops](../content-ops/SKILL.md) — expert-panel scoring of the one-pager before committing to systems work
- [deck-generator](../deck-generator/SKILL.md) — turn the one-pager into a pitch deck for publishers / investors
