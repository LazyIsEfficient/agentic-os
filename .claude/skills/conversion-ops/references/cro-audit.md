# CRO Audit Tool (`scripts/cro_audit.py`)

Fetches a landing page and scores it across 8 conversion dimensions. No headless browser needed.

## Usage

```bash
# Single URL audit
python scripts/cro_audit.py --url https://example.com/landing-page

# Batch mode — multiple URLs
python scripts/cro_audit.py --urls https://example.com/page1 https://example.com/page2

# URLs from a file (one per line)
python scripts/cro_audit.py --file urls.txt

# Specify industry for benchmark comparison
python scripts/cro_audit.py --url https://example.com --industry saas

# JSON output
python scripts/cro_audit.py --url https://example.com --json

# Save report to file
python scripts/cro_audit.py --url https://example.com --output report.json
```

## Scoring Dimensions (each 0–100)

1. **Headline Clarity** — Is the value prop obvious in <5 seconds?
2. **CTA Visibility** — Are CTAs prominent, contrasting, above the fold?
3. **Social Proof** — Testimonials, logos, case studies, numbers?
4. **Urgency** — Scarcity, deadlines, limited offers?
5. **Trust Signals** — Security badges, guarantees, privacy, certifications?
6. **Form Friction** — How many fields? Is the form intimidating?
7. **Mobile Responsiveness** — Viewport meta, responsive patterns, touch targets?
8. **Page Speed Indicators** — Image optimization, script count, resource size?

**Overall CRO Score** = Weighted average across all 8 dimensions.

## Output

- Per-dimension score with specific findings
- Priority fixes ranked by impact
- Before/after suggestions for each issue
- Industry benchmark comparison
- Overall letter grade (A+ through F)

## Supported Industries

`saas`, `ecommerce`, `agency`, `finance`, `healthcare`, `education`, `b2b`, `general`
