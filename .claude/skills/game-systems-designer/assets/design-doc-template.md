# Design doc — <game title>

> One per game. This is the contract every other skill builds against. Numbers go in `<TBD by game-balancer>`. Pricing goes in `<TBD by iap-manager>`.

## 1. Pitch (from concept one-pager)
- **Logline:** [Genre] where you [verb] to [goal] in [setting] with [twist].
- **Fantasy:** You are a <role>. You <do thing>. The feeling is <emotion>.
- **Hook (first 30s):** <the moment>
- **Comp titles:** <2–3>
- **Wedge:** <the one different thing>
- **Platforms:** <>
- **Payment rails:** <as captured by concept-creator and validated by monetization-strategist>

## 2. Aesthetics (MDA — what the player feels)
- Dominant: <1–2 from the MDA aesthetic list>
- Supporting: <1–2>
- Explicitly *not* targeting: <e.g. "Submission" if the game wants engagement, not pastime>

## 3. Dynamics (the patterns that produce the aesthetics)
<2–4 paragraphs describing the patterns of play — e.g. "tension between greed and survival", "build-up and catharsis", "social pressure with hidden info">

## 4. Player verbs (max 3)
For each verb (see [system-spec-template.md](system-spec-template.md) for the long form):
- **Verb 1:** <name> — <input → representation → feedback → failure → depth axis>
- **Verb 2:** <name> — <>
- **Verb 3:** <name> — <>

## 5. Core loop
<one paragraph, one diagram if helpful>
- Decision the player makes: <>
- Action they take: <>
- Feedback they get: <>
- Reward / consequence: <>
- Context for the next decision: <>
- Loop length: <seconds / minutes>

## 6. Meta loop(s)
For each meta loop:
- **Name:** <e.g. "run-to-run progression", "weekly season", "collection completion">
- **What it tracks:** <>
- **What it unlocks:** <>
- **How it connects back to the core loop:** <the player's reason to come back>
- **Loop length:** <hours / days / weeks>

## 7. Systems list (links to system specs)
- <System name> — one-line role
- ...

The systems list is the *menu* of major designs. Each item has its own filled `system-spec-template.md`.

## 8. Content systems
- **Content unit:** <level / encounter / card / quest / character>
- **Content production model:** <handcrafted / procedural / hybrid / UGC>
- **Content per arc:** <e.g. "20 hand-built levels in chapter 1", "300 cards across 4 sets">
- **Variety drivers:** <what keeps content from feeling samey>
- **Content cadence (live ops):** <weekly / monthly / seasonal / none>

## 9. Narrative integration
- **Theme (one sentence):** <>
- **Delivery channels (ranked):** <e.g. environmental → barks → cinematics → item descriptions>
- **Minimum narrative for the fantasy to land:** <what cannot be cut>
- **Player agency in story:** <linear / branching / emergent / authored>

## 10. Onboarding (first hour)
- **First 60 seconds:** <what the player does, sees, feels>
- **First 10 minutes:** <which verbs introduced, in what order>
- **First hour:** <which systems unlocked, what mastery looks like>
- **Tutorial style:** <discovered / guided / hidden / contextual>

## 11. Failure design
- **How players fail in the core loop:** <>
- **Why failure feels fair:** <attribution: what the player can learn>
- **What the player keeps after failure:** <progression that survives loss>
- **Death / loss rate target:** <design intent — actual numbers from `game-balancer`>

## 12. Session shape
- **Target session length:** <minutes>
- **Sessions per day target:** <>
- **Within-session arc:** <what "one session" looks like start to end>

## 13. Social dimension
- **Single-player / co-op / PvP / asynchronous / community-driven:** <>
- **What players share:** <runs, builds, characters, scores, replays, UGC>
- **Where they share it:** <in-game / external — Discord / TikTok / Reddit>

## 14. Constraints inherited from the brief
- **Engine:** <>
- **Team / scope:** <>
- **Hard dates:** <>
- **Platform-imposed:** <>
- **Payment rails:** <re-stated for the engineer's reference>

## 15. Open design questions (for review)
- <questions the team must resolve before build kickoff>

## 16. Handoffs
- **`game-balancer`:** which systems and which curves to tune first
- **`iap-manager`:** what monetization model the design assumes, and what catalog SKUs it implies (currency packs, cosmetics, passes)
- **`godot-engineer` (or other engine team):** which systems to build first, prototype priorities, save/load expectations
- **Screen-level UX / accessibility:** which screens are load-bearing, which flows need the most attention
- **the `marketer` agent:** the strongest hooks to lead with on store page and trailer
