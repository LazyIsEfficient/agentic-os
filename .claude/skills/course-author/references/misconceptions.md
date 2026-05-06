# Misconceptions

A misconception callout is a short block that names a wrong intuition the learner plausibly holds, shows why it fails, and offers a better frame. Done well, it's the highest-leverage paragraph in the lesson — it converts a fragile learner (right answer, wrong reason) into a durable learner (right answer, right reason). Done badly, it reads as a lecture the learner didn't ask for.

## The shape

Every misconception callout has three beats, in order:

1. **Trap.** A belief the learner plausibly holds. Stated as the belief, not as a villain. Not "people think X, which is wrong." Rather: "You might assume X."
2. **Why it fails.** A concrete failure mode. A specific scenario, a specific broken outcome. Not "this doesn't scale" — rather "at 500 concurrent writers, this produces N lost updates per minute."
3. **Do instead.** The better frame, tied back to the core idea of the lesson. One sentence, action-first.

## Source the trap from the learner's likely prior

The belief in "Trap" should be something the learner has plausibly absorbed — from older docs, a common blog-post pattern, a previous job, or just a natural but wrong intuition. If the trap reads as a strawman nobody would actually believe, skip the callout; you're not addressing a real risk.

Sources of real misconceptions:
- **Older versions of the same technology.** A practice that was correct in version N is now wrong in version N+1.
- **Adjacent-domain transfer.** A practice that's correct in web apps doesn't apply in batch jobs, or vice versa.
- **Natural extrapolation.** "If some caching is good, more caching is better." "If async is faster here, it's faster everywhere."
- **Anthropomorphic reasoning about models.** "The model will ask if it's unclear." (It won't.)
- **Happy-path reasoning in system design.** "Services will be up." (They won't.)

## Frame without condescension

The callout should land as "here's a smart-sounding idea that breaks in a specific way", not "here's what dumb people think". Readers recognize the difference instantly, and a condescending callout loses trust for the rest of the lesson.

Compare:

> **Trap:** Most people think you can just add a cache. That's wrong.

vs.

> **Trap:** When latency is high on a read endpoint, adding a cache looks like the obvious fix.
> **Why it fails:** The hard part isn't reading from the cache — it's knowing when to invalidate. Without a staleness budget, a cache ships bugs instead of speed.
> **Do instead:** Before adding a cache, name the staleness budget for this data. If the answer is "never stale", cache-aside is wrong; reach for a different pattern.

The second version wins. It gives the learner a reason the trap seems attractive, then specifies the failure, then points them at a usable decision.

## Placement

Place misconceptions **between the worked example and the exercises**. Why:
- Before the worked example, the learner hasn't yet seen the right frame, so the correction lands on thin air.
- Inside the worked example, the correction interrupts the flow and costs the example its momentum.
- After the exercises, the learner has already committed to the wrong frame; the correction is damage control, not prevention.

The one exception: if the worked example explicitly uses the correct pattern and the learner is likely to ask "why not the obvious approach?" — answer in an aside *inside* the example. Keep it short.

## One, two, or three

Lessons vary. Most have one callout. Some have two. Three is the ceiling — more than three and the lesson starts to feel like a list of warnings, which trains the learner to skim.

If the spec names four or more misconceptions, pick the top one to three by impact ("which would cost the learner the most if they left with it unchallenged?") and drop the rest into "going deeper" or flag the spec as overloaded.

## AI-content misconception prompts

Common ones, drawn from `course-design/references/domain-pitfalls.md`:
- Prompt-as-incantation: phrasing tricks over specification.
- Anthropomorphizing: the model "knows" or "intends".
- Context-window blindness: pasting more vs filtering relevance.
- Single-turn tunnel vision: forcing multi-turn work into one shot.
- Evaluation by vibes: judging output by how it reads.

For AI content specifically, misconception callouts work well when they're paired with a small before/after: show the prompt or interaction that embodies the wrong belief, then show the version that reflects the better frame.

## System-design misconception prompts

Common ones:
- Scale-first: designing for 10× before shipping 1×.
- Cargo-cult patterns: CQRS / microservices / Kubernetes as defaults.
- Synchronous by default: ignoring the blast radius of a slow dependency.
- Caching as magic: adding a cache before naming the staleness budget.
- Metrics theater: dashboards that nobody acts on.

For system-design content, callouts land best when "Why it fails" includes a specific failure scenario with numbers — "at 2k QPS, the blast radius is…" — rather than an abstract warning.

## Checklist

Before shipping a callout, check:
- [ ] The trap is stated as a belief the learner plausibly holds, not a strawman.
- [ ] The failure mode is concrete (scenario + broken outcome).
- [ ] The "do instead" is one action-first sentence.
- [ ] The callout is placed between the worked example and the exercises.
- [ ] The lesson has no more than three callouts.
