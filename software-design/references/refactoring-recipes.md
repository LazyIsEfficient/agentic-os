# Refactoring Recipes

A refactoring is a behavior-preserving change in the structure of code. The two halves of that definition matter equally:

- **Behavior-preserving** — the tests that passed before still pass after, without modification. If a test had to change, it wasn't a refactoring; it was a behavior change wearing refactoring's clothes.
- **Change in structure** — the code is shaped differently for the better. If nothing meaningful improved, it wasn't worth the diff.

This file is a catalogue of moves from smell to fix. Each one names the smell, the mechanical steps, and what to watch out for.

## The Cardinal Rule

> **Refactor on green. Behavior change and structure change never share a commit.**

The discipline is: get tests passing, refactor, run tests again, commit, then change behavior in a separate commit. Trying to refactor *and* fix a bug *and* add a feature in one go produces a diff nobody can review and a bisect that points nowhere.

If you need to refactor before you can fix the bug (because the current shape makes the fix impossible), do the refactor first, in its own commit, with the existing tests still green. Then fix the bug in a second commit.

## Smell → Fix Catalogue

### Long Method

**Smell**: a function longer than the screen, with multiple sections separated by blank lines or comments like `// validate input`, `// load related data`, `// compute total`, `// persist`, `// notify`.

**Fix — Extract Method**:

```typescript
// before
async function placeOrder(input: Input): Promise<Order> {
  // validate
  if (input.items.length === 0) throw new Error('No items')
  for (const item of input.items) {
    if (item.quantity <= 0) throw new Error('Bad quantity')
  }

  // load
  const customer = await prisma.customer.findUniqueOrThrow({ where: { id: input.customerId } })
  const products = await prisma.product.findMany({ where: { sku: { in: input.items.map(i => i.sku) } } })

  // compute
  let total = 0
  for (const item of input.items) {
    const product = products.find(p => p.sku === item.sku)!
    total += product.price * item.quantity
  }

  // persist
  const order = await prisma.order.create({ data: { customerId: customer.id, total, items: input.items } })

  // notify
  await sendgrid.send({ to: customer.email, template: 'order-placed', vars: { orderId: order.id } })

  return order
}
```

```typescript
// after
async function placeOrder(input: Input): Promise<Order> {
  validateOrderInput(input)
  const { customer, products } = await loadOrderContext(input)
  const total = calculateTotal(input.items, products)
  const order = await persistOrder(customer, input.items, total)
  await notifyOrderPlaced(customer, order)
  return order
}
```

The named functions become testable in isolation, and the top-level function reads as a sentence describing the use case.

**Watch out for**: parameters multiplying. If `validateOrderInput` needs five parameters, you might be missing a `Cart` value object that should hold them.

### Primitive Obsession

**Smell**: domain concepts represented as raw `string` / `number`. Repeated validation. Comments like `// in cents`. Wrong values silently passed where the type compiles.

**Fix — Replace Primitive with Value Object**:

```typescript
// before
function transfer(fromAccount: string, toAccount: string, amountCents: number, currency: string) {
  if (!fromAccount.match(/^acct_/)) throw new Error('Bad account')
  if (amountCents < 0) throw new Error('Negative amount')
  if (!['USD', 'EUR', 'GBP'].includes(currency)) throw new Error('Bad currency')
  // ... business logic
}
```

```typescript
// after
class AccountId {
  private constructor(readonly value: string) {}
  static from(raw: string): AccountId {
    if (!raw.match(/^acct_/)) throw new DomainError('Invalid account ID')
    return new AccountId(raw)
  }
}

class Money {
  constructor(readonly cents: number, readonly currency: Currency) {
    if (cents < 0) throw new DomainError('Negative amount')
  }
  static usd(cents: number) { return new Money(cents, 'USD') }
}

function transfer(from: AccountId, to: AccountId, amount: Money) {
  // ... business logic; validation already done at construction
}
```

The validation happens once at the boundary; everywhere else assumes valid values.

**Watch out for**: serialization. Value objects need a clear way to cross network/database boundaries. Add `toJSON()` / `fromJSON()` if needed.

### Feature Envy

**Smell**: a method that uses another object's data more than its own.

**Fix — Move Method**:

```typescript
// before
class Order {
  total(): number {
    return this.customer.address.country === 'US'
      ? this.subtotal() * 1.0825
      : this.subtotal() * 1.20
  }
}
```

```typescript
// after
class Address {
  taxRate(): number {
    return this.country === 'US' ? 0.0825 : 0.20
  }
}

class Order {
  total(): number {
    return this.subtotal() * (1 + this.customer.address.taxRate())
  }
}
```

Tax knowledge belongs to `Address`, not `Order`. Now an arbitrary tax change is one file.

### Data Clump

**Smell**: the same group of fields appears together in many places.

**Fix — Introduce Parameter Object** (a value object):

```typescript
// before
function searchFlights(originCity: string, originAirport: string, destCity: string, destAirport: string, departDate: Date, returnDate: Date | null) { /* ... */ }
```

```typescript
// after
class Airport { constructor(readonly city: string, readonly code: string) {} }
class DateRange { constructor(readonly start: Date, readonly end: Date | null) {} }

function searchFlights(origin: Airport, destination: Airport, dates: DateRange) { /* ... */ }
```

The function signature now reads like the domain.

### Switch Statement on Type

**Smell**: a switch (or chain of `if`s) that branches on a string or enum to do different things.

**Fix — Replace Conditional with Polymorphism** (or with a strategy map; see [solid.md](solid.md)):

```typescript
// before
function calculateFee(payment: Payment): number {
  switch (payment.type) {
    case 'card': return payment.amount * 0.029 + 30
    case 'bank': return Math.min(payment.amount * 0.008, 500)
    case 'crypto': return payment.amount * 0.005
    default: throw new Error('Unknown type')
  }
}
```

```typescript
// after
interface PaymentMethod {
  calculateFee(amount: number): number
}

class CardPayment implements PaymentMethod {
  calculateFee(amount: number) { return amount * 0.029 + 30 }
}
class BankPayment implements PaymentMethod {
  calculateFee(amount: number) { return Math.min(amount * 0.008, 500) }
}
class CryptoPayment implements PaymentMethod {
  calculateFee(amount: number) { return amount * 0.005 }
}
```

Or, if a class hierarchy is heavyweight, a strategy map:

```typescript
const feeStrategies: Record<PaymentType, (amount: number) => number> = {
  card: (a) => a * 0.029 + 30,
  bank: (a) => Math.min(a * 0.008, 500),
  crypto: (a) => a * 0.005,
}

function calculateFee(type: PaymentType, amount: number): number {
  const strategy = feeStrategies[type]
  if (!strategy) throw new Error(`Unknown type: ${type}`)
  return strategy(amount)
}
```

**Watch out for**: don't extract until you have the third case. Two branches is "duplication"; three is "interesting."

### Anemic Domain Model

**Smell**: an entity that's just public fields and getters/setters; all rules live in services.

**Fix — Move Method onto Entity**:

```typescript
// before
class Order { status: string; items: OrderLine[] /* all public */ }

class OrderService {
  cancel(order: Order, reason: string) {
    if (order.status === 'shipped') throw new Error('Cannot cancel')
    order.status = 'cancelled'
  }
}
```

```typescript
// after
class Order {
  private constructor(/* ... */) {}
  cancel(reason: CancellationReason): void {
    if (this.status === 'shipped') throw new DomainError('Cannot cancel a shipped order')
    if (this.status === 'cancelled') return
    this.status = 'cancelled'
  }
}

class OrderService {
  async cancelOrder(orderId: OrderId, reason: CancellationReason) {
    const order = await this.orders.findById(orderId)
    if (!order) throw new NotFoundError()
    order.cancel(reason)
    await this.orders.save(order)
  }
}
```

The rule cannot be bypassed because the field is private and the only mutation path enforces it.

### God Class

**Smell**: a class with twenty methods covering unrelated concerns. Multiple imports from unrelated libraries. Multiple test files trying to test it.

**Fix — Extract Class** (repeatedly, by responsibility):

1. Identify cohesive groups of methods that operate on the same fields.
2. Pull each group into its own class.
3. The original class either becomes a thin coordinator or disappears entirely.

Don't try to do it in one PR if the class is large. Extract one cohesive group at a time, ship, repeat.

### Shotgun Surgery

**Smell**: a single conceptual change forces edits in many files.

**Fix — Find the Missing Concept**: the concept isn't *contained* anywhere. Locate a place where it could live, and migrate the scattered logic there one caller at a time.

**Watch out for**: this is the hardest refactoring on the list because the missing concept often isn't obvious. Use the act of writing the test for the new feature as a forcing function — wherever the test would naturally exercise the new concept, that's where the concept wants to live.

### Direct Infrastructure Call in Domain

**Smell**: `import { prisma } from '@/lib/prisma'` (or any other infra import) inside a domain or application file.

**Fix — Extract Interface (Port)**:

1. Define an interface in the domain layer that captures what the domain needs.
2. Move the Prisma call into a new adapter class that implements that interface.
3. Inject the adapter from the composition root.
4. Update the domain code to depend on the interface, not Prisma.

```typescript
// before — domain file imports Prisma
import { prisma } from '@/lib/prisma'

export async function placeOrder(input: Input) {
  const order = await prisma.order.create({ data: { /* ... */ } })
  return order
}
```

```typescript
// after — domain depends on a port; adapter wraps Prisma
// core/ports/driven/order-repository.port.ts
export interface OrderRepository {
  save(order: Order): Promise<void>
  nextId(): OrderId
}

// core/application/orders/place-order.ts
export async function placeOrder(deps: { orders: OrderRepository }, input: Input): Promise<Order> {
  const order = Order.place(input)
  await deps.orders.save(order)
  return order
}

// adapters/driven/prisma-order-repository.ts
export class PrismaOrderRepository implements OrderRepository {
  constructor(private prisma: PrismaClient) {}
  async save(order: Order) { await this.prisma.order.create({ data: this.toRow(order) }) }
  nextId(): OrderId { return OrderId.generate() }
}
```

**Watch out for**: do the whole journey in one commit per file (interface + use case + adapter + composition root wiring). A half-refactored use case is a mess for the next reader.

### Long Parameter List

**Smell**: a function with seven parameters.

**Fix**: usually one of:

- **Introduce Parameter Object** (when several parameters represent one concept).
- **Preserve Whole Object** (when several parameters all come from one larger object the caller already has).
- **Replace Parameter with Method Call** (when one parameter can be computed from another).

If none of those apply, the function is doing too much. Extract a class.

### Comments Explaining What

**Smell**: a comment like `// loop over the items and total them up`.

**Fix — Extract Method, Use Method Name as the Comment**:

```typescript
// before
// loop over items and apply discounts
let total = 0
for (const item of items) {
  const lineTotal = item.price * item.quantity
  const discount = item.discountCode ? lineTotal * 0.1 : 0
  total += lineTotal - discount
}
```

```typescript
// after
const total = items.reduce((sum, item) => sum + applyDiscount(item), 0)

function applyDiscount(item: OrderItem): number {
  const lineTotal = item.price * item.quantity
  return item.discountCode ? lineTotal * 0.9 : lineTotal
}
```

Good comments explain *why*, not *what*. The code itself shows what.

### Mutable Setters Everywhere

**Smell**: an entity with public setters that any caller can use to mutate state directly.

**Fix — Replace Setters with Intent-Revealing Methods**:

```typescript
// before
order.setStatus('shipped')
order.setShippedAt(new Date())
order.setTrackingNumber('1Z999AA10123456784')
```

```typescript
// after
order.markShipped({ trackingNumber: '1Z999AA10123456784' })
// internally sets status, timestamp, tracking number, and emits OrderShipped event
```

A method named for the *business action* enforces invariants and emits events. Three setters can't.

### Boolean Parameter

**Smell**: `createUser(email, password, true)` — the `true` is some flag, but at the call site you can't tell what it means.

**Fix**: split into two methods, or use an explicit named option:

```typescript
// option A — split methods
createUser(email, password)
createAdminUser(email, password)

// option B — named option
createUser({ email, password, role: 'admin' })
```

### Test That Mocks Everything

**Smell**: a unit test with eight `jest.mock(...)` calls.

**Fix**: this is a *design* smell, not a test smell. The unit under test depends on too many things. Either:

- Extract the pure logic out of the I/O wrapper. Test the pure logic with no mocks.
- Replace the mocks with hand-written fakes that implement a port. The fake is reusable across many tests and doesn't break when the implementation changes.

If the test still needs lots of setup, the unit is doing too much.

## How to Do a Refactoring Safely

For any non-trivial refactoring:

1. **Run the tests.** Make sure they pass *before* you touch anything.
2. **Make the smallest possible change in one direction.** Add the new structure alongside the old one if you can; don't delete the old yet.
3. **Run the tests.**
4. **Migrate callers one at a time.** Each call site updated, tests run.
5. **When all callers are on the new structure, delete the old one.**
6. **Run the tests.**
7. **Commit.** With a message that says "refactor: <what>". No behavior change.

This sequence is slower than a big rewrite, but it's reversible at every step. If something breaks, you know exactly where.

## When NOT to Refactor

- **In code you're about to delete.** Why polish a corpse?
- **In code with no tests, in territory you don't understand.** Add tests first. Then refactor.
- **Right before a deadline.** Refactoring near a deadline is how outages happen.
- **For taste alone.** "I would have written it differently" is not a reason to change someone else's code. There must be a concrete improvement: easier change, fewer bugs, clearer name, deleted code.
- **As part of a feature commit.** Always separate.

## Related

- [solid.md](solid.md) — the principles each refactoring is moving toward
- [cohesion-and-coupling.md](cohesion-and-coupling.md) — the smells, in vocabulary form
- [code-review-heuristics.md](code-review-heuristics.md) — when to suggest a refactoring in a review
- [tactical-ddd.md](tactical-ddd.md) — what shapes to refactor *toward* when modeling a domain
- [hexagonal-architecture.md](hexagonal-architecture.md) — the destination of the "extract interface" refactoring
