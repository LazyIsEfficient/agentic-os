---
name: security
description: >-
  Scan and redact PII and sensitive data (emails, phone numbers, SSNs, API keys,
  IP addresses, credentials, amounts, company/person names) from repository files.
  Includes a pre-commit hook to block commits containing PII. Use when asked to
  audit code for sensitive data, sanitize files before publishing, or install PII
  detection hooks. For application security hardening see security-engineering.
---

# Security Sanitizer

Scans and redacts PII / sensitive data from files in this repo. Uses only Python standard library — no external dependencies.

## Tools

| Script | Purpose | Key Command |
|--------|---------|-------------|
| `sanitizer.py` | Scan or redact PII in files | `python3 security/sanitizer.py --scan --dir . --recursive` |
| `pre-commit-hook.sh` | Git hook to block commits with PII | `cp security/pre-commit-hook.sh .git/hooks/pre-commit` |

## Configuration

Edit `sanitizer-config.json` to customize blocklists, custom regex patterns, skip paths, and placeholder format.

## Exit Codes

`0` = clean, `1` = PII found (useful for CI).

## Related skills

- `security-engineering` — application security, OWASP, auth hardening
