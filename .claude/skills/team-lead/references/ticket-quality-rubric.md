# Ticket Quality Rubric

Score each ticket 0–2 on each dimension. Total ≥10/12 = ready to work. <8 = send back for rework.

| # | Dimension | 0 | 1 | 2 |
|---|---|---|---|---|
| 1 | **Title** | "fix stuff" | Has verb + object but vague | Action verb + specific subject |
| 2 | **Problem statement** | Missing | Present but unclear who/what | Clear who is affected, what's broken, expected behavior |
| 3 | **Acceptance criteria** | None | Listed but not testable | Bulleted, testable, complete |
| 4 | **Scope** | Multiple unrelated outcomes | Slight scope ambiguity | One outcome, clearly bounded |
| 5 | **Links / context** | No links, no context | Some links, gaps | Linked to epic, related tickets, PRs, ADRs as relevant |
| 6 | **Owner & priority** | Both missing | One missing or unjustified | Both set, priority justified |

## Worked Examples

### ❌ Bad (score 2/12)
> **Title:** Cleanup auth
> **Description:** auth is messy, fix it
> **AC:** —
> **Owner:** —
> **Priority:** Urgent

Problems: vague title, no problem statement, no AC, no owner, mystery urgent.

### ⚠️ Mediocre (score 7/12)
> **Title:** Refactor session middleware
> **Description:** The session middleware has grown organically and is hard to test.
> **AC:** Make it cleaner and easier to test.
> **Owner:** @alice
> **Priority:** Medium

Problems: AC isn't testable ("cleaner"), no link to the affected files, no scope boundary — could balloon.

### ✅ Good (score 12/12)
> **Title:** Extract `requireAuth` middleware into its own module with unit tests
> **Description:** `requireAuth` currently lives in `src/server/index.ts` mixed with route registration. This blocks unit-testing the auth path in isolation and was a contributing factor in incident INC-204.
> **AC:**
> - `requireAuth` exported from `src/server/middleware/require-auth.ts`
> - ≥90% line coverage in `require-auth.test.ts`
> - All existing routes wired through the new module; no behavioral change
> - No new dependencies added
> **Links:** parent epic ENG-89 · incident INC-204 · related PR #441
> **Owner:** @alice · **Priority:** P2 (post-incident hardening)

Specific subject, clear motivation, testable AC, scope fence ("no behavioral change"), linked context.

## Priority Rubric

| Priority | Definition | Examples |
|---|---|---|
| **P0 / Urgent** | Active customer impact or revenue loss. Drop everything. | Production outage, payment failures, security incident |
| **P1 / High** | Significant impact, time-sensitive (this week). | Feature blocking a launch, regression for >5% of users |
| **P2 / Medium** | Important but not time-sensitive (this cycle). | Tech debt with concrete pain, planned features |
| **P3 / Low** | Nice to have. May be closed without action. | Polish, minor optimizations, ideas |

If you can't justify a priority by referencing the rubric, the priority is wrong.
