# Common Event Properties and Source Maps

## Auto-Injected on Every Event

| Property | Source |
|---|---|
| `appEnvironment` | `NEXT_PUBLIC_APP_ENV` |
| `appName` | `'playPlatformApp'` |
| `appVersion` | `package.json` version |
| `appBlockChainEnvironment` | mainnet / testnet |

## Commonly Tracked Properties

| Property | Used In |
|---|---|
| `slug`, `name`, `frequency`, `projectId` | Quest events |
| `tokenSlug`, `pointsPledged`, `tokenStatus` | Token events |
| `game`, `option_id`, `token_amount`, `points_spent` | Redeem events |
| `tx_hash`, `attempt_id` | Transaction events |
| `error_code`, `error_message` | Error events |
| `wallet_address_masked`, `wallet_provider` | Wallet events |
| `page`, `path`, `referrer_url` | Navigation events |
| `utm_source`, `utm_medium`, `utm_campaign` | Attribution |

## Source Maps (Production Debugging)

Source maps are uploaded to PostHog on deploy via GitHub Actions:

```yaml
# .github/workflows/posthog-sourcemaps.yml
- uses: PostHog/upload-source-maps@v0.4.6
  with:
    directory: apps/platform-app/.next
    env-id: ${{ secrets.POSTHOG_PROJECT_ID_PRODUCTION }}
    cli-token: ${{ secrets.POSTHOG_CLI_TOKEN }}
    version: ${{ github.sha }}
```

Separate uploads for production (main branch) and staging (staging branch), versioned by git SHA.
