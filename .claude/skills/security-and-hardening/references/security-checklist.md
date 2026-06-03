# Security Checklist

Pre-commit and pre-merge security verification steps.

## OWASP Top 10 Quick Scan
- [ ] A01 Broken Access Control — authorisation enforced server-side on every route
- [ ] A02 Cryptographic Failures — no plaintext secrets; TLS enforced; strong hashing (bcrypt/argon2)
- [ ] A03 Injection — parameterised queries; no string-concatenated SQL/shell commands
- [ ] A04 Insecure Design — threat model reviewed for new features
- [ ] A05 Security Misconfiguration — no debug/dev settings in production config
- [ ] A06 Vulnerable Components — dependency audit clean (`npm audit --audit-level=high`, `cargo audit`)
- [ ] A07 Auth Failures — sessions invalidated on logout; brute-force protection in place
- [ ] A08 Software Integrity — supply chain: lockfile committed; CI verifies checksums
- [ ] A09 Logging Failures — security events logged; no PII/secrets in logs
- [ ] A10 SSRF — outbound requests validated against allowlist

## Secrets
- [ ] No secrets in source, commits, or environment variable names logged
- [ ] `.env` gitignored; `.env.example` has no real values
- [ ] Secret scanning CI step passes

## Pre-Commit Gate
- [ ] Static analysis / linter with security rules passes
- [ ] Unit tests for auth/authz paths pass
- [ ] Dependency audit passes
