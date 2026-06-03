# Configuration

## Required Environment Variables

| Variable | Description |
|----------|-------------|
| `GROWTH_ENGINE_DATA_DIR` | Data directory (default: `./data/experiments`) |
| `GROWTH_ENGINE_AGENTS` | Comma-separated agent names (default: `content,email,linkedin,seo,blog`) |

## Optional Tuning

| Variable | Default | Description |
|----------|---------|-------------|
| `HIGH_VOLUME_AGENTS` | `content,email` | Agents needing only 10 samples/variant |
| `LOW_VOLUME_AGENTS` | `seo,linkedin,blog` | Agents needing 30 samples/variant |
| `P_WINNER` | `0.05` | p-value threshold for winner |
| `P_TREND` | `0.10` | p-value threshold for trending |
| `LIFT_WIN` | `15.0` | Minimum % lift for keep decision |
| `BOOTSTRAP_ITERATIONS` | `1000` | Bootstrap resamples for CI |
| `BATCH_MODE_MAX_VARIANTS` | `10` | Max variants in batch mode |

## Pacing Alert Variables

| Variable | Description |
|----------|-------------|
| `PIPELINE_API_URL` | Pipeline/CRM API endpoint |
| `PIPELINE_AUTH_TOKEN` | Bearer token for pipeline API |
| `RECRUITING_API_URL` | Recruiting API endpoint |
| `RECRUITING_AUTH_TOKEN` | Bearer token for recruiting API |
| `EMAIL_API_URL` | Email platform API base URL |
| `EMAIL_AUTH_TOKEN` | Bearer token for email platform |
| `OUTBOUND_CAMPAIGNS` | JSON: `{"name": "campaign-id"}` |
| `RECRUITING_CAMPAIGNS` | JSON: `{"name": "campaign-id"}` |
| `DAILY_LEAD_TARGET` | Leads/day target (default: 10) |
| `WEEKLY_CANDIDATE_TARGET` | Candidates/week target (default: 400) |

## Dependencies

```
pip install numpy scipy
```
