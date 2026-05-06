# Onboarding and failure

Two of the most undervalued areas in systems design. Onboarding is what most players see before they bounce. Failure is what every player feels every session for the entire life of the game. Both are *systems*, not afterthoughts.

## Onboarding is the first hour

The "tutorial" is a tiny fraction of onboarding. Onboarding is the entire first hour — the first time the player meets every verb, every system, every loop, and forms an opinion about whether to come back tomorrow.

For each verb in the design:
- **When** is it introduced?
- **In what context** (under threat? safely? as a reward?)
- **How is mastery shown** (animation, feedback, the player's own success)
- **How long** does the player practice it before the next verb arrives?

Verbs introduced in the wrong order, too close together, or without practice space — the player feels overwhelmed and quits.

## The first 60 seconds

The single most important window. In 60 seconds, the player should have:

- **Touched the controls.** No menus, no story. The player presses something and the world responds.
- **Seen the fantasy.** A glimpse of what the game *is*, in motion, not described.
- **Hit a moment of agency.** A choice that mattered, however small.

If the first 60 seconds are a logo + cutscene + main menu + difficulty select + character creator, the game has used its first 60 seconds on *not playing*.

## The first 10 minutes

By the 10-minute mark:

- **The core loop has run** at least 3–5 times.
- **The dominant aesthetic has been felt** at least once (sensation, fantasy, challenge — whatever the design promises).
- **One verb is being practiced.** Not all verbs introduced — one verb practiced.
- **A meta-progression hint** has been shown (something unlocks, something accumulates, something the player can imagine continuing).

Games that fail the 10-minute test usually do so because they spent too long *teaching* and not enough time *playing*.

## The first hour

By the 1-hour mark:

- **All major verbs have been introduced** at least once each, in *separate contexts*.
- **At least one meta loop has fired** (run ended, day passed, level cleared, season-progress visible).
- **The player has failed and recovered.** Failure design (below) lands here.
- **The player has made a *meaningful* choice** in the meta loop (which path, which build, which faction).
- **The player can describe the fantasy in their own words.** This is the test: ask a playtester at the 1-hour mark "what's this game about?" and listen.

## Tutorial styles

Pick one style and commit:

- **Discovered tutorial** — the player figures it out from environmental cues, level design, and the systems themselves. High craft to make legible. Best for Discovery aesthetic.
- **Guided tutorial** — UI prompts, "press X to Y" hints, contextual tooltips. Cheap, common, often badly done. Best for complex systems with tight time budgets to teach.
- **Hidden tutorial** — the early levels *are* the tutorial; the player doesn't know they're being taught. Best craft, requires excellent level design. Examples: *Half-Life 2*, *Portal*.
- **Contextual tutorial** — tutorials trigger when the player is about to *need* the information, not before. Best for sprawling systems (RPGs, sims) where front-loading would overwhelm.

Mixing styles tends to feel inconsistent. Pick one for the game's spine; use a second sparingly for specific systems.

## Failure design

Failure is a system, not an event. Players experience it every session for the life of the game. Bad failure design produces a game that feels *unfair*, *punishing*, or *cheap* — even when the underlying balance is fine.

The four pillars of fair failure:

1. **Attribution** — the player can identify *what they did wrong*. Failures with no attribution feel arbitrary.
2. **Recoverability** — the player can either reverse the failure (undo, retry, second chance) or take *something* away from it (resources, knowledge, progression).
3. **Pacing of failure** — failure happens at a rate the player can absorb. Three rapid failures in a row breaks confidence; one failure every 30 minutes feels like the system isn't trying.
4. **Aesthetic of failure** — losing should *feel like the aesthetic the game promises*. A roguelike's death should feel like *Discovery* (you learned something) and *Challenge* (you'll do better). A cozy farming sim's failure should feel like *Submission* (relax and try tomorrow).

## Failure types and when to use them

- **Soft fail** — the player loses progress in the current attempt but keeps meta-progression. Roguelike standard. Best for Challenge aesthetic.
- **Hard fail** — the player loses meta-progression. Permadeath, ironman. Best when the *risk of permanent loss* is the dominant aesthetic.
- **Setback** — the player loses time, not progress. Common in MMOs, story-driven games. Lowest cost; lowest emotional weight.
- **Cosmetic fail** — the player "loses" but the world / character carries the loss as flavor. Best for Narrative aesthetic.
- **Multi-attempt fail** — the player has N tries before any meta-progression is lost. Common in F2P (energy / lives systems). Care: this can feel like a paywall, not failure design.

## Failure friction (the rage-quit budget)

Each failure spends some of the player's emotional budget. Designs to minimize friction:

- **Fast restart.** Time between failure and "trying again" should be seconds, not a load screen.
- **Visible delta.** Show what changed between this attempt and the last (better gear, more knowledge, a new option).
- **Optional context.** A short replay, a "what hit you" callout, a stat summary — opt-in, never forced.
- **No menu detour.** Failure → restart should be one or two button presses, not a navigation through screens.

## Onboarding-failure interaction

The two interact in the first hour:

- **Players should fail in the first hour.** A game that lets you win for the first hour teaches you it's easy; the difficulty spike later feels unfair.
- **The first failure should land in a context that demonstrates fair failure.** If the player's first death feels arbitrary, they form an opinion about the *whole game's failure design* in that moment.
- **The first recovery should be visible and rewarding.** The player learns "failure means I get to try again with X more / better Y."

## Output for the design doc

In §10 of the design doc:
- **First 60 seconds** — what the player does, sees, feels
- **First 10 minutes** — verbs introduced, in what order
- **First hour** — systems unlocked, mastery shown
- **Tutorial style** chosen

In §11:
- **How the player fails** in the core loop
- **Why failure feels fair** (attribution chain)
- **What they keep** after failure
- **Death / loss rate target** (design intent — actual numbers from `game-balancer`)
