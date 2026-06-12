# Recommended Workflow

1. **Weekly:** Run `scripts/cro_audit.py` on your top landing pages to track CRO scores over time
2. **Post-survey:** Run `scripts/survey_lead_magnet.py` to turn survey data into content strategy
3. **Pre-launch:** Audit new landing pages before driving paid traffic
4. **Monthly:** Batch audit competitor landing pages to benchmark against

## Configuration

No API keys required. Both tools work with local analysis only.

Optional environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `USER_AGENT` | No | Custom user agent for page fetching (default provided) |
| `REQUEST_TIMEOUT` | No | HTTP timeout in seconds (default: 15) |

## Dependencies

```bash
pip install -r requirements.txt
```
