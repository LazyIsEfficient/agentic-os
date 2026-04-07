# Unit Testing — Components

Import from `@/test-utils/render` for automatic provider wrapping (ChakraProvider + QueryClientProvider with retries disabled):

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
    render(<TaskItem {...defaultProps} url="https://example.com" cta="Play" />)
    const link = screen.getByRole('link', { name: /play/i })
    expect(link).toHaveAttribute('href', 'https://example.com')
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

## Custom Render with Providers

```typescript
// test-utils/render.tsx
import { render, RenderOptions } from '@testing-library/react'
import { ChakraProvider } from '@chakra-ui/react'
import { YggTheme } from '@repo/ui/Themes'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const AllProviders = ({ children }: { children: React.ReactNode }) => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
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

## Query Priority

Prefer accessibility-first queries:

1. `getByRole('button', { name: /submit/i })` — semantic, best
2. `getByText('Submit')` — visible text
3. `getByLabelText('Email')` — form controls
4. `getByTestId('submit-btn')` — last resort

Use `queryBy*` to assert absence:

```typescript
expect(screen.queryByText('Error')).not.toBeInTheDocument()
```

## User Interactions

Prefer `userEvent.setup()` over `fireEvent` for realistic interaction:

```typescript
import userEvent from '@testing-library/user-event'

it('opens menu and shows options', async () => {
  const user = userEvent.setup()
  render(<ProfileMenu />)

  await user.click(screen.getByRole('button'))

  await waitFor(() => {
    expect(screen.getByText('Sign Out')).toBeInTheDocument()
  })
})
```

## Mocking Patterns

**Child components** — replace with stubs using `require('react')` inside factory:

```typescript
jest.mock('../ProfileHero', () => {
  const React = require('react')
  return {
    ProfileHero: ({ username }: { username: string }) =>
      React.createElement('div', { 'data-testid': 'profile-hero' }, username),
  }
})
```

**Next.js modules**:

```typescript
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(() => ({ back: jest.fn(), push: jest.fn() })),
  usePathname: jest.fn(() => '/test-page'),
}))
```

**Zustand stores** — selector pattern:

```typescript
jest.mock('@/domains/authentication/hooks/useUserStore', () => ({
  __esModule: true,
  default: jest.fn(),
}))

const mockState = (state: any) => {
  (mockUseUserStore as jest.Mock).mockImplementation((selector) => selector(state))
}
```

**Services**:

```typescript
jest.mock('@/domains/points/service', () => ({
  pointsClientService: {
    getPoints: jest.fn(),
    getPointsPledged: jest.fn(),
  },
}))
```
