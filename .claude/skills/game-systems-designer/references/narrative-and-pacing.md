# Narrative and pacing

Every game carries narrative weight, even systems-led ones. *Tetris* has narrative ("the line is rising; you survive"). *Vampire Survivors* has narrative ("you are alone against an endless horde"). The job of narrative design in a systems-led game is **to deliver theme, fantasy, and stakes through the systems already in the game** — not to bolt a separate story on top.

## What narrative does in a game

- **Justifies the fantasy.** The systems give the player verbs; the narrative explains *why* this fantasy is worth investing in.
- **Charges the stakes.** A loss in a system without narrative is a number going down. A loss with narrative is *something happening to a character, place, or world*.
- **Carries the meta loop.** Story beats are some of the strongest meta-progression hooks (the player wants to know what happens next).
- **Creates the talking point.** Stories travel. Mechanics rarely do. The thing players post about is usually a *moment*, which is narrative-shaped.

## Delivery channels

Pick the channels deliberately, in order of design priority:

1. **Environmental** — the world and its objects tell the story (level design, art direction, ambient audio, found notes, environmental destruction). Cheapest per beat for systems-led games. Strongest for Discovery aesthetic.
2. **Barks** — short character lines, voice or text, triggered by events. Cheap, high reusability. Strong for Fellowship and Sensation.
3. **Item descriptions** — flavor text on cards, weapons, locations. Cheap, optional engagement. Strong for Discovery and Expression.
4. **Cutscenes / set pieces** — authored moments. Expensive per beat. Strong for Narrative aesthetic but rarely the right primary channel for systems-led games.
5. **Dialogue trees / branching conversations** — high cost per beat, high engagement. Strong for Narrative + Expression (player choice). Best when the verb itself is *Persuade* or *Read*.
6. **Live-ops events** — story arcs that play out across weeks of operation. High cost in coordination, low cost per beat. Strong for Fellowship.
7. **Player stories** — emergent narrative players generate themselves. Lowest cost (the players do the work); requires *systems that produce stories worth telling*.

For most systems-led games, the order is: **environmental + barks + item descriptions + player stories**, with cutscenes used sparingly for the climaxes.

## The minimum narrative test

For each part of the design, ask: *what's the minimum narrative needed for the fantasy to land?*

- A hero's journey doesn't need 50 hours of authored story — it needs a clear "before" and a clear "after" with the player carrying the change in the middle.
- A survival fantasy doesn't need lore dumps — it needs a believable threat and a believable scarcity.
- A trading fantasy doesn't need named characters — it needs *places that feel different from each other* and *prices that respond to the world*.

Designers add narrative until the fantasy *lands*, then stop. Adding more narrative past the landing point usually buries the systems.

## Pacing across an arc

A play arc (a single playthrough, a season, a chapter) has the same shape as a single level — open / build / twist / climax / resolve — but stretched out:

- **Open** — the world introduces itself; verbs introduced one at a time; stakes feel low
- **Build** — verbs combine; stakes rise; the player understands what's at risk
- **Twist** — something the player didn't see coming reframes the early game (a betrayal, a power swap, a setting change)
- **Climax** — the systems are at maximum complexity; the stakes are highest; the player has the verbs and content to meet the challenge
- **Resolve** — the arc closes; the player carries something forward (mastery, story, world-state)

A game without a twist drifts. A game without a resolve feels truncated. A game without a build feels like it never started.

## Pacing within a session

Within a single session, the pacing micro-cycle is:

- **Tension** rises across the loop (each iteration adds resources or risk)
- **Release** at the end of the loop (the run ends, the round closes, the day passes)
- **Reflection** beat — the moment between loops when the player sees what they kept

Games that skip the reflection beat (no run-summary, no end-of-day pause, no scoreboard) feel exhausting because the player has no "breathing" moment.

## Pacing across days/weeks (live ops)

For live games:

- **Daily**: short engagement bursts; the daily reward is a *narrative beat*, not just numbers
- **Weekly**: a story arc per week or two; weekly events have *names and stakes*
- **Seasonal**: a story arc that resolves; the next season opens a new chapter
- **Annual**: a major narrative reset (new continent, new era, new villain)

Live games that treat narrative as decorative will lose to live games that use narrative as their meta-progression backbone.

## Anti-patterns

- **Lore wall onboarding** — the game opens with paragraphs of world history before the player has done anything. Cut to the verb; let the world reveal itself.
- **Cutscene tax** — every system unlock requires a 90-second non-skippable cutscene. Players will skip them; the production is wasted.
- **Branching that doesn't branch** — the player makes "choices" that funnel back to the same outcome. The narrative dynamic is *Submission*, not *Expression*.
- **Disconnected story** — the cutscenes and the gameplay are about different things. The player learns to ignore one or the other.
- **Live-ops content with no story** — events called things like "Event 14" with no theme, characters, or stakes. Players have nothing to talk about; engagement decays.

## Output for the design doc

In §9 of the design doc:
- **Theme** in one sentence
- **Delivery channels ranked** by design priority
- **Minimum narrative for the fantasy** (the cut line)
- **Player agency in story** (linear / branching / emergent / authored)
- For each arc, a one-paragraph **pacing sketch** (open → build → twist → climax → resolve)
