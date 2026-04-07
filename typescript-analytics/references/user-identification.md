# User Identification

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
