---
name: social-growth
description: Write short LinkedIn and X promo posts that earn comments and click-throughs to a blog post or idea. Use when turning a published blog post into social posts, drafting a LinkedIn growth post in the engineering-leader voice, or writing the same-copy X fan-out. Triggers on "write the LinkedIn post", "social post for this blog", "LinkedIn growth post", "X promo post", "promote this post on social". Produces a LinkedIn-primary post (180–260 words) and an X variant (same copy, retuned to fit), plus Buffer-ready cadence notes. For long-form X articles/threads with ASCII diagrams in founder voice see x-longform-post. For marketing brief intake see marketing-shaper.
when_to_use: |
  Use when turning a published blog post into LinkedIn and X social posts,
  drafting a standalone LinkedIn growth post in the engineering-leader voice,
  writing the same-copy X fan-out from a LinkedIn draft, or promoting a raw
  idea without a blog post yet. Produces a LinkedIn-primary post (180–260 words)
  and an X variant, plus Buffer cadence notes when a blog file is the input.

  Not when: writing long-form X articles with ASCII diagrams or founder-voice
  threads — use x-longform-post instead. For cross-platform campaign planning or
  marketing brief intake use marketing-shaper.
---

# Social Growth Post Writer

LinkedIn-primary, X fan-out. One input — a blog post or a raw idea — produces two ready-to-paste outputs: a LinkedIn post that drives comments, and an X variant of the same copy tightened for the X feed.

This skill is what [blog-post-author](../blog-post-author/SKILL.md) invokes for its LinkedIn and X share-post asset tasks. It also works standalone when there's no blog file yet.

## Core rules

1. Accept either a blog file path (read end-to-end; extract takeaway, strongest line, one specific number, URL slug) or a raw idea/notes. Stop and ask for angle or strongest concrete claim if given only a vague topic.
2. LinkedIn is primary — copy quality is set here. X is a same-copy fan-out by default; don't tune X at the cost of LinkedIn signal.
3. Hook on line 1: rotate between `🌶️ Take:`, `✨ Shower Thought:`, bold standalone claim, or lived detail — see `references/hook-patterns.md`.
4. Target 180–260 words on LinkedIn. Each body paragraph is 1–3 sentences, no filler transitions, hard line breaks between paragraphs.
5. Close with a real question (not rhetorical) that the audience wants to type an answer to — see `references/hook-patterns.md` for patterns.
6. Include a CTA link only if a blog post exists. No blog → close on the question only.
7. Never invent metrics or anecdotes the user didn't supply — stop and ask instead.
8. Run the humanizer pass from `../content-ops/experts/humanizer.md` before finalizing. Target 90+.
9. Output two labeled blocks (LinkedIn + X) per `references/output-format.md`. Include Buffer cadence note only when input is a blog file.

## Audience and platform priority

- **LinkedIn — primary.** CTOs, VPs Eng, senior engineers, technical decision-makers.
- **X — fan-out.** Same copy. For game-design topics the priority may invert — ask before assuming LinkedIn-primary.

## What this skill does NOT do

- Long-form X articles with ASCII diagrams → [x-longform-post](../x-longform-post/SKILL.md)
- Cross-platform campaign planning → [marketing-shaper](../marketing-shaper/SKILL.md)
- Auto-queueing to Buffer → separate explicit step, requires user confirmation

## References

- [references/hook-patterns.md](references/hook-patterns.md) — hook type selection guide and closing question patterns
- [references/banned-vocabulary.md](references/banned-vocabulary.md) — banned words and constructions for both platforms
- [references/output-format.md](references/output-format.md) — LinkedIn structure, X variant rules, Buffer cadence note format
