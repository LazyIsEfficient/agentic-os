# Usability Testing

A usability test is a structured observation of a participant trying to complete tasks with a design. It's the most common evaluative method in UX research, and one of the most misused.

The misuse: most "usability tests" are actually **opinion surveys with a prototype in the background**. The moderator asks "do you like this?" and "does this make sense?" while the participant clicks around. That's not a usability test. A real usability test watches *behavior*, not *opinion*, and that distinction is the entire point.

## What a Usability Test Is For

A usability test answers: **can this user, doing this task, with this design, succeed — and where do they get stuck?**

Things it's good at:

- Finding *where* users struggle.
- Surfacing the *gap* between the designer's mental model and the user's.
- Catching usability problems that are obvious in hindsight and invisible in design review.
- Validating that a fix *actually* fixes the problem.

Things it's *bad* at:

- Telling you whether to build the thing in the first place (that's discovery).
- Comparing two designs head-to-head (that's an A/B test or competitive evaluation).
- Telling you what users *want* (that's an interview).
- Telling you how *common* a problem is (that's a survey or analytics).

If your study question is one of the bad-at items, do a different kind of study. Don't shoehorn a usability test into a question it can't answer.

## The 5-User Rule (and Its Limits)

Jakob Nielsen's [classic finding](https://www.nngroup.com/articles/why-you-only-need-to-test-with-5-users/) is that 5 users will surface roughly 80% of usability issues for a single user type performing a single task set. Beyond 5, returns diminish quickly.

**This is true *and* widely misunderstood.** The full statement is:

- 5 users **per user type**. If you have small business and enterprise users, that's 5 + 5 = 10.
- 5 users **for a single task set**. If you're testing checkout *and* search *and* settings, the issues are mostly independent; 5 each.
- 5 users finds 80% **of usability issues**. The remaining 20% includes the rare-but-severe ones; if your stakes are high, you may want more.
- 5 users does **not** tell you that one design is better than another. That's an A/B test.
- 5 users does **not** give you statistical confidence on rates. "3 out of 5 users had problem X" is not 60% — it's a hint.

The right way to use the rule: **5 users is the minimum for a useful usability test.** Don't run 3. Don't run 30 unless you have a specific reason. Run 5 per user type, fix what you find, and run 5 more on the next iteration.

The iterative version is much more powerful than one big study. Five users → fix → five more → fix → five more catches more issues at less total cost than one 25-user study.

## Designing the Test

### 1. Pick the question

What are you trying to learn? Be specific:

- "Can users complete checkout without help?"
- "Where do users get stuck in onboarding?"
- "Does the new error message help users recover?"
- "Do users understand what 'archived' means in our app?"

A vague question ("is it usable?") produces a vague test produces vague findings.

### 2. Pick the tasks

A task is a specific thing you'll ask the participant to do. Good tasks have these properties:

- **Realistic.** Something a real user would actually want to do.
- **Specific.** Concrete enough to know when they're done.
- **Goal-oriented**, not feature-oriented. "Buy a pair of running shoes" not "click the buy button."
- **Open about the goal**, **silent about the method.** Tell them what to accomplish, not how.
- **Independent.** Each task should stand alone; failure in task 1 shouldn't make task 2 impossible.

Examples:

| Bad task | Better task |
|---|---|
| "Click on Settings, then click on Account, then change your email." | "Change your email address to a new one." |
| "Navigate to the dashboard." | "Find out how many tickets your team closed last week." |
| "Use the search feature." | "Find that article we discussed about pricing changes." |
| "Read the error message and resolve it." | "Something went wrong when you tried to save. Get back on track." |

The "better" versions test whether users can **figure out** the path. The "bad" versions tell users the path and only test whether they can follow instructions.

### 3. Pick the fidelity

Fidelity should match the question. The biggest mistake is using too-high fidelity for early-stage questions.

| Fidelity | Tests | Doesn't test |
|---|---|---|
| Paper sketch | Concept, basic flow | Polish, micro-interactions, real data |
| Wireframe (Balsamiq, Figma low-fi) | IA, navigation, content priority | Visual hierarchy, brand, motion |
| High-fidelity Figma prototype | Visual hierarchy, micro-copy, click flow | Real performance, edge cases, animation timing |
| Functional prototype | Real interactions, animation, edge cases | Real backend, real latency, real data |
| Live product (staging) | Everything | The one thing you wanted to change before testing |

Higher fidelity costs more to build and biases participants toward visual feedback ("the colors are nice") instead of structural feedback ("I don't know what this page is for"). Use the lowest fidelity that lets you learn.

### 4. Write the script

A usability test script has roughly four sections:

1. **Intro** (5 min) — welcome, consent, set expectations.
2. **Background** (5 min) — quick context about the participant.
3. **Tasks** (30–40 min) — the main event.
4. **Debrief** (5 min) — wrap-up questions, thanks.

For a fillable script, see [assets/usability-test-script.md](../assets/usability-test-script.md).

### 5. Pilot it

**Always pilot before the real sessions start.** Run the full script with one internal person or friendly user. You will discover:

- Tasks that take 5x longer than estimated.
- Tasks that are impossible because the prototype doesn't support them.
- Tasks the pilot participant misunderstands in a way you didn't predict.
- The order that feels natural vs. the one you wrote.

Fix the script. Then run the real study.

## The Intro (Word for Word)

The intro is more important than it looks. It sets expectations, calibrates the participant, and prevents most of the worst usability test failures. Some of it is best read almost word-for-word:

> Thanks so much for joining today. Before we start, I want to set a few things up so we get the most out of our time.
>
> **First, this is a test of the design, not of you.** There are no right or wrong answers. If something is confusing, that's a problem with the design, not with you — and that's exactly what we're trying to learn.
>
> **Second, please think out loud as you go.** Tell me what you're looking at, what you're thinking, what you expect to happen, what's confusing. The more I hear from you, the more useful this is.
>
> **Third, I'm not the designer of what you're about to see.** You can be completely honest. You won't hurt my feelings. Telling me it's confusing helps me; telling me it's great when it's actually confusing doesn't help anyone.
>
> **Fourth, I can't help you during the tasks.** I'll seem like I'm being unhelpful. That's because if I help you, I won't see what's actually hard. Just do whatever you'd do if I weren't here.
>
> Any questions? I'm going to start recording now.

The first sentence ("test of the design, not of you") is the single most important. Without it, participants try to look smart instead of behaving naturally. With it, they're freed to struggle visibly, which is what you need.

## Moderating: The Hard Part

Moderating a usability test is harder than moderating an interview. The trap is that you'll see the participant struggle and your instinct is to *help*. **Resist.**

### Things to do

- **Assign the task.** Read it aloud or hand them a card. Then *stop talking.*
- **Watch.** Note what they look at, what they click, what they hesitate over, where their eye goes.
- **Encourage think-aloud** when they go quiet: "What are you thinking?" "What are you looking for?" "What are you expecting to happen?"
- **Ask after the task** — not during — what they were thinking at the moment they got stuck.
- **Echo and probe** when they say something interesting: "You said that's confusing — say more about that?"
- **Move on when they're done** (or visibly stuck for too long): "That's perfect. Let's try the next one."

### Things to NOT do

- **Don't help.** Don't point to the right button. Don't say "have you tried clicking there?" Don't explain what something means. The participant's struggle is the data.
- **Don't ask leading questions.** "Was that easy?" → "Tell me how that felt."
- **Don't sell.** "What you didn't see is that this also does X..." No. They didn't see it because they didn't see it.
- **Don't argue.** Participant says "this is broken" — even if it isn't, don't defend. Probe the perception, then move on.
- **Don't fill silence.** Let them think. The silence is when their next observation is forming.
- **Don't speed-run the protocol.** A task that's "quick" for an expert is not quick for a first-time user.

### When the participant is *really* stuck

What do you do when 4 minutes pass and they still can't find the button?

1. **Wait.** A long pause is data. Most stuck participants find a path eventually.
2. **Probe**: "What are you looking for?" "What are you expecting to see?" Their answer is gold.
3. **Encourage giving up**: "If you couldn't figure this out, what would you do in real life?" Real-life answers ("I'd close the tab" or "I'd email support") are more honest than infinite struggle.
4. **Move on**: "Let's set this one aside and try the next task." Mark as "task failed" in your notes.

The participant getting stuck and giving up is *successful data*, not a failed session. Treat it that way out loud — they should leave feeling helpful, not embarrassed.

## Remote vs In-Person

Both work. Trade-offs:

| Aspect | In-person | Remote |
|---|---|---|
| Setup time | High (room, scheduling, travel) | Low |
| Participant comfort | Often higher | Often higher (in their own space) |
| Body language visibility | Excellent | Partial |
| Diversity of recruitment | Limited to local | Global |
| Cost | Higher (often much) | Lower |
| Tech difficulty | Low | Real |
| Easy to record | Yes (one camera) | Yes (built-in) |
| Two-way attention | Strong | Weaker (participants get distracted by their other tabs) |

**For most teams, remote is the default.** It's faster, cheaper, and recruits from a wider pool. Reserve in-person for studies where context matters (physical environment, multi-device flows, co-located team observation).

For remote: tools like Zoom, Google Meet, Lookback, or UserTesting all work. Test the participant's tech beforehand if you can. Have a backup link ready.

## Moderated vs Unmoderated

A different axis: do you watch live, or does the participant complete the test on their own time with a recording tool?

| Aspect | Moderated | Unmoderated |
|---|---|---|
| Depth of insight | High (probe in real time) | Lower (no probes) |
| Sample size achievable | 5–20 sessions/week | 50+ sessions/week |
| Cost per session | High | Low |
| Best for | Why questions, complex flows | What questions, simple flows, scale |
| Participant experience | Personal | Solitary |

Use moderated when you want to understand *why* users struggle. Use unmoderated when you have a clear, simple task and want to know *how often* something happens at scale.

A common combination: **moderated first** to find the issues qualitatively; **unmoderated next** to quantify how often each issue occurs.

## Notes During the Test

Take light notes; the recording is the source of truth.

- **Task success.** Mark each task as success / partial / fail / abandon.
- **Critical incidents.** A specific moment of confusion, frustration, hesitation, or surprise. Note the time and a one-line description.
- **Quotes.** Especially anything that captures something uniquely well.
- **Body language.** Especially relevant in person — the sigh, the lean back, the squint.

Don't try to write everything. Your job is to *moderate*, not to transcribe.

## Synthesizing Results

After 5 sessions, take 1–2 hours to:

1. **Re-watch the moments you flagged**, or skim the transcripts.
2. **List every distinct usability issue** observed across sessions.
3. **Tag each issue** by severity (catastrophic / serious / minor / cosmetic) and by frequency (how many participants hit it).
4. **Group issues** that share a root cause.
5. **Prioritize** by severity × frequency.

The output is a list of issues — *not* a long report. The team wants to know what to fix. See [synthesis-and-insights.md](synthesis-and-insights.md) for the longer story.

## A Severity Scale

A useful severity rubric, from Nielsen's heuristic evaluation work:

| Severity | Definition | What to do |
|---|---|---|
| **Catastrophic** | Users can't complete the task | Fix before launch |
| **Serious** | Users complete the task but with significant struggle, or many users fail | Fix in the next iteration |
| **Minor** | Users complete the task with minor friction; only some users notice | Fix when convenient |
| **Cosmetic** | Visual or wording polish that doesn't impede use | Fix during normal design hygiene |

Categorizing forces honesty about which issues *actually* matter and which the team should ignore.

## Anti-Patterns

- **The opinion test.** Moderator asks "what do you think?" instead of watching what users do. Polite opinions; no insight.
- **The leading task.** "Find the checkout button" — the user now knows there's a checkout button. Test whether they would have looked for one in the first place.
- **The friendly moderator.** "Ah, you're so close! Just click that one!" Moderator helps; data is contaminated.
- **Wrong fidelity.** Testing brand colors and font choices on a paper sketch; testing IA on a polished prototype. Match fidelity to question.
- **One-shot study.** Run 12 users in one big study, get a 30-page report, fix nothing because it's overwhelming. 5 users → fix → 5 more is much more effective.
- **Internal-only participants.** Friends, employees, family. Polite, biased, uncalibrated. You learn what the team already believes.
- **No pilot.** First real session reveals a broken prototype.
- **Tasks are tutorials.** "Click here, then click here, then click here." You're testing whether the user can read instructions, not whether the design works.
- **Asking if they liked it at the end.** They will say yes. They are being polite. The behavior in the body of the test is the data; the closing opinion is noise.
- **Only counting what went wrong.** Note what went *right* too — those are the things not to break in the next iteration.
- **Ignoring the 5-user rule's caveats.** Treating 5 users as a verdict instead of as an iteration sample. Five users find issues; they don't measure rates.
- **Comparing two designs in a 5-user usability test.** Use an A/B test for that.
- **The survey at the end.** "On a scale of 1 to 5, how easy was that?" Tells you nothing; people answer what makes them feel polite.

## Related

- [research-methods.md](research-methods.md) — when usability testing is the right method
- [study-planning.md](study-planning.md) — planning the test
- [interview-craft.md](interview-craft.md) — many of the same skills (probing, silence, neutrality)
- [synthesis-and-insights.md](synthesis-and-insights.md) — turning observed issues into a prioritized list
- [communicating-findings.md](communicating-findings.md) — getting the team to actually fix the issues
- [assets/usability-test-script.md](../assets/usability-test-script.md) — fillable script template
- [ux-design/references/accessibility.md](../../ux-design/references/accessibility.md) — usability testing with assistive technology users
