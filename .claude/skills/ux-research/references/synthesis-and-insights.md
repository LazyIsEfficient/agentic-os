# Synthesis and Insights

Synthesis is the process of turning raw research data into things the team can act on. It is the part of the work where most studies fail — not because the data was bad, but because the synthesis was rushed, biased, or never finished.

The synthesis stage is where insight is created. Done well, it's the most valuable hour of the entire study. Done badly, it's the place where 20 hours of recordings become a slide deck nobody reads.

## The Findings → Insight → Recommendation Ladder

A common confusion: people use these words interchangeably. They aren't the same, and conflating them produces reports that are simultaneously too long and too useless.

| Term | What it is | Example |
|---|---|---|
| **Observation** | A specific thing someone did or said | "P3 spent 90 seconds looking for the export button. Eventually clicked the gear icon. Said: 'I thought there'd be a download.'" |
| **Finding** | A pattern across multiple observations | "4 of 6 participants couldn't find the export button on the first try; all four expected it under a 'download' label." |
| **Insight** | The *why* behind a finding — a theory of the user's mental model | "Users think of CSV export as 'downloading the data,' not as 'exporting' it. The verb mismatch hides the feature." |
| **Recommendation** | A specific action to take | "Rename the 'Export' button to 'Download as CSV' and move it to the top-right of the table." |

The four are a ladder. Each rests on the one below.

A report that gives only observations is data, not insight. A report that gives only recommendations is opinion the team will ignore. **A report that gives all four is what changes decisions.**

## The Workflow

A useful synthesis workflow has roughly five steps:

1. **Capture** — get all the raw data into a single place.
2. **Tag** — mark observations as you go through the data.
3. **Cluster** — group related observations into themes.
4. **Interpret** — for each theme, ask "so what?" and articulate an insight.
5. **Recommend** — for each insight, name the action.

Rushing any step degrades the next one.

### 1. Capture

Get every relevant artifact into one place: notes, recordings, transcripts, screenshots, screen recordings, post-session memos. The point is that the synthesis happens against the raw material, not against summaries you wrote three weeks ago.

Tools: Dovetail, Notion, Miro, Airtable, Google Docs, plain folders. The tool doesn't matter; what matters is that the team can find anything in it.

### 2. Tag

As you go through each session, tag observations. A tag is a one-line label: "couldn't find export," "confused by the icon," "expected it to be in settings."

Two principles:

- **Tag what was actually said or done**, not your interpretation of it. "Said 'this is annoying'" not "user is frustrated."
- **Use participant words where possible.** They are more honest than your translations.

A tag is fine-grained: a single observation might get 1–3 tags. Don't try to tag perfectly the first time; you'll re-tag during clustering.

### 3. Cluster

Once you have a body of tags, group them into themes. The classic technique is **affinity mapping**: put each tag on a sticky note (physical or digital), put related ones near each other, name the resulting groups.

Affinity mapping is more powerful than it looks because it:

- Forces you to confront the data spatially.
- Surfaces patterns you'd miss in a list.
- Lets multiple researchers cluster together and see disagreements as they happen.
- Reveals the "outliers" — observations that don't fit any cluster (which are sometimes the most important).

Tools for digital affinity mapping: Miro, FigJam, Mural, or built into Dovetail.

#### Anatomy of a useful cluster

A cluster has:

- **A short name** that captures the theme. Not "Findings about checkout" but "Users abandon when shipping cost surprises them."
- **A handful of representative observations**. Not all of them — the most vivid 3–5.
- **A count** of how many participants the theme came up for. "5 of 6" is a stronger pattern than "1 of 6."
- **An interpretation** in one sentence — what you think it *means*.

#### How many clusters?

Most usability tests produce 5–15 distinct clusters. Most discovery studies produce 8–20. If you have 50 clusters, you haven't clustered yet — you've just listed observations under headings. Re-cluster.

If you have 2 clusters, you've over-grouped — split them.

### 4. Interpret

For each cluster, ask **"so what?"**

A cluster like "users couldn't find the export button" is data. The "so what" is the insight:

- **Why** were they looking somewhere else?
- **What does that tell us** about their mental model?
- **What does it imply** about how the design should change?

Insights are theories of the user. They're falsifiable, they're explanatory, and they generalize beyond the specific observation.

Examples:

| Finding | Insight |
|---|---|
| 4 of 6 users couldn't find export | Users think of structured data as something to "download," not "export" — the verb mismatch hid the feature |
| Users abandoned the cart when shipping cost appeared | Users decide to buy *before* knowing total cost; finding out the total at checkout feels like a bait-and-switch even when it isn't |
| Users typed in the search box without scrolling first | Search is the default discovery tool for users in this segment; the visual nav is decorative to them |
| Users skipped the empty state's CTA | Empty states with one CTA feel like ads, not instructions |

The insight is **portable**: the team can apply it to other parts of the product, not just the specific screen tested.

### 5. Recommend

Each insight should produce one or more **specific actions**.

A bad recommendation: "Improve the export feature."
A good recommendation: "Rename the 'Export' button to 'Download as CSV' and move it to the top of the table. Owner: Sam. Estimated effort: small. Validation: re-test with 5 users in two weeks."

Rules for good recommendations:

- **Specific.** A reader knows what to do without further interpretation.
- **Owned.** A person or team accountable.
- **Bounded.** Not "rebuild everything" but a discrete change.
- **Linked to the insight.** "Because users think of this as 'download'..." — the rationale travels with the recommendation.
- **Prioritized.** P0 / P1 / P2.
- **Falsifiable.** A success criterion the team can measure later.

## The Confirmation Bias Trap

The single largest source of error in synthesis is confirmation bias: you find what you came to find. The defenses are not optional.

### Write the hypothesis first

Before you start synthesis, write down what you currently believe the answer is. Then read the data with that hypothesis in mind and **actively look for evidence that contradicts it**. The contradicting evidence is much more valuable than the confirming evidence.

### Look for the disconfirming case

For every theme, ask: "what would *not* fit this theme?" If the answer is "nothing" then either you've found a real, robust theme — or you've stopped seeing the data that doesn't fit. Force yourself to find at least one observation that contradicts each theme before you commit to it.

### Have someone else review

Pair synthesis is much more reliable than solo synthesis. A second researcher's fresh eyes catch your blind spots. If you can't pair, at least have someone else review the clusters and ask "would you have grouped this differently?"

### Quote, don't paraphrase

Use participants' actual words in your themes and insights. Paraphrasing introduces interpretation; quotes are hard to misread.

### Count

If a theme is "many users were confused," count. "5 of 6 participants" is honest; "users were confused" is rhetoric.

### Beware the vivid quote

A single dramatic moment can dominate synthesis disproportionately. The participant who passionately declared "this product changed my life!" or "I would rather use Excel than this" sticks in memory and crowds out the four less-quotable participants who had milder, more typical reactions. Weight by frequency, not by drama.

## Quantifying Qualitative Data

Qualitative research generates *patterns*, not statistics. But you can be *quantitatively honest* about the patterns:

- **Use counts**, not adjectives. "5 of 6" beats "many."
- **Distinguish "all" from "most" from "some" from "one."** Each is a different strength of evidence.
- **Acknowledge n.** "In a study of 6 users, 5 had this problem" is honest. "83% of users have this problem" is statistical theater.
- **Don't generalize beyond the sample.** Findings about US small business owners do not necessarily apply to enterprise users in Japan. State the population the findings apply to.

A reader should always be able to ask "out of how many?" and get a clear answer.

## Synthesis Anti-Patterns

- **Cherry-picking the dramatic quote.** One vivid moment becomes the headline; four boring sessions are forgotten.
- **Skipping clustering.** Going straight from raw notes to a recommendation. Misses patterns and over-weights the most recent session.
- **Confirmation bias.** Reading the data with the team's hopes in mind; seeing what you want to see.
- **Solo synthesis on a big study.** No second pair of eyes; blind spots untouched.
- **Themes that match the team's existing beliefs.** Suspiciously well. Ask: "what did I expect to find?" If everything matches, you're not seeing the data.
- **Recommendations without insights.** "Make the button bigger" — why? The team will ignore it.
- **Insights without recommendations.** "Users have a mental model gap around exports." — so what?
- **Findings without counts.** "Users were confused." How many? Out of how many?
- **The 50-page report.** Time-consuming to write, not read by anyone. A one-pager + a 30-min readout reaches more people and changes more decisions.
- **Treating outliers as noise.** Sometimes the outlier is the most important data point — the user with the very different mental model is showing you something the others can't.
- **Re-synthesizing months later for a different question.** The data was collected to answer question X; the team now wants it to answer question Y. Be honest: it can't, or it can only weakly. Run a new study.
- **No "what we don't know."** A good synthesis is honest about what the study can't answer. Hides nothing; reduces over-claiming.

## Related

- [research-methods.md](research-methods.md) — different methods produce different kinds of data; synthesis varies accordingly
- [interview-craft.md](interview-craft.md) — interview data is the most common synthesis input
- [usability-testing.md](usability-testing.md) — usability findings get a specific form of synthesis
- [communicating-findings.md](communicating-findings.md) — packaging the synthesis output for the team
- [personas-and-jtbd.md](personas-and-jtbd.md) — personas and JTBD statements are synthesis artifacts
- [ethics-and-bias.md](ethics-and-bias.md) — bias defenses for synthesis
