# Difficulty and pacing

Difficulty is *not* the same as challenge. **Difficulty** is how hard the system is. **Challenge** is the player's experience of being meaningfully tested. A game can be difficult without being challenging (it's just unfair) and challenging without being difficult (it asks the player to think, not to react fast).

## The flow channel

The classical model: as the player improves, the system should also get harder. If skill outpaces challenge, the player is bored. If challenge outpaces skill, the player is anxious. The "flow channel" is the band where they roughly match.

Designers often visualize this as a graph:
- X-axis: time / progress
- Y-axis: difficulty (challenge)
- Two diagonals: the boredom floor and the anxiety ceiling
- The flow channel: the band between

A well-tuned game keeps players in the flow channel for the bulk of the experience, with deliberate excursions:
- **Just-above-floor** (early game, breathers, victory laps)
- **Just-below-ceiling** (boss fights, climactic moments, late game)

A constant-flow game is exhausting; a constant-floor game is forgettable.

## The first failure

Where the *first* failure lands shapes the whole experience. Two patterns:

- **Failure-as-tutorial** — the player fails early, in a low-stakes way, and learns something. They form an opinion that "this game is fair and teaches me." Best for Challenge games.
- **Failure-after-investment** — the player succeeds for hours, then hits a wall. They form an opinion that "this game ambushed me." Catastrophic for retention.

Schedule the first failure deliberately. Validate in playtest that the *first* failure feels fair, not just that *most* failures feel fair.

## Difficulty curve shape

Like progression curves, difficulty has shape choices:

- **Smooth ramp** — gentle, continuous increase. Best for narrative-led games.
- **Stepped** — long flats interrupted by spikes (boss fights, world transitions). Best for traditional action games.
- **Wave** — alternating high/low intensity. Best for survival, horror, long-session games (gives a breather).
- **Choose-your-own** — the player picks difficulty (easy / normal / hard / nightmare). Best for replay value, accessibility, broad audiences.
- **Adaptive (DDA)** — the system measures the player's success rate and tunes in real time. Best for games where one curve can't fit the audience (e.g. *Resident Evil 4*'s adaptive ammo drops).

Pick the shape; the constants come from playtest data, not the spreadsheet.

## DDA (dynamic difficulty adjustment)

DDA hides the difficulty change from the player. Done well, players feel the game "just gets them." Done badly, players feel cheated when they realize the game was making things easy/hard secretly.

Rules:
- **Adjust resources, not rules.** A boss can drop more ammo when the player is struggling; the boss should not change behavior mid-fight in a way that breaks the player's mental model.
- **Adjust slowly.** Per-encounter, per-level, per-session — not per-hit.
- **Don't punish improvement.** A player who gets better should *feel* the difficulty rise to match, not have it auto-scale to keep them at 50% win rate forever.
- **Disclose if asked.** Don't deny that DDA exists; players will reverse-engineer it. Just don't *explain* it loudly during play.

## Rubber-banding (specific case)

Used in racing games and some MOBAs to keep matches close. Often hated when over-applied.

- **Light rubber-banding** — the lead car loses a small % of speed; the trailing car gets a small boost. Players in the middle see it as "anyone can win until the last lap."
- **Heavy rubber-banding** — first place gets actively punished; last place catches up effortlessly. Players in first place rage-quit.

Use light rubber-banding when the goal is *parity of session experience*. Don't use it when the goal is *recognition of skill*.

## Pacing within a level/encounter

A well-paced encounter has:
- **Open** — establish the threat at moderate intensity
- **Build** — escalate; introduce additional pressure (more enemies, less time, harder choices)
- **Twist** — change the conditions (a new mechanic, an environmental shift, a reveal)
- **Climax** — peak intensity; player must use everything they've learned in the encounter
- **Resolve** — fall in intensity; reward; transition to the next encounter

An encounter that's flat-intensity throughout is exhausting. An encounter that climaxes at the start is anti-climactic. An encounter that never twists is forgettable.

## Pacing across a session

Within a single session, layer multiple encounter-arcs:

- **First encounter:** moderate intensity (warmup)
- **Middle encounters:** alternating high/low (give breathers between intense moments)
- **Final encounter:** highest intensity of the session
- **Post-final:** a quiet beat to let the player reflect / save / quit on a high note

Sessions that end on a low (a defeat, a chore) reduce return rate. Sessions that end on a high (a victory, a level-up, a reveal) increase return rate. Schedule "exit ramps" deliberately.

## Difficulty and aesthetic

The difficulty curve must serve the dominant aesthetic:

- **Challenge** — needs a real curve; players opt in for the difficulty
- **Discovery** — moderate difficulty; the *exploration* is the reward, not the survival
- **Sensation** — easier; the player is here for feel, not for trial
- **Narrative** — easier; the *story* is the reward, and overly hard fights interrupt it
- **Fellowship** — variable; some players want it harder for the bragging rights, others want it easier for the hangout
- **Submission** — flat; difficulty barely matters

A roguelike pitched on Challenge that ships with a smooth easy curve has betrayed its aesthetic.

## Output for the design / balance

In the balance docs:
- **Chosen difficulty curve shape** + rationale
- **First-failure plan** — where it lands, why it's fair, what the player keeps
- **Per-encounter difficulty target** (often a target completion-rate at first attempt, e.g. 60%)
- **DDA rules** if any (what adjusts, by how much, how often)
- **Telemetry** — what success/failure events to track to validate the curve post-launch
