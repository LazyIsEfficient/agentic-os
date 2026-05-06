# blog-post-shaper — opinion

Example of `/blog-shape` producing an `opinion-template.md` brief — a thought-leadership post with a contrarian claim.

---

## User's initial request

> I want to write a blog post about why "AI agent reliability" is mostly a context-engineering problem, not a model problem. Aimed at engineering leaders.

## Shaper's batched questions

Argument-driven, position taken, audience clear-ish — routes to `opinion-template.md`.

1. **Single takeaway sentence** — sharpen "context engineering, not model" into one sentence the reader leaves with. "Most AI agent failures are context engineering bugs, not model bugs"?
2. **Why now / argument structure** — what made this post timely, and what 2–4 claims support the takeaway?
3. **Counterargument** — what's the strongest "but the model *is* the problem" objection a hostile reader will raise?
4. **Voice + length** — match founder voice or another reference, and how long should this run?
5. **SEO surface + publication context** — own blog vs Substack/Medium, and is there a target keyword or is this owned-audience only?
6. **Asset bundle** — yes/no on each: hero image, OG card, X share thread, LinkedIn share, newsletter excerpt, embedded diagrams, internal-link map.

## User's answers

1. "Most AI agent failures get blamed on the model when they're actually context engineering bugs the team never instrumented."
2. Why now: every team I talk to is upgrading models hoping reliability will fix itself. Claims: (a) the failure mode is reproducible across models, so it isn't model-specific; (b) the failures cluster around context-window edges (truncation, ordering, missing tools); (c) teams that instrument their context get reliability without changing models. Recent trigger: I keep seeing the same Slack message — "we upgraded to Sonnet 4.6, why is reliability still bad?"
3. The strongest objection: "but the bigger model *does* fix some of these — we measured it." Yes — for some cases, but the fix is shallow and regresses when context grows. Worth naming directly.
4. Match founder voice profile. Length 1500–2200.
5. Own blog (own domain). SEO target: "AI agent reliability" as primary, "context engineering" secondary, informational intent.
6. Hero image: yes, generated, abstract — something that conveys "context window stuffed with garbage." OG card: separate from hero, with the takeaway sentence as the title overlay. X share: thread with the three claims as separate posts. LinkedIn: yes, single post. Newsletter excerpt: pull-quote with the takeaway. Embedded diagrams: one ASCII diagram showing "model upgrade vs context fix" timing curves. Internal-link map: link to my prior post on prompt caching, and one on observability for agents. Quality gate: yes, expert panel + humanizer pass.

## Output brief

```markdown
## Working title
Most AI Agent Failures Are Context Engineering Bugs, Not Model Bugs

## Variant
opinion / thought leadership

## Single takeaway
Most AI agent failures get blamed on the model when they're actually context engineering bugs the team never instrumented.

## Why now
Every engineering team I talk to is upgrading models hoping reliability will fix itself. The recurring Slack message: "we upgraded to Sonnet 4.6, why is reliability still bad?" The model upgrade keeps not fixing the problem because the problem isn't the model.

## Argument structure
1. The failure mode is reproducible across models — same prompts, same shape of failure, different vendors. That tells you the bug is upstream of the model.
2. The failures cluster around context-window edges: truncation, ordering, missing tool definitions, stale memory. None of those are weights problems.
3. Teams that instrument their context — what's in it, in what order, at what point in the trace — fix reliability without changing models.

## Evidence
- Anecdote: three teams in the last quarter that "fixed" reliability by switching models, then watched it regress two weeks later when their context grew.
- Reproducibility data: the same eval shape fails across Sonnet, Opus, GPT-4-class, Gemini — same percentile, same shape.
- Counter-example: one team that instrumented context shape (slot-by-slot tracing) and lifted P50 reliability 23 points without changing the model.

## Counterargument acknowledged
"The bigger model *does* fix some failures — we measured it." True for some cases. But the fix is shallow: it pushes the failure mode out by ~10–15% headroom, and regresses when context grows back into that band. The lift looks impressive in eval; it fails in production.

## Stakes
Engineering leaders are paying 2–5× per token for upgrades that don't fix what they think they're fixing — and they're not investing in the instrumentation that would. The gap compounds: every quarter the agent stack grows, the context grows with it, and the unfixed bugs scale linearly.

## Target reader
- Who: engineering leaders shipping AI agents in production — VPs of Engineering, staff engineers, AI/ML platform leads.
- Funnel stage: awareness — building authority, not pushing a CTA.
- What they currently believe: reliability is a model-quality problem, and the next model release will fix it.

## Voice and tone
- Match founder voice profile.
- Reference posts: prior post on prompt caching (cadence and ASCII-diagram style). Prior post on agent observability (vocabulary).
- Constraints: no em-dashes, no AI-tell phrases, no rhetorical-question-then-answer, no "let's dive in", word range 1500–2200.

## Length
- Target: 1500–2200 words
- Hard ceiling: 2400 words

## SEO surface
- Target keyword: "AI agent reliability" (primary), "context engineering" (secondary)
- Search intent: informational — engineering leaders evaluating where reliability problems come from
- Meta description angle: "Reliability problems get blamed on the model. They're usually context engineering bugs — here's how to tell, and what to instrument."
- URL slug suggestion: ai-agent-reliability-context-engineering

## Asset bundle (required — author emits task DAG from this list)
- [x] Hero / featured image — generated, abstract; "context window stuffed with garbage" angle
- [x] OG / social share image (1200×630) — separate from hero; takeaway sentence as title overlay
- [x] X (Twitter) share post — thread of 3–5 posts mirroring the three claims
- [x] LinkedIn share post — single post, ~1200 chars, opening on the takeaway
- [x] Newsletter excerpt — pull-quote with the takeaway sentence + lede paraphrase, 200–400 words
- [x] Embedded diagrams — one ASCII diagram showing "model upgrade reliability curve" vs "context fix reliability curve"
- [ ] Code samples — none
- [x] Internal-link map — link to prior prompt-caching post and prior agent-observability post; auto-suggest 1–2 more
- [x] Pull quotes / callouts — 2 callouts (the counterargument + its rebuttal; the takeaway)
- [ ] Author bio / sign-off — standard

## Publication context
- Platform: own blog (own domain)
- Author byline: standard
- Cross-post plan: re-post on LinkedIn after 7 days; no Medium / Substack cross-post
- Comments enabled: no

## Source material
- Newsletter draft from last month covering adjacent ground (instrumenting agents, not the contrarian framing)
- Three customer call notes referencing the recurring Slack message
- Internal eval data (anonymized) showing the cross-model failure shape

## Scope
- In: argument that reliability is upstream of the model; named failure modes (truncation, ordering, missing tools, stale memory); the instrumentation prescription; one concrete counter-example team
- Out: tool recommendations, vendor names beyond model families, a survey of context-window sizes, code snippets, deep dive on each named failure mode (those become follow-up posts)

## Quality gate
- [x] Expert panel score 90+ (content quality + strategic quality)
- [x] AI humanizer pass clean (no detectable AI patterns)
- [x] Source citations checked against primary docs (eval methodology described accurately)
- [x] SEO meta validated (title ≤60 chars, description ≤155 chars, slug under 5 words)

## Approach
1. Review newsletter draft and reference posts for voice cadence.
2. Draft the post in the target length and tone. Stop for approval.
3. Run through expert panel scoring (target 90+). Iterate until passing.
4. Run AI humanizer pass (24-pattern check). Fix any flagged patterns.
5. Emit the asset-bundle task DAG (planning-and-task-breakdown format) — one task per declared asset, with `files_write`, `depends_on`, and `parallel_safe` set so the user can dispatch agents to generate them.

## Deliverable
- One publication-ready blog post in target length
- Expert panel scorecard
- Asset-bundle task DAG ready for agent dispatch

## Open questions
- Whether to name a specific vendor in the cross-model failure-shape evidence, or keep it abstract. (Default: abstract, cite "across Sonnet/Opus/GPT-4-class/Gemini" without per-vendor numbers.)
```

---

**Next step:** paste this into a fresh session and `blog-post-author` will draft the post and emit the asset-bundle task DAG, or say `go` and the executor takes the brief through draft + DAG.
