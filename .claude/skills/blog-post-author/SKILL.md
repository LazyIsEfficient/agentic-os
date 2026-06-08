---
name: blog-post-author
description: Use to draft a blog post from a filled blog-post-shaper brief — opinion, case study, or deep dive — and emit per-task files for the asset bundle (hero image, OG card, social posts, embedded diagrams, code samples, internal-link map, newsletter excerpt) so the calling agent can fan them out to subagents. Triggers on "write the blog post", "draft this post", "expand the blog brief", "author the post", or when handed a filled blog brief from blog-post-shaper. Writes one post against the brief and one file per asset task; does not reopen scope decisions. For intake shaping see blog-post-shaper. For a standalone LinkedIn/X promo post see social-growth; for other non-blog content (threads, decks, newsletters) see marketing-shaper. For courses see course-author.
when_to_use: |
  Use when you have a filled blog brief from `blog-post-shaper` and need to draft the post (opinion, case study, or deep dive) and emit one dispatch-ready task file per declared asset. Triggers on "write the blog post", "draft this post", "expand the blog brief", or "author the post".

  Not when: the idea is still vague or scoping decisions are unresolved — use `blog-post-shaper` first. Not when the deliverable is a LinkedIn or X promo post for the blog — use `social-growth` (the post's social-share posts are an asset this skill's bundle emits via `social-growth`). Not when the deliverable is a standalone tweet thread or deck, or a standalone newsletter — use `marketing-shaper` or `x-longform-post`; the post's newsletter *excerpt* is an asset this skill emits. Not when writing lesson content — use `course-author`.
---

# Blog Post Author

Your job is to turn a single blog brief into a publication-ready post **and** a directory of dispatch-ready task files (one per declared asset) that the calling agent can fan out to subagents. You are the writer and the task-file emitter — but only of asset tasks, not of the post's scope. You do not rescope, you do not change the takeaway, you do not add asset types the brief didn't declare.

## When this skill applies

You have a filled blog brief from `blog-post-shaper` (variant: opinion, case study, or deep dive). Your job is to draft the post against the brief's takeaway, voice, and length, then write one file per declared asset under `tasks/`.

If you were handed a raw idea without a brief, stop. Route back to `blog-post-shaper`. Drafting without a brief produces a post that feels fine and doesn't earn the publish.

## Procedure

1. **Read the brief end-to-end.** Single takeaway, target reader, voice, length, asset bundle, quality gate, and target slug are the contract. If any are blank or `<unknown>`, flag and stop — don't paper over it.
2. **Read the variant guidance** in [`references/post-structure.md`](references/post-structure.md) for the structural arc (hook → body → close).
3. **Draft the post** by filling [`assets/blog-post-template.md`](assets/blog-post-template.md). Match the brief's voice. Honor the length range. Open on the hook, never on filler.
4. **Verify the draft against the brief.** Single takeaway present and unambiguous? Voice matches reference posts? SEO meta written if SEO surface declared? Quality gate items achievable?
5. **Write task files.** For each asset declared in the brief's bundle, write one file `tasks/T-<slug>.md` using the template in [`references/asset-bundle.md`](references/asset-bundle.md). Skip asset types the brief did *not* declare. Do not invent new ones. The quality gate is always the final task and must reference every other task.
6. **Output**, in order:
   - the drafted post path
   - the list of task file paths (one per asset task), ordered for sequential dispatch with parallel groups called out inline
   - the next-step pointer

   Stop. The calling agent does the fan-out using its `Agent` tool — one subagent per task file.

## Universal rules

- **Stay inside the brief.** New takeaways, new sections, new asset types — those are intake decisions. Raise them; don't absorb them.
- **One concept per section.** If a section makes two claims, split it.
- **Hook over filler.** Open on the strongest sentence in the post. Never "in this post we'll explore…" or "imagine if…".
- **Match the reference posts the brief named.** Cadence, sentence length, paragraph rhythm.
- **Cite primary sources for technical claims.** Defer to `source-driven-development`. Don't invent URLs, version numbers, or stats.
- **Code snippets must be runnable as shown** unless explicitly labeled `// pseudocode` or `// excerpt`. Borrow [course-author/references/code-snippet-discipline.md](../course-author/references/code-snippet-discipline.md) if the post is technical.
- **Diagrams render on the target platform.** If the brief says Mermaid but the platform is Substack (no Mermaid support), flag and switch to image gen.
- **One task = one file = one subagent.** The task file is self-contained: a subagent reading only that file should know what to build, where to write the output, and how to verify success.
- **Output paths are real, not placeholders.** Substitute the post slug into every path before writing the task file.
- **No filler asset tasks.** If the brief said "no Twitter share post", do not emit a Twitter task "for completeness." The brief is the contract.
- **Cap each asset task at one output unit.** "Draft 4 diagrams" splits into 4 separate diagram task files.
- **Quality gate is the last task** and lists every prior task as a prerequisite in its prose.

## References

- [references/post-structure.md](references/post-structure.md) — hook → body → close arcs for opinion / case study / deep dive
- [references/asset-bundle.md](references/asset-bundle.md) — catalog of asset types and their task-file template

## Output shape

```
Post draft: content/blog/<slug>.md

Asset tasks (dispatch-ready, one file each):
  Sequential foundation:
    - tasks/T-post-draft.md          # already done; reference only
  Parallel batch (run after post draft):
    - tasks/T-hero-image.md
    - tasks/T-code-samples.md
    - tasks/T-internal-link-map.md   # mutates post body — serialize against pull-quotes
  Sequential after hero:
    - tasks/T-og-image.md
  Parallel batch (run after OG):
    - tasks/T-x-share.md
    - tasks/T-li-share.md
    - tasks/T-newsletter-excerpt.md
  Final gate:
    - tasks/T-quality-gate.md

Next step: hand each task file to a subagent (parent agent has Agent tool).
Tasks marked "Parallel batch" can be dispatched simultaneously.
```

The parallel/sequential grouping reflects real dependencies, not ceremony. If the brief produces only sequential tasks, list them as a single ordered list with no batches.

## Related skills

- [blog-post-shaper](../blog-post-shaper/SKILL.md) — produces the brief this skill consumes
- [content-ops](../content-ops/SKILL.md) — expert panel scoring of the drafted post; usually the final quality-gate task
- [autoresearch](../autoresearch/SKILL.md) — variant generation if the post is a high-stakes hero piece
- [source-driven-development](../source-driven-development/SKILL.md) — mandatory for citing APIs, specs, and vendor behavior in deep dives
- [documentation-writer](../documentation-writer/SKILL.md) — shares Mermaid discipline and incremental-update etiquette
- [code-simplification](../code-simplification/SKILL.md) — embedded code samples should pass the simplification bar
- [seo-ops](../seo-ops/SKILL.md) — keyword and search-intent inputs upstream; SEO meta validation downstream
- [course-author](../course-author/SKILL.md) — sibling content authoring skill; borrow code-snippet-discipline.md for technical posts
- [x-longform-post](../x-longform-post/SKILL.md) — sibling content type for X long-form, not blog
