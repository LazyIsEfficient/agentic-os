# Interview checklist

For each template, these are the questions to ask the user when the relevant section is missing or vague. Batch them into one AskUserQuestion call. Skip any whose answers are already obvious from the user's initial message or the working directory.

## Universal questions (any template)

- **Goal**: "In one sentence, what changes for the user when this is done?"
- **Done criteria**: "How will you know it's working? What would you check?"
- **Deadline / urgency**: "Is there a date this needs to land by, or is this open-ended?"
- **Out of scope**: "What should I explicitly *not* touch or expand into?"

## Multi-repo feature (`feature-rollout-template.md`)

- **Repos**: "Which repos/services are in play? Paths if you have them."
- **Rollout order**: "Any constraints on which repo ships first? (e.g. consumer before producer, schema before code)"
- **Contracts**: "Is there a shared API/schema/event contract that needs to change? Who owns it?"
- **Compatibility**: "Does this need to be backwards-compatible during rollout, or can we ship a flag day?"

## Single-repo feature (`single-repo-feature-template.md`)

- **Entry points**: "Where in the code does this start? A route, a CLI command, a job?"
- **Tests**: "What level of test coverage do you want — unit, integration, both?"

## Investigation (`investigation-template.md`)

- **The actual question**: "What's the one question you want answered? (not 'tell me about X' — a question with an answer)"
- **Decision it unblocks**: "What will you do differently depending on the answer?"
- **Depth**: "Quick scan, medium dig, or thorough? Roughly how much time should I spend?"
- **Prior knowledge**: "What do you already know or suspect? What have you ruled out?"

## Bugfix (`bugfix-template.md`)

- **Repro**: "Can you reproduce it? If so, how?"
- **First seen**: "When did it start? Any recent deploy or change you suspect?"
- **Blast radius**: "How many users / how often? Is this a fire or a papercut?"
- **Workaround**: "Is there a workaround in place, or is the system broken right now?"

## Question hygiene

- Never ask more than ~6 questions in one batch.
- Never ask a question whose answer is obvious from the user's message or the cwd.
- Prefer concrete questions ("which repo?") over open-ended ones ("tell me more about the system").
- If the user already volunteered something in prose, *distill it into the template* — don't ask them to repeat themselves.
