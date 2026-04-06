---
name: typescript-testing-backend
description: This skill provides backend testing rules with Jest, real PostgreSQL integration patterns, and service-level testing conventions. Automatically loaded when writing backend tests, reviewing test quality, or when "backend test", "service test", "API test", "integration test", "database test", or "backend test coverage" are mentioned.
---

# TypeScript Testing Rules (Backend)

## Test Framework

- **Jest 29.7.0**: Primary test runner (not Vitest)
- **@swc/jest**: TypeScript transpiler (fast SWC-based compilation)
- **Supertest**: For HTTP endpoint testing via custom `TestServer`
- **Test environment**: `jsdom`
- **Config**: `apps/platform-app/config/jest/jest.config.js`
- **Test scripts**:
  ```json
  "test": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js"
  "test:ci": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js --maxWorkers=2 --ci"
  ```
- **Mocks**: Use `jest.mock()` and `jest.fn()` — not `vi.mock()` / `vi.fn()`

## Directory Structure

Tests live in co-located `__tests__/` folders next to source files:

```
apps/platform-app/
├── app/api/v1/
│   ├── faq/
│   │   ├── services/faq.service.ts
│   │   ├── controllers/faq.controller.ts
│   │   └── __tests__/
│   │       ├── faq.service.test.ts
│   │       └── faq.controller.test.ts
│   ├── points/
│   │   └── __tests__/
│   │       ├── get-points.integration.test.ts
│   │       └── shared-test-setup.ts
│   └── shared/test-utils/        ← Shared backend test utilities
│       ├── test-database.ts
│       ├── server-mock.ts
│       └── mocks/
│           ├── authentication-mock.ts
│           ├── network-config-mock.ts
│           ├── common-mock.ts
│           └── thirdweb-mock.ts
└── test-utils/render.tsx          ← Frontend test utilities
```

## Naming Conventions

| Type | Pattern | Example |
|---|---|---|
| Service tests | `{module}.service.test.ts` | `faq.service.test.ts` |
| Controller tests | `{module}.controller.test.ts` | `faq.controller.test.ts` |
| Integration tests | `{feature}.integration.test.ts` | `get-points.integration.test.ts` |
| Component tests | `{ComponentName}.test.tsx` | `ProfileStats.test.tsx` |
| Hook tests | `use{HookName}.test.ts/tsx` | `useProfileData.test.ts` |

## Coverage Configuration

Coverage is **enabled by default** (`collectCoverage: true`). CI outputs JUnit XML to `test-results/jest/results.xml`. No explicit thresholds are configured — rely on code review and PR process.

## Unit Testing Services

Mock Prisma at the module boundary using `jest.mock()`:

```typescript
jest.mock('@repo/prisma', () => ({
  prisma: {
    faqArticle: {
      findMany: jest.fn(),
    },
  },
}));

import { prisma } from '@repo/prisma'
import { FaqService } from '../services/faq.service'

describe('FaqService', () => {
  const mockPrisma = prisma as jest.Mocked<typeof prisma>

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should return articles ordered by order ascending', async () => {
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

## Unit Testing Controllers

Inject a typed mock of the service:

```typescript
import { FaqController } from '../controllers/faq.controller'
import { FaqService } from '../services/faq.service'

describe('FaqController', () => {
  let faqController: FaqController
  let mockFaqService: jest.Mocked<Pick<FaqService, 'getArticles'>>

  beforeEach(() => {
    mockFaqService = {
      getArticles: jest.fn(),
    }
    faqController = new FaqController(mockFaqService as FaqService)
  })

  it('should return articles from service', async () => {
    const mockArticles = [{ id: '1', title: 'Article 1' }]
    mockFaqService.getArticles.mockResolvedValue(mockArticles)

    const result = await faqController.getArticles()

    expect(result).toEqual(mockArticles)
  })
})
```

## Integration Testing with Supertest

Integration tests use a real PostgreSQL database and a custom `TestServer` that simulates Next.js route handlers.

### Shared Test Setup

```typescript
// __tests__/shared-test-setup.ts
import { setupTestDatabase } from '@/app/api/v1/shared/test-utils/test-database'
import { createPointsTestServer } from './test-server'

export let testPrisma: PrismaClient
export let server: Server

export async function setupTestEnvironment() {
  testPrisma = await setupTestDatabase()

  jest.mock('@repo/prisma', () => ({ prisma: testPrisma }))

  const testServer = await createPointsTestServer()
  server = testServer.getServer()
  await testServer.start()
}
```

### Integration Test

```typescript
import request from 'supertest'
import { setupTestEnvironment, testPrisma, server } from './shared-test-setup'
import { authTestHelpers } from '@/app/api/v1/shared/test-utils/mocks/authentication-mock'

describe('GET /api/v1/points - Integration Tests', () => {
  beforeAll(async () => {
    await setupTestEnvironment()
  })

  beforeEach(async () => {
    await testPrisma.pointTransaction.deleteMany({})
    authTestHelpers.clearMocks()
  })

  it('should return user points', async () => {
    const userId = 'test-user-id'
    authTestHelpers.mockAuthenticatedUser(userId)

    await testPrisma.pointTransaction.createMany({
      data: [
        { userId, points: 40, categoryId: 'cat-1' },
        { userId, points: 30, categoryId: 'cat-2' },
      ],
    })

    const response = await request(server)
      .get('/api/v1/points')
      .expect(200)

    expect(response.body.totalPoints).toBe(70)
    expect(response.body.userId).toBe(userId)
  })

  it('should return 401 when unauthenticated', async () => {
    authTestHelpers.mockUnauthenticatedUser()

    await request(server).get('/api/v1/points').expect(401)
  })
})
```

## TestServer Pattern

The `TestServer` class in `shared/test-utils/server-mock.ts` simulates Next.js route handlers, handles dynamic route segments, parses query params, and maps error types to HTTP status codes:

```typescript
// apps/platform-app/app/api/v1/projects/__tests__/test-server.ts
export function createProjectsTestServer() {
  return new TestServer({
    '/api/v1/projects': {
      GET: async (args) => {
        const { GetProjectsQuerySchema } = await import('@/app/api/v1/projects/projects.schemas')
        const validatedQuery = GetProjectsQuerySchema.parse(args.query || {})
        return projectsController.getProjects({ query: validatedQuery })
      },
    },
  })
}
```

## Authentication Mocking

Use `authTestHelpers` from the shared test-utils for all auth state:

```typescript
import { authTestHelpers } from '@/app/api/v1/shared/test-utils/mocks/authentication-mock'

// Mock an authenticated user
authTestHelpers.mockAuthenticatedUser(userId, email?, walletAddress?)

// Mock unauthenticated state
authTestHelpers.mockUnauthenticatedUser()

// Mock an auth error
authTestHelpers.mockAuthenticationError('Session expired')

// Reset auth mocks between tests
authTestHelpers.clearMocks()
```

## Database Testing

### Setup and Teardown

The `TestDatabase` class creates an isolated PostgreSQL database per test run:

- Creates a unique database: `test_{randomUUID}`
- Runs `npx prisma migrate reset --force`
- Seeds from `scripts/run-seed.ts`
- Drops the database on teardown

```typescript
import { setupTestDatabase } from '@/app/api/v1/shared/test-utils/test-database'

let testPrisma: PrismaClient

beforeAll(async () => {
  testPrisma = await setupTestDatabase() // creates isolated DB + migrations + seed
})

afterAll(async () => {
  await testPrisma.$disconnect()
  // TestDatabase drops the DB automatically
})
```

### Data Cleanup Between Tests

Clean only the records your tests create — don't truncate seed data:

```typescript
beforeEach(async () => {
  // Clean only test-created records
  await testPrisma.pointTransaction.deleteMany({})
  await testPrisma.project.deleteMany({ where: { slug: { startsWith: 'test-' } } })
})
```

### Accessing Seeded Data

Integration tests can read seeded baseline data directly:

```typescript
it('should return seeded categories', async () => {
  const category = await testPrisma.pointCategories.findFirst()
  expect(category).not.toBeNull()
})
```

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
