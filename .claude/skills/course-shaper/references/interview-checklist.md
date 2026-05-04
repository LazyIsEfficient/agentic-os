# Interview checklist

For each template, these are the questions to ask when the section is missing or vague. Batch them into one `AskUserQuestion` call. Skip any whose answers are already obvious from the user's initial message.

## Universal questions (any template)

- **Audience**: "Who is this for — role, experience level, and what do they already know? Who should *skip* it?"
- **Outcomes**: "What should the learner be *able to do* when they finish? Give me 1–3 concrete, observable outcomes — verbs like build, diagnose, design, compare, implement, explain. Avoid 'understand' or 'know about'."
- **Assessment bar**: "How will you know a learner has actually got it? Per-lesson checks, a final project, a portfolio piece, or nothing formal?"
- **Format**: "Medium and duration? Written / video / notebook / live? Total hours?"
- **Tooling**: "What stack, runtime, or environment do you want to assume? Any API keys or sandboxes the learner needs?"
- **Opinions**: "What opinion or point of view do you want the course to embed? (Courses without an opinion read like Wikipedia — boring and forgettable.)"

## Full course (`full-course-template.md`)

- **Topics in scope**: "What topics map to each outcome? If a topic doesn't support an outcome, should it be cut?"
- **Out of scope**: "What are you *deliberately* not covering? Name it so the outline doesn't drift there."
- **Source material**: "Do you already have notes, posts, talks, or a repo we can mine for content?"
- **Platform**: "Where will this live — a docs site, Notion, a learning platform, a repo?"

## Single module (`single-module-template.md`)

- **Standalone or part of a course?**: "Is this a unit inside a larger course, or a self-contained module?"
- **Lesson count**: "Rough lesson count you have in mind? (3–8 is typical.)"
- **Module-level evidence**: "Is there a single exercise or mini-project that proves the module outcome?"

## Workshop (`workshop-template.md`)

- **Duration and mode**: "How long (1–4 hours typical), and live vs recorded?"
- **Pre-work**: "What must participants have installed/configured before they join, or should the first 10 minutes cover setup?"
- **Artifact**: "What do they leave the session with — a working repo, a diagram, a written plan?"
- **Group size**: "Solo, small group, or cohort? This changes hands-on block design."

## Domain-specific prompts (AI usage / system design)

If the course is about **effective AI usage**, also ask:
- "Which AI systems — chat assistants, coding agents, API-level integration, or all three?"
- "Is the audience building *with* AI (developers, integrators) or using AI *at work* (operators, analysts)?"
- "Do you want to embed a stance on context engineering, evals, or agent design, or stay tool-neutral?"

If the course is about **system design fundamentals**, also ask:
- "What scale are we teaching at — small services, mid-size distributed systems, or hyperscale?"
- "Do you want the course to be language/stack-agnostic, or anchored in a specific stack?"
- "Which fundamentals are load-bearing — reliability, scalability, data modeling, API design, cost, or a subset?"

## Question hygiene

- Never ask more than ~6 questions in one batch.
- Never ask a question whose answer is obvious from the user's message.
- Prefer concrete questions ("what outcomes?") over open-ended ("tell me about the audience").
- If the user volunteered something in prose, distill it into the template — don't ask them to repeat.
- **Push back on topic lists**. If the user gives topics instead of outcomes, ask: "what should the learner *do* with <topic>?" The template is outcome-led, not topic-led.
