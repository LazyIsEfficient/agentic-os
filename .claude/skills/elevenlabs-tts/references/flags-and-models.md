# ElevenLabs TTS — Flags and Models

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--text` | stdin | Spoken text to synthesize |
| `--voice-id` | `JBFqnCBsd6RMkjVDRZzb` (George) | ElevenLabs voice ID |
| `--model` | `eleven_multilingual_v2` | Model to use |
| `--output` | `output.mp3` | Output file path |
| `--list-voices` | — | Print all available voices and exit |

## Models

| Model ID | Quality | Speed | Languages |
|----------|---------|-------|-----------|
| `eleven_multilingual_v2` | Best | Standard | 29 |
| `eleven_turbo_v2_5` | Good | Fast | 32 |
| `eleven_flash_v2_5` | Good | Ultra-fast, 50% cheaper | 32 |

Default is `eleven_multilingual_v2` — best quality for pre-recorded content.
Use `eleven_flash_v2_5` if generating many audio files and cost is a concern.

## Integration with yt-shorts-script

A Shorts script produced by `yt-shorts-script` contains `SAY:` lines. To generate audio from a script, extract the SAY lines and concatenate them in order.

```bash
# Extract all SAY: lines, strip the label, join into one block
grep '^SAY:\|^\[' script.txt | grep 'SAY:' | sed 's/^SAY: "//' | sed 's/"$//' | tr '\n' ' ' | npm run tts -- --output narration.mp3
```

Or provide the full narration text directly:

```bash
npm run tts -- --text "Most engineers skip CLAUDE.md. It lives at your repo root..." --output hook.mp3
```

## What this skill does NOT do

- Real-time streaming playback — the script writes to file only
- Voice cloning or custom voice creation — use the ElevenLabs dashboard
- Automatic SAY line extraction — extract manually or via grep before passing text
- Captioning or subtitle generation — separate step (Whisper or similar)
