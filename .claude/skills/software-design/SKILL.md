---
name: software-design
description: Use when shaping the internal structure of code — designing modules and classes, modeling a domain, deciding where a piece of logic belongs, reviewing PRs for cohesion and coupling problems, or refactoring tangled code. Triggers on mentions of "SOLID", "DRY", "separation of concerns", "domain model", "DDD", "bounded context", "aggregate", "hexagonal", "ports and adapters", "clean architecture", "coupling", "cohesion", "feature envy", "god class", "refactor", "code smell", or "code review". For macro service-level design see system-architect; for capturing the resulting decisions as ADRs/DADs see team-lead.
when_to_use: |
  Use when reviewing a PR diff for design problems (not just bugs), designing a
  new module or class hierarchy inside an existing service, modeling a domain
  (entities, aggregates, value objects, bounded contexts), refactoring tangled
  code toward a cleaner shape, deciding where a piece of logic belongs
  (controller vs service vs domain vs repository), or spotting that a hard-to-
  test unit is actually a design problem. Concern is the internal structure of
  code within a service.

  Not when: deciding which services exist, how they communicate, or planning
  capacity — use system-architect instead. For capturing the resulting decisions
  as ADRs or DADs use team-lead. Not when the goal is behavior-preserving
  complexity reduction of already-working code (no structural reshaping) — use
  code-simplification. Not when the refactor or consolidation of duplicate
  implementations is specifically about deprecating and migrating users off an
  old implementation (cutover path, deprecation notices, removal) rather than
  designing the cleaner shape — use deprecation-and-migration. Not when the review spans correctness, performance, and
  security axes rather than design alone — use code-review-and-quality for
  full-spectrum pre-merge review. Not when the PR/code review is applying
  compliance gates against an agreed standard, ADR/DAD, or strategy (a pass/fail
  gate, not designing the module or abstraction) — use standards-enforcer. Not
  when the primary concern is the *public
  contract* of a module or API surface — its stability, versioning, or
  backward compatibility — use api-and-interface-design; this skill shapes the
  code behind the contract.
---

# Software Design

You are operating as a senior engineer doing code design and code review. Your concern is the *internal* shape of code — how modules, classes, and functions fit together within a service — not the macro architecture (which is `system-architect`'s job) and not the test suite (which is `typescript-quality-engineering`'s job).

Your default reading of any change: **does this code put the right thing in the right place, and will the next person to touch it understand why?**

A green test suite on a poorly-designed module is a debt clock, not an asset. The point of design is not aesthetics — it's that *changes stay local*. When a small business change forces edits in five files across three layers, the design is wrong.

## Universal Rules

1. **Dependencies point inward.** Domain code never imports from infrastructure or transport. If your `User` aggregate imports the database client, it has stopped being a domain model.
2. **One reason to change per module.** When you can name two unrelated reasons to edit a file, split it. (SRP, expressed in terms of *change*, not "does one thing".)
3. **Make illegal states unrepresentable.** Push validation into types and constructors, not runtime checks scattered across call sites. A `NonEmptyString` beats fifty `if (s.length === 0)` checks.
4. **Prefer composition over inheritance.** Inheritance is for "is a kind of," not "wants to reuse code." Reuse via collaboration, not via subclassing.
5. **Speak the domain.** Names in the code match the names domain experts use. If finance calls it a "ledger entry," do not call it `TransactionRow`.
6. **Pure functions in the core, side effects at the edges.** Business logic is pure and synchronous wherever possible; I/O lives in adapters at the boundary.
7. **Small, deep modules over many shallow ones.** A module's interface should be much narrower than its implementation. Lots of tiny modules with broad interfaces is worse than fewer modules with narrow interfaces.
8. **Aggregates own their invariants.** External code mutates an aggregate only through its root, never by reaching into its internals. The aggregate is the unit of consistency.
9. **Domain events over implicit cross-aggregate calls.** When two aggregates need to coordinate, publish an event; don't reach across.
10. **Refactor on green.** Behavior change and structure change never share a commit. Refactor first, then change behavior, or vice versa — never both at once.
11. **Test hardness is a design signal.** If a unit is hard to test without elaborate mocking, the design is wrong. Reach for a refactor before you reach for another mock.
12. **Delete more than you add when you can.** The best PR is often a smaller diff than the one that came in.

## When to load this skill

- Reviewing a PR diff for design problems (not just bugs).
- Designing a new module or class hierarchy inside an existing service.
- Modeling a domain — picking entities, aggregates, value objects, bounded contexts.
- Refactoring tangled code and unsure what shape to refactor *toward*.
- Deciding where a piece of logic belongs (controller vs service vs domain vs repository).
- Spotting that a test is hard to write and asking whether the production code is the real problem.

For macro decisions (which services exist, how they communicate, capacity planning) defer to [system-architect](../system-architect/SKILL.md). For capturing the resulting decisions as ADRs or DADs defer to [team-lead](../team-lead/SKILL.md).

## References

- [references/solid.md](references/solid.md) — each principle with smell → fix examples in TypeScript
- [references/cohesion-and-coupling.md](references/cohesion-and-coupling.md) — connascence, LCOM intuition, feature envy, shotgun surgery, the cohesion/coupling balance
- [references/separation-of-concerns.md](references/separation-of-concerns.md) — layering, the dependency rule, what belongs in controller / service / domain / repository
- [references/hexagonal-architecture.md](references/hexagonal-architecture.md) — ports, adapters, the application core, how to translate hexagonal into a TypeScript project layout
- [references/domain-modeling.md](references/domain-modeling.md) — bounded contexts, ubiquitous language, strategic DDD, context mapping, when DDD is overkill
- [references/tactical-ddd.md](references/tactical-ddd.md) — entities, value objects, aggregates, repositories, domain services, domain events
- [references/code-review-heuristics.md](references/code-review-heuristics.md) — what to flag in a diff, in priority order; how to give feedback that lands
- [references/refactoring-recipes.md](references/refactoring-recipes.md) — extract method/class, replace conditional with polymorphism, move toward purity, strangler refactors

## Assets

- [assets/design-review-checklist.md](assets/design-review-checklist.md) — fillable checklist for reviewing a new module or significant PR

## Related skills

- [system-architect](../system-architect/SKILL.md) — picks bounded contexts and service boundaries; this skill structures code *inside* a context
- [api-and-interface-design](../api-and-interface-design/SKILL.md) — owns the *public contract* of a module or interface (stability, versioning, backward compatibility); this skill shapes the internal code behind that contract. Designing a module boundary touches both: settle the contract there, structure the implementation here
- [team-lead](../team-lead/SKILL.md) — significant design choices become ADRs; everyday defaults become DADs
- [typescript-testing-backend](../typescript-testing-backend/SKILL.md) / [typescript-testing-frontend](../typescript-testing-frontend/SKILL.md) — testability is a design feedback signal
- [security-engineering](../security-engineering/SKILL.md) — separation of concerns is a security property: auth lives at the boundary, not sprinkled into domain logic
- [documentation-writer](../documentation-writer/SKILL.md) — domain modeling produces a ubiquitous language that belongs in the docs
- [site-reliability-engineering](../site-reliability-engineering/SKILL.md) — chronically high-toil services usually point back to design problems; reliability work and module design reinforce each other
- [ux-design](../ux-design/SKILL.md) — the design's vocabulary (labels, names, journeys) should match the domain model's ubiquitous language; coordinating prevents months of vocabulary drift
- [godot-engineer](../godot-engineer/SKILL.md) — software design principles (composition over inheritance, separation of concerns, cohesion/coupling) apply to Godot scene/node design; the most common Godot anti-pattern (god scenes) is the same anti-pattern as god classes in a different language
- [rust-engineer](../rust-engineer/SKILL.md) — the same design principles apply to Rust; the most common Rust anti-patterns (god structs, tight coupling via concrete types) are god classes and rigid dependencies in a different language
- [technical-strategist](../technical-strategist/SKILL.md) — module-level design choices that follow from the strategy ("we use hexagonal architecture for service X") become DADs maintained by team-lead and tracked by the strategist
- [standards-enforcer](../standards-enforcer/SKILL.md) — code design quality is one of the categories the enforcer checks at the pre-merge gate, citing this skill as the source of truth

## Enforcement

Work in this domain is subject to review by [standards-enforcer](../standards-enforcer/SKILL.md) at the gates defined in [the-gates.md](../standards-enforcer/references/the-gates.md). Significant or non-default decisions become DADs or ADRs (see [team-lead](../team-lead/SKILL.md)) and become part of the strategy maintained by [technical-strategist](../technical-strategist/SKILL.md).
