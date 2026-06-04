---
name: security
description: >-
  Scan and redact PII and sensitive data (emails, phone numbers, SSNs, API keys,
  IP addresses, credentials, amounts, company/person names) from repository files.
  Includes a pre-commit hook to block commits containing PII. Use when asked to
  audit code for sensitive data, sanitize files before publishing, or install PII
  detection hooks. For application security hardening see security-engineering.
when_to_use: |
  Use when auditing a repository for accidentally committed PII or secrets,
  sanitizing files before open-sourcing or publishing, or installing a pre-commit
  hook to block future PII commits. Focused exclusively on data-at-rest scanning
  and redaction using regex pattern matching.

  Not when: hardening application code against OWASP vulnerabilities, implementing
  auth/sessions/input validation, or doing a cross-stack security review — use
  security-and-hardening or security-engineering instead.
---

# Security Sanitizer

Scans and redacts PII / sensitive data from files in this repo. Uses only Python standard library — no external dependencies.

## Tools

| Script | Purpose | Key Command |
|--------|---------|-------------|
| `sanitizer.py` | Scan or redact PII in files | Run the project's PII sanitizer script against the target directory (e.g., `python3 <path-to-sanitizer.py> --scan --dir . --recursive`) |
| `pre-commit-hook.sh` | Git hook to block commits with PII | Install the pre-commit hook from the project's security hooks directory into `.git/hooks/pre-commit` |

## Configuration

Edit `sanitizer-config.json` to customize blocklists, custom regex patterns, skip paths, and placeholder format.

## Exit Codes

`0` = clean, `1` = PII found (useful for CI).

## Related skills

- [security-engineering](../security-engineering/SKILL.md) — application security, OWASP, auth hardening
