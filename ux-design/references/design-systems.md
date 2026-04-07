# Design Systems

A design system is a shared language between design and engineering — a set of reusable components, design tokens, and patterns that the team builds with instead of reinventing every screen. Done well, a design system makes consistency cheap, lets the team move fast, and frees designers and engineers to focus on the interesting problems instead of the recurring ones.

Done badly, a design system is a permanent backlog of "the system can't do what I need" complaints, a maintenance burden nobody owns, and a thick layer of friction between design and ship.

This file is the playbook for building, contributing to, and not over-investing in a design system.

## What a Design System Is (and Isn't)

A design system is:

- **A set of design tokens** — the smallest atoms of visual design (color, type, spacing, radius, shadow). Defined once, consumed everywhere.
- **A library of reusable components** — buttons, inputs, cards, modals, tables, all built once and used many times, in design tools and in code.
- **Documented patterns** — the agreed-upon way to do common things (forms, lists, empty states, error states).
- **Accessibility built in** — the components are correct by default; you can't accidentally ship an inaccessible button.
- **Governance** — a process for proposing changes, accepting contributions, deprecating things, communicating updates.
- **A living thing** — versioned, evolving, breaking sometimes, improving constantly.

A design system is *not*:

- A Figma library by itself. (Figma is the design representation; the code is half the system.)
- A code component library by itself. (Code without a design representation drifts.)
- A finished thing. (A "complete" design system is a stagnant design system.)
- Mandatory uniformity. (A system enables consistency where consistency helps; it doesn't ban differentiation where differentiation matters.)
- A substitute for design judgment. (The system gives you tools; you still decide how to use them.)

## When to Build a Design System

Building a design system is expensive — months of upfront work, ongoing maintenance, governance overhead. Worth it when:

- **You have multiple products or surfaces** that share a brand and behaviors.
- **You have multiple teams** each doing the same component differently (the giveaway: 7 different button styles in production).
- **You're growing the design and engineering team** and onboarding cost is rising.
- **Inconsistency is becoming a customer complaint** or causing real bugs.
- **You can sustain the maintenance** with at least one part-time owner.

It's *not* worth it when:

- **You have one small product** with one designer and one developer.
- **The product is in early discovery** and the design itself is changing weekly.
- **There's no team to maintain it.** A design system with no owner is a smell that turns into rot.
- **The team is unwilling to use it.** A system that everyone ignores is worse than no system.

A useful default for early-stage teams: **don't build a design system; build a small set of conventions.** A handful of tokens (color, spacing, type), a few primitive components (button, input, card), a shared file. That's enough until the team grows.

## Tokens

Design tokens are the smallest atoms of the system: named values for colors, sizes, spacings, radii, shadows, etc. Tokens are *named* not *literal*: not `#3B82F6` but `color.brand.primary` or `color.action.default`.

### Why named tokens

Three reasons:

1. **Single source of truth.** Change the value once; it changes everywhere.
2. **Semantic meaning.** `color.error` is clearer than `#DC2626`. The next designer or developer knows what it's for.
3. **Theme support.** Dark mode, brand variants, white-label products — all swap tokens, not values.

### Token categories

A useful starting set:

```
color
├── neutral
│   ├── 0     (white)
│   ├── 50    (very light gray)
│   ├── 100
│   ├── ...
│   └── 900   (near-black)
├── brand
│   ├── primary
│   └── secondary
├── action
│   ├── default
│   ├── hover
│   ├── active
│   └── disabled
└── semantic
    ├── success
    ├── warning
    ├── error
    └── info

spacing
├── 0    (0px)
├── 1    (4px)
├── 2    (8px)
├── ...

radius
├── none (0)
├── sm   (4px)
├── md   (8px)
├── lg   (12px)
└── full (9999px)

font
├── family
│   ├── sans
│   └── mono
├── size
│   ├── xs   (12px)
│   ├── sm   (14px)
│   ├── ...
├── weight
│   ├── regular  (400)
│   ├── medium   (500)
│   ├── semibold (600)
│   └── bold     (700)
└── lineHeight
    ├── tight  (1.2)
    ├── normal (1.5)
    └── loose  (1.7)

shadow
├── none
├── sm
├── md
├── lg
└── xl
```

### Two layers: primitive and semantic

Mature systems often have **two token layers**:

- **Primitive tokens** are the literal values: `color.blue.500`.
- **Semantic tokens** map intent to primitives: `color.action.default` → `color.blue.500`.

Components use semantic tokens. When the brand changes, you update the mapping (`color.action.default` → `color.indigo.500`) and the entire UI follows.

This indirection is powerful but adds complexity. Add it when you have themes (dark mode, brand variants) or are likely to.

### Tokens in code

Tokens should live in code as the source of truth — JSON, JS objects, CSS variables, Tailwind config, Style Dictionary output, whatever fits your stack. The Figma library should *consume* the same tokens, ideally automatically (Tokens Studio for Figma, or similar tooling).

The single most common design-system failure: design tokens in Figma and code drift apart. The Figma library has one shade of blue; the code has another. The fix is automation — generate the Figma tokens from the code (or vice versa) instead of maintaining them by hand.

## Components

A component is a reusable interface element: a button, an input, a card, a modal. Each component has:

- **A defined API** — the props/parameters it accepts.
- **A set of variants** — primary, secondary, ghost, etc.
- **A set of states** — default, hover, focus, active, disabled, loading, error.
- **Accessibility behavior** — keyboard support, ARIA attributes, focus management.
- **Documentation** — what it does, when to use it, when not to use it, examples.

### Anatomy of a good component

A button component might have:

- **Variants:** primary, secondary, tertiary, ghost, destructive
- **Sizes:** sm, md, lg
- **States:** default, hover, focus, active, disabled, loading
- **Optional:** with icon (left, right, only), full-width, link-style

Each combination is documented and visually consistent. The designer using the Figma component doesn't have to recreate any of these; the engineer using the code component doesn't either.

### Variants vs new components

A common question: "Is this a variant of an existing component, or a new component?"

Heuristic: if the variants share **purpose and behavior**, they belong to one component with variants. If they share *appearance* but have different purposes, they're separate components.

Examples:

- **Button (primary, secondary, ghost)** — same purpose (a clickable action), different visual emphasis. One component, three variants.
- **Button vs Link** — different purposes (action vs navigation), different behaviors (form submission vs URL navigation), different accessibility semantics. Two components, even if they look similar.
- **Card vs Tile** — if they have the same structure (header, content, footer) but different sizes or use cases, often one component with size/type variants. If they're structurally different, two components.

Err on the side of fewer components with more variants. Many small components fragment the system.

### Composition over configuration

A component with 47 props is unmaintainable. A component built from smaller pieces — `<Card><CardHeader/><CardContent/><CardFooter/></Card>` — is composable, flexible, and easier to understand.

Compose where possible. Configure when composition would be over-engineered for the use case.

### Component documentation

Each component needs documentation. The minimum:

- **What it is** (one sentence).
- **When to use it.**
- **When *not* to use it.**
- **Visual examples** of all variants and states.
- **Code example** (the canonical usage).
- **API reference** (props, slots, events).
- **Accessibility notes** (keyboard, ARIA, color contrast).
- **Related components** (links to alternatives).

Tools: Storybook is the de facto standard for component documentation in code. Figma docs pages are common for the design representation. The two should match.

## Patterns

A pattern is the recommended way to do something that's bigger than a single component — a form, an empty state, a destructive action confirmation, an onboarding flow, a search.

Patterns are higher-level than components and lower-level than full features. They're the team's accumulated wisdom about how to do common things consistently.

A pattern document includes:

- **The pattern's purpose.**
- **The components used.**
- **The structure** (with diagrams or examples).
- **Variations** for different use cases.
- **Accessibility considerations.**
- **Anti-patterns to avoid.**

Common patterns to document:

- **Forms** (layout, validation, submission, error handling).
- **Empty states** (illustration, message, primary action).
- **Error states.**
- **Loading states.**
- **Confirmation dialogs** (destructive actions).
- **Tables** (selection, sorting, filtering, pagination).
- **Navigation patterns** (sidebar, top nav, breadcrumbs).
- **Search and filtering.**
- **Notification and feedback** (toasts, banners, alerts).

## Governance

A design system without governance becomes a free-for-all or a deserted town. Governance is the answer to: who owns this, how do changes happen, how is it kept honest?

### Ownership models

| Model | How it works | Best for |
|---|---|---|
| **Centralized team** | A dedicated design system team builds and maintains everything. | Large orgs (~100+ engineers). Strong, consistent, but bottlenecked. |
| **Federated** | Multiple teams contribute; a small core team curates and reviews. | Mid-sized orgs. Balances ownership and consistency. |
| **Distributed** | Whoever needs a component builds it; loose coordination. | Small teams. Fast but messy. |

The right model depends on team size and how many products share the system. Most teams in the 5–50 engineer range benefit from a federated model with a small (often part-time) core team.

### Change process

A useful change process for a federated system:

1. **Anyone can propose** a new component, a change to an existing one, or a deprecation.
2. **The proposal is discussed** in a regular cadence (e.g. weekly office hours, monthly review).
3. **The change is built** by the proposer or by the design system team.
4. **The change is reviewed** for consistency, accessibility, API quality, naming.
5. **The change is shipped** with versioning and changelog.
6. **The change is communicated** so consumers know about it.

This is a mini-RFC process. The overhead is real but worth it for changes that ripple across many products.

### Versioning

A design system is a dependency. Treat it like one:

- **Semantic versioning.** Breaking changes require a major version bump.
- **Changelog.** What changed, why, how to migrate.
- **Deprecation policy.** Components are deprecated for a known period before removal. Consumers have time to migrate.
- **Long-lived vs experimental.** Some components are stable and supported; others are experimental and can change. Mark which is which.

### When the system says no

The system will, sometimes, not have what someone needs. Three responses:

1. **Use it as-is**, accepting some compromise. Sometimes the right answer when the difference is marginal.
2. **Extend the system.** Add a new variant, a new component, a new pattern. Goes through the change process.
3. **Build outside the system** with explicit acknowledgment. "This screen uses a custom component because X." A note in the design and a ticket to either bring it into the system later or leave it as a one-off.

The wrong response: silently building outside the system, not telling anyone, accumulating drift. This is how systems die — death by a thousand exceptions.

## Design and Code in Sync

The hardest part of running a design system is keeping the design representation (Figma) and the code representation (React, Vue, etc.) in sync. They want to drift.

Practices that help:

- **Tokens generated from code.** The single source of truth for colors, type, spacing is in code. Figma tokens are generated from it.
- **Component parity.** For every code component, there's a Figma component, and vice versa. New components added in one place are added in the other.
- **Storybook embedded in design docs.** The design docs link to live code examples.
- **Joint reviews.** When a new component is added or changed, a designer and an engineer both review.
- **Automation.** Tools like Tokens Studio, Figma Code Connect, Storybook Figma plugin reduce manual sync work.

Without these, drift is constant and the system loses trust.

## Common Failure Modes

### "We're going to build a design system" syndrome

Six months of upfront infrastructure work; nothing ships; team gives up. The right approach is incremental: extract patterns from real product work as they recur, not pre-build a system in the abstract.

### Design system as constraint, not enabler

The system forbids things, doesn't enable them. Designers feel they're fighting the system. They start working around it. The system loses authority.

Fix: when a designer wants something the system doesn't have, the system either *adds it* or *explains why not*. Both are productive responses; "no, just use what we have" is not.

### Design and code drift

Figma library has one button style; code has another. Designers reference the Figma; engineers reference the code; the result is inconsistent UI. Fix: automation, joint reviews, single source of truth in code.

### Frozen system

The system was built two years ago. Brand has shifted; product has expanded; user needs have changed. The system doesn't reflect any of it. Fix: scheduled audits and a willingness to break things (with versioning).

### Component sprawl

300 components, half of them duplicates of each other. Nobody can find anything. New designers add new components instead of finding the existing one because they don't know it exists.

Fix: regular consolidation; good search; good docs; pruning unused components.

### Maintenance debt

The system "works" but is held together with duct tape. Nobody wants to touch it because everything depends on it. Fix: dedicated maintenance time, treated as engineering work, not done in spare cycles.

### "We built a system; we're done"

Treating the system as a project with an end date. Systems don't end; they evolve. Without ongoing investment, they rot.

### Adopting an external system uncritically

"Let's just use Material" / "Let's just use Bootstrap." Sometimes right; often wrong. External systems carry assumptions about the kind of product they're for. They may or may not match yours.

Adopt external systems when:
- The external system matches your product's needs closely.
- You don't have the bandwidth to build and maintain your own.
- The brand isn't a major differentiator.

Build your own when:
- The brand is part of the value proposition.
- The product is genuinely different from what the external system was built for.
- You have the team to maintain it.

A common middle path: build on top of an external system (e.g. Tailwind + Radix primitives + your own component layer). Get the foundation for free; customize the parts that matter.

## Anti-Patterns

- **Building a design system before the product is stable.** Designs that are still changing weekly produce a system you'll discard.
- **Pre-building hundreds of components no one uses.** Build the components real product work needs, not the components you imagine it might need.
- **No owner.** The system is everyone's responsibility, which means nobody's. It rots.
- **No governance.** Anyone can change anything. Inconsistency creeps back in.
- **Excessive governance.** Every change requires a 6-week review. Engineering bypasses the system to ship.
- **Tokens that are just hex codes.** No semantic meaning; no theming support; no maintainability.
- **Components with 30 props.** Unmaintainable. Decompose.
- **A component for every screen.** Components should be reusable across many screens; "ProfilePageHeader" is not a component, it's a layout.
- **Storybook out of date.** The docs say one thing; the code does another. Trust collapses.
- **Figma library out of date.** Same problem in the other direction.
- **No accessibility in the components.** Then every consumer has to add it themselves; most don't; the product is inaccessible.
- **No deprecation policy.** Components live forever; "we can't break anyone." Eventually the system is full of cruft and nobody uses the new things.
- **Over-claiming.** "The design system makes everyone faster." Sometimes; not always; some things are harder. Be honest about trade-offs.
- **Treating Figma as the source of truth.** Then the code drifts and the production UI doesn't match the design.
- **Treating code as the source of truth without keeping Figma in sync.** Then designers design something the system can't render.

## Related

- [visual-design-fundamentals.md](visual-design-fundamentals.md) — the visual decisions tokens encode
- [interaction-design.md](interaction-design.md) — the interaction patterns components enforce
- [accessibility.md](accessibility.md) — accessibility built into components
- [content-and-ux-writing.md](content-and-ux-writing.md) — UX writing patterns as part of the system
- [handoff-and-collaboration.md](handoff-and-collaboration.md) — design tokens as the handoff contract
- [software-design](../../software-design/SKILL.md) — components are software too; SOLID and cohesion principles apply
