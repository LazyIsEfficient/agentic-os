# Typed Analytics System

A second analytics layer provides fully type-safe events with typed property maps.

## Event Schema

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

## Typed Event Properties

```typescript
export interface RedeemEventProperties extends BaseEventProperties {
  game?: string
  option_id?: string
  token_amount?: number
  points_required?: number
  points_spent?: number
  tx_hash?: string
  attempt_id?: string
  error_code?: string
  error_message?: string
}
```

## Analytics Class

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

## useAnalytics Hook

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
  token_amount,
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
