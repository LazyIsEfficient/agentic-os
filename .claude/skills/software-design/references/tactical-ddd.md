# Tactical DDD — Building Blocks

The tactical patterns are the shapes you reach for *inside* a bounded context: entities, value objects, aggregates, repositories, domain services, and domain events. Each one is a tool with a specific job. None of them are mandatory — pick the ones that help with the rules you actually have. For the strategic context (where boundaries go, ubiquitous language) see [domain-modeling.md](domain-modeling.md).

## Entity vs Value Object

The most useful distinction in tactical DDD.

### Value Object

A value object is **identified by its data**. Two value objects with the same fields are interchangeable. They are immutable.

```typescript
class Money {
  constructor(readonly amount: number, readonly currency: Currency) {
    if (amount < 0) throw new DomainError('Money cannot be negative')
    if (!Number.isFinite(amount)) throw new DomainError('Money must be finite')
  }

  static usd(amount: number): Money { return new Money(amount, 'USD') }

  add(other: Money): Money {
    if (other.currency !== this.currency) throw new DomainError('Currency mismatch')
    return new Money(this.amount + other.amount, this.currency)
  }

  multiply(factor: number): Money {
    return new Money(Math.round(this.amount * factor), this.currency)
  }

  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency
  }
}
```

Properties of a good value object:

- **Immutable.** Operations return new instances; never mutate.
- **Self-validating.** Invariants enforced in the constructor. Once you have a `Money`, you know it's valid.
- **No identity.** Two `Money(100, 'USD')` are the same money. There is no "this particular hundred dollars."
- **Behavior, not just data.** Methods like `add`, `multiply`, `format` belong on the value object, not on a service.

Things that should usually be value objects: `Money`, `EmailAddress`, `PhoneNumber`, `Address`, `DateRange`, `Coordinates`, `Percentage`, `Currency`, `Color`. Anything you'd otherwise model as a primitive ([primitive obsession](cohesion-and-coupling.md)).

### Entity

An entity is **identified by an ID**, not by its data. Two entities with the same fields but different IDs are *different*. Entities have a lifecycle.

```typescript
class Order {
  private constructor(
    readonly id: OrderId,
    readonly customerId: CustomerId,
    private items: OrderLine[],
    private status: OrderStatus,
  ) {}

  static place(input: PlaceOrderInput): Order { /* ... */ }

  cancel(reason: CancellationReason): void {
    if (this.status === 'shipped') throw new DomainError('Cannot cancel a shipped order')
    if (this.status === 'cancelled') return // idempotent
    this.status = 'cancelled'
  }

  total(): Money {
    return this.items.reduce((sum, line) => sum.add(line.subtotal()), Money.usd(0))
  }
}
```

Properties of a good entity:

- **Has an ID** that doesn't change over its lifetime.
- **Mutable, but only through its own methods.** No external code reaches in and sets fields.
- **Enforces invariants** in its methods. Methods *fail loudly* when invariants would be violated.
- **Has behavior tied to its lifecycle.** Methods describe what happens to the entity, not just what data it holds.

The contrast with the **anemic domain model** anti-pattern is sharp: an anemic `Order` has fields and getters/setters, and all the rules ("cannot cancel a shipped order") live in services. The class above puts the rule on the entity, where it can't be bypassed.

## Aggregates and Aggregate Roots

An **aggregate** is a cluster of entities and value objects treated as a single unit for the purposes of consistency and persistence. The **aggregate root** is the one entity through which all access to the aggregate flows.

The classic example: an `Order` aggregate contains `OrderLines`. Outside code never touches `OrderLine` directly — it goes through the `Order`.

```typescript
class Order {  // aggregate root
  private constructor(
    readonly id: OrderId,
    private items: OrderLine[],   // ← internal, not exposed
    private status: OrderStatus,
  ) {}

  addItem(sku: Sku, quantity: number, price: Money): void {
    if (this.status !== 'draft') throw new DomainError('Cannot add items after placing the order')
    if (quantity <= 0) throw new DomainError('Quantity must be positive')
    const existing = this.items.find((line) => line.sku.equals(sku))
    if (existing) {
      existing.increaseQuantity(quantity)
    } else {
      this.items.push(OrderLine.new(sku, quantity, price))
    }
  }

  removeItem(sku: Sku): void { /* ... */ }
  itemsView(): ReadonlyArray<OrderLine> { return this.items }  // read-only view
}
```

### Aggregate rules

1. **One root per aggregate.** Outside code holds a reference only to the root.
2. **The root enforces all invariants** that span the aggregate. ("An order must have at least one line." "The total cannot exceed the customer's credit limit.")
3. **The aggregate is the unit of transactional consistency.** When you save it, you save the whole thing atomically. When you load it, you load enough to make consistent decisions.
4. **Reference other aggregates by ID, not by object reference.** An `Order` holds a `CustomerId`, not a `Customer` object. If you need customer data, fetch it through its own repository.
5. **Keep aggregates small.** A 47-entity aggregate is a god-aggregate. Most aggregates should be 1–5 entities. The cost of a large aggregate is concurrent-update conflicts and slow loads.

### Why "reference by ID"?

- **Loading:** loading an `Order` shouldn't drag in the entire customer history.
- **Concurrency:** two users editing the same `Customer` shouldn't fail because they touched two unrelated `Order`s.
- **Boundaries:** aggregates are independently consistent. Cross-aggregate consistency is *eventual*, achieved via [domain events](#domain-events) or sagas.

### How to find aggregate boundaries

Ask: **what must be consistent in a single transaction?** That's one aggregate. Anything else can be eventually consistent.

- An `Order` and its `OrderLines` must be consistent — you can't have a line whose total doesn't match the items. One aggregate.
- An `Order` and its `Customer` must *not* be in the same aggregate — updating the order shouldn't lock the customer record. Two aggregates, linked by `CustomerId`.

If you're tempted to put two things in the same aggregate, write down the invariant that requires it. If you can't articulate one, they're separate aggregates.

## Repositories

A **repository** is the interface through which the application loads and saves an aggregate. One repository per aggregate root.

```typescript
// core/ports/driven/order-repository.port.ts
import type { Order } from '@/core/domain/order/order'
import type { OrderId } from '@/core/domain/order/order-id'

export interface OrderRepository {
  findById(id: OrderId): Promise<Order | null>
  save(order: Order): Promise<void>
  nextId(): OrderId
}
```

Properties:

- **Returns domain objects, not ORM rows.** The repository is the translation point between the persistence model and the domain model.
- **One repository per aggregate root.** Not per table, not per use case.
- **Interface in the domain layer; implementation in infrastructure.** Standard hexagonal port/adapter split.
- **No business logic.** Repositories load and save. They don't decide things. Decisions live on entities.
- **Query methods are minimal.** Don't expose every possible query as a repository method — that turns the repository into a generic ORM. For complex read patterns, use a separate read model (CQRS-lite).

### What about reads?

If your read patterns are complex (search pages, dashboards, reports), a domain-style repository is the wrong tool. Reads don't have invariants and don't need aggregate loading. Use a separate "query service" or read model that returns DTOs straight from the database, bypassing the domain. This is CQRS in its lightest form: reads are flat, writes go through aggregates.

## Domain Services

A **domain service** is a stateless function that holds business logic that doesn't naturally belong on any single entity or value object.

When to reach for a domain service:

- The operation involves **multiple aggregates**, none of which "owns" the logic.
- The logic is **truly stateless** — give it inputs, get back outputs.
- It would feel **awkward to put on either entity** because it's about the relationship between them.

Example: transferring money between two accounts.

```typescript
// core/domain/banking/transfer-service.ts
export class TransferService {
  static transfer(from: Account, to: Account, amount: Money): TransferResult {
    if (!from.canDebit(amount)) return TransferResult.insufficientFunds()
    if (from.currency !== to.currency) return TransferResult.currencyMismatch()
    from.debit(amount)
    to.credit(amount)
    return TransferResult.success(TransferId.generate())
  }
}
```

`Account.transferTo(other, amount)` would feel forced — neither account "owns" the transfer. A static domain service is the honest expression.

**Warning**: domain services are easy to overuse. Every "I'll just add a service" is a temptation to slip into the [anemic domain model](#anti-patterns) trap. Default to putting logic on entities and value objects; reach for a domain service only when the logic genuinely doesn't belong to one.

## Domain Events

A **domain event** is a record of something that happened in the domain — past tense, immutable, named in the ubiquitous language. `OrderPlaced`, `PaymentReceived`, `SubscriptionRenewed`. They are how aggregates communicate without holding references to each other.

```typescript
// core/domain/order/order-events.ts
export class OrderPlaced {
  readonly occurredAt = new Date()
  constructor(
    readonly orderId: OrderId,
    readonly customerId: CustomerId,
    readonly total: Money,
  ) {}
}

// core/domain/order/order.ts
export class Order {
  private events: DomainEvent[] = []

  static place(input: PlaceOrderInput): Order {
    const order = new Order(/* ... */)
    order.events.push(new OrderPlaced(order.id, order.customerId, order.total()))
    return order
  }

  pullEvents(): DomainEvent[] {
    const out = this.events
    this.events = []
    return out
  }
}
```

The application service collects events from the aggregate after a successful save and publishes them through an `EventPublisher` port:

```typescript
// core/application/orders/place-order.ts
export async function placeOrder(deps: PlaceOrderDeps, input: PlaceOrderInput): Promise<Order> {
  return deps.unitOfWork.run(async () => {
    const order = Order.place(input)
    await deps.orders.save(order)
    await deps.events.publishAll(order.pullEvents())
    return order
  })
}
```

For at-least-once delivery with transactional safety, pair domain events with the [outbox pattern](../../typescript-data-engineering/references/message-brokers.md).

### Why domain events instead of direct calls?

When two aggregates need to coordinate ("when an order is placed, send a welcome email if it's the customer's first order"), the wrong move is for `Order.place()` to call `EmailService.send()`. That couples the order aggregate to email, breaks the dependency rule, and makes the order impossible to test in isolation.

The right move: `Order` emits `OrderPlaced`. A separate handler subscribes to `OrderPlaced`, decides whether the customer is new, and triggers the email. The order knows nothing about email; the email handler knows nothing about the order's internals.

### Domain events vs integration events

- **Domain events** live inside one bounded context. They use the context's vocabulary and may carry rich domain objects. They are an internal mechanism.
- **Integration events** cross context boundaries. They use a published language (often a separate schema), carry only IDs and primitives, and are versioned carefully.

Don't publish domain events to external systems directly — translate them at the boundary.

## Putting It Together — A Worked Example

```typescript
// core/domain/subscription/subscription.ts
export class Subscription {
  private events: DomainEvent[] = []

  private constructor(
    readonly id: SubscriptionId,
    readonly customerId: CustomerId,
    private plan: Plan,                      // value object
    private status: SubscriptionStatus,
    private currentPeriod: BillingPeriod,    // value object
  ) {}

  static start(input: StartSubscriptionInput): Subscription {
    const sub = new Subscription(
      SubscriptionId.generate(),
      input.customerId,
      input.plan,
      'active',
      BillingPeriod.startingNow(input.plan.billingCycle),
    )
    sub.events.push(new SubscriptionStarted(sub.id, sub.customerId, sub.plan.id))
    return sub
  }

  renew(now: Date): void {
    if (this.status !== 'active') throw new DomainError(`Cannot renew a ${this.status} subscription`)
    if (!this.currentPeriod.hasEnded(now)) throw new DomainError('Period has not ended yet')
    this.currentPeriod = this.currentPeriod.next()
    this.events.push(new SubscriptionRenewed(this.id, this.currentPeriod))
  }

  cancel(reason: CancellationReason): void {
    if (this.status === 'cancelled') return
    this.status = 'cancelled'
    this.events.push(new SubscriptionCancelled(this.id, reason))
  }

  pullEvents(): DomainEvent[] { /* ... */ }
}
```

What this code is doing right:

- **Value objects** for `Plan`, `BillingPeriod`, `CancellationReason`. None of these are passed around as primitives.
- **Private constructor + named factory** (`start`) — the only way to make a subscription is the one the domain blesses.
- **Invariants enforced in methods** — you cannot renew a cancelled subscription, or renew before the period ends.
- **Events emitted from the methods** that change state. The application service pulls them after save.
- **No imports from infrastructure.** This file would compile without a database, an HTTP framework, or a queue.

## Anti-Patterns

### Anemic Domain Model

The single most common DDD failure: classes that are bags of getters and setters, with all logic in services.

```typescript
// anemic
class Order {
  id: string
  status: string
  items: OrderLine[]
  // ... all public, all settable
}

class OrderService {
  cancel(order: Order, reason: string) {
    if (order.status === 'shipped') throw new Error('Cannot cancel')
    order.status = 'cancelled'
  }
}
```

The rule "cannot cancel a shipped order" is in the service. Any other code that mutates `order.status` directly bypasses the rule. The model has no protection.

**Fix**: move the rule onto the entity. Make fields private. Mutate through methods.

### Aggregate as Database Table

Modeling an aggregate as a 1:1 mirror of a database table. The aggregate ends up holding every column the database holds — including ones that shouldn't be loaded for the use case at hand.

**Fix**: model the aggregate around invariants and behavior, not around tables. The repository translates between the two.

### God Aggregate

One aggregate that owns everything. Loading it locks half the database.

**Fix**: split by transactional consistency boundary. Reference other aggregates by ID.

### Repository as Generic Query Builder

`UserRepository` with thirty methods: `findByEmail`, `findByEmailAndStatus`, `findByCohortAndCreatedAfter`, `findByEmailAndCohortAndStatus`...

**Fix**: a repository handles aggregate persistence, not arbitrary queries. Use a separate read model or query service for ad-hoc queries.

### Domain Service for Everything

When every operation is a domain service, the entities have nothing to do, and you've just rebuilt the anemic model with extra files.

**Fix**: ask "could this method live on an entity or value object?" before reaching for a service. The answer is usually yes.

### Domain Events as Carriers of Business Logic

Event handlers that contain business decisions ("if the order total is over $1000, escalate to manager"). The decision belongs in the domain, not the handler.

**Fix**: emit a richer event (`LargeOrderPlaced`), or move the decision into the aggregate.

## Related

- [domain-modeling.md](domain-modeling.md) — strategic context: where bounded contexts go
- [separation-of-concerns.md](separation-of-concerns.md) — where the domain layer lives
- [hexagonal-architecture.md](hexagonal-architecture.md) — how repositories and ports fit
- [solid.md](solid.md) — why entities own their behavior (SRP, OCP)
- [cohesion-and-coupling.md](cohesion-and-coupling.md) — primitive obsession, data clumps
