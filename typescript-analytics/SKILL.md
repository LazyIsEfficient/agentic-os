---
name: typescript-analytics
description: This skill provides analytics engineering rules using PostHog for event tracking, feature flags, error capture, and user identification. Covers client-side and server-side patterns, type-safe events, and API lifecycle tracking. Automatically loaded when implementing analytics, tracking events, adding feature flags, or when "PostHog", "analytics", "feature flag", "event tracking", "capture", "identify", "A/B test", or "experiment" are mentioned.
---

# Analytics Engineering Rules (PostHog + TypeScript)

## Setup and Dependencies

- **posthog-js** ^1.229.5 — client-side SDK
- **posthog-node** ^5.5.1 — server-side SDK
- **@posthog/cli** ^0.4.8 — source map uploads
- **Region**: PostHog US (`us.posthog.com`)

### PostHog Proxy (Ad Blocker Bypass)

PostHog API calls are proxied through the app's domain via Next.js rewrites:

```typescript
// next.config.ts
rewrites: [
  { source: '/ph/static/:path*', destination: `${POSTHOG_ASSETS_ORIGIN}/static/:path*` },
  { source: '/ph/:path*', destination: `${POSTHOG_INGEST_ORIGIN}/:path*` },
]
```

Client connects to `/ph` instead of `us.i.posthog.com` directly.

### Initialization

```typescript
// providers/posthog/PosthogProvider.tsx
posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY, {
  api_host: '/ph',
  ui_host: POSTHOG_UI_ORIGIN,
  capture_pageview: false,   // Manual pageview tracking
  capture_pageleave: true,
  autocapture: false,        // Explicit events only — no autocapture
})
```

**Rules**:
- `autocapture: false` — track events explicitly, never rely on autocapture
- `capture_pageview: false` — use custom `trackPageViewed()` for full control
- Always proxy through `/ph` to avoid ad blocker interference

### Environment Variables

```
NEXT_PUBLIC_POSTHOG_KEY=          # PostHog project API key (required)
NEXT_PUBLIC_APP_ENV=              # development | staging | production
POSTHOG_PROJECT_ID_PRODUCTION=   # For source map uploads
POSTHOG_PROJECT_ID_STAGING=
POSTHOG_CLI_TOKEN=                # CLI auth for CI
```

## Architecture

```
apps/platform-app/
├── providers/posthog/
│   ├── PosthogProvider.tsx          ← Client-side init + React provider
│   └── PosthogTrackIdentity.tsx     ← Auto-identify on auth state change
├── libs/posthog/
│   ├── posthog.ts                   ← Unified client/server getter
│   ├── posthog-server.ts            ← Server-side instance ('use server')
│   ├── feature-flags-server.ts      ← Server-side flag checks
│   ├── types.ts                     ← UnifiedPostHogInstance type
│   ├── captureEvents.ts             ← Event capture utilities
│   ├── captureErrors.ts             ← Error tracking
│   ├── applyMetaData.ts             ← Auto-inject metadata on every event
│   └── constants.ts                 ← EVENTS and FEATURE_FLAGS enums
├── libs/analytics/
│   ├── analytics.ts                 ← Analytics class with typed methods
│   └── analytics-events.ts          ← Typed event schemas + properties
└── hooks/analytics/
    ├── useFeatureFlag.ts            ← Client-side feature flag hook
    └── useComponentError.ts         ← Component error tracking hook
```

## Unified Client/Server Pattern

A single `getPostHog()` function returns the same interface on both client and server:

```typescript
// libs/posthog/posthog.ts
export async function getPostHog(): Promise<UnifiedPostHogInstance> {
  if (isServer) {
    const { getServerPostHog } = await import('./posthog-server')
    return getServerPostHog()
  }
  return applyClientMetadata(posthogClient as PostHogClientInstance)
}
```

### Server-Side Instance

For API routes and server components — flush immediately for serverless:

```typescript
// libs/posthog/posthog-server.ts
export async function getServerPostHog(): Promise<UnifiedPostHogInstance> {
  const posthogInstance = new PostHog(key, {
    host: POSTHOG_INGEST_ORIGIN,
    flushAt: 1,        // Send immediately (critical for serverless)
    flushInterval: 0,  // Don't batch
  })

  const session = await sessionService.getUserSession()
  return applyServerMetadata(posthogInstance, { user: session?.user })
}
```

**Rules**:
- Always use `flushAt: 1` and `flushInterval: 0` for serverless environments
- Always call `posthog.shutdown()` in `finally` blocks for server-side usage
- Retrieve user session and inject metadata before capturing

## Automatic Metadata Injection

Every event automatically includes app metadata via the `applyMetaData` wrapper:

```typescript
// libs/posthog/applyMetaData.ts
function mergeEventProperties(properties?: Properties): Properties {
  return {
    ...properties,
    appEnvironment: metadata.appEnvironment,              // 'production' | 'staging' | 'development'
    appName: metadata.appName,                            // 'playPlatformApp'
    appVersion: metadata.appVersion,                      // from package.json
    appBlockChainEnvironment: metadata.appBlockChainEnvironment,  // mainnet | testnet
  }
}
```

Feature flags auto-reload when `$set` or `$set_once` properties are present in a capture call.

## Event Tracking

### Event Naming Convention

Events use a `domain:action` pattern with an enum:

```typescript
// libs/posthog/constants.ts
export enum EVENTS {
  // Auth
  SIGN_IN_CLICKED = 'sign_in:clicked',
  SIGN_IN = 'sign_in',
  LOGOUT_CLICKED = 'logout:clicked',
  LOGOUT = 'logout',
  LINK_WALLET_CLICKED = 'link_wallet:clicked',
  LINK_WALLET_SUCCESS = 'link_wallet:success',
  LINK_WALLET_ERROR = 'link_wallet:error',

  // Quests
  QUEST_CARD_CLICKED = 'quest:card_clicked',
  QUEST_ENROLLED = 'quest:enrolled',
  QUEST_COMPLETED = 'quest:completed',

  // Games
  GAME_CARD_CLICKED = 'game:card_clicked',

  // Token operations (each follows CTA → Success → Error pattern)
  CLAIM_CTA_CLICKED = 'claim:cta_clicked',
  CLAIM_SUCCESS = 'claim:success',
  CLAIM_ERROR = 'claim:error',
  PLEDGE_CTA_CLICKED = 'pledge:cta_clicked',
  PLEDGE_SUCCESS = 'pledge:success',
  PLEDGE_ERROR = 'pledge:error',
  APPROVE_CTA_CLICKED = 'approve:cta_clicked',
  APPROVE_SUCCESS = 'approve:success',
  APPROVE_ERROR = 'approve:error',
  CONTRIBUTE_CTA_CLICKED = 'contribute:cta_clicked',
  CONTRIBUTE_SUCCESS = 'contribute:success',
  CONTRIBUTE_ERROR = 'contribute:error',
  STAKE_CTA_CLICKED = 'stake:cta_clicked',
  STAKE_SUCCESS = 'stake:success',
  STAKE_ERROR = 'stake:error',
  UNSTAKE_CTA_CLICKED = 'unstake:cta_clicked',
  UNSTAKE_SUCCESS = 'unstake:success',
  UNSTAKE_ERROR = 'unstake:error',
  SWAP_CTA_CLICKED = 'swap:cta_clicked',
  SWAP_SUCCESS = 'swap:success',
  SWAP_ERROR = 'swap:error',
}

export enum EVENT_STATUS {
  IN_PROGRESS = 'in_progress',
  SUCCESS = 'success',
  ERROR = 'error',
}
```

**Naming rules**:
- Format: `{domain}:{action}` — always lowercase, colon-separated
- User interactions: `{domain}:cta_clicked` (not just "clicked")
- Async operations: Track the full lifecycle — `cta_clicked` → `success` / `error`
- New events must be added to the `EVENTS` enum, never use raw strings

### Capture Functions

**Simple event capture**:

```typescript
// libs/posthog/captureEvents.ts
export async function capturePostHogEvent(eventName: EVENTS, properties: Properties) {
  const posthog = await getPostHog()
  await posthog.capture(eventName, properties)
}
```

**API lifecycle tracking** (IN_PROGRESS → SUCCESS/ERROR):

```typescript
export function captureApiEvent(eventName: EVENTS, baseProperties: Properties = {}) {
  return {
    event: (statusProperties: Properties) => {
      capturePostHogEvent(eventName, {
        ...baseProperties,
        ...statusProperties,
      })
    },
    properties: baseProperties,
  }
}
```

Usage in service calls:

```typescript
// domains/quests/service.ts
const response = await apiClient.activities.enrollActivity({
  params: { slug: activity.slug },
  body: { abstractWalletAddress },
  analytics: captureApiEvent(EVENTS.QUEST_ENROLLED, {
    slug: activity.slug,
    name: activity.name,
    frequency: activity.frequency,
    published: activity.published,
    projectId: activity.projectId,
    featured: activity.featured,
  }),
})
```

### Manual Event Capture Example

```typescript
// Token claim flow
const handleClaim = async () => {
  capturePostHogEvent(EVENTS.CLAIM_CTA_CLICKED, {
    tokenSlug: slug,
    pointsPledged,
    tokenStatus: status,
    status: EVENT_STATUS.IN_PROGRESS,
  })

  try {
    await allocationModule.claimAllocationAsync({ ... })

    capturePostHogEvent(EVENTS.CLAIM_SUCCESS, {
      tokenSlug: slug,
      pointsPledged,
      tokenStatus: status,
      isRefund: status === TokenStatus.ENDED,
    })
  } catch (error) {
    capturePostHogEvent(EVENTS.CLAIM_ERROR, {
      tokenSlug: slug,
      pointsPledged,
      tokenStatus: status,
    })
  }
}
```

## Typed Analytics System

A second analytics layer provides fully type-safe events with typed property maps:

### Event Schema

```typescript
// libs/analytics/analytics-events.ts
export const ANALYTICS_EVENTS = {
  NAVIGATION: { PAGE_VIEWED: 'navigation:page_viewed' },
  REDEEM: {
    OPTION_CLICKED: 'redeem:option_clicked',
    SUCCESS_VIEWED: 'redeem:success_viewed',
    FAILURE_VIEWED: 'redeem:failure_viewed',
    COOLDOWN_VIEWED: 'redeem:cooldown_viewed',
    START_CANCEL: 'redeem:start_cancel',
    START_MODAL_VIEWED: 'redeem:start_modal_viewed',
    START_CONFIRMED: 'redeem:start_confirmed',
    PENDING_VIEWED: 'redeem:pending_viewed',
    TRANSACTION_INITIATED: 'redeem:transaction_initiated',
    TRANSACTION_RETRIED: 'redeem:transaction_retried',
    MAX_RTP_PER_WALLET: 'redeem:max_rtp_per_wallet',
  },
  TRANSACTIONS: {
    VIEW_ALL_CLICKED: 'transactions:view_all_clicked',
    TX_EXTERNAL_OPENED: 'transactions:tx_external_opened',
    PAGE_CHANGED: 'transactions:page_changed',
  },
} as const
```

### Typed Event Properties

```typescript
export interface RedeemEventProperties extends BaseEventProperties {
  game?: string
  option_id?: string
  ygg_amount?: number
  points_required?: number
  points_spent?: number
  tx_hash?: string
  attempt_id?: string
  error_code?: string
  error_message?: string
}
```

### Analytics Class

```typescript
// libs/analytics/analytics.ts
export class Analytics {
  static track<T extends EventName>(event: T, properties?: EventPropertiesMap[T]) { }
  static trackGeneric(event: string, properties?: GenericEventProperties) { }
  static identify(distinctId: string, properties?: GenericEventProperties) { }
  static alias(alias: string) { }
  static reset() { }
  static setPersonProperties(properties: GenericEventProperties) { }
  static group(groupType: string, groupKey: string, groupProperties?: GenericEventProperties) { }
  static trackPageViewed(path: string, referrerUrl: string, utmProps?: Record<string, string>) { }
}
```

### useAnalytics Hook

```typescript
export const useAnalytics = () => ({
  track: Analytics.track.bind(Analytics),
  trackGeneric: Analytics.trackGeneric.bind(Analytics),
  identify: Analytics.identify.bind(Analytics),
  alias: Analytics.alias.bind(Analytics),
  reset: Analytics.reset.bind(Analytics),
  setPersonProperties: Analytics.setPersonProperties.bind(Analytics),
  group: Analytics.group.bind(Analytics),
  trackPageViewed: Analytics.trackPageViewed.bind(Analytics),
  events: ANALYTICS_EVENTS,
})
```

Usage:

```typescript
const { track, events } = useAnalytics()

track(events.REDEEM.TRANSACTION_INITIATED, {
  game,
  option_id,
  ygg_amount,
  points_spent,
  status: EVENT_STATUS.IN_PROGRESS,
})
```

## Pageview Tracking

Manual pageview on route change:

```typescript
// layouts/GlobalNavLayout.tsx
const { trackPageViewed } = useAnalytics()

useEffect(() => {
  trackPageViewed(pathname, typeof document !== 'undefined' ? document.referrer || '/' : '/')
}, [pathname, trackPageViewed])
```

Includes UTM parameters: `utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`.

## User Identification

Identify users on auth state change and track group membership:

```typescript
// providers/posthog/PosthogTrackIdentity.tsx
export default function PosthogTrackIdentity(): null {
  const { user, isAuthenticated } = useUserStore((state) => state)

  useEffect(() => {
    if (isAuthenticated && user?.id && user?.email) {
      // Identify user
      posthog.identify(user.id, {
        id: user.id,
        email: user.email,
      })

      // Track group membership
      user.groups?.forEach((group) => {
        if (group?.slug) {
          posthog.group('group', group.slug)
        }
      })
    }
  }, [isAuthenticated, user?.id, user?.email, user?.groups?.length])

  return null
}
```

**Rules**:
- Identify with user ID as `distinctId`, not email
- Include `email` as a person property for PostHog dashboard lookups
- Track groups via `posthog.group('group', slug)` for organization-level analytics
- Re-identify when auth state changes (dependency array includes auth fields)

## Feature Flags

### Feature Flag Constants

```typescript
// libs/posthog/constants.ts
export enum FEATURE_FLAGS {
  STAKING = 'staking',
  SWAP_WIDGET = 'swap-widget',
  BOOST = 'boost',
  BOOST_SURPRISE = 'boost-surprise',
  TOKEN_SECTION = 'token-section',
  FAQ = 'faq',
  REDEEM = 'redeem',
  REDEEM_STAKING = 'redeem-staking',
  REDEEM_DEBUG_PANEL = 'redeem-debug-panel-{slug}',  // Dynamic flag with parameter
}
```

**Rules**:
- All flags must be added to the `FEATURE_FLAGS` enum
- Use kebab-case for flag names
- Dynamic flags use `{param}` placeholder syntax

### Client-Side Hook

```typescript
// hooks/analytics/useFeatureFlag.ts
export const useFeatureFlag = (flagName: FEATURE_FLAGS[keyof FEATURE_FLAGS]): boolean => {
  const posthog = usePostHog()
  const [isEnabled, setIsEnabled] = useState(false)

  useEffect(() => {
    const checkFlag = () => {
      try {
        const enabled = posthog.isFeatureEnabled(flagName) ?? false
        setIsEnabled(enabled)
      } catch (error) {
        clientLogger.error({}, `Error checking feature flag ${flagName}:`)
        setIsEnabled(false)  // Default to disabled on error
      }
    }

    if (posthog.getFeatureFlag(flagName) !== undefined) {
      checkFlag()
    } else {
      posthog.onFeatureFlags(checkFlag)  // Wait for flags to load
    }
  }, [flagName])

  return isEnabled
}
```

**Rules**:
- Default to `false` (disabled) on error — fail-closed
- Wait for flags to load via `onFeatureFlags` callback before checking
- Use the typed enum, never raw strings

### Server-Side Flag Check

```typescript
// libs/posthog/feature-flags-server.ts
export async function checkFeatureFlag(
  flagName: FEATURE_FLAGS[keyof FEATURE_FLAGS],
  userId: string | undefined,
): Promise<boolean> {
  const posthog = new PostHog(key, { host, flushAt: 1, flushInterval: 0 })
  try {
    const distinctId = userId ? String(userId) : 'anonymous'
    const isEnabled = await posthog.isFeatureEnabled(flagName, distinctId)
    return isEnabled ?? false
  } finally {
    await posthog.shutdown()
  }
}

// For multivariate flags (string variants)
export async function getFeatureFlag(
  flagName: FEATURE_FLAGS[keyof FEATURE_FLAGS],
  userId: string | undefined,
): Promise<string | boolean | undefined> {
  // Same pattern, uses posthog.getFeatureFlag()
}
```

**Rules**:
- Always call `posthog.shutdown()` in `finally` — prevents serverless timeout leaks
- Use `'anonymous'` as distinctId when user is not authenticated
- `checkFeatureFlag` returns boolean, `getFeatureFlag` returns variant value

## Error Tracking

### Error Capture

```typescript
// libs/posthog/captureErrors.ts
export async function capturePosthogError(error: Error, properties: Properties) {
  const posthog = await getPostHog()
  await posthog.captureException(error, properties)
}
```

### Component Error Hook

```typescript
// hooks/analytics/useComponentError.ts
export default function useComponentError(
  error: string | Error | null | undefined,
  options: UseComponentErrorOptions,
) {
  const { sourceComponent, errorType = ERROR_TYPES.COMPONENT_ERROR, errorMessage, additionalProperties = {} } = options

  useEffect(() => {
    if (error) {
      const errorObj = new Error(`${errorType}: ${errorMessage}`)
      errorObj.name = `${errorType}: ${sourceComponent}`

      capturePosthogError(errorObj, {
        errorMessage,
        errorType,
        sourceComponent,
        ...additionalProperties,
      })
    }
  }, [error, sourceComponent, errorType, additionalProperties])
}
```

### Error Types

```typescript
export enum ERROR_TYPES {
  COMPONENT_ERROR = 'Component Error',
  API_ERROR = 'API Error',
  NETWORK_ERROR = 'Network Error',
  SERVICE_ERROR = 'Service Error',
}
```

### Automatic API Error Tracking

The API client automatically captures errors based on HTTP status:

```typescript
// libs/api-client/api-error-handler.ts
export const shouldTrackHttpError = (status: number) => {
  if (status >= 500) return true              // Server errors — always track
  if ([401, 403, 408].includes(status)) return true  // Auth/permission/timeout
  if ([400, 409, 422].includes(status)) return true  // Business logic errors
  if ([404, 429].includes(status)) return false      // Skip common noise
  return false
}
```

The API client wraps all requests and captures IN_PROGRESS → SUCCESS/ERROR with full context (status, method, domain, response body, stack trace).

## Common Event Properties

### Auto-Injected on Every Event

| Property | Source |
|---|---|
| `appEnvironment` | `NEXT_PUBLIC_APP_ENV` |
| `appName` | `'playPlatformApp'` |
| `appVersion` | `package.json` version |
| `appBlockChainEnvironment` | mainnet / testnet |

### Commonly Tracked Properties

| Property | Used In |
|---|---|
| `slug`, `name`, `frequency`, `projectId` | Quest events |
| `tokenSlug`, `pointsPledged`, `tokenStatus` | Token events |
| `game`, `option_id`, `ygg_amount`, `points_spent` | Redeem events |
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

## Rules Summary

1. **Never use autocapture** — all events must be explicit and in the `EVENTS` or `ANALYTICS_EVENTS` enum
2. **Track the full lifecycle** — `cta_clicked` → `in_progress` → `success` / `error`
3. **Use the unified pattern** — `getPostHog()` for both client and server, not raw SDK imports
4. **Flush immediately on server** — `flushAt: 1`, `flushInterval: 0`, always `shutdown()` in `finally`
5. **Default flags to disabled** — `false` on error or when flags haven't loaded
6. **Identify by user ID** — never by email; set email as a person property
7. **Proxy through /ph** — never call PostHog directly from the client
8. **Add new events to the enum** — never use raw strings for event names
9. **Include domain context** — slug, name, status, and relevant IDs in every event
10. **Mask sensitive data** — wallet addresses should be masked in properties
