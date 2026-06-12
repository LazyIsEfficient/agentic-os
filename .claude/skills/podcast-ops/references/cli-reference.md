# CLI Reference and Environment Variables

## CLI Commands

```bash
# Process latest episode from RSS feed
# Replace <YOUR_RSS_FEED_URL> with your podcast's real feed URL.
python scripts/podcast_pipeline.py --rss "<YOUR_RSS_FEED_URL>"

# Process a local transcript
python scripts/podcast_pipeline.py --transcript episode-42.txt

# Batch process last 5 episodes
python scripts/podcast_pipeline.py --batch "<YOUR_RSS_FEED_URL>" --episodes 5

# Generate weekly calendar from existing outputs
python scripts/podcast_pipeline.py --calendar

# Process with custom dedup window
python scripts/podcast_pipeline.py --rss "<YOUR_RSS_FEED_URL>" --dedup-days 60

# Process and only keep 80+ viral score content
python scripts/podcast_pipeline.py --rss "<YOUR_RSS_FEED_URL>" --min-score 80
```

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes (for Whisper) | OpenAI API key for audio transcription |
| `ANTHROPIC_API_KEY` | Yes (for generation) | Anthropic API key for content generation |
| `OPENAI_LLM_KEY` | Optional | Separate OpenAI key if using GPT for generation instead |

---

## Reference Files

| File | Purpose |
|------|---------|
| `scripts/podcast_pipeline.py` | Main pipeline script |
| `requirements.txt` | Python dependencies |
| `README.md` | Setup and usage guide |
