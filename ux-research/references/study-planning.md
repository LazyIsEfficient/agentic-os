# Study Planning

A research study without a plan is improvisation. Sometimes improvisation works; usually it produces a study that consumes a week, generates 20 hours of recordings, and yields no clear answer because the question wasn't sharp enough to begin with.

Plan the study *before* you write the discussion guide, *before* you start recruiting, and *especially* before you talk to the first participant. This file is the playbook for that plan.

## The Plan, in Sections

A research plan is a one-pager that anyone on the team can read in three minutes and understand:

1. **The question** — what we want to know, in one sentence.
2. **The hypothesis** — what we currently believe the answer is, and why.
3. **The method** — the research method, with justification.
4. **The participants** — who, how many, how recruited, how compensated.
5. **The protocol** — the structure of each session.
6. **The analysis plan** — how the data will be turned into findings.
7. **The deliverable** — what gets shared with whom and when.
8. **What we're explicitly NOT studying** — to keep scope honest.

A complete plan is in [assets/research-plan-template.md](../assets/research-plan-template.md). Each section gets its own discussion below.

## 1. The Question

> **The single most important sentence in any research study.**

A good research question is:

- **Specific.** "Why do users abandon checkout?" — not "are users happy?"
- **Answerable.** A question whose answer the team will recognize when they hear it.
- **Decision-linked.** Ideally, you can name the decision the answer will inform. "If we learn X, we will do Y; if we learn Z, we will do W."

If you can't write the question in one sentence, you don't yet know what you're studying. Stop and think more before recruiting anybody.

### Examples

| Bad question | Better question |
|---|---|
| "How do users feel about our product?" | "Why do trial users who reach the integration step rarely complete it?" |
| "Is the new design better?" | "Can users in our 'small business' segment complete the new onboarding flow without help, and where do they get stuck?" |
| "What features should we add?" | "What jobs are our power users currently working around the product to accomplish?" |
| "Are users satisfied with X?" | "Among users who've used X at least three times in the last month, what behaviors and unmet needs predict whether they recommend us?" |

## 2. The Hypothesis

A hypothesis is what the team currently believes the answer is. **Writing it down before the study is essential**, for two reasons:

1. It surfaces the team's assumptions so research can confirm or invalidate them.
2. It protects you from confirmation bias — without a written hypothesis, the team will reframe its beliefs after the data comes in to match what was found.

A hypothesis is not a prediction you have to defend. It's the team's current model. The point is to test it.

### Examples

> "We believe trial users abandon the integration step because they don't have admin access to the systems they need to integrate with, and our docs assume they do."

> "We believe small business owners value automation more than customization, but we have not actually tested this — we've been designing as if it were true for two years."

> "We believe the search results page is the main reason for the bounce rate, but the analytics could equally be explained by users finding what they need in the search dropdown without ever clicking through."

If the team can't agree on a hypothesis, that's a finding in itself — surface the disagreement before the study so the study can be designed to resolve it.

## 3. The Method

Pick the method that answers the question, not the method you're most comfortable with. See [research-methods.md](research-methods.md) for the decision logic.

The method section of the plan answers:

- **What method**, and **why this method** for this question.
- What the method *can* answer and what it *cannot* answer.
- What the alternative methods would have been and why you rejected them.

The "rejected alternatives" sentence prevents the team from second-guessing later. If you wrote "we considered a survey but the question is generative, so we are doing interviews" up front, the conversation never happens after the fact.

## 4. The Participants

Who, how many, how recruited, how compensated.

### Who — recruitment criteria

Define the participant profile *before* you start recruiting. Specifically:

- **Inclusion criteria** — what makes someone eligible (e.g. "has used our product at least 3 times in the last month").
- **Exclusion criteria** — what disqualifies them (e.g. "works at a competitor," "is an existing employee," "participated in our last study").
- **Quotas** — how many of each segment you need (e.g. "at least 3 from each of our 4 customer tiers").
- **Diversity** — within the segment, what variation matters (geography, role, experience level, accessibility needs).

The hardest part of recruitment is *not* finding people. It's not finding the *wrong* people. A study filled with the easiest-to-recruit participants will reach the wrong conclusions.

### How many — sample size

A common myth: "we need 100 participants." For most qualitative research, 100 is wasteful. Sample size depends on the method and the goal.

| Method | Typical sample | Notes |
|---|---|---|
| Discovery interviews | 6–12 per segment | Saturation usually around 8; more for unfamiliar domains |
| Usability tests | 5 per user type | Nielsen's "5 users find 80% of issues" — see [usability-testing.md](usability-testing.md) for the limits |
| Diary studies | 8–15 | Higher dropout; recruit a buffer |
| Surveys | 100–400+ | Depends on margin of error, segments |
| Card sorts | 15–30 | Diminishing returns above 30 |
| Tree tests | 30–50 | For statistical confidence |
| A/B tests | Varies hugely | Use a power calculator |

The key principle: **stop when you stop learning new things.** If interview 8 surfaces the same themes as interviews 5, 6, and 7, you've hit saturation. If interview 8 surfaces completely new themes, you may need 12 or 15.

### How recruited

Several common channels, each with biases:

- **Existing user base** — easy, but biased toward engaged users. Need to oversample lapsed/lost users to balance.
- **Recruitment panels** (User Interviews, Respondent.io, Userlytics) — fast but expensive. Quality varies by panel; screen carefully.
- **Social media outreach** — biased toward your followers. Useful for niche segments.
- **Customer support tickets** — finds people who have problems. Good for some studies, biased for others.
- **Snowball sampling** — ask interviewees to recommend others. Biased toward similar people, but can reach hard-to-find segments.

Document the channel in your plan and acknowledge its biases.

### How compensated

Pay people. Always.

- **Fair rate.** Local minimum wage is too low for the time and effort. $50-150/hour for consumer studies, $200-500/hour for B2B/expert participants is common.
- **Form of payment.** Gift cards (Amazon, Visa) are easy. Cash, charity donations on their behalf, account credits — all valid.
- **Pay even if the study is cut short.** If you cancel a session, the participant still gets paid. If a session ends in 20 minutes because the participant doesn't fit, they still get the full amount.
- **Pay employees and customers too.** "They get paid by us already" is not a reason to skip compensation. Their attention to research is separate from their day job.

The cost of compensation is small compared to the cost of bad recruitment and biased findings.

## 5. The Protocol

The protocol is the structure of each research session. For an interview, it's the discussion guide. For a usability test, it's the task script. For a survey, it's the questionnaire.

The protocol section of the plan describes:

- **The structure** of each session (warmup → key questions → debrief, or whatever shape).
- **The total time** per session.
- **What's recorded** and what's noted.
- **What artifacts** the participant interacts with (a prototype, a homepage, a printout).

The full guide is a separate artifact — see [interview-craft.md](interview-craft.md) for interviews and [usability-testing.md](usability-testing.md) for usability tests, plus the [assets/](../assets/) templates.

### Pilot the protocol

Before you run the real study, **pilot the protocol with 1–2 internal people** (or a friendly customer). You will discover:

- Questions that don't make sense to anyone but the team.
- Tasks that take 5x longer than you estimated.
- Tools and prototypes that break in unexpected ways.
- The order of questions that feels natural vs. the one you wrote.

Fix the protocol before the real study starts. The pilot is not "wasted" — it's part of the plan.

## 6. The Analysis Plan

How will you turn raw data into findings?

This is the section most often skipped, and it's the section most often regretted later. A study with no analysis plan produces 20 hours of recordings and a researcher who doesn't know where to start.

A good analysis plan answers:

- **Where will the raw data live?** (Recording archive, transcript folder, notes spreadsheet.)
- **How will it be coded or tagged?** Affinity mapping in Miro? Thematic coding in Dovetail? Manual notes in a spreadsheet?
- **Who is doing the analysis?** Solo, paired, with the team in a synthesis workshop?
- **What's the timeline?** Don't underestimate. Synthesis usually takes about as long as the research itself.
- **What's the target output format?** A one-pager? A slide deck? A workshop?

For larger studies, **one researcher should not synthesize alone.** Have a peer review your themes; their fresh eyes catch your blind spots. See [synthesis-and-insights.md](synthesis-and-insights.md).

## 7. The Deliverable

What does the team get at the end? When? Who attends?

- **One-pager findings** for fast distribution.
- **A readout meeting** for the team to absorb and discuss together (often more valuable than any document).
- **Highlight reels** of participant footage for emotional impact (use selectively; powerful but easy to misuse for cherry-picking).
- **A workshop** to translate findings into design decisions or backlog items.
- **A long-form report** *only* if the audience needs detail and will actually read it.

Include the *date* the deliverables will be ready in the plan. If you commit to a delivery date, stakeholders can plan around it.

## 8. What We're Explicitly NOT Studying

The most underused section. Saying out loud what the study is *not* answering protects the scope and protects the findings from over-interpretation later.

> "This study will not tell us anything about international users; we are recruiting only US-based participants. It will not answer questions about pricing; we are not asking pricing questions. It will not validate the new design; we are studying the problem space, not the proposed solution."

When the team comes to the readout and says "but does this tell us about pricing?" — point to this section and say "no, that's a separate study."

## Ethics and Consent

Every study, regardless of size, needs:

- **Informed consent.** Participants know what they're signing up for, what's recorded, who'll see it, how it'll be used, and how to withdraw.
- **Right to withdraw at any time** — including after the session, if they change their mind.
- **Confidentiality** — participants are not identified by name in any deliverable unless they explicitly agree.
- **Special care for vulnerable populations** — children, people in crisis, people with cognitive or physical disabilities. Consult ethics references; don't wing it.
- **Data retention policy.** How long the recordings live, who has access, when they're destroyed.
- **Special care for sensitive topics.** Health, finances, relationships, immigration status — assume more care, not less.

For more, see [ethics-and-bias.md](ethics-and-bias.md).

## Anti-Patterns

- **No written plan.** "We'll just chat with some users." Six interviews later, the team can't agree on what was learned.
- **Question that's too broad.** "What do users think about our product?" The synthesis is impossible because the data is incoherent.
- **Hypothesis-free study.** Then the team retroactively discovers it confirms whatever they were planning anyway.
- **Recruitment by convenience.** Whoever signs up first; whoever the team knows; the easiest panel. Biased findings, every time.
- **Cheap compensation.** Then you only get people who say yes for free, who are systematically different from the segment you want to learn about.
- **No analysis plan.** Researcher is paralyzed at the start of synthesis; output is late or weak.
- **Pilot skipped.** First real session reveals a broken prototype or a confusing task; you've burned a participant and an hour to learn what a pilot would have caught.
- **Scope creep.** "Since we're talking to them anyway, can we ask about pricing too?" The study now answers no question well.
- **Findings reused for the wrong question.** A study about onboarding gets cited two months later as "evidence" about pricing. Cite carefully.
- **No recruitment buffer.** Plan for 8, recruit 8, half no-show, study has 4 participants and incoherent findings. Always overrecruit.

## Related

- [research-methods.md](research-methods.md) — picking the right method for the question
- [interview-craft.md](interview-craft.md) — running interviews
- [usability-testing.md](usability-testing.md) — running usability tests
- [synthesis-and-insights.md](synthesis-and-insights.md) — turning data into findings
- [ethics-and-bias.md](ethics-and-bias.md) — consent, compensation, sensitive topics
- [assets/research-plan-template.md](../assets/research-plan-template.md) — fillable plan template
