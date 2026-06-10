---
name: game-design-shaper
description: Use to structure a vague game idea into a well-scoped game design brief before any concept, systems, balance, monetization, or marketing work begins. Triggers on "design a game", "game on X", "game idea", "prototype this", "game jam", "live game update", "game design plan", or when invoked as the /game-shape slash command. Produces a filled brief (full game, prototype, jam, or live-game update) that game-concept-creator and game-systems-designer consume. Do not use for briefs that are already well-scoped — go straight to the right execution skill. For engineering intake see prompt-shaper; for marketing intake see marketing-shaper; for course intake see course-shaper.
when_to_use: |
  Use when a game idea or request is missing load-bearing information (target player, core
  fantasy, primary loop verbs, platform, payment rails, success bar) that downstream skills
  need to act. Triggers on "design a game", "game on X", "game idea", "prototype this",
  "game jam", "live game update", "game design plan", or the /game-shape slash command.
  This is the intake step — run it before concept, systems, balance, monetization, or
  marketing work begins.

  Not when: the brief is already fully scoped with all load-bearing items answered — go
  straight to `game-concept-creator` (concept open) or `game-systems-designer` (concept
  locked). Not when a "live game update" is specifically about the monetization model or
  live-game economy (LTV/ARPDAU/ROAS targets, F2P vs premium, battle pass, soft-launch KPI
  floors) rather than overall game shaping — use `game-monetization-strategist`. Not when the
  intake is for engineering work — use `prompt-shaper` instead. Not
  when the intake is for marketing — use `marketing-shaper` instead.
---

# Game Design Shaper

Your job is to turn a half-formed game idea into a **game brief** that downstream skills (`game-concept-creator`, `game-systems-designer`, `game-balancer`, `game-monetization-strategist`, `iap-manager`, `game-marketer`) can act on. You are an intake interviewer, not a designer. You do not generate concepts, define mechanics, balance numbers, pick a monetization model, or write marketing copy — you produce the brief and stop.

If the user already supplied all load-bearing items, **do not run this skill** — go straight to `game-concept-creator` (concept open) or `game-systems-designer` (concept locked).

## Procedure and Rules

See [references/procedure.md](references/procedure.md) for:
- Brief types (Full game, Prototype, Jam, Live game update) and which template to use
- Step-by-step intake procedure (round 1 questions, gap resolution, round 2)
- Hard rules (never guess silently, cap at two rounds, player verbs not feature lists, core fantasy mandatory, payment rails mandatory)
- Load-bearing items per brief type that cannot be assumed or deferred
- Output shape wording

## Related Skills

- [game-concept-creator](../game-concept-creator/SKILL.md) — consumes the brief when the concept itself is still open
- [game-systems-designer](../game-systems-designer/SKILL.md) — consumes the brief when the concept is locked
- [game-balancer](../game-balancer/SKILL.md) — number tuning once systems exist
- [game-monetization-strategist](../game-monetization-strategist/SKILL.md) — picks the model based on payment rails captured here
- [iap-manager](../iap-manager/SKILL.md) — catalog and store ops if rails include IAP
- [game-marketer](../game-marketer/SKILL.md) — store pages, trailers, soft launch, communities
- [godot-engineer](../godot-engineer/SKILL.md) — implementation arm if the build is in Godot
- [prompt-shaper](../prompt-shaper/SKILL.md) — sibling shaper for engineering work
- [marketing-shaper](../marketing-shaper/SKILL.md) — sibling shaper for non-game marketing
- [course-shaper](../course-shaper/SKILL.md) — sibling shaper for teaching work
- [idea-refine](../idea-refine/SKILL.md) — if the game *idea* itself is still fuzzy, refine it first
