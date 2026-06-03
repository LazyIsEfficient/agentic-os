---
name: deprecation-and-migration
description: Manages deprecation and migration. Use when removing old systems, APIs, or features. Use when migrating users from one implementation to another. Use when deciding whether to maintain or sunset existing code.
when_to_use: |
  Use when replacing an old system, API, or library with a new one; sunsetting a feature no
  longer needed; consolidating duplicate implementations; removing dead code; planning the
  lifecycle of a new system from design time; or deciding whether to maintain a legacy system
  or invest in migration.

  Not when: the task is purely refactoring without user-facing removal — use `software-design`
  instead. Not when the task is writing the replacement system — use the appropriate
  feature-building skill first, then return here for the cutover and removal.
---

# Deprecation and Migration

## Overview

Code is a liability, not an asset. Every line of code has ongoing maintenance cost — bugs to fix, dependencies to update, security patches to apply, and new engineers to onboard. Deprecation is the discipline of removing code that no longer earns its keep, and migration is the process of moving users safely from the old to the new.

## Universal Rules

1. **Code is a liability.** Every line carries ongoing cost; deprecate when the same functionality can be provided with less complexity.
2. **Hyrum's Law makes removal hard.** With enough users, every observable behavior becomes depended on — active migration, not announcement alone, is required.
3. **No replacement, no deprecation.** Never deprecate without a proven alternative that covers all critical use cases.
4. **Default to advisory.** Use compulsory deprecation only when maintenance cost or security risk is unsustainable; compulsory requires tooling, docs, and support.
5. **The Churn Rule.** If you own the deprecated infrastructure, you are responsible for migrating your users — not just announcing the deadline.
6. **Verify zero usage before removal.** Confirm no active consumers via metrics, logs, and dependency analysis before deleting code.
7. **Deprecation planning starts at design time.** When building something new, ask "how would we remove this in 3 years?"

## References

- [references/migration-process.md](references/migration-process.md) — deprecation decision checklist, compulsory vs advisory table, four-step migration process with templates
- [references/migration-patterns.md](references/migration-patterns.md) — strangler pattern, adapter pattern, feature flag migration, zombie code definition and response
- [references/rationalizations-and-red-flags.md](references/rationalizations-and-red-flags.md) — rationalization table and red-flag checklist

## Verification

After completing a deprecation:

- [ ] Replacement is production-proven and covers all critical use cases
- [ ] Migration guide exists with concrete steps and examples
- [ ] All active consumers have been migrated (verified by metrics/logs)
- [ ] Old code, tests, documentation, and configuration are fully removed
- [ ] No references to the deprecated system remain in the codebase
- [ ] Deprecation notices are removed (they served their purpose)
