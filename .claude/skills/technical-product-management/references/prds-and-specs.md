# PRDs and Specs

A PRD (Product Requirements Document) is the bridge between "we've decided to build this" and "the team is building it." Done well, it aligns the team on what they're building and why, surfaces open questions before they become rework, and serves as a reference when memory fades. Done badly, it's a 30-page document nobody reads that tries to be a contract and ends up being neither informative nor enforceable.

The most important thing to internalize about PRDs: **they answer "what and why," not "how."** The how is engineering's job. A PRD that specifies the implementation has taken something away from the team that the team should own.

## What a PRD Is For

A PRD has three audiences and serves three purposes:

1. **For the team building it** — a shared understanding of what we're solving, who for, and what done looks like.
2. **For stakeholders adjacent to it** — design, research, support, sales, legal, marketing — a reference they can read to know what to expect and to flag concerns.
3. **For the future team members** who weren't there when it was decided — context for why this was built and what was rejected along the way.

A PRD serves *none* of these audiences if it's too long to read, too vague to inform decisions, or too prescriptive to leave room for engineering's judgment. The discipline is to keep it short, specific, and *what/why-shaped*.

## What a PRD Is NOT For

- **A contract.** A PRD is a reference, not a binding agreement. The team will discover things during build that change the plan; the PRD updates accordingly.
- **A specification of the implementation.** The how is engineering's job. The PRD says "users should be able to upload files up to 100MB"; engineering decides whether that means S3, multipart upload, chunked transfer, presigned URLs, etc.
- **A marketing document.** The audience is the building team, not the public.
- **A status report.** A PRD isn't updated weekly with progress; it's updated when the *plan* changes.
- **A justification document.** The PRD doesn't have to defend itself against every possible criticism. It states the decision; rationale lives in the strategy and prioritization that produced it.

## The One-Pager Format

The most useful PRD format for most product work is **one to three pages**, structured as follows:

### 1. Title and one-line summary

> "Reduce time-to-first-value for new teams from 14 days to under 7 days by building a guided onboarding flow with templates and a default first project."

One sentence the rest of the team can remember and repeat.

### 2. The Problem

> One paragraph. What's the user pain? What's the evidence it's real?

Example:

> Our analytics show that 60% of new teams who sign up never complete their first project; the median time-to-first-project is 14 days. Interviews with 8 lapsed users in Q3 indicated that the setup work in the first few sessions felt like overhead and they "ran out of energy" before getting to the value. This problem is the largest contributor to our 90-day churn rate.

Notice: this paragraph **states the problem and cites the evidence**. A PRD without evidence is a guess.

### 3. The Users

> Who exactly has this problem? Reference personas or JTBD if you have them. Be specific about the segment.

Example:

> The primary user is the team admin in a 5-20 person B2B team using our product for the first time, typically a project coordinator or operations lead. They are time-constrained, evaluating multiple tools at once, and have low tolerance for ambiguous setup work. (See the "Maria" persona in research/personas.)

### 4. The Goal / Success Metric

> What does done look like? Concrete, observable, ideally measurable. The metric you'll watch to know if the bet paid off.

Example:

> Median time-to-first-project for new teams drops from 14 days to under 7 days within 60 days of launch. 30-day retention for teams who completed first project increases by at least 5 percentage points. Counter-metric: trial-to-paid conversion does not decrease.

Notice: a *primary metric*, a *time horizon*, and a *counter-metric*. The counter-metric prevents the team from gaming the primary one.

### 5. The Approach (high level)

> The general direction the team is taking, *not* the implementation. One paragraph.

Example:

> We will introduce a guided onboarding flow that walks new teams through a meaningful first project using their actual data, plus a templates library so they can start from working examples instead of a blank canvas. The flow is interactive, contextual, and skippable for power users.

Notice: it says *what the team will build* in user-visible terms, not *how it will be built*. No mention of which framework, which database, which animation library.

### 6. Non-Goals

> What we are explicitly NOT doing. The most important section of the PRD.

Example:

> - We are *not* building per-segment custom flows. The same flow serves all team types.
> - We are *not* shipping advanced configuration during onboarding; that comes later.
> - We are *not* building admin dashboards for monitoring onboarding completion (separate workstream).
> - We are *not* localizing for non-English users in this release.

This section saves more arguments than any other. Future stakeholders will ask "did you consider X?" — and you can point at the non-goal: "yes, and we explicitly chose not to."

### 7. Open Questions

> Things we don't yet know that the build process needs to answer or resolve.

Example:

> - Should the flow use real user data or sample data? (Lean toward real; engineering to confirm feasibility.)
> - What happens if a user closes the flow halfway through? Resume on next login? (Resume.)
> - How do we handle teams with non-standard account structures? (TBD; ~5% of new teams.)

Open questions don't block the PRD; they're flagged as work the team will resolve as it goes.

### 8. Acceptance Criteria (or "Definition of Done")

> Concrete, testable criteria for "this is done." Brief; should fit in a few bullets.

Example:

> - New team users see the guided flow on first login.
> - The flow walks them through creating one real project with at least 3 items.
> - At least 5 templates are available, covering the most common use cases.
> - Existing users see no change.
> - Performance: flow loads within 1.5s on a 3G connection.
> - Accessibility: flow is keyboard-navigable and meets WCAG 2.2 AA.

Acceptance criteria are *user-visible* and *testable*. They don't specify the implementation; they specify the outcome.

### 9. Dependencies and Risks

> What this work depends on and what could go wrong.

Example:

> - **Dependency:** the new templates require the templates infrastructure, which is being built in parallel by the platform team. Slip risk: medium.
> - **Risk:** if the flow feels "in the way" rather than helpful, completion rate could *drop*. Mitigation: usability test the flow before launch.
> - **Risk:** real-data templates expose us to bad data states (e.g. team has only 1 user). Mitigation: scoped recovery for edge cases.

### 10. Timeline (loose)

> When the team expects to ship, with confidence level.

Example:

> Aim to ship to internal beta by end of Q2; public launch within 4 weeks of internal beta if metrics look healthy. Confidence: medium — depends on the templates dependency.

Don't fake precision. "End of Q2" is honest; "May 18" is theater.

---

That's it. **One to three pages**, all of the above included, none of the implementation specified. A PRD this size is *read*, which is the entire point.

## The "Spec as Contract" Anti-Pattern

The most common PRD failure mode: the PRD becomes a contract that the team defends instead of a reference that they update.

Symptoms:

- Engineering pushes back on a change because "that's not in the spec."
- The PM resists changing the spec because "we already aligned on it."
- The spec is treated as the source of truth even when reality has moved past it.
- Stakeholders point at the spec to claim the team is "behind" when actually the spec is wrong.
- The spec is referenced in performance reviews ("the team didn't deliver what was specced").

When this happens, the team has confused the *purpose* of the PRD. It exists to serve the work, not to bind it. The PRD updates as the team learns; it does not become a stick to beat the team with.

The fix is cultural and contractual. Cultural: the team treats the PRD as a living document, updated regularly, with the most recent version always being the truth. Contractual: leadership evaluates the team on outcomes (did the work hit the goal?), not on plan-faithfulness (did the team build exactly what they said they would?).

If your organization can't make this shift, you'll always have feature-factory PMs and demoralized engineers. The PRD is downstream of the cultural choice; the cultural choice is the real lever.

## When NOT to Write a PRD

Not every piece of work needs a PRD. The cost of a PRD is real (writing it, reviewing it, maintaining it), and for small work the cost exceeds the benefit.

| Work shape | PRD effort |
|---|---|
| Bug fix | None |
| Small UI tweak | None or a one-paragraph ticket description |
| Routine improvement | Ticket-level description; no PRD |
| Self-contained feature (one team, ~weeks of work) | One-pager PRD |
| Multi-team feature | Full PRD |
| New product or major initiative | Full PRD + design doc + RFC |
| Platform / infrastructure work | Engineering RFC, not a PRD (system-architect skill) |

A PRD for a bug fix is overhead. A bug fix for a multi-team feature is a recipe for misalignment. Match the artifact to the size of the decision.

## Writing a PRD Well

Some practical tips:

### Start with the user, not the solution

A PRD that opens with "we will build X" has skipped the most important step. Open with the *user* and the *problem*; the solution should feel inevitable by the time you get to it. If it doesn't, you don't yet have a PRD — you have a feature pitch.

### Cite evidence

Every claim about user pain should be linked to a source: a research study, a support ticket count, an analytics report, an interview transcript. A PRD without citations is a guess, and the team will treat it as one.

### Use plain language

A PRD full of jargon, acronyms, and consultant-speak is harder to read and hides imprecision. Plain language forces clarity.

### Show the metric early and often

The success metric belongs near the top, not buried in section 9. The team should be reminded constantly of what success looks like.

### Specify non-goals

The most underused section in PRDs. Spend real time here. Every non-goal you state up front is an argument you don't have to have later.

### Leave room for engineering judgment

The PRD says *what* and *why*. Engineering will figure out *how*, often better than you would. Don't undermine that by over-specifying.

### Get review before finalization

Send the draft to engineering, design, and adjacent stakeholders before locking it. They will spot omissions, wrong assumptions, and impossible asks. Better to find out at the PRD stage than during build.

### Update it when reality moves

A PRD that's never updated is decoration. When discovery surfaces a new constraint, when engineering finds a faster path, when the team realizes the original plan was wrong — update the PRD. Mark what changed.

### Link, don't duplicate

Link to the strategy doc, the research findings, the design files, the related ADRs. Don't try to inline everything. The PRD is a hub, not an encyclopedia.

## User Stories and Acceptance Criteria

Many teams use user stories and acceptance criteria *inside* tickets, even when they don't use them in the PRD itself. The conventions:

### User story format

> As a `<user>`, I want to `<action>`, so that `<outcome>`.

Example:

> As a team admin, I want to invite my teammates with an email link, so that they can join the project without me sharing my password.

What this format does well:

- **Forces user-centeredness.** You can't write a story without naming a user.
- **Forces purpose.** The "so that" clause tells you why this story matters.
- **Discourages technical detail.** "As a developer, I want a service that exposes a REST endpoint" is a smell — that's not a user story; it's a tech task.

### Acceptance criteria

The specific, testable conditions for "this story is done." Each criterion is observable and unambiguous.

Common formats:

- **Bullet list:** simple "this works" criteria.
- **Given / When / Then** (BDD format): "Given I am a logged-in admin, When I click 'Invite teammate', Then I see a form to enter their email address."
- **Checklist:** for stories with many conditions.

The best format is whichever the team can write and read consistently. Don't argue about format; argue about *whether the criteria are clear and testable*.

### Common acceptance criteria failures

- **"It works."** Not testable.
- **"It's good." / "It feels right."** Subjective; will be argued forever.
- **Technical implementation criteria.** "Uses the new API endpoint." That's not user-visible; it's a tech detail.
- **Missing edge cases.** Only the happy path; the unhappy paths get bolted on under deadline pressure.
- **Criteria that contradict each other.** "Loads instantly" + "shows complete data including 10k items." Pick one.

A useful test: read the criteria to a stranger. Can they tell *exactly* what would constitute success? If not, the criteria are too vague.

## Spec for a Large Initiative

When the work is larger than a one-pager can capture, the right artifact is usually a *combination*:

- **PRD** (one-pager) — the product framing: problem, users, goal, non-goals.
- **Design doc** (engineering, owned by [system-architect](../../system-architect/SKILL.md)) — the technical approach.
- **Design / UX spec** (owned by [ux-design](../../ux-design/SKILL.md)) — the interface and interaction.
- **Research findings** (owned by [ux-research](../../ux-research/SKILL.md)) — the evidence the PRD cites.

The PM coordinates these so they're consistent and align with each other. The PM does *not* write all of them; the right discipline owns each. Confusing the PRD with the design doc is the most common failure here — the PM tries to write the engineering details, gets them wrong, and frustrates engineering.

For a multi-team initiative, you may also want:

- **A high-level PRD** (the problem and goal at the program level).
- **One PRD per workstream** (each team's slice).
- **A coordination doc** (sequencing, dependencies, who owns what).

This is where a TPM earns the "T": coordinating multiple teams and multiple documents into a coherent program of work.

## Anti-Patterns

- **The 30-page PRD.** Nobody reads it; details rot; the team works from a different mental model than the document.
- **Implementation in the PRD.** PM specifies the database schema, the API shape, the framework choice. Engineering is angry; the design is worse.
- **No success metric.** The team can ship the feature and never know if it worked.
- **No non-goals.** Stakeholders treat anything not explicitly excluded as "in scope." Scope creep follows.
- **No evidence.** The PRD asserts user pain without citing the research that found it.
- **Marketing language.** "Delight users with a seamless experience." Means nothing.
- **PRD as contract.** The team can't change the plan without a fight; reality moves; the document goes stale.
- **PRD as status update.** The PM updates it weekly with progress; it becomes noise.
- **PRD by committee.** Every stakeholder edits it; the document becomes incoherent.
- **PRD for a bug fix.** Overhead exceeds benefit.
- **No PRD for a multi-team initiative.** Teams build different things; integration is a nightmare.
- **PRD that ignores constraints.** "The team will ship X by Q3 with no caveats." Engineering didn't agree; design didn't agree; reality won't cooperate.
- **PRD that nobody read before sign-off.** Stakeholders rubber-stamp, then complain post-launch. Force review before the build starts.
- **PRD that lives in a dead drive.** Never linked from anywhere; nobody can find it. Put it where the team works.

## Related

- [product-strategy.md](product-strategy.md) — strategy informs which PRDs get written
- [prioritization.md](prioritization.md) — prioritization decides which PRDs become the next thing
- [discovery-to-delivery.md](discovery-to-delivery.md) — discovery feeds the PRD's evidence section
- [working-with-engineering.md](working-with-engineering.md) — engineering reviews the PRD before commitment
- [system-architect](../../system-architect/SKILL.md) — the design doc is the engineering counterpart to the PRD
- [ux-design](../../ux-design/SKILL.md) — design specs are the design counterpart to the PRD
- [ux-research](../../ux-research/SKILL.md) — research provides the evidence the PRD cites
- [team-lead](../../team-lead/SKILL.md) — PRD content becomes tickets in the team's backlog
- [assets/prd-template.md](../assets/prd-template.md) — fillable one-page PRD template
