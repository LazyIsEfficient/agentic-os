# Build vs Buy vs Adopt

The single most consequential class of decisions a technical strategist makes: for any non-trivial capability your team needs, do you **build** it in-house, **buy** a commercial vendor, or **adopt** an open-source solution? Each has different costs, different risks, and different long-term implications.

The wrong default is "build it ourselves" — it's the most flattering option for an engineering team but usually the most expensive over time. The other wrong default is "buy everything" — it's the path of least resistance but creates lock-in, ongoing cost, and a product made of glued-together vendors.

This file is about making the call deliberately.

## The Three Options Defined

### Build

**Write the capability in-house, owned and maintained by your team.**

- **Up-front cost**: high (engineering time to design, build, test).
- **Ongoing cost**: medium-to-high (maintenance, bug fixes, evolution).
- **Time to value**: longest.
- **Control**: total. You can change anything.
- **Lock-in**: zero. It's your code.
- **Differentiation**: maximum, if the capability is core to your product.

### Buy

**Pay a commercial vendor for a hosted, managed, or licensed product.**

- **Up-front cost**: low (just the integration).
- **Ongoing cost**: subscription or licensing fees, often growing with usage.
- **Time to value**: shortest.
- **Control**: limited. The vendor controls the roadmap.
- **Lock-in**: high. Switching costs grow over time.
- **Differentiation**: minimal. Your competitors can buy the same thing.

### Adopt

**Use an open-source project, possibly self-hosted or possibly via a managed cloud offering.**

- **Up-front cost**: low (initial integration) but with hidden costs (operational, learning).
- **Ongoing cost**: operational (running it) plus possibly contributing back.
- **Time to value**: short to medium.
- **Control**: medium. You can fork or contribute, but the project has its own roadmap.
- **Lock-in**: medium. The project itself can change direction or die.
- **Differentiation**: little (others can adopt the same thing).

## When to Build

Build when **all** of the following are true:

1. **The capability is strategically central** to what makes your product different. If a competitor with the same vendor stack would be the same product, don't build. If building gives you a meaningful edge, build.
2. **You can sustain the maintenance** indefinitely. Every line of code you write is code you'll maintain forever. If you can't commit to maintaining it, don't build.
3. **The off-the-shelf options don't fit.** Carefully evaluate buy and adopt options first. Most "we need to build this" arguments dissolve under careful evaluation.
4. **You have engineering capacity** to do it well. Building badly is worse than not building.

Examples where build is usually right:

- The core algorithm of your product (the search ranking, the recommendation engine, the matching algorithm).
- The proprietary data model that competitors can't replicate.
- The user-facing interface where polish matters.
- A capability where vendor lock-in would be existential.

Examples where build is usually wrong:

- Authentication and identity (use Auth0, Cognito, Clerk, Supabase Auth, etc.).
- Payment processing (Stripe, Adyen, etc.).
- Email delivery (SendGrid, Postmark, etc.).
- Analytics (PostHog, Mixpanel, Segment, etc.).
- Logging and metrics infrastructure (Datadog, Grafana Cloud, New Relic, etc.).
- Standard databases (use Postgres or your cloud's managed equivalent).

The pattern: **build the things that are uniquely yours; don't build the things every product has.**

## When to Buy

Buy when **all** of the following are true:

1. **The capability is not strategically central.** It's necessary infrastructure but not what makes you special.
2. **A vendor solution exists that fits.** Most categories have multiple vendors; pick the one that fits.
3. **The total cost of ownership over the expected horizon is reasonable.** Vendor pricing usually grows with usage; model the cost at 2x and 5x your current scale.
4. **The lock-in is acceptable.** Some vendors lock you in heavily (data formats, proprietary APIs, deeply integrated tooling). Some are easier to switch from. Prefer vendors with portable formats.

Examples where buy is usually right:

- Identity / SSO (Auth0, Okta, Cognito).
- Payment processing (Stripe, Adyen).
- Email delivery (Postmark, SendGrid).
- Customer support (Intercom, Zendesk).
- Error tracking (Sentry, Bugsnag).
- Cloud infrastructure (AWS, GCP, Azure — these are buy decisions even if you call them "infra").
- Specialized SaaS in adjacent verticals (HR, legal, finance tools).

Examples where buy is usually wrong:

- Capabilities core to your differentiation.
- Anything where the vendor's roadmap might diverge from your needs in critical ways.
- Anything where the vendor's pricing model becomes punitive at scale (per-user pricing for products with many users; per-event pricing for high-event-volume products).
- Anything where the integration complexity exceeds the build cost.

The pattern: **buy commodities; don't buy your competitive advantage.**

## When to Adopt (Open Source)

Adopt when **all** of the following are true:

1. **The OSS project is mature and well-maintained.** Look at the contributor count, release cadence, issue response time. A project with one contributor and no commits in six months is a risk.
2. **The license is compatible** with your business. Some licenses (AGPL, SSPL) impose conditions you may not want.
3. **You have the operational capacity** to run it. Self-hosting OSS isn't free; you trade vendor cost for ops cost.
4. **The community is active enough** that you can get help when something breaks.
5. **The project has a sustainable funding model** (corporate backing, foundation, sponsorships) so it's likely to survive.

Examples where adopt is usually right:

- Databases (Postgres, ClickHouse, Redis — though many are best run as managed services).
- Web frameworks (React, Vue, Next.js, etc.).
- Programming languages (Python, Go, TypeScript, etc.).
- Build tools (Vite, Webpack, etc.).
- Operating systems (Linux).
- Many libraries and SDKs.

Examples where adopt is usually wrong:

- Niche tools with one maintainer who might disappear.
- Projects with restrictive licenses for commercial use.
- Tools that require deep operational expertise you don't have.
- Half-finished projects ("we'll contribute back the missing parts" — usually you won't).

The pattern: **adopt mature OSS for foundational tech; be skeptical of recent, single-vendor OSS that might be a bait-and-switch.**

## Hybrid Patterns

Many real decisions are hybrid:

- **Build on top of OSS**: adopt Postgres, but build your application's data model on top.
- **Buy with custom integration**: use Stripe but build your own subscription management layer.
- **Adopt managed OSS**: run Postgres as a managed service (RDS, Cloud SQL, Supabase) — adopt the technology, buy the operations.
- **Build the wrapper, buy the engine**: write a thin wrapper around a vendor SDK that lets you swap vendors later.

These hybrids are often the right answer. The pure build/buy/adopt decision is rarely as clean as the framework suggests.

## The Total Cost of Ownership Trap

The most common mistake in build/buy/adopt decisions: **comparing the up-front cost only**.

A vendor that costs $10k/year for 5 years is $50k. A build that takes 3 engineer-months is ~$60k in salary alone. They look similar.

But the *total* cost includes:

### Build TCO

- **Up-front engineering**: 3 months × loaded cost ≈ $60k
- **Ongoing maintenance**: ~20% of original effort per year × 5 years ≈ $60k
- **Bug fixes, feature requests, evolution**: ~10% per year × 5 years ≈ $30k
- **Onboarding new engineers**: small but real
- **Total**: ~$150k over 5 years

### Buy TCO

- **Vendor fees**: $10k × 5 years = $50k
- **Integration**: 1 engineer-month ≈ $20k
- **Ongoing integration maintenance**: ~$5k/year × 5 years = $25k
- **Migration cost if you ever leave**: variable, but real
- **Total**: ~$95k over 5 years

In this hypothetical, buy looks cheaper. But it depends on:

- **Vendor pricing growth**. If usage doubles, the vendor cost doubles. Build TCO doesn't change with usage (much).
- **The opportunity cost of the engineering time**. If those 3 months would have shipped features that brought in $200k of revenue, build is worse than the numbers show.
- **The risk of lock-in**. If you ever need to leave the vendor, the migration cost is real and painful.
- **The strategic value of control**. If the vendor's roadmap diverges from your needs, build wins long-term even if it costs more short-term.

The point: **don't compare just the dollar numbers**. Model the realistic TCO including maintenance, opportunity cost, lock-in risk, and strategic flexibility.

## The "It's Just a Weekend Project" Trap

Engineers love to estimate build cost low. "I could write that in a weekend." Sometimes true; usually false.

The hidden costs of building:

- **Edge cases**: the demo works; the real-world cases break it.
- **Reliability**: making it 99.9% reliable takes 10x as long as making it work.
- **Security**: doing security right is a separate job.
- **Documentation**: somebody has to write it for the next engineer.
- **Operations**: monitoring, alerting, runbooks, incident response.
- **Evolution**: the requirements change; the code has to change with them.
- **Onboarding**: new team members have to learn the in-house thing instead of the well-known commercial alternative.
- **Bus factor**: the engineer who built it leaves; nobody else knows how it works.

A "weekend project" usually becomes a year-long maintenance burden. The discipline is to be honest about this when sizing.

A useful test: **estimate the build cost. Triple it. Then ask if it's still worth it.** If yes, build. If no, you were lying to yourself about the original estimate.

## Vendor Risk

Every vendor decision carries vendor risk:

- **Vendor goes out of business** (or gets acquired and the new owner kills the product).
- **Vendor changes pricing** in ways that hurt you.
- **Vendor's product diverges** from your needs.
- **Vendor's reliability degrades**.
- **Vendor's terms of service change**.

Mitigations:

- **Pick large, stable vendors** for critical infrastructure when possible.
- **Have a portability plan**. Even if you don't execute it, knowing how you'd leave reduces lock-in cost.
- **Use abstractions**: a thin wrapper around the vendor's SDK lets you swap later.
- **Watch the vendor's signals**: layoffs, leadership changes, product direction changes.
- **Re-evaluate annually**: vendor decisions are not "forever."

The opposite mitigation — **never buying anything because of vendor risk** — is its own failure mode. Some risk is acceptable; the calculation is whether the risk is worth the benefit.

## OSS Risk

Adopting OSS has its own risks:

- **The project gets abandoned.** Maintainers move on; bug fixes stop.
- **The license changes.** Some recent OSS projects have switched to non-OSS licenses (Elasticsearch, Redis, MongoDB).
- **The community fragments.** A fork divides users and contributors.
- **A critical bug is unfixed for months** because the maintainer is busy.
- **The project's direction diverges from your needs.**

Mitigations:

- **Pick mature, well-maintained projects.** Number of contributors, release cadence, issue response time, corporate backing all matter.
- **Be ready to fork** if necessary. Forking is expensive but it's an option.
- **Contribute back** when you can. A project you contribute to is one you have influence over.
- **Don't depend on niche projects** for critical capabilities.
- **Have a backup**: know what you'd do if the project disappeared.

## Decision Framework

A practical decision framework for build/buy/adopt:

1. **Define the capability precisely.** What exactly do you need? What's in scope, what's out?
2. **List the options.** Several vendors, several OSS projects, the build option. Don't shortcut this; the best option is often one you didn't initially consider.
3. **Score each on:**
   - Up-front cost
   - Ongoing cost (TCO over 3-5 years)
   - Time to value
   - Strategic fit (does this support our differentiation, or is it commodity?)
   - Lock-in risk
   - Operational burden
   - Maintenance burden
4. **Filter out options that fail any deal-breaker.** (e.g., licensing incompatibility, missing critical feature, prohibitive cost at projected scale)
5. **Pick the option with the best overall fit**, not the one that scores highest on any single dimension.
6. **Document the decision as an ADR** ([team-lead](../../team-lead/SKILL.md)). Include the rejected alternatives and why.
7. **Set a re-evaluation date**. Most decisions are worth revisiting annually or biannually as the situation changes.

This is more work than "let's just pick the popular one," and it's worth it. A wrong build/buy/adopt decision compounds for years.

## Worked Example

**Capability needed**: a system for sending transactional and marketing emails.

**Options**:

1. **Build**: write our own SMTP integration, manage our own sender reputation, track deliverability ourselves.
2. **Buy: SendGrid**: pay per email sent; managed deliverability; established product.
3. **Buy: Postmark**: smaller player but excellent deliverability for transactional; pricing different from SendGrid.
4. **Buy: AWS SES**: cheap pay-per-use; less polished UX; you handle some deliverability work yourself.
5. **Adopt: Postal (open source)**: self-hosted, free, but you handle all the operations.

**Diagnosis**: email is a commodity capability. We're not differentiated by our ability to send email. We need reliable transactional delivery and basic marketing capability.

**Strategic fit**: low. Email is not our product; it's infrastructure.

**Decision**: Buy. Specifically, Postmark for transactional (high reliability matters most) and SES for marketing email (cheap at our volume).

**Rejected**:
- Build: no strategic value; high TCO; we'd be re-implementing what mature vendors already do.
- Postal: would cost engineering time to operate; no strategic benefit.
- SendGrid for everything: pricing scales worse for our usage pattern.

**Re-evaluation**: 12 months. If our volume changes significantly or if a vendor's pricing changes, revisit.

This is the kind of decision that should take half a day to make and produce a clear rationale that the team can refer back to. Not made in a meeting on the spur of the moment.

## Anti-Patterns

- **"It's faster to build it ourselves"** — almost never true if the capability has any complexity.
- **"We need to control everything"** — control has a cost; pay it deliberately.
- **"We'll save money by self-hosting"** — sometimes true, often false when you account for operational time.
- **"This vendor is expensive"** without modeling the full cost of building or adopting.
- **"That OSS project is popular"** without checking maintenance health.
- **"This is too important to trust to a vendor"** for capabilities every vendor handles fine.
- **"We can't afford the vendor"** at small scale, ignoring that the cost will grow with usage but so will revenue.
- **NIH (Not Invented Here) syndrome**. Building things that already exist because the engineers want to.
- **NIH's opposite: Cargo Cult Buying**. Buying everything because building is "old-fashioned." Loses control and creates a product made of vendor wrappers.
- **No re-evaluation**. Decisions made years ago that no longer make sense; nobody revisits.
- **No exit plan**. Locked into a vendor with no migration path.
- **Hybrid that's worse than either pure option**. A mix of build and buy that has the costs of both and the benefits of neither.
- **Decision based on the engineer's preference**, not the strategic situation.
- **Decision based on the loudest voice in the room** rather than evidence.
- **Decision without a writeup**. No record; nobody can reason about it later.

## Related

- [tech-bets-and-investments.md](tech-bets-and-investments.md) — build/buy/adopt is often a major bet
- [platform-vs-product.md](platform-vs-product.md) — when to build a platform vs. solve product needs
- [strategy-as-constraint.md](strategy-as-constraint.md) — the strategy may pre-load this decision
- [team-lead](../../team-lead/SKILL.md) — capturing the decision as an ADR
- [system-architect](../../system-architect/SKILL.md) — designs that integrate the chosen option
- [cloud-infrastructure](../../cloud-infrastructure/SKILL.md) — many infrastructure decisions are build/buy/adopt
- [security-engineering](../../security-engineering/SKILL.md) — security implications of each choice
