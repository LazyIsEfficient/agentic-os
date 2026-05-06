# Cohesion and Coupling

These are the two forces underlying SOLID and most other design principles. Get them right and SOLID falls out for free; get them wrong and no amount of interface extraction will save you.

- **Cohesion** = how strongly the things inside a module belong together.
- **Coupling** = how dependent one module is on the internals of another.

The goal: **high cohesion within modules, low coupling between them.** Modules should be tight on the inside and loose on the outside.

## Cohesion Spectrum

From worst to best (Yourdon & Constantine):

| Level | What's grouped | Example | Verdict |
|---|---|---|---|
| **Coincidental** | Nothing in common | `utils.ts` with 47 unrelated helpers | Worst |
| **Logical** | Same category, different purpose | "All validation functions" regardless of what they validate | Bad |
| **Temporal** | Run at the same time | `bootstrap()` doing config + DB connect + cache warm + metric init | Tolerable for setup only |
| **Procedural** | Steps in a procedure | A controller method that does steps 1–5 in order | OK if steps belong to one transaction |
| **Communicational** | Operate on the same data | Functions that all read/write `Order` | Good |
| **Sequential** | Output of one is input of next | Pipeline stages | Good |
| **Functional** | Contribute to a single, well-defined task | A class that does one thing well | Best |

If you can't describe a module in a single sentence without "and," it's probably below "communicational."

### Smell: low cohesion

```typescript
// utils/helpers.ts
export function formatDate(d: Date): string { /* ... */ }
export function hashPassword(p: string): Promise<string> { /* ... */ }
export function calculateTax(amount: number, region: string): number { /* ... */ }
export function slugify(s: string): string { /* ... */ }
```

Four unrelated concerns in one file. Anyone editing this file is probably touching code they don't understand to find the function they came for.

### Fix

```
domain/pricing/tax.ts          → calculateTax
domain/url/slug.ts             → slugify
auth/password-hasher.ts        → hashPassword
shared/format/date.ts          → formatDate
```

Each file is functionally cohesive: one concept, one reason to change.

## Connascence — The Sharper Lens on Coupling

Connascence is the more precise replacement for the vague word "coupling." Two pieces of code are connascent when a change to one *requires* a change to the other to keep the program correct.

Ranked from least to most harmful:

| Type | Definition | Example |
|---|---|---|
| **Connascence of Name** | Both refer to the same name | Two files both call `getUser` |
| **Connascence of Type** | Both must agree on a type | Function param and caller both use `User` |
| **Connascence of Meaning** | Both must agree on the meaning of magic values | `0` means "guest", `1` means "user" — everywhere |
| **Connascence of Position** | Both must agree on argument order | `createUser(name, email, age)` |
| **Connascence of Algorithm** | Both must implement the same algorithm | Two services compute the same hash |
| **Connascence of Execution** | Order of execution matters | Must call `init()` before `start()` |
| **Connascence of Timing** | Time-sensitive interactions | Race conditions |
| **Connascence of Identity** | Both must reference the same instance | Singleton state |

**Two rules**:

1. **The more connascent two pieces of code are, the closer they should live.** Connascence of Position between two files in different services is a disaster; the same connascence within one function is fine.
2. **Move toward weaker forms of connascence.** Replace magic numbers (Meaning) with named constants (Name). Replace positional args (Position) with an options object (Name). Replace duplicated algorithms (Algorithm) with a shared function (Name).

### Example: weakening connascence

**Connascence of Position** (fragile):

```typescript
function createUser(name: string, email: string, age: number, isAdmin: boolean) { /* ... */ }
createUser('Glenn', 'g@example.com', 35, false)
```

Reorder the parameters and every call site silently breaks (or worse, type-checks).

**Connascence of Name** (less fragile):

```typescript
function createUser(input: { name: string; email: string; age: number; isAdmin: boolean }) { /* ... */ }
createUser({ name: 'Glenn', email: 'g@example.com', age: 35, isAdmin: false })
```

Rename a field and TypeScript catches every call site. Order no longer matters.

## Coupling Smells

### Feature Envy

A method that uses another object's data more than its own:

```typescript
class Order {
  getCustomerCity(): string {
    return this.customer.address.city
  }
  getCustomerCountry(): string {
    return this.customer.address.country
  }
  getCustomerPostalCode(): string {
    return this.customer.address.postalCode
  }
}
```

These methods envy `Customer`. Move them:

```typescript
class Customer {
  city(): string { return this.address.city }
  country(): string { return this.address.country }
  postalCode(): string { return this.address.postalCode }
}
```

### Inappropriate Intimacy

Two classes know too much about each other's internals:

```typescript
class Cart {
  applyDiscount(discount: Discount) {
    this.total = this.total - this.total * discount.percent / 100
    discount.usedCount++
    discount.lastUsedAt = new Date()
  }
}
```

`Cart` is mutating `Discount`'s fields directly. Tell `Discount` to record its own usage:

```typescript
class Discount {
  recordUsage(): void {
    this.usedCount++
    this.lastUsedAt = new Date()
  }
}

class Cart {
  applyDiscount(discount: Discount) {
    this.total = discount.applyTo(this.total)
    discount.recordUsage()
  }
}
```

### Shotgun Surgery

A single conceptual change forces edits in many files. The opposite of cohesion: the concept is *spread*, not *contained*.

If adding a new payment method requires editing `OrderService`, `Invoice`, `Receipt`, `EmailTemplate`, `AdminDashboard`, and three database migrations, the payment-method concept is not contained in any one place. Find or create a `PaymentMethod` module that owns the variation.

### Data Clumps

The same group of fields appears together in many signatures:

```typescript
function shipOrder(orderId: string, street: string, city: string, postalCode: string, country: string) { /* ... */ }
function validateAddress(street: string, city: string, postalCode: string, country: string) { /* ... */ }
function formatAddress(street: string, city: string, postalCode: string, country: string) { /* ... */ }
```

That clump is a missing concept. Extract it:

```typescript
class Address {
  constructor(readonly street: string, readonly city: string, readonly postalCode: string, readonly country: string) {}
  format(): string { /* ... */ }
}

function shipOrder(orderId: string, address: Address) { /* ... */ }
function validateAddress(address: Address): Result { /* ... */ }
```

### Primitive Obsession

Domain concepts modeled as raw primitives — strings everywhere for IDs, emails, money:

```typescript
function transfer(from: string, to: string, amount: number) { /* ... */ }
transfer('user-42', 'user-99', 1000) // is that 1000 cents? dollars? euros?
```

Wrap them:

```typescript
class UserId { constructor(readonly value: string) {} }
class Money { constructor(readonly amount: number, readonly currency: Currency) {} }

function transfer(from: UserId, to: UserId, amount: Money) { /* ... */ }
transfer(new UserId('user-42'), new UserId('user-99'), Money.usd(1000))
```

Now the type system enforces what comments used to.

## How to Measure (Informally)

You don't need a tool. Ask:

- **If I rename a field in this module, how many other files do I have to touch?** (Coupling)
- **If I split this file in half, how many imports cross the new boundary?** (Cohesion)
- **If a stakeholder asks for one change, how many files do I edit?** (Shotgun surgery)
- **What % of methods in this class touch the same fields?** (LCOM intuition — high overlap = cohesive)

A 10-line file with one purpose beats a 200-line file with five.

## The Cohesion/Coupling Trade-off

You cannot push cohesion infinitely high without splitting modules so finely that coupling between the resulting fragments becomes the new problem. Hundreds of one-function files with deep import graphs is a different disease, not a cure.

The sweet spot:

- **One module = one concept = one reason to change.**
- **Module interface narrower than implementation** (Ousterhout's "deep modules").
- **Concepts that change together live together** (Common Closure Principle).

When you're tempted to split, ask: do these halves change for *different* reasons? If yes, split. If not, keep them together.

## Related

- [solid.md](solid.md) — SOLID is cohesion/coupling distilled into rules of thumb
- [refactoring-recipes.md](refactoring-recipes.md) — mechanical fixes for each smell above
- [code-review-heuristics.md](code-review-heuristics.md) — what to flag in a diff
