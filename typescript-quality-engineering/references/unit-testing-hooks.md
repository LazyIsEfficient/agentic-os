# Unit Testing — Hooks

Use `renderHook()` with a provider wrapper:

```typescript
import { renderHook, act, waitFor } from '@/test-utils/render'

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
  it('initializes with ["all"] when filterValue is null', () => {
    const { result } = renderHook(
      () => useQuestFilterGroup({ filterValue: null, isOpen: false, allItems: ['a', 'b'] }),
      { wrapper },
    )
    expect(result.current.checkboxGroup.value).toEqual(['all'])
  })

  it('resets to store value when isOpen changes', () => {
    const { result, rerender } = renderHook(
      ({ isOpen }) => useQuestFilterGroup({ filterValue: ['a'], isOpen, allItems: ['a', 'b'] }),
      { wrapper, initialProps: { isOpen: false } },
    )

    act(() => { result.current.checkboxGroup.setValue(['b']) })
    expect(result.current.checkboxGroup.value).toEqual(['b'])

    rerender({ isOpen: true })
    expect(result.current.checkboxGroup.value).toEqual(['a'])
  })
})
```

## Async Hook Testing

```typescript
it('returns loading then data when authenticated', async () => {
  mockState({ isAuthenticated: true, user: { email: 'user@test.com' } })
  mockGetPoints.mockResolvedValue({ totalPoints: 1500 })

  const { result } = renderHook(() => useProfileData(), { wrapper: createWrapper() })

  await waitFor(() => {
    expect(result.current.isLoading).toBe(false)
  })
  expect(result.current.stats).toHaveLength(4)
})
```
