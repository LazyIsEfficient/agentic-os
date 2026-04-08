# Quality Baseline Check

The quality baseline is the set of checks the enforcer applies to code, tests, and documentation to verify the work meets the team's bar. Like the security baseline, it doesn't restate the rules — it routes to the source-of-truth skills and confirms that the work complies.

The quality baseline is *less* non-negotiable than security. Some quality checks can be deferred or scoped down with an explicit decision; the enforcer's job is to surface the trade-off, not to block all imperfection.

## What the Quality Baseline Covers

| Category | Source | What the enforcer checks |
|---|---|---|
| **Code design** | [software-design](../../software-design/SKILL.md) | Composition, cohesion, separation of concerns, SOLID where applicable |
| **Code review process** | [software-design/references/code-review-heuristics.md](../../software-design/references/code-review-heuristics.md) | Was the PR actually reviewed? Were the high-impact concerns surfaced? |
| **Test coverage** | [typescript-testing-backend](../../typescript-testing-backend/SKILL.md), [typescript-testing-frontend](../../typescript-testing-frontend/SKILL.md), [typescript-quality-engineering](../../typescript-quality-engineering/SKILL.md) | Are there tests? Do they cover the changed code? Are they testing observable behavior? |
| **Test quality** | Same | Are the tests independent, deterministic, and meaningful? |
| **Accessibility** (UI) | [ux-design/references/accessibility.md](../../ux-design/references/accessibility.md) | WCAG AA: contrast, keyboard, semantic HTML, ARIA, color independence |
| **UX writing** (UI) | [ux-design/references/content-and-ux-writing.md](../../ux-design/references/content-and-ux-writing.md) | Plain language, error messages, empty states, no lorem ipsum |
| **Microcopy** (UI) | Same | Real text in production; no placeholders |
| **Documentation** | [documentation-writer](../../documentation-writer/SKILL.md) | Are user-facing docs updated? Are non-obvious code decisions commented? |
| **API design** (when applicable) | [system-architect](../../system-architect/SKILL.md) | Consistent with existing API patterns; backwards-compatible where required |
| **Internationalization** (UI) | [ux-design/references/content-and-ux-writing.md](../../ux-design/references/content-and-ux-writing.md) | Translation keys, not literal strings; layout supports text expansion |
| **Performance** (when applicable) | [site-reliability-engineering](../../site-reliability-engineering/SKILL.md), [godot-engineer/references/performance-and-profiling.md](../../godot-engineer/references/performance-and-profiling.md) | No obvious regressions; no allocations in hot paths; profiled if performance-critical |

The enforcer's job for each category: **verify that the relevant source-of-truth skill's baseline has been met**, citing the specific reference file when blocking.

## The Check, Step by Step

### Step 1: Identify the code-shape and scope

What kind of work is this?

- **A new feature** that adds functionality.
- **A bug fix** that corrects existing behavior.
- **A refactor** that changes structure without changing behavior.
- **A configuration change**.
- **A documentation update**.
- **A dependency update**.

Each kind has different quality concerns. A bug fix needs different checks than a new feature. A refactor needs to verify behavior is preserved (tests still pass, no functional changes). A doc update needs minimal review.

### Step 2: Check the code design

For non-trivial code changes, route to [software-design](../../software-design/SKILL.md).

The questions:

- **Does this change belong here?** Or is it touching files that shouldn't be involved? Sign of a missing concept or shotgun surgery.
- **Does it cross layer boundaries the wrong way?** Domain code reaching into infrastructure; tight coupling via deep `getNode` paths; etc.
- **Is the logic in the right place?** Business rules on entities; persistence in repositories; HTTP concerns in controllers.
- **Are invariants enforced where they belong?** Or scattered across callers?
- **Are abstractions earning their cost?** Or over-engineered?
- **Is the naming honest?** Class and method names match what they do.
- **Is testability OK?** Hard-to-test code is a design smell.

The enforcer doesn't restate the design heuristics. The enforcer asks: "Did the code review surface these concerns? If the answer is yes and they were addressed, OK. If the answer is no, flag them."

### Step 3: Check the test coverage

For any non-trivial change, there should be tests. The question is *what kind*.

- **For a new feature**: tests of the new functionality. Unit tests for the building blocks; integration tests for the seams; E2E tests for the critical paths.
- **For a bug fix**: a regression test that would have caught the bug. Without this, the same bug returns.
- **For a refactor**: existing tests still pass. (No new tests needed if behavior is unchanged.)
- **For a configuration change**: smoke tests, ideally.

The enforcer routes to the relevant testing skill and verifies:

- **Are there tests?** A non-trivial change with no tests is a flag.
- **Do they cover the changed lines?** Not 100% — just the meaningful parts of the change.
- **Are they testing the right thing?** Observable behavior, not internal calls.
- **Do they pass in CI?** A failing test is a block.
- **Are they following the team's testing conventions?** Routes to the testing skills.

The enforcer doesn't enforce a coverage *number* (90%? 80%?). The enforcer enforces *meaningful* coverage of *changed* code.

### Step 4: Check the accessibility (UI changes)

For UI changes, route to [ux-design/references/accessibility.md](../../ux-design/references/accessibility.md).

The baseline:

- **Color contrast** meets WCAG AA.
- **Color is not the only signal** for any meaning.
- **Semantic HTML** is used (button, link, heading, etc.).
- **Keyboard navigation** works.
- **Focus indicators** are visible.
- **Form labels** are present and associated.
- **Alt text** for meaningful images.
- **ARIA attributes** where needed.
- **Animations** respect `prefers-reduced-motion`.

The enforcer verifies these have been considered. For non-trivial UI work, the enforcer also checks that the change has been *manually* tested with keyboard navigation (not just automated tests). Automated accessibility tools catch ~30-50% of issues; manual testing catches the rest.

### Step 5: Check the UX writing

For UI changes that include text:

- **No lorem ipsum.** All text is final.
- **Error messages are specific and actionable.** No "something went wrong."
- **Empty states explain what would normally be there** and provide a next action.
- **Button labels are verb + object** ("Save changes," not "OK").
- **Translation keys** for any user-facing string.
- **Voice and tone** consistent with the rest of the product.

The enforcer doesn't write the copy. The enforcer flags when copy is missing or when it falls outside the team's standards. Routes to [ux-design/references/content-and-ux-writing.md](../../ux-design/references/content-and-ux-writing.md).

### Step 6: Check the documentation

- **User-facing docs** updated if user-visible behavior changes.
- **API docs** updated if API changes.
- **Code comments** for non-obvious decisions.
- **README** updated if setup or running instructions change.
- **CHANGELOG** entry if the team maintains one.

The enforcer doesn't write docs. The enforcer flags when docs are missing for changes that should have them.

### Step 7: Check API and contract changes

If the change modifies an API, an event schema, a function signature exposed across teams, or any other contract:

- **Is the change backwards-compatible?** If not, who's the consumer? Have they been notified?
- **Is there a deprecation period** for removed fields?
- **Is the version bumped** appropriately?
- **Is there a migration path** for existing consumers?

Routes to [system-architect](../../system-architect/SKILL.md) for API design principles.

### Step 8: Check performance impact (when relevant)

For changes that might affect performance:

- **In hot paths**: any new allocations? Any new database queries? Any blocking calls?
- **In rendering code**: any new draw calls? Any unbatched work?
- **In CI**: did the change make CI noticeably slower?
- **In production**: are there relevant performance metrics? Is there a baseline to compare against?

The enforcer doesn't measure performance. The enforcer flags when a change is likely to have performance impact and requires that the team verify it before merge. Routes to [site-reliability-engineering](../../site-reliability-engineering/SKILL.md) for performance practices.

### Step 9: Verify automated checks have run

- **Linter** has run and passed.
- **Formatter** has been applied.
- **Type checker** has run and passed (in typed languages).
- **CI tests** have run and passed.
- **Security scans** have run.
- **Accessibility scans** (where applicable) have run.

The enforcer doesn't run these manually. The enforcer verifies they've been run by CI and that their results are clean. A failed check is a block.

## What "Quality" Doesn't Mean

The quality baseline is *not*:

- **Personal preference about style**. The formatter handles formatting.
- **Bikeshedding about variable names**. If the name is reasonable, leave it alone.
- **Maximum test coverage**. Coverage is a means, not an end.
- **Perfect code**. Perfect is the enemy of good; the team has limited capacity.
- **Performance optimization for code that isn't measurably slow**. Profile first.
- **Documentation for trivial code**. Self-explanatory code doesn't need comments.
- **Adding features that "would be nice"**. Stay in scope.

The enforcer's job is to apply the baseline, not to chase perfection. Pragmatism matters; the team's velocity matters; pure quality maximization is gatekeeping.

## Calibration: How Strict to Be

The strictness depends on the work:

| Work shape | Strictness |
|---|---|
| Bug fix in isolated code | Light (test the fix; don't refactor adjacent code) |
| New feature in greenfield code | Medium (clean design, full tests, accessibility) |
| Change to load-bearing code | High (extra review, regression tests, performance check) |
| Refactor of existing code | Medium (verify behavior is preserved; tests pass) |
| Performance-critical change | High (profile before and after) |
| User-facing UI change | High (accessibility, microcopy, design conformance) |
| Internal tool / CLI | Light (functionality matters more than polish) |
| Throwaway script | Very light (it's throwaway) |

The enforcer adjusts the bar based on what the work *is*, not on a uniform standard. The same change in two different contexts might have different bars.

## Common Failure Modes

### "Tests aren't needed for this change"

Sometimes true (a config change with no logic). Usually false (any code change has things to test).

The enforcer asks: "What would tell us this is broken? If the answer is 'production telemetry' or 'a customer report,' that's too late. If the answer is 'a regression test,' add it now."

### "I'll add the tests next sprint"

Next sprint doesn't come. The enforcer doesn't accept this for any change that introduces or modifies behavior.

### "The code reviewer didn't flag it"

The code review missed it. That happens. The enforcer's job is the *second* layer of defense; some things will get caught here that the original review missed.

### "Senior engineer wrote it; I trust it"

Senior engineers make mistakes too. The bar is the same.

### "This is just a hotfix"

Hotfixes are exactly when the bar matters most. A hotfix that introduces a new bug because it skipped quality checks is much worse than the original problem.

The enforcer's response: a hotfix should still meet the baseline. If the baseline can't be met under the time pressure, the team should consider whether the hotfix is the right approach (vs. rolling back, vs. communicating the issue).

### "We'll fix the accessibility later"

Accessibility, like security, doesn't get fixed later. It's in the design from the start or it's not in the product. The enforcer treats accessibility as a baseline gate, not an optional polish step.

### "The lorem ipsum is just placeholder; we'll replace it"

Replace it now. Lorem ipsum that ships is lorem ipsum the user sees.

## Quality Exceptions

Unlike security, quality has more room for legitimate exceptions:

- **Temporary debt for a deadline**: ship without the full test suite, file the gap, address it next sprint.
- **Skipping a code design refinement** because the rewrite is bigger than the value.
- **Deferring an accessibility issue** for an internal tool (not a user-facing product).
- **Skipping a test** that's hard to write because the underlying code is being deleted next month.

In each case, the exception process applies (see [exceptions-and-waivers.md](exceptions-and-waivers.md)). The enforcer's job is to make the trade-off *visible and deliberate*, not to block.

The pattern: **flag the gap, route through exception, decide deliberately**.

## Anti-Patterns

- **Approving without actually reviewing.** Rubber stamp.
- **Blocking on trivial style issues** while missing the substantive concerns.
- **Approving security-relevant code** that hasn't passed the security check.
- **Inconsistent strictness.** Strict on some PRs, loose on others.
- **No tests required** for any change. Coverage rots fast.
- **100% coverage requirement** that the team games. Coverage is a means, not an end.
- **Approving UI work without accessibility check.** Ships inaccessible.
- **Approving placeholder text.** Placeholder ships.
- **No documentation requirement** for changes that need it.
- **Letting failed CI through** because the failure is "unrelated."
- **Treating quality as binary** instead of a spectrum that depends on the context.
- **Pure no without options.** "This isn't good enough" without "here's how to make it good enough."
- **Reviewing for personal style** instead of for the team's standards.
- **Not citing the source skill.** "This is bad" without specifying *which standard* it violates.

## Related

- [the-gates.md](the-gates.md) — when this check happens
- [security-baseline-check.md](security-baseline-check.md) — the security half
- [operational-readiness-check.md](operational-readiness-check.md) — what comes after this for releases
- [exceptions-and-waivers.md](exceptions-and-waivers.md) — when quality is deferred
- [software-design](../../software-design/SKILL.md) — source of truth for code design
- [typescript-testing-backend](../../typescript-testing-backend/SKILL.md), [typescript-testing-frontend](../../typescript-testing-frontend/SKILL.md), [typescript-quality-engineering](../../typescript-quality-engineering/SKILL.md) — sources of truth for testing
- [ux-design/references/accessibility.md](../../ux-design/references/accessibility.md) — source of truth for accessibility
- [ux-design/references/content-and-ux-writing.md](../../ux-design/references/content-and-ux-writing.md) — source of truth for microcopy
