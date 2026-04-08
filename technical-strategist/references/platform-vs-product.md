# Platform vs Product

One of the most consequential calls a technical strategist makes: **when do you invest in shared platform infrastructure, and when do you let each product team solve its own problems?**

The platform argument is intuitive: extract common needs into a shared layer; let teams build on it; multiply velocity. The opposite argument is also intuitive: every platform team is a tax on the product teams; don't add overhead unless it pays back. Both arguments are real. The wrong call wastes years of engineering capacity.

This file is about making the call honestly.

## What "Platform" Means Here

A *platform* is a piece of internal infrastructure that multiple teams or products share. Examples:

- An internal CI/CD system used by all teams
- A shared design system used by all frontend teams
- A common observability stack
- An identity/auth service used by every product
- A shared event bus
- A feature flag system
- An internal developer portal
- A shared database access layer
- A common testing framework

Platforms are usually built and maintained by a **platform team** whose customers are *other engineering teams*, not end users.

Platforms are *not* the same as common libraries (libraries are imported and don't have a maintaining team). Platforms are *not* the same as architecture (architecture is the structure; the platform is the running system). Platforms have a team, a roadmap, and customers — like a product, but the customers are internal.

## When Platform Investment Pays Off

A platform investment pays off when **all** of the following are true:

1. **Multiple teams have the same problem.** Not "could have"; *do have*. Look at the actual work happening across teams; if three or more are independently solving the same thing, there's a real platform opportunity.
2. **The problem is hard enough that solving it once is much cheaper than solving it many times.** A 5-line utility doesn't need a platform. A complex system (auth, billing, observability) does.
3. **The teams will actually use the platform.** Building a platform that no one adopts is the most common platform failure.
4. **The platform team has enough capacity** to maintain and evolve the platform without becoming a bottleneck for the product teams.
5. **The investment horizon is long enough** to justify the up-front cost. Platforms pay back over years, not months.

When all these are true, a platform investment is one of the highest-leverage things a strategist can do. A good platform multiplies velocity for every team that uses it.

## When Platform Investment Doesn't Pay Off

A platform is the wrong investment when **any** of the following is true:

1. **Only one team has the problem.** "Pre-solving" a problem that doesn't yet exist for other teams is speculative work. Wait until the problem actually appears in three places.
2. **The platform team has different incentives from the product teams.** If the platform team is rewarded for shipping platform features and the product teams are rewarded for shipping product features, the platform team will build things the product teams don't want.
3. **The platform can't keep up with product teams' needs.** A platform that's always one quarter behind what the product teams need is worse than no platform — the product teams have to work around it.
4. **The platform forces uniformity that doesn't fit.** A shared design system that doesn't accommodate the legitimate differences between products is a platform that the product teams will work around.
5. **The total cost of the platform** (build + maintain + slow product teams down + onboarding) exceeds the savings from sharing.

When any of these is true, the platform is a tax. Don't build it; let teams solve their own problems.

## The Platform-Team Trap

The most common failure: building a platform team that becomes a bottleneck instead of a multiplier.

The pattern:

1. The strategist sees that several teams are doing similar work.
2. They form a platform team to extract the common work.
3. The platform team starts building the platform.
4. Product teams need things from the platform.
5. The platform team prioritizes its own roadmap (ergonomics, features, internal cleanup) over the product teams' urgent needs.
6. Product teams build workarounds because they can't wait.
7. Workarounds calcify into "shadow platforms."
8. The platform now exists *plus* the workarounds the product teams built; the cost is the sum of both.

The trap is that the platform team feels productive — they're shipping platform features — but the product teams are *less* productive than before. Net effect: negative.

The cure: **the platform team's success metric is the product teams' velocity**, not the platform team's own output. If product teams aren't visibly faster, the platform isn't working.

This requires:

- **Platform team treats product teams as customers**. Listens to them; prioritizes their needs; measures their satisfaction.
- **Platform team has explicit SLAs** for responding to product team needs.
- **Product teams have an escape hatch**: if the platform doesn't fit, they can solve the problem themselves *temporarily* without being blamed, and the platform team treats it as a signal.
- **Platform team is small**. A 12-person platform team is a problem; a 3-person platform team that knows what to focus on is an asset.

## When to Build a Platform Team

Build a platform team when:

- **At least 3 product teams have the same problem.** Two is a coincidence; three is a pattern.
- **The problem is well-understood.** Trying to extract a platform from a problem nobody understands yet is premature.
- **You can name the customers and what they need.** "We will build for these specific teams, who need these specific things, by this date."
- **You can fund the team for at least 18 months.** A platform team that gets cut after a year leaves the workarounds in place and produces no benefit.
- **The leadership of the team has experience with platform work.** Platform work is different from product work; running a platform team requires specific skills.

When *not* to build a platform team:

- **It's too early.** The patterns aren't clear yet. Let the teams solve it themselves; extract later when the right shape is obvious.
- **The current solution works.** "This could be cleaner" isn't a reason to build a platform.
- **You can't commit the resources.** A half-funded platform team is worse than none.
- **The product teams don't want it.** A platform imposed on resistant teams gets bypassed.

## Internal Tools vs External Products

A subtle distinction: a *platform* can sometimes evolve into an *external product*. A team building internal observability tooling might decide to spin it out as a product (this is the origin of many famous open-source and SaaS tools). 

Most internal platforms should *not* try to become external products. Internal customers are different from external customers; the requirements diverge; supporting both is hard. The platform team that tries to do both usually does both badly.

A better pattern: **run the internal platform as if it were a product** (with users, SLAs, roadmap, support) but don't try to externalize it. The internal users get the focus they need; the strategist doesn't waste energy on commercial concerns.

If a platform genuinely has external value, spin it out as a separate product team with separate funding and separate goals. Don't try to do both with the same people.

## The "Build for Yourself First" Pattern

A useful platform-building pattern: **the platform team is its own first customer**.

Before extracting a platform for shared use, the team building it should use it for their own work. This forces the team to feel the rough edges and fix them before exposing the platform to others.

This is sometimes called "eat your own dog food" — the platform team uses what they ship.

Platforms built this way are usually much better than platforms built for "abstract users we'll have someday." The team that builds for itself first builds for real needs and real friction; the team that builds for hypothetical future users builds for what they imagine those users will want.

## Adoption Strategy

A platform without adoption is wasted effort. The hardest part of platform work isn't building the platform; it's getting teams to use it.

Adoption strategies, in rough order of effectiveness:

### 1. The platform is obviously better than the alternative

If using the platform is *clearly* easier, faster, and cheaper than not using it, teams adopt without prompting. This is the gold standard. It requires the platform to be genuinely good.

### 2. The platform solves a problem the team is actively struggling with

If the team is in pain *right now*, they'll adopt anything that helps. Time the platform's release to land when teams need it.

### 3. The platform is mandatory for new work, optional for old

This is a gentle push: new code must use the platform; existing code is grandfathered. Over time, the new platform displaces the old approach naturally.

### 4. Migration assistance

The platform team helps the product team migrate. Pair programming, dedicated migration sprints, prebuilt migration tools. This is expensive but works.

### 5. Mandates from above

Leadership says "everyone must use the platform." This *can* work but is brittle: if the platform isn't actually good, the mandate is resented and worked around.

The wrong adoption strategy: **building it and hoping**. "If we build it, they will come." They won't. Adoption takes deliberate effort.

## Multi-Tenant and Per-Tenant

A subtle platform decision: **does the platform serve all tenants the same way, or does it specialize per-tenant?**

- **Multi-tenant**: one platform, all teams use it identically. Cheaper to maintain; less flexible.
- **Per-tenant**: the platform supports per-team customization. More flexible; more expensive.

For many platforms, **multi-tenant first, with per-tenant escape hatches** is the right pattern. Most teams use the standard configuration; teams with unusual needs get an escape hatch (a config flag, a custom integration point, an opt-out).

The wrong pattern: trying to satisfy every team's specific needs in the platform itself. The platform becomes complex and hard to maintain; the team that asked for the customization is happy; the other teams pay the maintenance cost forever.

## Documentation and Discoverability

A platform that nobody can figure out how to use is a platform that doesn't exist. Documentation is a first-class platform feature, not an afterthought.

What good platform documentation looks like:

- **Quickstart**: a 5-minute "hello world" that shows the platform working.
- **Common patterns**: how to do the most common things, with copy-pasteable examples.
- **Reference**: comprehensive details for the rest.
- **Migration guides**: how to move from common alternatives to this platform.
- **Troubleshooting**: what to do when it breaks.
- **Roadmap**: what's coming next; what's deprecated.
- **Support channel**: how to get help when stuck.

Platform teams that under-invest in documentation produce platforms that no one adopts.

## Sunsetting a Platform

Sometimes a platform doesn't pay off. The team adopted it; it's not actually multiplying velocity; the cost exceeds the benefit.

What to do:

1. **Acknowledge the failure honestly.** Don't spin it as a success.
2. **Decide what to do**: continue with major changes, sunset the platform and let teams solve their own problems, or replace with a different approach.
3. **Communicate the decision** clearly to all affected teams.
4. **Provide a migration path** for existing users. Sunsetting without a path leaves teams stranded.
5. **Postmortem**: what would we do differently next time?

Sunsetting is hard but it's better than running a failed platform forever. Sunk cost is real; it's not a reason to keep going.

## Anti-Patterns

- **Premature platform**. Built before the patterns were clear; doesn't fit anyone's needs.
- **Over-broad platform**. Tries to solve every team's problem; satisfies none well.
- **Platform team disconnected from users**. Builds what they imagine teams want, not what teams actually need.
- **Platform that's always behind product needs**. Becomes a tax instead of a multiplier.
- **Platform that mandates uniformity** where legitimate differences exist.
- **Platform without an exit hatch**. Teams that don't fit have no recourse.
- **Platform without documentation**. Nobody can adopt it.
- **Platform without explicit customers**. "We're building this for everyone" → built for no one.
- **Platform that competes with vendor solutions**. NIH syndrome at the platform level.
- **Platform that's also trying to be an external product**. Splits focus.
- **Mandated adoption without quality**. Teams resent the mandate and work around the platform.
- **Half-funded platform team**. Can't keep up; teams build workarounds; platform produces negative value.
- **Platform measured by its own output** rather than by product team velocity.
- **No sunset path**. Failed platforms run forever, consuming engineering capacity.
- **Platform that tries to solve a different team's problem** to justify its existence.
- **Platform that the platform team itself doesn't use**. Dog food matters.

## Related

- [tech-bets-and-investments.md](tech-bets-and-investments.md) — platform investments are major bets
- [build-vs-buy-vs-adopt.md](build-vs-buy-vs-adopt.md) — the platform itself can be built, bought, or adopted
- [strategy-as-constraint.md](strategy-as-constraint.md) — platform decisions constrain product teams
- [system-architect](../../system-architect/SKILL.md) — designs the platform's technical shape
- [team-lead](../../team-lead/SKILL.md) — captures platform decisions as ADRs
- [technical-product-management](../../technical-product-management/SKILL.md) — TPM principles apply to platform teams (their customers are other teams)
- [site-reliability-engineering](../../site-reliability-engineering/SKILL.md) — platforms need operational discipline like products
