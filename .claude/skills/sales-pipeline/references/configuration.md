# Sales Pipeline — Customization Guide

## Key Customization Points

- **Intent scoring**: Edit `PAGE_INTENT_SCORES` dict in `rb2b_webhook_ingest.py` to match your URL patterns
- **Agency detection**: Edit `AGENCY_KEYWORDS_*` dicts in `rb2b_instantly_router.py` for your market
- **Loss reason scoring**: Edit `LOSS_REASON_BONUS` dict in `deal_resurrector.py` for your close reasons
- **Signal queries**: Edit `SEARCH_QUERIES` in `trigger_prospector.py` for your target market
- **Campaign routing**: Edit `data/campaigns.json` with your Instantly campaign UUIDs
