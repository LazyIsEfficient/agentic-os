# Skill-Building Ruleset

Canonical best practices for authoring Claude skills in this repository,
distilled from Anthropic's **The Complete Guide to Building Skills for Claude**
(published 2026). These are the rules; the guide is the rationale.

Where this repo's gates are **stricter** than the guide, the local rule wins —
see [Local divergences](#local-divergences-this-repo) at the end. When in doubt,
the deterministic gate (`scripts/validate.sh`) is the final authority.

---

## 1. Core principles

- **R1 — Progressive disclosure.** Three levels, smallest first: frontmatter
  (always in context) → `SKILL.md` body (loaded when relevant) → linked files in
  `references/`/`assets/` (read on demand). Put only what's needed at each level.
- **R2 — Composability.** Assume other skills load alongside yours. Never assume
  you are the only capability available.
- **R3 — Portability.** A skill should behave identically across Claude.ai,
  Claude Code, and the API, given its declared dependencies. Declare
  environment needs in `compatibility`; don't hard-code one surface.

## 2. File structure

- **R4** — A skill is a single kebab-case folder containing exactly one
  `SKILL.md` plus optional `scripts/`, `references/`, `assets/`.
- **R5** — `scripts/` = runnable code; `references/` = read-only knowledge loaded
  as needed; `assets/` = templates/fonts/icons used in output. Keep each in its
  lane (don't put fill-out templates in `references/`, don't inline runnables).

## 3. Naming (hard rules)

- **R6** — The main file is named exactly `SKILL.md` (case-sensitive). No
  variants (`SKILL.MD`, `skill.md`).
- **R7** — Folder and `name` are kebab-case: `notion-project-setup` ✅; no
  spaces, underscores, or capitals.
- **R8** — `name` must match the folder name.
- **R9** — A skill `name` may **not** contain `claude` or `anthropic` (reserved).

## 4. Frontmatter (the most load-bearing part)

- **R10** — Required: `name` and `description`. (This repo additionally requires
  `when_to_use` — see R31.)
- **R11** — `description` MUST state BOTH **what the skill does** AND **when to
  use it** (concrete trigger phrases a user would actually say). Mention relevant
  file types.
- **R12** — `description` ≤ 1024 characters. (Local rubric prefers ≤ ~800 — R32.)
- **R13** — No XML angle brackets (`<` or `>`) anywhere in frontmatter — it is
  injected into the system prompt and brackets are a prompt-injection vector.
  **Exception:** a command's `argument-hint` may use the documented
  `<placeholder>` / `[optional]` syntax — it is a CLI usage hint rendered to the
  user, not instruction text folded into the model's context.
- **R14** — Optional fields when useful: `license`, `compatibility` (1–500 chars,
  environment needs), `allowed-tools` (restrict tool access), `metadata`
  (author/version/mcp-server/tags/etc.).

## 5. Writing the description

- **R15** — Pattern: **[what it does] + [when to use it] + [key capabilities]**,
  with literal trigger phrases in quotes.
- **R16** — Reject these: too vague ("Helps with projects"), missing triggers,
  or purely technical with no user-facing trigger. The description is how the
  router decides to load you — write it for the router, not for engineers.

## 6. Writing the instructions (SKILL.md body)

- **R17 — Be specific and actionable.** Give the exact command and the expected
  output; "validate the data before proceeding" is not an instruction. Show what
  success looks like.
- **R18 — Put critical instructions first**, under explicit `## Important` /
  `## Critical` headers. Buried or verbose instructions get skipped.
- **R19 — Include error handling**: the common failure, its cause, and the fix.
- **R20 — Prefer code over prose for anything that must be exact.** Bundle a
  script for critical validations — code is deterministic; language
  interpretation isn't.
- **R21 — Keep `SKILL.md` lean** and push detail into `references/`, linking to
  it. (Guide cap: < 5,000 words. Local cap: ~100 lines — R32.)

## 7. Design before code

- **R22** — Start by writing **2–3 concrete use cases**: trigger → steps →
  result. Answer: what does the user want, what multi-step workflow it needs,
  which tools (built-in or MCP), what domain knowledge to embed.
- **R23 — Define success criteria up front** (aspirational, not precise):
  triggers on ~90% of relevant queries; completes in fewer tool calls / tokens
  than the no-skill baseline; zero failed tool calls; no user correction needed.

## 8. Testing

- **R24 — Iterate on ONE hard task until it succeeds, then extract the skill.**
  In-context learning on a single case gives faster signal than broad testing.
- **R25 — Test triggering**: fires on obvious tasks AND paraphrases; does NOT
  fire on unrelated topics. Maintain a should-trigger / should-NOT-trigger list.
- **R26 — Test function**: valid outputs, tool calls succeed, error handling
  works, edge cases covered.
- **R27 — Prove value vs. baseline**: compare the same task with and without the
  skill (messages, failed calls, tokens).
- **R28 — Debug triggering** by asking Claude "When would you use the [skill]
  skill?" — it quotes the description back; fix what's missing.

## 9. Tuning trigger rate

- **R29 — Under-triggering** (skill doesn't load when it should) → add detail and
  trigger keywords to the description, especially technical terms.
- **R30 — Over-triggering** (loads for irrelevant queries) → add negative
  triggers ("Do NOT use for X — use Y instead"), narrow scope, be more specific.

## 10. Distribution & context hygiene

- **R-Dist** — For sharing: host on GitHub with a **repo-level** README (for
  humans — distinct from the skill folder), example usage, and an install guide.
  Position by **outcome, not features**.
- **R-Ctx** — If responses degrade: shrink `SKILL.md` (move docs to
  `references/`), and don't keep an excessive number of skills enabled at once.
  Prefer progressive disclosure over inlining everything.

---

## Local divergences (this repo)

This repo enforces conventions that **override or tighten** the guide. Follow
these here; `scripts/validate.sh` is the deterministic gate.

- **R31 — `when_to_use` is a required frontmatter field.** The guide folds "when"
  into `description`; this repo additionally requires a separate `when_to_use`
  key (enforced by `validate.sh`). Keep triggers explicit in both.
- **R32 — Tighter size caps.** Local review rubric caps `SKILL.md` at **~100
  lines** and descriptions at **~800 chars** (vs. the guide's 5,000 words /
  1024 chars). Follow the stricter local cap.
- **R33 — In-skill `README.md` is a known divergence.** The guide says *do not*
  put a `README.md` inside a skill folder (docs go in `SKILL.md`/`references/`);
  several skills here ship one. Prefer `SKILL.md` + `references/` for new skills;
  existing in-skill READMEs are a cleanup candidate, not a pattern to copy.
- **R34 — Reciprocal routing.** Beyond the guide's negative-trigger advice, this
  repo requires cross-references between contending skills to be **reciprocal**:
  if A deflects to B on a shared trigger, B must deflect back. (See the
  `skill-library-review` rubric and `.claude/rules/`.)
- **R35 — Tiered review.** Skill-quality findings follow `.claude/rules/review-tiers.md`:
  only deterministic (`validate.sh`) checks gate; LLM-judgment findings are
  advisory and go to the findings ledger. A "should-fix" without deterministic
  evidence proposes; it does not block.
- **R36 — Distribution here is the pinned-release flow**, not Claude.ai upload:
  changes land via PR → `validate.sh` → `scripts/release.sh` (content-addressed
  tarball + digest pin). See `RELEASING.md`.

---

## Quick checklist

**Before you start** — 2–3 concrete use cases · tools identified · folder
structure planned.

**During development** — folder kebab-case · `SKILL.md` exact spelling · `---`
frontmatter delimiters · `name` kebab-case == folder · `description` has WHAT +
WHEN · `when_to_use` present (local) · no `<`/`>` anywhere · instructions
specific & actionable · error handling · examples · references linked ·
`SKILL.md` within the local size cap.

**Before merge** — triggers on obvious + paraphrased queries · does NOT trigger
on unrelated topics · functional tests pass · `bash scripts/validate.sh` green ·
reciprocal cross-refs resolve.

**After merge** — watch for under/over-triggering · refine description &
instructions · bump `metadata.version` · log recurring advisory findings to the
ledger.

---

*Source: Anthropic, "The Complete Guide to Building Skills for Claude" (2026).
This file canonizes that guidance for this repository; where the two differ, the
[Local divergences](#local-divergences-this-repo) section and `scripts/validate.sh`
are authoritative.*
