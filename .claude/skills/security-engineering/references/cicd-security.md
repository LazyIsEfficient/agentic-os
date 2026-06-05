# CI/CD Security — Cursor CLI Automated Review

## Security Review GitHub Action

The platform uses Cursor CLI integrated into GitHub Actions for automated security-focused code review on every PR.

**Workflow**: `.github/workflows/security-review.yml`

```yaml
name: Security Review
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  contents: read
  pull-requests: write
```

**Installation and auth**:

```bash
# Anti-pattern: curl | bash executes unverified code from the network. Always download, checksum-verify, then execute.
# DO NOT USE: curl https://cursor.com/install -fsS | bash

# SAFE: download + verify checksum before executing
curl -fsSL https://cursor.com/install -o /tmp/cursor-install.sh
sha256sum --check cursor-install.sha256  # pin the expected hash
bash /tmp/cursor-install.sh
# Authenticates via CURSOR_API_KEY GitHub secret
```

**3-Phase Review Methodology**:

1. **Repository context**: Identify existing security frameworks, patterns, sanitization
2. **Comparative analysis**: Compare new code against established security patterns
3. **Vulnerability assessment**: Trace user input through to sensitive operations

**Vulnerability Categories Scanned**:

- **Input validation**: SQL/command/XXE/template/NoSQL injection, path traversal
- **Auth & authorization**: Auth bypass, privilege escalation, JWT issues (weak signing, alg confusion, no expiry), IDOR
- **Crypto & secrets**: Hardcoded keys/passwords/tokens, weak crypto, improper key storage, weak RNG (`Math.random()`)
- **Injection & code execution**: RCE via deserialization, YAML deserialization, eval/dynamic code, XSS (reflected/stored/DOM-based)
- **Data exposure**: Sensitive data in logs, PII violations, API data leakage, debug exposure in production
- **Business logic & financial**: Race conditions, TOCTOU, transaction replay, double-spending
- **Config & supply chain**: Insecure defaults, missing security headers (CSP, HSTS), permissive CORS, vulnerable dependencies
- **Web3 critical**: Private keys/mnemonics in client-bundle code → automatic `--request-changes`

**Output**: Structured markdown with File/Line/Severity/Category/Description/Exploit Scenario/Fix Recommendation. Emoji markers: 🚨 Critical, 🔒 Security, ⚡ Performance, ⚠️ Logic, ✅ Resolved.

**Deliberate out-of-scope** (to reduce false positives):

- UUIDs assumed unguessable
- Environment variables and CLI flags trusted
- Tabnabbing, XS-Leaks, prototype pollution (unless extreme confidence)
- React/Angular XSS unless unsafe methods (`dangerouslySetInnerHTML`, `bypassSecurityTrustHtml`)
- Client-side auth checks (server is responsible)
- Logging non-PII data

## General Code Review Action

**Workflow**: `.github/workflows/cursor-code-review.yml`

Runs alongside security review but covers broader quality — max 10 inline comments prioritizing critical issues. Checks existing comments and resolves fixed issues.

## Smart Contract Review

Smart contract repos use a dedicated Cursor review with `composer-1.5` model and `.cursorrules` enforcing:

1. **SECURITY FIRST** — flag vulnerabilities immediately
2. Reentrancy attacks, access control, integer overflow/underflow
3. Unchecked external calls, unbounded loops
4. Timestamp dependence, hardcoded addresses
5. Unsafe delegate calls, front-running vulnerabilities

## Supply Chain Check

**Workflow**: `.github/workflows/supply-chain-check.yml`

```bash
pnpm audit --audit-level=high
./.github/scripts/check-vulnerable-packages.sh  # Custom blocking check
```

Runs on PR and push to main/staging.
