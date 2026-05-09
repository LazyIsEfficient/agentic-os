# Interview checklist

For each template, these are the questions to ask the user when the relevant section is missing or vague. Batch them into one AskUserQuestion call. Skip any whose answers are already obvious from the user's initial message or the working directory.

Each question is tagged:
- 🔒 **load-bearing** — must be answered before the brief ships; re-ask in round 2 if missing.
- 🟡 **assumable** — fill with a safe default and tag inline as `[Assumed: <value> — say if wrong]` if the user defers. The default is in italics.

## Universal questions (any template)

- 🔒 **Goal**: "In one sentence, what changes for the user when this is done?"
- 🔒 **Done criteria**: "How will you know it's working? What would you check?"
- 🟡 **Deadline / urgency**: "Is there a date this needs to land by, or is this open-ended?" *Default: open-ended.*
- 🟡 **Out of scope**: "What should I explicitly *not* touch or expand into?" *Default: anything outside the stated goal.*

## Multi-repo feature (`feature-rollout-template.md`)

- 🔒 **Repos**: "Which repos/services are in play? Paths if you have them."
- 🔒 **Contracts**: "Is there a shared API/schema/event contract that needs to change? Who owns it?"
- 🟡 **Rollout order**: "Any constraints on which repo ships first? (e.g. consumer before producer, schema before code)" *Default: producer-then-consumer; schema-then-code.*
- 🟡 **Compatibility**: "Does this need to be backwards-compatible during rollout, or can we ship a flag day?" *Default: backwards-compatible.*

## Single-repo feature (`single-repo-feature-template.md`)

- 🟡 **Entry points**: "Where in the code does this start? A route, a CLI command, a job?" *Default: discover during step 1 of the approach.*
- 🟡 **Tests**: "What level of test coverage do you want — unit, integration, both?" *Default: unit + integration on the new code paths.*

## Investigation (`investigation-template.md`)

- 🔒 **The actual question**: "What's the one question you want answered? (not 'tell me about X' — a question with an answer)"
- 🔒 **Decision it unblocks**: "What will you do differently depending on the answer?"
- 🟡 **Depth**: "Quick scan, medium dig, or thorough? Roughly how much time should I spend?" *Default: medium dig.*
- 🟡 **Prior knowledge**: "What do you already know or suspect? What have you ruled out?" *Default: none stated.*

## Bugfix (`bugfix-template.md`)

- 🔒 **Broken behavior**: "What does it do vs. what should it do?"
- 🔒 **Repro**: "Can you reproduce it? If so, how?"
- 🟡 **First seen**: "When did it start? Any recent deploy or change you suspect?" *Default: unknown — to investigate.*
- 🟡 **Blast radius**: "How many users / how often? Is this a fire or a papercut?" *Default: unknown — papercut assumed.*
- 🟡 **Workaround**: "Is there a workaround in place, or is the system broken right now?" *Default: assume no workaround.*

## Question hygiene

- Round 1: 3–6 questions, prioritizing 🔒 load-bearing items first.
- Round 2 (only if a 🔒 item is still unresolved): 1–3 follow-ups covering only those items. Do not re-open 🟡 items.
- Never ask a question whose answer is obvious from the user's message or the cwd.
- Prefer concrete questions ("which repo?") over open-ended ones ("tell me more about the system").
- If the user already volunteered something in prose, *distill it into the template* — don't ask them to repeat themselves.
- If the user defers on a 🟡 item ("you decide", "whatever's standard"), apply the default and tag it `[Assumed: <value> — say if wrong]`. Do not re-ask.
