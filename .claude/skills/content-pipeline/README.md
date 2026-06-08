# Content Pipeline

Script-driven content production: ingest raw source, repurpose it into platform-native drafts, and gate the drafts before publish. Non-interactive Python; chain the stages or run any one standalone.

```
quote-mining ─┐
              ├─► atoms ─► content-transform ─► drafts ─► quality-scorer ─► quality-gate ─► publish
editorial-brain ┘
```

See [SKILL.md](SKILL.md) for the agent contract and per-stage usage.

## Scripts

| Script | Does |
|--------|------|
| `scripts/quote-mining-engine.py` | Scan podcast RSS feeds + meeting notes for quotable, contrarian, viral-worthy moments |
| `scripts/editorial-brain.py` | Two-pass LLM clip discovery in video transcripts; only 90+ clips get cut |
| `scripts/content-transform.py` | Repurpose long-form atoms into X / LinkedIn / YouTube Short / newsletter drafts |
| `scripts/content-quality-scorer.py` | Heuristic 5-dimension batch scorer (voice, specificity, AI-slop, length, engagement) |
| `scripts/content-quality-gate.py` | CI-style publish filter that runs the scorer and drops drafts below threshold |

## Setup

```bash
pip install -r requirements.txt   # anthropic, feedparser
cp .env.example .env              # set ANTHROPIC_API_KEY; configure optional feeds/voice
```

Data lands in `./data/` by default (`CONTENT_OPS_DATA_DIR` to override). Video cutting in `editorial-brain.py` additionally needs `yt-dlp` + `ffmpeg`.

## Cross-skill dependency

`content-transform.py`'s optional in-loop expert panel reuses the sibling [`content-ops`](../content-ops/SKILL.md) skill's `experts/` panels and `scoring-rubrics/content-quality.md` rather than duplicating them. Path resolves to `../content-ops/` by default; override with `CONTENT_OPS_SKILL_DIR`.

## License

MIT
