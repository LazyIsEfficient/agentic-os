# Integration Testing — API Routes

Integration tests use a **real PostgreSQL database** and a custom **TestServer** that simulates Next.js route handlers.

## Test Database

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

## TestServer

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

## Authentication Helpers

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

## Shared Test Setup Pattern

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

## Integration Test Example

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

## Data Cleanup Rules

- **Clean only test-created records** — don't truncate seeded baseline data
- Use `deleteMany` with time-based or prefix-based filters
- Each test creates its own data — never depend on another test's records
- Use `beforeEach` for cleanup, not `afterEach` (ensures clean state even after failures)
