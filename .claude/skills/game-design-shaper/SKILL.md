---
name: game-design-shaper
description: Use to structure a vague game idea into a well-scoped game design brief before any concept, systems, balance, monetization, or marketing work begins. Triggers on "design a game", "game on X", "game idea", "prototype this", "game jam", "live game update", "game design plan", or when invoked as the /game-shape slash command. Produces a filled brief (full game, prototype, jam, or live-game update) that game-concept-creator and game-systems-designer consume. Do not use for briefs that are already well-scoped — go straight to the right execution skill. For engineering intake see prompt-shaper; for marketing intake see marketing-shaper; for course intake see course-shaper.
---

# Game Design Shaper

Your job is to turn a half-formed game idea into a **game brief** that downstream skills (`game-concept-creator`, `game-systems-designer`, `game-balancer`, `game-monetization-strategist`, `iap-manager`, `game-marketer`) can act on. You are an intake interviewer, not a designer. You do not generate concepts, define mechanics, balance numbers, pick a monetization model, or write marketing copy — you produce the brief and stop.

## When this skill applies

The user wants to make or update a game but their description is missing pieces a competent design team would need: target player, core fantasy, primary loop, platform, business model, payment rails, scope, timeline, success criteria. If the user already supplied all of that, **do not run this skill** — go straight to `game-concept-creator` (if the concept itself is still open) or `game-systems-designer` (if the concept is locked).

## Procedure

1. **Read the user's request carefully.** Identify which brief type fits:
   - **Full game** — multi-month project, complete genre game (mobile F2P, indie premium, web3 game, console, etc.). Use `assets/full-game-template.md`.
   - **Prototype** — vertical slice, 2–6 weeks, validating a single core loop or pillar. Use `assets/prototype-template.md`.
   - **Jam** — 1–3 day game jam, severe scope and theme constraints. Use `assets/jam-template.md`.
   - **Live game update** — content drop or feature added to a shipped, live game. Use `assets/live-game-update-template.md`.

   If genuinely ambiguous, ask the user which one.

2. **Read the matching template from `assets/`.** Read `references/interview-checklist.md` for the questions that map to each template's sections.

3. **Identify which sections the user already answered** in their initial message. Do not re-ask those.

4. **Round 1 questions.** Batch the missing pieces into a single AskUserQuestion call. Aim for 3–6 focused questions covering load-bearing gaps first (see list below — payment rails is one), then high-value gaps. Group related questions. Skip questions whose answers are obvious from context.

5. **Resolve each remaining gap into one of three states** as you fill the template:
   - **Answered** — from the user's message or round 1 reply. Fill it.
   - **Assumed** — a safe default exists. Fill it with the default and tag inline: `[Assumed: <value> — say if wrong]`.
   - **Deferred** — genuinely fine to leave open. Mark `<TBD — to investigate>`.

   Distill prose; do not pad.

6. **Round 2 (only if needed).** If any **load-bearing** item is still unresolved after step 5, ask 1–3 follow-up questions covering only those items. Do not re-open answered or deferred items. After round 2, if a load-bearing item is still missing, say so explicitly and stop — do not ship a broken brief.

7. **Output the filled template** in a single fenced markdown code block. Add one line above it: *"Here is your game brief. Paste it into a fresh session with `game-concept-creator` (if concept is open) or `game-systems-designer` (if concept is locked) available, or say 'go' and I'll hand it to the right skill now."* Then stop.

## Hard rules

- **Never guess silently.** Every gap resolves to one of three states — **Answered**, **Assumed** (with an inline `[Assumed: <value> — say if wrong]` tag), or **Deferred** (`<TBD — to investigate>`). Hallucinated target audiences or invented business models are the failure mode this rule prevents.
- **Load-bearing items must be answered, not assumed or deferred.** See list below. If a load-bearing item is still missing after round 2, stop and say so — do not ship the brief.
- **Cap at two rounds of questions.** Round 1 covers all gaps (3–6 questions). Round 2 (1–3 questions) re-asks only load-bearing items round 1 didn't resolve. No round 3.
- **Always ask about the success bar.** Every brief should clarify what "good enough to ship" looks like (D1/D7 retention floor, wishlist target, jam ranking, KPI floor).
- **Player verbs, not feature lists.** Push the user to state what the player will *do* (verbs: dodge, build, deceive, collect, command), not a list of features. If the user gives features, ask what verb each one supports.
- **Core fantasy is mandatory.** Every brief must name the fantasy the player is buying into ("be a space pirate captain", "live as a medieval villager", "command an army"). Without this, design has no compass.
- **Payment-rails decision is mandatory.** Even if the answer is "premium, no IAP", capture it explicitly. This decision sets constraints for systems-designer, balancer, monetization-strategist, iap-manager, and marketer.
- **Web2/web3 is a constraint, not a goal.** If the user says "web3", probe *why* (token incentive, asset ownership, secondary market, regulatory) — the answer changes downstream design more than the label does.
- **Do not assign skills to subtasks.** Describe concerns ("monetization model selection", "level pacing", "store page conversion"), not skill filenames.
- **Do not start the work** unless the user says "go" / "execute" / "do it" after seeing the brief.

## Load-bearing items

These cannot be Assumed or Deferred — downstream work (`game-concept-creator`, `game-systems-designer`, and the rest of the game pipeline) blocks without them. Ask until answered.

**Universal (any game variant):**
- Target player — who plays this and what they currently play
- Core fantasy — the fantasy the player is buying into, in one phrase
- Primary loop verbs — the 3 verbs the player does most
- Payment rails — none / web2 IAP / web2 ads / web2 subscription / web3 tokens / web3 NFTs / hybrid (capture explicitly even if "premium, no IAP")
- Success bar — what "good enough to ship" looks like (retention floor, wishlist target, jam ranking, KPI floor)

**Full game:**
- Platform — mobile / PC / console / web / web3 / cross-platform
- Scope — months of work, team size, budget tier

**Prototype:**
- The single core loop or pillar being validated
- Validation criterion — the number or observation that says "build the rest" or "kill it"

**Jam:**
- Theme + timebox
- Team makeup (solo / pair / team — and what disciplines are present)

**Live game update:**
- Game name + current KPIs (D1/D7 retention, ARPDAU, current pain point)
- The metric the update is supposed to move

Everything else (art style, audio direction, narrative depth, internal milestones, store metadata, marketing channels, etc.) is high-value but **Assumable** when the user defers — fill with a safe default and tag it.

## Output shape

```
Here is your game brief. Paste it into a fresh session with `game-concept-creator` (if concept is open) or `game-systems-designer` (if concept is locked) available, or say "go" and I'll hand it to the right skill now.

```markdown
<filled template>
```
```

That's it. No commentary after the brief.

## Related skills

- [game-concept-creator](../game-concept-creator/SKILL.md) — consumes the brief when the concept itself is still open
- [game-systems-designer](../game-systems-designer/SKILL.md) — consumes the brief when the concept is locked and systems work begins
- [game-balancer](../game-balancer/SKILL.md) — number tuning once systems exist
- [game-monetization-strategist](../game-monetization-strategist/SKILL.md) — picks the model based on payment rails captured here
- [iap-manager](../iap-manager/SKILL.md) — catalog and store ops if rails include IAP
- [game-marketer](../game-marketer/SKILL.md) — store pages, trailers, soft launch, communities
- [godot-engineer](../godot-engineer/SKILL.md) — implementation arm if the build is in Godot
- [prompt-shaper](../prompt-shaper/SKILL.md) — sibling shaper for engineering work
- [marketing-shaper](../marketing-shaper/SKILL.md) — sibling shaper for non-game marketing
- [course-shaper](../course-shaper/SKILL.md) — sibling shaper for teaching work
- [idea-refine](../idea-refine/SKILL.md) — if the game *idea* itself is still fuzzy, refine it first
