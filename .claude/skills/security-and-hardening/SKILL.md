---
name: security-and-hardening
description: Hardens code against vulnerabilities. Use when handling user input, authentication, data storage, or external integrations. Use when building any feature that accepts untrusted data, manages user sessions, or interacts with third-party services. For cross-stack security review (infrastructure, Web3, CI/CD, agentic AI) see security-engineering. For PII sanitization see security.
when_to_use: |
  Use when building or reviewing web application code that accepts user input,
  implements authentication or authorization, stores or transmits sensitive data,
  integrates with external APIs, handles file uploads or webhooks, or processes
  payment or PII data. Provides developer-focused patterns: input validation,
  parameterized queries, XSS prevention, OWASP Top 10, session management, rate
  limiting, and secrets management for TypeScript/Node web applications.

  Not when: auditing infrastructure security, CI/CD pipelines, smart contracts, or
  agentic AI systems — use security-engineering instead. For scanning existing
  files for accidentally committed PII use security.
---

# Security and Hardening

## Overview

Security-first development practices for web applications. Treat every external input as hostile, every secret as sacred, and every authorization check as mandatory. Security isn't a phase — it's a constraint on every line of code that touches user data, authentication, or external systems.

## Universal Rules

### Always Do (No Exceptions)

1. Validate all external input at the system boundary (API routes, form handlers).
2. Parameterize all database queries — never concatenate user input into SQL.
3. Encode output to prevent XSS; use framework auto-escaping, don't bypass it.
4. Use HTTPS for all external communication.
5. Hash passwords with bcrypt/scrypt/argon2 (never store plaintext).
6. Set security headers (CSP, HSTS, X-Frame-Options, X-Content-Type-Options).
7. Use httpOnly, secure, sameSite cookies for sessions.
8. Run `npm audit` before every release.

### Ask First (Requires Human Approval)

- Adding new authentication flows or changing auth logic
- Storing new categories of sensitive data (PII, payment info)
- Adding new external service integrations
- Changing CORS configuration
- Adding file upload handlers
- Modifying rate limiting or throttling
- Granting elevated permissions or roles

### Never Do

- Never commit secrets to version control (API keys, passwords, tokens).
- Never log sensitive data (passwords, tokens, full credit card numbers).
- Never trust client-side validation as a security boundary.
- Never disable security headers for convenience.
- Never use `eval()` or `innerHTML` with user-provided data.
- Never store sessions in client-accessible storage (localStorage for auth tokens).
- Never expose stack traces or internal error details to users.

## References

- [references/owasp-patterns.md](references/owasp-patterns.md) — OWASP Top 10 code patterns: injection, broken auth, XSS, access control, misconfiguration, sensitive data exposure
- [references/input-validation.md](references/input-validation.md) — Zod schema validation, file upload safety, rate limiting, secrets management
- [references/audit-triage.md](references/audit-triage.md) — npm audit decision tree, rationalizations, red flags, verification checklist
- [references/security-checklist.md](references/security-checklist.md) — Detailed pre-commit security checklist

## Related skills

- [security](../security/SKILL.md) — PII scanning and pre-commit hooks for sensitive data at rest
- [security-engineering](../security-engineering/SKILL.md) — cross-stack security design, threat modeling, architecture review
