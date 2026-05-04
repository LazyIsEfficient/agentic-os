# Domain pitfalls

Common misconceptions learners bring to AI-usage and system-design topics. Each lesson spec's "Misconceptions to address" section should draw from this list (or extend it) — `course-author` is responsible for naming and correcting them in the lesson itself.

Two disciplines for designers:
- A misconception is only worth addressing if the lesson genuinely risks reinforcing or leaving it unchallenged.
- Name the misconception as *a thing the learner might already believe*, not as a villain to defeat. Learners resist being told they were wrong; they accept being shown a better frame.

## AI-usage pitfalls

### Prompt-as-incantation
Learners treat prompts as magic words rather than specifications. They believe phrasing tricks matter more than context, constraints, and success criteria.
- **What to teach instead**: prompting is specification writing. The prompt is a contract; vague contracts produce vague outputs.

### Anthropomorphizing the model
Learners assume the model "knows" things the way a person does, reasons like a person, and has intent.
- **What to teach instead**: the model samples plausible continuations conditioned on context. It has no persistent memory across calls (unless given one), no intent, and no ground truth check. Behavior is shaped by what's in the context window *now*.

### Context-window blindness
Learners paste huge amounts of irrelevant text and expect the model to pick out what matters, or conversely, paste too little and expect the model to ask.
- **What to teach instead**: every token in the context competes for attention. Relevance density matters more than length. Retrieval and filtering *before* prompting beats dumping-and-hoping.

### Evaluation by vibes
Learners judge model output by whether it looks right, not whether it's right.
- **What to teach instead**: for any non-trivial use, write down what a good output looks like *before* you see one. Run the same prompt across a few cases. Diff.

### Single-turn tunnel vision
Learners design one-shot prompts when the task is naturally multi-turn, or build chains when one prompt would do.
- **What to teach instead**: match turn structure to task structure. Branching decisions, external tool calls, and long work benefit from multi-turn or agentic patterns. Simple transforms don't.

### Agent-as-oracle
Learners assume agents will figure out ambiguous instructions the way a smart colleague would.
- **What to teach instead**: agents fail silently on ambiguity — they produce confident wrong answers. Precision up-front and observable checkpoints mid-run are how you catch drift.

### Confusing cost with value
Learners optimize for the cheapest model for every task, or reflexively reach for the strongest model for every task.
- **What to teach instead**: model selection is a per-task decision based on error tolerance, latency budget, and cost ceiling. Measure, don't assume.

## System-design pitfalls

### Scale-first thinking
Learners design for 10× traffic before they've shipped 1×. Premature distribution, premature sharding, premature microservices.
- **What to teach instead**: design for the load you have plus one order of magnitude of headroom. Past that, you're solving future problems with current information.

### Cargo-cult patterns
Learners adopt patterns (CQRS, event sourcing, microservices, Kubernetes) because they recognize the name, not because the problem demands them.
- **What to teach instead**: every pattern pays a complexity cost. The question is whether the cost is justified by the current constraints. "Because it's best practice" isn't an answer.

### Handwaving at failure
Learners design happy-path systems and treat failures as a testing concern.
- **What to teach instead**: failure modes are part of the design. Every dependency can be slow, broken, or wrong. Name what happens in each case *at design time*.

### Database-as-single-source
Learners treat the primary database as the only place state can live, then fight its scaling curve.
- **What to teach instead**: state has shape — hot path, cold path, derived, cached, indexed. Different shapes want different stores. Read-heavy and write-heavy workloads often belong in different places.

### Caching as performance magic
Learners add a cache when latency is bad and call it done.
- **What to teach instead**: caching is a correctness problem masquerading as a performance solution. Invalidation is the hard part. Every cache needs a named staleness budget.

### Synchronous coupling by default
Learners call services synchronously because it's easier to reason about, ignoring that one slow dependency takes down the fleet.
- **What to teach instead**: sync vs async is a decision. Sync is right when you need the answer now and the dependency is fast and reliable; async is right when you need decoupling or the work is slow.

### Metrics theater
Learners build dashboards full of metrics that nobody acts on. They confuse observability with "having metrics".
- **What to teach instead**: a metric earns its place only if a change in it changes someone's behavior. Start from the decisions; pick metrics that inform them.

### Cost as an afterthought
Learners design systems without cost models, then discover at scale that a design choice that seemed free is the biggest line item.
- **What to teach instead**: cost is a first-class constraint alongside latency and reliability. Name the unit cost (per request / per GB / per DAU) and track it against the design.

## Using this list

Scan the list when filling a lesson spec's "Misconceptions to address" section. Pick the 1–3 that most directly threaten the lesson's objective. If the list doesn't cover a pitfall your lesson exposes, add it here — this reference grows with the course.
