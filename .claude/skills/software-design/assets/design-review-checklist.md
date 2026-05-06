# Design Review Checklist

Use this checklist when reviewing a significant PR (a new module, a non-trivial refactor, or a feature that adds a new concept) or when designing a new module before writing it. Copy this file into the PR description, the design doc, or a scratchpad and check items off explicitly.

This is a *design* review, not a typo hunt. The goal is to catch problems that will be expensive to fix later if they ship now.

---

## Context

- **PR / module:** _____
- **Reviewer:** _____
- **Date:** _____
- **One-sentence summary of what this change does:** _____

---

## 1. Scope

- [ ] The change does **one thing**. Refactors and feature changes are not mixed.
- [ ] If the change touches many files, the breadth is justified by a single concept (not [shotgun surgery](../references/cohesion-and-coupling.md#shotgun-surgery)).
- [ ] Anything unrelated has been split into a separate PR.
- [ ] The PR description names the *why*, not just the *what*.

**Notes:** _____

---

## 2. Layering and Dependencies

- [ ] No domain file imports from `infrastructure/`, `transport/`, or any third-party SDK.
- [ ] No application file talks to a database, message broker, or HTTP framework directly — only through ports.
- [ ] HTTP concerns (status codes, headers, request parsing) live in the controller, not in services or domain.
- [ ] Authentication and authorization happen at the boundary, not scattered through business logic.
- [ ] If the change introduces a new dependency, it's an *interface* in the domain layer with a concrete adapter in infrastructure.

**Notes:** _____

---

## 3. Where the Logic Lives

- [ ] Business rules and invariants live on entities or value objects, not in services.
- [ ] No `if (status === ...) throw` checks in service code that should be on the entity.
- [ ] No public setters on entities. All mutation goes through intent-revealing methods.
- [ ] Coordination across multiple aggregates happens in an application service or via domain events, not by reaching into another aggregate.
- [ ] Validation lives at the right boundary: shape validation at the controller, invariants on the entity.

**Notes:** _____

---

## 4. Domain Modeling

- [ ] Names in the code match the names domain experts use (ubiquitous language).
- [ ] No primitive obsession: money, IDs, emails, time ranges are value objects, not raw `string` / `number`.
- [ ] Aggregate boundaries match transactional consistency boundaries — what must be consistent in one save is one aggregate.
- [ ] Aggregates reference other aggregates by ID, not by object reference.
- [ ] Aggregates are small (most have 1–5 entities). No god aggregate that owns everything.
- [ ] If a domain concept is new, it has an obvious owner (entity, aggregate, value object, or domain service).

**Notes:** _____

---

## 5. Cohesion and Coupling

- [ ] Each module has **one reason to change**. If you can name two unrelated reasons, it should be split.
- [ ] No [feature envy](../references/cohesion-and-coupling.md#feature-envy): methods don't reach into other objects more than their own.
- [ ] No [data clumps](../references/cohesion-and-coupling.md#data-clumps): groups of fields that travel together have been promoted to a value object.
- [ ] No [inappropriate intimacy](../references/cohesion-and-coupling.md#inappropriate-intimacy): one class isn't mutating another's internals.
- [ ] Connascence is local: tightly-coupled code lives close together; weakly-coupled code can live far apart.

**Notes:** _____

---

## 6. SOLID Smells (selective — not a religion)

- [ ] **SRP**: no class with three unrelated responsibilities.
- [ ] **OCP**: a switch statement that branches on type and is *likely to grow* has been replaced with polymorphism or a strategy map. (One-off switches are fine.)
- [ ] **LSP**: subclasses don't throw `NotSupportedError` from inherited methods.
- [ ] **ISP**: no port has methods that no real consumer uses together.
- [ ] **DIP**: high-level modules depend on interfaces, not on concrete vendor SDKs.

**Notes:** _____

---

## 7. Testability

- [ ] The unit under test can be tested without mocking more than two collaborators.
- [ ] No `jest.mock(...)` of the database / broker / external API to test pure business logic — that logic should be pure.
- [ ] If the test needs to mock time, randomness, or UUIDs, those are injected as ports (`Clock`, `IdGenerator`), not called directly.
- [ ] Tests assert observable behavior, not internal method calls.
- [ ] Hard-to-test code triggered a refactor, not another mock.

**Notes:** _____

---

## 8. Failure Handling and Concurrency

- [ ] What happens if this code runs twice for the same input? (Idempotency.) — answer: _____
- [ ] What happens if step N succeeds and step N+1 fails? (Transactional boundary.) — answer: _____
- [ ] What happens if two concurrent requests modify the same aggregate? (Optimistic locking, version field.) — answer: _____
- [ ] If this writes to a DB *and* publishes an event, are they in the same transaction (outbox), or is divergence acceptable?
- [ ] Errors fail loudly, with domain-specific error types — not silent `catch {}`.

**Notes:** _____

---

## 9. Naming

- [ ] Class names accurately describe what's inside.
- [ ] Method names describe *what they do*, not *what they call*.
- [ ] No abbreviations or single-letter names except loop indices.
- [ ] Names match the ubiquitous language of the domain.
- [ ] No "Manager", "Helper", "Util", or "Processor" suffixes — those usually hide a missing concept.

**Notes:** _____

---

## 10. Cost vs. Benefit

- [ ] Every abstraction in the change has earned its complexity. No interfaces with one implementation, no factories returning one type, no DI container for three classes.
- [ ] No code added "just in case we need it later."
- [ ] Comments explain *why*, not *what*. (If a comment explains what, the code should do so instead.)
- [ ] The PR deletes at least *something* — dead code, an old branch, a TODO, a stale comment. If not, why?

**Notes:** _____

---

## 11. Documentation and Decisions

- [ ] If the change introduces a non-default architectural choice, an [ADR](../../team-lead/assets/adr-template.md) accompanies (or precedes) the PR.
- [ ] If the change establishes a new everyday default the team should follow, a [DAD](../../team-lead/assets/dad-template.md) captures it.
- [ ] If the change affects how a system works at a level a future engineer would need to know, the relevant doc under `docs/` is updated in the same PR.
- [ ] The vocabulary in code, tests, comments, and docs is consistent.

**Notes:** _____

---

## Verdict

- [ ] **Approve** — design is sound; ready to merge.
- [ ] **Approve with minor changes** — non-blocking suggestions only.
- [ ] **Request changes** — blocking issues identified above.
- [ ] **Needs design discussion** — too many fundamental problems for line-by-line review; pull this into a conversation.

**Top three things to fix (in priority order):**

1. _____
2. _____
3. _____

---

## Related

- [solid.md](../references/solid.md)
- [separation-of-concerns.md](../references/separation-of-concerns.md)
- [cohesion-and-coupling.md](../references/cohesion-and-coupling.md)
- [code-review-heuristics.md](../references/code-review-heuristics.md)
- [refactoring-recipes.md](../references/refactoring-recipes.md)
