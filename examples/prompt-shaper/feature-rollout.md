# prompt-shaper — multi-repo feature rollout

Example of `/shape` producing a `feature-rollout-template.md` brief for a feature that spans more than one repo.

---

## User's initial request

> We need to add SSO via Okta. The marketing site has the login button, the API issues sessions, and the dashboard reads them. I want to ship this in two weeks.

## Shaper's batched questions

The shaper detects three repos in play (marketing site, API, dashboard) and routes to `feature-rollout-template.md`. It asks one batch via `AskUserQuestion`:

1. **Exact repo paths and roles?** "Marketing site / API / dashboard" is the shape — what are the actual repo names and what does each one own in the SSO flow?
2. **Existing auth — replace or coexist?** Does Okta replace the current session model, or run alongside email/password for a transition period?
3. **Session model — do we keep our own sessions or trust Okta tokens?** This decides whether the API verifies a JWT per request or issues its own cookie after Okta callback.
4. **Compliance / security must-haves?** SOC2, audit log, IP allowlists, MFA enforced by Okta only, anything that gates merge?
5. **Two-week deadline — hard or soft?** What's tied to it (customer commit, board demo, end-of-quarter)?
6. **Out of scope?** Anything explicitly deferred — SCIM provisioning, group-based roles, JIT user creation?

## User's answers

1. `web-marketing`, `api-server`, `app-dashboard`. Marketing site has the "Sign in" button → redirects to API → API does Okta OIDC → dashboard reads session.
2. Coexist for 30 days, then email/password disabled.
3. API issues its own httpOnly cookie after Okta callback. Dashboard never sees the Okta token.
4. MFA enforced via Okta. Audit log entry on every login. SOC2 review after merge — not blocking.
5. Hard. Tied to a customer rollout on the 21st.
6. SCIM and group roles deferred. JIT user creation in scope (auto-create on first login if email matches an allowed domain).

## Output brief

```markdown
## Goal
Customers can sign in to the dashboard via Okta SSO with MFA enforced by Okta. Email/password coexists for 30 days, then is disabled. JIT-creates users on first login when their email matches an allowed domain.

## Repos in scope
- `web-marketing` — login button, OIDC redirect entry point
- `api-server` — Okta OIDC callback, session issuance (httpOnly cookie), JIT user creation, audit-log entry
- `app-dashboard` — reads existing session cookie, no Okta token exposure

## Constraints
- Hard deadline: customer rollout on the 21st (two weeks).
- Email/password must coexist for 30 days post-merge, then be disabled by feature flag.
- MFA enforced at the Okta layer — no MFA logic in our code.
- Every login emits an audit-log entry (existing audit pipeline).
- Out of scope: SCIM provisioning, group-based roles, role mapping from Okta groups.

## Approach
1. Spawn an Explore subagent per repo to map current auth surface and report back.
2. Produce an integrated plan: OIDC callback contract, cookie format, JIT flow, allowed-domain config, rollback toggle. Stop and wait for approval.
3. On approval, implement repo-by-repo. One PR per repo. Tests required: unit + one integration test that walks the full callback → cookie → dashboard read path.

## Deliverables
- Plan doc (inline)
- PRs: one per repo, linked
- Migration / rollout notes: feature-flag default off → on at customer rollout → email/password disable at +30d
- Test plan covering happy path, MFA-required path, JIT creation, denied-domain rejection

## Open questions to investigate first
- Where does the existing session cookie live (domain, path, SameSite)? Must Okta callback set the same one?
- Is the audit-log pipeline synchronous or fire-and-forget? Does login block on it?
- Allowed-domain list — config-managed or env-managed?
```

---

**Next step:** paste this into a fresh session, or say `go` and the executor spawns the per-repo Explore subagents.
