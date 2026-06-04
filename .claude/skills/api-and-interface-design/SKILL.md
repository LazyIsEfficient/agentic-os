---
name: api-and-interface-design
description: Guides stable API and interface design. Use when designing APIs, module boundaries, or any public interface. Use when creating REST or GraphQL endpoints, defining type contracts between modules, or establishing boundaries between frontend and backend.
when_to_use: |
  Use when designing new API endpoints, defining module or team boundaries, creating component prop interfaces, establishing database schemas that inform API shape, or changing existing public interfaces. Also use when reviewing an interface contract for stability or backward compatibility.

  Not when: only implementing code against an already-defined API — use [incremental-implementation](../incremental-implementation/SKILL.md) instead. Not when the primary concern is deprecating or removing an existing interface — use [deprecation-and-migration](../deprecation-and-migration/SKILL.md) instead.
---

# API and Interface Design

## Overview

Design stable, well-documented interfaces that are hard to misuse. Good interfaces make the right thing easy and the wrong thing hard. This applies to REST APIs, GraphQL schemas, module boundaries, component props, and any surface where one piece of code talks to another.

## Universal Rules

1. **Contract first.** Define the interface before implementing it. Types and schemas are the spec.
2. **Consistent error semantics.** Pick one error strategy and use it everywhere. Mixed patterns break consumers.
3. **Validate at boundaries only.** Trust internal code; validate at system edges where external input enters. Treat third-party responses as untrusted data.
4. **Prefer addition over modification.** Extend interfaces with optional fields. Never remove or change existing field types.
5. **Predictable naming.** Plural nouns for REST resources, camelCase for fields, is/has/can for booleans, UPPER_SNAKE for enums.
6. **Paginate list endpoints from the start.** Adding pagination later is a breaking change.
7. **Apply Hyrum's Law.** Every observable behavior — including undocumented quirks — is a potential commitment. Be intentional about what you expose.
8. **One version at a time.** Extend rather than fork. Multiple parallel versions multiply maintenance cost.

## Red Flags

- Endpoints that return different shapes depending on conditions
- Inconsistent error formats across endpoints
- Validation scattered throughout internal code instead of at boundaries
- Breaking changes to existing fields (type changes, removals)
- List endpoints without pagination
- Verbs in REST URLs (`/api/createTask`, `/api/getUsers`)
- Third-party API responses used without validation or sanitization

## Verification

After designing an API:

- [ ] Every endpoint has typed input and output schemas
- [ ] Error responses follow a single consistent format
- [ ] Validation happens at system boundaries only
- [ ] List endpoints support pagination
- [ ] New fields are additive and optional (backward compatible)
- [ ] Naming follows consistent conventions across all endpoints
- [ ] API documentation or types are committed alongside the implementation

## References

- [references/design-principles.md](references/design-principles.md) — Hyrum's Law, One-Version Rule, contract-first, error semantics, boundary validation, naming conventions
- [references/rest-and-typescript-patterns.md](references/rest-and-typescript-patterns.md) — REST resource design, pagination, filtering, PATCH, discriminated unions, input/output separation, branded IDs
