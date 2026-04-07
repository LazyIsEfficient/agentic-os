# Domain Modeling — Strategic DDD

Domain-Driven Design has two halves: **strategic** (where do model boundaries go, and what language do we use inside them) and **tactical** (what shapes do we use inside a model — entities, value objects, aggregates). This file covers strategic DDD; see [tactical-ddd.md](tactical-ddd.md) for the building blocks.

The strategic half is the more important of the two. You can build a working system without tactical DDD; you cannot build a working system whose model is in the wrong place or whose vocabulary contradicts the business.

## The Core Idea

> Software is a model of a domain. The cost of confusion between the team's mental model and the code is paid forever, in every change request.

Domain modeling is the practice of:

1. **Listening to domain experts** until you can describe their work in their own words.
2. **Naming things in code the way they name them.**
3. **Drawing boundaries** around groups of concepts that hang together — bounded contexts.
4. **Defining the relationships** between those boundaries explicitly, so integration happens with eyes open instead of by accident.

When code says `TransactionRow` and finance says "ledger entry," every conversation across that gap costs effort. Multiply by years and you get codebases nobody wants to touch.

## Ubiquitous Language

A *ubiquitous language* is a vocabulary shared by the developers and the domain experts within a single bounded context. The same word means the same thing in conversation, in tickets, in tests, and in code.

Rules:

- **Use the words domain experts actually use,** not what's convenient for code. If they say "policy" and you call it "rule," somebody loses.
- **One word per concept.** If "user," "customer," and "account" mean the same thing, pick one and rename the others.
- **Use the language in code names.** Class names, method names, file names, table names. `Order.cancel()` not `OrderProcessor.handleCancellation()`.
- **Update the language when the domain shifts.** If the business stops calling them "subscriptions" and starts calling them "memberships," rename the code. Yes, all of it. The cost of the rename is much less than the cost of the gap.
- **Different words across bounded contexts is fine.** "Customer" in Sales is not the same thing as "Customer" in Support. They share an ID and not much else.

A ubiquitous language is not a glossary you write once and put on a wiki. It's a living vocabulary you maintain in conversation. The glossary is the side effect.

## Bounded Contexts

A **bounded context** is the boundary within which a particular model — and a particular ubiquitous language — applies. Inside the context, "Order" means one thing. Outside, it might mean something different, and that's fine.

Why bounded contexts matter: every attempt to build a single model that covers all of "Customer," "Order," and "Product" across the whole business eventually collapses under contradictions. Sales' Customer needs marketing preferences and lead status. Billing's Customer needs tax IDs and payment methods. Support's Customer needs ticket history. Forcing one model to satisfy all three produces a god-class with thirty fields, half of which are null in any given context.

The fix: **let each context have its own model.** They share an identity (the customer ID), and they integrate via well-defined contracts at the boundaries.

### How to find the boundaries

You don't draw bounded contexts on a whiteboard from first principles. You discover them through several signals:

- **Language shifts.** When the same word means different things to different people, you've found a boundary. ("Shipment" means "the box" to warehouse and "the contract" to legal.)
- **Org boundaries.** Conway's law: software boundaries naturally align with team boundaries. If two teams own one model, friction is constant.
- **Change rates.** Subsystems that change for different reasons want to be different contexts.
- **Different tools or storage needs.** A search context wants Elasticsearch; a transactional context wants Postgres. That's two contexts.
- **Different stakeholders giving conflicting requirements.** Almost always means two contexts pretending to be one.

### Context maps

Once you have multiple bounded contexts, the relationships between them matter as much as the boundaries themselves. A context map names how each pair of contexts integrates. The vocabulary:

| Pattern | Meaning | When |
|---|---|---|
| **Shared Kernel** | Two contexts share a small, jointly-owned model | High coordination, small overlap, two teams willing to coordinate |
| **Customer / Supplier** | Downstream consumes upstream's API; upstream considers downstream's needs | Friendly teams; downstream can influence upstream |
| **Conformist** | Downstream just accepts whatever upstream produces | Upstream won't or can't accommodate (third party, legacy) |
| **Anti-Corruption Layer** | Downstream wraps upstream in a translation layer | Upstream's model leaks would corrupt the downstream model |
| **Open Host Service** | Upstream publishes a stable, well-documented protocol for many downstreams | Many consumers; upstream commits to API stability |
| **Published Language** | Both sides agree on a third-party schema (events, JSON Schema, Protobuf) | Decoupling integration from either side's internal model |
| **Separate Ways** | No integration. Two systems live next to each other | Integration cost > value |

**The most important pattern in this list is the anti-corruption layer.** It's the translation point that keeps a clean downstream model from being polluted by an upstream model you don't control. In hexagonal terms, the ACL is an adapter that maps between two domain languages — usually living at the boundary between your service and a legacy system, third-party API, or another bounded context.

Example: a `payments` context integrates with a third-party processor whose API talks about `charge`, `customer`, `source`. Your domain talks about `payment`, `payer`, `instrument`. The ACL translates:

```typescript
// adapters/driven/stripe-payment-gateway.ts (anti-corruption layer)
import type { PaymentGateway, Payment, PaymentResult } from '@/core/ports/driven/payment-gateway.port'

export class StripePaymentGateway implements PaymentGateway {
  async charge(payment: Payment): Promise<PaymentResult> {
    const stripeResult = await this.stripe.charges.create({
      amount: payment.amount.cents,
      currency: payment.amount.currency,
      source: payment.instrument.token,
      customer: payment.payer.externalId,
    })
    return this.toPaymentResult(stripeResult)  // translate Stripe → domain
  }

  private toPaymentResult(stripe: Stripe.Charge): PaymentResult {
    return PaymentResult.fromGateway({
      id: PaymentId.from(stripe.id),
      status: this.mapStatus(stripe.status),
      capturedAt: stripe.created ? new Date(stripe.created * 1000) : null,
    })
  }
}
```

The Stripe vocabulary stops at this file. The rest of the codebase talks about `Payment`, `Payer`, `PaymentResult` and never sees a `Stripe.Charge`.

## When DDD Is Overkill

Strategic DDD is not free. It costs upfront thinking, ongoing renames, and disciplined boundaries. It pays back when:

- The domain has **non-trivial rules and concepts** that aren't obvious from the data shape.
- The system will live **for years**, not months.
- **Multiple teams** will work on it.
- The business **changes language and rules** as the company grows.

It is overkill when:

- The system is a thin wrapper over a third-party API. There's no domain to model — just adapters.
- The system is pure CRUD: forms, tables, and reports with no real invariants. ("If it can be expressed as a spreadsheet, you don't need DDD.")
- The system is throwaway, an internal admin tool, or a prototype.
- The business model is simple and stable enough that the data shape *is* the model.

The middle ground is the most dangerous: a system that's too complex for "just CRUD" but where nobody invests in the domain model. You end up with anemic objects, fat services, and a vocabulary that drifts away from the business one PR at a time. If you're in this zone, **start small**: pick the one bounded context with the most painful rules and model it properly. Leave the rest as CRUD until it earns its keep.

## Strategic Design as a Continuous Activity

Bounded contexts are not architecture astronauts' fantasy — they shift as the business shifts. Practical advice:

- **Revisit boundaries every six to twelve months.** Has anything new emerged? Has a team split or merged? Has a concept moved?
- **When a single change requires touching files across many "contexts," your boundaries are wrong.** Either the boundary is in the wrong place, or what you thought was one context is actually two.
- **When two contexts integrate constantly and chattily, they may want to merge.** Or there's a missing third context that owns the conversation.
- **Pay attention to language drift.** If engineers and product start using different words for the same thing, fix it before it ossifies.

## Anti-Patterns

- **Big design up front** — drawing the perfect context map before writing any code. The map only stabilizes after you've built and rebuilt the system a couple of times.
- **One ubiquitous language for the whole company** — collapses under contradictions. Each context gets its own.
- **Stealing terminology from textbooks** — if the business doesn't say "aggregate root," don't bring it into conversations with them. Use DDD vocabulary among engineers, business vocabulary with the business.
- **Shared database across contexts** — the most common form of context bleed. If two contexts write the same table, they're not really separate contexts.
- **Anti-corruption layer that doesn't translate** — passing upstream objects through unchanged with a wrapper class. Pollution with extra steps.
- **Renaming without retiring the old name** — both names live forever, in different files, by different authors. Pick one and grep ruthlessly.

## Related

- [tactical-ddd.md](tactical-ddd.md) — building blocks inside a bounded context
- [separation-of-concerns.md](separation-of-concerns.md) — where the model lives in a layered codebase
- [hexagonal-architecture.md](hexagonal-architecture.md) — anti-corruption layers as adapters
- [system-architect](../../system-architect/SKILL.md) — service boundaries and bounded contexts often (but not always) align
