# Communicating Findings

The work of research is wasted if the findings don't change decisions. The most common cause of waste isn't bad research — it's *unread research*. Long reports filed in shared drives, slides circulated by email, findings nobody can recall a week later.

This file is the playbook for getting findings to land.

## The Core Principle

> **Communication is part of the research, not a deliverable after it.**

If you treat communication as a final report you write at the end, you've already lost. The team's attention is bid for by everyone — engineering escalations, customer requests, leadership priorities, the next sprint. Your findings compete with all of that. Plan the communication as carefully as you plan the study.

The questions to answer before you start communicating:

1. **Who needs to act on this?** That person is your primary audience.
2. **What decision are they making?** Your findings should inform that decision specifically.
3. **What format suits how they consume information?** A 30-page PDF, a 30-minute readout, a 5-minute video, a one-pager?
4. **When do they need it?** Before the next planning meeting? Before the design review on Friday? Six months ago, ideally?
5. **What's the *one thing* they should walk away knowing?**

If you can't answer all five before writing anything, draft answers and adjust as you go — but don't skip them.

## Formats — Match the Format to the Audience

Different audiences want different things. The same study can produce multiple deliverables.

### One-pager findings (single sheet, 5-min read)

- **For:** product, design, engineering, anyone making decisions in the affected area.
- **Contains:** the question, the method (one line), the top 3 findings, the top recommendations, what to read next if interested.
- **Strength:** read by far more people than longer reports.
- **Weakness:** loses nuance.

The one-pager is the *highest leverage* artifact in research communication. If you write only one thing, write this.

### The readout meeting (30–60 min, live)

- **For:** the team that owns the affected area, plus stakeholders.
- **Format:** present findings, play short clips, take questions, collaboratively discuss "so what."
- **Strength:** discussion produces shared understanding the document can't.
- **Weakness:** only the people in the room benefit.

A readout is more valuable than a report for most studies. The discussion is where the team commits to action.

Tips for a good readout:

- **Don't read the slides.** People can read faster than you can talk.
- **Show, don't tell.** Clips of users actually struggling are far more persuasive than your description.
- **Save time for discussion.** Half the meeting, minimum, should be conversation, not presentation.
- **End with "what changes."** Not "the end" — "what should we do differently? Who owns what? When do we revisit?"
- **Record it.** People who couldn't make it can watch. People who *did* make it can re-watch the parts they missed.

### Highlight reels / video clips (2–10 min)

- **For:** leadership, sales, marketing, executives. People who need to *feel* the user pain, not just know it intellectually.
- **Format:** edited footage of participants struggling, expressing surprise, articulating frustration.
- **Strength:** emotional, memorable, shared in Slack and recalled months later.
- **Weakness:** easy to misuse — you can construct any narrative from selective clips. Use carefully.

Use highlight reels to *complement* findings, not replace them. The clip shows the pain; the finding tells you what to do about it.

### The long report (10+ pages)

- **For:** rare. People who genuinely need depth — a stakeholder writing a strategy doc, a regulatory submission, an academic paper.
- **Format:** structured document with full method, full findings, appendices.
- **Strength:** complete and citable.
- **Weakness:** read by approximately nobody.

Write a long report only when someone has *asked for one* and you know they'll read it. Otherwise, the time is better spent on a one-pager and a readout.

### The wall poster / persona card / artifact

- **For:** ambient awareness — keeping users in the team's daily field of view.
- **Format:** a single image or page that lives somewhere visible.
- **Strength:** reaches people without competing for time.
- **Weakness:** ignored after a week unless it's referenced in actual decisions.

If you make a poster, make sure someone references it in a meeting or it dies.

## The "So What" Test

Every finding must pass the **so what test**: does it change a decision? If not, it's data, not a finding.

- "Users found the export button hard to find." → So what? → "We should rename the button and move it." → That's a finding.
- "Users said our brand colors are nice." → So what? → ... nothing actionable. → That's noise.
- "5 of 6 participants didn't use the search bar." → So what? → "Search isn't earning its space; the visible nav is doing the work." → That's a finding.

If you can't articulate the "so what" for a finding, either *find* it (the insight is buried), or *delete* it (it's not a finding).

## The Right Number of Findings

A common failure: 30 findings, equally weighted. The team is overwhelmed and acts on none.

**A good readout has 3 to 7 findings.** Beyond 7, the team can't hold them all in mind. Prioritize ruthlessly:

- **The 3 most important things you learned.** The headline.
- **The 4 next most important.** The supporting evidence and additional themes.
- **Everything else.** Mentioned in the appendix or full report; not the focus.

A 20-finding study can be communicated as "the top 3, with the long tail in the appendix." Don't try to give everything equal weight.

## The Headline

The first thing the audience reads (or hears) is the headline. **Spend disproportionate effort on it.**

A good headline is:

- **One sentence.**
- **A finding, not a topic.** "Users abandon checkout when shipping cost surprises them" — not "study on checkout flow."
- **Honest.** Doesn't oversell or undersell.
- **Memorable.** The team should be able to repeat it from memory.

Examples:

| Bad headline | Better headline |
|---|---|
| "Q1 user research findings" | "Most users can't tell our product apart from a spreadsheet — and the ones who can are the ones we should be designing for" |
| "Usability test results" | "5 of 6 users abandoned checkout when shipping cost appeared, regardless of price" |
| "User feedback summary" | "Users want to trust the AI's recommendations but our UI doesn't show its work" |

Strong headlines are arguments. They commit. They take a position the audience can react to.

## Showing the Data

Two errors are common:

1. **Hiding the data**, presenting only conclusions. The audience has to take your word for it; if they don't trust you, they ignore the conclusions.
2. **Drowning in data**, presenting everything. The audience gets lost; the conclusions don't land.

The right balance: **strong conclusions, with evidence directly attached**. For each finding, include 1–3 representative quotes or clips. The audience should see *why* you concluded what you concluded.

### Quotes and clips

- **Use participant words verbatim.** Paraphrasing introduces interpretation.
- **Attribute by ID, not name.** "P3" not "Sarah."
- **Pick representative, not extreme.** The most dramatic quote is often the least typical.
- **Provide context.** "P3, when asked to find the export button: 'I thought there'd be a download button somewhere?'" — better than just the quote alone.

### Counts and numbers

- **Use counts, not adjectives.** "5 of 6 users" beats "many users."
- **Acknowledge the n.** "In our study of 6 users..."
- **Don't overclaim.** Findings from 6 US users are not findings about all global users. State the population.

### Visual aids

A useful visual is one that *adds information* the prose doesn't. A useless visual is one that decorates the prose.

- **Heatmaps** of where users clicked or looked — useful when relevant.
- **Funnels** showing drop-off rates — useful when there's a comparison.
- **Quote cards** that pull a quote out for emphasis — useful for memorability.
- **Stock photos** of people pretending to look thoughtful — useless. Skip.

## Adapting to the Audience

The same finding might need three different framings for three audiences:

| Audience | Framing |
|---|---|
| **Designers** | "Users couldn't find the export button; we should rename it 'Download as CSV'" |
| **Engineers** | "Renaming the export button is a low-effort win that 4 of 6 users would have benefited from. Estimated impact: ~30% reduction in support tickets about exports." |
| **Product** | "Export discoverability is one of the top 3 friction points in our analytics workflow. Cost to fix: small. Cost of not fixing: continued friction in a feature we already invested in." |
| **Leadership** | "Our analytics workflow has a friction problem we can fix cheaply. We have a clear, evidence-based plan." |

The underlying finding is the same. The framing differs because each audience cares about different things and has different decision criteria.

## Getting Findings to Stick

A finding heard is not a finding remembered. Some practices help findings outlive the readout meeting:

- **Recurring references.** Cite the finding in design reviews, sprint planning, and decision documents for weeks afterward. "Per the Q1 findings, users in this segment prioritize speed over flexibility — that's the lens for this feature."
- **Tie findings to decisions.** When a decision is made citing a finding, write that down. The decision becomes evidence the finding mattered.
- **Surface findings in onboarding.** New team members read the recent research as part of joining.
- **Quote findings in roadmap discussions.** "We're prioritizing this because of finding X from study Y."
- **Maintain a research index.** A shared, searchable list of past findings. Future researchers cite it; future designers consult it.
- **Re-validate when relevant.** "We thought X based on the study from 6 months ago — is it still true?" Revisiting keeps findings honest.

## When the Findings Are Unwelcome

Sometimes research surfaces things the team doesn't want to hear:

- "Users don't actually want this feature."
- "The redesign is worse than the old version."
- "The new direction the team has been pursuing doesn't match what users care about."

How to communicate uncomfortable findings well:

1. **Lead with empathy.** Acknowledge the team's investment. "I know this is frustrating to hear after everyone's hard work on the redesign."
2. **Be specific, not sweeping.** "Users couldn't find feature X" is better than "the redesign failed."
3. **Frame as opportunity, not condemnation.** "Here's what we now know that we didn't before — and here's how to use it."
4. **Don't soften the finding to make it easier to hear.** If it's a real finding, the team needs to hear it clearly. Wrap it in empathy, not euphemism.
5. **Bring options, not just problems.** "Here's the finding. Here are three things the team could do in response. We can talk through which one fits best."
6. **Be ready for pushback.** Some teams will deny, deflect, or attack the methodology. Respond to specific concerns; don't get defensive.
7. **Cite the data, not your authority.** "5 of 6 users couldn't find the button" lands better than "I think the design is wrong."

The hardest version: **leadership has committed publicly to a direction the research now contradicts.** Be honest, be specific, give options, but recognize that organizational momentum is real. Sometimes the honest finding still loses to the political reality. That's okay — the finding is on the record, and the team has been told. Future decisions will be better informed even if this one isn't reversed.

## Anti-Patterns

- **The unread report.** 30-page PDF, filed in a shared drive, never opened. The team's attention is finite.
- **The presentation that's just the slides.** No discussion, no decisions. Time wasted.
- **Findings buried in method.** First 10 pages are "how we recruited and ran the study." The audience gives up before reaching the findings. Method goes in the appendix.
- **Equal weight on every finding.** 25 bullet points; nothing prioritized; team acts on none.
- **Findings without recommendations.** "Users were confused." So what should we do?
- **Recommendations without findings.** "We should redesign the dashboard." Why? Where's the evidence?
- **Vague findings.** "Users wanted more clarity." Says nothing.
- **Cherry-picking the dramatic.** One vivid quote becomes the finding; the boring 5 sessions are ignored.
- **Pretending certainty you don't have.** "Users prefer A over B." Based on what? 6 sessions? Be honest about the limits.
- **Defending the team's existing plan.** Presenting the research as if it confirms what the team was already doing — even when it doesn't. This is the most damaging kind of dishonesty.
- **No follow-up.** Findings communicated; team forgets within a week. No one references them again. Plan the recurring reference up front.
- **Findings communicated only once.** Big readout meeting; never mentioned again. Findings die in the silence.
- **Communicating everything to everyone.** Engineering doesn't need the same depth as the executive sponsor. Tailor.

## Related

- [synthesis-and-insights.md](synthesis-and-insights.md) — what you're communicating
- [discovery-and-problem-framing.md](discovery-and-problem-framing.md) — problem statements and how they're communicated
- [personas-and-jtbd.md](personas-and-jtbd.md) — persona and JTBD artifacts as communication tools
- [ethics-and-bias.md](ethics-and-bias.md) — communicating uncomfortable findings honestly
- [assets/findings-readout-template.md](../assets/findings-readout-template.md) — fillable readout / one-pager template
- [documentation-writer](../../documentation-writer/SKILL.md) — getting findings into living documentation
