# Mocking Patterns

Follow **Tests-only default and refactor callouts** in [SKILL.md](../SKILL.md). When mocks feel excessive, deeply nested, or tied to internal implementation, treat that as a testability signal: describe it under **Refactor opportunities (not in scope)** (bulleted). Do not widen production APIs or refactor modules in the same turn unless the user asked.

## Zustand Store Mocking

Mock the store module and use the selector pattern:

```typescript
jest.mock('@/domains/authentication/hooks/useUserStore', () => ({
  __esModule: true,
  default: jest.fn(),
}))

import useUserStore from '@/domains/authentication/hooks/useUserStore'

const mockUseUserStore = useUserStore as jest.MockedFunction<typeof useUserStore>

const mockState = (state: any) => {
  (mockUseUserStore as jest.Mock).mockImplementation((selector) => selector(state))
}

// In tests:
mockState({
  isAuthenticated: true,
  user: { email: 'user@test.com' },
  abstractWalletAddress: '0x1234567890abcdef',
})
```

For integration tests, set state directly on the store:

```typescript
import { userStore } from '@/domains/authentication/hooks/useUserStore'

beforeEach(() => {
  userStore.setState({
    isAuthenticated: false,
    user: null,
    rehydrated: true,
    abstractWalletAddress: null,
  })
})
```

## Service / API Mocking

Mock the service module, then configure return values per test:

```typescript
jest.mock('@/domains/points/service', () => ({
  pointsClientService: {
    getPoints: jest.fn(),
    getPointsPledged: jest.fn(),
  },
}))

import { pointsClientService } from '@/domains/points/service'
const mockGetPoints = pointsClientService.getPoints as jest.Mock

beforeEach(() => {
  jest.clearAllMocks()
  mockGetPoints.mockResolvedValue({ totalPoints: 1500, transactions: [] })
})
```

## Next.js Module Mocking

```typescript
// Router & navigation
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(() => ({ back: jest.fn(), push: jest.fn() })),
  usePathname: jest.fn(() => '/test-page'),
}))

// Link — render as plain <a>
jest.mock('next/link', () => {
  const React = require('react')
  return ({ children, href }: any) => React.createElement('a', { href }, children)
})

// Image — render as plain <img>
jest.mock('next/image', () => {
  const React = require('react')
  return (props: any) => React.createElement('img', props)
})
```

## Child Component Mocking

Replace complex child components with simple stubs:

```typescript
jest.mock('../ProfileHero', () => {
  const React = require('react')
  return {
    ProfileHero: ({ username }: { username: string }) =>
      React.createElement('div', { 'data-testid': 'profile-hero' }, username),
  }
})
```

Use `const React = require('react')` inside mock factories — top-level imports are not available inside `jest.mock()` callbacks.

## Chakra UI / Window Mocking

For components using Chakra's responsive features:

```typescript
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
})
```
