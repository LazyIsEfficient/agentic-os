# planning-and-task-breakdown — CSV export single-repo feature

Plan produced by `planning-and-task-breakdown` from the CSV export brief in [`../prompt-shaper/single-repo-feature.md`](../prompt-shaper/single-repo-feature.md). Single repo (`analytics-app`), async CSV generation, BullMQ-backed. Demonstrates an XS contract task unblocking parallel slices, vertical slicing within one codebase, and infra (S3 lifecycle) running in parallel with code work.

---

## Input brief (from `/shape`)

Summarized:

- **Goal:** Per-user CSV export of last 90 days of events. Async via BullMQ, written to S3 streaming, expires after 7 days.
- **Repo:** `analytics-app`
- **Constraints:** ~5M rows max, streaming write (no in-memory buffering), reuse BullMQ.
- **Out of scope:** filtering, custom columns, scheduled exports, non-CSV formats.
- **Open questions:** S3 bucket choice, authorization (per-tenant only).

## Planner's read-only investigation

- Confirms BullMQ queues live in `src/jobs/` with one queue per domain (existing `email-queue`, `webhook-queue`); CSV export gets its own `export-queue`.
- Confirms a streaming-read path exists for the events table (`eventsStream(tenantId, fromDate, toDate)` returns an async iterable).
- Confirms an S3 client wrapper already exists (`src/lib/s3.ts`) with a `streamingUpload(key, body)` helper.
- Authorization: existing middleware enforces tenant scoping. Confirms exports are filtered to the requesting user's tenant.

Decision: a new dedicated bucket (`exports.example.com`) is cleaner than colocating with the analytics bucket — easier to apply the 7-day lifecycle rule without touching unrelated objects. Logged as an Architecture Decision.

---

## Output plan

````markdown
# Implementation Plan: CSV export

## Overview
Users request a CSV export of their last 90 days of events. The request enqueues a BullMQ job that streams events to S3. The UI polls a status endpoint; when ready, a Download button surfaces a presigned URL. Files expire after 7 days via an S3 lifecycle rule.

## Architecture Decisions
- **Queue:** new `export-queue` BullMQ queue (mirrors existing per-domain pattern).
- **Bucket:** new dedicated bucket `exports.example.com` with a 7-day lifecycle rule. Reason: scoped lifecycle without touching the main analytics bucket.
- **Streaming:** server-side via existing `eventsStream` + `streamingUpload`. No in-memory buffering at any layer.
- **Authorization:** existing tenant-scoping middleware applies to both the enqueue endpoint and the download (presigned URL is signed by the API only after authz).
- **Status polling:** UI polls every 3s while job is `queued` or `running`; stops on `ready` or `failed`.

## Execution DAG

```yaml
dag:
  - T-row-formatter || T-s3-bucket-infra
  - T-row-formatter → T-job-handler
  - T-s3-bucket-infra → T-job-handler
  - T-job-handler → T-export-contract
  - T-export-contract → T-enqueue-endpoint || T-status-endpoint
  - T-enqueue-endpoint, T-status-endpoint → T-ui-button || T-ui-status
  - T-ui-button, T-ui-status → T-integration-test
  - checkpoint: Pre-merge after [T-integration-test]
```

## Task List (presentational)

### Phase 0: Foundations
- [ ] T-row-formatter
- [ ] T-s3-bucket-infra

### Phase 1: Job + contract
- [ ] T-job-handler
- [ ] T-export-contract

### Phase 2: API endpoints
- [ ] T-enqueue-endpoint
- [ ] T-status-endpoint

### Phase 3: UI + verification
- [ ] T-ui-button
- [ ] T-ui-status
- [ ] T-integration-test

### Checkpoint: Pre-merge
- [ ] All tests pass; build clean
- [ ] Integration test exports a 100k-row sample to a test bucket and the file is readable
- [ ] S3 lifecycle rule verified in the test bucket (object expires)
- [ ] Authorization test: cross-tenant download returns 403

## Task Details

### Task: Pure-function row formatter

```yaml
id: T-row-formatter
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - src/exports/format-row.ts
  - src/exports/__tests__/format-row.test.ts
files_read:
  - src/types/event.ts
branch_suffix: row-formatter
scope: XS
```

**Description:** Pure function `formatEventRow(event): string` that returns one CSV line. Columns: `timestamp, user_id, event_name, properties` with `properties` JSON-stringified and CSV-escaped. No I/O, no external deps. Easiest task to test in isolation; unblocks the job handler.

**Acceptance criteria:**
- [ ] Returns a single CSV line ending in `\n`
- [ ] Escapes commas, quotes, and newlines in `properties`
- [ ] JSON-stringifies `properties` deterministically (sorted keys)

**Verification:**
- [ ] `npm test -- format-row` passes (≥6 cases: empty properties, nested, with quotes, with commas, with newlines, with unicode)

---

### Task: Provision S3 bucket + lifecycle rule

```yaml
id: T-s3-bucket-infra
depends_on: []
parallel_safe: true
conflicts_with: []
files_write:
  - infra/buckets/exports.ts
  - infra/buckets/__tests__/exports.test.ts
files_read: []
branch_suffix: s3-infra
scope: XS
```

**Description:** Pulumi module provisioning `exports.example.com` bucket with a 7-day expiration lifecycle rule and tenant-scoped IAM (write from API, read via presigned URL only). Runs entirely in parallel with code work.

**Acceptance criteria:**
- [ ] Bucket created with versioning off, public access blocked
- [ ] Lifecycle rule: objects expire 7 days after creation
- [ ] IAM: API role has `PutObject`; no role has direct `GetObject`

**Verification:**
- [ ] `pulumi preview` shows the expected diff
- [ ] Pulumi unit tests pass
- [ ] Apply to staging; manual verify via AWS console

---

### Task: BullMQ job handler

```yaml
id: T-job-handler
depends_on: [T-row-formatter, T-s3-bucket-infra]
parallel_safe: true
conflicts_with: []
files_write:
  - src/jobs/export-events.ts
  - src/jobs/__tests__/export-events.test.ts
  - src/queues/export-queue.ts
files_read:
  - src/exports/format-row.ts
  - src/lib/events-stream.ts
  - src/lib/s3.ts
branch_suffix: job-handler
scope: M
```

**Description:** Worker that consumes the `export-queue`. Streams events from `eventsStream(tenantId, from, to)` through `formatEventRow` and into `streamingUpload(key, body)`. Updates job state via the existing BullMQ progress mechanism. On error, marks the job failed with a retry-safe error code; partially-written objects are deleted.

**Acceptance criteria:**
- [ ] Streams 100k synthetic events end-to-end with constant memory (no buffer growth)
- [ ] Updates progress every N rows (configurable, default 10k)
- [ ] On error: deletes partial S3 object, marks job failed
- [ ] On success: stores final S3 key on the job

**Verification:**
- [ ] `npm test -- export-events` passes (mocked `eventsStream` and `s3`)
- [ ] Integration: enqueue a 1k-row job → completes → object exists in test bucket

---

### Task: Define export API contract

```yaml
id: T-export-contract
depends_on: [T-job-handler]
parallel_safe: true
conflicts_with: []
files_write:
  - src/types/export.ts
  - docs/api/exports.md
files_read:
  - src/jobs/export-events.ts
branch_suffix: contract
scope: XS
```

**Description:** Contract-first task that unblocks the two endpoint slices and the UI. Defines `POST /api/exports` request/response, `GET /api/exports/:id` response, status enum (`queued | running | ready | failed`), and the presigned-URL shape.

**Acceptance criteria:**
- [ ] Types file exports `ExportCreateRequest`, `ExportCreateResponse`, `ExportStatusResponse`, `ExportStatus`
- [ ] Doc covers each endpoint with example request and response
- [ ] No implementation logic

**Verification:**
- [ ] `tsc --noEmit` passes
- [ ] One backend reviewer + one frontend reviewer sign off before downstream tasks dispatch

---

### Task: `POST /api/exports` enqueue endpoint

```yaml
id: T-enqueue-endpoint
depends_on: [T-export-contract]
parallel_safe: true
conflicts_with: []
files_write:
  - src/routes/exports/create.ts
  - src/routes/exports/__tests__/create.test.ts
files_read:
  - src/types/export.ts
  - src/queues/export-queue.ts
  - src/middleware/tenant-scope.ts
branch_suffix: enqueue
scope: S
```

**Description:** Endpoint that accepts the export request, validates the date range (last 90 days only), enqueues the BullMQ job for the requesting tenant, and returns `{ id, status: "queued" }`. Tenant scoping enforced via existing middleware.

**Acceptance criteria:**
- [ ] Valid request → job enqueued, 202 with `{ id, status: "queued" }`
- [ ] Invalid range (>90 days) → 400
- [ ] Cross-tenant request → 403 (covered by middleware test)

**Verification:**
- [ ] `npm test -- routes/exports/create` passes
- [ ] Manual: hit endpoint, observe job in BullMQ dashboard

---

### Task: `GET /api/exports/:id` status endpoint

```yaml
id: T-status-endpoint
depends_on: [T-export-contract]
parallel_safe: true
conflicts_with: []
files_write:
  - src/routes/exports/status.ts
  - src/routes/exports/__tests__/status.test.ts
files_read:
  - src/types/export.ts
  - src/queues/export-queue.ts
  - src/lib/s3.ts
  - src/middleware/tenant-scope.ts
branch_suffix: status
scope: S
```

**Description:** Endpoint that reads job state from BullMQ and returns the typed status response. When job is `ready`, the response includes a presigned URL valid for 5 minutes. Tenant scoping enforced.

**Acceptance criteria:**
- [ ] `queued | running` → status only
- [ ] `ready` → status + presigned URL (5-min TTL)
- [ ] `failed` → status + error code
- [ ] Cross-tenant request → 403

**Verification:**
- [ ] `npm test -- routes/exports/status` passes
- [ ] Manual: complete a job → status returns presigned URL → curl downloads the file

---

### Task: Download button UI

```yaml
id: T-ui-button
depends_on: [T-enqueue-endpoint, T-status-endpoint]
parallel_safe: true
conflicts_with: [T-ui-status]
files_write:
  - src/components/exports/ExportButton.tsx
  - src/components/exports/__tests__/ExportButton.test.tsx
files_read:
  - src/types/export.ts
  - src/lib/api.ts
branch_suffix: ui-button
scope: S
```

**Description:** "Export last 90 days" button on the analytics dashboard. Click → calls `POST /api/exports` → kicks off polling. Disabled while a job for the current user is in flight. Shows a spinner while polling.

**Acceptance criteria:**
- [ ] Click triggers the enqueue request
- [ ] Disabled while job is `queued` or `running`
- [ ] Re-enabled on `ready` or `failed`
- [ ] Double-click protection (no duplicate jobs)

**Verification:**
- [ ] `npm test -- ExportButton` passes
- [ ] Manual: click, observe polling in network tab, observe enabled state transitions

---

### Task: Status indicator + download link UI

```yaml
id: T-ui-status
depends_on: [T-enqueue-endpoint, T-status-endpoint]
parallel_safe: true
conflicts_with: [T-ui-button]
files_write:
  - src/components/exports/ExportStatus.tsx
  - src/components/exports/__tests__/ExportStatus.test.tsx
files_read:
  - src/types/export.ts
  - src/lib/api.ts
branch_suffix: ui-status
scope: S
```

**Description:** Component that polls `GET /api/exports/:id` every 3s while job is `queued | running`, then renders the download link (using the presigned URL from the status response) when `ready`, or an error message when `failed`.

**Acceptance criteria:**
- [ ] Polls every 3s; stops on terminal state
- [ ] Renders presigned URL as a download link on `ready`
- [ ] Renders error code on `failed`
- [ ] Handles expired presigned URL (re-fetches status if user clicks an expired link)

**Verification:**
- [ ] `npm test -- ExportStatus` passes
- [ ] Manual: full happy path renders the link, clicks download, file lands

**Note on `conflicts_with`:** `T-ui-button` and `T-ui-status` both update the parent dashboard component to mount the new pieces. They serialize via `conflicts_with` even though they touch separate components — listed for symmetry on the parent edit.

---

### Task: End-to-end integration test

```yaml
id: T-integration-test
depends_on: [T-ui-button, T-ui-status]
parallel_safe: true
conflicts_with: []
files_write:
  - e2e/exports/full-flow.spec.ts
files_read: []
branch_suffix: e2e
scope: S
```

**Description:** Playwright test that signs in as a tenant user, clicks the export button, polls until ready, downloads the file, and asserts row count. Runs against a test S3 bucket with a 1-hour lifecycle (instead of 7-day) for cleanup.

**Acceptance criteria:**
- [ ] Happy path: 100-row export → file downloads → row count matches
- [ ] Cross-tenant download attempt → 403
- [ ] Expired presigned URL → UI refetches and re-presents

**Verification:**
- [ ] `npm run e2e -- exports/full-flow` passes in CI

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| 5M-row export exceeds BullMQ default job timeout | Medium | Set `lockDuration` and `stalledInterval` higher on `export-queue`; documented in runbook |
| Presigned URL leakage | Medium | 5-min TTL; URL never stored client-side; tenant-scoped `GetObject` policy |
| Streaming write fails partway through | Medium | Job handler deletes partial object on error; user can retry |

## Open Questions

- New dedicated `exports.example.com` bucket vs reuse the analytics bucket — decided new bucket; confirm with infra cost owner
- Should completed exports be discoverable in the dashboard for the full 7-day window, or only by job ID? — out of scope for v1; flag for v2 design
````

---

## How a dispatcher consumes this plan

Day-zero ready set: `[T-row-formatter, T-s3-bucket-infra]` — both have `depends_on: []`. The infra task and the pure-function task run in parallel on `feature/csv-row-formatter` and `feature/csv-s3-infra` — they share zero files.

After both verify, ready set becomes `[T-job-handler]`. Solo dispatch.

After `T-job-handler` verifies, ready set becomes `[T-export-contract]`. Solo, XS — fast.

After `T-export-contract` verifies, ready set becomes `[T-enqueue-endpoint, T-status-endpoint]`. Both depend only on the contract; no shared `files_write`. Two agents in parallel.

After both endpoints verify, ready set becomes `[T-ui-button, T-ui-status]`. They list each other in `conflicts_with` (both edit the parent dashboard). Dispatcher serializes — picks one, runs solo, then the other.

After both UI tasks verify, `T-integration-test` runs solo. Pre-merge checkpoint clears.

**Maximum parallelism budget on this plan: 2 agents** — Phase 0 fan-out and the endpoint fan-out. Smaller than the multi-repo example (which fans out to 4) because single-repo work has more file overlap.
