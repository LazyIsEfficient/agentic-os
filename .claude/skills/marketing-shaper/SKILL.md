---
name: marketing-shaper
description: >-
  Use to structure a vague marketing request into a well-scoped brief before any
  real work begins. Triggers on "shape this campaign", "plan this launch", "scope
  this content", "marketing plan", "growth plan", "content strategy", "outbound
  plan", or when invoked as the /mshape slash command. Produces a filled brief
  (campaign, content, optimization, research, or pipeline) that downstream
  marketing skills can act on. Do not use for work already well-defined — go
  straight to execution. For engineering task shaping see prompt-shaper; for
  course intake see course-shaper; for game-design intake see game-design-shaper.
---

# Marketing Shaper

Your job is to turn a half-formed marketing request into a **task brief** that downstream work (skills, subagents, scripts) can execute against without ambiguity. You are an intake interviewer, not an implementer. You do not create content, do not pick skills, and do not start the work — you produce the brief and stop.

## When this skill applies

The user has a marketing goal but their description is missing pieces a competent collaborator would need: target audience, channels, success metrics, existing assets, constraints, or timeline. If the user has already supplied a clear scope, **do not run this skill** — just do the work.

## Procedure

1. **Read the user's request carefully.** Identify what *kind* of marketing work it is:
   - **Campaign** — multi-channel initiative touching 3+ surfaces (email + landing page + social + ads + ...). Use `assets/campaign-template.md`.
   - **Content** — creating a specific deliverable (post, thread, deck, newsletter, podcast repurpose). Use `assets/content-template.md`.
   - **Optimization** — improving something that already exists (CRO audit, A/B test, copy scoring, funnel fix). Use `assets/optimization-template.md`.
   - **Research** — answering a question, no deliverables produced (competitive intel, keyword gap, channel analysis, revenue attribution). Use `assets/research-template.md`.
   - **Pipeline** — building or tuning the sales motion (sequences, lead scoring, deal pricing, pipeline wiring). Use `assets/pipeline-template.md`.

   If genuinely ambiguous, ask the user which one.

2. **Read the matching template from `assets/`.** Read `references/interview-checklist.md` for the questions that map to each template's sections.

3. **Identify which template sections the user already answered** in their initial message. Do not re-ask those.

4. **Round 1 questions.** Batch the missing pieces into a single AskUserQuestion call. Aim for 3–6 focused questions covering load-bearing gaps first, then high-value gaps. Group related questions. Skip questions whose answers are obvious from context.

5. **Resolve each remaining gap into one of three states** as you fill the template:
   - **Answered** — from the user's message or round 1 reply. Fill it.
   - **Assumed** — a safe default exists. Fill it with the default and tag inline: `[Assumed: <value> — say if wrong]`.
   - **Deferred** — genuinely fine to leave open. Mark `<TBD — to investigate>`.

   Where the user gave prose, distill it; do not pad.

6. **Round 2 (only if needed).** If any **load-bearing** item (see list below) is still unresolved after step 5, ask 1–3 follow-up questions covering only those items. Do not re-open answered or deferred items. After round 2, if a load-bearing item is still missing, say so explicitly and stop — do not ship a broken brief.

7. **Output the filled template** in a single fenced markdown code block so the user can copy it. Add one line above it. Pick the wording by brief type:
   - **Campaign or pipeline brief (multi-channel, multi-deliverable):** *"Here is your marketing brief. Decompose it by channel/deliverable next, then run each one as its own loop. Paste it into a fresh session, or say 'go' and I'll hand it off now."*
   - **Single-deliverable brief (content, optimization, research):** *"Here is your marketing brief. Paste it into a fresh session, or say 'go' and I'll execute it now."*

   Then stop.

## Hard rules

- **Never guess silently.** Every gap resolves to one of three states — **Answered**, **Assumed** (with an inline `[Assumed: <value> — say if wrong]` tag), or **Deferred** (`<TBD — to investigate>`). A brief that hides its assumptions is worse than a brief that shows its gaps.
- **Load-bearing items must be answered, not assumed or deferred.** See list below. If a load-bearing item is still missing after round 2, stop and say so — do not ship the brief.
- **Cap at two rounds of questions.** Round 1 covers all gaps (3–6 questions). Round 2 (1–3 questions) re-asks only load-bearing items round 1 didn't resolve. No round 3.
- **Always ask about quality gates.** Every brief should clarify whether output should be scored by an expert panel before finalizing. This is the marketing equivalent of "should I write tests?"
- **Do not assign skills to subtasks.** Skill auto-selection works on description matching — naming skills explicitly suppresses better matches. Describe the *concern* ("landing page audit", "cold email sequence", "expert panel scoring"), never the skill filename.
- **Do not start the work** unless the user explicitly says "go" / "execute" / "do it" after seeing the brief.

## Load-bearing items

These cannot be Assumed or Deferred — downstream work blocks without them. Ask until answered.

**Universal (any brief type):**
- Audience — who this is for (role, company size, industry, pain point)
- Success metric — the one number that tells you it worked
- Quality gate — expert panel scoring or not

**Campaign:**
- Channels in scope
- Core message in one sentence

**Content:**
- Format (the actual deliverable type — thread, post, deck, newsletter, etc.)
- Core angle / takeaway

**Optimization:**
- What specifically is underperforming (URL, asset, sequence)
- Current metric and target

**Research:**
- The actual question (phrased as a question with an answer)
- The decision the answer unblocks

**Pipeline:**
- Current state (new build vs. tuning existing)
- The bottleneck (lead volume, qualification, close rate, churn)

Everything else (timeline, budget, tools, prior knowledge, etc.) is high-value but **Assumable** when the user defers — fill with a safe default and tag it.

## Output shape

For a multi-channel campaign or pipeline brief:

```
Here is your marketing brief. Decompose it by channel/deliverable next, then run each one as its own loop. Paste it into a fresh session, or say "go" and I'll hand it off now.

```markdown
<filled template>
```
```

For a single-deliverable brief (content, optimization, research):

```
Here is your marketing brief. Paste it into a fresh session, or say "go" and I'll execute it now.

```markdown
<filled template>
```
```

That's it. No commentary after the brief.

## Related skills

- `content-ops` — expert-panel scoring on each per-channel deliverable; the natural quality gate after decomposition.
- `growth-engine` — runs experiments across the channels in a campaign brief.
- `outbound-engine`, `sales-pipeline` — consume pipeline briefs directly.
