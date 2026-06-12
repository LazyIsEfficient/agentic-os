# Tool Reference

## Gong-to-Insight Pipeline (`scripts/gong_insight_pipeline.py`)

Extracts structured intelligence from sales call transcripts. Works with Gong API or plain transcript files.

```bash
# Analyze a single transcript file
python scripts/gong_insight_pipeline.py --file transcript.txt

# Analyze multiple transcript files
python scripts/gong_insight_pipeline.py --dir ./transcripts/

# Pull recent calls from Gong API (last 7 days)
python scripts/gong_insight_pipeline.py --gong --days 7

# Pull specific call by ID
python scripts/gong_insight_pipeline.py --gong --call-id abc123

# Output as JSON file
python scripts/gong_insight_pipeline.py --file transcript.txt --output insights.json

# Generate content topics from recurring objections
python scripts/gong_insight_pipeline.py --dir ./transcripts/ --content-topics

# Generate follow-up suggestions for outbound sequences
python scripts/gong_insight_pipeline.py --file transcript.txt --follow-ups
```

**What it extracts:**
- Objections (categorized: pricing, timing, competition, authority, need)
- Buying signals (budget confirmed, timeline mentioned, decision maker engaged, champion identified)
- Competitive mentions (who was mentioned, context: positive/negative/neutral)
- Pricing discussions (anchors, pushback, willingness indicators)
- Content topic suggestions from recurring objection patterns
- Personalized follow-up drafts based on call context

**Output:** Structured JSON to stdout or file. Each call produces an `insights` object with `objections`, `buying_signals`, `competitive_mentions`, `pricing_discussions`, `content_topics`, and `follow_ups` arrays.

---

## Revenue Attribution Mapper (`scripts/revenue_attribution.py`)

Maps content pieces to pipeline and closed revenue. Proves content ROI with first-touch and multi-touch attribution.

```bash
# Run full attribution report (GA4 + HubSpot)
python scripts/revenue_attribution.py --report

# First-touch attribution only
python scripts/revenue_attribution.py --report --model first-touch

# Multi-touch (linear) attribution
python scripts/revenue_attribution.py --report --model linear

# Time-decay attribution
python scripts/revenue_attribution.py --report --model time-decay

# Filter by date range
python scripts/revenue_attribution.py --report --start 2025-01-01 --end 2025-03-31

# Calculate cost-per-acquisition by content type
python scripts/revenue_attribution.py --cpa --costs content_costs.json

# Identify content gaps in the buyer journey
python scripts/revenue_attribution.py --gaps

# Output as JSON
python scripts/revenue_attribution.py --report --json --output attribution.json
```

**What it produces:**
- Content-to-revenue mapping (which blog posts, videos, podcasts drove deals)
- First-touch, linear, and time-decay attribution models
- Cost-per-acquisition by content type (blog, video, podcast, webinar)
- Content ROI report with revenue per piece
- Content gap analysis (funnel stages with no attribution)
- Top-performing content ranked by attributed revenue

**Data sources:** GA4 (page paths, sessions, conversions) + HubSpot (deals, touchpoints, close dates)

---

## Multi-Source Client Report Generator (`scripts/client_report_generator.py`)

Generates unified client-ready BI reports from GA4, HubSpot, Ahrefs, and Gong.

```bash
# Generate full client report
python scripts/client_report_generator.py --client "Acme Corp"

# Specify date range
python scripts/client_report_generator.py --client "Acme Corp" --start 2025-03-01 --end 2025-03-31

# Output as markdown
python scripts/client_report_generator.py --client "Acme Corp" --format markdown --output report.md

# Output as JSON (for rendering in slides/dashboards)
python scripts/client_report_generator.py --client "Acme Corp" --format json --output report.json

# Skip specific data sources
python scripts/client_report_generator.py --client "Acme Corp" --skip gong
python scripts/client_report_generator.py --client "Acme Corp" --skip ahrefs,gong

# Enable anomaly detection
python scripts/client_report_generator.py --client "Acme Corp" --anomalies

# Compare to previous period
python scripts/client_report_generator.py --client "Acme Corp" --compare previous-month
```

**What it produces:**
- Executive summary with key metrics and period-over-period changes
- Traffic section: sessions, users, top pages, channel breakdown (GA4)
- Pipeline section: deals created, moved, closed, revenue (HubSpot)
- SEO section: keyword rankings, backlinks, domain rating changes (Ahrefs)
- Call quality section: talk ratios, objection frequency, win rates (Gong)
- Anomaly flags: unusual spikes/drops with severity and context
- Output as structured markdown or JSON
