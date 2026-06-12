# Tool Reference

## Content Attack Brief (`scripts/content_attack_brief.py`)

Full keyword intelligence pipeline. Requires `AHREFS_TOKEN` and GSC auth.

```bash
# Run the full brief
python scripts/content_attack_brief.py
```

**What it produces:**
- Topic fingerprint from your content library
- BOFU money keywords ranked by Impact × Confidence
- Trending keywords with sparkline visualizations
- Competitor gap analysis (keywords they rank for, you don't)
- Decaying page alerts (traffic drops >30%)
- Execution pipeline (auto-create → semi-auto → team)

**Output:** Prints formatted report to stdout + saves JSON to `OUTPUT_DIR/content-attack-brief-latest.json`

---

## GSC Client (`scripts/gsc_client.py`)

Google Search Console API client. Works as CLI or importable library.

```bash
# CLI usage
python scripts/gsc_client.py --queries 50 --days 28
python scripts/gsc_client.py --striking                    # Striking distance keywords (pos 4-20)
python scripts/gsc_client.py --pages 100 --days 7
python scripts/gsc_client.py --trend                       # Daily click/impression trend
python scripts/gsc_client.py --devices                     # Mobile vs desktop split
python scripts/gsc_client.py --sites                       # List verified properties
python scripts/gsc_client.py --json --queries 25           # JSON output
```

```python
# Library usage
from gsc_client import GSCClient

gsc = GSCClient()
rows = gsc.striking_distance(days=28, min_position=4, max_position=20)
for row in rows:
    print(f"{row['keys'][0]}: pos {row['position']:.1f}, {row['impressions']} impressions")
```

---

## GSC Auth (`scripts/gsc_auth.py`)

One-time OAuth setup for Google Search Console access.

```bash
python scripts/gsc_auth.py
# Opens browser → Google Sign-In → saves token locally
```

---

## Trend Scout (`scripts/trend_scout.py`)

Multi-source trend detection. No API keys required for basic functionality.

```bash
python scripts/trend_scout.py
```

**Sources:** Google Trends RSS, Hacker News, Reddit, X/Twitter (needs `BRAVE_API_KEY`)

**Output:** Prints summary + saves JSON to `OUTPUT_DIR/flash-trends-latest.json` and markdown report.
