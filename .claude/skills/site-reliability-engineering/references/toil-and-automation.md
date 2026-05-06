# Toil and Automation

Toil is the operational work that consumes engineering time without producing lasting value. Left unmanaged, it grows until the team has no time for anything else; it's the slow tax that turns a high-velocity team into a maintenance team.

The most important thing about toil is that it must be **measured and capped**, not "felt." A team that handles toil "as it comes up" eventually does nothing else.

## The Definition (Google SRE)

Toil is operational work that has *all* of the following characteristics:

- **Manual** — a human is doing it.
- **Repetitive** — the same shape, again and again.
- **Automatable** — a script or tool could do it instead.
- **Tactical** — driven by an interrupt, not by a plan.
- **No enduring value** — when it's done, the system is exactly where it was.
- **Scales linearly with the system** — twice as much system, twice as much toil.

This definition is precise on purpose. Things that are merely *annoying* are not toil; things that *seem* automatable but only run once a year are not toil; things that produce value (refactoring, design work) are not toil even if they're repetitive within themselves.

### Examples of toil

- Manually approving routine deploys.
- Running a database snapshot before every release because the script is broken.
- Restarting a stuck worker every few days.
- Rotating expired certificates by hand.
- Resizing a disk that fills up predictably every two weeks.
- Acking the same noisy alert over and over and silencing it for 4 hours.
- Manually adding a user to a group when they join a team.
- Triaging incoming bug tickets and routing them to teams.
- Walking through a 12-step checklist for a "release" that should be a button.

### Examples that are *not* toil

- **Postmortems.** Repetitive, but produce enduring value (lessons, action items).
- **On-call response to novel incidents.** Tactical and manual, but each one is a different problem.
- **Code review.** Repetitive in cadence, but the value is the catch.
- **Refactoring.** Manual and repetitive *within* the refactor, but the result is permanent.
- **Design discussions.** Manual but produce decisions, not just state changes.
- **Painful manual things you do twice a year.** Annoying, but the automation cost almost certainly exceeds the toil cost.

If you're unsure: ask "if I never do this task again, is the system in a worse state?" If yes, it's not toil. If no, it is.

## Why Toil Is Dangerous

Three reasons toil is more harmful than it looks:

1. **It crowds out engineering work.** Every hour spent on toil is an hour not spent building reliability, paying down debt, or shipping features. The team's capacity to *improve* the system shrinks.
2. **It scales with the system.** Most toil grows linearly (or worse) with the size of the deployment. As the system grows, toil becomes the dominant load on the team.
3. **It produces burnout and attrition.** Engineers signed up to build, not to babysit. A team that becomes a toil farm will lose its best people first — they have other options.

The team you don't notice is being overwhelmed by toil today is the team that loses three engineers in six months and you can't figure out why.

## The 50% Rule

> **No SRE should spend more than 50% of their time on toil over a quarter.**

This is the Google SRE workbook's rule, and it's a useful default. Two reasons:

1. **The remaining 50% goes to engineering work that reduces toil.** Without that investment, toil only ever grows.
2. **It's a forcing function.** When the cap is breached, the *team* has to push back — declare bankruptcy, escalate to leadership, drop projects, or ship the automation. Without a cap, the conversation never happens.

The 50% number is not magic; some teams target 30%, some allow 60% temporarily during a launch. What matters is that **a number exists, it is measured, and it triggers action when breached.**

## Measuring Toil

Two things that work:

### 1. Self-reporting

At the end of every on-call shift, the on-call estimates how many hours of the shift were toil. Logged in a shared spreadsheet or dashboard.

This is approximate but honest, and the trend is what matters more than the precise number. A shift that consistently reports 80% toil is a problem regardless of whether the real number is 75% or 85%.

### 2. Categorize incoming work

Tag every ticket as `toil`, `engineering`, or `incident-response`. Run a monthly report. Watch the ratio.

This is harder to game and gives you a per-team metric the team lead can present to leadership.

## The Automation Backlog

Toil that has been identified but not yet eliminated lives on the **automation backlog**. This is a real backlog with real prioritization, not a wish list.

Each item has:

- **What's being toiled on** (in concrete terms).
- **How often it occurs** (and how much time per occurrence).
- **Estimated cost** to automate.
- **Estimated saving** per quarter, in engineer-hours.
- **Owner** for the automation work.

A worked example:

| Toil | Frequency | Cost / occurrence | Quarterly cost | Cost to automate | Owner |
|---|---|---|---|---|---|
| Restart stuck `email-worker` pods | ~2x/week | 15 min | ~6h | ~2 days | Glenn |
| Rotate vendor API keys | quarterly | 4h | 4h | ~1 week | Alex |
| Triage incoming `bug` tickets | ~10/day | 3 min | ~32h | ~1 week (auto-routing) | Sam |
| Manually add new joiners to engineering groups | ~1/week | 20 min | ~4h | ~3 days | Infra |

The "quarterly cost" column is sortable. **Automate the highest-cost item first**, regardless of how interesting it is.

## What Counts as "Automated"

Three levels of automation, each better than the last:

1. **Scripted.** A human runs a script when needed. Cuts the time and reduces error, but still requires a human to notice the trigger.
2. **Triggered.** The script runs automatically in response to an event (cron, alert, deploy hook). Human only intervenes for exceptions.
3. **Self-healing.** The system detects and corrects the condition without producing any work for a human at all.

Aim for the highest level the toil justifies. Stuck-pod restarts that happen weekly should be self-healing (Kubernetes liveness probes). Quarterly key rotations might just be triggered. One-off cleanups might just be scripted.

The cost ratio matters: **don't spend a week automating something that costs an hour a year**. The 50% rule is about *aggregate* time, not about every individual task.

## "Automate the Second Time, Not the First"

A useful heuristic: the first time you do a manual operation, **document it in a runbook**. The second time, you have evidence it's recurring, and the runbook becomes the spec for the script. The third time, the script should already exist.

This protects against premature automation:

- Things you do once never recur and never need automation.
- Things you do twice are clearly recurring and worth the investment.
- The runbook captures the *steps*, which is the hardest part of writing the script.

## Toil-Reduction Sprints

When a team is over the 50% cap, the right response is not "we'll fix it as we go." That fails because there's no time *between* the toil to fix the toil. The right response is a **dedicated reliability sprint**:

- 1–2 weeks where the team **commits to no new feature work**.
- The full team works through the top items on the automation backlog.
- The metric is "next quarter's toil percentage," not "tickets closed."

Reliability sprints are unpopular with stakeholders. The error budget policy is what justifies them — see [slis-slos-error-budgets.md](slis-slos-error-budgets.md#error-budget-policy). When the budget is exhausted, the next sprint is reliability work; that's the agreement.

## Toil From Other People's Code

Some toil is generated by other teams' work: a service that crashes weekly because of a bug nobody owns, an upstream API that requires manual reconciliation because it doesn't expose the right query, a deploy script that needs babysitting.

The right response is *not* to absorb the toil silently. It's to:

1. **Surface it.** The team that generates the toil should see the cost. Quantify and report.
2. **Push the work back.** "This is taking 6 hours/week from our team; here's what we'd need from yours to fix it." File the ticket on *their* backlog, not yours.
3. **Build temporary mitigations** that make the toil manageable until the upstream fix lands — but make it visibly temporary so nobody mistakes it for a permanent solution.

If the upstream team won't or can't fix it, escalate. Toil that's permanently absorbed is a management problem, not an engineering one.

## Anti-Patterns

- **"Toil isn't real work."** It is real work. It's just not the work you should be doing.
- **No measurement.** "We feel like there's a lot of toil." You don't know until you measure. Sometimes the team's stress is from a different cause; sometimes the toil is much worse than they think.
- **Hero toil-handling.** One engineer absorbs all the toil because they're the only one who knows how. They burn out, leave, and now nobody can do it. Spread it deliberately.
- **The unending automation project.** "We're going to rewrite the deploy system to eliminate this toil." Six months later, no progress, and the manual process keeps running. Bias toward small automations that ship quickly.
- **Automating before understanding.** Writing a script to automate a process you've never done by hand. The script encodes assumptions that turn out to be wrong; the toil reappears as debugging the script.
- **Premature automation of one-offs.** Investing a week to automate something that runs once a quarter. The 50% rule is aggregate.
- **Treating on-call as the toil-handling shift.** On-call is for *responding to incidents*, not for clearing the toil queue. They're related but not the same; conflating them means the on-call ships nothing and incidents don't get the attention they deserve.
- **Hiding the toil from leadership.** If the people deciding budget and headcount don't see the toil percentage, they don't fund the work to reduce it.
- **No automation backlog.** Toil identified, no plan to fix. Identification without action is just complaining.
- **Reliability sprints that get hijacked.** The dedicated sprint becomes a "well, we have a customer-promised feature, can you slip just this one in?" The whole sprint then evaporates. Treat the boundary as inviolable.

## Related

- [on-call.md](on-call.md) — high toil on-call rotations are unsustainable
- [postmortems.md](postmortems.md) — recurring incidents are toil; postmortem action items eliminate them
- [runbooks.md](runbooks.md) — documented step → script → triggered automation
- [slis-slos-error-budgets.md](slis-slos-error-budgets.md) — error budget exhaustion justifies reliability sprints
- [software-design](../../software-design/SKILL.md) — chronically high-toil services are usually a design smell; the runbook is treating a symptom of bad code
- [team-lead](../../team-lead/SKILL.md) — toil reduction work fits naturally into the team's planning cadence
