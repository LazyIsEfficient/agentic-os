# Event Tracking

## Event Naming Convention

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

## Capture Functions

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

## Manual Event Capture Example

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
