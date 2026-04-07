# Secure Code Patterns

## SQL Injection Prevention

```typescript
// UNSAFE
const result = await db.query(`SELECT * FROM users WHERE id = '${userId}'`)

// SAFE — Prisma (parameterized by default)
const result = await prisma.user.findUnique({ where: { id: userId } })

// SAFE — Drizzle
const result = await db.select().from(users).where(eq(users.id, userId))
```

## Command Injection Prevention

```typescript
// UNSAFE
exec(`convert ${filename} output.png`)

// SAFE
execFile('convert', [filename, 'output.png'])
```

## Access Control

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

## Fail-Closed Pattern

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

## Password Storage

```typescript
// UNSAFE
crypto.createHash('md5').update(password).digest('hex')

// SAFE
import { hash, verify } from 'argon2'
const hashed = await hash(password)
const valid = await verify(hashed, password)
```
