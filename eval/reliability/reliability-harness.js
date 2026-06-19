// reliability-harness — the RELIABILITY experiment runner.
//
// Question it answers: does a review-loop produce MORE RELIABLE Rust than a
// single pass? "Reliable" here is DETERMINISTIC — every unit is scored by a
// HIDDEN held-out test suite (eval/reliability/hidden/<fixtureId>.rs) via
// check-hidden-tests.sh. There is NO LLM judge in this harness; the JSON line
// the checker emits IS the verdict.
//
// Shape: a flat list of UNITS = fixtures × arms × repeats is run through
// pipeline(units, produceStage, checkStage). Each unit is one independent
// (fixture, arm, repeat) trial. Repeats let the aggregator measure variance —
// the floor and defect-rate that single-pass-vs-review actually move.
//
// The three arms:
//   - "baseline"     — one-pass general-purpose producer, no library/skills.
//   - "self-review"  — general-purpose producer that implements, then critiques
//                      its OWN code once and revises. Still no library/skills.
//   - "pod"          — the v2-collab collaboration pod (technical-pm → engineer
//                      → reviewer), maxRounds 4. The review-loop arm under test.
//
// Sandbox constraints honored here (mirrors eval-harness.js):
//   - NO filesystem access from the workflow itself. Every write/exec is
//     delegated to a sub-agent (which has Write/Bash). Fixtures arrive as
//     OBJECTS already read from disk by the calling command.
//   - Math.random() and Date.now() THROW in this sandbox. ALL variation
//     (per-unit artifact paths) is derived from indices — fixtureId/arm/repeat —
//     never RNG, never wall-clock.
//   - args may arrive as an object OR a JSON-encoded string (mirrors v2-collab).
//
// args: {
//   fixtures: [<fixture object>...],   // { id, signature, crate_name, task }
//   arms?: ["baseline","self-review","pod"],
//   repeats?: 5,
//   runId: string,
// }

export const meta = {
  name: "reliability-harness",
  description:
    "Reliability experiment runner: for each (fixture, arm, repeat) unit it produces a Cargo library crate named `solution` (baseline one-pass, self-review one-pass-plus-revise, or the v2-collab review-loop pod), then runs the HIDDEN held-out test suite via check-hidden-tests.sh and records the deterministic per-unit score (total/passed/failed/failures). No LLM judge — the checker JSON is the verdict. Returns one record per unit for the command to materialize and aggregate into defect-rate / clean-rate / floor.",
  phases: [{ title: "Produce" }, { title: "Check" }],
};

// --- StructuredOutput schemas (flat objects; NO top-level allOf/oneOf/anyOf,
//     which 400 the StructuredOutput endpoint and come back empty). -----------

// A producer (or the pod-materializer) returns the crate ROOT DIR it wrote —
// the directory containing Cargo.toml, so the checker can run cargo test.
const PRODUCE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["artifact_path"],
  properties: {
    artifact_path: {
      type: "string",
      description:
        "Absolute path of the crate ROOT DIRECTORY this unit wrote — the directory that DIRECTLY contains Cargo.toml (with src/lib.rs under it). NOT the Cargo.toml file, NOT src/. The unique directory created under this unit's assigned run path. Empty string if nothing was written.",
    },
  },
};

// The checker sub-agent returns the parsed single JSON line from
// check-hidden-tests.sh, plus a `produced` flag the stage sets.
const CHECK_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["total", "passed", "failed", "failures", "produced"],
  properties: {
    total: {
      type: ["integer", "null"],
      description:
        "The `total` field from the checker JSON line (number of hidden tests). null if the checker exited 2 (env-skip, no JSON emitted) or produced no parseable line.",
    },
    passed: {
      type: "integer",
      description:
        "The `passed` field from the checker JSON line. 0 on compile-defect or when nothing ran.",
    },
    failed: {
      type: ["integer", "null"],
      description:
        "The `failed` field from the checker JSON line. null if the checker exited 2 / emitted no JSON.",
    },
    failures: {
      type: "array",
      items: { type: "string" },
      description:
        "The `failures` array from the checker JSON line (failing test names, or [\"compile-error\"] on a build defect). Empty array if all passed or none ran.",
    },
    produced: {
      type: "boolean",
      description:
        "True IFF a crate directory existed and the checker was actually dispatched against it. False only when the produce stage reported no artifact.",
    },
  },
};

// --- helpers ---------------------------------------------------------------

// Quote a path for safe single-shell-token interpolation into the checker
// command the sub-agent runs. The crate dir is a /private/tmp path we built
// from validated runId/fixtureId/arm/repeat, but belt-and-braces.
function shellSingleQuote(s) {
  return `'${String(s).replace(/'/g, `'\\''`)}'`;
}

// The crate convention EVERY arm prompt must carry: a library crate named
// `solution`, Cargo.toml [package] name="solution", src/lib.rs exposing the
// fixture's exact signature, no deps, builds offline.
function crateConvention(fixture, crateDir) {
  return [
    "## CRATE CONVENTION (required — the hidden test suite depends on it)",
    "Write a Cargo LIBRARY crate named `solution`:",
    '- Cargo.toml with `[package]` `name = "solution"` and NO external dependencies (must build offline).',
    "- `src/lib.rs` that exposes EXACTLY this public item (same name, same signature):",
    "",
    `    ${fixture.signature}`,
    "",
    `Write Cargo.toml and src/lib.rs UNDER the directory ${crateDir} (mkdir -p it).`,
    "RETURN the crate ROOT DIRECTORY — the directory that directly contains Cargo.toml.",
    "Do NOT write anywhere else; do NOT touch the live .claude tree or the repo.",
  ].join("\n");
}

// Per-arm extra instruction appended to the task + crate convention.
const ARM_INSTRUCTION = {
  baseline:
    "Write the crate in ONE pass. Do NOT read/load/invoke any library skills, subagents, or /-commands.",
  "self-review":
    "First implement it. THEN critically review your OWN code for edge cases, boundary bugs, panics, and missed requirements, and revise once to fix what you find. Do NOT use any library skills, subagents, or /-commands.",
};

// --- args parse / validate -------------------------------------------------

let input = args || {};
if (typeof input === "string") {
  try {
    input = JSON.parse(input);
  } catch {
    throw new Error(
      "reliability-harness: args arrived as a string that is not valid JSON; pass { fixtures, arms, repeats, runId } as an object."
    );
  }
}

const fixtures = Array.isArray(input.fixtures) ? input.fixtures : null;
const arms =
  Array.isArray(input.arms) && input.arms.length > 0
    ? input.arms
    : ["baseline", "self-review", "pod"];
const repeats =
  Number.isInteger(input.repeats) && input.repeats > 0 ? input.repeats : 5;
const runId = input.runId;

if (!fixtures || fixtures.length === 0) {
  throw new Error(
    "reliability-harness: args.fixtures must be a non-empty array of fixture objects (read from disk by the command)."
  );
}
if (!runId || !/^[a-z0-9-]+$/.test(String(runId))) {
  throw new Error(
    "reliability-harness: args.runId must be a short id matching ^[a-z0-9-]+$ (used in the artifact path)."
  );
}
for (const f of fixtures) {
  if (!f || typeof f.id !== "string" || !/^[a-z0-9-]+$/.test(f.id)) {
    throw new Error(
      "reliability-harness: every fixture needs an id matching ^[a-z0-9-]+$ (used in the artifact path and hidden-test path)."
    );
  }
  if (typeof f.signature !== "string" || typeof f.task !== "string") {
    throw new Error(
      `reliability-harness: fixture ${f.id} is missing a string signature or task.`
    );
  }
}
const KNOWN_ARMS = new Set(["baseline", "self-review", "pod"]);
for (const a of arms) {
  if (!KNOWN_ARMS.has(a)) {
    throw new Error(
      `reliability-harness: unknown arm "${a}"; expected one of baseline | self-review | pod.`
    );
  }
}

// --- build the FLAT unit list: fixtures × arms × repeats -------------------
// repeat index r is 0-based here; it appears as r<repeat> (r0..r{repeats-1}) in
// the path. All variation is index-derived — no RNG, no clock.
const units = [];
for (const fixture of fixtures) {
  for (const arm of arms) {
    for (let repeat = 0; repeat < repeats; repeat++) {
      units.push({ fixture, arm, repeat });
    }
  }
}

// --- stages ----------------------------------------------------------------

// produceStage: write the `solution` crate for this unit, return its root dir
// (or null on a genuine produce failure — never a placeholder).
async function produceStage(unit, _orig, _index) {
  const { fixture, arm, repeat } = unit;
  phase("Produce");
  const crateDir = `/private/tmp/eval-run/reliability-${runId}/${fixture.id}/${arm}/r${repeat}`;
  const label = `produce:${fixture.id}:${arm}:r${repeat}`;
  const convention = crateConvention(fixture, crateDir);

  if (arm === "pod") {
    // The review-loop arm: run the v2-collab pod (one level of nesting is
    // allowed from a top-level workflow). Pass the CLEAN task + crate
    // convention — NOT a disk-write instruction: the pod accumulates its
    // deliverable in an in-memory artifact map and does not write files. (A
    // disk-write prompt confuses the pod's agents — the empty-artifact bug.)
    const podTask = [
      fixture.task.trim(),
      "",
      convention,
      "",
      "Produce the COMPLETE crate as file(s) in your artifact (artifact_edits):",
      "Cargo.toml and src/lib.rs (use those exact relative filenames). The",
      "reviewer gates on the finished file content; put the real content in the files.",
    ].join("\n");

    const podResult = await workflow("v2-collab", { task: podTask, maxRounds: 4 });
    const podArtifact =
      podResult && podResult.artifact && typeof podResult.artifact === "object"
        ? podResult.artifact
        : {};
    const fileNames = Object.keys(podArtifact);

    if (fileNames.length === 0) {
      // Genuine produce FAILURE. Record no artifact — do NOT substitute a
      // placeholder, which would then be scored as if it were the pod's real
      // output (this was a real bug — never substitute).
      log(`[${fixture.id}/${arm}/r${repeat}] pod returned NO artifact — produce failure`);
      return { unit, crateDir: null };
    }

    // The pod cannot write to disk; a sub-agent (has Write/Bash) materializes
    // the map faithfully under crateDir and reports the crate root.
    const materialize = await agent(
      [
        `The v2-collab pod produced the crate file(s) below for fixture "${fixture.id}",`,
        `arm "pod", repeat r${repeat}.`,
        `Create ${crateDir} (mkdir -p) and write EACH file faithfully under it at its`,
        `given relative filename — its EXACT bytes, do not edit, reformat, or`,
        `summarize. If a filename contains a slash (e.g. src/lib.rs) create the`,
        `subdirectories. The crate must end up with Cargo.toml at ${crateDir}/Cargo.toml`,
        `and src/lib.rs at ${crateDir}/src/lib.rs.`,
        `Then RETURN the crate ROOT DIRECTORY: ${crateDir}. Do not write anywhere`,
        `else; do not invent or add content not in the artifact.`,
        "",
        "## ARTIFACT (filename -> content)",
        JSON.stringify(podArtifact),
        "",
        "Return ONLY { artifact_path } — the crate root directory you wrote into.",
      ].join("\n"),
      {
        agentType: "general-purpose",
        schema: PRODUCE_SCHEMA,
        label,
        phase: "Produce",
      }
    );
    const dir =
      materialize && materialize.artifact_path ? materialize.artifact_path : null;
    log(`[${fixture.id}/${arm}/r${repeat}] crate: ${dir || "(none)"}`);
    return { unit, crateDir: dir };
  }

  // baseline / self-review: a single general-purpose producer writes the crate.
  const producePrompt = [
    "## TASK",
    fixture.task.trim(),
    "",
    convention,
    "",
    "## ARM-SPECIFIC INSTRUCTION",
    ARM_INSTRUCTION[arm],
    "",
    "## OUTPUT",
    "Return ONLY { artifact_path } — the crate ROOT DIRECTORY you wrote (the one containing Cargo.toml).",
  ].join("\n");

  const produced = await agent(producePrompt, {
    agentType: "general-purpose",
    schema: PRODUCE_SCHEMA,
    label,
    phase: "Produce",
  });
  const dir = produced && produced.artifact_path ? produced.artifact_path : null;
  log(`[${fixture.id}/${arm}/r${repeat}] crate: ${dir || "(none)"}`);
  return { unit, crateDir: dir };
}

// checkStage: run the HIDDEN suite against the produced crate; record the
// deterministic score. One record per unit.
async function checkStage(prev, unit, _index) {
  phase("Check");
  const { fixture, arm, repeat } = unit;
  const crateDir = prev ? prev.crateDir : null;
  const base = { run: runId, fixture: fixture.id, arm, repeat };

  if (!crateDir) {
    // Produce failed -> nothing to check. no-artifact is a defect for scoring,
    // not an env-skip: total stays null but the aggregator treats it as 0/floor.
    log(`[${fixture.id}/${arm}/r${repeat}] check: skipped (no artifact)`);
    return {
      ...base,
      produced: false,
      total: null,
      passed: 0,
      failed: null,
      failures: ["no-artifact"],
    };
  }

  const hiddenRs = `eval/reliability/hidden/${fixture.id}.rs`;
  const cmd = `EVAL_ALLOW_CODE_EXEC=1 bash eval/reliability/check-hidden-tests.sh ${shellSingleQuote(
    crateDir
  )} ${shellSingleQuote(hiddenRs)}`;

  const verdict = await agent(
    [
      "Run EXACTLY this one command from the repo root and capture the SINGLE",
      "JSON line it prints to stdout (and its exit code):",
      "",
      `  ${cmd}`,
      "",
      "The checker contract (check-hidden-tests.sh):",
      '- On a run (green OR red OR compile-defect) it exits 0 and prints ONE JSON',
      '  line: {"total":N,"passed":P,"failed":F,"failures":["test_name",...]}.',
      "  A build defect scores as total=<#tests>, passed=0, failures=[\"compile-error\"].",
      "- On an environment-skip (cargo missing, EVAL_ALLOW_CODE_EXEC unset, timeout)",
      "  it exits 2 and prints NO JSON line (only a SKIP message on stderr).",
      "",
      "Return the parsed JSON line as { total, passed, failed, failures, produced }:",
      "- Copy total/passed/failed/failures verbatim from the JSON line.",
      "- If the checker exited 2 / printed no JSON line, return total:null, passed:0,",
      "  failed:null, failures:[\"env-skip\"].",
      "- ALWAYS set produced:true (a crate directory existed and you ran the checker).",
      "Do NOT run any other command; do NOT modify the crate or the hidden file.",
    ].join("\n"),
    {
      agentType: "general-purpose",
      schema: CHECK_SCHEMA,
      label: `check:${fixture.id}:${arm}:r${repeat}`,
      phase: "Check",
    }
  );

  if (!verdict) {
    log(`[${fixture.id}/${arm}/r${repeat}] check: dispatch failed`);
    return {
      ...base,
      produced: true,
      total: null,
      passed: 0,
      failed: null,
      failures: ["check-dispatch-failed"],
    };
  }

  const total = Number.isInteger(verdict.total) ? verdict.total : null;
  const passed = Number.isInteger(verdict.passed) ? verdict.passed : 0;
  const failed = Number.isInteger(verdict.failed) ? verdict.failed : null;
  const failures = Array.isArray(verdict.failures) ? verdict.failures : [];
  log(
    `[${fixture.id}/${arm}/r${repeat}] check: ${passed}/${total ?? "?"} passed` +
      (failures.length ? ` (failures: ${failures.join(", ")})` : "")
  );
  return { ...base, produced: true, total, passed, failed, failures };
}

const results = await pipeline(units, produceStage, checkStage);

return results;
