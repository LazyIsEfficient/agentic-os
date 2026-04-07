# SOLID — In Practice

SOLID is a set of heuristics, not laws. Each principle is best understood as a smell-detector: when you violate it, *something specific* gets harder. Read each principle in terms of "what becomes painful when I ignore this," not as a rule to apply mechanically.

## S — Single Responsibility Principle

**"A module should have one reason to change."** Reason here means *stakeholder concern*, not "does one thing".

A `UserService` that handles authentication, profile updates, and email notifications has three reasons to change: the auth team, the profile team, and the comms team. Three different stakeholders, three different change cadences, three different review groups. Split it.

### Smell

```typescript
class UserService {
  async signup(email: string, password: string) {
    const hashed = await bcrypt.hash(password, 12)
    const user = await prisma.user.create({ data: { email, passwordHash: hashed } })
    await sendgrid.send({ to: email, template: 'welcome', vars: { name: email } })
    analytics.track('user_signed_up', { userId: user.id })
    return user
  }
}
```

This class touches password hashing, persistence, transactional email, and product analytics. Four reasons to change.

### Fix

```typescript
class SignupService {
  constructor(
    private users: UserRepository,
    private hasher: PasswordHasher,
    private notifier: SignupNotifier,
    private analytics: AnalyticsTracker,
  ) {}

  async signup(email: string, password: string): Promise<User> {
    const user = await this.users.create({ email, passwordHash: await this.hasher.hash(password) })
    await this.notifier.welcome(user)
    this.analytics.userSignedUp(user)
    return user
  }
}
```

Each collaborator can change independently. The signup service orchestrates; it doesn't *know* how email is sent or how analytics are routed.

### How to spot it

- The class name has "and" in its honest description ("handles signup *and* notifications *and* analytics").
- Two unrelated tickets routinely touch the same file.
- Two test files want to test the same class for different reasons.
- The file has imports from three different infrastructure libraries (DB, email, analytics, payments).

## O — Open/Closed Principle

**"Open for extension, closed for modification."** Adding a new variant should not require editing existing code paths.

This principle is about *extension points*. The point is not "never change existing code"; it's "make the common axis of change a new file, not a new branch in an existing switch statement."

### Smell

```typescript
function calculateShipping(order: Order): number {
  if (order.region === 'US') return order.weight * 0.5
  if (order.region === 'EU') return order.weight * 0.7 + 5
  if (order.region === 'APAC') return order.weight * 1.2 + 10
  throw new Error('Unknown region')
}
```

Every new region modifies this function. Reviewers and tests for *every* region pile up around it.

### Fix

```typescript
interface ShippingCalculator {
  region: Region
  calculate(order: Order): number
}

const calculators: Record<Region, ShippingCalculator> = {
  US: { region: 'US', calculate: (o) => o.weight * 0.5 },
  EU: { region: 'EU', calculate: (o) => o.weight * 0.7 + 5 },
  APAC: { region: 'APAC', calculate: (o) => o.weight * 1.2 + 10 },
}

function calculateShipping(order: Order): number {
  const calc = calculators[order.region]
  if (!calc) throw new Error(`Unknown region: ${order.region}`)
  return calc.calculate(order)
}
```

Adding a new region adds a new entry, not a new branch. The dispatch lives in one place.

### When NOT to apply

OCP costs structure. **Don't pre-extract for variants you don't have.** Two cases is "duplication," three is "interesting." Wait until the third case to extract — that's when the extension axis is real.

## L — Liskov Substitution Principle

**"Subtypes must be substitutable for their base types."** A function that accepts `Bird` must work for any `Bird` subclass without surprises.

LSP is most often violated by inheritance hierarchies that model "is a" loosely. The classic example: `Square extends Rectangle`. Mathematically a square *is* a rectangle, but a `setWidth(5)` on a square that also forces `height = 5` breaks any code that expected `setWidth` and `setHeight` to be independent.

### Smell

```typescript
class Bird {
  fly() { /* ... */ }
}

class Penguin extends Bird {
  fly() { throw new Error("Penguins don't fly") }
}

function migrate(birds: Bird[]) {
  birds.forEach((b) => b.fly()) // throws on penguin
}
```

### Fix

Model "can fly" as a capability, not as inherited behavior:

```typescript
interface Bird { species: string }
interface Flier extends Bird { fly(): void }

function migrate(birds: Flier[]) {
  birds.forEach((b) => b.fly())
}
```

### How to spot it

- Subclasses that throw `NotSupportedError` from inherited methods.
- `instanceof` checks at call sites to distinguish subclasses.
- Tests that use a base class but pass mock objects that return absurd values to bypass behavior.

## I — Interface Segregation Principle

**"No client should be forced to depend on methods it does not use."** A small, focused interface is better than a large catch-all.

### Smell

```typescript
interface UserStore {
  findById(id: string): Promise<User>
  create(input: CreateUser): Promise<User>
  update(id: string, input: UpdateUser): Promise<User>
  delete(id: string): Promise<void>
  search(query: string): Promise<User[]>
  countByCohort(cohort: string): Promise<number>
  exportToCsv(): Promise<string>
}

class WelcomeEmailJob {
  constructor(private users: UserStore) {} // only needs findById!
}
```

`WelcomeEmailJob`'s tests now have to mock seven methods to use one.

### Fix

```typescript
interface UserReader {
  findById(id: string): Promise<User>
}

class WelcomeEmailJob {
  constructor(private users: UserReader) {}
}
```

A class implementing the full `UserStore` still satisfies `UserReader` — interfaces compose.

### How to spot it

- Test files mock five methods to test code that uses one.
- A single interface has methods that no real consumer uses together.
- "Optional" methods or methods that throw "not applicable" for some implementations.

## D — Dependency Inversion Principle

**"High-level modules should not depend on low-level modules. Both should depend on abstractions."** And: "Abstractions should not depend on details. Details should depend on abstractions."

This is the principle that makes [hexagonal architecture](hexagonal-architecture.md) possible. It is the **most load-bearing** of the five for keeping a codebase changeable.

### Smell

```typescript
// signup.service.ts
import { prisma } from '@/lib/prisma'
import { sendgrid } from '@/lib/sendgrid'

export async function signup(email: string, password: string) {
  const user = await prisma.user.create({ data: { email, /* ... */ } })
  await sendgrid.send({ to: email, /* ... */ })
}
```

`signup` depends directly on Prisma and SendGrid. To test it, you have to mock both modules. To swap email providers, you edit business logic. The high-level "signup business rule" depends on low-level details.

### Fix

```typescript
// domain/signup.ts — pure, no infra imports
export interface UserRepository {
  create(input: CreateUserInput): Promise<User>
}
export interface EmailSender {
  sendWelcome(to: string): Promise<void>
}

export async function signup(
  deps: { users: UserRepository; email: EmailSender },
  input: { email: string; password: string },
): Promise<User> {
  const user = await deps.users.create({ /* ... */ })
  await deps.email.sendWelcome(user.email)
  return user
}

// adapters/prisma-user-repository.ts
export class PrismaUserRepository implements UserRepository { /* ... */ }

// adapters/sendgrid-email-sender.ts
export class SendgridEmailSender implements EmailSender { /* ... */ }

// composition-root.ts
const result = await signup(
  { users: new PrismaUserRepository(prisma), email: new SendgridEmailSender(sg) },
  { email, password },
)
```

The domain function knows nothing about Prisma or SendGrid. The dependency arrow now points *inward* — adapters depend on the domain interface, not the other way around.

### How to spot it

- Domain logic files import from `@/lib/<infrastructure>`.
- Unit tests have to `jest.mock('@/lib/prisma')` to test business rules.
- Swapping a vendor (email, payments, storage) requires editing files that have nothing to do with that vendor.

## SOLID Without Becoming a Caricature

SOLID applied dogmatically produces overengineered code: an interface for every class, a factory for every interface, dependency injection for every collaborator. That's worse than the smell.

Heuristics for restraint:

- **Wait for the second use case** before extracting an abstraction. The first one always looks general; the second tells you what's actually general.
- **Don't extract interfaces with one implementation** unless you need it for testing or polymorphism. TypeScript's structural typing means you can extract later without breaking callers.
- **Composition root, not framework.** Wire dependencies in *one* file at the entry point, not via a runtime DI container, unless your codebase is large enough to justify it.
- **Aim for "easy to delete," not "easy to extend."** Code that's easy to delete is also easy to change.

## Related

- [cohesion-and-coupling.md](cohesion-and-coupling.md) — the underlying forces SOLID is trying to manage
- [hexagonal-architecture.md](hexagonal-architecture.md) — DIP applied to the whole service
- [refactoring-recipes.md](refactoring-recipes.md) — mechanical moves to fix each smell
