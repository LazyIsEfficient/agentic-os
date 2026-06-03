# Security Review Checklist

Use this during code review to catch common security issues.

## Input Validation
- [ ] All user-supplied input is validated and sanitised before use
- [ ] No raw SQL string concatenation (use parameterised queries)
- [ ] No eval / exec on user input

## Authentication & Authorisation
- [ ] Endpoints enforce authentication where required
- [ ] Authorisation checks happen server-side, not only client-side
- [ ] Sensitive operations require re-authentication

## Secrets & Credentials
- [ ] No secrets, tokens, or credentials committed to source
- [ ] Environment variables used for all config that varies by environment
- [ ] `.env` files are gitignored

## Dependencies
- [ ] No dependencies with known critical CVEs (run `npm audit` / `cargo audit` / equivalent)
- [ ] Dependency versions are pinned or bounded

## Output Encoding
- [ ] HTML output is escaped to prevent XSS
- [ ] JSON responses set correct `Content-Type`

## Error Handling
- [ ] Error messages do not leak stack traces or internal paths to the client
- [ ] Logging does not capture PII or secrets
