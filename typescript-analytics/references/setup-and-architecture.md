# Setup, Dependencies, and Architecture

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
