---
name: yt-shorts-pipeline
description: >-
  End-to-end YouTube Shorts production pipeline: script → screen record →
  narration + captions → assembled 9:16 MP4. Orchestrates yt-shorts-script,
  shorts-record.mjs, and shorts-assemble.mjs. Use when producing a Short
  from a topic through to a finished video file. Triggers on "make a Short",
  "produce this Short", "run the Shorts pipeline", "assemble the Short",
  "record a Short", "generate the video". For script-only work see
  yt-shorts-script. For audio-only see elevenlabs-tts.
when_to_use: |
  Use when producing a YouTube Short end-to-end from a topic to a finished 9:16 MP4 file: generating the script, recording the screen, and assembling narration + captions via ElevenLabs + FFmpeg. Triggers on "make a Short", "produce this Short", "run the Shorts pipeline", "assemble the Short", "record a Short", or "generate the video".

  Not when: the task is script-only with no video output — use yt-shorts-script. Not when the task is audio-only TTS generation — use elevenlabs-tts. Not when the task is analyzing YouTube channels for packaging patterns before scripting — use yt-competitive-analysis.
---

# YouTube Shorts Pipeline

Screen-record + AI narration + auto-captions → 9:16 MP4. The only human step is the screen-record itself. Everything else is automated.

All scripts run from your project root with env loaded from `.env.local` (`ELEVEN_API_KEY` required, `ffmpeg` required).

## Prerequisites

- `ELEVEN_API_KEY` in `.env.local`
- `ffmpeg` installed (`brew install ffmpeg`)
- Node.js ≥ 22
- `@elevenlabs/elevenlabs-js` in `package.json`

## Quick Reference

```
yt-shorts-script  →  script.txt
shorts:record     →  recording.mp4
shorts:assemble   →  short.mp4
```

## References

- [references/pipeline-steps.md](references/pipeline-steps.md) — step-by-step instructions for all three pipeline stages with re-run patterns
- [references/options-reference.md](references/options-reference.md) — full CLI flag tables for shorts:record and shorts:assemble, output file conventions
