# Decision Lifecycle

How an ADR or DAD moves from idea to accepted to (eventually) superseded.

## ADR Lifecycle

```
Proposed ──► Accepted ──► (later) Superseded by ADR-XXXX
                    └──► Deprecated (no replacement)
```

### 1. Proposed
- Author drafts the ADR using [adr-template.md](adr-template.md).
- Status: `Proposed`.
- Posted as a PR against `docs/adr/`.
- Linked from the relevant ticket.

### 2. Review
- At least 2 reviewers, including the area owner.
- Reviewers must engage with **alternatives**, not just the chosen option. If the "options considered" section is weak, send back.
- Open questions resolved in PR comments → reflected in the doc before merge.

### 3. Accepted
- Status flipped to `Accepted` in the same PR that merges.
- Date set.
- ADR index updated.
- Follow-up tickets created and linked from the Consequences section.

### 4. Superseded
- A new ADR is written with `Supersedes: ADR-XXXX`.
- The old ADR is updated **only** to set status `Superseded by ADR-YYYY` and add a single line at the top pointing to the successor. Body is otherwise unchanged.
- Never delete superseded ADRs — they are the team's memory.

### 5. Deprecated
- Used when the decision is abandoned with no replacement (e.g., the feature was killed).
- Status flipped, brief note added explaining why.

## DAD Lifecycle

DADs are living documents.

### 1. Created
- Status: `Active`.
- Author is typically the area's lead or guild.
- Reviewed by the relevant team / guild.

### 2. Updated
- Edits in place when the default evolves.
- Append to the changelog at the bottom — date + one-line summary of what changed.
- Significant changes (changing the default itself) should trigger a notification to the team.

### 3. Superseded
- A new DAD replaces it. Old DAD's status → `Superseded by DAD-XXXX` with a pointer at the top.

### 4. Quarterly Review
- All active DADs reviewed once a quarter.
- For each: still accurate? Still followed in practice? If not, update or supersede.
- A DAD that no longer reflects reality is **worse than no DAD** — it teaches new joiners the wrong thing.

## Numbering & Indexing

- Numbers are zero-padded (4 digits) and never reused, even after deprecation.
- Each directory has a `README.md` index with one row per record:

```markdown
| ID | Title | Status | Date |
|---|---|---|---|
| ADR-0042 | Use Temporal for long-running order workflows | Accepted | 2026-03-12 |
| ADR-0041 | Adopt OpenTelemetry as instrumentation standard | Accepted | 2026-02-28 |
| ADR-0040 | Migrate sessions from cookies to JWT | Superseded by ADR-0046 | 2026-01-10 |
```

- The index is regenerated, not hand-edited, when possible.

## Linking

Decisions live or die by their links. Always cross-link:
- ADR → DAD it deviates from
- ADR → tickets that motivated it
- ADR → tickets created as follow-ups
- ADR → superseding / superseded ADRs
- DAD → ADRs that deviate from it
- Tickets → relevant ADR / DAD
- Code (header comment in non-obvious files) → relevant ADR

A decision record nobody can find from the code is a decision record that doesn't exist.
