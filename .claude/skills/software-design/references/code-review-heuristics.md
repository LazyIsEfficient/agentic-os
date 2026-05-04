# Code Review Heuristics

A code review is a design conversation, not a typo hunt. The goal is to catch the things that *will be expensive later if they go in now*: design problems, layering violations, hidden coupling, missing invariants. Not whitespace.

This file is a priority-ordered checklist for reading a diff, plus a guide to giving feedback that lands.

## What to Look for, in Order

Stop at the first category that fires — fix it before moving on. The earlier categories invalidate the later ones.

### 1. Does this change belong here at all?

Before reading the diff, ask: **does the file being modified have a legitimate reason to be involved in this change?**

- A bug fix that touches eight files across three layers usually means the design is wrong, not the bug. The bug is a symptom; the [shotgun surgery](cohesion-and-coupling.md#shotgun-surgery) is the disease.
- A "small feature" that requires editing controllers, services, repositories, and DTOs for a single new field probably means the new field doesn't have an obvious owner. Find the missing concept.
- An "unrelated cleanup" mixed with a feature change is a red flag. Two PRs.

### 2. Does it cross a layer boundary the wrong way?

Read the imports at the top of every changed file in the domain layer. **No imports from `infrastructure/`, `transport/`, or third-party SDKs.** If you see one, that's the comment.

- `import { prisma } from '@/lib/prisma'` in a domain file? → block.
- `import axios from 'axios'` in an application service? → block. Wrap it in a port.
- HTTP status codes referenced anywhere except the controller? → block.
- Domain entity calling `logger.info(...)`? → block (decorator at the boundary).

This is mechanical and you can usually catch it with lint rules. If you can't, this is the most valuable comment you'll leave.

### 3. Is logic in the right layer?

A controller that does:

```typescript
async function placeOrderHandler(req: Request, res: Response) {
  const items = req.body.items
  const total = items.reduce((sum, i) => sum + i.price * i.quantity, 0)
  if (total > 10000) await sendApprovalEmail(req.body.userId)
  await prisma.order.create({ data: { items, total } })
  res.json({ ok: true })
}
```

…has business logic (the $10k threshold, the discount calculation), persistence, and email coordination *all* in the controller. Three layers' worth of work crammed into one. This is the most common form of layering rot.

The comment: "the $10k approval rule and the order persistence both belong in a use case; the controller should only parse, authorize, call, and respond."

### 4. Are invariants enforced where they belong?

Look for runtime checks like `if (status === 'shipped') throw ...` in services or controllers. If the entity has a `status` field, the rule should be on the entity, not in the caller. Otherwise the next caller will forget.

Look for entities with public setters or with all-public fields. The entity isn't enforcing anything; it's just a data bag. Anemic model.

### 5. Are abstractions earning their cost?

The opposite failure: too much structure for too little benefit.

- An interface with one implementation and no test fakes? → probably premature.
- A factory that returns one concrete type? → delete the factory.
- A `BaseService` that two services inherit from? → composition, not inheritance.
- A "dependency injection container" introduced for three classes? → composition root with constructors is enough.
- Wrapper classes (`UserManager` wraps `UserService` wraps `UserRepository`) with no behavior added at each layer? → flatten.

The principle: **wait for the second use case before extracting an abstraction**. The first one always looks general; the second tells you what's actually general.

### 6. Is the naming honest?

- Does the class name accurately describe what's inside? `UserService` that handles auth, profile, and notifications has lied about its scope.
- Does the method name describe *what it does*, or just *what it calls*? `processOrder` is uninformative; `placeOrder`, `cancelOrder`, `refundOrder` are honest.
- Does the variable name match the type? `data: User` is fine; `data: any` is a smell.
- Is the name in the ubiquitous language? If finance calls it a "ledger entry," it should be `LedgerEntry`, not `TransactionRow`.
- Are there abbreviations or single letters that aren't loop indices? Spell things out.

### 7. Is it easy to test?

Open the test file (or imagine writing it). If the test needs:

- More than two mocks → too coupled.
- A mock for time, randomness, or UUID generation → those should be ports, not direct calls.
- A real database to test a pure rule → the rule isn't pure yet.
- Setup that spans 30+ lines for a unit test → the unit is doing too much.

**If the test is hard, the design is wrong.** Reach for a refactor before reaching for another mock.

### 8. Are concurrency, ordering, and failure handled?

- What happens if this code runs twice for the same input? (Idempotency.)
- What happens if the DB write succeeds and the email send fails? (Transactional boundary.)
- What happens if two requests modify the same aggregate concurrently? (Optimistic locking, version field.)
- What happens if this consumer is at-least-once and the message is replayed? (Inbox / dedup key.)

These don't always require a fix in the PR — sometimes the answer is "we accept this for now, ticket linked." But asking the question is the comment.

### 9. Does the diff also delete anything?

A PR that only adds code and never removes any is suspicious. Most worthwhile changes simplify *something*, even slightly:

- Was the old branch in a switch statement removed when the new strategy was added?
- Was the obsolete helper deleted when its only caller moved on?
- Was the dead config flag removed?

A 500-line addition that doesn't touch the existing code is often code that *runs in parallel with the code it should have replaced*. Both versions now exist forever.

### 10. Does the test prove the right thing?

- Does the test assert observable behavior, or does it assert that internal methods were called? (See `typescript-quality-engineering`.)
- Does it have a literal expected value, or a calculation? `expect(total).toBe(70)`, not `expect(total).toBe(a + b)`.
- Does it test the rule, or does it just exercise the happy path?
- Are edge cases covered? Empty lists, max values, time-zone boundaries, currency mismatches.

### 11. Style and readability

Last and least. Style problems are real but they're cheap to fix and shouldn't dominate review attention.

- Inconsistent formatting? → linter / formatter, not human review.
- Variable names that shadow outer scope? → comment if confusing.
- A function that's three nested levels deep? → suggest extracting.
- A 200-line method? → suggest extracting, but only if you can name the parts honestly.

## How to Give Feedback That Lands

The goal of a comment is **a change in the code or a change in the author's mental model**. A comment that produces neither is wasted ink.

### Be specific

Bad: "this could be cleaner."
Good: "the discount calculation in lines 42–58 belongs on `Order`, not in `OrderController`. Future callers (jobs, CLI) won't go through this controller."

### Lead with the *why*, not the *what*

Bad: "use a value object here."
Good: "passing `(amount: number, currency: string)` everywhere risks mismatches at call sites. A `Money` value object would let the type system catch this and would also be where rounding rules live. Same for the three other call sites of this function."

The "why" lets the author *learn the heuristic*, not just apply this one fix.

### Distinguish blockers from suggestions

Use prefixes (or the platform's labels) so the author knows what must change vs what's optional:

- **Blocking:** correctness, security, layering violation, missing invariant.
- **Suggest:** structural improvement, naming, simplification.
- **Nit:** style, micro-optimization, personal preference. *Use sparingly.*
- **Question:** "is this intentional? I'd expect X here." Use when you're not sure yet.

A review that's all blockers crushes the author. A review that's all nits trains the author to ignore comments. Mix honestly.

### Quote the line, don't reference it

Inline review on the actual line beats "see line 47" every time. The author's eye lands where the conversation is.

### Propose an alternative when you can

Bad: "this is wrong."
Good: "this is wrong because X. I'd do Y instead. Want me to push a commit?"

A concrete alternative is a much smaller cognitive load than "figure out something better."

### Praise what's worth praising

If the design is good — if the author resisted the temptation to add complexity, found a clean abstraction, deleted dead code — say so. The comment costs nothing and the next PR will be better for it.

### Don't review tired

You will hallucinate problems, miss real ones, and write comments that are more snippy than you intended. If you're tired or annoyed, close the tab. Review tomorrow.

## What NOT to Comment On

- **Bikeshed naming choices** when both names are acceptable. Pick a name in your own code.
- **Things the linter or formatter handles.** Configure the tool.
- **Personal style preferences** that aren't in a written team convention. Write the convention first if it matters.
- **Speculative future requirements.** "What if we need to support gRPC later?" Cross that bridge later.
- **Anything that would be a complete rewrite.** If the design is fundamentally wrong, escalate to a conversation, not a 40-comment review thread.

## Anti-Patterns in Reviewing

- **Drive-by review.** Three nits and no engagement with the design. Worse than no review.
- **Bikeshed pile-on.** Four reviewers all weigh in on whether to use `let` or `const` and nobody notices the SQL injection.
- **"LGTM" without reading.** Tells the author nothing and trains everyone to skip review.
- **Approval-as-favor.** Approving because the author needs to ship, despite real problems. The problems don't disappear; they ship to production.
- **Holding the PR hostage** for a personal preference. Leave the comment, mark it non-blocking, approve.
- **Re-litigating old decisions.** "Why are we using React Query?" — not in this PR.

## Related

- [solid.md](solid.md) — what to look for in module structure
- [separation-of-concerns.md](separation-of-concerns.md) — what counts as a layer violation
- [cohesion-and-coupling.md](cohesion-and-coupling.md) — the smell vocabulary
- [refactoring-recipes.md](refactoring-recipes.md) — concrete moves to suggest in comments
- `assets/design-review-checklist.md` — fillable checklist for a significant PR
