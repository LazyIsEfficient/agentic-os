# Configuration

All scripts read from environment variables. Copy `.env.example` to `.env` and fill in your values.

## Required Environment Variables

| Variable | Used By | Description |
|----------|---------|-------------|
| `GONG_API_KEY` | Gong Pipeline, Client Report | Gong API access key |
| `GONG_API_BASE_URL` | Gong Pipeline, Client Report | Gong API base URL |
| `HUBSPOT_API_KEY` | Attribution, Client Report | HubSpot private app token |
| `GA4_PROPERTY_ID` | Attribution, Client Report | GA4 property ID |
| `GA4_CREDENTIALS_JSON` | Attribution, Client Report | Path to GA4 service account JSON |

## Optional Environment Variables

| Variable | Used By | Description |
|----------|---------|-------------|
| `AHREFS_TOKEN` | Client Report | Ahrefs API token |
| `YOUR_DOMAIN` | Client Report | Root domain for Ahrefs SEO lookup (default: `example.com`) |
| `OUTPUT_DIR` | All | Directory for output files (default: `./output`) |

## Data Flow

```
Gong Transcripts → Insight Pipeline → Objections, Signals, Competitors → Content Topics + Follow-ups
GA4 + HubSpot   → Attribution Mapper → Content ROI, CPA, Gap Analysis → Revenue Proof
GA4 + HubSpot + Ahrefs + Gong → Client Report → Executive Summary + Anomalies → Client Deliverable
```

## Recommended Workflow

1. **Weekly:** Run `scripts/gong_insight_pipeline.py --gong --days 7` to extract call intelligence
2. **Monthly:** Run `scripts/revenue_attribution.py --report` to prove content ROI
3. **Monthly:** Run `scripts/client_report_generator.py` for each client deliverable
4. **Quarterly:** Run `scripts/revenue_attribution.py --gaps` to find content gaps
5. **Ongoing:** Feed Gong insight follow-ups into outbound sequences

## Dependencies

```bash
pip install -r requirements.txt
```
