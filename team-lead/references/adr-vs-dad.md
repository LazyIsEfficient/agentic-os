# ADR vs DAD — Decision Tree

The two formats answer different questions. Pick the right one before writing.

## Decision Tree

```
Is this how we already do things by default, written down for new joiners?
├── Yes → DAD
└── No → Is the choice non-obvious AND expensive to reverse?
        ├── No → Just code review / inline comment / PR description
        └── Yes → Is it deviating from an existing DAD?
                ├── Yes → ADR (cite the DAD)
                └── No → ADR (and consider whether the *new* default deserves a DAD too)
```

## Side-by-Side

| | ADR | DAD |
|---|---|---|
| **Question answered** | "Why did we pick this here?" | "What do we do by default?" |
| **Trigger** | A specific decision point with real alternatives | A pattern the team applies repeatedly |
| **Tone** | Analytical, weighs options | Prescriptive, states the rule |
| **Length** | 1–3 pages | Half a page |
| **Lifecycle** | Immutable; superseded by new ADRs | Living document; updated in place |
| **Numbered** | Yes, sequential | Yes, sequential |
| **Audience** | Reviewers, future maintainers | New joiners, code reviewers |

## Examples

| Situation | Format |
|---|---|
| "We use Postgres for OLTP" | DAD |
| "We chose CockroachDB for the global ledger because we need multi-region writes" | ADR (deviates from the Postgres DAD) |
| "All services emit OpenTelemetry traces" | DAD |
| "We adopted Honeycomb instead of Datadog because of high-cardinality query needs" | ADR |
| "PRs require one approval and CI green" | DAD (or team handbook) |
| "We're switching the auth model from sessions to JWT" | ADR |
| "TypeScript strict mode is on in every package" | DAD |
| "We added a one-off cron job" | Neither — code is enough |

## Anti-Patterns

- **ADR for the obvious choice.** If the "options considered" are straw men, you're writing a DAD. Convert it.
- **DAD for a controversial call.** If reasonable engineers would disagree, it's an ADR.
- **Bundling decisions.** "ADR-0050: tooling overhaul" covering five unrelated choices. Split into five ADRs.
- **Rewriting accepted ADRs.** Never. Supersede with a new one and link both ways.
- **Stale DADs.** A DAD that no longer reflects practice is worse than no DAD. Review DADs quarterly.
- **Decision records nobody can find.** Maintain an index (`docs/adr/README.md`, `docs/dad/README.md`) listing all records with status, date, one-line summary.
- **Records without context.** "We chose X" with no rationale teaches nobody anything.
