# Unit Testing — Backend Services and Controllers

## Backend Services

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

## Backend Controllers

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
