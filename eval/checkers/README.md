# Deterministic checkers (Tier-0 spine)

Each checker takes a produced artifact and renders a **deterministic** PASS/FAIL
verdict — same input, same verdict, every run. This is the only tier permitted
to gate an eval arm. Semantic quality (taste, routing, prose) is the blind judge
panel's job, not these scripts'.

The eval runner calls **one entrypoint**, identically for both arms of a fixture
(library-ON and baseline), so neither arm gets a different bar.

## The contract

```
run-checker.sh <kind> <artifact_path_or_dir> [extra checker args...]
```

`run-checker.sh` maps a **frozen** `kind` to a concrete checker, runs it, and
passes the checker's exit code and one-line stdout verdict straight through.

### Frozen kind vocabulary

This vocabulary is pinned across the parallel eval tasks. **Do not extend it**
without changing the contract in the plan.

| `kind`                       | checker script              | what it verifies |
| ---------------------------- | --------------------------- | ---------------- |
| `validate-library-artifact`  | `check-library-artifact.sh` | a SKILL.md / agent passes `scripts/validate.sh` |
| `cargo-test`                 | `check-code-compiles.sh`    | a Rust artifact builds + tests green |
| `schema-match`               | `check-schema-match.sh`     | a text/HTML/md/json artifact has required structure |

Legacy alias: `validate.sh` is accepted as a synonym for
`validate-library-artifact` (existing fixtures use the old `kind` value). An
unknown `kind` exits **2** with an error.

### Exit-code semantics (uniform across every checker)

| exit | meaning   | when |
| ---- | --------- | ---- |
| `0`  | **PASS**  | the artifact satisfied the check |
| `1`  | **FAIL**  | the artifact was produced but did not satisfy the check |
| `2`  | **SKIP / could-not-run** | missing artifact, missing toolchain, no patterns, unknown kind — an *environment* problem, NOT an artifact verdict |

The `2` ("could-not-run") code is deliberately distinct from `1` ("FAIL"). A
checker that cannot run — e.g. `cargo` is not installed — **never silently
passes** and never reports FAIL; it exits 2 so the runner can record an
environment-skip instead of charging the arm with a failure it never earned.

Every checker prints exactly one verdict line on stdout, prefixed `PASS` /
`FAIL` / `SKIP`.

## The checkers

### `check-library-artifact.sh <artifact>` — `validate-library-artifact`

Stages the produced artifact into a **fresh copy of the repo's live `.claude`
tree**, then runs `bash scripts/validate.sh <stage>`. PASS iff `validate.sh`
exits 0. The staging approach: copy the live `.claude` tree into a temp dir, drop
the artifact under `skills/<validated-slug>/SKILL.md` (or `agents/<validated-name>.md`),
then run the validator against that staged tree.

The artifact is untrusted (model-generated), so staging is hardened: any symlink
in the artifact tree is **rejected** (exit 2) before copying — `cp -R` would
otherwise follow it and write through into the live `.claude`; the destination
slug/basename is derived from untrusted frontmatter `name:` / filename and must
match `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$` (no slashes, `..`, or dots) or it is
rejected before any `mkdir`/`cp`; and the composed destination's realpath is
asserted to stay under `<stage>/.claude`.

`<artifact>` may be:
- a **directory** mirroring a `.claude` subtree (its contents are overlaid onto
  `<stage>/.claude`), e.g. `<dir>/skills/<slug>/SKILL.md` or `<dir>/agents/<name>.md`;
- a single **`SKILL.md`** — staged at `<stage>/.claude/skills/<slug>/SKILL.md`,
  where `<slug>` is read from the artifact's own `name:` frontmatter;
- a single **agent `<name>.md`** — staged at `<stage>/.claude/agents/<name>.md`.

The staging dir is a temp dir, cleaned up on exit; the live tree is never
mutated.

### `check-code-compiles.sh <artifact>` — `cargo-test`

For a Rust artifact the build+test *is* the check.
- Directory with `Cargo.toml` → `cargo test` in it; PASS iff green.
- Directory without `Cargo.toml` → `rustc` compile-only of every discovered
  `.rs` file; PASS iff all compile (no Cargo harness to run).
- Single `.rs` file → `rustc` compile-only of that file.

If the needed toolchain (`cargo` / `rustc`) is absent, exits **2**
(environment-skip) — it does not pretend the code built.

### `check-schema-match.sh <artifact> [patterns...]` — `schema-match`

Asserts an artifact contains every required structural pattern. Generic enough
for both `claims-doc` and `pod-deliverable` output types. Each pattern is an
extended regex (`grep -E`) matched against the whole artifact; PASS iff every
pattern matches at least once.

Patterns come from, in priority order:
1. extra CLI args: `check-schema-match.sh <artifact> '^## Assumptions' '^## Conclusion'`
2. a sidecar file: `check-schema-match.sh <artifact> --patterns <file>` (one
   pattern per line; blank lines and `#` comments ignored);
3. a conventional sidecar with no args: `<artifact>.patterns` (for a file) or
   `<dir>/.patterns` (for a directory).

For a directory artifact the search spans all files under it. For a `.json`
artifact, a pattern written as `jq:<filter>` is evaluated as a `jq` existence
check (truthy, non-null) instead of regex — lets a JSON deliverable assert
structural keys precisely. (`jq:` patterns exit 2 if `jq` is unavailable or the
artifact is not JSON.)

If no patterns are supplied by any route, exits **2** — there is nothing to
check against.

## Adding a new checker

The `kind` vocabulary is frozen for the current eval; adding a checker is a
contract change, not a drop-in. When that change is sanctioned:

1. Write `check-<thing>.sh` honoring the uniform contract: take the artifact as
   `$1`, print one `PASS`/`FAIL`/`SKIP` line, exit `0`/`1`/`2` accordingly.
   Bash only (Node is fine for JSON parsing helpers; never Python — repo rule).
2. Make it `chmod +x`.
3. Add a `case` arm in `run-checker.sh` mapping the new `kind` to it.
4. Update this table and the frozen-vocabulary note in the plan.
5. Demonstrate it: a known-good sample exits 0, a known-bad sample exits 1, and
   a could-not-run condition exits 2.
