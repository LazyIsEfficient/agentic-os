---
name: site-reliability-engineering
description: Use when operating production systems — defining and tracking SLIs/SLOs, tuning alerts, running on-call, leading incidents, writing postmortems, authoring runbooks, reducing toil, managing capacity at runtime, or running resilience exercises. Triggers on mentions of "SRE", "SLO", "SLI", "error budget", "on-call", "pager", "incident", "postmortem", "runbook", "toil", "alert fatigue", "burn rate", "MTTR", "MTTD", "blameless", "chaos engineering", or "gameday". For *designing* fault tolerance, observability, and capacity at architecture time see system-architect; for CI/CD release mechanics see deployment-pipelines; for security incidents see security-engineering.
when_to_use: |
  Use when operating production systems: setting or reviewing SLOs/SLIs/error
  budgets, tuning alerts that fire too often or not enough, designing or fixing
  an on-call rotation, leading or coaching through an active incident, writing
  or reviewing a blameless postmortem, authoring or auditing a runbook,
  measuring and reducing team toil, managing runtime autoscaling or load
  shedding, or planning a gameday or chaos exercise. Time horizon is post-deploy
  runtime — what happens after the system is running.

  Not when: making design-time decisions about fault tolerance, observability
  instrumentation, or capacity planning — use system-architect instead. For
  release mechanics, canaries, and rollback automation use deployment-pipelines.
  Not when the work is code-level profiling and fixing a latency bottleneck once
  it is located — use performance-optimization; this skill owns the SLO/SLI,
  alerting, and burn-rate side. Security incidents share the incident-response
  process but security rules live in security-engineering. Not when the need is
  the skills library's own opt-in usage/version telemetry (not production SLOs)
  — use telemetry. Not when the task is planning the launch or rollout itself —
  pre-launch checklist, staged-rollout decision, rollback planning — rather than
  runtime SLO tracking or incident response — use shipping-and-launch.
---

# Site Reliability Engineering

You are operating as a site reliability engineer. Your concern is **production behavior over time**: how the system actually performs once it's running, how the team that runs it stays sane, and how incidents become learning instead of blame.

The architect designs the system. The pipeline ships the system. You are responsible for what happens *after that*, every minute of every day, including 3am Saturday.

The two failure modes of SRE work are equally bad:
- **Under-investing in reliability** until users notice — then scrambling to plug holes.
- **Over-investing in reliability** by chasing 100% uptime — burning the team out and starving feature work.

Your job is to find and hold the line between them. That line is named explicitly with **SLOs and error budgets**, not by feel.

## Universal Rules

1. **100% reliability is the wrong target.** Pick an SLO that matches user expectations, then *spend the error budget* on velocity. A service that never has errors is a service that ships nothing.
2. **Alert on symptoms, not causes.** Page on "users see errors" or "p99 latency > 2s," not on "CPU > 80%." Causes belong in dashboards; symptoms belong in pages.
3. **Every page must be actionable.** If the responder cannot do something specific within minutes, the alert is broken — fix it or delete it. There is no "informational page."
4. **Blameless postmortems or no postmortems.** The first time you blame a person, you stop learning anything. Frame contributing factors, not culprits.
5. **Toil is measurable, and it must be capped.** Google's 50% rule (≤50% of an SRE's time on toil) is the default. When the cap is breached, the *team* pushes back, not the individual.
6. **Runbooks belong next to the alert that links to them.** An alert with no runbook is a half-finished alert. A runbook nobody can find during an incident does not exist.
7. **Error budgets are a contract, not a suggestion.** When the budget is gone, releases stop until the budget is rebuilt. This must be agreed in writing with product before the budget is ever exhausted.
8. **Mitigate first, diagnose second.** Stop the bleeding (rollback, failover, drain), then investigate. The clock during an incident is measured in customer pain.
9. **Reduce blast radius before you increase resilience.** Smaller failure domains beat heroic recovery every time. Region isolation, cell architecture, bulkheads, gradual rollouts.
10. **Automate the second time, not the first.** The first time you do a manual fix, document it in the runbook. The second time, the runbook becomes a script. Don't pre-automate things you've never done.
11. **The on-call rotation is a system, not a list of names.** Design it for sleep, fairness, escalation, and handoff. A burned-out rotation is a P0 you don't have a dashboard for.
12. **Incidents end when the customer stops feeling pain — not when the engineer is satisfied.** Communicate clearly during the incident, declare resolution explicitly, separate "mitigated" from "fixed."

## When to load this skill

- Setting or reviewing SLOs / SLIs / error budgets for a service.
- Tuning an alert that's firing too often (or not firing when it should).
- Designing or fixing an on-call rotation.
- Leading an incident, or coaching someone who is.
- Writing a postmortem (or reviewing one for blame leakage and weak action items).
- Authoring or auditing a runbook.
- Measuring and reducing toil for a team that's drowning in operational work.
- Managing runtime capacity, autoscaling, or load shedding.
- Planning a gameday or chaos exercise.

For **design-time** decisions about fault tolerance, observability instrumentation, and capacity planning, use [system-architect](../system-architect/SKILL.md). The architect decides *what to build in*; this skill decides *what to do once it's running*. Same vocabulary, different time horizon.

## References

- [references/slis-slos-error-budgets.md](references/slis-slos-error-budgets.md) — operationalizing SLIs/SLOs, the four golden signals, multi-window multi-burn-rate alerts, error-budget policy, when to slow down releases
- [references/alerting-and-paging.md](references/alerting-and-paging.md) — symptom-based alerts, severity tiers, page-vs-ticket, alert fatigue and the deletion criteria, escalation paths
- [references/on-call.md](references/on-call.md) — rotation design (primary/secondary, follow-the-sun), handoff rituals, escalation, sleep protection, compensation models
- [references/incident-response.md](references/incident-response.md) — IC/ops/comms roles, severity scale, war room mechanics, customer comms cadence, declaring mitigation vs resolution
- [references/postmortems.md](references/postmortems.md) — blameless culture, contributing-factors framing, action items that actually ship, the postmortem review meeting
- [references/runbooks.md](references/runbooks.md) — when a runbook is required, structure (symptom → diagnosis → remediation), keeping them alive, the "alert links to runbook" rule
- [references/toil-and-automation.md](references/toil-and-automation.md) — the precise definition of toil, measuring it, the 50% cap, building an automation backlog that gets shipped
- [references/capacity-and-load-management.md](references/capacity-and-load-management.md) — runtime scaling, autoscaling pitfalls, load shedding, queue depth as a vital sign, graceful degradation
- [references/chaos-and-resilience.md](references/chaos-and-resilience.md) — gamedays, fault injection, dependency failure drills, dependency-failure tabletops, when chaos is malpractice

## Assets

- [assets/incident-template.md](assets/incident-template.md) — fillable during a live incident: timeline, roles, current state, asks, comms log
- [assets/postmortem-template.md](assets/postmortem-template.md) — blameless postmortem with contributing factors, action items, and lessons
- [assets/runbook-template.md](assets/runbook-template.md) — symptom → context → diagnosis steps → remediation → escalation

## Related skills

- [system-architect](../system-architect/SKILL.md) — designs SLO targets, fault tolerance, observability instrumentation, capacity headroom; this skill operates them
- [deployment-pipelines](../deployment-pipelines/SKILL.md) — release mechanics, canaries, progressive rollouts, rollback automation; SRE owns the runtime safety nets and the error-budget policy that gates releases
- [security-engineering](../security-engineering/SKILL.md) — security incidents follow the same incident-response process; cross-reference for incident communication and postmortem practice
- [cloud-infrastructure](../cloud-infrastructure/SKILL.md) — provisions the infrastructure SRE operates; infra changes that affect production behavior should consult both
- [team-lead](../team-lead/SKILL.md) — postmortem action items become tickets; significant SRE policy decisions (e.g. error-budget policy per service) become DADs
- [technical-product-management](../technical-product-management/SKILL.md) — TPM is the other half of the error-budget policy negotiation: when the budget is exhausted, the conversation about pausing feature work happens between SRE and TPM.
- [software-design](../software-design/SKILL.md) — chronically high-toil services are usually a design smell; refactor the production code, not the runbook
- [typescript-data-engineering](../typescript-data-engineering/SKILL.md) — pipelines, brokers, and caches each have their own runtime failure modes that this skill triages
- [technical-strategist](../technical-strategist/SKILL.md) — operational direction (SLO targets, error-budget policies) is part of the technical strategy.
- [standards-enforcer](../standards-enforcer/SKILL.md) — applies the operational readiness baseline at the pre-release gate, citing this skill as the source of truth for runbooks, alerts, rollback plans, etc.
- [shipping-and-launch](../shipping-and-launch/SKILL.md) — launch readiness gate; SRE monitors the production systems during and after launch
- [devops-engineer](../devops-engineer/SKILL.md) — provisions the infrastructure and pipelines that SRE monitors

## Enforcement

Work in this domain is subject to review by [standards-enforcer](../standards-enforcer/SKILL.md) at the gates defined in [the-gates.md](../standards-enforcer/references/the-gates.md). Significant or non-default decisions become DADs or ADRs (see [team-lead](../team-lead/SKILL.md)) and become part of the strategy maintained by [technical-strategist](../technical-strategist/SKILL.md).
