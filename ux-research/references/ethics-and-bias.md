# Ethics and Bias

Research is an exchange. The participant gives you their time, attention, and often something personal about how they live and work. You give them respect, compensation, and the assurance that what they share will be handled honestly. The exchange only works if you keep your end of it.

This file is the standards of practice. It's also the catalogue of ways research goes wrong even when it isn't trying to.

## Informed Consent

A participant has consented when:

1. They **know what they're agreeing to** — what the study is about, what's recorded, who will see it, what it'll be used for, how long it'll be kept.
2. They **agree freely** — not coerced by employer, friend, money pressure, or perceived obligation.
3. They **can withdraw at any time** without consequence — including after the session ends.

Consent is not a checkbox. A consent form signed without understanding is not consent. The test: could the participant explain to a friend what they just agreed to?

### What to disclose

Before the session:

- Who you are (you, your team, your organization).
- What the study is about (in plain terms; not a marketing pitch).
- What will happen during the session (interview, screen share, prototype walkthrough, etc.).
- How long it will take.
- What's being recorded (audio? video? screen?).
- Who will see the recording (just the immediate team? client? public report?).
- How long the data will be kept and when it'll be destroyed.
- That they can stop, skip questions, or withdraw at any time.
- That withdrawal has no consequences for them — including no loss of compensation.
- How they'll be compensated and when.

Restate the key points on the recording at the start of the session. This protects you and gives them a clear "exit point."

### Written vs verbal

- **Written consent** for: anything sensitive (health, finances, immigration, employment), academic studies, regulated industries, anything with potential legal exposure, anything where the recording will be shown outside the immediate team.
- **Verbal consent on the recording** is fine for: low-stakes usability tests, internal research, recordings that won't leave the immediate team.

When in doubt, get it in writing.

### Right to withdraw

Make it real. A participant who says "actually, can we stop?" gets a thank-you, full compensation, and an immediate end to the session. No "are you sure?" No follow-up about why. No retention of their data after withdrawal.

Withdrawal *after* the session must also work. If a participant emails a week later and asks to be removed, remove their data and confirm.

## Compensation

Pay people. Pay them fairly. Pay them on time.

### Why compensation matters ethically

- **Time has value.** Asking for an hour of someone's attention without compensating it is extracting unpaid labor.
- **Compensation widens the pool.** Without it, you're recruiting only people who say yes for free, who are systematically different from the segment you're trying to learn about.
- **It makes the relationship explicit.** Money on the table changes the dynamic from "favor" to "professional engagement," which is more honest.
- **It protects against exploitation.** People in vulnerable economic situations are more likely to participate; fair compensation prevents the research from being predatory.

### Rates

Norms vary by region, role, and seniority. Rough US ranges as of writing:

- **Consumer / general public:** $50–$150 per hour-long session.
- **Professional / specialist:** $100–$250.
- **Executive / hard-to-recruit / regulated:** $200–$500+.
- **Children / vulnerable populations:** higher, with parental compensation included.

Cheap compensation is a false economy: you save money on participants and pay for it in biased findings.

### Form

Common forms: gift cards (Amazon, Visa, retailer-specific), prepaid debit cards, account credits, charity donations on the participant's behalf, direct cash. Tax obligations may apply over certain thresholds — check.

### Pay if the session falls through

If you cancel: full compensation. If they show up but the prototype is broken and you have to cancel after 5 minutes: full compensation. If they don't fit the criteria after the screener: still pay something (a smaller "screener fee" is common). If a session takes 30 minutes instead of 60 because you got everything you needed: full compensation for the booked time.

The principle: **the participant kept their commitment; you keep yours.**

## Vulnerable Populations

Some groups warrant extra care because they may be less able to refuse, more affected by harm, or more likely to be exploited:

- **Children** — parental consent required, child assent required separately, never alone with the researcher, age-appropriate language and tasks.
- **People in crisis** — financial, medical, emotional. Don't extract data from someone in distress; reschedule or cancel.
- **People with cognitive disabilities** — consent must accommodate the disability; have a trusted support person present if needed.
- **Employees of your own company** — there's an implied power dynamic. Make withdrawal genuinely free of consequence; don't share findings with their manager in identifiable form.
- **Customers paying for the product** — be careful not to mix research with sales or support.
- **People in regulated contexts** — patients, students, prisoners, military. Often subject to formal IRB or ethics board approval. Don't wing it.
- **People reliant on the product for income** — gig workers, freelancers, small business owners using your tool. They may feel they can't decline for fear of consequences.

When in doubt, slow down. Consult someone who has run research with that population before.

## Sensitive Topics

Certain topics require extra care regardless of who the participant is:

- **Health and medical** — privacy regulations vary by region (HIPAA in the US, GDPR in EU). Consult before recording.
- **Financial** — never ask for actual numbers; ask about ranges or relative comparisons. Don't ask for screenshots of bank statements unless you're prepared for the consequences.
- **Immigration status, legal history, citizenship** — never ask unless absolutely required and consented.
- **Sexuality, religion, politics** — usually irrelevant to product research; avoid unless directly relevant.
- **Trauma, abuse, mental health** — train for it before researching it. Have resources ready.
- **Children's safety, family dynamics** — consult professionals. Don't improvise.

If a participant volunteers sensitive information you didn't ask for, handle it with care: thank them for sharing, don't probe further unless directly relevant, exclude it from the report unless it informs the actual question.

## Data Handling

What happens to the data after the session is part of the ethical commitment.

### Storage

- **Encrypt at rest.** Recordings, transcripts, notes — all stored with encryption.
- **Limit access.** Only people who need it. Not the entire company.
- **Identifiable vs anonymized.** Identifiable data (names, emails, video) needs stricter access controls than anonymized data.
- **Backups follow the same rules.** A backup that exposes identifiable data is the same problem as the original exposure.

### Retention

- **Define a retention period in advance.** "Recordings deleted 1 year after study completion" is a typical default.
- **Follow it.** Calendar a deletion date. Actually delete.
- **Honor withdrawal requests immediately.** Even if the retention period hasn't expired.

### Sharing

- **Inside the team:** generally fine, with anonymization where appropriate.
- **Outside the team:** requires explicit consent, often re-confirmed for the specific use.
- **Public-facing:** explicit, written, specific consent for the specific use. "We may share this with the public" is too vague — "we will use a 30-second clip from this session in a conference talk on January 15" is specific.
- **In aggregate findings:** generally fine without specific consent, as long as individuals can't be re-identified.

### Re-identification

The risk: even anonymized data can sometimes be re-identified by combining quasi-identifiers (job title, region, age, employer). For small samples in narrow segments, this risk is real. Strip more aggressively than you think you need to. "Project coordinator at a 40-person agency in Brooklyn" is identifiable to anyone who knows the industry.

## Researcher Bias

You will see what you expect to see. The defenses are not optional.

### Confirmation bias

The team's existing beliefs shape what you notice in the data. Defenses:

- **Write the hypothesis before the study.** Make beliefs explicit so you can be honest about whether the data confirms or refutes them.
- **Look actively for contradicting evidence.** For each theme, ask "what observations don't fit?" If you find none, you're not seeing them.
- **Have someone else review.** A second researcher's eyes catch your blind spots.
- **Pay attention to your discomfort.** When the data contradicts what you wanted to find, that's the gold — write it down extra carefully.

### Anchoring

The first few sessions disproportionately shape how you interpret later sessions. Defenses:

- **Don't synthesize after each session.** Wait until you have 5+, so the early ones don't anchor everything.
- **Re-read your early notes after the later sessions.** You'll often see things differently with the rest of the data in mind.

### Recency

The last session you ran is fresh and vivid; earlier sessions feel less real. Defenses:

- **Re-listen to sessions in random order**, not in the order they were run.
- **Weight by frequency, not vividness.**

### Expert bias

You know the product too well. Things that confuse first-time users seem obvious to you. Defenses:

- **When you find yourself thinking "this should be obvious," it isn't.** That's the data.
- **Test with people who don't already know the product.**
- **Have outsiders review your synthesis.**

### Politeness bias

Participants are nice to you. They tell you the design is "fine" when it isn't, agree with statements you make, and avoid criticizing the team. Defenses:

- **Watch behavior, not opinion.** What they do is more reliable than what they say.
- **Set the stage in the intro.** "There are no wrong answers; we want to hear what doesn't work."
- **Probe negatives explicitly.** "Tell me what didn't work — that's the most useful kind of feedback."
- **Don't defend the design.** Defending teaches them to stop being honest.

## Sample Bias

Your participants are not your users. The gap between them is one of the largest sources of bad research. Common sources:

### Recruitment bias

- **People who say yes to research** are systematically different from the population. They're often more engaged, more verbal, more willing to give time.
- **Friends and family** are biased toward you. Useless.
- **Existing users** miss everyone who churned, who never signed up, or who tried and bounced.
- **Recruitment panels** miss people who don't sign up for panels.
- **Free participants** miss people whose time has too much value to give for free.

Defenses: combine recruitment channels; oversample lapsed and lost users; pay enough to widen the pool; document the recruitment biases in your report.

### Self-selection bias

People who volunteer for research are different from people who don't. Especially severe in surveys ("only people with strong opinions answer optional surveys").

Defenses: incentivize broadly; reach out actively; over-recruit and randomly sample down.

### Convenience bias

Recruiting whoever is easiest is the most common bias and the hardest to detect afterward.

Defenses: define recruitment criteria *before* recruiting; refuse to compromise them; budget extra time for harder-to-reach segments.

### Survivorship bias

You only talk to users who still use the product. The ones who quit are invisible. The reasons they quit are exactly the things you most need to learn.

Defenses: deliberately recruit churned users; customer support log mining; exit surveys.

## Integrity in Communication

Not every ethical issue is about the participant. Some are about how you communicate findings.

- **Don't cherry-pick.** Reporting the dramatic vivid quote without context is dishonest. Pick representative material.
- **Don't oversell certainty.** A study of 6 users doesn't prove anything; it suggests strongly. State the n. Acknowledge what the study can't answer.
- **Don't hide unwelcome findings.** If the data invalidates a team's plan, communicate it. Hiding it is a worse betrayal than the disagreement.
- **Don't reframe findings to fit the team's existing direction.** This is the most damaging kind of dishonesty — it makes research a tool for confirmation rather than a tool for truth.
- **Don't claim what you didn't find.** "Users want X" — based on what data? If they didn't say it, don't claim it.
- **Don't generalize beyond the sample.** Findings about US users are not findings about all global users.
- **Cite who, when, how.** Findings should be traceable to the studies that produced them. Future readers can check the basis for the claim.

## Anti-Patterns

- **Consent as paperwork.** Signed forms; participant has no idea what they agreed to. Not consent.
- **Coercive recruitment.** "Your manager said you should participate." Doesn't matter what they "agree" to — it isn't free agreement.
- **Cheap compensation.** Recruiting only people who say yes for free.
- **Late compensation.** Paying weeks after the session. Erodes trust and the participant relationship.
- **Friend-and-family research.** Polite, biased, useless.
- **Over-promising.** "This will only take 15 minutes" when you know it'll take 45.
- **Identifying participants by name in reports.** "Sarah said..." — even if Sarah agreed, anyone who knows Sarah can read the report. Use IDs.
- **Re-using data for a different question.** Data was collected with consent for purpose X; using it for purpose Y without re-consenting is a violation, even if technically the same data.
- **Hiding withdrawal.** Burying the "you can withdraw" mention in legal text. Make it visible and actionable.
- **Unencrypted recordings on laptops.** Lost laptop, lost recordings, real harm.
- **Endless retention.** Recordings from 2018 still on a shared drive in 2026 because no one set a deletion date.
- **Recording without consent.** "I forgot to ask." Delete the recording. Re-do the session if you can.
- **Defending the design in interviews.** Trains the participant to stop being honest.
- **Writing the conclusions before the study runs.** "We'll just run a quick study to confirm." Theater, not research.
- **Cherry-picking quotes.** The dramatic quote becomes the finding; the boring 5 sessions are forgotten.
- **Reframing findings to please the team.** Makes the next study less trusted and worth less.
- **Pretending certainty you don't have.** Six users do not prove anything. Say so.
- **Reusing participants.** Same panel, same people, every study. They become "professional participants" who know what to say. Rotate the pool.

## Related

- [study-planning.md](study-planning.md) — building consent and compensation into the plan
- [interview-craft.md](interview-craft.md) — handling sensitive topics in real time
- [synthesis-and-insights.md](synthesis-and-insights.md) — bias defenses during synthesis
- [communicating-findings.md](communicating-findings.md) — integrity in communication
- [security-engineering](../../security-engineering/SKILL.md) — handling participant data securely
