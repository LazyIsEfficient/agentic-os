---
name: source-driven-development
description: Grounds every implementation decision in official documentation. Use when you want authoritative, source-cited code free from outdated patterns. Use when building with any framework or library where correctness matters.
when_to_use: |
  Use when the user wants code that follows current best practices for a given
  framework, building boilerplate or patterns that will be copied across a
  project, implementing features where the framework's recommended approach
  matters (forms, routing, data fetching, state management, auth), reviewing or
  improving code that uses framework-specific patterns, or any time framework-
  specific code would otherwise be written from training-data memory.

  Not when: the task does not depend on a specific framework version (renaming
  variables, fixing typos, moving files), involves pure logic that works the same
  across all versions, or the user explicitly wants speed over verification.
---

# Source-Driven Development

Every framework-specific code decision must be backed by official documentation. Don't implement from memory — verify, cite, and let the user see your sources. Training data goes stale, APIs get deprecated, best practices evolve.

## Core Rules

1. Read the dependency file (`package.json`, `requirements.txt`, etc.) first — the version determines which patterns are correct.
2. Fetch the specific documentation page for each feature, not the homepage or full docs.
3. Rank sources: official docs > official blog/changelog > MDN/web standards > compatibility tables. Never cite Stack Overflow or blog posts as primary sources.
4. Write code that matches the documented API signatures exactly; if the docs show a new pattern, use it.
5. Include a citation comment for every non-trivial framework-specific decision, with full URL and anchor.
6. When docs conflict with existing project code, surface the conflict and let the user decide — don't silently pick one.
7. If a pattern cannot be found in official docs, flag it explicitly as unverified rather than hedging.

## Verification

After implementing with source-driven development:

- [ ] Framework and library versions were identified from the dependency file
- [ ] Official documentation was fetched for framework-specific patterns
- [ ] All sources are official documentation, not blog posts or training data
- [ ] Code follows the patterns shown in the current version's documentation
- [ ] Non-trivial decisions include source citations with full URLs
- [ ] No deprecated APIs are used (checked against migration guides)
- [ ] Conflicts between docs and existing code were surfaced to the user
- [ ] Anything that could not be verified is explicitly flagged as unverified

## References

- [references/process.md](references/process.md) — four-step detect → fetch → implement → cite process with examples
- [references/anti-patterns.md](references/anti-patterns.md) — common rationalizations and red flags
