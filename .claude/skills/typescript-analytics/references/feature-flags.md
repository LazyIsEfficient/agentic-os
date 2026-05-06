# Feature Flags

## Feature Flag Constants

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

## Client-Side Hook

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

## Server-Side Flag Check

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
