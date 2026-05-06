# Design Critique

A critique is a structured conversation about a piece of design work, with the goal of making it better. Done well, critique is the most reliable way to improve a design — better than the designer working alone, better than ad-hoc feedback, better than waiting for usability tests.

Done badly, critique is a vibes meeting where everyone gives opinions, the designer feels attacked, the work doesn't change, and people start avoiding the meeting. Most "design reviews" in most companies are this.

The difference is **structure**. A useful critique has a designer asking for a specific kind of feedback at a specific stage of the work, and reviewers giving feedback in the form most useful to the designer. Both sides have a job.

## What Critique Is For

A critique is an exchange. The designer wants:

- **Sharper thinking.** Other people see things the designer is too close to see.
- **Validation that the work is on the right track** — or honest pushback if it isn't.
- **Specific suggestions** for things to try.
- **Catching problems early**, while they're cheap to fix.

A critique is *not* for:

- **Approval.** A critique is collaborative, not gating.
- **Rewriting the design by committee.** The designer is still the designer.
- **Status updates.** "Here's what I've been working on this week" is not critique.
- **Performance reviews.** Critique is about the work, not the person.
- **Designer's emotional support.** Sometimes that's needed; that's a different conversation.

The two failure modes: critique-as-approval (turns into gatekeeping; designers learn to game it) and critique-as-vibes (everyone has opinions; nothing improves).

## The Designer's Job

The designer asks for the critique. Their job is to *set the conversation up well*.

### Bring context

The first 2–3 minutes should give reviewers:

- **What the design is for.** The problem statement, in one sentence.
- **Who it's for.** The user segment or persona.
- **Constraints.** Technical, business, time, dependencies.
- **What's been tried already.** "I considered approach X but rejected it because Y."
- **What stage the design is at.** Sketch, wireframe, mockup, prototype, almost-shipped.
- **What kind of feedback you want.** This is the most important sentence.

Without context, reviewers don't know what they're looking at. They make assumptions, those assumptions are usually wrong, and the feedback misses the mark.

### Ask for what you need

The single most important sentence in the entire critique:

> "I'd specifically like feedback on `<X>`. I'm not looking for feedback on `<Y>` right now."

Examples:

> "I'd like feedback on the structure and information hierarchy. The visuals are placeholder; please don't focus on the colors or icons."

> "I'd like feedback on whether this onboarding flow makes sense for first-time users. I'm not looking for feedback on the copy yet — that's coming."

> "I'd like brutal feedback on the empty state. Does it tell the user what to do?"

> "I'd like to know if the trade-offs I made make sense. I considered making this a modal — I went with a side panel because of X. Is that the right call?"

This single sentence reshapes the conversation. Reviewers know what's in scope. The designer gets actionable feedback.

### Be open

Critique only works if the designer is *willing to change the work*. If you're showing something you've already committed to, you're not asking for critique — you're asking for approval. Be honest with yourself about which one you want.

### Don't defend prematurely

A common designer instinct: explain *why* a choice was made before the reviewer can finish their feedback. This kills the critique.

The reviewer's reaction is data. Even if the reaction is "wrong" by your understanding, the fact that the reviewer reacted that way is information about how a future user might react. Listen first; explain (if needed) only after the reviewer has finished.

### Take notes

Take notes during critique, even if you think you'll remember. You won't. Specifically note:

- **What confused people.**
- **What people asked about** ("why is this here?").
- **What people suggested** (note even the bad suggestions; they often point at real problems).
- **What people praised** (so you don't accidentally remove what worked).

After the critique, sit with the notes. Don't react immediately. The good ideas will rise; the noise will fall.

## The Reviewer's Job

The reviewer's job is to *help the designer improve the work*. That's it. Not to show off, not to win, not to share their pet preferences.

### Listen to the ask

If the designer said "I want feedback on the structure," don't give feedback on the colors. The designer chose what to ask for; respect that. Notes about the colors can go in a follow-up message; they don't belong in this conversation.

### Lead with the why

Bad: "I'd move the button to the top."
Good: "I'd move the button to the top because users in this state will probably scan there first. I'm thinking of the analytics-reading pattern from study X."

The "why" lets the designer judge the suggestion. The bare suggestion forces them to either take it or fight it.

### Be specific

Bad: "This feels off."
Good: "The headline and subhead don't have enough hierarchy difference; the eye doesn't land on either."

Vague feedback is unactionable. The designer can't fix "off." They can fix "not enough hierarchy."

### Distinguish blocking from suggestion

In good critique, not all feedback is equal. Some feedback is "this would be a real problem if you ship it." Some is "I'd consider this." Some is "this is just my preference." Make the distinction explicit.

Useful prefixes (steal from code review):

- **Blocking:** "I think this is a real problem we should solve before shipping."
- **Strong suggestion:** "I think this could be significantly better with X."
- **Suggestion:** "Have you considered Y?"
- **Preference:** "Personally I'd lean Z, but it's a judgment call."
- **Question:** "Why is this here? I'm not sure I follow."

A critique made entirely of "preferences" wastes the designer's time. A critique made entirely of "blocking" crushes them. Mix honestly.

### Don't redesign in the room

The temptation to grab the marker and redraw the design yourself is strong. Resist. Your job is to help the designer think, not to do their job. Suggest, ask, push — but the design stays in their hands.

### Build on others' feedback

If another reviewer made a point and you agree, say so. Don't repeat the same point in different words; reinforce it briefly and move on.

If you disagree, say so respectfully. Disagreement among reviewers is fine — it tells the designer that there's a real trade-off. They get to decide.

### Praise what works

A critique is not just for problems. Name what's working — especially the non-obvious things the designer might be tempted to remove later. "The empty state with the inline action is great — it's much clearer than the version with the modal."

This isn't softness; it's information. Praise prevents the designer from "improving" the things that didn't need improvement.

### Don't review tired

You will hallucinate problems, miss real ones, and write feedback you didn't mean. If you're tired or in a bad mood, decline or postpone.

## Critique Formats

There's no single "right" critique format. Useful ones:

### Open studio / share-out

A regular session (weekly) where designers share work in progress. Each gets 10–15 minutes. Mostly informal but with light structure.

- **Best for:** ambient awareness; catching problems early; maintaining team cohesion.
- **Risk:** unfocused; can become a status meeting.
- **Fix:** require an explicit "ask" for each piece shown.

### 1:1 critique

Designer and one trusted reviewer (often a peer or design lead). Half an hour to an hour.

- **Best for:** in-progress work; sensitive feedback; deep discussion of trade-offs.
- **Risk:** echo chamber; one perspective only.
- **Fix:** rotate reviewers; combine with group critique.

### Group critique (3–6 people)

A small group, including design and adjacent disciplines (PM, engineering, sometimes research, sometimes stakeholders).

- **Best for:** decisions that affect multiple disciplines; surfacing trade-offs; cross-functional alignment.
- **Risk:** diffuse feedback; non-designers giving design feedback.
- **Fix:** facilitate carefully; let the designer choose which feedback to act on.

### Async critique

The designer posts the work in a chat or document; reviewers comment over time.

- **Best for:** time-zone-distributed teams; lightweight feedback; specific questions.
- **Risk:** slow; comments without context; pile-on; no real conversation.
- **Fix:** clear ask in the post; deadline for feedback; designer summarizes and responds.

### Heuristic critique / expert review

A reviewer (usually senior design or research) walks through the design against a checklist of heuristics (Nielsen's 10, accessibility, content, etc.).

- **Best for:** late-stage review; catching specific problem categories; auditing against a standard.
- **Risk:** mechanical; misses subjective issues.
- **Fix:** combine with user-centered methods.

Most teams need 2–3 of these formats running concurrently: a regular open studio, occasional 1:1, and ad-hoc group reviews for big decisions.

## Facilitating Critique

Group critiques benefit from a *facilitator* — someone whose job is to keep the conversation on track, not to give feedback themselves.

The facilitator's role:

- **Time-keep.** Each piece gets the time it was allotted; nobody dominates.
- **Direct the conversation.** "Let's hear from Alex first." "Sam, you had a comment?"
- **Re-anchor on the ask.** "Remember, the designer asked about structure, not visuals."
- **Surface consensus and disagreement.** "It sounds like several of you agree about the empty state."
- **Protect the designer.** "Let's give Glenn a chance to respond before we pile on."
- **End with a recap.** "So the main feedback was X, Y, Z. Did I capture it?"

A good facilitator turns a chaotic vibes meeting into a productive working session. Without one, group critiques degrade.

## After the Critique

What the designer does *after* the critique determines whether it had any value.

The right sequence:

1. **Sit with the notes** for a few hours or overnight. Don't react in the room.
2. **Sort the feedback** into: things to act on, things to consider, things to acknowledge but not act on, things to reject.
3. **Reply to the reviewers** with a summary of what you took. "Thanks for the feedback. I'm going to try X based on Sam's point. I'm leaving Y as-is because Z. Alex, I'd love to talk through the third one — can we sync?"
4. **Iterate.** Make the changes.
5. **Show the result** in the next critique if it's a significant change.

The "reply with a summary" step matters. It tells reviewers their feedback was heard. Without it, reviewers feel ignored and stop giving real feedback.

## Receiving Difficult Feedback

Some critique is uncomfortable. The work is yours; the criticism feels personal even when it isn't. Ways to handle this well:

- **Separate the work from yourself.** The reviewer is critiquing the design, not you. Easy to say; takes practice to feel.
- **Listen completely before reacting.** Even if you disagree, hear it out.
- **Ask questions** if you don't understand. "Can you say more about why you'd move that?"
- **Don't argue in the room.** Note disagreements; respond after sitting with them.
- **It's okay to disagree.** You're the designer; you make the call. But disagree from a place of having actually considered the feedback, not from defensiveness.
- **Watch for patterns.** If three different reviewers point at the same thing, that's not an opinion — it's a real signal.
- **Take care of yourself.** Critique is hard. After a tough session, take a break. Don't power through.

## When Critique Goes Wrong

Common failure modes and how to fix them:

### "This is great!" syndrome

The work isn't great, but everyone says it is, and the designer ships something flawed. Fix: ask for *specific* feedback; the open question "what could be better?" usually surfaces real concerns.

### Pile-on

Five reviewers each point out the same thing, the designer feels crushed, defensive, useless. Fix: facilitator surfaces the consensus quickly and moves on.

### Bikeshedding

Reviewers fixate on the trivial (button color, icon choice) and miss the structural problems. Fix: designer's explicit ask scopes the discussion. Facilitator redirects.

### Rabbit holes

One reviewer's pet topic eats the meeting. Fix: time-box. "Let's note that and come back to it."

### Designer-as-victim

The designer treats every piece of feedback as an attack and pushes back on everything. Critique becomes adversarial; reviewers stop giving real feedback. Fix: coach the designer on receiving feedback; let them know feedback is data, not insult.

### Reviewer-as-redesigner

A reviewer takes over and redesigns the work in real time. Designer feels dispossessed. Fix: facilitator explicitly returns the floor to the designer.

### Critique-as-approval

The team treats critique as gating. "Did design get critiqued?" becomes a checkbox. Designers start showing only safe work. Fix: separate critique (improvement) from approval (decision). They're different processes.

### Critique-of-the-week

Every week's critique is a new piece nobody has seen. Reviewers can't track progress; the designer can't take feedback iteratively. Fix: show *progress* in the critique. "Here's how I changed it based on last week's feedback."

## Anti-Patterns

- **No explicit ask.** Reviewers don't know what to give feedback on.
- **Defending prematurely.** Designer explains every choice before reviewers can finish.
- **Vague feedback.** "It feels off." Unactionable.
- **All preferences, no rationale.** Reviewers' personal taste dominates.
- **No prioritization.** Every piece of feedback presented as equally important.
- **Rewriting the design in the room.** Reviewers grab the marker; designer becomes spectator.
- **No follow-up.** Designer takes notes; nothing happens.
- **No reply to reviewers.** Reviewers feel ignored; stop giving real feedback.
- **Hostile critique.** Personal attacks dressed as feedback. Toxic; destroys the practice.
- **"Only senior designers critique."** Junior designers have fresh eyes that catch things experienced ones miss. Include them.
- **Critique as performance.** Designer presents polished work and looks for applause. Not critique.
- **Avoiding critique.** Designer never shares work in progress; ships designs that haven't been pressure-tested.
- **Group think.** First reviewer's opinion shapes everyone else's. Fix: ask reviewers to write down their reactions before sharing.
- **Feedback without "why."** "Move the button." Why?
- **Too much feedback.** Reviewers offer 30 things to fix; designer is overwhelmed; nothing gets fixed. Fix: prioritize ruthlessly.

## Related

- [design-process.md](design-process.md) — critique is part of the develop and deliver phases
- [wireframing-and-prototyping.md](wireframing-and-prototyping.md) — what you're showing in critique
- [handoff-and-collaboration.md](handoff-and-collaboration.md) — late-stage critique with engineering
- [software-design](../../software-design/SKILL.md) — code review heuristics overlap heavily
- [team-lead](../../team-lead/SKILL.md) — facilitating a critique session as a lead
- [assets/critique-prompt-template.md](../assets/critique-prompt-template.md) — fillable critique setup
