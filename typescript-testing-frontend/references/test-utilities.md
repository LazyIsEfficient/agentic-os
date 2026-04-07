# Test Utilities — Provider Wrapper

All component and hook tests import from `@/test-utils/render` instead of `@testing-library/react` directly. This wraps renders with the required providers:

```typescript
// test-utils/render.tsx
import { render, RenderOptions } from '@testing-library/react'
import { ChakraProvider } from '@chakra-ui/react'
import { AppTheme } from '@repo/ui/Themes'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

const AllProviders = ({ children }: { children: React.ReactNode }) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
    },
  })

  return (
    <QueryClientProvider client={queryClient}>
      <ChakraProvider value={AppTheme}>{children}</ChakraProvider>
    </QueryClientProvider>
  )
}

const customRender = (ui: React.ReactElement, options?: Omit<RenderOptions, 'wrapper'>) =>
  render(ui, { wrapper: AllProviders, ...options })

export * from '@testing-library/react'
export { customRender as render }
```

**Important**: React Query retries are **disabled** in tests to avoid flaky async behavior.
