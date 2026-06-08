---
description: Find completed plans in .claude/plans/ and delete them after confirmation (maintainer tooling)
allowed-tools: Read, Bash
---

You are cleaning up completed plan files in `.claude/plans/`. Plans are working documents — once their work has shipped (or been abandoned), they should be deleted so the directory reflects only **live** work. Deletion is destructive, so you confirm before removing anything and you never guess.

## Status vocabulary

Every plan carries a status line near the top: `**Status:** <state>`. The lifecycle states:

| State | Meaning | Action |
|---|---|---|
| `proposed` | not started | **keep** |
| `in-progress` | being executed | **keep** |
| `shipped` | the work landed (merged) | **delete candidate** |
| `superseded` | replaced by another plan or abandoned | **delete candidate** |

## Steps

1. **List plans.** Run `ls -1 .claude/plans/*.md`. If there are none, report "no plans to clean" and stop.

2. **Read each plan's status.** For every file, read its `**Status:**` line.
   - `shipped` / `superseded` → deletion candidate.
   - `proposed` / `in-progress` → keep.
   - Missing or unrecognized status → do **not** guess. List it under "status unclear — review manually" and keep it.

3. **Present.** Show the deletion candidates (filename, status, one-line title/purpose) and, separately, the plans being kept and any with unclear status. If there are no deletion candidates, report that and stop.

4. **Confirm.** STOP and ask the user to confirm deletion of the listed candidates. Do not delete without an explicit yes. Let the user exclude any file from the set before proceeding.

5. **Delete.** For each confirmed plan, run `git rm <path>` (staged deletion — recoverable until commit). Report exactly what was removed and remind the user to commit the deletion.

Never delete a plan whose status is `proposed`, `in-progress`, missing, or unrecognized — when in doubt, keep it and flag it for the user.
