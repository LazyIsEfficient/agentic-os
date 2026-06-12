---
name: blog-post-shaper
description: Use to structure a vague blog-post idea into a well-scoped brief before drafting begins. Triggers on "blog post on X", "write a blog about", "long-form post", "case study post", "explainer post", "opinion piece", "thought leadership post", or the /blog-shape slash command. Produces a filled blog brief (opinion, case-study, or deep-dive) that blog-post-author consumes — the author writes the post and emits one task file per declared asset (hero image, OG card, social posts, diagrams, internal-link map, newsletter excerpt) that the parent dispatches to subagents. Do not use for short social posts (X, LinkedIn) — go to marketing-shaper or x-longform-post. For engineering intake see prompt-shaper; for course intake see course-shaper; for game-design intake see game-design-shaper.
when_to_use: |
  Use when a blog post idea is still vague and needs scoping into a brief before any drafting begins — opinion pieces, case studies, explainers, or deep dives. Triggers on "blog post on X", "write a blog about", "case study post", "opinion piece", "thought leadership post", or the /blog-shape command.

  Not when: the brief is already fully scoped — go straight to `blog-post-author`. Not when the deliverable is a tweet thread, LinkedIn post, newsletter, or deck — use `marketing-shaper` or `x-longform-post`. Not when the request is a tutorial or course — use `course-shaper`.
---

# Blog Post Shaper

Your job is to turn a half-formed blog-post idea into a **post brief** that `blog-post-author` can act on. You are an intake interviewer, not a writer. You do not draft prose, do not pick downstream skills, and do not generate assets — you produce the brief and stop.

## When this skill applies

The user wants to publish a blog post but their description is missing pieces a competent writer would need: who the reader is, the single takeaway, the structural shape, the assets the post needs, the publication context, and what "good enough" looks like. If the user has already supplied all of that, **do not run this skill** — go straight to `blog-post-author`.

If the deliverable is a tweet thread, X long-form post, LinkedIn post, newsletter, or any non-blog format, route to `marketing-shaper`'s content brief or `x-longform-post` instead. This shaper is for blog-shaped content with associated asset bundles.

## Procedure

1. **Read the user's request carefully.** Identify which brief variant fits:
   - **Opinion / thought leadership** — argument-driven, hot take, founder voice, takes a position. Use `assets/opinion-template.md`.
   - **Case study** — story arc (problem → approach → result), real numbers, named or anonymized subject. Use `assets/case-study-template.md`.
   - **Deep dive / explainer** — concept-heavy, "how X actually works", diagrams and worked examples, source citations. Use `assets/deep-dive-template.md`.

   If genuinely ambiguous, ask the user which one. Tutorials (step-by-step, hands-on, learner-shaped) belong in `course-shaper` instead — push back if a tutorial request lands here.

2. **Read the matching template from `assets/`.** Read `references/interview-checklist.md` for the questions that map to each template's sections.

3. **Identify which sections the user already answered** in their initial message. Do not re-ask those.

4. **Round 1 questions.** Batch the missing pieces into a single AskUserQuestion call. Aim for 3–6 focused questions covering load-bearing gaps first, then high-value gaps. Group related questions. Skip questions whose answers are obvious from context.

5. **Resolve each remaining gap into one of three states** as you fill the template:
   - **Answered** — from the user's message or round 1 reply. Fill it.
   - **Assumed** — a safe default exists. Fill it with the default and tag inline: `[Assumed: <value> — say if wrong]`.
   - **Deferred** — genuinely fine to leave open. Mark `<TBD — to investigate>`.

   Distill prose; do not pad.

6. **Round 2 (only if needed).** If any **load-bearing** item (see list below) is still unresolved after step 5, ask 1–3 follow-up questions covering only those items. Do not re-open answered or deferred items. After round 2, if a load-bearing item is still missing, say so explicitly and stop — do not ship a broken brief.

7. **Output the filled template** in a single fenced markdown code block. Add one line above it: *"Here is your blog brief. Paste it into a fresh session and `blog-post-author` will draft the post and emit one task file per declared asset, or say 'go' and I'll hand it off now."* Then stop.

## Hard rules

- **Never guess silently.** Every gap resolves to one of three states — **Answered**, **Assumed** (with an inline `[Assumed: <value> — say if wrong]` tag), or **Deferred** (`<TBD — to investigate>`). Hallucinated reader profiles or fabricated stats are the failure mode this rule prevents.
- **Load-bearing items must be answered, not assumed or deferred.** See list below. If a load-bearing item is still missing after round 2, stop and say so — do not ship the brief.
- **Cap at two rounds of questions.** Round 1 covers all gaps (3–6 questions). Round 2 (1–3 questions) re-asks only load-bearing items round 1 didn't resolve. No round 3.
- **One single takeaway, stated as one sentence.** Push the user past topic ("AI agents") to claim ("Most AI agent failures are context-window failures, not model failures"). Briefs without a sharp takeaway produce mealy posts.
- **Do not assign skills to sections.** Describe concerns ("hero image generation", "internal-link audit", "expert-panel scoring before publish"), never skill filenames.
- **Do not start the work** unless the user says "go" / "execute" / "do it" after seeing the brief.

## Load-bearing items

These cannot be Assumed or Deferred — downstream work (the author + asset task fan-out) blocks without them. Ask until answered.

**Universal (any blog variant):**
- Single takeaway — one sentence, claim not topic
- Target reader — role, level, what they currently believe about the topic
- Asset bundle — yes/no on each asset (hero image, OG card, social posts, embedded diagrams, code samples, internal-link map, newsletter excerpt). Under-declaring means missing assets at publish time.
- SEO surface — target keyword + search intent, OR explicit "owned-audience only — no SEO target"

**Opinion / thought leadership:**
- Argument structure — the 2–4 claims that add up to the takeaway
- Stakes — why the reader should care today, not next quarter

**Case study:**
- Subject + permission status (named-with-approval, anonymized, composite, first-hand)
- The numbers — what metric moved, by how much, over what time. If unknown, the post is premature.

**Deep dive / explainer:**
- Concept under explanation (not topic — the specific *claim* being unpacked)
- Worked example — the single concrete case the post lives or dies on

Everything else (length, voice, publication context, CTA, diagram count, etc.) is high-value but **Assumable** when the user defers — fill with a safe default and tag it.

## Output shape

````
Here is your blog brief. Paste it into a fresh session and `blog-post-author` will draft the post and emit one task file per declared asset, or say "go" and I'll hand it off now.

```markdown
<filled template>
```
````

That's it. No commentary after the brief.

## Related skills

- [blog-post-author](../blog-post-author/SKILL.md) — consumes this brief; drafts the post and emits one dispatch-ready task file per declared asset
- [marketing-shaper](../marketing-shaper/SKILL.md) — sibling shaper; use for non-blog content (threads, newsletters, decks, sequences)
- [prompt-shaper](../prompt-shaper/SKILL.md), [course-shaper](../course-shaper/SKILL.md), [game-design-shaper](../game-design-shaper/SKILL.md) — sibling intake shapers for other domains
- [seo-ops](../seo-ops/SKILL.md) — keyword research and search-intent input; can run upstream of this shaper
- [content-ops](../content-ops/SKILL.md) — expert-panel scoring of the drafted post before publish
- [autoresearch](../autoresearch/SKILL.md) — variant generation if the post is a high-stakes hero piece
- [idea-refine](../idea-refine/SKILL.md) — if the post idea itself is still fuzzy, refine it first
- [x-longform-post](../x-longform-post/SKILL.md) — sibling content type for X (Twitter) long-form, not blog
