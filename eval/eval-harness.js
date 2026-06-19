// eval-harness — the comparative eval runner (task T-runner).
//
// Wires the two-arm comparative harness end to end. For each fixture it:
//   1. PRODUCE — runs BOTH arms (library + baseline) and captures each arm's
//      written artifact path.
//   2. CHECK   — runs the Tier-0 deterministic checker (run-checker.sh) on each
//      arm's artifact and records PASS/FAIL per arm.
//   3. JUDGE   — dispatches a blind pairwise judge panel (N=judges, default 3),
//      position-randomized WITHOUT RNG (alternated on the judge index), then
//      aggregates per dimension by MAJORITY winner + MEDIAN margin and records
//      the verdicts in the run's canonical A=library / B=baseline frame with a
//      blinding_map, so eval/aggregate/aggregate.mjs recovers arms correctly.
//
// Returns an array of result objects, one per fixture, each conforming EXACTLY
// to eval/schema/result.schema.json. The calling command materializes them to
// eval/results/<runId>.jsonl and runs the aggregator.
//
// Sandbox constraints honored here:
//   - NO filesystem access from the workflow itself. Every read/write/exec is
//     delegated to a subagent (which has Read/Bash). The fixtures are passed in
//     as OBJECTS already read from disk by the command.
//   - Math.random() and Date.now() THROW in this sandbox. ALL variation
//     (position randomization, per-arm artifact paths) is derived from indices,
//     never RNG.
//
// args: { fixtures: [<fixture object>...], runId: string, judges?: 3 }

export const meta = {
  name: "eval-harness",
  description:
    "Comparative eval runner: for each two-arm fixture it produces both arms (library + baseline), applies the Tier-0 deterministic checker to each, then runs a blind position-randomized pairwise judge panel and aggregates per dimension by majority/median. Returns one result-schema record per fixture for the command to materialize and aggregate.",
  phases: [
    { title: "Produce" },
    { title: "Check" },
    { title: "Judge" },
  ],
};

// --- StructuredOutput schemas (flat objects; NO top-level allOf/oneOf/anyOf,
//     which 400 the StructuredOutput endpoint and come back empty). -----------

// One producer returns the EXACT path of the artifact it wrote.
const PRODUCE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["artifact_path"],
  properties: {
    artifact_path: {
      type: "string",
      description:
        "Absolute path of the single artifact file this arm wrote. For a library-skill this is the SKILL.md FILE path (not its directory) — the checker stages the file. The path must be the unique one created under the assigned arm directory.",
    },
  },
};

// One checker sub-agent returns the deterministic verdict for one arm.
const CHECK_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["pass", "note"],
  properties: {
    pass: {
      type: "boolean",
      description:
        "True IFF run-checker.sh exited 0 (PASS). Exit 1 (FAIL) and exit 2 (skip/could-not-run) are both false.",
    },
    note: {
      type: "string",
      description:
        "The checker's one-line stdout verdict, or 'skipped' when the checker exited 2 (could-not-run).",
    },
  },
};

// One blind judge returns the judge-output.schema.json shape (per_dimension +
// overall). evidence is carried at this layer only; the aggregator drops it.
const JUDGE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["per_dimension", "overall"],
  properties: {
    per_dimension: {
      type: "array",
      minItems: 1,
      description:
        "One verdict per rubric dimension, in the order presented. dimension keys join to the rubric.",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["dimension", "winner", "margin", "evidence"],
        properties: {
          dimension: { type: "string", description: "Rubric dimension key." },
          winner: {
            type: "string",
            enum: ["A", "B", "tie"],
            description: "Blind winner for this dimension in A/B terms only.",
          },
          margin: {
            type: "number",
            minimum: 0,
            maximum: 1,
            description: "Normalized 0..1 margin; 0 when winner is 'tie'.",
          },
          evidence: {
            type: "string",
            description:
              "One-line justification quoting the deciding text. No quote -> record 'tie'.",
          },
        },
      },
    },
    overall: {
      type: "object",
      additionalProperties: false,
      required: ["winner", "margin"],
      properties: {
        winner: {
          type: "string",
          enum: ["A", "B", "tie"],
          description: "Blind overall winner in A/B terms.",
        },
        margin: {
          type: "number",
          minimum: 0,
          maximum: 1,
          description: "Normalized 0..1 overall margin; 0 when winner is 'tie'.",
        },
      },
    },
  },
};

// --- helpers ---------------------------------------------------------------

// Quote a path/string for safe single-shell-token interpolation into a command
// the checker sub-agent runs. The runId/fixtureId are validated upstream; this
// is belt-and-braces for the artifact path the producer reports back.
function shellSingleQuote(s) {
  return `'${String(s).replace(/'/g, `'\\''`)}'`;
}

// Build the produce prompt for one arm. The producer must WRITE its artifact to
// a unique path under the assigned arm directory and RETURN that exact path.
function buildProducePrompt(fixture, armName, armDir, armPrompt) {
  return [
    "## TASK (produce the deliverable below)",
    fixture.task.trim(),
    armPrompt && armPrompt.trim() ? `\n## ARM-SPECIFIC INSTRUCTION\n${armPrompt.trim()}` : "",
    "",
    "## WHERE TO WRITE THE ARTIFACT",
    `Create the directory ${armDir} (mkdir -p) and write your artifact to a unique`,
    `file path UNDER it. For a library skill, write the single SKILL.md and RETURN`,
    `the SKILL.md FILE path itself (e.g. ${armDir}/SKILL.md) — the checker stages the`,
    `file, not a directory. For a Rust crate, write Cargo.toml + src/ under that`,
    `directory and RETURN THE CRATE ROOT DIRECTORY (the one containing Cargo.toml) so`,
    `the checker can run \`cargo test\`. For any other deliverable, return the primary`,
    `file you want checked. Do NOT write anywhere else; do NOT touch the live .claude`,
    `tree or the repo.`,
    "",
    "## OUTPUT",
    "Return ONLY { artifact_path } — the exact absolute path you wrote.",
  ]
    .filter(Boolean)
    .join("\n");
}

// Build the blind judge prompt. Per pairwise-judge-protocol.md: the judge gets
// the task, the rubric dimensions, and TWO neutrally labelled artifact PATHS to
// read — and NOTHING that identifies an arm (no arm names, notes, prompts, or
// deterministic verdicts).
function buildJudgePrompt(fixture, pathForA, pathForB) {
  const dims = fixture.rubric.dimensions
    .map((d) => `- \`${d.key}\` (max ${d.max}): ${d.asks}`)
    .join("\n");
  return [
    "You are an impartial judge comparing two outputs for the same task. You do",
    "not know who or what produced either output, and you must not speculate about it.",
    "",
    "## Task that both outputs were asked to satisfy",
    fixture.task.trim(),
    "",
    "## Rubric — score each dimension independently; `asks` is the question you answer",
    dims,
    "",
    "## The two outputs",
    `Read the FULL contents of BOTH files before judging:`,
    `- Output A is the file at: ${pathForA}`,
    `- Output B is the file at: ${pathForB}`,
    `(If a path is a directory, read every file under it.)`,
    "",
    "For EACH rubric dimension, decide whether A, B, or tie is better on that axis,",
    "give a margin in 0..1 (0 for a tie), and a one-line evidence justification that",
    "QUOTES the deciding text from the output you picked. Then give an overall",
    "winner + margin across all dimensions.",
    "",
    "Posture: adversarial / default-reject. When the evidence for a dimension is weak,",
    "ambiguous, or roughly even, answer tie — do not invent a winner. Quote before you",
    "assert: a verdict with no quote from the artifact is a tie. evidence is required",
    "for ties too (quote what makes the two roughly even).",
    "",
    "Return ONLY the StructuredOutput object (per_dimension[] + overall).",
  ].join("\n");
}

// Translate one judge's blind A/B/tie winner into arm space using THAT judge's
// position assignment. assignment.A and assignment.B are arm names.
function toArm(blindWinner, assignment) {
  if (blindWinner === "tie") return "tie";
  if (blindWinner === "A") return assignment.A;
  if (blindWinner === "B") return assignment.B;
  return "tie"; // defensive: an out-of-enum value is treated as no-signal
}

// Median of an array of numbers (sorted middle; N=3 -> middle element).
function median(nums) {
  if (nums.length === 0) return 0;
  const s = [...nums].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : (s[mid - 1] + s[mid]) / 2;
}

// Aggregate one dimension's per-judge arm-space votes into a canonical A/B
// verdict. Majority winner (>= floor(N/2)+1), median margin, ties recorded.
// Canonical frame: A=library, B=baseline. A non-majority => tie, margin 0.
function aggregateVotes(armVotes, marginsByArm, panelSize) {
  const counts = { library: 0, baseline: 0, tie: 0 };
  for (const v of armVotes) counts[v] = (counts[v] || 0) + 1;
  const threshold = Math.floor(panelSize / 2) + 1;

  let winnerArm = "tie";
  if (counts.library >= threshold) winnerArm = "library";
  else if (counts.baseline >= threshold) winnerArm = "baseline";

  // Map the winning ARM into the canonical A/B frame (A=library, B=baseline).
  let winner;
  if (winnerArm === "library") winner = "A";
  else if (winnerArm === "baseline") winner = "B";
  else winner = "tie";

  // Median margin is taken over the margins cast FOR the winning arm; a tie is
  // forced to margin 0 per the protocol.
  let margin = 0;
  if (winnerArm !== "tie") {
    const winMargins = marginsByArm[winnerArm] || [];
    margin = median(winMargins);
  }
  return { winner, margin };
}

// --- run -------------------------------------------------------------------

// args may arrive as an object or, depending on the invocation path, as a
// JSON-encoded string — parse the latter (mirrors v2-collab's string handling).
let input = args || {};
if (typeof input === "string") {
  try {
    input = JSON.parse(input);
  } catch {
    throw new Error(
      "eval-harness: args arrived as a string that is not valid JSON; pass { fixtures, runId } as an object."
    );
  }
}
const fixtures = Array.isArray(input.fixtures) ? input.fixtures : null;
const runId = input.runId;
const panelSize =
  Number.isInteger(input.judges) && input.judges > 0 ? input.judges : 3;

if (!fixtures || fixtures.length === 0) {
  throw new Error(
    "eval-harness: args.fixtures must be a non-empty array of fixture objects (read from disk by the command)."
  );
}
if (!runId || !/^[a-z0-9-]+$/.test(String(runId))) {
  throw new Error(
    "eval-harness: args.runId must be a short id matching ^[a-z0-9-]+$ (used in the artifact path)."
  );
}

const ARMS = ["library", "baseline"]; // canonical order: library=A, baseline=B

// One stage: take a fixture object, run produce -> check -> judge, return the
// result.schema.json record. pipeline() runs each fixture through this with a
// clean orchestration context.
async function fixtureStage(fixture, _orig, _index) {
  const fixtureId = fixture.id;
  const checkKind = fixture.deterministic_check.kind;
  const baseDir = `/private/tmp/eval-run/${runId}/${fixtureId}`;

  // --- PRODUCE BOTH ARMS ---------------------------------------------------
  phase("Produce");
  log(`[${fixtureId}] producing both arms`);

  const artifactPath = {}; // arm -> reported artifact path

  for (const armName of ARMS) {
    const arm = fixture.arms[armName];
    const armDir = `${baseDir}/${armName}`;
    const producePrompt = buildProducePrompt(
      fixture,
      armName,
      armDir,
      arm.prompt
    );

    if (arm.kind === "pod") {
      // A pod arm runs the v2-collab collaboration pod (one level of nesting is
      // allowed from a top-level workflow). Pass the CLEAN task — NOT the
      // disk-write produce prompt: the pod accumulates its deliverable in an
      // in-memory artifact map (artifact_edits), it does not write files itself.
      // Feeding it "write to <dir> and return a path" confuses the pod's agents
      // and was the cause of the empty-artifact capture bug.
      const podTask = [
        fixture.task.trim(),
        arm.prompt && arm.prompt.trim() ? `\n${arm.prompt.trim()}` : "",
        "",
        "Produce the COMPLETE deliverable as file(s) in your artifact (artifact_edits)",
        "— e.g. a single index.html for a web page, or SKILL.md for a skill. The",
        "reviewer gates on the finished file content; put the real content in the file.",
      ]
        .filter(Boolean)
        .join("\n");
      const podResult = await workflow("v2-collab", { task: podTask, maxRounds: 4 });
      const podArtifact =
        podResult && podResult.artifact && typeof podResult.artifact === "object"
          ? podResult.artifact
          : {};
      const fileNames = Object.keys(podArtifact);
      if (fileNames.length === 0) {
        // Genuine produce FAILURE. Record no artifact — do NOT substitute a
        // placeholder, which would then be judged as if it were the library's
        // real output (the corpus-1 false-baseline-sweep bug).
        artifactPath[armName] = null;
        log(`[${fixtureId}] ${armName} pod returned NO artifact — recording produce failure`);
      } else {
        // The pod cannot write to disk; a sub-agent (has Bash/Write) materializes
        // the map faithfully and reports the primary file's path.
        const materialize = await agent(
          [
            `A collaboration pod produced the file(s) below for arm "${armName}".`,
            `Create ${armDir} (mkdir -p) and write EACH file faithfully under it at`,
            `its given filename — its EXACT bytes, do not edit or summarize content.`,
            `If a filename contains a slash, create the subdirectories. Then RETURN`,
            `the path to the PRIMARY deliverable (the main entry — the .html page, the`,
            `SKILL.md, or the top-level source file). Do not write anywhere else; do`,
            `not invent content.`,
            "",
            "## ARTIFACT (filename -> content)",
            JSON.stringify(podArtifact),
            "",
            "Return ONLY { artifact_path } — the exact path of the primary file written.",
          ].join("\n"),
          {
            agentType: "general-purpose",
            schema: PRODUCE_SCHEMA,
            label: `produce:${fixtureId}:${armName}`,
            phase: "Produce",
          }
        );
        artifactPath[armName] =
          materialize && materialize.artifact_path ? materialize.artifact_path : null;
      }
    } else {
      // kind === "agent": dispatch the single named producer agent.
      const produced = await agent(producePrompt, {
        agentType: arm.agentType,
        schema: PRODUCE_SCHEMA,
        label: `produce:${fixtureId}:${armName}`,
        phase: "Produce",
      });
      artifactPath[armName] = produced ? produced.artifact_path : null;
    }
    log(`[${fixtureId}] ${armName} artifact: ${artifactPath[armName] || "(none)"}`);
  }

  // --- CHECK BOTH ----------------------------------------------------------
  phase("Check");
  const deterministic = {};
  for (const armName of ARMS) {
    const path = artifactPath[armName];
    if (!path) {
      // No artifact produced -> the checker cannot run; record a non-pass with a
      // skip note rather than dispatching a checker against a missing path.
      deterministic[armName] = {
        pass: false,
        check: checkKind,
        note: "skipped: producer returned no artifact path",
      };
      log(`[${fixtureId}] ${armName} check: skipped (no artifact)`);
      continue;
    }
    // schema-match requires the fixture to declare the required patterns; pass
    // them through as extra checker args (else the checker exits 2 = skip).
    const patterns = Array.isArray(fixture.deterministic_check.patterns)
      ? fixture.deterministic_check.patterns
      : [];
    const patternArgs = patterns.map(shellSingleQuote).join(" ");
    // cargo-test executes untrusted model code; it is opt-in per run via
    // args.allowCodeExec (the checker still gates on EVAL_ALLOW_CODE_EXEC).
    const envPrefix =
      checkKind === "cargo-test" && input.allowCodeExec ? "EVAL_ALLOW_CODE_EXEC=1 " : "";
    const cmd =
      `${envPrefix}eval/checkers/run-checker.sh ${shellSingleQuote(checkKind)} ${shellSingleQuote(path)}` +
      (patternArgs ? ` ${patternArgs}` : "");
    const verdict = await agent(
      [
        `Run this exact command from the repo root and capture its EXIT CODE and`,
        `its one-line stdout:`,
        "",
        `  ${cmd}`,
        "",
        `The checker contract: exit 0 = PASS, exit 1 = FAIL, exit 2 = skip/could-`,
        `not-run. Return { pass, note } where pass is TRUE only if the exit code is`,
        `0. For exit 2, return pass:false with note "skipped". Otherwise put the`,
        `checker's one-line stdout verdict in note.`,
      ].join("\n"),
      {
        agentType: "general-purpose",
        schema: CHECK_SCHEMA,
        label: `check:${fixtureId}:${armName}`,
        phase: "Check",
      }
    );
    deterministic[armName] = {
      pass: verdict ? !!verdict.pass : false,
      check: checkKind,
      note: verdict ? verdict.note || "" : "checker dispatch failed",
    };
    log(`[${fixtureId}] ${armName} check: ${deterministic[armName].pass ? "PASS" : "FAIL/skip"}`);
  }

  // --- JUDGE (blind pairwise panel) ---------------------------------------
  phase("Judge");
  const libPath = artifactPath.library;
  const basePath = artifactPath.baseline;

  // Per-judge position assignment, alternated on the judge index j (NO RNG):
  //   j even -> A=library, B=baseline ; j odd -> A=baseline, B=library.
  // This cancels position bias deterministically across the panel.
  const dimKeys = fixture.rubric.dimensions.map((d) => d.key);
  // Per-dimension arm-space votes and margins-by-arm, plus the same for overall.
  const dimVotes = new Map(); // dimKey -> { votes:[], marginsByArm:{library:[],baseline:[]} }
  for (const k of dimKeys) {
    dimVotes.set(k, { votes: [], marginsByArm: { library: [], baseline: [] } });
  }
  const overallVotes = [];
  const overallMarginsByArm = { library: [], baseline: [] };

  for (let j = 0; j < panelSize; j++) {
    const assignment =
      j % 2 === 0
        ? { A: "library", B: "baseline" }
        : { A: "baseline", B: "library" };
    const pathForA = assignment.A === "library" ? libPath : basePath;
    const pathForB = assignment.B === "library" ? libPath : basePath;

    const judgePrompt = buildJudgePrompt(fixture, pathForA, pathForB);
    const out = await agent(judgePrompt, {
      agentType: "general-purpose",
      schema: JUDGE_SCHEMA,
      label: `judge:${fixtureId}:${j}`,
      phase: "Judge",
    });
    if (!out) {
      log(`[${fixtureId}] judge ${j} failed/skipped — not counted`);
      continue;
    }

    // Translate this judge's per-dimension A/B verdicts into arm space using
    // THIS judge's assignment, then accrue per dimension.
    const seen = new Set();
    for (const dv of out.per_dimension || []) {
      if (!dv || typeof dv.dimension !== "string") continue;
      const bucket = dimVotes.get(dv.dimension);
      if (!bucket || seen.has(dv.dimension)) continue; // ignore unknown/duplicate keys
      seen.add(dv.dimension);
      const arm = toArm(dv.winner, assignment);
      bucket.votes.push(arm);
      const m = typeof dv.margin === "number" ? dv.margin : 0;
      if (arm === "library") bucket.marginsByArm.library.push(m);
      else if (arm === "baseline") bucket.marginsByArm.baseline.push(m);
    }

    // Overall.
    if (out.overall && typeof out.overall.winner === "string") {
      const arm = toArm(out.overall.winner, assignment);
      overallVotes.push(arm);
      const m = typeof out.overall.margin === "number" ? out.overall.margin : 0;
      if (arm === "library") overallMarginsByArm.library.push(m);
      else if (arm === "baseline") overallMarginsByArm.baseline.push(m);
    }
  }

  // Aggregate per dimension (majority winner, median margin) in the canonical
  // A=library / B=baseline frame.
  const per_dimension = dimKeys.map((k) => {
    const b = dimVotes.get(k);
    const { winner, margin } = aggregateVotes(b.votes, b.marginsByArm, panelSize);
    return { dimension: k, winner, margin };
  });
  const overall = aggregateVotes(overallVotes, overallMarginsByArm, panelSize);

  log(`[${fixtureId}] panel done: overall winner ${overall.winner} (margin ${overall.margin})`);

  // --- BUILD RESULT (conforms EXACTLY to result.schema.json) ---------------
  return {
    fixture: fixtureId,
    run: runId,
    output_type: fixture.output_type,
    deterministic: {
      library: deterministic.library,
      baseline: deterministic.baseline,
    },
    judge: {
      per_dimension,
      overall,
      panel_votes: panelSize,
    },
    blinding_map: { A: "library", B: "baseline" },
  };
}

const results = await pipeline(fixtures, fixtureStage);

return results;
