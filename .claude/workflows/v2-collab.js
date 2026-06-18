// v2-collab — in-session multi-agent collaboration pod.
//
// This is the IN-CLAUDE-CODE version of the v2 runtime: instead of a standalone
// Rust+Redis harness driven from a terminal, the orchestration runs as a Workflow
// the session invokes directly. A pod (PM -> engineer -> library-reviewer)
// collaborates over a shared in-memory artifact across orchestrator-clocked rounds
// until the reviewer approves or the round cap is hit. Each turn is a real Claude
// Code subagent (agent() with agentType), so it runs on the subscription — no API
// key, no Redis, no Docker, no second process.
//
// What carried over from the Rust runtime: the round protocol, done-on-reviewer-
// approve, the task-as-seed-prompt shape, and the structured Contribution interface.
// What is gone (and unneeded for a single in-session pod): the external Redis
// blackboard and broker fan-out. Durability/resume is provided by the Workflow
// tool itself (resumeFromRunId).
//
// Returns { approved, rounds, files, artifact, log } — the calling command materializes
// `artifact` (filename -> content) to disk with path sanitization and may gate it
// with scripts/validate.sh. The Workflow sandbox cannot write files itself.
//
// args: a task string, or { task: string, maxRounds?: number, roles?: Role[] }.
// roles (optional) overrides the default pod; each is { key, agentType, directive }.
// The LAST role in the roster is the approval gate — its `approve:true` ends the run.

export const meta = {
  name: "v2-collab",
  description:
    "In-session multi-agent collaboration pod: technical-pm -> engineer -> library-reviewer collaborate over a shared artifact across orchestrator-clocked rounds until the reviewer approves or the round cap is hit. Each turn is a real Claude Code subagent (subscription, no API/Redis/Docker). Returns the produced artifact for the caller to materialize and gate.",
  phases: [
    {
      title: "Collaborate",
      detail:
        "Round loop: PM frames the work, the engineer produces/revises the artifact, the library-reviewer reviews and votes approve. Repeat until approved or the round cap.",
    },
  ],
};

// One agent turn's structured output. Flat object only — no top-level
// allOf/oneOf/anyOf (those 400 the StructuredOutput schema and fail as empty).
const CONTRIBUTION_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["artifact_edits", "note", "approve"],
  properties: {
    artifact_edits: {
      type: "object",
      description:
        "filename -> FULL new file content for each file this turn adds or replaces. Empty object if this turn only reviews/frames and changes no file. Filenames are relative paths (e.g. 'SKILL.md'); never absolute, never containing '..'.",
      additionalProperties: { type: "string" },
    },
    note: {
      type: "string",
      description:
        "Short rationale for this turn: what you framed, produced, or (for the reviewer) why you did or did not approve.",
    },
    approve: {
      type: "boolean",
      description:
        "True ONLY if the artifact is complete and ready to ship as-is. The run ends the moment the library-reviewer returns true. PM/engineer should return false unless the work is genuinely done.",
    },
  },
};

const ROLES = [
  {
    key: "pm",
    agentType: "technical-pm",
    directive:
      "You are the PM for this pod. Frame the deliverable: state the acceptance criteria and any non-goals so the engineer builds the right thing. You usually change no files (empty artifact_edits) on round 1 — your job is the frame. approve=false unless the artifact already fully meets the task.",
  },
  {
    key: "eng",
    agentType: "engineer",
    directive:
      "You are the engineer. Produce or REVISE the actual deliverable, returning each file's full new content in artifact_edits. Address the PM's acceptance criteria and the reviewer's prior notes. approve=false unless you believe it is genuinely done.",
  },
  {
    key: "rev",
    agentType: "library-reviewer",
    directive:
      "You are the reviewer. Judge the current artifact against the task's acceptance criteria and the repo's standards. If it is complete and correct, return approve=true and change nothing. Otherwise approve=false and put the specific, actionable fixes in `note` — the engineer will act on them next round. Do not rewrite the artifact yourself.",
  },
];

function renderArtifact(artifact) {
  const names = Object.keys(artifact);
  if (names.length === 0) return "(empty — nothing produced yet)";
  return names
    .map((n) => `--- ${n} ---\n${artifact[n]}`)
    .join("\n\n");
}

function renderLog(log) {
  if (log.length === 0) return "(none yet)";
  return log
    .slice(-9)
    .map((e) => `[round ${e.round} ${e.role}${e.approve ? " APPROVED" : ""}] ${e.note}`)
    .join("\n");
}

function buildPrompt(task, role, artifact, log, round) {
  return [
    "## TASK (the instruction for this run — read-only)",
    task.trim(),
    "",
    `## YOUR ROLE (round ${round})`,
    role.directive,
    "",
    "## CURRENT SHARED ARTIFACT",
    renderArtifact(artifact),
    "",
    "## RECENT CONTRIBUTIONS (newest last)",
    renderLog(log),
    "",
    "## OUTPUT",
    "Return ONLY the structured contribution: `artifact_edits` (filename -> full new content for files you add/replace this turn, or {} if none), `note` (your rationale), and `approve` (true only if the artifact is done).",
  ].join("\n");
}

// ---------------------------------------------------------------------------

const input = typeof args === "string" ? { task: args } : args || {};
const task = input.task;
const maxRounds = Number(input.maxRounds) > 0 ? Number(input.maxRounds) : 6;
const roles =
  Array.isArray(input.roles) && input.roles.length ? input.roles : ROLES;

if (!task || !String(task).trim()) {
  throw new Error(
    "v2-collab: no task provided. Pass args as a task string or { task, maxRounds }."
  );
}

const artifact = {}; // filename -> content, accumulated across rounds
const logEntries = [];
let approved = false;
let roundsRun = 0;

phase("Collaborate");
for (let round = 1; round <= maxRounds && !approved; round++) {
  roundsRun = round;
  log(`Round ${round}/${maxRounds}`);
  for (const role of roles) {
    const contrib = await agent(buildPrompt(task, role, artifact, logEntries, round), {
      agentType: role.agentType,
      schema: CONTRIBUTION_SCHEMA,
      label: `r${round}:${role.key}`,
      phase: "Collaborate",
    });
    if (!contrib) {
      logEntries.push({ round, role: role.key, note: "(no contribution — agent skipped/failed)", approve: false });
      continue;
    }
    const edits = contrib.artifact_edits || {};
    for (const [name, content] of Object.entries(edits)) artifact[name] = content;
    logEntries.push({ round, role: role.key, note: contrib.note || "", approve: !!contrib.approve });
    if (role === roles[roles.length - 1]) approved = !!contrib.approve;
  }
}

log(approved ? `Approved in ${roundsRun} round(s)` : `Hit round cap (${roundsRun}) without approval`);

return {
  approved,
  rounds: roundsRun,
  files: Object.keys(artifact),
  artifact,
  log: logEntries,
};
