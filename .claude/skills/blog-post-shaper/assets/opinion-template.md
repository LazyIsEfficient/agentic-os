## Working title
<title — sharper later, but commit to a frame now>

## Variant
opinion / thought leadership

## Single takeaway
<one sentence — the claim the reader leaves with. Not a topic, a position.>

## Why now
<what made this post timely — a recent event, a recurring debate the user keeps having, a market shift, a contrarian read on a hot topic>

## Argument structure
1. <claim 1 — supports the takeaway>
2. <claim 2>
3. <claim 3>

(Each claim should be defensible on its own. The takeaway is what they add up to.)

## Evidence
- <data point, anecdote, citation, or first-hand observation backing claim 1>
- <…claim 2>
- <…claim 3>

## Counterargument acknowledged
<the strongest objection a hostile reader will raise — name it, then say why the takeaway still holds>

## Stakes
<what's at risk if the reader ignores this — the cost of staying inside the conventional wisdom>

## Target reader
- Who: <role, level, industry, current belief>
- Funnel stage: <awareness | consideration | decision>
- What they currently believe: <the conventional wisdom this post pushes against>

## Voice and tone
- <founder voice, contrarian, authoritative, deadpan, etc.>
- Reference posts to match: <named prior post, or "match founder voice profile">
- Constraints: <no em-dashes, no AI-tell phrases, no rhetorical-question-then-answer, character/word ranges, banned words>

## Length
- Target: <word count range, e.g. 1200–1800>
- Hard ceiling: <if any>

## SEO surface
- Target keyword: <"none — owned-audience only" | primary keyword + 1-2 secondaries>
- Search intent: <informational | commercial | navigational | "n/a">
- Meta description angle: <one sentence the SERP snippet should communicate>
- URL slug suggestion: <short-and-keyword-bearing, or "auto">

## Asset bundle (required — author emits task DAG from this list)
- [ ] Hero / featured image — <generated | designed | stock | none>; describe the visual angle
- [ ] OG / social share image (1200×630) — <separate from hero | reuse hero>
- [ ] X (Twitter) share post — <thread | single | none>
- [ ] LinkedIn share post — <yes | no>
- [ ] Newsletter excerpt — <pull-quote | rewritten lede | none>
- [ ] Embedded diagrams — <Mermaid | ASCII | generated images | none>; how many, what they show
- [ ] Code samples — <inline only | extracted to runnable repo | none>
- [ ] Internal-link map — <list 2–5 prior posts to link from inside this one | "none — first post in series" | "auto from sitemap">
- [ ] Pull quotes / callouts — <how many | none>
- [ ] Author bio / sign-off — <standard | custom for this post | none>

## Publication context
- Platform: <own blog | Substack | Medium | LinkedIn article | Hashnode | guest post on X | …>
- Author byline: <…>
- Cross-post plan: <yes/no, where, with what delay>
- Comments enabled: <yes | no>

## Source material
- <existing draft, notes, prior post, transcript, dataset, internal memo>
- <or "none — original creation">

## Scope
- In: <what this post covers>
- Out: <what it explicitly does NOT cover or expand into>

## Quality gate
- [ ] Expert panel score 90+ (content quality + strategic quality) — <yes | no — justify>
- [ ] AI humanizer pass clean (no detectable AI patterns) — <yes | no>
- [ ] Source citations checked against primary docs — <yes | no>
- [ ] SEO meta validated (title length, description length, slug) — <yes | no>

## Approach
1. Review source material and reference posts for voice cadence.
2. Draft the post in the target length and tone. Stop for approval.
3. Run through expert panel scoring (target 90+). Iterate until passing.
4. Run AI humanizer pass (24-pattern check). Fix any flagged patterns.
5. Emit the asset-bundle task DAG (planning-and-task-breakdown format) — one task per declared asset, with `files_write`, `depends_on`, and `parallel_safe` set so the user can dispatch agents to generate them.

## Deliverable
- One publication-ready blog post in target length
- Expert panel scorecard (if quality gate enabled)
- Asset-bundle task DAG ready for agent dispatch

## Open questions
- <thing 1>
