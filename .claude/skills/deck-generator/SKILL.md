---
name: deck-generator
description: Generate professional presentations with AI-generated images. Use when asked to create a deck, presentation, pitch deck, or slides. Supports style presets (whiteboard, corporate, minimalist, etc). Uses Imagen 4.0 API for image generation and Google Slides API for assembly. Produces full decks from markdown content specs in minutes.
when_to_use: |
  Use when asked to create a deck, presentation, pitch deck, or slides — including converting a
  game concept one-pager into a publisher/investor pitch deck. Accepts a topic, a markdown file,
  or a structured content spec as input, and produces AI-generated slide images in a consistent
  visual style.

  Not when: the goal is a written document rather than a visual presentation — use
  [documentation-and-adrs](../documentation-and-adrs/SKILL.md) or [documentation-writer](../documentation-writer/SKILL.md) instead.
---

# Deck Generator

Generate complete presentations where every slide is an AI-generated image in a consistent visual style.

## Quick Start

1. Read the content spec (user provides slide content or a markdown file)
2. Read [references/workflow.md](references/workflow.md) to pick or customize a visual style (Step 2: Style Selection)
3. Run `scripts/generate-deck.py` with content + style

See [references/workflow.md](references/workflow.md) for the full step-by-step workflow including:
- Content spec normalization (per-slide structure)
- Style presets (`whiteboard`, `corporate`, `minimalist`, `dark-tech`, `playful`, `editorial`)
- CLI usage and flags
- Regenerating individual slides
- Content JSON format
- Google Slides integration (flags accepted but NOT YET IMPLEMENTED — local images only)
- Cost (~4¢/image), speed (~2 min for 14 slides), and auth details

## Related skills

- [course-author](../course-author/SKILL.md) — feeds an authored lesson in as the markdown content spec when a lesson is delivered as slides
