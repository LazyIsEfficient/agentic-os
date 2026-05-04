# End-to-End Testing — Playwright

## Configuration

```typescript
// playwright.config.ts
export default defineConfig({
  testDir: './e2e/playwright',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  reporter: process.env.CI
    ? [['list'], ['junit', { outputFile: 'test-results/junit.xml' }]]
    : 'html',
  use: {
    baseURL: process.env.PLAYWRIGHT_TEST_BASE_URL || 'http://localhost:3000',
    trace: process.env.CI ? 'on-first-retry' : 'on',
    screenshot: process.env.CI ? 'only-on-failure' : 'on',
    video: process.env.CI ? 'retain-on-failure' : 'on',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: {
    command: 'pnpm dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
})
```

## E2E Test Example

```typescript
// e2e/playwright/__tests__/landing.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Landing Page', () => {
  test('should load successfully', async ({ page }) => {
    await page.goto('/')
    await page.waitForLoadState('networkidle')
    await expect(page).toHaveTitle('Yield Guild Games Platform')
  })
})
```

## E2E Rules

- **Chromium only in CI** — add Firefox/WebKit for local dev if needed
- **Retries**: 2 in CI, 0 locally
- **Artifacts**: Trace on first retry, screenshot/video on failure (CI); always-on locally
- **Auto web server**: Starts `pnpm dev` automatically, reuses existing server locally
- **JUnit output**: `test-results/junit.xml` for CI integration
- Use `page.waitForLoadState('networkidle')` before assertions on page content
- Prefer `page.getByRole()` and `page.getByText()` over CSS selectors
