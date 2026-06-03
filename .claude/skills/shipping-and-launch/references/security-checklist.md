# Pre-Launch Security Checklist

Security checks to complete before any production launch.

## Authentication & Sessions
- [ ] Login, logout, and session expiry tested end-to-end
- [ ] Password reset flow does not leak account existence
- [ ] MFA enforced for admin accounts

## Transport
- [ ] HTTPS enforced; HTTP redirects to HTTPS
- [ ] HSTS header set
- [ ] TLS certificate valid and auto-renewing

## Headers
- [ ] `Content-Security-Policy` set and tested
- [ ] `X-Frame-Options` or `frame-ancestors` set
- [ ] `Referrer-Policy` set

## Secrets & Config
- [ ] All secrets rotated from staging values
- [ ] No `.env` or config files with real credentials in repo
- [ ] Secret scanning passed on final commit

## Dependencies
- [ ] `npm audit --audit-level=high` (or equivalent) passes
- [ ] No dependencies with known critical CVEs

## Access Control
- [ ] All admin routes require authentication
- [ ] API endpoints return 401/403 for unauthenticated/unauthorised requests (tested)
- [ ] Rate limiting in place on auth and public endpoints
