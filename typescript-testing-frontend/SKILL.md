---
name: typescript-testing-frontend
description: This skill provides frontend testing rules with Jest, React Testing Library, Chakra UI, Zustand, and Next.js patterns. Automatically loaded when writing frontend tests, reviewing test quality, or when "frontend test", "component test", "hook test", "React test", "UI test", or "frontend test coverage" are mentioned.
---

# TypeScript Testing Rules (Frontend)

## Test Framework

- **Jest 29.7.0**: Primary test runner
- **@swc/jest**: TypeScript/JSX transpiler (fast SWC-based compilation, not Babel)
- **React Testing Library 16.x**: Component and hook testing (`@testing-library/react`)
- **@testing-library/jest-dom 6.x**: Extended DOM assertions (`toBeInTheDocument()`, etc.)
- **jest-canvas-mock**: Canvas element polyfill
- **Test environment**: `jsdom`
- **Test timeout**: 90 seconds
- **Config**: `apps/platform-app/config/jest/jest.config.js`
- **Test scripts**:
  ```json
  "test": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js"
  "test:ci": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js --maxWorkers=2 --ci"
  ```

### Setup Files

- `config/jest/jest.setup.js` — imports `@testing-library/jest-dom` and `jest-canvas-mock`, polyfills `TextEncoder`, `TextDecoder`, `structuredClone`, `ResizeObserver`, `Request`, `Response`, `Headers`
- `config/jest/env.setup.js` — loads environment variables from `.env`

## Key Dependencies

| Library | Version | Purpose |
|---|---|---|
| `@chakra-ui/react` | ^3.33.0 | UI framework |
| `@tanstack/react-query` | ^5.66.9 | Data fetching / server state |
| `zustand` | ^5.0.3 | Client state management |
| `next` | 15.x | Framework (App Router) |
| `thirdweb` | — | Web3 wallet connection |

## Directory Structure

Tests live in co-located `__tests__/` folders next to source files:

```
apps/platform-app/
├── domains/
│   ├── quests/
│   │   ├── components/
│   │   │   ├── quest-tasks/
│   │   │   │   ├── TaskItem.tsx
│   │   │   │   └── __tests__/
│   │   │   │       ├── TaskItem.test.tsx
│   │   │   │       └── QuestTasks.test.tsx
│   │   ├── hooks/
│   │   │   ├── useQuestFilterGroup.ts
│   │   │   └── __tests__/
│   │   │       └── useQuestFilterGroup.test.tsx
│   ├── profile/
│   │   ├── components/
│   │   │   └── __tests__/
│   │   │       ├── ProfileStats.test.tsx
│   │   │       └── ProfileActivity.test.tsx
│   │   ├── hooks/
│   │   │   └── __tests__/
│   │   │       └── useProfileData.test.ts
│   │   └── __tests__/
│   │       └── ProfileMenu.test.tsx
├── test-utils/
│   └── render.tsx          ← Global test utilities with providers
└── config/jest/
    ├── jest.config.js
    ├── jest.setup.js
    └── env.setup.js
```

## Naming Conventions

| Type | Pattern | Example |
|---|---|---|
| Component tests | `{ComponentName}.test.tsx` | `TaskItem.test.tsx` |
| Hook tests | `use{HookName}.test.ts` or `.test.tsx` | `useProfileData.test.ts` |
| Integration tests | `{Feature}.integration.test.tsx` | `SignInModal.integration.test.tsx` |

## Test Utilities — Provider Wrapper

All component and hook tests import from `@/test-utils/render` instead of `@testing-library/react` directly. This wraps renders with the required providers:

```typescript
// test-utils/render.tsx
import { render, RenderOptions } from '@testing-library/react'
import { ChakraProvider } from '@chakra-ui/react'
import { YggTheme } from '@repo/ui/Themes'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const AllProviders = ({ children }: { children: React.ReactNode }) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  })

  return (
    <QueryClientProvider client={queryClient}>
      <ChakraProvider value={YggTheme}>{children}</ChakraProvider>
    </QueryClientProvider>
  )
}

const customRender = (ui: React.ReactElement, options?: Omit<RenderOptions, 'wrapper'>) =>
  render(ui, { wrapper: AllProviders, ...options })

export * from '@testing-library/react'
export { customRender as render }
```

**Important**: React Query retries are **disabled** in tests to avoid flaky async behavior.

## Component Testing

### Basic Component Test

```typescript
import { render, screen, fireEvent } from '@/test-utils/render'
import { TaskItem } from '../TaskItem'

describe('TaskItem', () => {
  const defaultProps = {
    cta: 'Enroll',
    completed: false,
    locked: false,
    isLoading: false,
  }

  it('renders disabled button when locked', () => {
    render(<TaskItem {...defaultProps} locked={true} cta="Locked" />)
    expect(screen.getByRole('button', { name: /locked/i })).toBeDisabled()
  })

  it('renders link with href when url is provided', () => {
    render(<TaskItem {...defaultProps} url="https://example.com/play" cta="Play" />)
    const link = screen.getByRole('link', { name: /play/i })
    expect(link).toHaveAttribute('href', 'https://example.com/play')
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('calls onEnroll when button clicked', () => {
    const onEnroll = jest.fn()
    render(<TaskItem {...defaultProps} onEnroll={onEnroll} />)
    fireEvent.click(screen.getByRole('button', { name: /enroll/i }))
    expect(onEnroll).toHaveBeenCalledTimes(1)
  })
})
```

### User Interactions with `userEvent`

Prefer `userEvent.setup()` over `fireEvent` for realistic user interaction simulation:

```typescript
import userEvent from '@testing-library/user-event'
import { render, screen, waitFor } from '@/test-utils/render'

describe('ProfileMenu', () => {
  it('opens menu and shows options when trigger clicked', async () => {
    const user = userEvent.setup()
    render(<ProfileMenu />)

    await user.click(screen.getByRole('button'))

    await waitFor(() => {
      expect(screen.getByText('Manage Wallet')).toBeInTheDocument()
      expect(screen.getByText('Sign Out')).toBeInTheDocument()
    })
  })

  it('calls logout when Sign Out is clicked', async () => {
    const user = userEvent.setup()
    render(<ProfileMenu />)

    await user.click(screen.getByRole('button'))
    await waitFor(() => expect(screen.getByText('Sign Out')).toBeInTheDocument())
    await user.click(screen.getByText('Sign Out'))

    expect(mockLogout).toHaveBeenCalled()
  })
})
```

## Hook Testing

Use `renderHook()` with an explicit wrapper providing the required context:

```typescript
import { renderHook, act, waitFor } from '@/test-utils/render'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ChakraProvider } from '@chakra-ui/react'
import { YggTheme } from '@repo/ui/Themes'

const wrapper = ({ children }: { children: React.ReactNode }) => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return (
    <QueryClientProvider client={queryClient}>
      <ChakraProvider value={YggTheme}>{children}</ChakraProvider>
    </QueryClientProvider>
  )
}

describe('useQuestFilterGroup', () => {
  it('should initialize with ["all"] when filterValue is null', () => {
    const { result } = renderHook(
      () => useQuestFilterGroup({
        filterValue: null,
        isOpen: false,
        allItems: ['item1', 'item2', 'item3'],
      }),
      { wrapper }
    )
    expect(result.current.checkboxGroup.value).toEqual(['all'])
  })

  it('should reset to store value when isOpen changes', () => {
    const { result, rerender } = renderHook(
      ({ isOpen }) => useQuestFilterGroup({
        filterValue: ['item1'],
        isOpen,
        allItems: ['item1', 'item2'],
      }),
      { wrapper, initialProps: { isOpen: false } }
    )

    act(() => {
      result.current.checkboxGroup.setValue(['item2'])
    })
    expect(result.current.checkboxGroup.value).toEqual(['item2'])

    rerender({ isOpen: true })
    expect(result.current.checkboxGroup.value).toEqual(['item1'])
  })
})
```

## Mocking Patterns

### Zustand Store Mocking

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

### Service / API Mocking

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

### Next.js Module Mocking

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

### Child Component Mocking

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

### Chakra UI / Window Mocking

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

## Query Priority

Prefer queries in this order (accessibility-first):

1. `getByRole()` — semantic, best for accessibility (`getByRole('button', { name: /submit/i })`)
2. `getByText()` — visible text content
3. `getByLabelText()` — form controls
4. `getByTestId()` — last resort when semantic queries are insufficient

Use `queryBy*` variants when asserting an element does **not** exist:

```typescript
expect(screen.queryByText('Error')).not.toBeInTheDocument()
```

## Async Testing

Use `waitFor()` for assertions that depend on async state updates:

```typescript
await waitFor(() => {
  expect(result.current.isLoading).toBe(false)
})
expect(result.current.stats).toHaveLength(4)
```

Use `act()` for synchronous state updates in hooks:

```typescript
act(() => {
  result.current.checkboxGroup.setValue(['item2'])
})
```

## Common Jest-DOM Assertions

| Matcher | Purpose |
|---|---|
| `toBeInTheDocument()` | Element exists in DOM |
| `toBeDisabled()` | Button/input is disabled |
| `toBeVisible()` | Element is visible |
| `toHaveAttribute(name, value?)` | Has HTML attribute |
| `toHaveTextContent(text)` | Contains text |
| `toHaveClass(className)` | Has CSS class |
| `toHaveStyle(css)` | Has inline style |
| `toHaveValue(value)` | Form input value |
| `toBeChecked()` | Checkbox/radio is checked |

## Coverage Configuration

Coverage is **enabled by default** (`collectCoverage: true`). CI outputs JUnit XML to `test-results/jest/results.xml`. No explicit thresholds are configured.

Excluded from coverage: `coveragePathIgnorePatterns: ['<rootDir>/test/test-utils.js']`

## Testing Policy

### No Snapshot Testing

This codebase uses behavioral assertions exclusively. Do not introduce snapshot tests.

### Keep All Tests Active

- Fix broken tests — do not use `test.skip()` or comment them out
- Delete tests that are genuinely no longer relevant

### Every Test Must Assert

Every `it()` block must include at least one `expect()` that validates observable behavior.

### Test Failure Response

- **Fix the test**: Wrong expected values, implementation detail coupling, flaky assertions
- **Fix the implementation**: Valid business rules, edge cases, contract violations
- **When in doubt**: Confirm with user before changing either
