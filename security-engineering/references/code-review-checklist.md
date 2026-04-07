# Security Code Review Checklist

## Input Handling
- [ ] All user input validated server-side (Zod schemas)
- [ ] Using parameterized queries (Prisma/Drizzle, not string concatenation)
- [ ] Input length limits enforced
- [ ] Allowlist validation preferred over denylist

## Authentication & Sessions
- [ ] Passwords hashed with Argon2/bcrypt (not MD5/SHA1)
- [ ] Session tokens have sufficient entropy (128+ bits)
- [ ] Sessions invalidated on logout
- [ ] MFA available for sensitive operations
- [ ] JWT secrets validated at startup, expiry configured

## Access Control
- [ ] Check for framework-level auth middleware before flagging missing per-route auth
- [ ] Authorization checked on every request
- [ ] Using object references user cannot manipulate
- [ ] Deny by default policy
- [ ] Privilege escalation paths reviewed

## Data Protection
- [ ] Sensitive data encrypted at rest (RDS, ElastiCache, ECR)
- [ ] TLS for all data in transit
- [ ] No sensitive data in URLs/logs (sanitizeData applied)
- [ ] Secrets in environment/vault (not code)
- [ ] `.env` files in `.gitignore`

## Error Handling
- [ ] No stack traces exposed to users
- [ ] Fail-closed on errors (deny, not allow)
- [ ] All exceptions logged with correlation context
- [ ] Consistent error responses (no user/resource enumeration)

## Web3 Specific
- [ ] No private keys or mnemonics in client-bundle code
- [ ] ReentrancyGuard on all transfer functions
- [ ] Signature includes chainId + contract address + deadline
- [ ] Replay prevention via usedHashes mapping
- [ ] Rate limiting / velocity controls on claim functions
- [ ] SafeERC20 for all token operations
- [ ] Slither analysis passes clean
