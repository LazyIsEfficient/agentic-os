# Configuration and Scoring Model

## Configuration

All scripts read from environment variables. Copy `.env.example` to `.env` and fill in your values.

Required:
- `GSC_SITE_URL` — your Google Search Console property URL
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` — for GSC OAuth
- `YOUR_DOMAIN` — your root domain

Optional:
- `AHREFS_TOKEN` — enables Ahrefs keyword data and competitor analysis
- `COMPETITORS` — comma-separated competitor domains
- `BRAVE_API_KEY` — enables X/Twitter trend scanning
- `CONTENT_VERTICALS` — comma-separated topics for trend relevance scoring
- `TREND_SUBREDDITS` — comma-separated subreddits to monitor

## Scoring Model

Keywords are scored on two axes:

**Impact (0-10):** Volume + CPC + Funnel Stage + Trend direction
**Confidence (0-10):** Keyword Difficulty + Current ranking position + Topic authority

**Priority = Impact × Confidence** (max 100)

## Funnel Classification

- **BOFU:** Commercial/transactional intent, or keywords containing "agency", "services", "pricing", "best", "vs", "hire"
- **MOFU:** Informational with buying signals — "how to", "guide", "roi", "case study"
- **TOFU:** Pure informational

## Recommended Workflow

1. **Weekly:** Run `scripts/content_attack_brief.py` for the full intelligence report
2. **Daily:** Run `scripts/gsc_client.py --striking` to monitor striking distance keywords
3. **2x/week:** Run `scripts/trend_scout.py` to catch trending topics early
4. **Monthly:** Review competitor gaps and adjust `COMPETITORS` list

## Dependencies

```bash
pip install -r requirements.txt
```
