# game-design-shaper — jam

Example of `/game-shape` producing a `jam-template.md` brief — 1–3 day jam with severe constraints.

---

## User's initial request

> 48-hour Ludum Dare in two weeks. Theme drops Friday night. Solo. I want to actually finish and place top 100 in Innovation this time.

## Shaper's batched questions

48-hour timebox, named jam, named ranking goal — routes to `jam-template.md`. Shaper doesn't need to ask the payment-rails question for a jam (no monetization), but does still ask about scope budget and cuts.

1. **Engine and starter kit** — Godot? Unity? Web? Do you have a template already prepped (audio system, pause menu, build pipeline) or starting from a fresh project?
2. **Solo confirmed — what art and audio sources are you allowed by jam rules and willing to use?** (Kenney, OpenGameArt, generated, all original?)
3. **Submission targets** — web build, Windows, both? Windows-only kills LD voting reach.
4. **Scope budget hour-by-hour** — what's your honest split between concept lock, prototype, vertical slice, polish, and submission buffer?
5. **Cuts on the table — what gets dropped first / second / third when you fall behind?** And what's the absolute MVP that ships if everything else fails?
6. **Innovation top 100 ambition — what are you optimizing the design *for* to land that?** A clear theme twist, an unusual mechanic, or both?

## User's answers

1. Godot 4 + C#. I have a starter template with: pause menu, settings, audio bus, fade transitions, and an itch-ready export config. About 6 hours of value pre-saved.
2. Kenney assets and royalty-free SFX from freesound. Original music if I have time, otherwise free CC0 loops.
3. Web (HTML5) primary, Windows secondary. Both submitted to itch.
4. Hour 0–4: concept lock + paper sketch. Hour 4–18: prototype playable end-to-end. Hour 18–32: vertical slice (real content). Hour 32–46: polish + audio. Hour 46–48: build + upload buffer.
5. First to cut: original music. Second: third enemy/level type. Third: any "juice" that isn't audio. Last thing standing: one playable level with the core verb readable in 30 seconds.
6. Optimizing for Innovation. The theme twist matters more than visual polish. I want the jam page comments to mention the mechanic, not the art.

## Output brief

```markdown
## Jam name and ruleset
- Jam: Ludum Dare (compo / jam — confirm at theme drop based on time available).
- Theme: <unknown — drops Friday night>.
- Time limit: 48 hours.
- Solo or team: solo.
- Submission rules: standard LD rules. Web build strongly preferred for ranking reach. All assets must be CC-permitted; original code preferred for compo.

## Theme interpretation
<to be filled at theme drop — keep it as a paragraph that names the *twist*, not a literal restatement. Theme literal first, then one twist away from it; pick the twist that opens a mechanical hook, not just a visual reskin.>

## One-line pitch
<to be filled at hour 4 lock — one sentence; if you can't say it in one sentence, the concept isn't locked yet>

## Core verb
<the *one* thing the player does — to be filled at hour 4 lock>

## Hook (first 30 seconds)
<what makes someone in the rating queue stop scrolling and play to the end — the mechanic must be readable here, not the story>

## Ranking targets
- Categories to optimize for: Innovation (primary), Theme, Fun.
- Categories to deprioritize: Graphics, Audio. (Won't be bad — won't be load-bearing.)

## Scope budget (hour-by-hour)
- Hour 0–4: concept lock + paper sketch. End of block: one-line pitch + core verb committed.
- Hour 4–18: prototype playable end-to-end with placeholder content. End of block: full loop start→end runs without hard-coding.
- Hour 18–32: vertical slice with real content (1 level, 2 enemy types, win/lose state).
- Hour 32–46: polish + audio + readability passes.
- Hour 46–48: web + Windows build, itch page, screenshots, gameplay clip, submission. **Buffer is sacred.**

## Cuts on the table (in order)
- First to cut: original music — fall back to a CC0 loop.
- Second to cut: third enemy / level type — ship with two if needed.
- Third to cut: any "juice" that isn't audio (screen shake, particles).
- Last thing standing: one playable level with the core verb readable in 30 seconds. Title screen + clear failure state. This is what ships if everything else burns.

## Engine and stack
- Engine: Godot 4 + C#.
- Templates / starter kits already prepared: personal Godot template (pause menu, settings, audio bus, fade transitions, itch web-export config). ~6 hours of pre-saved value.
- Asset sources permitted by jam rules: Kenney CC0 art, freesound CC0 SFX, original music if time allows otherwise CC0 loops.

## Team and roles (if not solo)
- Solo. Self-imposed check-in: post a screenshot to the LD discord every 12 hours for accountability.

## Submission checklist (skeleton)
- Build target: web (HTML5) primary, Windows secondary. Both on itch.
- Title screen / credits: required (asset attribution, jam template attribution).
- Controls explained: required — on title screen and as in-game tooltip on first input.
- Itch / submission page copy ready: pitch, controls, gameplay clip, three screenshots.
- Screenshots: 3 minimum, taken from the vertical slice.
- 30-second gameplay clip: GIF or MP4 — must show the core verb, not the menu.

## Open questions
- Compo (solo, all original) or jam (any tools, any team)? Decide at theme drop based on whether the theme rewards art polish (lean jam, use Kenney) or mechanic clarity (lean compo).
- If theme drops at a bad angle for the planned starter template, willing to scrap and use a fresh project? Default: yes — template is convenience, not strategy.
```

---

**Next step:** paste this into a fresh session at theme drop with `godot-engineer` available. Concept lock fields stay `<to be filled>` until the theme is announced — fill them at hour 4 of the jam, not before.
