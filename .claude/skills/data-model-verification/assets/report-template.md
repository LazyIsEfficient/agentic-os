# Data model verification — <project or PR id>

**Reviewed:** `DATA_MODEL.md` (sections: …) · **Verifier:** data-model-verifier · **Date:** YYYY-MM-DD
**Cold context:** yes — catalog diff + Source paths only; no documenter conversation

## Headline

| VERIFIED | REFUTED | UNVERIFIABLE | Total inventoried |
|---:|---:|---:|---:|
| n | n | n | n |

**Verdict:** `<pass | hold>` — hold when REFUTED > 0 (Tier 1 counterexamples required below)

## Most damaging finding

<If REFUTED > 0: section, property, what catalog claims vs what Source shows, file:line counterexample>

## Property inventory and verdicts

| ID | Section | Property | Catalog type | Verdict | Source evidence |
|---|---|---|---|---|---|
| P1 | `OrderCreated` | `orderId` | `uuid` | VERIFIED | `src/events/order.ts:12` |
| P2 | `OrderCreated` | `legacyId` | `integer` | REFUTED | absent in `src/events/order.ts` (grep) |

## REFUTED detail (Tier 1 — blocking)

### P2 — `OrderCreated.legacyId`

- **Catalog claims:** `legacyId` · `integer` · required
- **Source says:** _(quote or "symbol not found in Source paths")_
- **Fix:** remove from catalog or add to source definition

## UNVERIFIABLE (advisory)

| ID | Reason |
|---|---|
| P3 | Source is untyped handler; no explicit field list |
