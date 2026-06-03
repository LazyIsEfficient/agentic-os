## Error-Specific Patterns

### Test Failure Triage

```
Test fails after code change:
├── Did you change code the test covers?
│   └── YES → Check if the test or the code is wrong
│       ├── Test is outdated → Update the test
│       └── Code has a bug → Fix the code
├── Did you change unrelated code?
│   └── YES → Likely a side effect → Check shared state, imports, globals
└── Test was already flaky?
    └── Check for timing issues, order dependence, external dependencies
```

### Build Failure Triage

```
Build fails:
├── Type error → Read the error, check the types at the cited location
├── Import error → Check the module exists, exports match, paths are correct
├── Config error → Check build config files for syntax/schema issues
├── Dependency error → Check package.json, run npm install
└── Environment error → Check Node version, OS compatibility
```

### Runtime Error Triage

```
Runtime error:
├── TypeError: Cannot read property 'x' of undefined
│   └── Something is null/undefined that shouldn't be
│       → Check data flow: where does this value come from?
├── Network error / CORS
│   └── Check URLs, headers, server CORS config
├── Render error / White screen
│   └── Check error boundary, console, component tree
└── Unexpected behavior (no error)
    └── Add logging at key points, verify data at each step
```

## Safe Fallback Patterns

When under time pressure, use safe fallbacks:

```typescript
// Safe default + warning (instead of crashing)
function getConfig(key: string): string {
  const value = process.env[key];
  if (!value) {
    console.warn(`Missing config: ${key}, using default`);
    return DEFAULTS[key] ?? '';
  }
  return value;
}

// Graceful degradation (instead of broken feature)
function renderChart(data: ChartData[]) {
  if (data.length === 0) {
    return <EmptyState message="No data available for this period" />;
  }
  try {
    return <Chart data={data} />;
  } catch (error) {
    console.error('Chart render failed:', error);
    return <ErrorState message="Unable to display chart" />;
  }
}
```

## Instrumentation Guidelines

Add logging only when it helps. Remove it when done.

**When to add instrumentation:**
- You can't localize the failure to a specific line
- The issue is intermittent and needs monitoring
- The fix involves multiple interacting components

**When to remove it:**
- The bug is fixed and tests guard against recurrence
- The log is only useful during development (not in production)
- It contains sensitive data (always remove these)

**Permanent instrumentation (keep):**
- Error boundaries with error reporting
- API error logging with request context
- Performance metrics at key user flows
