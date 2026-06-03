# Options Reference

## shorts:record

| Flag | Default | Description |
|------|---------|-------------|
| `--output` | `recording.mp4` | Output path |
| `--display` | `1` | AVFoundation display index |
| `--script` | — | Print shot list from script file before recording |
| `--list-displays` | — | List available capture devices and exit |

## shorts:assemble

| Flag | Default | Description |
|------|---------|-------------|
| `--video` | required | Path to screen recording |
| `--script` | — | Script file (SAY lines → narration) |
| `--audio` | — | Pre-generated narration MP3 (skips ElevenLabs) |
| `--srt` | — | Pre-generated captions SRT (skips timing conversion) |
| `--output` | `short.mp4` | Final MP4 path |
| `--voice-id` | `JBFqnCBsd6RMkjVDRZzb` (George) | ElevenLabs voice |
| `--model` | `eleven_multilingual_v2` | ElevenLabs model |

## Output Files

For `--output my-topic-short.mp4`, the assembler also saves:
- `my-topic-narration.mp3` — standalone narration audio
- `my-topic-captions.srt` — captions for manual import if needed

Store finished Shorts under `public/shorts/` or a working directory outside
the repo. Don't commit MP4s or MP3s.

## What This Pipeline Does NOT Do

- Talking head or face-cam recording — screen-record only
- Upload to YouTube — separate step
- Thumbnail generation — see `yt-competitive-analysis` for packaging patterns
- Background music — add manually in CapCut if wanted
