# planning-and-task-breakdown — Okta SSO multi-repo rollout

Plan produced by `planning-and-task-breakdown` from the Okta SSO brief in [`../prompt-shaper/feature-rollout.md`](../prompt-shaper/feature-rollout.md). Three repos in scope: `web-marketing`, `api-server`, `app-dashboard`. Demonstrates contract-first parallelism, a fan-out/fan-in DAG, and explicit conflict edges where two tasks touch the same module.

---

## Input brief (from `/shape`)

The planner receives the brief verbatim. Summarized:

- **Goal:** Okta SSO with MFA, JIT user creation on allowed domains, email/password coexisting for 30 days then disabled.
- **Repos:** `web-marketing` (login button), `api-server` (Okta callback + cookie issuance + audit log), `app-dashboard` (reads existing session cookie).
- **Hard deadline:** customer rollout on the 21st.
- **Out of scope:** SCIM, group-based roles.
- **Open questions:** existing cookie shape, audit-log pipeline (sync/async), allowed-domain config location.

## Planner's read-only investigation

Before writing tasks, the planner enters plan mode and:

- Spawns one Explore subagent per repo to map the current auth surface (these become tasks `T-explore-marketing`, `T-explore-api`, `T-explore-dashboard` so the work is captured in the plan, not lost in a conversation).
- Confirms the existing session cookie: `__sess`, httpOnly, SameSite=Lax, Domain=.example.com, 7-day TTL.
- Confirms the audit-log pipeline is fire-and-forget via a Kafka producer — login does not block on audit success.
- Confirms BullMQ is not used here; the original "background job system?" question doesn't apply.

The investigation surfaces one decision: allowed-domain list lives in env today (`SSO_ALLOWED_DOMAINS`); migrating to runtime config is out of scope for v1 and is recorded as an Open Question.

---

## Output plan

````markdown
# Implementation Plan: Okta SSO

## Overview
Customers sign in to the dashboard via Okta SSO. The API exchanges the OIDC code for an Okta token, then issues its own httpOnly session cookie — the dashboard never sees the Okta token. Email/password coexists behind a feature flag for 30 days post-merge, then is disabled. JIT user creation on first login when the email matches `SSO_ALLOWED_DOMAINS`.

## Architecture Decisions
- **Session model:** API issues its own cookie post-callback. Okta token never leaves the API. Reason: existing cookie consumers in `app-dashboard` are unchanged, no token rotation in the SPA.
- **Allowed-domain config:** env var (`SSO_ALLOWED_DOMAINS`) for v1. Runtime config-management lift deferred.
- **MFA:** enforced in Okta only. No MFA logic in our code.
- **Audit log:** fire-and-forget via the existing Kafka producer. Login does not block on audit-log success.
- **Coexistence flag:** `FLAG_SSO_REQUIRED` — default `false` (email/password allowed). Flipped to `true` 30 days after merge.

## Execution DAG

```yaml
dag:
  - T-explore-marketing || T-explore-api || T-explore-dashboard
  - T-explore-marketing, T-explore-api, T-explore-dashboard → T-contract
  - T-contract → T-api-callback || T-marketing-button || T-dashboard-cookie-check || T-allowed-domains-config
  - T-api-callback → T-api-jit-user || T-api-audit-log
  - T-api-jit-user, T-api-audit-log, T-marketing-button, T-dashboard-cookie-check, T-allowed-domains-config → T-feature-flag
  - T-feature-flag → T-e2e-integration
  - checkpoint: Pre-merge after [T-e2e-integration]
```

## Task List (presentational)

### Phase 0: Discovery
- [ ] T-explore-marketing
- [ ] T-explore-api
- [ ] T-explore-dashboard

### Phase 1: Contract
- [ ] T-contract

### Phase 2: Implementation slices
- [ ] T-api-callback
- [ ] T-api-jit-user
- [ ] T-api-audit-log
- [ ] T-marketing-button
- [ ] T-dashboard-cookie-check
- [ ] T-allowed-domains-config

### Phase 3: Glue and verification
- [ ] T-feature-flag
- [ ] T-e2e-integration

### Checkpoint: Pre-merge
- [ ] All three repos build clean
- [ ] E2E test passes against the Okta staging tenant
- [ ] Audit-log entries verified in the Kafka topic
- [ ] `FLAG_SSO_REQUIRED` defaults to `false`
- [ ] Human approves before opening PRs

## Task Details

### Task: Explore current auth surface in `web-marketing`

```yaml
id: T-explore-marketing
depends_on: []
parallel_safe: true
conflicts_with: []
files_write: []
files_read:
  - web-marketing/src/components/Header.tsx
  - web-marketing/src/pages/login.tsx
  - web-marketing/src/lib/auth.ts
branch_suffix: explore-marketing
scope: XS
```

**Description:** Read-only investigation. Map the current login button, its onClick / href, and any existing session reads. Produce a 1-page note covering: where the button lives, what it links to today, what changes when switching to OIDC redirect at `/api/auth/sso/start`.

**Acceptance criteria:**
- [ ] Note identifies the login button component and its current trigger
- [ ] Note identifies any existing session reads (or confirms there are none)
- [ ] Note flags any blockers to redirecting to `/api/auth/sso/start`

**Verification:**
- [ ] Note attached to the plan as an artifact (linked from Architecture Decisions)
- [ ] No code changes (`files_write` is empty by design)

---

### Task: Explore current auth surface in `api-server`

```yaml
id: T-explore-api
depends_on: []
parallel_safe: true
conflicts_with: []
files_write: []
files_read:
  - api-server/src/middleware/session.ts
  - api-server/src/lib/cookies.ts
  - api-server/src/routes/auth/**
branch_suffix: explore-api
scope: XS
```

**Description:** Read-only investigation. Map the existing session middleware, cookie issuance helpers, and any auth routes. Confirm cookie name, flags, domain, and TTL. Produce a 1-page note feeding `T-contract`.

**Acceptance criteria:**
- [ ] Note records `__sess` cookie format (name, flags, domain, TTL)
- [ ] Note identifies the existing session-issuance code path
- [ ] Note flags any conflict with the planned callback route

**Verification:**
- [ ] Note attached to the plan
- [ ] No code changes

---

### Task: Explore current auth surface in `app-dashboard`

```yaml
id: T-explore-dashboard
depends_on: []
parallel_safe: true
conflicts_with: []
files_write: []
files_read:
  - app-dashboard/src/lib/session.ts
  - app-dashboard/src/components/AppShell.tsx
branch_suffix: explore-dashboard
scope: XS
```

**Description:** Read-only investigation. Confirm the dashboard reads only the existing session cookie and never expects an Okta token. Identify any code paths that would need to change (none expected — this is a confirmation task).

**Acceptance criteria:**
- [ ] Note confirms the dashboard reads `__sess` and nothing else
- [ ] Note flags any code expecting Okta-specific claims (unexpected; would change the contract task)

**Verification:**
- [ ] Note attached to the plan
- [ ] No code changes

---

### Task: Define OIDC contract and shared types

```yaml
id: T-contract
depends_on: [T-explore-marketing, T-explore-api, T-explore-dashboard]
parallel_safe: true
conflicts_with: []
files_write:
  - docs/auth/oidc-contract.md
  - api-server/src/types/auth.ts
files_read:
  - api-server/src/middleware/session.ts
branch_suffix: contract
scope: XS
```

**Description:** Contract-first task that unblocks every parallel consumer in Phase 2. Defines the OIDC callback URL shape, the cookie format (name, flags, TTL), the JIT user payload, and the allowed-domain env schema. Output: one markdown doc + a TypeScript types file consumed by `api-server` and copied (not symlinked) into `app-dashboard` later if needed.

**Acceptance criteria:**
- [ ] Doc covers: callback URL (`/api/auth/sso/callback`), query params (`code`, `state`), error states, cookie format, JIT payload, env config schema
- [ ] Types file exports `OidcCallbackParams`, `JitUserPayload`, `SsoConfig`
- [ ] No implementation logic — types and prose only

**Verification:**
- [ ] `tsc --noEmit` passes on `api-server/`
- [ ] Two human reviewers (one API, one frontend) sign off on the contract doc before downstream tasks dispatch

---

### Task: Implement Okta OIDC callback in `api-server`

```yaml
id: T-api-callback
depends_on: [T-contract]
parallel_safe: true
conflicts_with: [T-api-jit-user, T-api-audit-log]
files_write:
  - api-server/src/routes/auth/sso/start.ts
  - api-server/src/routes/auth/sso/callback.ts
  - api-server/src/lib/okta-client.ts
  - api-server/src/middleware/session.ts
files_read:
  - api-server/src/types/auth.ts
  - api-server/src/lib/cookies.ts
branch_suffix: api-callback
scope: M
```

**Description:** Handle the OIDC redirect entry (`/api/auth/sso/start`) and the callback (`/api/auth/sso/callback`). Verify the state param. Exchange the code for an Okta token. Hand off to `T-api-jit-user` for user lookup/creation (stub call here; real impl arrives via that task). Issue the existing `__sess` cookie. *Never* persist or log the Okta token.

**Acceptance criteria:**
- [ ] `/start` issues a state cookie and redirects to Okta with the right scopes
- [ ] `/callback` verifies state; rejects mismatch with 400
- [ ] `/callback` exchanges code for token via `okta-client.ts` (mocked in unit tests)
- [ ] `/callback` issues `__sess` matching the existing format (httpOnly, SameSite=Lax, Domain=.example.com, 7-day TTL)
- [ ] Okta token never logged or persisted

**Verification:**
- [ ] `npm test -- --grep "sso/(start|callback)"` passes
- [ ] `npm run build` succeeds
- [ ] Manual: hitting the callback with a stubbed Okta response sets the expected cookie

**Note on `conflicts_with`:** `T-api-jit-user` and `T-api-audit-log` both edit `routes/auth/sso/callback.ts`. They must serialize behind this task — listed in `conflicts_with` for symmetry, even though `depends_on` already orders them.

---

### Task: JIT user creation on first login

```yaml
id: T-api-jit-user
depends_on: [T-api-callback]
parallel_safe: true
conflicts_with: [T-api-callback, T-api-audit-log]
files_write:
  - api-server/src/lib/jit-user.ts
  - api-server/src/routes/auth/sso/callback.ts
files_read:
  - api-server/src/types/auth.ts
  - api-server/src/db/users.ts
branch_suffix: api-jit
scope: S
```

**Description:** When the callback receives an unknown email matching `SSO_ALLOWED_DOMAINS`, auto-create the user with the JIT payload defined in the contract. Reject (403) if the domain is not allowed. Existing users continue to log in normally.

**Acceptance criteria:**
- [ ] New user with allowed domain → user row created, session issued
- [ ] New user with disallowed domain → 403, no user created
- [ ] Existing user → existing row, session issued, no duplicate

**Verification:**
- [ ] `npm test -- --grep "jit-user"` passes
- [ ] Integration test: stubbed Okta response → user row appears in test DB

---

### Task: Audit-log entry on every login

```yaml
id: T-api-audit-log
depends_on: [T-api-callback]
parallel_safe: true
conflicts_with: [T-api-callback, T-api-jit-user]
files_write:
  - api-server/src/lib/audit.ts
  - api-server/src/routes/auth/sso/callback.ts
files_read:
  - api-server/src/types/auth.ts
branch_suffix: api-audit
scope: S
```

**Description:** Emit one Kafka audit-log entry per successful login (fire-and-forget). Schema: `{ event: "login.sso", user_id, email, timestamp, ip }`. Login latency must not regress.

**Acceptance criteria:**
- [ ] One audit message per login, schema matches spec
- [ ] Producer failure does not fail the login
- [ ] No PII beyond email in the message

**Verification:**
- [ ] `npm test -- --grep "audit"` passes (Kafka producer mocked)
- [ ] Manual smoke: tail the staging Kafka topic during a test login

---

### Task: Wire login button to OIDC entry in `web-marketing`

```yaml
id: T-marketing-button
depends_on: [T-contract]
parallel_safe: true
conflicts_with: []
files_write:
  - web-marketing/src/components/Header.tsx
  - web-marketing/src/pages/login.tsx
files_read:
  - web-marketing/src/lib/auth.ts
branch_suffix: marketing-button
scope: S
```

**Description:** Update the "Sign in" button to redirect to `/api/auth/sso/start`. Keep the email/password fallback link visible behind a `FLAG_SSO_REQUIRED=false` check (the flag implementation arrives in `T-feature-flag`; for now, default to showing both).

**Acceptance criteria:**
- [ ] Button click navigates to `/api/auth/sso/start`
- [ ] Email/password link remains visible
- [ ] No new auth state in the marketing site

**Verification:**
- [ ] `npm test -- --grep "Header"` passes
- [ ] Manual: click button → 302 to Okta

---

### Task: Confirm `app-dashboard` reads only the session cookie

```yaml
id: T-dashboard-cookie-check
depends_on: [T-contract]
parallel_safe: true
conflicts_with: []
files_write:
  - app-dashboard/src/lib/session.ts
files_read:
  - app-dashboard/src/types/auth.ts
branch_suffix: dashboard-cookie
scope: XS
```

**Description:** Add a typed assertion that the dashboard's session reader only consumes `__sess` and never expects Okta-specific claims. Fix any drift caught by `T-explore-dashboard`. Likely a no-op except for tightening types.

**Acceptance criteria:**
- [ ] Session reader returns the typed shape from `T-contract`
- [ ] No Okta-specific imports in the dashboard

**Verification:**
- [ ] `tsc --noEmit` passes on `app-dashboard/`
- [ ] `npm test -- --grep "session"` passes

---

### Task: Add `SSO_ALLOWED_DOMAINS` env config

```yaml
id: T-allowed-domains-config
depends_on: [T-contract]
parallel_safe: true
conflicts_with: []
files_write:
  - api-server/src/config/sso.ts
  - api-server/.env.example
  - docs/runbook/sso.md
files_read: []
branch_suffix: allowed-domains
scope: XS
```

**Description:** Read `SSO_ALLOWED_DOMAINS` (comma-separated) at boot, expose typed access to the JIT logic, and document in the runbook. Reject startup if the env is missing in non-dev environments.

**Acceptance criteria:**
- [ ] `loadSsoConfig()` returns `{ allowedDomains: string[] }`
- [ ] Missing env in production → process exits with a clear error
- [ ] Runbook documents how to add/remove domains and the redeploy requirement

**Verification:**
- [ ] `npm test -- --grep "sso/config"` passes
- [ ] Manual: unset env in staging → process exits with the expected message

---

### Task: Add `FLAG_SSO_REQUIRED` feature flag

```yaml
id: T-feature-flag
depends_on:
  - T-api-jit-user
  - T-api-audit-log
  - T-marketing-button
  - T-dashboard-cookie-check
  - T-allowed-domains-config
parallel_safe: false
conflicts_with: []
files_write:
  - api-server/src/lib/flags.ts
  - api-server/src/middleware/session.ts
  - web-marketing/src/lib/flags.ts
  - web-marketing/src/components/Header.tsx
files_read: []
branch_suffix: sso-flag
scope: M
```

**Description:** Wire the flag that gates email/password coexistence. Default `false`. When `true`: marketing site hides the email/password link; API rejects email/password login with a 410. Flipped manually 30 days after merge.

**Marked `parallel_safe: false` because** it touches the session middleware (which other tasks have already modified) and the marketing Header component. Runs after every Phase 2 task verifies.

**Acceptance criteria:**
- [ ] Flag defaults to `false`
- [ ] When `true`: email/password login → 410, marketing link hidden
- [ ] Flag is read at request time, not boot time (so it can be flipped without a redeploy)

**Verification:**
- [ ] `npm test -- --grep "FLAG_SSO_REQUIRED"` passes in both repos
- [ ] Manual: flip flag in staging → email/password login fails as expected

---

### Task: End-to-end integration test

```yaml
id: T-e2e-integration
depends_on: [T-feature-flag]
parallel_safe: true
conflicts_with: []
files_write:
  - e2e/sso/okta-flow.spec.ts
files_read: []
branch_suffix: e2e-sso
scope: M
```

**Description:** Playwright test against the Okta staging tenant. Walks the full flow: marketing button → Okta login (test user) → callback → dashboard load → session cookie verified → audit-log entry observed in Kafka.

**Acceptance criteria:**
- [ ] Happy path passes against Okta staging
- [ ] Disallowed-domain path fails with 403
- [ ] Audit-log entry observed in the test Kafka topic

**Verification:**
- [ ] `npm run e2e -- okta-flow` passes in CI

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Allowed-domain env config requires redeploy to change | Low | Documented in runbook; runtime config lift deferred to v2 |
| Audit-log Kafka producer drops messages on broker outage | Medium | Existing fire-and-forget contract — login does not block; out of scope to harden here |
| Cookie domain (`.example.com`) doesn't cover internal subdomains | Medium | `T-explore-*` confirms current cookie domain matches all consumer hostnames |
| Okta staging tenant rate-limits CI E2E test | Low | Cap test runs; cache successful flow for subsequent assertions |

## Open Questions

- Allowed-domain list config-managed vs env — confirmed env for v1; revisit if Ops needs runtime updates during the 30-day coexistence window
- Okta staging credentials in CI — does the CI runner have access, or run E2E only on demand?
````

---

## How a dispatcher consumes this plan

Day-zero ready set: `[T-explore-marketing, T-explore-api, T-explore-dashboard]` — all three have `depends_on: []`. A Cursor Background Agents runner spawns three agents on `feature/sso-explore-marketing`, `feature/sso-explore-api`, `feature/sso-explore-dashboard`. Each agent receives only its own task block as the prompt — the block is self-contained.

After all three explore tasks verify, ready set becomes `[T-contract]`. Solo dispatch (the contract task is XS but blocks everything downstream).

After `T-contract` verifies, ready set becomes `[T-api-callback, T-marketing-button, T-dashboard-cookie-check, T-allowed-domains-config]` — four tasks dispatch in parallel. None share `files_write`, so `conflicts_with` is empty between them.

After `T-api-callback` verifies, `T-api-jit-user` and `T-api-audit-log` enter the ready set. They both write `routes/auth/sso/callback.ts`, so they list each other in `conflicts_with` — the dispatcher picks one, runs it solo, then runs the other.

After every Phase 2 task verifies, `T-feature-flag` is the only ready task. It's `parallel_safe: false` (touches files multiple parties already modified) — runs solo.

After `T-feature-flag` verifies, `T-e2e-integration` runs solo. The Pre-merge checkpoint clears, and the human opens three PRs (one per repo).

**Maximum parallelism budget on this plan: 4 agents** — the Phase 2 fan-out. Phase 0 has 3, then 1, then 4, then 2 (jit + audit serialized by conflict), then 1, then 1.
