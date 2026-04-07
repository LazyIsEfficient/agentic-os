# Queries, Async Testing, and Assertions

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
