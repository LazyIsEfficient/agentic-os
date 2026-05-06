# course-shaper — workshop

Example of `/course-shape` producing a `workshop-template.md` brief — single 1–4 hour session.

---

## User's initial request

> Running a 2-hour workshop at our internal eng all-hands next month on writing better PR descriptions. Audience is the whole engineering org, mixed levels.

## Shaper's batched questions

Single session, fixed time, mixed audience — routes to `workshop-template.md`.

1. **Group size and delivery mode** — 20 people in a room, 100 on Zoom, 300 hybrid?
2. **Outcomes — what does each participant *leave with*?** A workshop should produce something. A revised real PR description? A team rubric? A checklist applied to a chosen PR?
3. **Mixed levels — calibrate to whom?** Junior engineers writing their first PRs, senior engineers reviewing 30/week, both?
4. **Pre-workshop participant setup** — bring a real PR they wrote? Anything to install?
5. **Hands-on vs teach time split** — how much of the 2 hours is them doing the work vs you talking?
6. **Voice / opinion** — opinionated ("a PR description should answer 4 specific questions" with a named template), or open ("here are patterns, pick what works for your team")?

## User's answers

1. ~80 engineers, hybrid (40 in-room, 40 on Zoom).
2. They leave with one of their own real PR descriptions rewritten to a usable standard, plus a checklist they can keep using.
3. Calibrate to mid-level. Juniors will benefit; seniors will use the time to think about review-side incentives.
4. Each participant brings the URL of one PR they personally authored in the last 30 days that they're not 100% proud of.
5. ~60% hands-on, 40% teach.
6. Opinionated. House view: a PR description must answer "what changed", "why now", "how was it tested", "what could go wrong" — in that order. Anything else is optional.

## Output brief

```markdown
## Workshop title
Writing PR Descriptions That Get Reviewed Faster

## One-line pitch
Walk in with a PR you're not proud of, walk out with one rewritten to a standard reviewers actually like — plus a checklist you'll keep using.

## Audience
- Primary: working engineers across the org, mid-level calibration. Juniors benefit from the standard; seniors benefit from thinking about the review-side incentives.
- Group size: ~80 (40 in-room, 40 remote).
- Prior knowledge assumed: has authored PRs in this team's repos in the last 30 days.

## Duration
- Total: 2 hours.
- Session count: 1.

## Delivery
- Mode: hybrid (in-person + Zoom). Plan for room participants to break out at tables; remote participants in named breakout rooms with a remote co-facilitator.
- Facilitator(s): primary facilitator + remote co-facilitator for Zoom breakouts.
- Participant setup required before start: each person brings the URL of one PR they personally authored in the last 30 days that they are not 100% proud of. No installs.

## Learning outcomes
By the end of the workshop, the participant can:
- Rewrite their own PR description to answer the four house questions ("what changed, why now, how tested, what could go wrong") in the prescribed order.
- Apply the checklist to a teammate's PR and produce a 60-second review note that improves the description without rewriting it.

## Agenda shape (rough)
- Opener / demo hook (10 min) — show two real PRs side-by-side, one good, one bad. Audience guesses which gets merged faster. Reveal the data.
- Teach block 1 (15 min) — the four-question structure, why it's in that order, common failure modes per question.
- Hands-on block 1 (30 min) — each participant rewrites their own PR description to the structure. Pair-share at tables / breakout rooms.
- Teach block 2 (15 min) — review-side incentives: what a reviewer is actually looking for, why "what could go wrong" earns trust faster than any other section.
- Hands-on block 2 (30 min) — swap PRs with one partner; produce a 60-second review note that improves *their* description without rewriting the code.
- Share-back / Q&A (20 min) — three volunteers read their before/after; final Q&A; checklist handout.

## Artifacts produced
- Each participant: their own real PR description rewritten to the standard.
- Each participant: one review note delivered to a partner.
- Workshop output: a 1-page checklist (the four questions, the failure modes, the review-side prompt) circulated org-wide afterward.

## Assessment bar
- In-session check: working artifact (the rewritten PR description) — facilitator spot-checks during hands-on blocks.
- Post-session follow-up: the 1-page checklist is circulated; team leads optional-encouraged to use the four-question structure as a default in PR templates.

## Voice and tone
Opinionated, fast-moving, example-heavy. The house view is named explicitly: "a PR description must answer these four questions in this order. Optional sections are optional." No equivocation in teach blocks. Discussion happens in hands-on time.

## Domain focus
- Subject: PR descriptions as the primary review interface.
- Opinions to embed:
  - The PR description is the single most leveraged artifact a working engineer writes.
  - "What could go wrong" earns trust faster than any other section.
  - A great PR description costs the author 10 extra minutes and saves the reviewer 30.

## Constraints
- Date / venue: <unknown — confirm date with org-ops>; main office room + Zoom.
- Equipment / bandwidth: hybrid AV setup verified beforehand; Zoom breakout rooms preconfigured.

## Source material available
- Two real PRs (one good, one bad) for the opener — pull from internal repos, anonymize before showing to remote participants.
- Prior 1-page checklist draft from a team-lead off-site last quarter.

## Open questions
- Should we mandate the four-question structure as the default in PR templates after this workshop, or stay at "encouraged"?
- Recording — yes for absent eng, or no to keep participation candid?
```

---

**Next step:** paste this into a fresh session with `course-design` available, or say `go` and the brief is handed forward to plan teach-block content and produce the checklist.
