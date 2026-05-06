# Security Baseline Check

The security baseline is **non-negotiable**. Other standards (code quality, operational readiness, even strategic alignment in some cases) can be deferred, scoped down, or waived through an exception process. Security cannot. A feature that ships with a security flaw is a feature that puts users and the business at risk in ways that aren't recoverable just by fixing the code later — credentials get stolen, data leaks, trust collapses.

This file is the workflow for the security check the enforcer performs. **It does not restate the security rules** — those live in [security-engineering](../../security-engineering/SKILL.md). The enforcer's job is to apply them at the gates.

## The Premise

The enforcer is *not* a security auditor. The enforcer is a generalist who applies the security baseline as part of a broader review. For deep security analysis (penetration testing, threat modeling, cryptographic review), engage someone with specialized security expertise.

But for the everyday baseline — the things that should be true of *every* feature — the enforcer is the line of defense. The baseline is what the team has agreed must be true; the enforcer verifies that it is.

The full security baseline lives in [security-engineering](../../security-engineering/SKILL.md). The categories below are *what to check*, not *the rules themselves*. For each category, the enforcer routes to the security-engineering reference file for the specific rules.

## What the Baseline Covers

The security baseline has roughly these categories:

| Category | Source | What the enforcer checks |
|---|---|---|
| **Input validation** | [security-engineering/references/secure-code-patterns.md](../../security-engineering/references/secure-code-patterns.md) | Is user input validated at the API boundary? |
| **Auth & authorization** | [security-engineering/references/api-security.md](../../security-engineering/references/api-security.md) | Are auth checks present? Authorization on every protected request? |
| **SQL injection** | [security-engineering/references/secure-code-patterns.md](../../security-engineering/references/secure-code-patterns.md) | Parameterized queries; never string concatenation. |
| **Secrets management** | [security-engineering/references/infrastructure-security.md](../../security-engineering/references/infrastructure-security.md) | Secrets in vault, not in code or env files. |
| **Data exposure** | [security-engineering/references/api-security.md](../../security-engineering/references/api-security.md) | API responses don't leak data the requesting user shouldn't see. |
| **Logging** | [security-engineering/references/api-security.md](../../security-engineering/references/api-security.md) | Sensitive data redacted in logs (auth headers, PII). |
| **Error handling** | [security-engineering/references/api-security.md](../../security-engineering/references/api-security.md) | Errors don't leak stack traces, internal paths, etc. |
| **Dependencies** | [security-engineering/references/cicd-security.md](../../security-engineering/references/cicd-security.md) | New dependencies vetted; no known CVEs. |
| **Encryption** | [security-engineering/references/infrastructure-security.md](../../security-engineering/references/infrastructure-security.md) | TLS in transit; encryption at rest where required. |
| **Rate limiting** | [security-engineering/references/api-security.md](../../security-engineering/references/api-security.md) | Public endpoints rate-limited. |
| **CSRF / XSS** | [security-engineering/references/owasp-top-10.md](../../security-engineering/references/owasp-top-10.md) | Mitigations in place for browser-facing endpoints. |
| **Smart contracts** (if applicable) | [security-engineering/references/web3-smart-contracts.md](../../security-engineering/references/web3-smart-contracts.md) | Contract security patterns; reentrancy guards; signature verification. |

The enforcer doesn't memorize the rules. The enforcer knows *which file to look at* for each category and routes the check accordingly.

## The Check, Step by Step

### Step 1: Identify the security surface

Before any specific check, ask: **what's the security surface of this work?**

- **Does it accept user input?** (Yes for almost any feature; pay attention to where the input enters and how it's handled.)
- **Does it handle auth?** (Sign-in, password reset, session management, token issuance.)
- **Does it expose data?** (API endpoints, file downloads, search results.)
- **Does it modify state?** (Anything that's not a pure read.)
- **Does it integrate with third parties?** (External APIs, OAuth, webhooks.)
- **Does it run untrusted code?** (User uploads, plugins, eval, code execution.)
- **Does it store secrets?** (Credentials, API keys, tokens.)
- **Is it on the network boundary?** (Public endpoint vs internal service.)
- **Does it touch payments / PII / health data / kids' data?** (Compliance requirements add to the baseline.)

The size of the security surface determines the depth of the check. A trivial UI tweak has minimal surface; a new authentication flow has maximum surface.

### Step 2: Match the surface to the relevant baseline categories

For each surface element, identify the categories that apply:

- **User input** → input validation, SQL injection, XSS.
- **Auth** → auth & authorization, secrets management, error handling.
- **Data exposure** → authorization, logging, response filtering.
- **State changes** → CSRF (browser), authorization, audit logging.
- **Third-party integration** → secrets, encryption, error handling, dependency vetting.
- **Untrusted code** → input validation, sandboxing, careful error handling.
- **Secrets storage** → secrets management, encryption.
- **Public endpoint** → rate limiting, auth, error handling, input validation.
- **Compliance-relevant data** → encryption, audit logging, data handling, retention.

For each applicable category, route to the relevant security-engineering reference file and verify the work meets the rules there.

### Step 3: Look for known anti-patterns

Some anti-patterns are common enough that the enforcer should look for them by default:

- **SQL string concatenation**: `query = "SELECT * FROM users WHERE id = " + userId`. Always wrong.
- **Auth bypass**: an endpoint with no auth check that should have one.
- **Secrets in code**: API keys, passwords, private keys committed to the repo.
- **Plaintext passwords**: storing or logging passwords in plaintext.
- **Unrestricted CORS**: `Access-Control-Allow-Origin: *` on a sensitive endpoint.
- **Missing CSRF**: state-changing endpoints without CSRF protection (browser context).
- **Disabled TLS**: HTTP where HTTPS is required.
- **Unsanitized user output**: user input rendered into HTML without escaping.
- **Predictable IDs**: sequential IDs that allow enumeration.
- **Default credentials**: dev/staging credentials shipped to production.
- **Open S3 buckets**: storage with public read on data that should be private.
- **Unvalidated redirects**: open redirects that can be used in phishing.

If any of these are present, block the change and route to the relevant security-engineering reference for the fix.

### Step 4: Check dependency hygiene

If the change adds or updates dependencies:

- **Are the new dependencies vetted?** Check for known vulnerabilities (Snyk, Dependabot, npm audit, etc.).
- **Do they come from trusted sources?** (Avoid unmaintained projects, single-person repos for critical functionality.)
- **Are they pinned to specific versions?** (Not just `latest`.)
- **Are licenses compatible?** (Some licenses are incompatible with commercial use.)

For deeper dependency security, see [security-engineering/references/cicd-security.md](../../security-engineering/references/cicd-security.md).

### Step 5: Check for compliance-relevant data

If the work touches compliance-relevant categories — payments (PCI), health (HIPAA), EU users (GDPR), children (COPPA), financial (SOC2), etc. — additional rules apply:

- **PCI**: payment processing must be isolated; specific encryption and audit requirements.
- **GDPR**: consent flows, data minimization, right to deletion, cross-border transfer restrictions.
- **HIPAA**: encryption, access logs, business associate agreements.
- **COPPA**: parental consent, no behavioral ad targeting for under-13.
- **SOC2**: change management, access control, audit logs.

These have specific requirements that go beyond the baseline. The enforcer flags compliance scope and routes to whoever owns compliance for the team.

### Step 6: Verify automated security checks have run

Some security checks are automated:

- **CI security scanning**: SAST tools, dependency scanners, secret scanners.
- **Linting**: rules that catch common security issues.
- **Test coverage** for security-related code (auth flows, input validation).
- **Pre-commit hooks**: secret detection, etc.

The enforcer verifies these have run and passed. A failed security scan is a block.

### Step 7: For higher-risk work, require a security review

The baseline check is a generalist's review. For higher-risk work, the enforcer requires a *specialist's* review:

- **New authentication flow** → security specialist reviews.
- **New cryptographic code** → security specialist reviews.
- **Major architectural change** to security-sensitive areas → security specialist reviews.
- **Smart contract changes** → smart contract security review.
- **Compliance-relevant changes** → compliance team reviews.
- **Anything where the team isn't sure** → escalate.

The enforcer's role is to *recognize* when specialist review is needed, not to *be* the specialist. The team is in trouble if it's only relying on the enforcer for security; the enforcer is the *baseline*, not the *audit*.

## What the Baseline Doesn't Cover

The baseline check is for the everyday case. It does *not* replace:

- **Full security audits** (third-party penetration testing).
- **Threat modeling** (the formal process of mapping the system's attack surface).
- **Cryptographic review** (anyone implementing crypto needs specialist review).
- **Compliance audits** (SOC2, PCI, etc., have their own processes).
- **Bug bounty / responsible disclosure programs**.
- **Incident response** (when something has already happened).

The enforcer's baseline check is *necessary but not sufficient*. The team needs the deeper security practices too.

## When the Baseline Is Violated

The enforcer's response to a baseline violation:

### For low-impact violations (missing log redaction, weak rate limit, missing input validation on non-critical field)

- **Block with a clear fix path.** "Add redaction here; here's how."
- **Don't escalate.** The team can fix it.
- **Re-review after the fix.**

### For medium-impact violations (auth bypass on a non-critical endpoint, leaked stack trace, missing CSRF on a state-changing endpoint)

- **Block firmly.** "This needs to be fixed before merge."
- **Cite the specific rule.** "Per security-engineering's API security reference, all state-changing endpoints require CSRF protection in browser contexts."
- **Offer the fix.** "Here's how to add CSRF protection to this endpoint."
- **Re-review carefully.**

### For high-impact violations (auth bypass on a critical endpoint, secret committed to repo, SQL injection, broken cryptography)

- **Block immediately.** Don't merge under any circumstances.
- **Escalate to the security-engineering specialist** (or the security team if one exists).
- **Treat as a near-miss incident.** This shouldn't have made it to PR review; how did it get here? Process improvement needed.
- **Verify the fix thoroughly.** A high-impact security fix needs to be reviewed by someone other than the original author.

### For violations that have already shipped

- **Treat as a security incident.** Engage the [site-reliability-engineering](../../site-reliability-engineering/SKILL.md) incident response process.
- **Determine the impact.** What data is exposed? For how long? Who's affected?
- **Mitigate immediately.** Take the feature offline if necessary.
- **Postmortem.** Blameless, focused on how the violation got past the enforcement gates.

## Exceptions to the Baseline

The security baseline allows fewer exceptions than other standards. Some things are non-negotiable:

- **No exceptions for SQL injection**, ever.
- **No exceptions for committed secrets**, ever.
- **No exceptions for missing auth on protected endpoints**, ever.
- **No exceptions for plaintext passwords**, ever.

For these, the enforcer blocks regardless of the team's wishes.

For other baseline items, there might be legitimate cases where the standard doesn't apply or where a temporary exception is acceptable. The exception process is the same as for other standards (see [exceptions-and-waivers.md](exceptions-and-waivers.md)), but with extra scrutiny:

- **Exception requests for security must be reviewed by a security specialist**, not just the strategist.
- **Exception requests must include a mitigation plan**: what's done to reduce the risk while the exception is in effect.
- **Security exceptions have a hard expiration date.** "Until we can fix it" is not acceptable; "expires in 30 days, then reviewed" is.

## Common Failure Modes

### "It's an internal endpoint; we don't need auth"

Internal endpoints get attacked too. Insider threats, lateral movement after a breach, accidental exposure via misconfiguration. The bar for internal endpoints is *almost* as high as external; the difference is small.

The enforcer doesn't accept "it's internal" as a reason to skip auth.

### "We'll add validation later"

Later doesn't come. The validation is added at the moment the work is done, or it's not added at all.

The enforcer doesn't accept "later" for security.

### "The library handles it"

Sometimes true; often false. Verify. The library might handle the *general* case but miss the specific case the team is doing.

The enforcer asks: "How do you know? Show me."

### "We're doing X like Y does"

Cargo-culting other companies isn't a security argument. The other company might be doing it wrong, or they might have context the team doesn't.

The enforcer asks: "What's the rule and where does it come from? Cite the source."

### "It's just for the demo"

Demos go to production. "Just for the demo" code stays. The enforcer treats demo code as production code if there's any chance it'll ship.

### "The PM said we can skip it"

Security isn't subject to PM override. The PM doesn't have the authority to waive security baselines. The enforcer escalates if PMs try to wave through security concerns.

## Anti-Patterns

- **Skipping security checks for "low-risk" features.** Almost all features have some surface; check it.
- **Trusting the developer's word** that something is secure, without verification.
- **Approving security work the enforcer doesn't understand.** If you're not sure, route to a specialist.
- **Letting "we'll fix it later"** pass for security.
- **Inconsistent application.** Strict on some teams, loose on others.
- **No hard line on critical violations.** Treating all security issues as negotiable.
- **Approving an exception for security without a specialist's review.**
- **No mitigation plan** for security exceptions.
- **Indefinite security exceptions.** "Until we have time to fix it" — never.
- **Ignoring automated scanner failures.** They might be false positives, but verify.
- **Reviewing security as a checklist exercise** without actually understanding what's being checked.
- **Approving security-relevant changes from senior engineers without review.** Senior engineers make security mistakes too.
- **Letting compliance scope creep silently.** New code that touches compliance data without going through compliance review.
- **No incident response when a violation reaches production.** The violation slipped through the gates; what changed?

## Related

- [the-gates.md](the-gates.md) — when this check happens
- [enforcement-philosophy.md](enforcement-philosophy.md) — the why
- [exceptions-and-waivers.md](exceptions-and-waivers.md) — the exception process
- [escalation.md](escalation.md) — when teams won't comply
- [security-engineering](../../security-engineering/SKILL.md) — the source of truth for the baseline
- [security-engineering/references/owasp-top-10.md](../../security-engineering/references/owasp-top-10.md) — the most common categories
- [security-engineering/references/code-review-checklist.md](../../security-engineering/references/code-review-checklist.md) — detailed checklist
- [site-reliability-engineering](../../site-reliability-engineering/SKILL.md) — for incident response if a violation ships
