---
name: typescript-quality-engineering
description: This skill provides quality engineering rules for writing automated tests — unit, integration, and end-to-end — using Jest, React Testing Library, Playwright, Supertest, and Hardhat. Automatically loaded when writing tests, reviewing test quality, debugging test failures, or when "test", "unit test", "integration test", "e2e", "Playwright", "coverage", "QA", "quality", or "test automation" are mentioned.
---

# Quality Engineering Rules (TypeScript)

## Test Frameworks

| Layer | Framework | Config |
|---|---|---|
| Unit (frontend) | Jest 29.7.0 + React Testing Library 16.x | `config/jest/jest.config.js` |
| Unit (backend) | Jest 29.7.0 + Supertest | Same config, `testEnvironment: 'jsdom'` |
| Unit (contracts) | Hardhat + Chai + Ethers.js | `hardhat.config.ts` |
| Integration (API) | Jest + Supertest + real PostgreSQL | `*.integration.test.ts` |
| Integration (hooks) | Jest + renderHook + React Query | `*.test.tsx` with wrapper |
| End-to-end | Playwright 1.56.1 | `playwright.config.ts` |

### Key Dependencies

```
jest                               ^29.7.0
@swc/jest                          # Fast TS compilation (not Babel)
@testing-library/react             ^16.2.0
@testing-library/jest-dom          ^6.6.3
@testing-library/dom               ^10.4.0
@playwright/test                   ^1.56.1
supertest                          # HTTP integration testing
jest-junit                         # JUnit XML for CI
jest-canvas-mock                   # Canvas polyfill for jsdom
```

### Test Scripts

```json
{
  "test": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js",
  "test:ci": "jest --config ... --maxWorkers=2 --ci",
  "e2e": "playwright test && npx shortest --headless",
  "e2e:playwright": "playwright test",
  "e2e:playwright:ci": "playwright test --reporter=list,junit"
}
```

## Directory Structure and Naming

Tests live in co-located `__tests__/` folders:

```
apps/platform-app/
├── app/api/v1/
│   ├── activities/
│   │   ├── controllers/activities.controller.ts
│   │   ├── services/activities.service.ts
│   │   └── __tests__/
│   │       ├── get-activities.integration.test.ts
│   │       ├── get-activity-by-slug.integration.test.ts
│   │       ├── enroll-activity.integration.test.ts
│   │       └── shared-test-setup.ts
│   └── shared/test-utils/
│       ├── test-database.ts
│       ├── server-mock.ts
│       └── mocks/
│           ├── authentication-mock.ts
│           ├── network-config-mock.ts
│           └── thirdweb-mock.ts
├── domains/
│   ├── quests/
│   │   ├── components/quest-tasks/__tests__/TaskItem.test.tsx
│   │   └── hooks/__tests__/useQuestFilterGroup.test.tsx
│   └── profile/
│       ├── components/__tests__/ProfileStats.test.tsx
│       └── hooks/__tests__/useProfileData.test.ts
├── e2e/playwright/__tests__/*.spec.ts
├── test-utils/render.tsx
└── config/jest/
    ├── jest.config.js
    ├── jest.setup.js
    └── env.setup.js
```

| Type | Pattern | Example |
|---|---|---|
| Component unit | `{ComponentName}.test.tsx` | `TaskItem.test.tsx` |
| Hook unit | `use{HookName}.test.ts/tsx` | `useProfileData.test.ts` |
| Service unit | `{module}.service.test.ts` | `faq.service.test.ts` |
| Controller unit | `{module}.controller.test.ts` | `faq.controller.test.ts` |
| API integration | `{action}.integration.test.ts` | `get-activities.integration.test.ts` |
| E2E | `{feature}.spec.ts` | `landing.spec.ts` |
| Smart contract | `{contract}.test.ts` | `payment_code.test.ts` |

---

## Unit Testing — Components

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

### Custom Render with Providers

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

### Query Priority

Prefer accessibility-first queries:

1. `getByRole('button', { name: /submit/i })` — semantic, best
2. `getByText('Submit')` — visible text
3. `getByLabelText('Email')` — form controls
4. `getByTestId('submit-btn')` — last resort

Use `queryBy*` to assert absence:

```typescript
expect(screen.queryByText('Error')).not.toBeInTheDocument()
```

### User Interactions

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

### Mocking Patterns

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

---

## Unit Testing — Hooks

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

### Async Hook Testing

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

---

## Unit Testing — Backend Services

Mock Prisma at the module boundary:

```typescript
jest.mock('@repo/prisma', () => ({
  prisma: {
    faqArticle: { findMany: jest.fn() },
  },
}))

import { prisma } from '@repo/prisma'

describe('FaqService', () => {
  const mockPrisma = prisma as jest.Mocked<typeof prisma>

  beforeEach(() => jest.clearAllMocks())

  it('returns articles ordered by order ascending', async () => {
    const mockArticles = [{ id: '1', title: 'Article 1', order: 1 }]
    mockPrisma.faqArticle.findMany.mockResolvedValue(mockArticles)

    const result = await faqService.getArticles()

    expect(result).toEqual(mockArticles)
    expect(mockPrisma.faqArticle.findMany).toHaveBeenCalledWith({
      orderBy: { order: 'asc' },
    })
  })
})
```

## Unit Testing — Backend Controllers

Inject typed mock of the service:

```typescript
describe('FaqController', () => {
  let faqController: FaqController
  let mockFaqService: jest.Mocked<Pick<FaqService, 'getArticles'>>

  beforeEach(() => {
    mockFaqService = { getArticles: jest.fn() }
    faqController = new FaqController(mockFaqService as FaqService)
  })

  it('returns articles from service', async () => {
    mockFaqService.getArticles.mockResolvedValue([{ id: '1', title: 'Article 1' }])
    const result = await faqController.getArticles()
    expect(result).toEqual([{ id: '1', title: 'Article 1' }])
  })
})
```

---

## Integration Testing — API Routes

Integration tests use a **real PostgreSQL database** and a custom **TestServer** that simulates Next.js route handlers.

### Test Database

The `TestDatabase` class creates an isolated PostgreSQL database per test run:

```typescript
// shared/test-utils/test-database.ts
export class TestDatabase {
  async setup() {
    await this.createTestDatabase()    // CREATE DATABASE test_{uuid}
    await this.runMigrations()         // prisma migrate reset --force
    await this.seedTestData()          // Run seed scripts
    await this.prisma.$connect()
  }

  async teardown() {
    await this.prisma.$disconnect()
    await this.dropTestDatabase()      // DROP DATABASE
  }

  async cleanupTestData() {
    // TRUNCATE all tables with FK checks disabled
    // SET session_replication_role = replica
  }
}
```

### TestServer

Simulates Next.js route handlers with dynamic segment matching:

```typescript
// shared/test-utils/server-mock.ts
export class TestServer {
  constructor(options: { controllers: Record<string, Record<string, Function>> }) { }
  // Handles: route matching with :slug params, JSON body parsing,
  // error mapping (UnauthorizedError → 401, NotFoundError → 404, etc.)
  async start(): Promise<number> { }  // Listens on auto-assigned port
  async stop(): Promise<void> { }
  getServer() { }  // Returns http.Server for Supertest
}
```

### Authentication Helpers

```typescript
// shared/test-utils/mocks/authentication-mock.ts
export const authTestHelpers = {
  mockAuthenticatedUser: (userId = 'user-1', email?, walletAddress?) => {
    // Sets session service mock + RequestAuthContext
  },
  mockUnauthenticatedUser: () => {
    // Clears session + RequestAuthContext
  },
  mockAuthenticationError: (msg = 'Authentication failed') => {
    // Rejects session lookup
  },
  clearMocks: () => {
    jest.clearAllMocks()
    RequestAuthContext.clear()
  },
}
```

### Shared Test Setup Pattern

Each API domain has a `shared-test-setup.ts`:

```typescript
// app/api/v1/activities/__tests__/shared-test-setup.ts
export async function setupTestEnvironment() {
  testPrisma = await setupTestDatabase()
  jest.mock('@repo/prisma', () => ({ prisma: testPrisma }))
  testServer = await createActivitiesTestServer()
  server = testServer.getServer()
  await testServer.start()
}

export async function teardownTestEnvironment() {
  if (testServer) await testServer.stop()
  await teardownTestDatabase()
}

export async function resetTestState() {
  authTestHelpers.clearMocks()
  await testPrisma.userActivityTask.deleteMany({
    where: { createdAt: { gte: new Date(Date.now() - 3600000) } },
  })
}
```

### Integration Test Example

```typescript
import request from 'supertest'

describe('GET /api/v1/activities/:slug - Integration Tests', () => {
  beforeAll(async () => { await setupTestEnvironment() })
  afterAll(async () => { await teardownTestEnvironment() })
  beforeEach(async () => { await resetTestState() })

  it('returns activity by slug for unauthenticated user', async () => {
    authTestHelpers.mockUnauthenticatedUser()

    const activity = await testPrisma.activity.findFirst()
    const response = await request(server)
      .get(`/api/v1/activities/${activity.slug}`)
      .expect(200)

    expect(response.body.slug).toBe(activity.slug)
    expect(response.body.tasks).toBeDefined()
  })

  it('returns activity with user tasks for authenticated user', async () => {
    const user = await testPrisma.user.findFirst()
    const activity = await testPrisma.activity.findFirst({ include: { tasks: true } })

    await testPrisma.userActivity.create({
      data: {
        userId: user.id,
        activityId: activity.id,
        state: 'in_progress',
        enrolledAt: new Date(),
      },
    })

    authTestHelpers.mockAuthenticatedUser(user.id)

    const response = await request(server)
      .get(`/api/v1/activities/${activity.slug}`)
      .expect(200)

    expect(response.body.tasks[0]).toHaveProperty('userActivityTask')
    expect(response.body.tasks[0].userActivityTask.state).toBe('in_progress')
  })

  it('returns 404 for non-existent activity', async () => {
    authTestHelpers.mockUnauthenticatedUser()
    await request(server).get('/api/v1/activities/non-existent').expect(404)
  })
})
```

### Data Cleanup Rules

- **Clean only test-created records** — don't truncate seeded baseline data
- Use `deleteMany` with time-based or prefix-based filters
- Each test creates its own data — never depend on another test's records
- Use `beforeEach` for cleanup, not `afterEach` (ensures clean state even after failures)

---

## End-to-End Testing — Playwright

### Configuration

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

### E2E Test Example

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

### E2E Rules

- **Chromium only in CI** — add Firefox/WebKit for local dev if needed
- **Retries**: 2 in CI, 0 locally
- **Artifacts**: Trace on first retry, screenshot/video on failure (CI); always-on locally
- **Auto web server**: Starts `pnpm dev` automatically, reuses existing server locally
- **JUnit output**: `test-results/junit.xml` for CI integration
- Use `page.waitForLoadState('networkidle')` before assertions on page content
- Prefer `page.getByRole()` and `page.getByText()` over CSS selectors

---

## Smart Contract Testing

### Hardhat + Chai + Ethers.js

```typescript
import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('Faucet Contract', function () {
  let mockERC20: CollateralizedToken
  let signer: Signer
  let bob: Signer

  before(async function () {
    const signers = await ethers.getSigners()
    signer = signers[0]

    bob = ethers.Wallet.createRandom().connect(signer.provider)
    await signer.sendTransaction({
      to: await bob.getAddress(),
      value: ethers.parseEther('1.0'),
    })

    const tokenFactory = await ethers.getContractFactory('CollateralizedToken')
    mockERC20 = await tokenFactory.deploy('Test Token', 'TEST')
    await mockERC20.waitForDeployment()
  })

  it('enforces withdraw limit', async function () {
    const decimals = await mockERC20.decimals()
    const limit = BigInt(10 ** Number(decimals)) * 1000n

    const factory = await ethers.getContractFactory('Faucet')
    const faucet = await factory.connect(signer).deploy(limit, await mockERC20.getAddress())
    await faucet.waitForDeployment()

    expect(await faucet.withdrawLimit()).to.equal(limit)

    await mockERC20.transfer(await faucet.getAddress(), limit * 2n)
    await faucet.connect(bob).faucet()

    expect(await mockERC20.balanceOf(await bob.getAddress())).to.equal(limit)
  })
})
```

### Time Manipulation

```typescript
import * as helpers from '@nomicfoundation/hardhat-network-helpers'

const currentTime = await helpers.time.latest()
await helpers.time.increase(3600)       // advance 1 hour
await helpers.time.increaseTo(target)   // advance to specific timestamp
await helpers.mine(10)                  // mine 10 blocks
```

### Event Assertions

```typescript
await expect(proxy.executeProposal(1))
  .to.emit(proxy, 'ProposalExecuted')
  .withArgs(1, owner.address)
```

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/monorepo.ci.yml
jobs:
  run_unit_and_integration_tests:
    runs-on: platform-app-testing-ci-runner
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: platform_test
          POSTGRES_HOST_AUTH_METHOD: trust
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm run prisma:generate
      - run: pnpm turbo run build --filter=@repo/* --filter=!@repo/evm-indexer
      - run: pnpm -w run platform-app-unit-integration-tests
        env:
          CI: 'true'
          POSTGRES_PRISMA_URL: 'postgresql://testuser:testpass@localhost:5432/platform_test'
          POSTGRES_URL_NON_POOLING: 'postgresql://testuser:testpass@localhost:5432/platform_test'
```

### Coverage

- `collectCoverage: true` in Jest config
- JUnit XML output: `test-results/jest/results.xml` (Jest), `test-results/junit.xml` (Playwright)
- No explicit coverage thresholds — enforced via code review

### Smart Contract CI

```yaml
# Foundry tests
- uses: foundry-rs/foundry-toolchain@v1
  with: { version: nightly }
- run: forge build --sizes
- run: forge test -vvv
```

---

## Test Quality Rules

### Every Test Must

1. **Assert observable behavior** — at least one `expect()` per `it()` block
2. **Be independent** — no test depends on another test's state or execution order
3. **Be deterministic** — same result every run, no flaky timing dependencies
4. **Use literal expected values** — `expect(total).toBe(70)`, not `expect(total).toBe(a + b)`

### Do Not

- Use `test.skip()` or comment out tests — fix or delete them
- Share mutable state between tests without cleanup
- Assert implementation details — test behavior, not internal method calls
- Use `sleep()` or arbitrary timeouts — use `waitFor()` or event-based waits

### Mock Scope

| Dependency | Unit Tests | Integration Tests |
|---|---|---|
| Prisma / database | `jest.mock('@repo/prisma')` | Real test database |
| Auth session | `jest.mock(...)` | `authTestHelpers` |
| External APIs | `jest.mock(...)` | `jest.mock(...)` |
| React Query | QueryClient with `retry: false` | Same |
| Internal utils | Real implementation | Real implementation |

### Test Failure Response

- **Fix the test**: Wrong expected values, coupled to implementation details, flaky assertions
- **Fix the implementation**: Valid business rules, edge cases, contract violations
- **When in doubt**: Confirm with the team before changing either
