# Anti-Patterns

The catch-all of smells that don't fit cleanly into the other reference files.

## Evidence and grounding smells

> These are the two failure modes behind most false-positive findings. Check them first.

- **Finding not grounded in the current file** — the finding quotes a line that isn't in the file as written, or paraphrases "how this skill probably reads" from memory. Every finding must quote the exact text at the cited `file:line`; if you can't quote it from the live file, it isn't a finding. Re-read the file before asserting what it says.
- **Collision claimed without checking the other side** — reporting that A collides with B after reading only A. Routing findings are two-sided: read B's `when_to_use`/"not when" too. A reciprocal tiebreaker on both sides means the overlap is already resolved. See [description-and-routing.md](description-and-routing.md) → Verifying a collision.

## Naming

- **Agent and skill share a name** — cosmetic, not blocking, but causes confusion when referring to "X" in conversation. Either disambiguate consistently (e.g., always say "the X agent" vs "the X skill"), or rename one.
- **Plural names** (`reviewers`, `tests`) — singular is the convention.
- **Verb-only names** (`reviewing`, `testing`) — domain-named or role-named is the convention (`code-review-and-quality`, `code-reviewer`).
- **PascalCase, snake_case, or spaced names** — only `lowercase-hyphenated` is valid.

## Description drift

- **Frontmatter description doesn't match SKILL.md body** — frontmatter promises X, body delivers Y. Loader routes on description; agent acts from body. Mismatch = silent misroute.
- **Description references skills that no longer exist** — dangling refs. Run `grep <skill-name>` against the library when renaming or removing a skill.
- **Description includes `etc.` or `and more`** — vague hedge that signals the author didn't finish thinking about scope.
- **Description out of sync with related-skills section** — the description names two siblings, the related-skills section names three different siblings. Pick one source of truth.

## Bloat

- **`SKILL.md` exceeds ~100 lines** — long content belongs in `references/`. The loader pays for every line on match; long SKILL.md degrades all matches that load it.
- **Long code blocks in `SKILL.md`** — link to `references/` instead. Short snippets (5–10 lines) for the universal-rules section are fine; anything longer is reference material.
- **Massive keyword list in description** — 15+ keywords dilutes signal. Pick the 5–10 the loader will actually see.
- **Multiple paragraphs of role framing** — "You are a senior X who has spent years..." → one short paragraph max.
- **Universal Rules section with 20+ bullets** — split into "must" (top 5–7) and reference for the rest.

## Misplaced content

- **Templates in `references/`** — anything the agent *fills out and copies* (ADRs, RFCs, briefs, review templates) goes in `assets/`. References are read-only domain knowledge.
- **Scripts in `references/`** — runnables go in `scripts/`.
- **Project-specific paths in SKILL.md body** — references should be portable. `apps/foo/services/bar.ts` won't transfer to other repos. Use generic identifiers (`apps/<service>/...`) or actual fictional examples.
- **Company names or proprietary terms in SKILL.md** — descriptions especially must be portable across repos. Concrete code examples in `references/` may use realistic identifiers, but frame them as examples, not as the only valid pattern.

## Tool allowlist smells

- **Read-only agent has Edit/Write** — blocking contradiction.
- **Intake agent has Agent tool** — allows nested delegation; breaks intake convergence.
- **Build agent has restrictive allowlist** — usually cripples it for marginal benefit.
- **Allowlist names a tool that doesn't exist** — silent ignore in some loaders; verify against current Claude Code tool list.
- **Tools listed in random order** — convention is read tools first, then write tools, then specialty (`AskUserQuestion`, `Agent`, MCP tools).

## Role smells

- **Orchestrator-only agent** — delegates everything, has no value of its own. Either give it real work or remove it; don't ship a pure pass-through.
- **Generic catch-all agent** ("the engineer agent does everything") — at some breadth, the agent is just the parent agent without a context-isolation reason. Delegating to it is overhead.
- **Two reviewers with overlapping scope** — clarify which fires when, or merge.
- **`Use proactively` without precise trigger** — fires every turn, becomes noise, gets ignored.
- **Agent that doesn't return a clear deliverable** — verdict, document, code change, brief. If the role doesn't end with a named output, it's probably a skill instead.

## Cross-reference smells

- **Asymmetric refs** — A says "see B" but B doesn't mention A. Add the reverse ref or remove the forward one.
- **Orphaned skill** — zero inbound references. Either it's a meta-skill (document it as such) or it was renamed/superseded.
- **Stale refs to renamed skills** — `grep` for old name across the library when renaming.
- **Cross-references in narrative form** — "you might also want..." instead of the conventional `For X see Y`. Consistency helps the loader.
- **Missing cross-references when adjacent skills exist** — every skill should name at least one neighbor. Truly standalone skills are rare.

## Frontmatter smells

- **`name` doesn't match folder/file** — silent misroute by the loader.
- **First-person description** ("I am...", "I help with...") — third-person is the convention.
- **Description without "Use when..."** — loader has only WHAT, no WHEN.
- **No trailing cross-reference** — leaves the loader no fallback for adjacent matches.
- **Description over 1024 chars** — some loaders enforce this hard.
- **YAML frontmatter not closed properly** (`---` missing on either side) — silent skip by some loaders.

## Universal-rules smells

- **Rules that are aspirational, not actionable** ("be thoughtful about X") — replace with a concrete check ("X must include Y because Z").
- **Rules that contradict each other** — usually a sign two skills got merged. Surface and resolve.
- **Rules without a "why"** — rules that read like edicts decay into folklore. Even one sentence of rationale ("because past incident Y showed Z") helps future contributors judge edge cases.

## Library-wide smells (only visible across files)

- **No skill claims a domain that obviously matters** — e.g., observability work but no `observability` skill. Either it's hiding inside another skill (note that), or there's a real gap.
- **Two skills both claim the same domain from different angles** — usually means one should subsume the other, or they need clearly drawn boundaries in their descriptions. First confirm neither *already* draws that boundary: if both descriptions carry a reciprocal "not when" deflecting to the other, the domains are already split and there is no finding (see [description-and-routing.md](description-and-routing.md) → Verifying a collision).
- **README index doesn't match the directory** — skills exist on disk but aren't in the README table (or vice versa). Run `ls .claude/skills/` against the README's skill list.
