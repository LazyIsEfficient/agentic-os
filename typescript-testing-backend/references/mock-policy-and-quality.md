# Mock Policy and Test Quality

## Mock and Stub Policy

| Dependency | Unit Tests | Integration Tests |
|---|---|---|
| Prisma / database | `jest.mock('@repo/prisma', ...)` | Real test DB instance |
| Auth session | `jest.mock(...)` | `authTestHelpers` |
| Third-party SDKs (Thirdweb, etc.) | `jest.mock(...)` | Mock via shared mocks |
| Internal validators / utils | Use real implementations | Use real implementations |
| External HTTP APIs | `jest.mock(...)` | `jest.mock(...)` |

Mock at the module boundary — not internal functions.

## Test Quality Criteria

### Use Literal Expected Values

```typescript
expect(response.body.totalPoints).toBe(70)
expect(response.status).toBe(201)
expect(user.role).toBe('admin')
```

### Verify Observable Outcomes

```typescript
expect(mockPrisma.faqArticle.findMany).toHaveBeenCalledWith({ orderBy: { order: 'asc' } })
expect(result).toEqual({ id: '1', status: 'created' })
```

### Every Test Must Assert

Every `it()` block must include at least one `expect()` that validates observable behavior.

### Keep All Tests Active

- Fix broken tests — do not use `test.skip()` or comment them out
- Delete tests that are genuinely no longer relevant
- Skipped tests create silent coverage gaps

## Test Failure Response

- **Fix the test**: Wrong expected values, implementation detail coupling, flaky assertions
- **Fix the implementation**: Valid business rules, edge cases, contract violations
- **When in doubt**: Confirm with user before changing either
