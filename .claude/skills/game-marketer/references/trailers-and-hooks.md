# Trailers and hooks

The trailer is the highest-leverage piece of marketing per minute of production. A great trailer outperforms a mediocre trailer by 3–5× on conversion. The hook (first 5 seconds) is most of the trailer's impact.

## The hook

The first 5 seconds answers three questions:

1. **What is this?** (genre, fantasy)
2. **Why should I keep watching?** (curiosity / promise / disruption)
3. **Is this for me?** (audience signal)

If any answer is missing, the viewer scrolls. Hook design rules:

- **Show, don't tell.** A logo + voiceover ("In a world...") loses; gameplay + a moment wins.
- **The hook is a moment, not a buildup.** Don't ramp; deliver.
- **Distinctive sensory signature** — a unique visual / audio motif the game owns. The bullet-time freeze in *SUPERHOT*. The screen-fill horde in *Vampire Survivors*. The "Red is sus" meme in *Among Us*.
- **Pattern interrupt.** Players have seen 10,000 trailers. The hook should momentarily *not look like* what they expected.

## Trailer types and their roles

### Reveal trailer
**Role:** announce the game; build anticipation; drive wishlists.
**Length:** 1:00–1:30.
**Content:** atmospheric beats; the fantasy; the wedge; minimal gameplay (sometimes).
**Hook:** mystery / pattern interrupt; the audience asks "what is this?"

### Gameplay trailer
**Role:** prove the game; convert wishlists into intent.
**Length:** 1:30–3:00.
**Content:** the verbs in action; system breadth; the wedge demonstrated; one wow moment.
**Hook:** the most striking gameplay moment in the game; "this is what you'll do."

### Launch trailer
**Role:** ship-day visibility; convert intent into purchase.
**Length:** 0:45–1:30.
**Content:** highlight reel of variety; CTA "OUT NOW"; review quotes; social proof.
**Hook:** familiar (re-uses recognizable beats) + amplified.

### Live-ops / season trailer
**Role:** announce new content; re-engage lapsed; convert pass.
**Length:** 0:45–1:30.
**Content:** new content beats; story / theme; pass progression visualized.
**Hook:** the new thing the player hasn't seen yet.

### TikTok / Shorts variant (vertical, native)
**Role:** discovery on short-form platforms.
**Length:** 0:15–0:60.
**Content:** vertical reframe; native pacing (faster cuts, captions, native music or trends); single hook + CTA.
**Hook:** within the first 1–2 seconds (much faster than horizontal); pattern-interrupt; viral-relevant.

### UA creative (paid ads)
**Role:** drive installs at target CPI.
**Length:** 0:15–0:30.
**Content:** clear hook + verb shown + CTA; multiple variants tested.
**Hook:** what survives the network's auction (data-tested, not taste-tested).

### Bumper (pre-roll, programmatic)
**Role:** brand recall.
**Length:** 0:06–0:15.
**Content:** logo + hook + CTA; nothing else.
**Hook:** the entire trailer.

## Run-of-show structure (longer trailers)

A 90-second trailer typically has this beat structure:

| Time | Beat | Purpose |
|---|---|---|
| 0:00–0:05 | Hook | Land the fantasy + verb |
| 0:05–0:15 | Show verb 1 | "What you do" |
| 0:15–0:30 | Show verb 2 + variety | Depth signal |
| 0:30–0:45 | Show meta / progression | Stickiness signal |
| 0:45–0:60 | Climax beat (set piece, boss, reveal) | Wow moment |
| 0:60–1:15 | Social / community / multiplayer (if any) | Aspiration |
| 1:15–1:25 | CTA ("OUT NOW," "WISHLIST") | Conversion |
| 1:25–1:30 | Logo + platforms | Identity |

For 30s trailers: pick 3 beats — Hook + Verb + CTA.
For 15s trailers: pick 2 beats — Hook + CTA.
For 6s bumpers: just the hook (the bumper *is* the hook).

## Music brief

Music carries 30–50% of a trailer's emotional impact. Brief includes:

- **Genre / mood** — orchestral / synthwave / lo-fi / chiptune / licensed track
- **BPM range** — fast trailers use 120–180; calm trailers use 60–90
- **Drop / sting timing** — hook lands musically at second 4–5
- **Custom score vs library track** — custom is differentiated; library is fast and cheap; licensed track is brand-amplifying but expensive

## Captions and subtitles

Many trailer viewers watch muted (mobile feeds, work, public spaces):

- **All trailers should be subtitle-friendly** — text overlays clarify what's happening even without audio
- **Music sting is replaced by visual stingers** for mute viewers
- **Localized subtitles** for major regions

## Asset pipeline (with `godot-engineer`)

Trailers need clean gameplay capture:

- **Dedicated debug build** with no UI clutter, optional cinematic camera
- **Captured at high resolution and high framerate** (4K, 60fps where possible — easier to downsample than upsample)
- **Multiple takes per beat** (so the editor has options)
- **Specific moments staged** for the trailer (the editor doesn't randomly capture; the team plays scripted scenarios)

## Performance metrics

Per trailer:

- **Watch-through rate** — % of viewers who finish (target: 30%+ on Steam, 20%+ on YouTube, 50%+ on TikTok for short-form)
- **Hook drop-off at 5s** — % who keep watching past the hook (target: <50% drop)
- **CTR on CTA** — % who click the CTA (target depends on platform; track per source)
- **Conversion to wishlist / install** by trailer source

A trailer that doesn't make it past the hook is unwatched. Front-load the value.

## Anti-patterns

- **Logo-first opening** — "STUDIO presents" wastes 3 seconds of hook
- **Buildup with no payoff** — slow musical intro that never lands a punch
- **Feature-list trailer** — "47 ships, 200 quests" with text overlays; reads like a bullet list
- **All cinematic, no gameplay** — players want to see what they'll *do*, not what the world looks like in cutscenes
- **Generic "epic" music** — feels like every other AAA trailer; no signature
- **Mismatched tone** — slick AAA trailer for an indie cozy game; or twee cozy trailer for a hardcore action game
- **CTA at the start** — "available now!" in the first 5 seconds; viewers haven't been convinced yet

## Output

For every trailer:
- Filled `trailer-brief-template.md`
- Concept / hook approved before storyboard
- Storyboard approved before edit
- Music brief delivered
- Capture session scheduled with `godot-engineer`
- Variants planned (length, aspect, platform-specific)
- Performance gates set
