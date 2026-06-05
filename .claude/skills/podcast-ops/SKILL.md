---
name: podcast-ops
description: >-
  Podcast-to-Everything content pipeline. Takes a podcast RSS feed or raw
  transcript and generates a full cross-platform content calendar: short-form
  video clips, Twitter/X threads, LinkedIn articles, newsletter sections, quote
  cards, blog outlines with SEO keywords, and YouTube Shorts/TikTok scripts.
  Scores each piece by viral potential (novelty × controversy × utility) and
  deduplicates against recent output. Use when asked to: "repurpose this podcast",
  "turn this episode into content", "podcast content calendar", "extract clips
  from this episode", "podcast to social", "content from RSS feed", "batch
  process episodes", or any request to turn podcast/audio content into a
  multi-platform content plan.
when_to_use: |
  Use when the input is a podcast RSS feed or transcript and the goal is to generate a multi-platform content calendar — short-form video clips, Twitter/X threads, LinkedIn articles, newsletter sections, quote cards, blog outlines, or YouTube Shorts/TikTok scripts. Also use for batch processing multiple episodes or scoring content by viral potential.

  Not when: the content source is not a podcast episode and there is no transcript or RSS feed — use `content-ops` or `blog-post-author` for general content creation. Not when only a single content format (e.g. just a blog post) is needed from the episode — use the relevant single-format skill directly.
---

# Podcast Ops

Turns podcast episodes into a full content calendar across every platform. One episode in, 15–20 content pieces out — scored, deduplicated, and scheduled.

## Core rules

1. Ingest via RSS feed, raw transcript, or batch mode — see `references/pipeline-steps.md` Step 1 for all three paths.
2. Run editorial brain extraction: pull narrative arcs, quotes, controversial takes, data points, stories, frameworks, and predictions.
3. Generate all 7 content types per episode: video clips, X threads, LinkedIn article, newsletter section, quote cards, blog outline, Shorts/TikTok script.
4. Score every piece: Viral Score = (Novelty × 0.4) + (Controversy × 0.3) + (Utility × 0.3). Cut anything below 40.
5. Dedup within batch and against last 30 days; flag >70% overlap pairs.
6. Assemble into a weekly calendar with platform-specific scheduling rules.
7. Write all output to `output/` directory with episodes/, calendar/, content_history.json, and pipeline_log.json.

## References

- [references/pipeline-steps.md](references/pipeline-steps.md) — full 7-step procedure: ingest, analysis, content generation, scoring, dedup, calendar, output
- [references/cli-reference.md](references/cli-reference.md) — CLI commands and environment variables
