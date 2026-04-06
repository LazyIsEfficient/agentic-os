---
name: security-engineering
description: This skill provides security engineering rules covering API security, infrastructure hardening, Web3 smart contract security, CI/CD security, OWASP Top 10:2025, ASVS 5.0, and Agentic AI security. Automatically loaded when reviewing code for vulnerabilities, implementing auth, handling user input, configuring infrastructure security, auditing smart contracts, or when "security", "vulnerability", "auth", "OWASP", "pentest", "audit", "access control", "injection", "XSS", "CSRF", or "secrets" are mentioned.
---

# Security Engineering Rules

## OWASP Top 10:2025

| # | Vulnerability | Key Prevention |
|---|---------------|----------------|
| A01 | Broken Access Control | Deny by default, enforce server-side, verify ownership |
| A02 | Security Misconfiguration | Harden configs, disable defaults, minimize features |
| A03 | Supply Chain Failures | Lock versions, verify integrity, audit dependencies |
| A04 | Cryptographic Failures | TLS 1.2+, AES-256-GCM, Argon2/bcrypt for passwords |
| A05 | Injection | Parameterized queries, input validation, safe APIs |
| A06 | Insecure Design | Threat model, rate limit, design security controls |
| A07 | Auth Failures | MFA, check breached passwords, secure sessions |
| A08 | Integrity Failures | Sign packages, SRI for CDN, safe serialization |
| A09 | Logging Failures | Log security events, structured format, alerting |
| A10 | Exception Handling | Fail-closed, hide internals, log with context |

## CI/CD Security — Cursor CLI Automated Review

### Security Review GitHub Action

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
curl https://cursor.com/install -fsS | bash
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

### General Code Review Action

**Workflow**: `.github/workflows/cursor-code-review.yml`

Runs alongside security review but covers broader quality — max 10 inline comments prioritizing critical issues. Checks existing comments and resolves fixed issues.

### Smart Contract Review

`ygg-play-platform-contracts` uses a dedicated Cursor review with `composer-1.5` model and `.cursorrules` enforcing:

1. **SECURITY FIRST** — flag vulnerabilities immediately
2. Reentrancy attacks, access control, integer overflow/underflow
3. Unchecked external calls, unbounded loops
4. Timestamp dependence, hardcoded addresses
5. Unsafe delegate calls, front-running vulnerabilities

### Supply Chain Check

**Workflow**: `.github/workflows/supply-chain-check.yml`

```bash
pnpm audit --audit-level=high
./.github/scripts/check-vulnerable-packages.sh  # Custom blocking check
```

Runs on PR and push to main/staging.

## API Security

### Authentication Patterns

**Session-based auth** (platform-app):

```typescript
// app/api/v1/shared/middlewares/auth.middleware.ts
// 1. Clear stale context per request (warm instance safety)
// 2. Validate session via sessionService.getUserSession()
// 3. Retrieve user via userService.findUserById()
// 4. Return 401 if missing/invalid
// 5. Cache in RequestAuthContext for handler access
```

**JWT auth** (ygg-redeem):

- `JWT_SECRET` and `JWT_EXPIRES_IN_SECONDS` validated via Zod at startup
- `JwtAuthGuard extends AuthGuard('jwt')`
- Thirdweb Web3 signature verification for wallet-based auth

**Signature-based partner API** (HMAC-SHA256):

```typescript
// partner-api/services/signature.service.ts
// Required headers: X-API-KEY, X-API-REQUEST (UUID), X-API-SIGNATURE
const msg = `${method}${path}${uuidv7}${jsonStableStringify(body)}`
const signature = crypto.createHmac('sha256', secret).update(msg).digest('hex')
// Verification: constant-time comparison
```

### Input Validation

**Zod at every boundary** — all API inputs validated with Zod schemas at startup and request time:

```typescript
// config.validation.ts
NODE_ENV: z.enum(['development', 'staging', 'production'])
DATABASE_URL: z.string()
JWT_SECRET: z.string()
CORS_ORIGINS: z.string()
DATABASE_MAX_CONNECTIONS: z.coerce.number().default(20)
```

**ts-rest contracts**: Type-safe API contracts enforced at compile time and runtime via `createNextHandler()`.

**URL validation**: Safe HTTP URL schema via Zod prevents open redirect and unsafe protocol attacks.

### Rate Limiting

**Redis-backed throttler** (ygg-redeem):

```typescript
// rate-limit/guards/redis-throttler.guard.ts
// Extends NestJS ThrottlerGuard with Redis storage
// Tracks by: JWT subject (decoded.sub) or IP address fallback
// Key format: ${userId|ip}${method}${path}
```

**Thirdweb payload expiry**: 300 seconds (5 minutes) for signature payloads.

**Smart contract velocity controls**: Per-transaction, lifetime, and rolling interval limits (see Web3 section).

### CORS

```typescript
// common/cors/index.ts
corsOptions: {
  origin: configService.get('CORS_ORIGINS').split(';'),  // Environment-driven allowlist
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Cookie'],
  exposedHeaders: ['Set-Cookie'],
}
```

### Security Headers

```typescript
// main.ts
app.use(helmet())
// Provides: CSP, X-Frame-Options: DENY, X-Content-Type-Options: nosniff,
//           Strict-Transport-Security, X-XSS-Protection
```

### Log Sanitization

```typescript
// libs/logger/logger.ts
const SENSITIVE_KEYS = ['authorization', 'cookie', 'csrf-token', 'x-csrf-token']

export const sanitizeData = (obj: unknown, depth = 0): unknown => {
  const isSensitive = SENSITIVE_KEYS.includes(key)
  return isSensitive ? '[REDACTED]' : sanitizeData(value, depth + 1)
}
```

### Error Handling

- Custom exception filters prevent information leakage
- No stack traces exposed to users
- Fail-closed on errors (deny, not allow)
- All exceptions logged with correlation context

```typescript
// UNSAFE — exposes internals
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.stack })
})

// SAFE — fail-closed with error ID
app.use((err, req, res, next) => {
  const errorId = crypto.randomUUID()
  logger.error({ errorId, err }, 'Unhandled exception')
  res.status(500).json({ error: 'Internal error', id: errorId })
})
```

## Infrastructure Security

### Network Isolation

**VPC design** (Pulumi):

- All databases and caches in private subnets, ingress restricted to VPC CIDR only
- No internet-facing databases — all access via VPC or Cloudflare tunnels

**Security group rules**:

| Resource | Port | Ingress Source |
|---|---|---|
| RDS PostgreSQL | 5432 | VPC CIDR only |
| ElastiCache Redis | 6379 | VPC CIDR only |
| ECS services | 80, 443 | 0.0.0.0/0 (public) |
| ECS dynamic ports | 32768-65535 | VPC CIDR only |
| Ethereum Geth RPC (dev) | 8545, 8546 | VPC CIDR only |

### Cloudflare Zero Trust

Per-developer tunnels with access policies scoped by email domain:

```typescript
// Access policy — team members
decision: 'allow'
includes: [{ emailDomain: { domain: 'yieldguild.games' } }]

// Access policy — external tools (IP-restricted)
decision: 'allow'
includes: [
  { ip: { ip: '35.90.103.132/30' } },  // Retool
]
```

- Session duration: 24 hours
- DNS records: `proxied: true` for Cloudflare protection
- Tunnel catch-all: `http_status:404` as last ingress rule

### Secrets Management

- **RDS**: `manageMasterUserPassword: true` — AWS-managed credential rotation
- **ECS tasks**: Secrets injected via Secrets Manager ARN, never as environment variables
- **IAM policies**: Scoped to specific secret ARN patterns, never `*`
- **GitHub Actions**: OIDC federation — no stored long-lived credentials
- **.env files**: Always in `.gitignore`, validated at startup via Zod
- **Dotenvx**: Encrypted secret files with `DECRYPT_PRIVATE_KEY` for shared dev environments

### Encryption

- **RDS**: `storageEncrypted: true` always
- **ElastiCache**: `atRestEncryptionEnabled: true` + `transitEncryptionEnabled: true`
- **ECR**: AES256 encryption, image scanning on push
- **TLS**: All services communicate over TLS; Cloudflare handles edge TLS

### IAM Principles

- **OIDC for CI/CD**: GitHub Actions uses `sts:AssumeRoleWithWebIdentity`, scoped to specific repo
- **Least privilege**: Each role has minimum required actions on specific resource ARNs
- **Separate dev access**: Dedicated IAM user for dev-team with secrets-read-only policy
- **No root usage**: Service accounts and scoped roles only

## Web3 Smart Contract Security

### Required Security Patterns

Every production contract must use:

1. **ReentrancyGuard** — `nonReentrant` on all token/ETH transfer functions
2. **Pausable** — `whenNotPaused` on user-facing operations; admin can emergency-pause
3. **AccessControl** — Role-based permissions for multi-actor contracts
4. **SafeERC20** — For all `transfer`/`transferFrom`/`approve` calls
5. **ECDSA verification** — Via OpenZeppelin only, never custom implementations

### Signature Verification Rules

```solidity
bytes32 hash = keccak256(abi.encodePacked(
    block.chainid,       // Prevent cross-chain replay
    address(this),       // Prevent cross-contract replay
    msg.sender,          // Prevent signature forwarding
    claimId,
    amount,
    asset,
    deadline             // Time-bound
));

bytes32 ethSignedHash = hash.toEthSignedMessageHash();
address recovered = ethSignedHash.recover(signature);
require(recovered == authorizedSigner, "Invalid signature");

// Replay prevention
require(!usedHashes[ethSignedHash], "Already claimed");
usedHashes[ethSignedHash] = true;
```

**Mandatory elements in signed data**:
- `block.chainid` — cross-chain replay prevention
- `address(this)` — cross-contract replay prevention
- `deadline` or `blockNumberDeadline` — time-bounded validity
- Per-claim unique identifier (claimId, paymentCode hash)

### Rate Limiting (On-Chain)

```solidity
struct VelocityControl {
    uint256 maxPerClaim;        // Per-transaction limit
    uint256 maxTotalClaimed;    // Lifetime limit
    uint256 intervalLimit;      // Per-interval ceiling
    uint256 interval;           // Time period (seconds)
    bool enabled;
}
```

Plus per-token daily limits: `dailyTokenWithdrawals[currentDay][asset]`

### Smart Contract Audit Findings

FailSafe audit of platform contracts identified 19 findings. Key themes:

| Theme | Examples |
|---|---|
| **Frontrunning** | Pool initialization frontrun + zero slippage |
| **Accounting bugs** | Recipient removal corrupts totalShare, index collision in merkle claims |
| **DoS vectors** | Unsafe iteration in recipient management, division by zero |
| **Missing validation** | Missing merkle totals validation, missing refund cap check |
| **Access control gaps** | FeeModule.collect lacks access control |
| **Governance** | No timelock for privileged admin functions |
| **Best practices** | Missing `_disableInitializers()`, signature lacks domain separation (EIP-712) |

### Slither Static Analysis

Run before every mainnet deployment:

```bash
npm run lint  # Runs Slither analysis
```

## Security Code Review Checklist

### Input Handling
- [ ] All user input validated server-side (Zod schemas)
- [ ] Using parameterized queries (Prisma/Drizzle, not string concatenation)
- [ ] Input length limits enforced
- [ ] Allowlist validation preferred over denylist

### Authentication & Sessions
- [ ] Passwords hashed with Argon2/bcrypt (not MD5/SHA1)
- [ ] Session tokens have sufficient entropy (128+ bits)
- [ ] Sessions invalidated on logout
- [ ] MFA available for sensitive operations
- [ ] JWT secrets validated at startup, expiry configured

### Access Control
- [ ] Check for framework-level auth middleware before flagging missing per-route auth
- [ ] Authorization checked on every request
- [ ] Using object references user cannot manipulate
- [ ] Deny by default policy
- [ ] Privilege escalation paths reviewed

### Data Protection
- [ ] Sensitive data encrypted at rest (RDS, ElastiCache, ECR)
- [ ] TLS for all data in transit
- [ ] No sensitive data in URLs/logs (sanitizeData applied)
- [ ] Secrets in environment/vault (not code)
- [ ] `.env` files in `.gitignore`

### Error Handling
- [ ] No stack traces exposed to users
- [ ] Fail-closed on errors (deny, not allow)
- [ ] All exceptions logged with correlation context
- [ ] Consistent error responses (no user/resource enumeration)

### Web3 Specific
- [ ] No private keys or mnemonics in client-bundle code
- [ ] ReentrancyGuard on all transfer functions
- [ ] Signature includes chainId + contract address + deadline
- [ ] Replay prevention via usedHashes mapping
- [ ] Rate limiting / velocity controls on claim functions
- [ ] SafeERC20 for all token operations
- [ ] Slither analysis passes clean

## Secure Code Patterns

### SQL Injection Prevention

```typescript
// UNSAFE
const result = await db.query(`SELECT * FROM users WHERE id = '${userId}'`)

// SAFE — Prisma (parameterized by default)
const result = await prisma.user.findUnique({ where: { id: userId } })

// SAFE — Drizzle
const result = await db.select().from(users).where(eq(users.id, userId))
```

### Command Injection Prevention

```typescript
// UNSAFE
exec(`convert ${filename} output.png`)

// SAFE
execFile('convert', [filename, 'output.png'])
```

### Access Control

```typescript
// UNSAFE — no authorization
app.get('/api/user/:id', async (req, res) => {
  return db.getUser(req.params.id)
})

// SAFE — ownership verified
app.get('/api/user/:id', authMiddleware, async (req, res) => {
  if (req.user.id !== req.params.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' })
  }
  return db.getUser(req.params.id)
})
```

### Fail-Closed Pattern

```typescript
// UNSAFE — fail-open
function checkPermission(user: User, resource: string): boolean {
  try {
    return authService.check(user, resource)
  } catch {
    return true // DANGEROUS
  }
}

// SAFE — fail-closed
function checkPermission(user: User, resource: string): boolean {
  try {
    return authService.check(user, resource)
  } catch (e) {
    logger.error({ user: user.id, resource, err: e }, 'Auth check failed')
    return false // Deny on error
  }
}
```

### Password Storage

```typescript
// UNSAFE
crypto.createHash('md5').update(password).digest('hex')

// SAFE
import { hash, verify } from 'argon2'
const hashed = await hash(password)
const valid = await verify(hashed, password)
```

## Agentic AI Security (OWASP 2026)

When building or reviewing AI agent systems (relevant to `doaf` framework):

| Risk | Description | Mitigation |
|------|-------------|------------|
| ASI01 | Goal Hijack — prompt injection alters objectives | Input sanitization, goal boundaries, behavioral monitoring |
| ASI02 | Tool Misuse — tools used unintended ways | Least privilege, fine-grained permissions, validate I/O |
| ASI03 | Identity & Privilege Abuse — delegated trust exploits | Short-lived scoped tokens, identity verification |
| ASI04 | Supply Chain — compromised plugins/MCP servers | Verify signatures, sandbox, allowlist plugins |
| ASI05 | Code Execution — unsafe code gen/execution | Sandbox execution, static analysis, human approval |
| ASI06 | Memory Poisoning — corrupted RAG/context | Validate stored content, segment by trust level |
| ASI07 | Insecure Inter-Agent Comms — spoofing/intercept | Authenticate, encrypt, verify message integrity |
| ASI08 | Cascading Failures — errors propagate across systems | Circuit breakers, graceful degradation, isolation |
| ASI09 | Human-Agent Trust Exploitation — over-trust manipulation | Label AI content, user education, verification steps |
| ASI10 | Rogue Agents — compromised agents acting maliciously | Behavior monitoring, kill switches, anomaly detection |

### Agent Security Checklist

- [ ] All agent inputs sanitized and validated
- [ ] Tools operate with minimum required permissions
- [ ] Credentials are short-lived and scoped
- [ ] Third-party plugins verified and sandboxed
- [ ] Code execution happens in isolated environments
- [ ] Agent communications authenticated and encrypted
- [ ] Circuit breakers between agent components
- [ ] Human approval for sensitive operations
- [ ] Behavior monitoring for anomaly detection
- [ ] Kill switch available for agent systems

## ASVS 5.0 Key Requirements

### Level 1 (All Applications)
- Passwords minimum 12 characters
- Check against breached password lists
- Rate limiting on authentication
- Session tokens 128+ bits entropy
- HTTPS everywhere

### Level 2 (Sensitive Data)
- All L1 requirements plus MFA for sensitive operations
- Cryptographic key management
- Comprehensive security logging
- Input validation on all parameters

### Level 3 (Critical Systems)
- All L1/L2 plus hardware security modules for keys
- Threat modeling documentation
- Advanced monitoring and alerting
- Penetration testing validation

## Language-Specific Security

### JavaScript / TypeScript

**Primary risks**: Prototype pollution, XSS, eval injection

```typescript
// UNSAFE: Prototype pollution
Object.assign(target, userInput)
// SAFE: Null prototype or validated keys
Object.assign(Object.create(null), validated)

// UNSAFE: eval injection
eval(userCode)
// SAFE: Never use eval with user input
```

**Watch for**: `eval()`, `innerHTML`, `document.write()`, `dangerouslySetInnerHTML`, `__proto__`, `constructor.prototype`

### Solidity

**Primary risks**: Reentrancy, access control bypass, integer issues, frontrunning

```solidity
// UNSAFE: No reentrancy protection
function withdraw(uint256 amount) external {
    token.transfer(msg.sender, amount);
    balances[msg.sender] -= amount;
}

// SAFE: ReentrancyGuard + checks-effects-interactions
function withdraw(uint256 amount) external nonReentrant {
    require(balances[msg.sender] >= amount, "Insufficient");
    balances[msg.sender] -= amount;
    token.safeTransfer(msg.sender, amount);
}
```

**Watch for**: Missing `nonReentrant`, unchecked external calls, `tx.origin` for auth, hardcoded addresses, unbounded loops, `delegatecall` to untrusted targets, missing `_disableInitializers()` in upgradeable contracts

### Python

**Primary risks**: Pickle deserialization RCE, shell injection, format string injection

```python
# UNSAFE
pickle.loads(user_data)
# SAFE
json.loads(user_data)

# UNSAFE
os.system(f"convert {filename} output.png")
# SAFE
subprocess.run(["convert", filename, "output.png"], shell=False)
```

**Watch for**: `pickle`, `eval()`, `exec()`, `os.system()`, `subprocess` with `shell=True`, `yaml.load()` (use `safe_load`)

### Go

**Primary risks**: Race conditions, template injection, slice bounds

```go
// UNSAFE: Race condition
go func() { counter++ }()
// SAFE: Atomics
atomic.AddInt64(&counter, 1)

// UNSAFE: Template injection
template.HTML(userInput)
// SAFE: Let template escape
{{.UserInput}}
```

**Watch for**: Goroutine data races, `template.HTML()`, `unsafe` package, unchecked slice access

### Shell (Bash)

**Primary risks**: Command injection, word splitting, globbing

```bash
# UNSAFE
rm $user_file
# SAFE
rm "$user_file"

# Always start scripts with
set -euo pipefail
```

**Watch for**: Unquoted variables, `eval`, backticks, `$(...)` with user input

## Deep Security Analysis Mindset

When reviewing any code, think like a senior security researcher:

1. **Memory model**: Managed vs manual? GC pauses exploitable?
2. **Type system**: Weak typing = type confusion attacks. Look for coercion exploits.
3. **Serialization**: Every language has its pickle/Marshal equivalent. All are dangerous with untrusted input.
4. **Concurrency**: Race conditions, TOCTOU, atomicity failures in the threading model.
5. **FFI boundaries**: Native interop is where type safety breaks down.
6. **Standard library**: Historic CVEs in std libs (Python urllib, Java XML, Ruby OpenSSL).
7. **Package ecosystem**: Typosquatting, dependency confusion, malicious packages.
8. **Build system**: Script injection during builds (Makefile, npm scripts, Gradle).
9. **Runtime behavior**: Debug vs release differences (Rust overflow, C++ assertions).
10. **Error handling**: How does the language fail? Silently? With stack traces? Fail-open?
