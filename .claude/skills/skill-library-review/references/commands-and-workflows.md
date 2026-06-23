# Commands and Workflows

Two artifact types beyond skills and agents. Both have frontmatter the loader
keys off, but their bodies are *executable* — a command body is a prompt the
harness runs, a workflow body is a JS program. Review them for what they
actually do, not just how they're described.

## Slash commands (`.claude/commands/*.md`)

A command is a markdown file: YAML frontmatter, then a prompt body the harness
runs when the user types `/<name>`. The filename is the command name.

### `description` — required

- One line, shown in `/help`. Same third-person, WHAT+WHEN posture as a skill
  description, but shorter — it's a menu entry, not a routing surface.
- Missing or empty → **blocking** (the command is invisible in `/help`).

### `argument-hint` — required when the body consumes args

- The body addresses arguments as `$ARGUMENTS` (all of them) or `$1`, `$2`
  (positional). If the body uses any of these, `argument-hint` must be present
  so `/help` shows the user what to pass — e.g. `argument-hint: <skill-name>`.
- Body uses `$1`/`$ARGUMENTS` but no `argument-hint` → **should-fix**.
- `argument-hint` present but the body never references an argument →
  **should-fix** (hint promises an input the command ignores).
- The hint should name what the body actually reads. A hint of `<skill-name>`
  while the body validates `$1` as kebab-case is coherent; a hint that names a
  different shape than the body parses is a finding.

### `allowed-tools` — minimal and sufficient

- Lists the tools the command body is permitted to invoke. Must cover what the
  body actually does, and nothing more.
- **CRITICAL — dispatch tool name is platform-specific.** This repo's `.claude/commands/` run on **Claude Code** only (not shipped on Cursor). There the subagent-spawn tool is **`Agent`** (see agent `tools:` fields and [tool-allowlists.md](tool-allowlists.md)). An `allowed-tools` that lists `Task` instead of `Agent` is a **blocking** finding for a Claude Code command — the body's "dispatch via Agent" step silently fails. On **Cursor**, consumer orchestration uses the **`Task`** tool instead; do not flag `Task` in Cursor-only docs as a defect.
- Body dispatches a subagent on Claude Code but `allowed-tools` omits `Agent` → **blocking**
  (the dispatch can't run).
- Body writes a file but `allowed-tools` omits `Write`/`Edit` → **blocking**.
- `allowed-tools` lists a tool the body never uses → **should-fix** (over-broad
  grant; trim to what the body invokes).
- A command whose body says "run the workflow via the `Workflow` tool" must list
  `Workflow`; one that greps for collisions must list `Glob`/`Grep`.

### Body coherence

- Every `$1`/`$ARGUMENTS` the hint promises must be used; every tool the body
  invokes must be in `allowed-tools`. The body is the source of truth — review
  the frontmatter *against* it, not in isolation.

## Workflows (`.claude/workflows/*.js`)

A workflow is a JS program the `Workflow` tool runs. It declares a `meta`
object and calls harness hooks: `phase()`, `agent()`, `pipeline()`,
`parallel()`, `log()`.

### `export const meta` — pure literal

- `meta` MUST be a plain object literal — `name`, `description`, `phases` set to
  literal strings/arrays. No variables, function calls, template interpolation,
  or computed keys. The harness reads `meta` *statically* to register the
  workflow; a non-literal value (`name: SOME_CONST`, `phases: buildPhases()`)
  can't be read before execution → **blocking**.
- `meta.name` must match how the workflow is invoked (the command that runs it
  passes `name: "<this>"` to the `Workflow` tool, and the filename matches).
  Mismatch is a silent misroute — **blocking**.
- `meta.phases[].title` should line up with the phases the body actually runs.
  A phase counts as *entered* if the body reaches it **either** via a top-level
  `phase("X")` marker **or** via a `{ phase: "X" }` option on an `agent()` /
  `pipeline()` / `parallel()` stage call (per-stage phase assignment is a
  deliberate pattern — a stage agent bounds its own phase, so no top-level
  `phase()` call exists for it). A phase declared in `meta` but entered by
  *neither* mechanism (or a phase entered in the body but absent from `meta`) is
  a **should-fix** — the declared shape lies about the run. Grep the body for
  both `phase("X")` and `phase: "X"` before flagging.

### `node --check` must pass

- The file must parse: `node --check .claude/workflows/<name>.js`. A syntax
  error → **blocking** (the workflow won't load). Run it; don't eyeball it.

### Schema-validated `agent()` outputs

- `agent(prompt, { schema })` validates the agent's JSON output against
  `schema`. Downstream code may then read **only** the fields the schema
  guarantees (`required` + declared `properties`). Reading a field the schema
  doesn't declare (`result.foo` where `foo` isn't in `properties`) is a
  **should-fix** — it's `undefined` at runtime and the schema won't catch it.
- A `required` field is always present; an optional one may be absent — guard it
  before deref. Dereferencing a non-required field without a guard → **should-fix**.

### Determinism

- Labels passed to `agent()` should be unique and derived from stable inputs
  (index, skill slug), not `Date.now()`/`Math.random()` — nondeterministic
  labels make runs hard to compare. Random/time-based labels → **nit**.

## What is NOT a finding

- A command with no `argument-hint` whose body genuinely takes no arguments —
  correct, not incomplete.
- A workflow `phase()` whose title paraphrases (not exact-matches) the `meta`
  title, as long as the sequence corresponds. Demand correspondence, not
  string equality.
- A `meta` phase with no top-level `phase("X")` call but which IS entered via a
  `{ phase: "X" }` option on a stage `agent()`/`pipeline()`/`parallel()` call —
  correct (per-stage phase assignment), not a missing phase.
- An `allowed-tools` that looks broad but every listed tool is actually invoked
  somewhere in the body. Verify against the body before flagging over-grant.
