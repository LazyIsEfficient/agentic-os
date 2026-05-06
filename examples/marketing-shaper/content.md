# marketing-shaper — content

Example of `/mshape` producing a `content-template.md` brief — a single piece of content.

---

## User's initial request

> Long-form X post about why most teams ship AI features that don't get used. I have a draft from my newsletter last month I can pull from.

## Shaper's batched questions

Single deliverable, format named, source material exists — routes to `content-template.md`.

1. **Target audience** — founders, PMs, eng leaders, builders? And funnel stage — awareness/curiosity, or "they know me, drive them somewhere"?
2. **Core message** — the *single* takeaway? "Don't ship before you have usage signal"? Sharpen.
3. **Voice** — match founder voice profile, or a specific reference post?
4. **Length and structure** — single long post (4000+ chars), or thread? Any character/format constraints to honor?
5. **Quality gate — expert panel score + AI-humanizer pass before publish?**
6. **Call to action — link out, no link, sign up for newsletter, book a call?**

## User's answers

1. Eng leaders + founders shipping AI features. Awareness — not pushing them anywhere yet, building authority.
2. Most "AI features" fail because teams ship the model before they ship the usage signal that tells them whether it's working.
3. Match founder voice profile. Reference: my "we deleted half our roadmap" post from March, that hit ~250k views.
4. Single long post, 4000–7000 chars. Keep ASCII diagrams or code blocks if they help — they did in the March post.
5. Yes both — score ≥90, then humanizer pass.
6. No link. Sign-off line that mentions the newsletter, no CTA button.

## Output brief

```markdown
## Goal
Build authority with eng leaders and founders shipping AI features by naming a pattern they're stuck inside (shipping the model before the usage signal). Drive newsletter awareness via the sign-off, no hard CTA.

## Format
Long-form X (Twitter) post. Single post, 4000–7000 chars. ASCII diagrams or code blocks permitted where they sharpen a point.

## Target audience
- Who: eng leaders and founders shipping AI features.
- Funnel stage: awareness — building authority, not pushing to a CTA.
- What they care about right now: their AI feature shipped, executives are asking why retention didn't move, and they don't know whether the feature is good or just rarely tried.

## Core message / angle
Most "AI features" fail because teams ship the model before they ship the usage signal — so they can't tell whether the feature is bad or just rarely reached. Fix: instrument the *path to* the feature before you ship the feature.

## Source material
- Newsletter draft from last month covering the same theme.
- Reference post: "we deleted half our roadmap" (March), ~250k views — the structural cadence to match.

## Voice and tone
- Match founder voice profile.
- Constraints: no em-dashes, no AI-tell phrases, no "in conclusion", no rhetorical-question-then-answer structure flagged by the 24-pattern detector.

## Scope
- In: pattern naming, why it happens, one ASCII diagram showing "model shipped vs. signal shipped" timing, two concrete examples, one prescription.
- Out: tool recommendations, vendor names, code snippets longer than 6 lines, screenshots.

## Approach
1. Review newsletter draft and reference post. Extract the structural beats from the March post.
2. Draft the post in the target format. Stop for approval.
3. Run through expert panel scoring (target 90+). Iterate until passing.
4. Run AI humanizer pass (24-pattern check). Fix any flagged patterns.
5. Deliver final version ready to publish.

## Quality gate
- [ ] Expert panel score 90+ (content quality + strategic quality)
- [ ] AI humanizer pass clean (no detectable AI patterns)
- [ ] Format constraints met (under 7000 chars, no banned phrases)

## Deliverable
- One publication-ready X post in the target format
- Expert panel scorecard
- Sign-off line mentioning the newsletter (no link, no CTA button)

## Open questions
- One ASCII diagram or two? March post had one, worked well.
```

---

**Next step:** paste this into a fresh session, or say `go` and the executor drafts, scores, and humanizes the post.
