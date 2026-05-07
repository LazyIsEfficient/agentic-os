## Working title
<title — name the concept being explained, ideally with a hook: "How X actually works", "The real reason Y", "X, explained">

## Variant
deep dive / explainer

## Single takeaway
<one sentence — the mental model the reader should leave with. Not "you'll learn about X", but "X is shaped like Y, and that's why Z".>

## Concept under explanation
<the specific thing being explained — be precise. "Prompt caching" is a topic. "Why prompt caching costs are dominated by cache writes, not cache reads" is a concept.>

## Prior knowledge assumed
- <concepts the reader must already understand to follow this post>
- <if "none — start from zero", say so>

## Mental model the post builds
<sketch the model in 3–5 sentences. The post's job is to install this model in the reader's head; everything else serves that goal.>

## Worked example
<a single concrete example the post unpacks step-by-step — the spine of the explainer. Name it now; the post lives or dies on its quality.>

## Common misconceptions to correct
- <"You might think X. Here's why X is wrong. Here's the better frame.">
- <misconception 2>
- <misconception 3>

(Lifting from the course-author misconception pattern: name the wrong intuition before correcting it. Don't ship a correction without the misconception attached — readers won't recognize it as theirs.)

## Source citations required
- <primary docs, papers, vendor specs, RFCs that must be cited>
- <"defer to source-driven-development for verification" if the topic touches APIs, protocols, or vendor behavior>

## Target reader
- Who: <role, level, current familiarity with the topic>
- Funnel stage: <awareness | consideration | decision>
- Why they care: <the specific decision or task this mental model unblocks>

## Voice and tone
- <explanatory, opinionated, deadpan, "smart friend at a whiteboard", etc.>
- Reference posts to match: <named prior post, or "match founder voice profile">
- Constraints: <no em-dashes, no AI-tell phrases, no rhetorical-question-then-answer, character/word ranges, banned words>

## Length
- Target: <word count range, e.g. 2000–3500 — deep dives run long>
- Hard ceiling: <if any>

## SEO surface
- Target keyword: <"none — owned-audience only" | primary keyword + 1-2 secondaries>
- Search intent: <informational (most likely) | other>
- Meta description angle: <one sentence the SERP snippet should communicate>
- URL slug suggestion: <short-and-keyword-bearing, or "auto">

## Asset bundle (required — author emits one task file per declared item)
- [ ] Hero / featured image — <generated | designed | stock | none>; describe the visual angle (e.g. abstract diagram of the mental model)
- [ ] OG / social share image (1200×630) — <separate from hero | reuse hero>
- [ ] X (Twitter) share post — <thread breaking down the explainer | single | none>
- [ ] LinkedIn share post — <yes | no>
- [ ] Newsletter excerpt — <pull-quote with the takeaway | rewritten lede | none>
- [ ] Embedded diagrams (mental model, architecture, flow) — <Mermaid | ASCII | generated images | none>; how many, what each shows
- [ ] Embedded charts / data viz — <Mermaid | ASCII | generated | none>
- [ ] Code samples — <inline only | extracted to runnable repo>; specify languages and runtime
- [ ] Glossary / sidebar of terms — <yes — list terms | no>
- [ ] Internal-link map — <list 2–5 prior posts to link from inside this one | "none" | "auto">
- [ ] Pull quotes / callouts (esp. for misconceptions) — <how many | none>
- [ ] Table of contents / outline — <yes for reading time > 8 min | no>

## Publication context
- Platform: <own blog | Substack | Medium | LinkedIn article | Hashnode | guest post | …>
- Author byline: <…>
- Cross-post plan: <yes/no, where, with what delay>
- Comments enabled: <yes | no>

## Source material
- <existing draft, notes, prior post, transcript, dataset, internal memo>
- Citations to gather: <list primary sources you don't have yet but will need>

## Scope
- In: <what this post covers>
- Out: <what it explicitly does NOT cover or expand into; adjacent concepts deferred to follow-up posts>

## Quality gate
- [ ] Expert panel score 90+ (content quality + strategic quality) — <yes | no — justify>
- [ ] AI humanizer pass clean — <yes | no>
- [ ] All technical claims cite primary sources (no training-data folklore) — <yes | no>
- [ ] Code samples runnable as shown — <yes | no | n/a>
- [ ] Diagrams render correctly on the target platform — <yes | no>
- [ ] SEO meta validated — <yes | no>

## Approach
1. Review source material and gather citations. Verify any technical claims against primary sources.
2. Draft the worked example first — the post is built around it.
3. Draft the surrounding prose: hook, mental model, misconception callouts, close. Stop for approval.
4. Run through expert panel scoring (target 90+). Iterate until passing.
5. Run AI humanizer pass (24-pattern check). Fix any flagged patterns.
6. Write one self-contained task file under `tasks/T-<slug>.md` per declared asset (output paths, what to do, success criteria, verify). The calling agent fans these out to subagents.

## Deliverable
- One publication-ready deep-dive post in target length
- Expert panel scorecard (if quality gate enabled)
- Source citation list
- One dispatch-ready task file per declared asset under `tasks/`

## Open questions
- <thing 1>
