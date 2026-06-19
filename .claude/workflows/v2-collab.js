// v2-collab — in-session multi-agent collaboration pod.
//
// This is the IN-CLAUDE-CODE version of the v2 runtime: instead of a standalone
// Rust+Redis harness driven from a terminal, the orchestration runs as a Workflow
// the session invokes directly. A pod (technical-pm -> engineer -> code-reviewer,
// roster configurable) collaborates over a shared in-memory artifact across
// orchestrator-clocked rounds until the reviewer approves or the round cap is hit.
// Each turn is a real Claude Code subagent (agent() with agentType), so it runs on
// the subscription — no API key, no Redis, no Docker, no second process.
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
// args: a task string, or { task, maxRounds?, roles?, autoCompose? }.
// roles (optional) explicitly overrides the roster; each is { key, agentType, directive }.
// When roles is omitted, the workflow auto-composes a task-fit roster via the
// `pod-architect` agent (set autoCompose:false to force the hard-coded default pod).
// A composed roster that fails validation falls back to the default ROLES.
// The LAST role in the roster is the approval gate — its `approve:true` ends the run.

export const meta = {
  name: "v2-collab",
  description:
    "In-session multi-agent collaboration pod: technical-pm -> engineer -> code-reviewer (roster configurable) collaborate over a shared artifact across orchestrator-clocked rounds until the reviewer approves or the round cap is hit. Each turn is a real Claude Code subagent (subscription, no API/Redis/Docker). Returns the produced artifact for the caller to materialize and gate.",
  phases: [
    {
      title: "Compose",
      detail:
        "If no roster was supplied, the pod-architect agent reads the task + live agent registry and composes a task-fit roster (gate-last, <=5 roles). Skipped when roles are passed explicitly.",
    },
    {
      title: "Collaborate",
      detail:
        "Round loop: PM frames the work, the engineer produces/revises the artifact, the reviewer reviews and votes approve. Repeat until approved or the round cap.",
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
        "True ONLY if the artifact is complete and ready to ship as-is. The run ends the moment the final reviewer returns true. PM/engineer should return false unless the work is genuinely done.",
    },
  },
};

// Structured roster returned by the pod-architect agent during auto-composition.
// Flat-ish object; no top-level allOf/oneOf/anyOf (those 400 the StructuredOutput
// schema and fail as empty). The agent enforces real-agents-only against the live
// registry; this schema only enforces shape and size.
const ROSTER_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["roles", "maxRounds"],
  properties: {
    roles: {
      type: "array",
      minItems: 1,
      maxItems: 5,
      description:
        "Ordered roster, gate LAST. Each role is the agent for one pod turn.",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["key", "agentType", "directive"],
        properties: {
          key: { type: "string", description: "Short stable handle, e.g. 'eng'." },
          agentType: {
            type: "string",
            description: "Exact name of a real agent under .claude/agents/.",
          },
          directive: {
            type: "string",
            description: "Short role-specific instruction for this pod turn.",
          },
        },
      },
    },
    maxRounds: {
      type: "integer",
      minimum: 1,
      maximum: 20,
      description: "Recommended round cap for this deliverable.",
    },
  },
};

// Default pod — general-purpose (code-reviewer gates). For authoring a library
// skill/agent, override the last role to `library-reviewer` via args.roles so the
// gate judges RULESET conformance instead of code quality.
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
    agentType: "code-reviewer",
    directive:
      "You are the reviewer and the approval gate. Judge the current artifact against the task's acceptance criteria and quality bar. If it is complete and correct, return approve=true and change nothing. Otherwise approve=false and put the specific, actionable fixes in `note` — the engineer will act on them next round. Do not rewrite the artifact yourself.",
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

function composePrompt(task) {
  return [
    "Compose the agent team (roster) that will build the following deliverable.",
    "",
    "## TASK",
    task.trim(),
    "",
    "## WHAT TO RETURN",
    "Survey the LIVE agent registry (.claude/agents/*.md) and return a structured roster:",
    "an ordered `roles` array of { key, agentType, directive } (1-5 entries) plus a recommended integer `maxRounds`.",
    "The LAST role MUST be a reviewer gate matched to the deliverable type (code-reviewer / security-reviewer / library-reviewer / adversarial-claims-reviewer).",
    "Every agentType MUST be the exact name of a real agent under .claude/agents/. Keep each directive short and specific to THIS deliverable.",
  ].join("\n");
}

// ---------------------------------------------------------------------------

const input = typeof args === "string" ? { task: args } : args || {};
const task = input.task;

if (!task || !String(task).trim()) {
  throw new Error(
    "v2-collab: no task provided. Pass args as a task string or { task, maxRounds }."
  );
}

// Caller's explicit round cap (positive integer) wins; otherwise the composer may
// suggest one; otherwise default 6. Always clamped to [1,20].
const maxRoundsRaw = Number(input.maxRounds);
const callerSetMaxRounds = Number.isInteger(maxRoundsRaw) && maxRoundsRaw > 0;
let maxRounds = callerSetMaxRounds ? Math.min(maxRoundsRaw, 20) : 6;

// A role is well-formed iff it carries non-empty string key/agentType/directive.
const wellFormedRole = (r) =>
  r &&
  typeof r.key === "string" && r.key.trim() &&
  typeof r.agentType === "string" && r.agentType.trim() &&
  typeof r.directive === "string" && r.directive.trim();

// Reviewer agents permitted as the final approval gate. Safety net only — the
// pod-architect agent is the source of truth (it reads the live registry); this
// set just deterministically rejects a composed roster whose gate is NOT a known
// reviewer, so a mis-composed run falls back to the default instead of running
// with a silently-skipped (gate-less) approval turn. Keep in sync with the
// reviewer agents under .claude/agents/.
const KNOWN_REVIEWERS = new Set([
  "code-reviewer",
  "security-reviewer",
  "library-reviewer",
  "adversarial-claims-reviewer",
]);

// Resolve the roster. Precedence: explicit args.roles override > pod-architect
// auto-composition (default when no override) > the hard-coded default ROLES.
let roles = ROLES;
let rosterSource = "default";
if (Array.isArray(input.roles) && input.roles.length) {
  if (!input.roles.every(wellFormedRole)) {
    throw new Error(
      "v2-collab: each entry in args.roles needs non-empty string key, agentType, and directive."
    );
  }
  roles = input.roles;
  rosterSource = "override";
} else if (input.autoCompose !== false) {
  // No roster supplied — let pod-architect compose one from the task + live registry.
  phase("Compose");
  log("Composing roster via pod-architect");
  const roster = await agent(composePrompt(task), {
    agentType: "pod-architect",
    schema: ROSTER_SCHEMA,
    label: "compose",
    phase: "Compose",
  });
  const candidate = roster && Array.isArray(roster.roles) ? roster.roles : null;
  const gate = candidate && candidate[candidate.length - 1];
  const valid =
    candidate &&
    candidate.length >= 1 &&
    candidate.length <= 5 &&
    candidate.every(wellFormedRole) &&
    gate &&
    KNOWN_REVIEWERS.has(gate.agentType);
  if (valid) {
    roles = candidate;
    rosterSource = "composed";
    log(`Composed roster: ${candidate.map((r) => r.agentType).join(" -> ")}`);
    if (!callerSetMaxRounds && Number.isInteger(roster.maxRounds) && roster.maxRounds > 0) {
      maxRounds = Math.min(roster.maxRounds, 20);
    }
  } else {
    log("Composition failed or violated invariants — using default roster.");
  }
}

const artifact = {}; // filename -> content, accumulated across rounds
const logEntries = [];
let approved = false;
let roundsRun = 0;

phase("Collaborate");
for (let round = 1; round <= maxRounds && !approved; round++) {
  roundsRun = round;
  log(`Round ${round}/${maxRounds}`);
  for (let i = 0; i < roles.length; i++) {
    const role = roles[i];
    const isGate = i === roles.length - 1; // last role in the roster is the approval gate
    const contrib = await agent(buildPrompt(task, role, artifact, logEntries, round), {
      agentType: role.agentType,
      schema: CONTRIBUTION_SCHEMA,
      label: `r${round}:${role.key}`,
      phase: "Collaborate",
    });
    if (!contrib) {
      // A failed/skipped turn never approves — including a failed gate turn.
      logEntries.push({ round, role: role.key, note: "(no contribution — agent skipped/failed)", approve: false });
      continue;
    }
    // Apply only a well-formed edits object; ignore a schema-violating non-object.
    const edits =
      contrib.artifact_edits &&
      typeof contrib.artifact_edits === "object" &&
      !Array.isArray(contrib.artifact_edits)
        ? contrib.artifact_edits
        : {};
    for (const [name, content] of Object.entries(edits)) artifact[name] = content;
    logEntries.push({ round, role: role.key, note: contrib.note || "", approve: !!contrib.approve });
    // OR-latch by INDEX (robust even if a roster repeats the same object reference):
    // `approved` only flips true, never back to false.
    if (isGate) approved ||= !!contrib.approve;
  }
}

log(approved ? `Approved in ${roundsRun} round(s)` : `Hit round cap (${roundsRun}) without approval`);

return {
  approved,
  rounds: roundsRun,
  rosterSource, // "override" | "composed" | "default"
  roster: roles.map((r) => ({ key: r.key, agentType: r.agentType })),
  files: Object.keys(artifact),
  artifact,
  log: logEntries,
};
