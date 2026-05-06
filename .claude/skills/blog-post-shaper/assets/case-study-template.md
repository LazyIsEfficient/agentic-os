## Working title
<title — name the protagonist and the result if possible: "How [team] [verb] [outcome]">

## Variant
case study

## Single takeaway
<one sentence — the generalizable lesson the reader leaves with. Not "we did X", but "X works because Y, and here's when it doesn't.">

## Subject
- Who: <company / team / project / person — named or anonymized>
- Approval / permission status: <named with approval | anonymized | composite | internal-only>
- Author byline: <…>

## Story arc
1. **Problem** — <what was broken or unsolved at the start; what was at stake>
2. **Approach** — <what was tried; the intervention; the bet>
3. **Outcome** — <what changed; specific numbers if available>
4. **Friction along the way** — <what didn't work, what was nearly abandoned, what surprised the team>
5. **Generalizable lesson** — <the reusable principle, stated as advice for someone in a similar spot>

## Numbers / evidence
- Before: <metric + value + date>
- After: <metric + value + date>
- Sample size / context: <enough for a reader to judge whether this generalizes>
- Caveats: <what makes this story specific to this subject; where it might not transfer>

## Source material
- <interviews, internal docs, dashboards, logs, emails, prior post — list everything available>
- <or "I lived this — first-hand account">

## Target reader
- Who: <role, level, industry — someone facing the same problem the subject faced>
- Funnel stage: <awareness | consideration | decision>
- Why they care: <the specific pain that maps to this case>

## Voice and tone
- <reportorial, founder-narrative, retro-style, deadpan, etc.>
- Reference posts to match: <named prior post, or "match founder voice profile">
- Constraints: <no em-dashes, no AI-tell phrases, character/word ranges, banned words>
- Anonymization rules: <if applicable — "swap company name", "round all numbers to nearest 10%", "no employee names">

## Length
- Target: <word count range, e.g. 1500–2500>
- Hard ceiling: <if any>

## SEO surface
- Target keyword: <"none — owned-audience only" | primary keyword + 1-2 secondaries>
- Search intent: <informational | commercial | navigational | "n/a">
- Meta description angle: <one sentence the SERP snippet should communicate>
- URL slug suggestion: <short-and-keyword-bearing, or "auto">

## Asset bundle (required — author emits task DAG from this list)
- [ ] Hero / featured image — <generated | designed | stock | none>; describe the visual angle (e.g. before/after chart, hero shot of subject)
- [ ] OG / social share image (1200×630) — <separate from hero | reuse hero>
- [ ] X (Twitter) share post — <thread with the numbers | single | none>
- [ ] LinkedIn share post — <yes | no>
- [ ] Newsletter excerpt — <pull-quote with the headline number | rewritten lede | none>
- [ ] Embedded charts / data viz — <Mermaid | ASCII | generated chart images | none>; how many, what they show
- [ ] Embedded diagrams (architecture, flow, timeline) — <Mermaid | ASCII | generated | none>
- [ ] Code samples — <inline only | extracted to runnable repo | none>
- [ ] Internal-link map — <list 2–5 prior posts to link from inside this one | "none" | "auto">
- [ ] Pull quotes / callouts — <how many | none>
- [ ] Subject approval review pass — <required before publish | not required>

## Publication context
- Platform: <own blog | Substack | Medium | LinkedIn article | guest post on X | …>
- Cross-post plan: <yes/no, where, with what delay>
- Embargo / timing constraints: <…>
- Comments enabled: <yes | no>

## Scope
- In: <what this post covers>
- Out: <what it explicitly does NOT cover (e.g. competitor names, regulatory details, follow-on results)>

## Quality gate
- [ ] Expert panel score 90+ (content quality + strategic quality) — <yes | no — justify>
- [ ] AI humanizer pass clean — <yes | no>
- [ ] Numbers verified against source material — <yes | no>
- [ ] Subject sign-off received (if named) — <yes | no | n/a>
- [ ] SEO meta validated — <yes | no>

## Approach
1. Review source material; extract the numbers, the moments of friction, and the generalizable lesson.
2. Draft the post following the story arc. Stop for approval.
3. Run through expert panel scoring (target 90+). Iterate until passing.
4. Run AI humanizer pass (24-pattern check). Fix any flagged patterns.
5. (If named subject) Send to subject for approval. Apply edits.
6. Emit the asset-bundle task DAG (planning-and-task-breakdown format) — one task per declared asset, with `files_write`, `depends_on`, and `parallel_safe` set so the user can dispatch agents to generate them.

## Deliverable
- One publication-ready case study in target length
- Expert panel scorecard (if quality gate enabled)
- Subject approval record (if named)
- Asset-bundle task DAG ready for agent dispatch

## Open questions
- <thing 1>
