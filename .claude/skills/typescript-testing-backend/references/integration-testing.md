# Integration Testing with Supertest

Integration tests use a real PostgreSQL database and a custom `TestServer` that simulates Next.js route handlers.

## Shared Test Setup

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

## Integration Test

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
