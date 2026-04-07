# Hexagonal Architecture (Ports and Adapters)

Hexagonal architecture (Alistair Cockburn, 2005) is the most concrete pattern for putting [separation of concerns](separation-of-concerns.md) into practice. The shape — a hexagon with the application core in the middle, ports on the edges, adapters on the outside — is a metaphor; the rules behind it are not.

## The Three Pieces

1. **Application core** — the business logic. Pure, self-contained, depends on nothing in the outside world. Knows about *interfaces* (ports), not implementations.
2. **Ports** — interfaces owned by the core that describe what the core needs from the outside ("driven" / "secondary" ports) or what the outside can ask of the core ("driving" / "primary" ports).
3. **Adapters** — concrete implementations of ports. Prisma adapter implements the persistence port; an HTTP controller drives the application through a primary port.

```
                         driving adapters
                  (HTTP, gRPC, CLI, jobs, tests)
                              │
                              ▼
                    ┌──────────────────┐
                    │  driving ports   │   ← interfaces the core EXPOSES
                    ├──────────────────┤
                    │                  │
                    │  application     │
                    │     core         │
                    │  (pure logic)    │
                    │                  │
                    ├──────────────────┤
                    │  driven ports    │   ← interfaces the core REQUIRES
                    └──────────────────┘
                              │
                              ▼
                          adapters
              (Prisma, SQS, SendGrid, Stripe, S3)
```

The key inversion: the **core defines the interfaces it needs**; adapters conform to those interfaces. The core never imports an adapter, only its own port definition.

## Driving vs Driven

- **Driving (primary) ports** are how the outside world *calls into* the core. Examples: "PlaceOrder", "GetUserProfile", "ProcessPayment". Use cases.
- **Driven (secondary) ports** are how the core *reaches out* to the world for things it can't do itself. Examples: "UserRepository", "EmailSender", "EventPublisher", "Clock", "RandomGenerator".

A controller is a *driving* adapter — it pushes a request into the core. A repository is a *driven* adapter — the core asks it for data. The naming matters because it tells you where to put the interface: driving ports live next to the use case that exposes them; driven ports live next to the domain that needs them.

## A Concrete Layout

```
src/
├── core/
│   ├── domain/                          ← entities, value objects, domain services
│   │   └── order/
│   │       ├── order.ts
│   │       ├── order-id.ts
│   │       └── order-events.ts
│   │
│   ├── ports/
│   │   ├── driving/                     ← what the outside can ask of the core
│   │   │   ├── place-order.port.ts      ← interface PlaceOrderUseCase
│   │   │   └── cancel-order.port.ts
│   │   └── driven/                      ← what the core needs from the outside
│   │       ├── order-repository.port.ts
│   │       ├── stock-reservation.port.ts
│   │       ├── event-publisher.port.ts
│   │       └── clock.port.ts
│   │
│   └── application/                     ← use cases (implement driving ports, depend on driven ports)
│       └── orders/
│           ├── place-order.ts
│           └── cancel-order.ts
│
├── adapters/
│   ├── driving/
│   │   ├── http/
│   │   │   └── order.controller.ts       ← calls PlaceOrderUseCase
│   │   ├── jobs/
│   │   │   └── retry-failed-orders.ts
│   │   └── cli/
│   │       └── place-order-command.ts
│   │
│   └── driven/
│       ├── prisma-order-repository.ts    ← implements OrderRepository
│       ├── redis-stock-reservation.ts    ← implements StockReservation
│       ├── sqs-event-publisher.ts        ← implements EventPublisher
│       └── system-clock.ts               ← implements Clock
│
└── composition-root.ts                   ← wires everything together at startup
```

A few rules baked into this layout:

- `core/` has zero imports from `adapters/`. You can verify this with an ESLint boundary rule.
- A driven port lives next to the *consumer* (the core), not next to the implementation.
- The composition root is the only file that knows about both halves.

## The Composition Root

The composition root is the single file at the entry point of your service that constructs concrete adapters and injects them into use cases. It's the **only** file that imports from both `core/` and `adapters/`.

```typescript
// composition-root.ts
import { PrismaClient } from '@prisma/client'
import { SQSClient } from '@aws-sdk/client-sqs'
import { PrismaOrderRepository } from '@/adapters/driven/prisma-order-repository'
import { SqsEventPublisher } from '@/adapters/driven/sqs-event-publisher'
import { SystemClock } from '@/adapters/driven/system-clock'
import { makePlaceOrder } from '@/core/application/orders/place-order'

export function buildContainer() {
  const prisma = new PrismaClient()
  const sqs = new SQSClient({})

  const orders = new PrismaOrderRepository(prisma)
  const events = new SqsEventPublisher(sqs, process.env.EVENTS_QUEUE_URL!)
  const clock = new SystemClock()

  return {
    placeOrder: makePlaceOrder({ orders, events, clock }),
    // ... other use cases
  }
}
```

The HTTP layer asks the container for the use case; it never news up adapters itself.

```typescript
// adapters/driving/http/order.controller.ts
import type { PlaceOrderUseCase } from '@/core/ports/driving/place-order.port'

export function makeOrderController(deps: { placeOrder: PlaceOrderUseCase }) {
  return {
    async place(req: Request, res: Response) {
      const result = await deps.placeOrder(parseInput(req))
      res.status(201).json(toDto(result))
    },
  }
}
```

No DI framework needed. Plain functions and constructors. The composition root is where wiring complexity is *contained*, not eliminated.

## Why It's Worth the Files

The first time you do this, it feels like a lot of ceremony for a CRUD service. Three things justify the cost over the medium term:

1. **Tests become trivial.** Use cases take their dependencies as parameters, so unit tests pass in fakes for ports — no `jest.mock('@/lib/prisma')` ever. You don't even need a mocking library; a literal object that implements the port works.
2. **Vendor swaps are isolated.** Replacing Prisma with Drizzle, SendGrid with Postmark, or SQS with RabbitMQ means writing one new adapter file. The core doesn't change.
3. **The core is a runnable specification of the business.** A new engineer can read `core/` and understand what the system *does* without learning the database schema or HTTP framework first.

## Testing Strategy Implied by Hexagonal

| Test type | What it covers | Setup |
|---|---|---|
| **Domain unit tests** | Entities, value objects, pure functions | No mocks. Plain object construction. |
| **Use case tests** | Application services with fake driven adapters | Hand-written fakes implementing the ports. No mocking framework. |
| **Adapter integration tests** | One adapter against the real external system | Testcontainers / real DB / real broker. One adapter at a time. |
| **End-to-end tests** | The whole service through a driving adapter | Real composition root, possibly real adapters or testcontainers. |

This is why hexagonal projects can usually delete most of their `jest.mock(...)` calls. If you're mocking a port, you've probably built a fake by hand instead — and that fake is reusable across tests.

## When NOT to Go Hexagonal

- **Throwaway scripts and prototypes.** The ceremony exceeds the benefit.
- **Pure CRUD services with no domain logic.** Two layers (routes + adapters) are honest about what the code does. Don't fake a domain model where there isn't one.
- **Wrapping a single third-party API.** Just write the adapter. The "core" would be empty.
- **You can't enforce the boundaries.** Without lint rules or strict review, the dependency arrows will inevitably reverse, and you'll have all the cost and none of the benefit.

The honest test: **can you describe a business invariant that doesn't fit cleanly in a controller or a SQL query?** If yes, go hexagonal. If no, stay flat until that day comes.

## Common Variants

- **Clean Architecture** (Robert Martin) — same idea with more ring names ("entities," "use cases," "interface adapters," "frameworks & drivers"). The dependency rule is identical.
- **Onion Architecture** (Jeffrey Palermo) — same idea with onion-skin diagrams. Same rule.
- **Functional Core, Imperative Shell** (Gary Bernhardt) — the same idea expressed in functional terms: pure core surrounded by an imperative shell that does I/O. Maps cleanly to hexagonal in TypeScript.

These are not different architectures. They're different vocabularies for the same dependency rule.

## Anti-Patterns

- **Domain imports an adapter.** The most common failure. Lint rule:
  ```json
  // .eslintrc — eslint-plugin-boundaries
  { "boundaries/elements": [
    { "type": "core", "pattern": "src/core/**" },
    { "type": "adapters", "pattern": "src/adapters/**" }
  ]}
  ```
  Forbid `core` from importing `adapters`.
- **"Just one quick query"** in a controller — bypassing the use case to call Prisma directly. Once one slips in, dozens follow.
- **Ports with five methods, of which any consumer uses one.** Split the port. ISP applies here too.
- **Returning ORM types from a repository.** The core now depends on Prisma's row shape. Map at the adapter boundary.
- **Use case calls another use case.** Hint of a missing domain service, or a missing application helper. Don't let the application layer turn into spaghetti.
- **Adapter that owns business logic.** "I'll just compute the discount in the SQL query." Now the discount rule lives outside the domain. Don't.

## Related

- [separation-of-concerns.md](separation-of-concerns.md) — the dependency rule and where each kind of logic belongs
- [solid.md](solid.md) — DIP is hexagonal in miniature
- [tactical-ddd.md](tactical-ddd.md) — what to put inside the core
- [code-review-heuristics.md](code-review-heuristics.md) — how to spot layering violations
