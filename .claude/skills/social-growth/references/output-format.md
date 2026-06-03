# Output Format

Return a single response with **two clearly-labeled blocks**, both ready to paste:

```
### LinkedIn (primary)

<post body — 180–260 words, hard line breaks between paragraphs>

### X (fan-out)

<post body — same copy, tightened for X>
```

If the input was a blog file path, also include a **Buffer cadence note** at the bottom:

```
### Buffer cadence

- One Content post per day max, weekday-only (Tue/Wed/Thu peak; Wed default).
- Fan-out to LinkedIn + X on the same day counts as one slot.
- Configure your Buffer channel IDs and queueing preferences locally before using this cadence.
```

Do not queue to Buffer from this skill. Queueing is a separate explicit step.

---

## LinkedIn structure

Target length: **180–260 words.**

1. **Hook (line 1).** Stop the scroll. Use one of:
   - `🌶️ Take:` — followed by a contrarian one-liner.
   - `✨ Shower Thought:` — followed by a half-formed observation that's actually true.
   - A bold standalone claim, ideally with a number.
   - A surprising lived detail.
2. **Setup (1–3 lines).** Why this is true / how you know. One specific.
3. **Body (3–6 short paragraphs).** The argument. Each paragraph is 1–3 sentences max. No filler transitions.
4. **Question (1 line).** A real question, not rhetorical. Something the reader has a take on and wants to type.
5. **CTA (1 line, only if a blog exists).** Link to the post with a one-liner framing — never "Read more on my blog."

If there's no blog, drop the CTA. Close on the question.

---

## X variant rules

- **Default — Premium long post.** The LinkedIn post fits in one X post without splitting. Single newline between paragraphs. Keep hook, body, question, CTA and link inline at the end.
- **If >280 chars and asked for a single tweet**, emit a 280-char standalone hook + link. The hook must work on its own.
- **Thread is not the default.** Only emit a thread if the user explicitly asks, or if the blog has 4+ distinct numbered takeaways. For thought-leadership threads with ASCII diagrams, route to `x-longform-post`.
