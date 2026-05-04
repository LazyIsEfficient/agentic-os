# Code snippet discipline

Code snippets are where lessons succeed or fail. A good snippet is short, runnable, self-contained, and labeled with its intent. A bad snippet is long, partial, undocumented, and leaves the learner reverse-engineering.

## The rules

### 1. Minimal — no more than the point requires

If the snippet demonstrates one mechanism, cut everything that isn't load-bearing for that mechanism. Setup, error handling, logging, tracing, styling — all of it goes unless it's the subject. A learner reading your snippet is spending working memory on every line; lines that don't earn their place tax the concept.

When real code *is* verbose, extract only the lines that matter for the teach. Use the omission pattern (below) to signal that real code has more.

### 2. Runnable as shown — or explicitly labeled as not

Default: snippets run. That means:
- All imports are present.
- All helper functions are either defined above or are standard library.
- No reference to `someHelper()` or `api.client` that the learner can't resolve.
- If the snippet requires an environment (API key, running service), say so in the snippet's intent label.

If a snippet is deliberately not runnable — because it's pseudocode, or because you're showing shape not working code — mark it explicitly:

```python
# pseudocode — illustrates the control flow, not a runnable script
```

or

```ts
// excerpt from <file> — surrounding setup omitted for brevity
```

Never ship partial code without one of these labels. The learner will try to run it, fail, and blame themselves.

### 3. One mechanism per snippet

A snippet that demonstrates two mechanisms teaches neither. Split. Each snippet gets one "what this shows" label.

If a mechanism genuinely requires multiple snippets (e.g., a before/after pair, or a three-step build-up), present them as a sequence with a one-line label each. The build-up is the lesson; the snippets are its steps.

### 4. Paired with an intent label

Every snippet has a one-line adjacent label: *"What this shows: ..."* or as part of the step heading. The label carries the *why*; the code carries the *what*. If you need more than one line to say what the snippet shows, the snippet is doing too much.

### 5. Omissions marked — not hidden

If a snippet elides code for brevity, mark the elision:

```ts
function handleRequest(req) {
  validate(req);
  const user = getUser(req.userId);

  // ... retry/circuit-breaker logic omitted for brevity
  const result = callDownstream(user);

  return format(result);
}
```

The `// ...` line is part of the teach: it tells the learner "real code has more here; we're not teaching that part now." Never pretend the omitted code doesn't exist.

### 6. Show the output

When a snippet produces output — a console log, an API response, a model completion, a test result — show the output next to or below the snippet:

```
$ python rate_limiter.py
Request 1: 200 OK
Request 2: 200 OK
...
Request 11: 429 Too Many Requests
```

Output anchors the code to reality. Lessons that describe output in prose instead of showing it feel hand-wavy; the learner can't verify.

### 7. Name the file if it matters

Multi-file examples need file-name headings:

```ts
// src/limiter.ts
export function limit(req: Request) { ... }
```

```ts
// src/server.ts
import { limit } from "./limiter";
```

If the whole example lives in one file, don't add a file-name heading — it's noise.

### 8. Prefer language features that match the audience

If the course assumes TypeScript, don't drop into Python for one snippet. If the audience is senior backend engineers, a `map` is fine; if it's beginners, a `for` loop may be clearer. The spec's audience section controls; don't show off.

### 9. No dead lines

`console.log("hello")` inside a lesson on rate limiting is a dead line. Every line either demonstrates the mechanism, sets up the demonstration, or is a marked omission. Dead lines tax working memory for no teach.

### 10. Version-pin when behavior depends on it

If a snippet depends on a specific SDK version, model, API, or runtime, say so:

```python
# anthropic==0.39.0, model claude-opus-4-6
```

This matters especially for AI content, where model behavior shifts over time. A snippet that "used to work" but doesn't with the current model should be updated or clearly dated.

## Format checklist (per snippet)

Before you ship a snippet, run through:

- [ ] Runnable as shown, or marked `pseudocode` / `excerpt`.
- [ ] One mechanism.
- [ ] Paired with a one-line "what this shows" label.
- [ ] Omissions marked with `// ...` + comment, not silent.
- [ ] Output shown if the snippet produces any.
- [ ] File name given if the example spans files.
- [ ] Language matches the course's assumed stack.
- [ ] Version-pinned if behavior is version-sensitive.
- [ ] No dead lines.

## AI-content specifics

For snippets that interact with AI models:
- Pin the model name and SDK version.
- Show the prompt exactly as the SDK will see it (not a simplified paraphrase in prose).
- Show a *real* completion if you can; if you must summarize, mark it as summarized.
- If the example uses a system prompt, show it. Hidden system prompts undermine the teach.

## System-design specifics

For architecture diagrams or configuration snippets:
- Prefer Mermaid over ad-hoc ASCII art (easier to update; renders in most venues).
- For config (YAML, HCL, JSON), show only the keys under discussion; use `# ...` elision for the rest.
- Name the constraints the configuration satisfies ("tuned for 2k QPS, p99 < 50ms"), so the learner can judge whether a similar config fits their situation.
