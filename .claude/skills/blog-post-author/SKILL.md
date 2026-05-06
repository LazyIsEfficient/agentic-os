---
name: blog-post-author
description: Use to draft a blog post from a filled blog-post-shaper brief — opinion, case study, or deep dive — and emit a planning-and-task-breakdown DAG for the asset bundle (hero image, OG card, social posts, embedded diagrams, code samples, internal-link map, newsletter excerpt). Triggers on "write the blog post", "draft this post", "expand the blog brief", "author the post", or when handed a filled blog brief from blog-post-shaper. Writes one post against the brief and emits the asset DAG; does not reopen scope decisions. For intake shaping see blog-post-shaper. For non-blog content (threads, decks, newsletters, sequences) see marketing-shaper. For courses see course-author.
---

# Blog Post Author

Your job is to turn a single blog brief into a publication-ready post **and** an asset-bundle task DAG that the user can dispatch to generate the surrounding files (hero image, OG card, social posts, embedded diagrams, code samples, internal-link map, newsletter excerpt). You are the writer and the planner — but only of assets, not of the post itself. You do not rescope, you do not change the takeaway, you do not add asset types the brief didn't declare.

## When this skill applies

You have a filled blog brief from `blog-post-shaper` (variant: opinion, case study, or deep dive). Your job is to draft the post against the brief's takeaway, voice, and length, then emit one task block per declared asset using the `planning-and-task-breakdown` format.

If you were handed a raw idea without a brief, stop. Route back to `blog-post-shaper`. Drafting without a brief produces a post that feels fine and doesn't earn the publish.

## Procedure

1. **Read the brief end-to-end.** The single takeaway, target reader, voice, length, asset bundle, and quality gate are the contract. If any are blank or marked `<unknown>`, flag the brief and stop — don't paper over it.
2. **Read the variant guidance** in [`references/post-structure.md`](references/post-structure.md) for the structural arc (hook → body → close) appropriate to opinion / case study / deep dive.
3. **Draft the post** by filling [`assets/blog-post-template.md`](assets/blog-post-template.md). Match the brief's voice. Honor the length range. Open on the hook, never on filler ("In today's post, we'll explore…" is filler — delete it).
4. **Verify the draft against the brief.** Single takeaway present and unambiguous? Voice matches reference posts? SEO meta written if SEO surface declared? Quality gate items achievable?
5. **Emit the asset-bundle task DAG.** For each asset declared in the brief's asset bundle, write one task block following [`references/asset-bundle.md`](references/asset-bundle.md) — which catalogs the asset types and their declared `files_write` paths — using the format from `planning-and-task-breakdown/references/task-block-format.md`. Skip asset types the brief did *not* declare. Do not invent new ones.
6. **Output**, in order: the drafted post, then the asset DAG (with execution-DAG summary line on top), then a one-line "next step" pointer. Stop.

## Universal rules

- **Stay inside the brief.** New takeaways, new sections, new asset types — those are intake decisions. Raise them; don't absorb them.
- **One concept per section.** If a section makes two claims, split it.
- **Hook over filler.** Open on the strongest sentence in the post. Never "in this post we'll explore…" or "imagine if…".
- **Match the reference posts the brief named.** Cadence, sentence length, paragraph rhythm. The voice profile is in the brief — apply it.
- **Cite primary sources for technical claims.** Defer to `source-driven-development`. Don't invent URLs, version numbers, or stats.
- **Code snippets must be runnable as shown** unless explicitly labeled `// pseudocode` or `// excerpt`. Borrow `course-author/references/code-snippet-discipline.md` if the post is technical.
- **Diagrams render on the target platform.** If the brief says Mermaid but the platform is Substack (no Mermaid support), flag and switch to image gen — don't ship broken markdown.
- **Asset DAG fields are authoritative.** `files_write` paths must be the actual paths the user wants the assets at — not placeholders. `depends_on` reflects real dependencies (e.g. OG image waits on hero image when reusing the visual). `parallel_safe: true` is the default; only `false` when the task mutates shared state.
- **No filler asset tasks.** If the brief said "no Twitter share post", do not emit a Twitter task "for completeness." The brief is the contract.
- **Cap each asset task at scope: S.** If an asset feels like `M` or `L`, split it into multiple tasks (e.g. "draft 4 diagrams" splits into "diagram 1", "diagram 2", … so each runs in parallel).
- **Surface the quality gate as the final task.** Expert-panel scoring, AI humanizer pass, SEO meta validation — each is one task with `depends_on` set to every prior asset and the post draft itself.

## References

- [references/post-structure.md](references/post-structure.md) — the hook → body → close arcs for opinion / case study / deep dive
- [references/asset-bundle.md](references/asset-bundle.md) — catalog of every asset type the bundle can declare, with the standard `files_write` paths, prompts/specs to include in each task, and dependency hints

## Output shape

```
<drafted blog post — full prose, no commentary>

---

# Asset bundle — task DAG

**Execution DAG:** T-post-draft → (T-hero-image || T-code-samples || T-internal-link-map) → T-og-image → (T-x-share || T-li-share || T-newsletter-excerpt) → T-quality-gate

## Task: Hero image

```yaml
id: T-hero-image
depends_on: [T-post-draft]
...
```

**Description:** ...

**Acceptance criteria:**
- [ ] ...

**Verification:**
- [ ] ...

## Task: ...

(repeat for each declared asset)
```

Then a one-line next-step pointer: *"Post draft above is ready for review. Asset DAG below is dispatch-ready — load `planning-and-task-breakdown` and run each task in parallel where `parallel_safe: true`, or hand individual tasks to subagents."*

## Related skills

- [blog-post-shaper](../blog-post-shaper/SKILL.md) — produces the brief this skill consumes
- [planning-and-task-breakdown](../planning-and-task-breakdown/SKILL.md) — the DAG format the asset bundle uses; required reading for the task block contract
- [content-ops](../content-ops/SKILL.md) — expert panel scoring of the drafted post; usually the final quality-gate task
- [autoresearch](../autoresearch/SKILL.md) — variant generation if the post is a high-stakes hero piece
- [source-driven-development](../source-driven-development/SKILL.md) — mandatory for citing APIs, specs, and vendor behavior in deep dives
- [documentation-writer](../documentation-writer/SKILL.md) — shares Mermaid discipline and incremental-update etiquette
- [code-simplification](../code-simplification/SKILL.md) — embedded code samples should pass the simplification bar
- [seo-ops](../seo-ops/SKILL.md) — keyword and search-intent inputs upstream; SEO meta validation downstream
- [course-author](../course-author/SKILL.md) — sibling content authoring skill; borrow code-snippet-discipline.md for technical posts
- [x-longform-post](../x-longform-post/SKILL.md) — sibling content type for X long-form, not blog
