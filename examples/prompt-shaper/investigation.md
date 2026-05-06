# prompt-shaper — investigation

Example of `/shape` producing an `investigation-template.md` brief — a question to answer, no code changes.

---

## User's initial request

> Our staging API got hit with what looks like credential stuffing last weekend. I want to know what we have in terms of detection and what we're missing before I take it to the security review.

## Shaper's batched questions

This is "figure out what we have" — clear investigation, not a fix. Routes to `investigation-template.md`.

1. **The single question to answer?** "What detection do we have for credential stuffing, and what's missing?" — or sharpen further?
2. **What decision does this answer unblock?** Going to security review with a concrete asks-list, vs. deciding whether to bring it up at all?
3. **Scope — which surfaces?** API only, or also marketing-site login, dashboard, internal tools?
4. **What you already know / suspect?** Anything from the weekend incident worth carrying in?
5. **Depth budget — quick scan, medium, or thorough?**
6. **Is any code change in scope, or strictly a written report?**

## User's answers

1. Sharpen: "What detection and rate-limiting do we have on credentialed endpoints today, and what gaps would credential stuffing exploit?"
2. Going to security review on the 14th with a prioritized ask-list. The investigation feeds the ask-list.
3. API only. Marketing site uses Okta-hosted login (separate). Internal tools out.
4. Logs show ~40k failed-login attempts from ~2k IPs over 6 hours. WAF didn't trigger. Cloudflare Bot Management is on but I'm not sure how it's configured for this surface.
5. Medium — a few hours, not a week.
6. Strictly a report. No code changes.

## Output brief

```markdown
## Question
What detection and rate-limiting do we have on credentialed endpoints today, and what gaps would credential stuffing exploit?

## Why it matters
Going to security review on the 14th with a prioritized ask-list. The findings here feed that ask-list directly — the difference between "we need three months of work" and "we need one config change" lives here.

## Scope
- Repos / systems / dashboards in play: `api-server` source, Cloudflare config, WAF rules, Bot Management settings, login/auth telemetry, application logs from the weekend incident window.
- Out of scope: marketing-site login (Okta-hosted, separate surface), dashboard session refresh, internal tools.

## What I already know / suspect
- Weekend incident: ~40k failed-login attempts from ~2k IPs over 6 hours.
- WAF did not trigger.
- Cloudflare Bot Management is enabled at the account level — unsure how it's configured for the auth path specifically.
- No automated alert fired. We found out via routine log review.

## Deliverable
A written answer with: findings, evidence (file:line, log links, commits), confidence level, and recommended next action. **No code changes** unless explicitly approved after the report.

Specifically the report should answer:
- What rate-limiting exists today on `POST /login`, `POST /password-reset`, `POST /signup`?
- What does Cloudflare Bot Management actually do on those routes (passive scoring vs. active block)?
- What lockout / backoff policy exists per-account and per-IP?
- What alerting fires on auth-failure spikes? At what threshold?
- What gaps would the weekend pattern have exploited that we got lucky on?

## Time / depth budget
medium — a few hours of code-and-config reading plus log spelunking, not a full audit.
```

---

**Next step:** paste this into a fresh session, or say `go` and the executor produces the report (no code) for the 14th security review.
