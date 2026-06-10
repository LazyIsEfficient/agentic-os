// Routing-collision sweep over the Claude Code skill library.
//
// Collision definition implemented (quoted from
// .claude/skills/skill-library-review/references/description-and-routing.md):
//
//   "A shared trigger keyword between two skills is not automatically a routing
//    collision. ... A collision requires a real overlap: a shared trigger keyword,
//    or two file-globs that both match the same file/request. ... Both sides
//    deflect (reciprocal 'not when') -> Not a finding. Only one side deflects ->
//    Should-fix: add the missing reverse tiebreaker. Neither side deflects ->
//    Blocking/should-fix: real collision, no disambiguation."
//
// So a *reportable* collision = two skills that genuinely contend for the same
// request (shared trigger keyword or overlapping file-glob) AND are NOT both
// disambiguated by reciprocal "Not when ... use <other>" cross-refs.
//
// Bounding the O(n^2) blow-up: ~82 skills is ~3,300 unordered pairs — far too
// many to brute-force as one agent per pair. Instead we (1) cluster skills by
// shared trigger vocabulary / domain in a single barrier agent, then (2) only
// emit candidate pairs WITHIN a cluster (intra-cluster pairs only — skills in
// different clusters do not contend by construction), then (3) run a
// DEFAULT-REJECT verify agent that re-reads both SKILL.md files per the memory
// lesson, then (4) dedup unordered (A,B == B,A).

export const meta = {
  name: "routing-collision-sweep",
  description:
    "Detect routing collisions across the skill library: pairs of skills whose trigger vocabulary both fires on the same task and which lack reciprocal 'not when' disambiguation. Clusters by domain to bound the pairwise blow-up, then default-reject verifies each candidate by re-reading both SKILL.md files.",
  phases: [
    {
      title: "Discover",
      detail:
        "List .claude/skills/*/SKILL.md and extract each skill's name, description, when_to_use, and trigger keywords/globs.",
    },
    {
      title: "Cluster",
      detail:
        "Barrier: group skills into domain clusters by shared trigger vocabulary so only co-located skills are compared.",
    },
    {
      title: "Detect",
      detail:
        "For each cluster, emit candidate collision pairs (intra-cluster only). Agents read the actual SKILL.md files before claiming overlap.",
    },
    {
      title: "Verify",
      detail:
        "Default-reject gate: re-read BOTH skills' files, confirm real contention, and reject any pair already resolved by reciprocal 'not when' cross-refs.",
    },
    {
      title: "Dedup & Report",
      detail:
        "Collapse unordered duplicate pairs (A,B == B,A) and return confirmed collisions.",
    },
  ],
};

// ---------------------------------------------------------------------------
// JSON-Schema constants
// ---------------------------------------------------------------------------

const SKILL_INVENTORY_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["skills"],
  properties: {
    skills: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "path", "description", "whenToUse", "triggers"],
        properties: {
          name: { type: "string" },
          path: { type: "string" },
          description: { type: "string" },
          whenToUse: { type: "string" },
          triggers: {
            type: "array",
            items: { type: "string" },
            description:
              "Trigger keywords, user phrases, and file globs extracted from description + when_to_use.",
          },
        },
      },
    },
  },
};

const CLUSTERS_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["clusters"],
  properties: {
    clusters: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["label", "sharedVocabulary", "members"],
        properties: {
          label: { type: "string" },
          sharedVocabulary: {
            type: "array",
            items: { type: "string" },
          },
          members: {
            type: "array",
            items: { type: "string" },
            description: "Skill names that share this trigger vocabulary/domain.",
          },
        },
      },
    },
  },
};

const CANDIDATES_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["candidates"],
  properties: {
    candidates: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["skillA", "skillB", "sharedTriggers", "why"],
        properties: {
          skillA: { type: "string" },
          skillB: { type: "string" },
          sharedTriggers: {
            type: "array",
            items: { type: "string" },
            description:
              "Concrete shared trigger keywords or overlapping file-globs that both skills fire on.",
          },
          why: {
            type: "string",
            description:
              "One sentence on the request both skills would fire on.",
          },
        },
      },
    },
  },
};

const VERDICT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["isRealCollision", "reason", "skillADeflects", "skillBDeflects", "severity"],
  properties: {
    isRealCollision: {
      type: "boolean",
      description:
        "True ONLY if the pair genuinely contends AND is not fully resolved by reciprocal 'not when' deflection. Default is false.",
    },
    skillADeflects: {
      type: "boolean",
      description: "Does skillA's description/when_to_use deflect to skillB on the shared trigger?",
    },
    skillBDeflects: {
      type: "boolean",
      description: "Does skillB's description/when_to_use deflect to skillA on the shared trigger?",
    },
    severity: {
      type: "string",
      enum: ["none", "should-fix", "blocking"],
      description:
        "none = reciprocal deflection (resolved); should-fix = only one side deflects; blocking = neither side deflects.",
    },
    reason: {
      type: "string",
      description:
        "Evidence: quote the actual 'Not when ... use <other>' line from each side, or state which side's tiebreaker is absent.",
    },
  },
  // NOTE: do NOT add a top-level allOf/oneOf/anyOf here. Anthropic tool
  // input_schema rejects them with "400 input_schema does not support oneOf,
  // allOf, or anyOf at the top level", which makes EVERY StructuredOutput call
  // in this phase fail silently (the agent completes without a verdict). The
  // severity<->isRealCollision consistency the schema used to encode is enforced
  // at runtime by reconcileSeverity() below instead.
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Stable unordered pair key (A,B == B,A) for dedup.
function pairKey(a, b) {
  return [a, b].sort().join(" × ");
}

// Intra-cluster unordered candidate pairs only — this is what bounds the blow-up.
function intraClusterPairs(members) {
  const pairs = [];
  const seen = members.slice().sort();
  for (let i = 0; i < seen.length; i++) {
    for (let j = i + 1; j < seen.length; j++) {
      pairs.push([seen[i], seen[j]]);
    }
  }
  return pairs;
}

// ---------------------------------------------------------------------------
// Workflow body
// ---------------------------------------------------------------------------

// ----- Phase 1: Discover -----
phase("Discover");

const inventory = await agent(
  `List every skill in this library and extract its routing surface.

Run this to enumerate the files (do not work from memory):
  ls .claude/skills/*/SKILL.md

For EACH SKILL.md you must READ the actual file (open it — do not summarize from training data). From the YAML frontmatter extract:
  - name
  - path (the SKILL.md path you read)
  - description (the full 'description:' field)
  - whenToUse (the full 'when_to_use:' field, or "" if absent)
  - triggers: every concrete trigger you can see — quoted user keywords/phrases,
    file globs (e.g. "*.sol", "**/*.test.ts"), tool/lib names, and slash commands —
    pulled from BOTH description and when_to_use.

Return the full inventory. Do not omit any skill. Read before you claim.`,
  {
    label: "discover-inventory",
    phase: "Discover",
    schema: SKILL_INVENTORY_SCHEMA,
  }
);

log(`Discovered ${inventory.skills.length} skills.`);

// Compact directory the downstream agents can reason over without re-reading
// every file just to cluster.
const directory = inventory.skills.map((s) => ({
  name: s.name,
  path: s.path,
  triggers: s.triggers,
  description: s.description,
}));

const pathByName = {};
for (const s of inventory.skills) pathByName[s.name] = s.path;

// ----- Phase 2: Cluster (barrier) -----
phase("Cluster");

const clusterResult = await agent(
  `Group these skills into DOMAIN CLUSTERS by SHARED TRIGGER VOCABULARY so that
only skills that could plausibly contend for the same request end up together.

Two skills belong in the same cluster if they share trigger keywords, overlapping
file globs, or operate in the same domain (e.g. all "frontend/UI", all "Solidity/
on-chain", all "deployment/CI", all "testing"). A skill may appear in more than one
cluster if its triggers span domains. Skills with no shared trigger vocabulary with
anyone form a singleton cluster (they cannot collide and will be skipped downstream).

Aim for tight, specific clusters (typically 2-8 members). A cluster with 20+ members
is too coarse — split it by the more specific shared vocabulary.

Skill directory (name, triggers, description):
${JSON.stringify(directory, null, 2)}

Return clusters with a label, the sharedVocabulary that binds them, and member names.`,
  {
    label: "cluster-by-vocabulary",
    phase: "Cluster",
    schema: CLUSTERS_SCHEMA,
  }
);

const clusters = clusterResult.clusters.filter((c) => c.members.length >= 2);
log(
  `Formed ${clusterResult.clusters.length} clusters; ${clusters.length} have >=2 members and proceed to detection.`
);

// ----- Phase 3: Detect (per-cluster candidate pairs) -----
phase("Detect");

// One detection thunk per cluster. Each only considers intra-cluster pairs, so
// the agent never reasons over the full O(n^2) space.
const detectThunks = clusters.map((cluster, idx) => async () => {
  const memberNames = cluster.members;
  const memberRecords = inventory.skills.filter((s) =>
    memberNames.includes(s.name)
  );
  const candidatePairs = intraClusterPairs(memberNames);

  if (candidatePairs.length === 0) return { candidates: [] };

  // Vary by index (no Date.now / Math.random allowed) so labels are unique.
  const tag = `detect-cluster-${idx}`;

  const result = await agent(
    `You are screening ONE cluster of skills for routing collisions — pairs whose
trigger vocabulary would BOTH fire on the same task.

Cluster: "${cluster.label}"
Shared vocabulary: ${JSON.stringify(cluster.sharedVocabulary)}

GROUNDING REQUIREMENT: before claiming any pair overlaps, READ the actual SKILL.md
file for both skills (open the file at the given path — do not rely on the summary
below alone). The summaries are a starting index, not ground truth.

Members (name -> path, triggers):
${memberRecords
  .map(
    (s) =>
      `- ${s.name}\n    path: ${s.path}\n    triggers: ${JSON.stringify(
        s.triggers
      )}`
  )
  .join("\n")}

Consider ONLY these unordered candidate pairs (do not invent cross-cluster pairs):
${candidatePairs.map(([a, b]) => `  - ${a}  ×  ${b}`).join("\n")}

A pair is a CANDIDATE collision only if there is REAL contention: a shared trigger
keyword, or two file-globs that both match the same file/request. Two skills that
merely sit in the same domain but fire on different requests are NOT candidates —
do not pad the list. Be precise about the shared trigger.

For each genuine candidate, give skillA, skillB, the concrete sharedTriggers, and a
one-sentence 'why' describing the request both would fire on. If the cluster has no
genuine contention, return an empty candidates array. Do NOT judge whether the pair
is disambiguated yet — that is the verify step's job; just surface real overlap.`,
    {
      label: tag,
      phase: "Detect",
      schema: CANDIDATES_SCHEMA,
    }
  );

  return result;
});

const detectResults = await parallel(detectThunks);

// Flatten + dedup candidate pairs (unordered) before verification.
const candidateByKey = new Map();
for (const r of detectResults) {
  // parallel() turns a throwing detect thunk into null — guard before deref.
  if (!r) continue;
  for (const c of r.candidates || []) {
    if (!c.skillA || !c.skillB || c.skillA === c.skillB) continue;
    const key = pairKey(c.skillA, c.skillB);
    if (!candidateByKey.has(key)) {
      candidateByKey.set(key, c);
    } else {
      // Merge shared triggers from duplicate sightings.
      const existing = candidateByKey.get(key);
      const merged = new Set([
        ...(existing.sharedTriggers || []),
        ...(c.sharedTriggers || []),
      ]);
      existing.sharedTriggers = [...merged];
    }
  }
}

const candidates = [...candidateByKey.values()];
log(`Detected ${candidates.length} unique candidate collision pairs to verify.`);

// ----- Phase 4: Verify (DEFAULT-REJECT, re-read both files) -----
phase("Verify");

// pipeline runs each candidate independently through the verify stage.
const verifyStage = async (candidate, _orig, index) => {
  const pathA = pathByName[candidate.skillA] || "(path unknown — locate it)";
  const pathB = pathByName[candidate.skillB] || "(path unknown — locate it)";

  const verdict = await agent(
    `You are an ADVERSARIAL, DEFAULT-REJECT verifier of ONE candidate routing
collision. Your prior is that this is NOT a collision. Only flip to true with
quoted evidence from BOTH files. This gate exists because routing-collision
findings are the single biggest source of false positives in this library —
they require a second file read.

Candidate pair:
  A = ${candidate.skillA}   (read: ${pathA})
  B = ${candidate.skillB}   (read: ${pathB})
  claimed shared triggers: ${JSON.stringify(candidate.sharedTriggers)}
  claimed why: ${candidate.why}

MANDATORY STEPS (do them in order; do not skip the read):
0. READ both SKILL.md files in full — the 'description' AND 'when_to_use' fields,
   including EVERY "Not when ... use <other>" clause. Quoting from memory is not
   reading; if a quote does not match the file, you are hallucinating — stop.
1. CONTENTION CHECK: confirm the two skills actually contend — a shared trigger
   keyword, or two file-globs that both match the same request. If they do not
   genuinely compete for the same request, set isRealCollision=false,
   severity="none", and say so. Neither-names-the-other is NOT contention.
2. RECIPROCAL DEFLECTION CHECK: does skillA's text deflect to skillB on the shared
   trigger ("Not when ... use ${candidate.skillB}")? Does skillB's text deflect to
   skillA? Set skillADeflects / skillBDeflects accordingly.

VERDICT TABLE (apply exactly):
  - Both sides deflect (reciprocal "not when")  -> isRealCollision=false, severity="none"  (RESOLVED, not a finding)
  - Only one side deflects                      -> isRealCollision=true,  severity="should-fix" (missing reverse tiebreaker)
  - Neither side deflects (but real contention) -> isRealCollision=true,  severity="blocking"
  - No genuine contention                       -> isRealCollision=false, severity="none"

In 'reason', QUOTE the actual "Not when ... use X" line from each side as evidence,
or state explicitly which side's tiebreaker is absent. A verdict without quoted
lines is invalid — default to isRealCollision=false.`,
    {
      label: `verify-${index}`,
      phase: "Verify",
      schema: VERDICT_SCHEMA,
    }
  );

  return { candidate, verdict };
};

const verified =
  candidates.length === 0 ? [] : await pipeline(candidates, verifyStage);

// ----- Phase 5: Dedup & Report -----
phase("Dedup & Report");

// Reconcile severity with isRealCollision per the verify-stage verdict table
// (a confirmed collision must never surface as severity="none", and a non-collision
// must never carry a non-none severity). Runtime safety net in case a model emits a
// verdict that slips past the schema's allOf consistency rules.
function reconcileSeverity(verdict) {
  if (!verdict) return verdict;
  if (!verdict.isRealCollision) {
    if (verdict.severity !== "none") {
      log(
        `Reconciled contradictory verdict: isRealCollision=false but severity="${verdict.severity}" -> "none".`
      );
    }
    return { ...verdict, severity: "none" };
  }
  // isRealCollision=true: at least one side deflects -> should-fix; neither -> blocking.
  // (Both-sides-deflect is "resolved" per the verdict table and never reaches here
  // with isRealCollision=true; if a contradictory verdict slips the schema, the
  // conservative should-fix is correct — we never fabricate a "blocking" from it.)
  if (verdict.severity === "none") {
    const resolved =
      verdict.skillADeflects || verdict.skillBDeflects ? "should-fix" : "blocking";
    log(
      `Reconciled contradictory verdict: isRealCollision=true but severity="none" -> "${resolved}".`
    );
    return { ...verdict, severity: resolved };
  }
  return verdict;
}

// Final unordered dedup safety net + keep only confirmed real collisions.
const confirmedByKey = new Map();
for (const v of verified) {
  if (!v || !v.verdict || !v.verdict.isRealCollision) continue;
  const verdict = reconcileSeverity(v.verdict);
  const key = pairKey(v.candidate.skillA, v.candidate.skillB);
  if (confirmedByKey.has(key)) continue;
  confirmedByKey.set(key, {
    skillA: v.candidate.skillA,
    skillB: v.candidate.skillB,
    sharedTriggers: v.candidate.sharedTriggers,
    severity: verdict.severity,
    skillADeflects: verdict.skillADeflects,
    skillBDeflects: verdict.skillBDeflects,
    reason: verdict.reason,
  });
}

const confirmed = [...confirmedByKey.values()];
log(
  `Confirmed ${confirmed.length} routing collisions (rejected ${
    verified.length - confirmed.length
  } candidates at the verify gate).`
);

return {
  scanned: inventory.skills.length,
  clusters: clusters.length,
  candidatePairs: candidates.length,
  confirmedCollisions: confirmed,
};
