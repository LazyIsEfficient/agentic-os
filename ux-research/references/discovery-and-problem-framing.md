# Discovery and Problem Framing

The most expensive mistake in product is solving the wrong problem well. The defense against it is **problem framing**: the practice of holding a question open long enough to understand it before committing to an answer.

This file is the playbook for the generative phase of research — the part *before* there's a design to evaluate. The questions are: who has the problem, what's the problem, why hasn't it been solved already, and is it worth solving?

## The Question Behind the Question

The single most useful skill in discovery is recognizing when a stated request hides a different question.

Examples:

- **"We need to redesign the dashboard."** The question behind the question is usually "users aren't getting value from the dashboard." The redesign might or might not be the answer; you don't know yet.
- **"We need to add a wishlist feature because competitors have one."** The question behind the question is "we are losing customers to competitors and we don't know why."
- **"Marketing wants a chatbot."** The question behind the question is "support volume is high and we want to reduce it" — and the right answer might be better self-service docs, not a chatbot.
- **"Users keep asking for export to CSV."** The question behind the question is "users are doing analysis we're not supporting in the product itself."

The technique: when someone proposes a *solution*, ask **"what problem would that solve?"** Repeat until you hit a problem you can verify. Then research the problem, not the proposed solution.

This is uncomfortable because the proposer often hears "you don't trust me" or "you're slowing things down." Frame it as collaboration: "I want to make sure we're aiming at the same target. Let me play back what I think we're solving."

## Jobs To Be Done

Jobs to be done (JTBD) is a framing that asks: *what is the user hiring this product to do?* It treats the product as an instrument for accomplishing a task in a specific context, and it deliberately ignores demographics in favor of motivation.

### The job statement

A JTBD statement has three parts:

> When `<situation>`, I want to `<motivation>`, so I can `<expected outcome>`.

Examples:

- "When I'm reviewing a PR on my phone in line at the coffee shop, I want to leave a comment without typing on a tiny keyboard, so I can keep the review moving without waiting until I'm back at my desk."
- "When I'm onboarding a new contractor to my agency, I want to give them access to only the projects they're working on, so I don't have to worry about them seeing client work that isn't theirs."
- "When I'm trying to estimate a sprint, I want to see how long similar tasks have taken in the past, so my estimate is grounded in evidence and the team trusts it."

What this format does well:

- **Centers the *situation*** — context shapes solutions, and the same person has different jobs in different situations.
- **Separates *motivation* from *expected outcome*** — the *outcome* is what the user is really after; the *motivation* is the immediate action.
- **Avoids feature requests** — the user doesn't ask for "a comment box" or "role-based permissions," they describe what they're trying to accomplish.

### How to find jobs

Run interviews framed around the situations you suspect are interesting. Ask people to walk you through the *last time* they did the thing — concrete, specific, recent. Avoid hypotheticals; people are bad at them.

Bad question: "What features would you want in a project management tool?"
Good question: "Tell me about the last time you onboarded a new person to a project. Walk me through what you did."

Bad question: "How important is mobile access?"
Good question: "When was the last time you tried to do something work-related on your phone? What were you trying to do? What happened?"

### Switching events

A particularly powerful JTBD technique: ask about the *last time the person switched* from one solution to another. The story of the switch tells you what the previous solution failed at and what the new one had to do. Often more revealing than asking about current usage.

> "When was the last time you switched from one tool to another for managing your work? What pushed you? What pulled you? What were you worried about?"

The "push, pull, anxieties, habits" frame ([Christensen's Switch model](https://strategyn.com/jobs-to-be-done/)) is an unusually generative interview prompt.

## Problem Statements

A problem statement is the artifact you produce after enough discovery to commit to a problem (but not yet to a solution). It's the contract between research and the rest of the team about what you're actually solving.

### A useful format

> **The problem**
> `<who>` has trouble with `<what>` when `<situation>`, which causes `<consequence>`.
>
> **What we know**
> `<the evidence — what research, interviews, analytics support this>`
>
> **What we don't know**
> `<honest list of remaining unknowns>`
>
> **Why now**
> `<why this problem is worth solving in this quarter, not next year>`
>
> **What success looks like**
> `<observable, measurable outcome that would indicate the problem is solved>`
>
> **What we are explicitly *not* doing**
> `<the related problems we are deliberately ignoring for now>`

The "explicitly not doing" section is the most underused. Saying out loud what the team is *not* solving prevents scope creep and frees the team to make sharp decisions.

### Worked example

> **The problem**
> Software team leads have trouble producing accurate sprint estimates when the team has fewer than 6 months of shared history, which causes commitments they can't keep and erodes trust between engineering and product.
>
> **What we know**
> 9 of 12 leads we interviewed in the last study explicitly named estimation as their biggest weekly source of stress. 7 of 12 said they "guess and pad." Analytics shows that 38% of issues take more than 2x their original estimate.
>
> **What we don't know**
> Whether the variance is dominated by individual estimator skill or by team structural factors. Whether people would actually trust a tool's estimate. How much padding is "expected" vs "harmful."
>
> **Why now**
> Two of our largest customers are switching from quarterly to monthly planning cycles, which makes the cost of bad estimates higher. Our biggest competitor just shipped an estimation feature.
>
> **What success looks like**
> Leads who use the new feature for at least one sprint report (in a follow-up survey) that they trust their estimates more, and the variance between estimate and actual narrows by some measurable amount.
>
> **What we are explicitly *not* doing**
> We are not building automated time tracking; we are not changing how issues are scored; we are not solving cross-team estimation; we are not doing capacity planning. All of these are real but separate problems.

A problem statement of this shape is reusable: design uses it to bound the solution space, engineering uses it to estimate the work, product uses it to communicate priorities, and research uses it to scope follow-up studies.

## Opportunity Sizing

Even when a problem is real, it might not be worth solving relative to other problems competing for the same team. Sizing puts a number (rough is fine) on the opportunity:

- **How many users have this problem?** From analytics, support tickets, surveys, or estimation from interviews. Order-of-magnitude precision is enough.
- **How often do they encounter it?** Once a year vs. every day matters enormously.
- **How painful is it?** Mild annoyance vs. blocking a critical workflow.
- **What's the alternative?** A free workaround vs. having to switch products entirely.
- **What's our cost to address it?** Rough engineering estimate; rough design estimate.

Multiply: `users × frequency × pain × (no good alternative)` produces a relative score that lets you rank problems against each other. The numbers are made up, but the *comparison* across problems is what matters.

The most common pitfall: sizing in absolute terms ("3000 users have this problem") when what you need is *relative* terms ("this is bigger than the other 4 things on the backlog"). Don't fight for precision; fight for clarity about which problems beat which other problems.

## What "Discovery" Actually Looks Like

A discovery effort is usually a small, fast study — not a six-month deep dive. A typical shape:

1. **A week of preparation.** Write the question, recruit ~6 participants, draft the interview guide.
2. **A week of interviews.** 6 conversations of 45–60 minutes each. Record (with consent), take notes, take a break between sessions.
3. **A week of synthesis.** Affinity mapping, theme identification, drafting the problem statement.
4. **A two-day readout.** A working session with the team to walk through findings and align on next steps.

Three weeks, maybe four. If discovery is taking three months, the question is too broad — narrow it.

Faster shapes are also valid: **continuous discovery** is the practice of running 1–3 interviews every week, ongoing, rather than as a discrete project. This produces a rolling, always-fresh understanding of users at the cost of slightly less depth per study. For mature teams, continuous discovery is usually the right default.

## When Discovery Goes Sideways

Discovery often produces uncomfortable findings. Some patterns to watch for:

- **The findings invalidate the team's plan.** This is the *point*. The cheaper to learn it now, the better. Communicate it carefully — see [communicating-findings.md](communicating-findings.md).
- **Multiple unrelated problems surface.** You went looking for one; found three. Pick the most important (use opportunity sizing) and explicitly defer the others.
- **The "users don't actually have this problem" finding.** Honest but unwelcome. Frame it as opportunity-cost: "you can spend the next quarter on this, where users don't seem to need it, or on these other things they do."
- **The problem turns out to be a process problem, not a product problem.** Common in B2B and enterprise. The product won't fix what's actually a workflow or org issue. Be honest about it.
- **The participants disagree wildly.** This usually means you've crossed two segments. Re-examine recruitment criteria; consider whether you're really studying one user type.

## Anti-Patterns

- **Solution-first framing.** "We need to research the chatbot." (No, you need to research the *problem* the chatbot might solve.)
- **Asking users what they want.** Users are bad at predicting their own behavior; ask them about what they *do*, not what they want.
- **Demographics as the main lens.** "What do millennials want?" Demographics rarely predict behavior as well as situation does. JTBD over personas for generative work.
- **Hypotheticals.** "If we built X, would you use it?" Polite agreement that doesn't predict behavior. Ask about the *last time* a similar real situation happened.
- **Discovery as a deliverable.** A 40-page report nobody reads. Discovery is for changing decisions; if it doesn't, it didn't happen.
- **Skipping the problem statement.** Going from interviews directly to wireframes. The team doesn't share a model of what they're solving; they argue about solutions instead.
- **Scope that's too big.** "Let's do a discovery on our entire product." Six months of interviews; nothing actionable. Narrow to a single, specific area.
- **Treating discovery as one-and-done.** Then never updating the understanding as the market changes. Continuous discovery is more robust.
- **No "what we're not doing."** The team takes the discovery as license to solve everything found in it; scope explodes; nothing ships.

## Related

- [research-methods.md](research-methods.md) — picking the right method for the discovery question
- [interview-craft.md](interview-craft.md) — how to actually run a JTBD or discovery interview
- [synthesis-and-insights.md](synthesis-and-insights.md) — turning interview transcripts into a problem statement
- [personas-and-jtbd.md](personas-and-jtbd.md) — packaging discovery output as JTBD statements
- [communicating-findings.md](communicating-findings.md) — getting the problem statement to land with the team
