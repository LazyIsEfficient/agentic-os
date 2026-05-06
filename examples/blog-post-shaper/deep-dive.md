# blog-post-shaper — deep dive / explainer

Example of `/blog-shape` producing a `deep-dive-template.md` brief — concept-heavy explainer post with a worked example.

---

## User's initial request

> Deep dive blog post explaining how prompt caching actually works in the Anthropic API — the bit most people get wrong is the cost asymmetry between cache writes and cache reads. Aimed at engineers who are already using the API.

## Shaper's batched questions

Concept-heavy, opinionated angle, audience clear — routes to `deep-dive-template.md`. Note: the user already has a clear *concept* (cost asymmetry) — push for the mental model and the worked example.

1. **Mental model in 3–5 sentences** — what's the model the reader leaves with? "Cache writes are 1.25× the base price; reads are 0.1×; so the breakeven is one read of the cached prefix"?
2. **Worked example** — what's the single concrete case the post unpacks? A call with a 5K-token system prompt, called 50× / hour?
3. **Misconceptions to correct** — what do readers probably believe that's wrong? "Caching is free", "cache hit rate is the metric", others?
4. **Citations needed** — Anthropic prompt-caching docs, anything else? Anything you don't yet have but will need to verify?
5. **Length + voice + diagrams** — how long, voice-match which prior post, and what diagrams (Mermaid / ASCII / generated)?
6. **SEO + asset bundle** — own blog, target keyword, and yes/no on hero/OG/X share/LinkedIn/newsletter/code-samples-repo/internal-links.

## User's answers

1. Model: "Prompt caching has two prices — write at 1.25× base, read at 0.1× base. Breakeven is one cache hit. Hit rate above 50% pays back massively; below 50% costs more than no caching." Add: cache TTL is 5 minutes; everything before the cache_control marker gets cached as a unit.
2. Worked example: a call with a 5,000-token system prompt + tools, called 50 times per hour from a chat product. Walk through total cost with caching off, total cost with caching on at varying hit rates.
3. Misconceptions: (a) "caching is free" (no — writes cost extra), (b) "cache hit rate is the metric" (better metric: cache-attributable cost reduction, since high hit rate at low absolute volume saves nothing), (c) "you can cache anything before the marker" (yes, but if anything before the marker changes between calls, the cache invalidates wholesale — most teams don't realize their tool definitions are unstable).
4. Citations: Anthropic prompt-caching docs (current). Source-driven-development for any quoted multipliers — confirm 1.25× and 0.1× against current docs at draft time. No academic papers needed.
5. Length 2500–3500. Match founder voice with a slightly more technical lean — reference: prior post on Anthropic API rate limits. Diagrams: 2 — one Mermaid showing the cache lifecycle (write → reads within TTL → expiry), one ASCII showing the cost-vs-hit-rate curve crossing the no-cache baseline at ~50%.
6. Own blog. SEO: "Anthropic prompt caching" primary, "prompt caching cost" secondary, informational. Hero: yes, generated, abstract — visualize the cost crossover. OG: separate from hero, with the takeaway as overlay. X: thread. LinkedIn: yes. Newsletter: pull-quote with the takeaway. Code samples: yes — extracted to a runnable repo, one example per misconception. Internal-link: link to my prior post on rate limits and prior post on tool-definition stability. Quality gate: expert panel + humanizer + source-driven-development for the multipliers.

## Output brief

```markdown
## Working title
Prompt Caching, Explained: Why Most Teams Get the Cost Math Wrong

## Variant
deep dive / explainer

## Single takeaway
Prompt caching has two prices — writes at 1.25× base, reads at 0.1× base. Breakeven is one cache hit; below ~50% hit rate, caching costs *more* than not caching.

## Concept under explanation
The cost asymmetry between cache writes and cache reads in the Anthropic API, and why hit rate is necessary but not sufficient as a metric — cache-attributable cost reduction is the real number.

## Prior knowledge assumed
- Basic comfort with the Anthropic SDK (`messages.create` round-trip)
- Familiar with the concept of system prompts and tool definitions
- Comfortable with simple cost arithmetic (token counts × per-token rates)

## Mental model the post builds
Prompt caching is a two-price system. Writes cost 1.25× the base input rate (the cache-write premium). Reads cost 0.1× the base rate. Cache TTL is 5 minutes; anything before the `cache_control` marker is cached as a unit, and any change to anything before the marker invalidates the entire cache. Breakeven is exactly one cache hit. Below ~50% hit rate (combined with cache TTL), caching costs more than running uncached. Above 50%, the savings compound aggressively.

## Worked example
A chat product calling the API with a 5,000-token system prompt + 1,500 tokens of tool definitions, 50 times per hour from a single user session.

- Uncached: 50 × 6,500 input tokens at base rate = X cost/hour
- Cached at 90% hit rate: 5 cache writes (6,500 × 1.25×) + 45 cache reads (6,500 × 0.1×) = Y cost/hour, savings ≈ Z%
- Cached at 30% hit rate (frequent invalidation due to unstable tool definitions): cache writes outweigh read savings, costs *more* than uncached.

The post walks through this case exactly, with the math visible.

## Common misconceptions to correct
- **"Caching is free."** No — writes cost 1.25× the base rate. If your hit rate is poor, caching is actively more expensive than not caching.
- **"Cache hit rate is the metric."** Better metric: cache-attributable cost reduction. A 95% hit rate on 100 calls/day saves trivial money; a 60% hit rate on 100,000 calls/day saves real money. Hit rate is necessary but not sufficient.
- **"You can cache anything before the marker."** Technically yes, but if *anything* before the marker changes between calls — even your tool definitions when you add a new tool — the cache invalidates wholesale. Most teams don't realize their tool definitions aren't stable across deploys, which silently kills their hit rate.

## Source citations required
- Anthropic prompt-caching documentation (current — must verify the 1.25× write multiplier and 0.1× read multiplier against the docs at draft time, defer to source-driven-development)
- Anthropic API rate limits documentation (referenced in passing)
- No academic papers required

## Target reader
- Who: engineers already using the Anthropic API who have seen "caching" in the docs and either (a) haven't turned it on, or (b) turned it on without measuring the cost impact
- Funnel stage: consideration — they're evaluating whether to invest in caching properly
- Why they care: they're spending real money on API calls, and someone keeps suggesting "have you turned on caching?"

## Voice and tone
- Match founder voice profile, slightly more technical lean
- Reference posts: prior post on Anthropic API rate limits (cadence and technical density), prior post on tool-definition stability (vocabulary)
- Constraints: no em-dashes, no AI-tell phrases, no rhetorical-question-then-answer, no "let's dive in", word range 2500–3500

## Length
- Target: 2500–3500 words
- Hard ceiling: 4000 words

## SEO surface
- Target keyword: "Anthropic prompt caching" (primary), "prompt caching cost" (secondary)
- Search intent: informational — engineers researching whether to use prompt caching and how
- Meta description angle: "Prompt caching has two prices, not one. Below ~50% hit rate, caching costs more than not caching. Here's the math, with a worked example."
- URL slug suggestion: anthropic-prompt-caching-explained

## Asset bundle (required — author emits task DAG from this list)
- [x] Hero / featured image — generated, abstract; visualize the cost crossover (caching cost vs uncached cost as hit rate climbs)
- [x] OG / social share image (1200×630) — separate from hero; "Below 50% hit rate, caching costs *more*" as overlay
- [x] X (Twitter) share post — thread (5–7 posts) walking through the worked example with the math
- [x] LinkedIn share post — single, ~1200 chars, opening on the takeaway
- [x] Newsletter excerpt — pull-quote with the takeaway + lede paraphrase, 200–400 words
- [x] Embedded diagrams — 2: (1) Mermaid showing the cache lifecycle (write → reads within TTL → expiry → re-write), (2) ASCII showing cost-vs-hit-rate curve crossing the no-cache baseline at ~50%
- [ ] Embedded charts / data viz — covered by the diagrams above
- [x] Code samples — extracted to a runnable repo (TypeScript). Three examples: (1) basic caching with stable system prompt, (2) measuring hit rate from API responses, (3) the unstable-tool-definition trap with before/after metric capture
- [x] Glossary / sidebar of terms — yes: "cache write", "cache read", "TTL", "cache_control marker", "cache-attributable cost reduction"
- [x] Internal-link map — link to prior rate-limits post and prior tool-definition-stability post; auto-suggest 1–2 more
- [x] Pull quotes / callouts — 3: the takeaway, the misconception about "free", the misconception about hit rate being the metric
- [x] Table of contents / outline — yes (post is long)

## Publication context
- Platform: own blog (own domain)
- Author byline: standard
- Cross-post plan: no cross-post (own audience first; revisit in 30 days)
- Comments enabled: yes

## Source material
- Anthropic prompt-caching docs (download fresh version at draft time)
- Two prior posts by the author on adjacent topics (rate limits, tool stability)
- Internal cost-experiment data (anonymized): a real call pattern showing the cost crossover at ~52% hit rate
- Sample app from prior course module on Anthropic API (to fork for the runnable code samples)
- Citations to gather: confirm the 1.25× and 0.1× multipliers against current Anthropic docs (defer to source-driven-development)

## Scope
- In: cost asymmetry math, the worked example, the three misconceptions, the cache lifecycle diagram, the cost-vs-hit-rate curve, the runnable code samples, the metric prescription (cache-attributable cost reduction)
- Out: comparison to OpenAI / Gemini caching mechanics (separate post), advanced topics like extended cache TTL or cache-aware prompt construction (follow-up post), code patterns for measuring hit rate at scale (separate operational post)

## Quality gate
- [x] Expert panel score 90+ (content quality + strategic quality)
- [x] AI humanizer pass clean
- [x] All technical claims cite primary sources (no training-data folklore)
- [x] Code samples runnable as shown
- [x] Diagrams render correctly on the target platform (own blog renders Mermaid; ASCII universal)
- [x] SEO meta validated

## Approach
1. Review source material; download current Anthropic prompt-caching docs and verify the 1.25× and 0.1× multipliers (defer to source-driven-development).
2. Draft the worked example first — the post is built around it. Numbers must be exact.
3. Draft the surrounding prose: hook, mental model, misconception callouts, close. Stop for approval.
4. Run through expert panel scoring (target 90+). Iterate until passing.
5. Run AI humanizer pass (24-pattern check). Fix any flagged patterns.
6. Emit the asset-bundle task DAG (planning-and-task-breakdown format) — one task per declared asset, with `files_write`, `depends_on`, and `parallel_safe` set so the user can dispatch agents to generate them.

## Deliverable
- One publication-ready deep-dive post in target length
- Expert panel scorecard
- Source citation list (Anthropic docs versions cited)
- Runnable code-sample repo (3 examples)
- Asset-bundle task DAG ready for agent dispatch

## Open questions
- Whether to include a section on "extended cache TTL" (1-hour cache option) or defer to a follow-up post. Default: defer — keep this post focused on the cost asymmetry mental model.
- Whether the runnable code samples should target both TypeScript and Python, or TypeScript-only with a "Python equivalent in the README" note. Default: TS-only with a README note.
```

---

**Next step:** paste this into a fresh session and `blog-post-author` will draft the post and emit the asset-bundle task DAG, or say `go` and the executor takes the brief through draft + DAG. Pull the current Anthropic docs first — the 1.25× and 0.1× multipliers are load-bearing for the entire post; any drift in the docs invalidates the math.
