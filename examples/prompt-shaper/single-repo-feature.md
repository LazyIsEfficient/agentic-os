# prompt-shaper — single-repo feature

Example of `/shape` producing a `single-repo-feature-template.md` brief for a change scoped to one codebase.

---

## User's initial request

> Add CSV export to the analytics dashboard. Per-user, last 90 days, async generation since some accounts have a lot of data.

## Shaper's batched questions

Single repo, single feature, async job — routes to `single-repo-feature-template.md`. The user already named the trigger ("Add"), the data ("last 90 days"), and the constraint ("async since accounts can be large"). Missing: which repo, what columns, how the user gets the file, whether the job system already exists.

1. **Repo path?**
2. **Columns and grouping?** "Per-user, last 90 days" — which fields, sorted how, one row per event or aggregated?
3. **Delivery — link, email, or in-app download?** And how long does the file stay around?
4. **Background job system — exists already, or new?**
5. **Performance ceiling?** Largest reasonable export — 100k rows, 1M, more?
6. **Out of scope?** Filtering, custom columns, scheduled exports, anything tempting to bundle?

## User's answers

1. `analytics-app`.
2. One row per event. Columns: timestamp, user_id, event_name, properties (JSON-stringified). Sort by timestamp asc.
3. In-app download — generate, store in S3, surface a "Download" button when ready. File expires after 7 days.
4. BullMQ already wired up.
5. ~5M rows is realistic for our biggest tenant. Streaming write, not in-memory.
6. Filtering, custom columns, scheduled exports — all out. Just a one-shot export of the standard event shape.

## Output brief

```markdown
## Goal
Users can export their last 90 days of events as a CSV. The job runs async because tenants can have millions of rows. The file lands in S3, expires after 7 days, and surfaces in-app via a "Download" button when ready.

## Repo
`analytics-app`

## Scope
- In: CSV export endpoint, BullMQ job, streaming writer to S3, in-app status + download button, 7-day expiry.
- Out: filtering, custom column selection, scheduled exports, formats other than CSV, ranges other than 90 days.

## Constraints
- Streaming write — must not load all events into memory. Largest realistic export ~5M rows.
- Existing BullMQ infrastructure — reuse, do not add a new job system.
- File expires 7 days after creation (lifecycle rule on the S3 bucket).
- One row per event. Columns: `timestamp, user_id, event_name, properties` (properties JSON-stringified). Sorted by timestamp asc.

## Approach
1. Read the current event-storage code and BullMQ setup. Confirm the streaming-read path exists for the events table.
2. Propose a plan: endpoint shape, job payload, S3 key scheme, status states, UI states. Stop for approval.
3. Implement. Tests required: unit on the row-formatter, integration that runs a small job end-to-end against a test S3 bucket.

## Deliverables
- One PR
- Test plan covering: small export, large export (smoke), expired file, double-click protection on the download button

## Open questions
- S3 bucket — existing analytics bucket or new dedicated one?
- Authorization — confirm the user can only download their own tenant's exports.
```

---

**Next step:** even single-repo features are usually multi-slice — paste the brief into a fresh session and run task breakdown to slice the feature into ordered, verifiable tasks (DB → API → UI vertical slices, each with acceptance and verification). Or say `go` and the shaper hands off to task breakdown, then the executor implements slice-by-slice with verification at each step.
