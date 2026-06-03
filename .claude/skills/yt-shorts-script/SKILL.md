---
name: yt-shorts-script
description: >-
  Generate a YouTube Shorts script from a topic and format choice. Outputs a
  60s primary script + 30s condensed cut, both with HOOK/BODY/CTA sections,
  per-line timing markers, and per-line visual direction notes. Three supported
  formats: talking-head, screen-record, text-on-screen. Engineering/AI audience
  voice. Triggers on `/yt-short`, "write a Shorts script", "YouTube Short on",
  "60-second script", "script for a Short", "script this Short". For channel
  research and outlier video patterns before scripting, run yt-competitive-analysis
  first. For social promotion posts after filming, see social-growth. For long-form
  X articles see x-longform-post.
when_to_use: |
  Use when drafting a YouTube Shorts script from a topic and format choice (talking-head, screen-record, or text-on-screen). Produces a 60s primary script and 30s condensed cut with HOOK/BODY/CTA sections, per-line timing markers, and visual direction notes. Triggers on "/yt-short", "write a Shorts script", "YouTube Short on", "60-second script", "script for a Short", or "script this Short".

  Not when: the task is the full end-to-end pipeline including recording and assembly — use yt-shorts-pipeline. Not when the task is channel research and outlier pattern analysis before scripting — run yt-competitive-analysis first. Not when the task is a long-form X article — use x-longform-post. Not when the task is social promotion posts after filming — use social-growth.
---

# YouTube Shorts Script Generator

Topic-first. You give a topic, angle, and format — you get a film-ready 60s script plus a 30s cut. Every line is ready to say or show. No filler, no "adjust as needed."

## Input

- **Topic**: What the Short is about (one sentence max)
- **Angle**: The specific claim or take — contrarian is stronger. Stop and ask if missing.
- **Format**: One of `talking-head`, `screen-record`, `text-on-screen`. Ask if missing.
- **Source material** (optional): A real number, incident, or tool to anchor the script

## Core rules

1. Always produce two blocks: 60s script then 30s cut, per `references/output-format.md`.
2. Choose format before scripting — format determines all SHOW notes; see `references/format-types.md`.
3. Follow the 8-step procedure in `references/procedure.md` — hook first, body beats, CTA, timing, SHOW notes, 30s cut, humanizer.
4. Timing is a hard constraint: 2.5–3 words/second. Count words; recount after every rewrite.
5. Run the mandatory humanizer pass on all SAY lines per `references/voice-and-humanizer.md`. Target 90+.
6. Use specific numbers, real tool names, real decisions — never generic observations.
7. CTA is one line only. Never "If you found this helpful…"

## What this skill does NOT do

- Repurpose from a Substack post — topic-first only
- B-roll narration format, 90s variant, or thumbnail copy
- Auto-post or schedule to any platform

## References

- [references/format-types.md](references/format-types.md) — talking-head, screen-record, text-on-screen SHOW note specs
- [references/output-format.md](references/output-format.md) — 60s/30s script template with timing markers
- [references/procedure.md](references/procedure.md) — 8-step script writing procedure
- [references/voice-and-humanizer.md](references/voice-and-humanizer.md) — SAY line voice rules and humanizer pass
- [references/script-examples.md](references/script-examples.md) — complete worked examples for all three formats
