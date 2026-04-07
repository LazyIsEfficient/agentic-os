# Database Testing

## Setup and Teardown

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

## Data Cleanup Between Tests

Clean only the records your tests create — don't truncate seed data:

```typescript
beforeEach(async () => {
  // Clean only test-created records
  await testPrisma.pointTransaction.deleteMany({})
  await testPrisma.project.deleteMany({ where: { slug: { startsWith: 'test-' } } })
})
```

## Accessing Seeded Data

Integration tests can read seeded baseline data directly:

```typescript
it('should return seeded categories', async () => {
  const category = await testPrisma.pointCategories.findFirst()
  expect(category).not.toBeNull()
})
```
