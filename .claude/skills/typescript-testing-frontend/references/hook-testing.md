# Hook Testing

Same convention as **Tests-only default and refactor callouts** in [SKILL.md](../SKILL.md): tests only unless the user asked for production changes; defer hook signature changes, new parameters, or consumer refactors to **Refactor opportunities (not in scope)** (bulleted). Flag awkward dependencies, missing seams, or mock depth there — do not implement refactors in the same turn unless instructed.

Use `renderHook()` with an explicit wrapper providing the required context:

```typescript
import { renderHook, act, waitFor } from '@/test-utils/render'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ChakraProvider } from '@chakra-ui/react'
import { AppTheme } from '@repo/ui/Themes'

const wrapper = ({ children }: { children: React.ReactNode }) => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return (
    <QueryClientProvider client={queryClient}>
      <ChakraProvider value={AppTheme}>{children}</ChakraProvider>
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
