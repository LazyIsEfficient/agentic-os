// audit-skill-library.js — sharded generate -> default-reject verify audit of the
// Claude Code skill/agent library.
//
// This reproduces the PROVEN harness recorded in
// .claude/memory/audit_skill_library_sharded.md. Do NOT redesign it.
//
// Why sharded + verified: five prior monolithic single-pass audits each ran a
// ~10-15% false-positive rate, concentrated entirely in cross-skill
// routing-collision findings (the one finding-type that needs a SECOND file
// read). The fix is execution-model, not rubric wording: one generation agent
// per skill (clean context), then an INDEPENDENT default-reject verify agent
// that re-reads the files and re-runs the Step-0 contention + reciprocal
// "not when" check before any finding is filed. The 2026-06-05 run over 79
// skills produced 43 candidates; the gate rejected 1 (severity, not falseness);
// the routing category had ZERO false positives.
//
// Two pipeline-hygiene gaps the per-finding gate misses are encoded explicitly
// below as Backstop 1 (meta-skill mis-attribution) and Backstop 2 (body-level
// dedup). Omitting either regresses to the 10-15% FP rate.

export const meta = {
  name: "audit-skill-library",
  description:
    "Sharded one-agent-per-skill generation + an independent default-reject verify gate that re-reads files and re-runs the Step-0 contention / reciprocal not-when check. Encodes Backstop 1 (meta-skill mis-attribution re-attribution) and Backstop 2 (dedup against existing issue bodies, not titles).",
  phases: [
    { title: "Discover", detail: "Enumerate every .claude/skills/*/SKILL.md to audit." },
    { title: "Generate", detail: "One generation agent per skill: clean context, reads the skill's actual SKILL.md + references and the skill-library-review rubric before claiming anything; emits candidate findings." },
    { title: "Verify", detail: "Independent default-reject agent re-reads the files and re-runs the Step-0 contention + reciprocal not-when check; rejects unless the finding survives." },
    { title: "Backstop", detail: "Re-attribute meta-skill findings from each finding's title/evidence (Backstop 1) and dedup against existing issue BODIES, not just titles (Backstop 2)." },
  ],
};

// ---------------------------------------------------------------------------
// JSON Schemas — outputs are validated via opts.schema.
// ---------------------------------------------------------------------------

// Generate stage emits an array of candidate findings for ONE skill.
const FINDINGS_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["findings"],
  properties: {
    findings: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["skill", "category", "severity", "title", "evidence"],
        properties: {
          // The skill the finding is ABOUT (may differ from the reviewing
          // skill — Backstop 1 re-attributes from this + title/evidence).
          skill: { type: "string", description: "Slug of the skill the finding is ABOUT (not necessarily the reviewing skill)." },
          category: {
            type: "string",
            enum: [
              "frontmatter",
              "routing-collision",
              "description-quality",
              "tool-allowlist",
              "cross-reference",
              "library-shape",
              "anti-pattern",
            ],
          },
          severity: { type: "string", enum: ["blocking", "should-fix", "nit"] },
          title: { type: "string", description: "One-line finding title." },
          // Must be the exact text quoted from the live file at file:line.
          evidence: { type: "string", description: "file:line plus the EXACT quoted line(s) from the current file." },
        },
      },
    },
  },
};

// Verify stage returns a per-finding verdict. Default-reject: isReal must be
// affirmatively true with a reason that cites the re-read files.
const VERDICT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["isReal", "reason", "correctedSkill"],
  properties: {
    isReal: { type: "boolean", description: "True ONLY if the finding survives an independent re-read and the Step-0 contention + reciprocal not-when re-check. Default false." },
    reason: { type: "string", description: "Why it survives or is rejected, citing the re-read file:line." },
    // Backstop 1 lives here too: the verifier may re-attribute. The final
    // Backstop pass re-attributes again from title/evidence as a safety net.
    correctedSkill: { type: "string", description: "The skill the finding is REALLY about, re-derived from its title/evidence. Same as input skill if no mis-attribution." },
  },
};

// Backstop 2 dedup output. Sibling evidence fields prove the dedup actually
// fetched and compared issue BODIES via gh, rather than reusing FINDINGS_SCHEMA
// (which would leave no proof the body comparison ran).
const DEDUP_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["findings", "droppedAsDuplicate", "issuesFetched"],
  properties: {
    findings: FINDINGS_SCHEMA.properties.findings,
    droppedAsDuplicate: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["title", "issueNumber"],
        properties: {
          title: { type: "string", description: "Title of the dropped duplicate finding." },
          issueNumber: { type: "integer", description: "Open issue number whose BODY already covers this finding." },
        },
      },
    },
    issuesFetched: { type: "integer", description: "Count of open issues fetched (with bodies) and compared against." },
  },
};

const RUBRIC = ".claude/skills/skill-library-review/SKILL.md";

// ---------------------------------------------------------------------------
// Phase: Discover — derive the skill list (not auto-provided).
// ---------------------------------------------------------------------------
phase("Discover");

let skills;
if (args && Array.isArray(args.skills) && args.skills.length > 0) {
  skills = args.skills;
} else {
  const listed = await agent(
    `List every skill in this repo's library. Run exactly:\n` +
      `  ls -1 .claude/skills/*/SKILL.md\n` +
      `For each path, output ONLY the skill slug (the directory name between ".claude/skills/" and "/SKILL.md").`,
    {
      label: "discover-skills",
      phase: "Discover",
      schema: {
        type: "object",
        additionalProperties: false,
        required: ["skills"],
        properties: {
          skills: { type: "array", items: { type: "string" } },
        },
      },
    }
  );
  skills = listed.skills;
}

log(`Discovered ${skills.length} skills to audit.`);

// ---------------------------------------------------------------------------
// Generate stage — ONE agent per skill, clean context. Grounding discipline:
// the agent MUST read the skill's actual files + the rubric before claiming.
// ---------------------------------------------------------------------------
async function generateStage(skill, _orig, _index) {
  const result = await agent(
    `You are auditing ONE skill: "${skill}".\n\n` +
      `GROUNDING DISCIPLINE — read before you claim (no working from memory):\n` +
      `1. Read .claude/skills/${skill}/SKILL.md in full.\n` +
      `2. Read every file under .claude/skills/${skill}/references/ and /assets/ that the SKILL.md links.\n` +
      `3. Read the review rubric ${RUBRIC} and its references/ files. Apply its\n` +
      `   Universal Rules and Review order. Quote the LIVE line for every finding —\n` +
      `   if you cannot quote it from the current file, do not file it.\n\n` +
      `For any routing-collision candidate, you MUST first run the rubric's Step-0\n` +
      `contention check: confirm the two skills genuinely contend (shared trigger\n` +
      `keyword or overlapping file-glob). If they contend, read BOTH skills'\n` +
      `when_to_use / "not when" — if each already deflects to the other, the overlap\n` +
      `is RESOLVED and is NOT a finding. Report a collision only when they truly\n` +
      `overlap AND a reciprocal tiebreaker is missing on at least one side.\n\n` +
      `Emit candidate findings as JSON. For each finding set "skill" to the skill\n` +
      `the finding is genuinely ABOUT (it may be a DIFFERENT skill than ${skill} if\n` +
      `the evidence points elsewhere — do not force it onto ${skill}). "evidence"\n` +
      `must be "file:line" plus the exact quoted line(s) from the current file.\n` +
      `If the skill is clean, return an empty findings array — invent nothing.`,
    {
      label: `generate:${skill}`,
      phase: "Generate",
      schema: FINDINGS_SCHEMA,
    }
  );
  // Stamp the reviewing skill so Backstop 1 can detect mis-attribution later.
  return (result.findings || []).map((f) => ({ ...f, _reviewedBy: skill }));
}

// ---------------------------------------------------------------------------
// Verify stage — INDEPENDENT, DEFAULT-REJECT. Re-reads the files and re-runs
// the Step-0 contention + reciprocal not-when check before any finding stands.
// ---------------------------------------------------------------------------
async function verifyStage(candidateFindings, _skill, index) {
  if (!candidateFindings || candidateFindings.length === 0) return [];

  const confirmed = [];
  for (let i = 0; i < candidateFindings.length; i++) {
    const f = candidateFindings[i];
    const verdict = await agent(
      `You are an ADVERSARIAL VERIFIER. DEFAULT TO REJECT. A finding stands ONLY\n` +
        `if it survives your own independent re-read — never trust the generator.\n\n` +
        `Candidate finding (finding #${index}-${i}):\n` +
        `  about-skill: ${f.skill}\n` +
        `  reviewed-by: ${f._reviewedBy}\n` +
        `  category:    ${f.category}\n` +
        `  severity:    ${f.severity}\n` +
        `  title:       ${f.title}\n` +
        `  evidence:    ${f.evidence}\n\n` +
        `Do ALL of the following, then return your verdict:\n` +
        `1. RE-READ .claude/skills/${f.skill}/SKILL.md (and any cited references file)\n` +
        `   yourself. Confirm the quoted evidence text appears VERBATIM at the cited\n` +
        `   file:line in the CURRENT file. If the quote is not in the live file, the\n` +
        `   finding is a hallucination -> isReal:false.\n` +
        `2. If category is "routing-collision": independently re-run the rubric's\n` +
        `   Step-0 contention check and the reciprocal "not when" check. Read BOTH\n` +
        `   contending skills' when_to_use / "not when". If each already deflects to\n` +
        `   the other, the overlap is RESOLVED -> isReal:false. A merely shared\n` +
        `   keyword between two NON-competing skills is not a collision -> isReal:false.\n` +
        `3. BACKSTOP 1 (re-attribution): determine which skill the finding is REALLY\n` +
        `   about from its TITLE and EVIDENCE, not from who reviewed it. A meta-skill\n` +
        `   agent (e.g. the one reviewing "skill-library-review") often over-reaches\n` +
        `   and attributes findings about OTHER skills to itself. Set "correctedSkill"\n` +
        `   to the true owning skill.\n\n` +
        `Set isReal:true ONLY if the evidence is verbatim-present AND (for collisions)\n` +
        `the reciprocal-tiebreaker check still fails. Otherwise isReal:false.`,
      {
        label: `verify:${f.skill}:${index}-${i}`,
        phase: "Verify",
        schema: VERDICT_SCHEMA,
      }
    );

    if (!verdict) {
      // Verifier rate-limited/errored (agent() returns null on terminal failure):
      // default-reject — a finding cannot be confirmed without an independent
      // re-read. Skip rather than null-deref and crash the whole skill's chain.
      log(`Verifier errored (default-reject) for "${f.title}" (${f.skill})`);
      continue;
    }
    if (verdict.isReal) {
      confirmed.push({
        ...f,
        skill: verdict.correctedSkill || f.skill,
        verifyReason: verdict.reason,
      });
    } else {
      log(`Gate rejected [${f.category}] "${f.title}" (${f.skill}): ${verdict.reason}`);
    }
  }
  return confirmed;
}

// ---------------------------------------------------------------------------
// Phase: Generate + Verify via the documented sharded harness. pipeline runs
// each skill through generate THEN verify independently (clean context per skill).
// ---------------------------------------------------------------------------
// Phase markers are assigned per-agent via {phase: "Generate"|"Verify"} inside
// each stage, so the stage agents bound their own phases. No pre-call markers
// here — those would fire before the pipeline and no longer bound their stages.
const perSkillConfirmed = await pipeline(skills, generateStage, verifyStage);

// pipeline returns one result per skill; flatten to a single finding list.
const verified = [];
for (const batch of perSkillConfirmed) {
  if (Array.isArray(batch)) {
    for (const f of batch) verified.push(f);
  }
}

// ---------------------------------------------------------------------------
// Phase: Backstop — the two pipeline-hygiene gaps the per-finding gate misses.
// ---------------------------------------------------------------------------
phase("Backstop");

// Backstop 1 — meta-skill mis-attribution. A finding's true owner is whatever
// its title/evidence describes, NOT the skill whose agent surfaced it. The
// verifier already re-attributed into `skill`; here we re-attribute once more
// from the finding's own title + evidence as the authoritative safety net.
const reattributed = await agent(
  `BACKSTOP 1 — meta-skill mis-attribution re-attribution.\n` +
    `A meta-skill reviewer (e.g. the agent reviewing "skill-library-review") can\n` +
    `attribute findings about OTHER skills to itself. For each finding below,\n` +
    `re-derive the skill it is REALLY about from its TITLE and EVIDENCE alone, and\n` +
    `overwrite "skill" with that true owner. Change nothing else.\n\n` +
    `Findings JSON:\n${JSON.stringify(verified)}`,
  {
    label: "backstop-1-reattribute",
    phase: "Backstop",
    schema: FINDINGS_SCHEMA,
  }
);
// Honor a legitimately-empty result (findings: []) instead of falling back to
// the prior set; only fall back when the field is absent/non-array (errored).
const finalFindings = reattributed && Array.isArray(reattributed.findings)
  ? reattributed.findings
  : verified;

// Backstop 1 returns a freshly-regenerated array, so the model can silently
// drop or hallucinate findings. Re-attribution must preserve count — if it
// didn't, the pass violated its own invariant, so we cannot trust it: discard
// the re-attribution and fall back to the verified (pre-backstop) set, which is
// already verify-gated and safe. Only "skill" attribution is lost, not findings.
let attributedFindings = finalFindings;
if (finalFindings.length !== verified.length) {
  log(
    `WARNING: Backstop 1 re-attribution changed finding count ` +
      `(${verified.length} in -> ${finalFindings.length} out). ` +
      `Re-attribution must only overwrite "skill", never add/drop findings — ` +
      `discarding the re-attribution and falling back to the verified set.`
  );
  attributedFindings = verified;
}

// Backstop 2 — dedup against existing issue BODIES, not just titles. Title-only
// dedup misses semantic duplicates (a CRM_API_KEY finding duplicated an open
// issue whose title never said "CRM"). Fetch open issues WITH bodies and drop
// any finding whose evidence/substance already appears in an issue body.
const deduped = await agent(
  `BACKSTOP 2 — dedup candidate findings against existing issue BODIES, not just titles.\n` +
    `Run: gh issue list --state open --limit 200 --json number,title,body\n` +
    `Then for EACH finding below, check whether its substance (the evidence/quote,\n` +
    `the file path, the specific defect) already appears anywhere in an existing\n` +
    `issue's BODY — even if no issue TITLE mentions it (e.g. a CRM_API_KEY finding\n` +
    `whose duplicate's title never said "CRM"). Drop every finding that is already\n` +
    `covered by an open issue body. Return the surviving non-duplicate findings in\n` +
    `"findings"; record each dropped duplicate as {title, issueNumber} in\n` +
    `"droppedAsDuplicate"; and set "issuesFetched" to how many open issues (with\n` +
    `bodies) you fetched and compared against.\n\n` +
    `Findings JSON:\n${JSON.stringify(attributedFindings)}`,
  {
    label: "backstop-2-body-dedup",
    phase: "Backstop",
    schema: DEDUP_SCHEMA,
  }
);

// Honor a legitimately-empty result (everything was a duplicate) instead of
// falling back to the pre-dedup set; only fall back when the field is absent.
const confirmedFindings = deduped && Array.isArray(deduped.findings)
  ? deduped.findings
  : attributedFindings;
const droppedCount = deduped && Array.isArray(deduped.droppedAsDuplicate)
  ? deduped.droppedAsDuplicate.length
  : 0;
log(
  `Backstop 2 dedup: fetched ${(deduped && deduped.issuesFetched) || 0} open issue bodies, ` +
    `dropped ${droppedCount} as duplicates.`
);
log(`Confirmed ${confirmedFindings.length} findings after verify gate + both backstops.`);

return confirmedFindings;
