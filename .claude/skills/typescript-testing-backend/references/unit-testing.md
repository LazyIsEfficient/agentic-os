# Unit Testing Services and Controllers

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
