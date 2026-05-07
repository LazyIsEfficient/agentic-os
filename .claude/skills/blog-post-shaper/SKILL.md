---
name: blog-post-shaper
description: Use to structure a vague blog-post idea into a well-scoped brief before any drafting begins. Triggers on "blog post on X", "write a blog about", "long-form post", "case study post", "explainer post", "opinion piece", "thought leadership post", or when invoked as the /blog-shape slash command. Produces a filled blog brief (opinion, case-study, or deep-dive) that blog-post-author consumes — the author then writes the post and emits one task file per declared asset (hero image, OG card, social posts, embedded diagrams, code samples, internal-link map) that the parent agent dispatches to subagents. Do not use for short social-format posts (X, LinkedIn) — go to marketing-shaper's content brief or x-longform-post. For engineering intake see prompt-shaper; for course intake see course-shaper; for game-design intake see game-design-shaper.
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

4. **Batch the missing questions into a single AskUserQuestion call.** Group related questions. Do not interrogate one at a time. Aim for 3–6 focused questions covering the genuinely unknown bits.

5. **Fill the template** with the user's initial message + their answers. Distill prose; do not pad. Where the user said "unknown", leave the section as `<unknown — to investigate>`.

6. **Output the filled template** in a single fenced markdown code block. Add one line above it: *"Here is your blog brief. Paste it into a fresh session and `blog-post-author` will draft the post and emit one task file per declared asset, or say 'go' and I'll hand it off now."* Then stop.

## Hard rules

- **Always ask about the asset bundle.** Every brief must declare which assets the post needs (hero image, OG card, social posts, embedded diagrams, code samples, internal-link map, newsletter excerpt). The downstream author emits one dispatch-ready task file per declared asset — under-declaring here means missing assets at publish time. This is the blog equivalent of "should I write tests?"
- **Always ask about the SEO surface.** Blog posts compete in search. The brief must capture target keyword (or "no SEO target — owned-audience only"), search intent, and meta description angle, even if the user defers to "you decide."
- **One single takeaway, stated as one sentence.** Push the user past topic ("AI agents") to claim ("Most AI agent failures are context-window failures, not model failures"). Briefs without a sharp takeaway produce mealy posts.
- **Do not assign skills to sections.** Describe concerns ("hero image generation", "internal-link audit", "expert-panel scoring before publish"), never skill filenames.
- **Do not invent audiences, metrics, or citations.** If the user didn't say it and you didn't ask, leave the section as `<unknown — to investigate>`. A brief with honest gaps is more useful than one that hallucinates a reader profile or fabricates a stat.
- **One round of questions, not many.** After one batch, fill remaining gaps with `<unknown>` rather than starting a second interrogation.
- **Do not start the work** unless the user says "go" / "execute" / "do it" after seeing the brief.

## Output shape

```
Here is your blog brief. Paste it into a fresh session and `blog-post-author` will draft the post and emit one task file per declared asset, or say "go" and I'll hand it off now.

```markdown
<filled template>
```
```

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
