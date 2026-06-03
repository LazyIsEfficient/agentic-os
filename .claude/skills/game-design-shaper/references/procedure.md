# Game Design Shaper Procedure

## Brief Types

Identify which brief type fits:

- **Full game** — multi-month project, complete genre game. Use `assets/full-game-template.md`.
- **Prototype** — vertical slice, 2–6 weeks, validating a single core loop. Use `assets/prototype-template.md`.
- **Jam** — 1–3 day game jam, severe scope and theme constraints. Use `assets/jam-template.md`.
- **Live game update** — content drop or feature added to a shipped game. Use `assets/live-game-update-template.md`.

## Steps

1. Read the request; identify the brief type (ask if ambiguous).
2. Read the matching template from `assets/`. Read `references/interview-checklist.md` for questions.
3. Identify which sections the user already answered. Do not re-ask those.
4. **Round 1 questions.** Batch missing pieces into a single AskUserQuestion call — 3–6 questions, load-bearing gaps first (payment rails is one).
5. Resolve each remaining gap into one of three states:
   - **Answered** — fill it.
   - **Assumed** — fill with default, tag inline: `[Assumed: <value> — say if wrong]`.
   - **Deferred** — mark `<TBD — to investigate>`.
6. **Round 2 (only if needed).** 1–3 questions covering only unresolved load-bearing items. No round 3.
7. Output the filled template in a single fenced markdown block. Add one line: *"Here is your game brief. Paste it into a fresh session with `game-concept-creator` (if concept is open) or `game-systems-designer` (if concept is locked) available, or say 'go' and I'll hand it to the right skill now."* Then stop.

## Hard Rules

- Never guess silently — every gap must be Answered, Assumed (tagged), or Deferred.
- Load-bearing items must be answered — never assumed or deferred.
- Cap at two rounds of questions.
- Always ask about the success bar (D1/D7 retention floor, wishlist target, jam ranking, KPI floor).
- Player verbs, not feature lists — push the user to state what the player will *do* (verbs: dodge, build, deceive, collect, command).
- Core fantasy is mandatory — every brief must name the fantasy the player is buying into.
- Payment-rails decision is mandatory — even if "premium, no IAP", capture it explicitly.
- Web2/web3 is a constraint, not a goal — if the user says "web3", probe *why*.
- Do not assign skills to subtasks — describe concerns, not skill filenames.
- Do not start the work unless the user says "go" / "execute" / "do it" after seeing the brief.

## Load-Bearing Items

**Universal (any game variant):**
- Target player — who plays this and what they currently play
- Core fantasy — the fantasy the player is buying into, in one phrase
- Primary loop verbs — the 3 verbs the player does most
- Payment rails — none / web2 IAP / web2 ads / web2 subscription / web3 tokens / web3 NFTs / hybrid
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

Everything else (art style, audio, narrative depth, store metadata, marketing channels) is Assumable — fill with a safe default and tag it.
