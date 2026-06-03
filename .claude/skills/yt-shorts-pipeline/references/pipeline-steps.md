# Pipeline Steps

## Full Pipeline

```
yt-shorts-script  →  script.txt  (SAY + SHOW lines with timing)
     ↓
shorts:record     →  recording.mp4  (silent screen capture, ~60s)
     ↓
shorts:assemble   →  short.mp4  (narration + blur-pad 9:16 + burned captions)
```

---

## Step 1 — Generate the script

Use the `yt-shorts-script` skill (or `/yt-short` command) to produce a script
file. Save it as a `.txt` file in the working directory, e.g. `my-topic.txt`.

The script must contain `SAY: "..."` lines — the assembler extracts these in
order to build the narration.

---

## Step 2 — Record your screen (silent)

```bash
# List displays to find the right index (usually 1 on MacBook Pro)
npm run shorts:record -- --list-displays

# Record with shot list printed from script
npm run shorts:record -- --script my-topic.txt --output recording.mp4

# Record without script
npm run shorts:record -- --output recording.mp4
```

- Recording is **silent** — no microphone, no narration during recording.
  Follow the SHOW notes printed at the start as your shot list.
- Target length: match the script's timing (60s for a 60s Short).
- Press **Ctrl+C** to stop.
- If the display index is wrong (black screen or wrong display), run
  `--list-displays` and pass `--display <index>`.

---

## Step 3 — Assemble the Short

```bash
npm run shorts:assemble -- \
  --script my-topic.txt \
  --video recording.mp4 \
  --output my-topic-short.mp4
```

What this does automatically:
1. Extracts all `SAY:` lines from the script in order
2. Calls ElevenLabs `convertWithTimestamps` → `my-topic-narration.mp3`
3. Converts character-level timing → word-grouped SRT → `my-topic-captions.srt`
4. FFmpeg: blur-pad landscape recording to 1080×1920 (9:16)
5. Overlays narration audio, burns captions (white bold, centred bottom)
6. Outputs `my-topic-short.mp4`

If caption burning fails (libass issue), the assembler retries without captions
and keeps the `.srt` file for manual import.

---

## Re-running Steps Independently

Re-record without regenerating narration:
```bash
npm run shorts:assemble -- \
  --audio my-topic-narration.mp3 \
  --srt my-topic-captions.srt \
  --video new-recording.mp4 \
  --output my-topic-short-v2.mp4
```

Regenerate narration only:
```bash
npm run tts -- --text "your narration text" --output narration.mp3
```
