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

4. **Batch the missing questions into a single AskUserQuestion call.** Group related questions. Do not interrogate the user with one question at a time. Aim for 3–6 focused questions covering the genuinely unknown bits. Skip questions whose answers are obvious from context.

5. **Fill the template** with the user's initial message + their answers. Where the user gave prose, distill it; do not pad.

6. **Output the filled template** in a single fenced markdown code block so the user can copy it. Add one line above it: *"Here is your marketing brief. Paste it into a fresh session, or say 'go' and I'll execute it now."* Then stop.

## Hard rules

- **Do not assign skills to subtasks.** Skill auto-selection works on description matching — naming skills explicitly suppresses better matches. Describe the *concern* ("landing page audit", "cold email sequence", "expert panel scoring"), never the skill filename.
- **Do not invent details.** If the user didn't say it and you didn't ask, leave the section as `<unknown — to investigate>`. A brief with honest gaps is more useful than a brief that hallucinates audiences or metrics.
- **Do not start the work** unless the user explicitly says "go" / "execute" / "do it" after seeing the brief.
- **Do not skip the questions step** even when you think you can guess. The point of this skill is to surface what the user hasn't thought through yet — guessing defeats the purpose.
- **One round of questions, not many.** If after one batch the brief is still thin, fill the gaps with `<unknown>` rather than starting a second interrogation.
- **Always ask about quality gates.** Every brief should clarify whether output should be scored by an expert panel before finalizing. This is the marketing equivalent of "should I write tests?"

## Output shape

```
Here is your marketing brief. Paste it into a fresh session, or say "go" and I'll execute it now.

```markdown
<filled template>
```
```

That's it. No commentary after the brief.
