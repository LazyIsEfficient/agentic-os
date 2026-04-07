# Separation of Concerns

A *concern* is anything a stakeholder cares about: a business rule, a transport mechanism, a persistence detail, an authentication check, a logging policy. Separation of concerns means giving each one its own place in the code so that changes to one don't ripple through the others.

The opposite — code where business rules, SQL, HTTP parsing, and email templates live in the same function — is "the big ball of mud." It works, until it doesn't.

## The Dependency Rule

> **Source code dependencies must point inward, toward higher-level policies.**
> — Robert Martin, *Clean Architecture*

Picture concentric rings:

```
   ┌──────────────────────────────────┐
   │    transport (HTTP, gRPC, CLI)   │  ← outer ring
   │  ┌────────────────────────────┐  │
   │  │   application services     │  │
   │  │  ┌──────────────────────┐  │  │
   │  │  │   domain model       │  │  │  ← inner ring
   │  │  │   (entities, rules)  │  │  │
   │  │  └──────────────────────┘  │  │
   │  └────────────────────────────┘  │
   │                                  │
   │  infrastructure (DB, brokers,    │
   │  email, third-party APIs)        │
   └──────────────────────────────────┘
```

Two rules:

1. **Source dependencies cross only inward.** Outer rings import from inner rings, never the reverse.
2. **The inner ring defines interfaces; the outer ring implements them.** This is the Dependency Inversion Principle applied at the architectural scale.

If your `Order` entity imports from `@/lib/prisma`, you've crossed the wrong way and you've coupled your business rules to a vendor.

## A TypeScript Project Layout That Respects This

```
src/
├── domain/                ← inner ring: pure business rules, no infra imports
│   ├── order/
│   │   ├── order.ts             ← Order aggregate, invariants, methods
│   │   ├── order-id.ts          ← value object
│   │   ├── order-events.ts      ← domain events
│   │   └── order-repository.ts  ← INTERFACE only, no implementation
│   └── pricing/
│       └── price-calculator.ts  ← pure function, no I/O
│
├── application/           ← use cases: orchestrate domain + ports
│   └── orders/
│       ├── place-order.ts       ← "place order" use case
│       └── cancel-order.ts
│
├── infrastructure/        ← outer ring: adapters that implement domain interfaces
│   ├── persistence/
│   │   └── prisma-order-repository.ts  ← implements OrderRepository
│   ├── messaging/
│   │   └── sqs-event-publisher.ts
│   └── email/
│       └── sendgrid-email-sender.ts
│
├── transport/             ← outer ring: how the world reaches the app
│   ├── http/
│   │   ├── routes/orders.ts
│   │   └── controllers/order.controller.ts
│   └── jobs/
│       └── consume-order-events.ts
│
└── composition-root.ts    ← wires concrete adapters into use cases
```

Inside `domain/`, **no file imports from `infrastructure/` or `transport/`**, ever. You can enforce this with an ESLint rule (`eslint-plugin-boundaries`) so it isn't aspirational.

## Where Each Kind of Logic Belongs

This is the most common question once you commit to layering. Use this table:

| Logic | Layer | Example |
|---|---|---|
| HTTP parsing, status codes, headers | Transport (controller) | "Return 404 if not found" |
| Authentication & authorization | Transport / application boundary | "Reject if user lacks role" |
| Input validation (shape) | Transport / application boundary | Zod schemas at the controller |
| Business rules, invariants, calculations | Domain | "Cannot ship an order with zero items" |
| Coordinating multiple aggregates / services | Application service (use case) | "Place order: reserve stock, charge card, persist, publish event" |
| Transactions | Application service | `prisma.$transaction(...)` wraps the use case |
| SQL, query shape, ORM specifics | Infrastructure (repository adapter) | `prisma.order.findMany(...)` |
| External API calls | Infrastructure (adapter) | Stripe, SendGrid, S3 |
| Background jobs / cron triggers | Transport (jobs) | Calls into application services |
| Logging / metrics / tracing | Cross-cutting (decorator or middleware) | Wraps adapters and use cases |

### A worked example

Place-order use case, layered correctly:

```typescript
// transport/http/controllers/order.controller.ts
import { z } from 'zod'
import { placeOrder } from '@/application/orders/place-order'

const PlaceOrderBody = z.object({
  customerId: z.string().uuid(),
  items: z.array(z.object({ sku: z.string(), quantity: z.number().int().positive() })).min(1),
})

export async function placeOrderHandler(req: Request, res: Response) {
  const body = PlaceOrderBody.parse(req.body)         // shape validation
  const userId = await requireUser(req)               // authn
  await assertCanPlaceOrder(userId, body.customerId)  // authz

  const order = await placeOrder(deps, { customerId: body.customerId, items: body.items, placedBy: userId })
  res.status(201).json(toOrderDto(order))             // transport mapping
}
```

```typescript
// application/orders/place-order.ts
import type { OrderRepository } from '@/domain/order/order-repository'
import type { StockReservation } from '@/domain/inventory/stock-reservation'
import type { EventPublisher } from '@/application/ports/event-publisher'
import { Order } from '@/domain/order/order'

export interface PlaceOrderDeps {
  orders: OrderRepository
  stock: StockReservation
  events: EventPublisher
  unitOfWork: UnitOfWork
}

export async function placeOrder(deps: PlaceOrderDeps, input: PlaceOrderInput): Promise<Order> {
  return deps.unitOfWork.run(async () => {
    await deps.stock.reserve(input.items)             // coordinate aggregates
    const order = Order.place(input)                  // domain method enforces invariants
    await deps.orders.save(order)                     // persist via interface
    await deps.events.publishAll(order.pullEvents())  // publish domain events
    return order
  })
}
```

```typescript
// domain/order/order.ts — pure, no infra imports
export class Order {
  private events: DomainEvent[] = []

  private constructor(
    readonly id: OrderId,
    readonly customerId: CustomerId,
    readonly items: ReadonlyArray<OrderLine>,
    readonly status: OrderStatus,
  ) {}

  static place(input: PlaceOrderInput): Order {
    if (input.items.length === 0) throw new DomainError('Order must have at least one item')
    const order = new Order(OrderId.generate(), CustomerId.from(input.customerId), input.items.map(OrderLine.from), 'placed')
    order.events.push(new OrderPlaced(order.id, order.customerId))
    return order
  }

  pullEvents(): DomainEvent[] {
    const out = this.events
    this.events = []
    return out
  }
}
```

```typescript
// infrastructure/persistence/prisma-order-repository.ts
import type { OrderRepository } from '@/domain/order/order-repository'
import { Order } from '@/domain/order/order'

export class PrismaOrderRepository implements OrderRepository {
  constructor(private readonly prisma: PrismaClient) {}
  async save(order: Order): Promise<void> {
    await this.prisma.order.upsert({ /* ... */ })
  }
  async findById(id: OrderId): Promise<Order | null> { /* ... */ }
}
```

Notice:

- The HTTP controller validates shape, handles auth, and maps DTOs. It contains no business logic.
- The application service orchestrates collaborators inside a transaction. It contains no business *rules* — those live on the entity.
- The domain entity enforces the invariant ("at least one item"). It depends on nothing outside the domain layer.
- The Prisma adapter implements the interface defined by the domain. The domain has no idea Prisma exists.

## When to Layer (and When Not To)

Layering has a real cost: more files, more indirection, more wiring. It pays off at scale and hurts at small scale.

| Project shape | Recommendation |
|---|---|
| Throwaway prototype, single file | Don't bother |
| Small CRUD service, one team, stable scope | Two layers: routes + services. Skip the domain layer until you have invariants worth enforcing |
| Service with complex business rules, multiple teams, long lifetime | Full layering: transport / application / domain / infrastructure |
| Service that wraps a third-party API with no real business logic | Two layers: routes + adapters. There's no domain to model |

The trigger to add a layer is **rules that don't fit anywhere**. When your service file starts holding "if the customer is a returning EU buyer in the last 30 days, apply this discount unless the SKU is on the blocklist," that rule wants to live in a domain object.

## Cross-Cutting Concerns

Logging, metrics, tracing, retries, authorization checks — these touch every layer. Two ways to handle them without polluting business code:

1. **Decorators / wrappers around adapters and use cases.** A `LoggingOrderRepository` wraps a `PrismaOrderRepository` and adds a log line per call. Composition.
2. **Middleware in transport.** Authentication, request logging, and tracing live in HTTP middleware, not in controllers.

What you do **not** do: pepper `logger.info(...)` into domain methods. That's a layering violation and it makes pure logic impure.

## Anti-Patterns

- **Anemic domain model** — entities are bags of getters and setters; all logic lives in services. The "domain" is just data. (See [tactical-ddd.md](tactical-ddd.md) for the fix.)
- **Smart UI / fat controller** — controllers contain business rules. When a CLI or background job needs the same rule, it gets duplicated.
- **Repository that returns ORM rows** — the rest of the codebase ends up coupled to the ORM shape. Repositories should return domain objects.
- **Domain calls infrastructure** — `Order.save()` that internally calls Prisma. The entity now imports the database.
- **God service** — one application service file with thirty methods covering an entire bounded context. Split by use case.
- **Use case calls another use case** — orchestration starts cascading. Either extract the shared logic to the domain or to a smaller application helper, or rethink the boundary.

## Related

- [hexagonal-architecture.md](hexagonal-architecture.md) — the same idea expressed as ports and adapters
- [solid.md](solid.md) — DIP is the formalism behind the dependency rule
- [tactical-ddd.md](tactical-ddd.md) — what goes in the domain layer
- [code-review-heuristics.md](code-review-heuristics.md) — how to spot layering violations in a PR
