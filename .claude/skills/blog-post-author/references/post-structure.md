# Post structure

The hook → body → close arc, specialized for each blog variant. The brief picks the variant; this reference picks the structure.

## Universal: the opening 200 words

The first 200 words decide whether the rest of the post is read.

- **Hook** (sentences 1–3): the strongest writing in the post. The contrarian claim, the headline number, the misconception. Never "in this post we'll explore." Never a definition the reader already knows. Never "imagine if."
- **Takeaway** (within the first 200 words): state it plainly. The reader who skims should still leave with the takeaway.
- **Stakes** (often inside the takeaway paragraph): why does this matter today, not next quarter?

If the brief gave you a single takeaway sentence, that sentence belongs in the first 200 words — verbatim or near-verbatim. Don't bury it.

## Universal: the close

- Restate the takeaway in different words from the open.
- Give the reader the one thing to do next — even if that's just "remember this when you're stuck on X."
- No "in conclusion." No "I hope this helped." No filler bow.
- The sign-off is whatever the brief declared: newsletter mention, link out, no link, CTA. Honor it exactly.

## Opinion / thought leadership

The structure mirrors the brief's argument structure:

```
1. Hook — name the contrarian claim or the pattern the reader is stuck inside.
2. Takeaway paragraph — the position, stated plainly. Stakes.
3. Claim 1 — the easiest defense. Evidence. One concrete example.
4. Claim 2 — the harder defense. More evidence. Acknowledge the counterargument here, where it's strongest, not at the end.
5. Claim 3 — the resolution. Pull the claims together; show how they imply the takeaway.
6. (Optional) Counterargument addressed head-on if not already woven in.
7. Close — stakes restated. Sign-off.
```

**Voice notes for opinion:**
- Lead with the strongest claim. Buried leads kill opinion posts.
- One claim per section. If a section makes two claims, you're hedging.
- Concrete > abstract. "We've seen this fail twice in production" beats "this can fail."
- Acknowledge the counterargument *inside* the section it weakens, not in a "but to be fair" paragraph at the end. Hostile readers stop reading before then.

## Case study

The structure follows the story arc from the brief:

```
1. Hook — open on the moment of friction or the headline number.
   Examples: "We were two days out from launch when the dashboards started lying."
            "We cut our infra bill by 71% in six weeks. Here's what worked, and what we'd skip next time."
2. Takeaway paragraph — the generalizable lesson, stated as advice.
3. Problem — what was broken or unsolved at the start. What was at stake.
4. Approach — what was tried. The bet. The reasoning.
5. Outcome — what changed. The numbers, with context (sample size, time window).
6. Friction — what didn't work, what was nearly abandoned, what surprised the team. **This is mandatory.** Stories without friction read like brochures.
7. Lesson — the generalizable principle. One sentence on what *doesn't* generalize.
8. Close — restate the lesson as advice. Sign-off.
```

**Voice notes for case study:**
- Numbers carry the post. Lead sections with the number; let prose explain.
- First-person plural ("we tried", "we shipped") lands harder than passive voice ("an approach was attempted"). Use it unless the brief specifies otherwise.
- Friction is non-negotiable. If the brief didn't surface friction, push the user to add it before drafting.
- If the subject is named, the post should read like the subject would proudly link to it — but not like a press release.

## Deep dive / explainer

The structure is built around the worked example:

```
1. Hook — name the misconception you're about to break, or the question this post answers.
   Examples: "Most people think prompt caching saves money on reads. The savings are actually in the writes."
            "Why does HTTP/2 still leak packet boundaries? It comes down to a TLS layer most people don't think about."
2. Takeaway paragraph — the mental model the reader will have by the end, in 2–3 sentences.
3. Setup — minimal context the reader needs. Skip what the brief said is assumed knowledge.
4. Worked example introduction — name the specific case the post unpacks.
5. Walk-through — go through the example one piece at a time. Each piece installs one part of the mental model.
6. Misconception callouts — interleaved where they land. Each one: name the wrong intuition → show why it breaks → give the better frame.
7. Generalization — "now that you've seen this case, here's the model in general."
8. Edge cases / caveats — where the model breaks down or doesn't apply.
9. Close — restate the mental model in different words. Point to the next concept (or the next post in the series).
```

**Voice notes for deep dive:**
- The worked example is the spine. If the example is weak, the post is weak — pause and find a better example before drafting.
- "Show, then tell" — let the reader see the mechanism work in the example before generalizing.
- Misconceptions are first-class. Name the wrong intuition before correcting it. Don't ship a correction without the misconception attached; readers won't recognize it as theirs.
- Cite primary sources for technical claims. No training-data folklore. Defer to `source-driven-development`.
- Diagrams earn their space. Each one should install a piece of the mental model the prose alone can't. If a diagram is just decoration, cut it.

## When to break the structure

The arcs above are defaults, not rules. Reasons to break them:

- The hook is so strong it deserves to delay the takeaway by a few extra paragraphs (rare — usually the takeaway should still land early).
- The case-study friction is the *whole* story (e.g. "we tried X, it failed, we tried Y, it failed, we tried Z, it worked"). Then friction *is* the body.
- The deep dive is short enough that walking through one example is the entire body, with no separate "generalization" section.

If you break the structure, the brief's takeaway and voice still hold. Structure is the frame; takeaway and voice are the contract.
