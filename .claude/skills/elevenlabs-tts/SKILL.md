---
name: elevenlabs-tts
description: >-
  Convert text to speech using ElevenLabs via the project's tts.mjs script.
  Outputs an MP3 file. Use when generating audio from a YouTube Shorts script,
  voiceover from SAY lines, or any text that needs narration. Requires
  ELEVEN_API_KEY in .env.local. Run from your project root.
  Triggers on "generate audio", "text to speech", "TTS", "voiceover", "read
  this script aloud", "convert to audio". For script generation upstream, see
  yt-shorts-script.
when_to_use: |
  Use when generating audio narration from text — including YouTube Shorts scripts (SAY: lines),
  voiceovers, or any text that needs to be converted to an MP3 file. Triggers on "generate
  audio", "text to speech", "TTS", "voiceover", "read this script aloud", or "convert to audio".

  Not when: the goal is generating the script itself — use `yt-shorts-script` upstream first.
  Not when: real-time streaming playback, voice cloning, or captioning is needed — those are
  outside the scope of this skill.
---

# ElevenLabs Text-to-Speech

Converts text to an MP3 using ElevenLabs. The script lives at `scripts/tts.mjs` in your project. Always run from your project root.

## Prerequisites

- `ELEVEN_API_KEY` set in `.env.local`
- `@elevenlabs/elevenlabs-js` installed
- Node.js ≥ 22

## Basic Usage

```bash
# From text argument
npm run tts -- --text "Your text here" --output out.mp3

# From stdin (useful for piping)
echo "Your text here" | npm run tts -- --output out.mp3

# Custom voice
npm run tts -- --text "Hello" --voice-id <voice-id> --output out.mp3

# List available voices (requires voices_read permission on the API key)
npm run tts -- --list-voices
```

See [references/flags-and-models.md](references/flags-and-models.md) for the full flags table, model comparison, yt-shorts-script integration example, and what this skill does NOT do.

## Output Location

Store generated audio files under `public/audio/` or a working directory outside the repo. Don't commit MP3s.
