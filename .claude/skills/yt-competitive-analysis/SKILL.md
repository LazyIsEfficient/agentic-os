---
name: yt-competitive-analysis
description: >-
  Analyze YouTube channels for outlier videos and packaging patterns. Identifies
  what's working (2x+ average views) across any set of channels. Use when asked for
  YouTube competitive analysis, viral video patterns, or packaging/title inspiration.
when_to_use: |
  Use when asked to analyze YouTube channels for outlier videos, identify viral video patterns, find packaging or title inspiration from specific creators, or track competitor YouTube performance. Requires a YouTube Data API v3 key.

  Not when: the task is scripting a YouTube Short — use yt-shorts-script. Not when the task is producing the full Short end-to-end (record + assemble) — use yt-shorts-pipeline. Not when the task is competitive analysis for non-YouTube platforms — use a general research approach.
---

# YouTube Competitive Analysis

Outlier detection and packaging pattern extraction for YouTube channels.

## When to Use

- User asks for YouTube competitive analysis
- User wants to find viral video patterns
- User wants packaging/title inspiration from specific creators
- User wants to track competitor YouTube performance

## Prerequisites

- YouTube Data API v3 key set as `$YOUTUBE_API_KEY`

## Usage

```bash
# Analyze specific channels
python3 analyze.py "$YOUTUBE_API_KEY" --channels "@handle1,@handle2" --days 30

# Use predefined sets
python3 analyze.py "$YOUTUBE_API_KEY" --set ai
python3 analyze.py "$YOUTUBE_API_KEY" --set business
python3 analyze.py "$YOUTUBE_API_KEY" --set both

# Export formats
python3 analyze.py "$YOUTUBE_API_KEY" --set both --output json
python3 analyze.py "$YOUTUBE_API_KEY" --set both --output console
```

## Predefined Channel Sets

**AI Creators:** Jeff Su, Alex Finn, Riley Brown, Dan Martell, Matt Wolfe, Nate Herk, Grace Leung, Matt Berman

**Business Creators:** Alex Hormozi, Gary Vaynerchuk, Patrick Bet-David, Codie Sanchez, Leila Hormozi, Iman Gadzhi, My First Million

## Output Interpretation

- **Multiplier**: Times above channel average (2.0x = double normal)
- **Outlier threshold**: 2x average. Study anything above this.
- **Title patterns**: Common words in outlier titles indicate proven formats
- **Cadence**: Videos per week. Higher cadence creators may have lower per-video averages.

## Packaging Skeletons (Proven Formats)

**Long-form:**
- "X, Clearly Explained"
- "X hours of Y in Z minutes"
- "The Laziest Way to X"
- "Give me X minutes and I'll Y"
- "X INSANE Use Cases for Y"

**Shorts:**
- "2024 vs 2025 X" (year comparison)
- "Bad Good Great X" (tier ranking)
- "Stop doing X, do Y instead" (contrarian)
