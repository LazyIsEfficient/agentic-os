# API Security

## Authentication Patterns

**Session-based auth** (example — a primary web app):

```typescript
// apps/<app>/api/v1/shared/middlewares/auth.middleware.ts
// 1. Clear stale context per request (warm instance safety)
// 2. Validate session via sessionService.getUserSession()
// 3. Retrieve user via userService.findUserById()
// 4. Return 401 if missing/invalid
// 5. Cache in RequestAuthContext for handler access
```

**JWT auth**:

- `JWT_SECRET` and `JWT_EXPIRES_IN_SECONDS` validated via Zod at startup
- `JwtAuthGuard extends AuthGuard('jwt')`
- Thirdweb Web3 signature verification for wallet-based auth

**Signature-based partner API** (HMAC-SHA256):

```typescript
// apps/<partner-api>/services/signature.service.ts
// Required headers: X-API-KEY, X-API-REQUEST (UUID), X-API-SIGNATURE
const msg = `${method}${path}${uuidv7}${jsonStableStringify(body)}`
const signature = crypto.createHmac('sha256', secret).update(msg).digest('hex')
// Verification: constant-time comparison
```

## Input Validation

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

## Rate Limiting

**Redis-backed throttler**:

```typescript
// rate-limit/guards/redis-throttler.guard.ts
// Extends NestJS ThrottlerGuard with Redis storage
// Tracks by: JWT subject (decoded.sub) or IP address fallback
// Key format: ${userId|ip}${method}${path}
```

**Thirdweb payload expiry**: 300 seconds (5 minutes) for signature payloads.

**Smart contract velocity controls**: Per-transaction, lifetime, and rolling interval limits (see Web3 section).

## CORS

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

## Security Headers

```typescript
// main.ts
app.use(helmet())
// Provides: CSP, X-Frame-Options: DENY, X-Content-Type-Options: nosniff,
//           Strict-Transport-Security, X-XSS-Protection
```

## Log Sanitization

```typescript
// libs/logger/logger.ts
const SENSITIVE_KEYS = ['authorization', 'cookie', 'csrf-token', 'x-csrf-token']

export const sanitizeData = (obj: unknown, depth = 0): unknown => {
  const isSensitive = SENSITIVE_KEYS.includes(key)
  return isSensitive ? '[REDACTED]' : sanitizeData(value, depth + 1)
}
```

## Error Handling

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
