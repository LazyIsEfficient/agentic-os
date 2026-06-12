# Autoresearch for Marketing

**Karpathy-inspired iterative optimization loops applied to conversion content.**

Inspired by Andrej Karpathy's [autoresearch](https://github.com/karpathy/autoresearch) concept — autonomous research loops that generate, evaluate, and evolve solutions — this skill applies the same pattern to marketing copy. Instead of optimizing ML experiments, it optimizes landing pages, emails, ads, and forms.

## How It Works

```
┌────────────┐    ┌─────────────┐    ┌──────────┐
│  Generate  │───►│  Score with  │───►│  Evolve  │
│ 10 variants│    │ 5-expert     │    │ top 3    │
└────────────┘    │ panel        │    └────┬─────┘
                  └─────────────┘         │
                        ▲                 │
                        └─────────────────┘
                          repeat until 85+
```

1. **Generate** 10+ variants of each content element (headline, CTA, body copy, etc.)
2. **Score** every variant with a 5-persona expert panel (CMO, skeptical founder, CRO expert, copywriter, your CEO)
3. **Evolve** the top performers — analyze what won, push those patterns further
4. **Cross-breed** winning elements into complete units
5. **Output** the best version + full experiment log

No traffic needed. No A/B test infrastructure. Minutes instead of weeks.

## Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Set your API key
export ANTHROPIC_API_KEY="your-api-key-here"

# 3. Run the optimizer
python3 scripts/autoresearch.py --input landing-page.html --type landing_page --min-score 85

# 4. Check results
cat data/landing-page-optimization-report.md
```

## What It Optimizes

| Content Type | Elements | Score Dimensions |
|-------------|----------|-----------------|
| Landing Pages | Headline, subheadline, CTA, problem section, social proof | First impression, clarity, trust, urgency, conversion |
| Email Sequences | Subject, opening, body, CTA, PS line | Open rate, read rate, click rate, reply rate, spam risk |
| Ad Copy | Headline, description, CTA | Scroll-stopping, clarity, click-worthiness, relevance, differentiation |
| Form Pages | Headline, subtext, bullets, button, field order | First impression, trust, completion likelihood, lead quality |

## The Expert Panel

Every variant is scored by 5 simulated experts:

1. **CMO** — "Would this make me stop and engage?"
2. **Skeptical Founder** — "Do I believe this?"
3. **CRO Expert** — "Is this clear and action-driving?"
4. **Senior Copywriter** — "Is this compelling and differentiated?"
5. **Your CEO** — Configurable. Define their priorities and tone inline when you run the panel (e.g. "direct, ROI-obsessed, allergic to jargon")

## Output Files

Each run produces:
- `{name}-optimized.{ext}` — The winning content
- `data/{name}-experiments.json` — Full experiment log with all scores
- `data/{name}-optimization-report.md` — Human-readable summary

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `--min-score` | 80 | Target score (stops when reached) |
| `--rounds` | 3 | Max optimization rounds |
| `--variants` | 10 | Variants per round |
| `--elements` | all | Specific elements to optimize |
| `--type` | auto | Content type override |

## Credit

Concept inspired by [Andrej Karpathy's autoresearch](https://github.com/karpathy/autoresearch) — applying autonomous iterative optimization to marketing instead of ML research.

## Requirements

- Python 3.10+
- Anthropic API key (`$ANTHROPIC_API_KEY`)
- See `requirements.txt` for Python dependencies
