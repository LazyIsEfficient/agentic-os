# Interview checklist

For each template, these are the questions to ask the user when the relevant section is missing or vague. Batch them into one AskUserQuestion call. Skip any whose answers are already obvious from the user's initial message or context.

## Universal questions (any blog variant)

- **Single takeaway**: "If the reader remembers one sentence from this post, what is it? Push past topic — give me the *claim*."
- **Target reader**: "Who is the reader? Role, level, what they currently believe about this topic."
- **Length target**: "How long should this run? Tight 800-word punch, standard 1500–2500, or full deep-dive 3000+?"
- **Voice**: "Match a reference post, founder voice, or specific tone? Any words/phrases I must avoid?"
- **Publication context**: "Where does this publish — own blog, Substack, Medium, LinkedIn article? Cross-post plan?"
- **SEO surface**: "Target keyword and search intent — or is this owned-audience only? If owned-audience, say so."
- **Asset bundle**: "Which assets does this post need? Hero image, OG card, X/LinkedIn share posts, embedded diagrams, code samples, internal-link map, newsletter excerpt — say yes/no on each."
- **Quality gate**: "Run through expert panel scoring (target 90+) and AI humanizer pass before publish?"

## Opinion / thought leadership (`opinion-template.md`)

- **Why now**: "What made this post timely? A recent event, a debate you keep having, a market shift?"
- **Argument structure**: "What are the 2–4 claims that add up to the takeaway?"
- **Counterargument**: "What's the strongest objection a hostile reader would raise? Naming it weakens it."
- **Stakes**: "What's at risk if the reader ignores this? Why should they care today, not next quarter?"
- **CTA / sign-off**: "Where does the post send the reader — newsletter mention, link out, no link, book a call?"

## Case study (`case-study-template.md`)

- **Subject + permission**: "Who's the protagonist — named with approval, anonymized, composite, or first-hand?"
- **Story arc**: "What was the problem at the start, what was tried, what was the outcome? Walk me through it."
- **The numbers**: "What metric moved, by how much, over what time? Sample size and caveats?"
- **Friction**: "What didn't work along the way? What was nearly abandoned? Stories without friction read like brochures."
- **Generalizable lesson**: "What's the principle a reader in a similar spot should take away? State it as advice."
- **Subject approval flow**: "Does the subject need to sign off before publish? If yes, who and when?"

## Deep dive / explainer (`deep-dive-template.md`)

- **Concept under explanation**: "What's the *specific* thing being explained? 'Prompt caching' is a topic. 'Why prompt caching costs are dominated by cache writes' is a concept."
- **Mental model**: "Sketch the model the post installs in the reader's head — 3–5 sentences."
- **Worked example**: "What's the single concrete example you'll unpack step-by-step? The post lives or dies on its quality."
- **Misconceptions**: "What does the reader probably believe that's wrong? Name 1–3 misconceptions to correct."
- **Source citations**: "Which primary docs, specs, or papers must be cited? Anything you'll need to defer to source-driven-development on?"
- **Diagrams**: "How many diagrams, and what does each show? Mermaid, ASCII, or generated images?"
- **Prior knowledge**: "What does the reader need to already know to follow this — or do you start from zero?"

## Question hygiene

- Never ask more than ~6 questions in one batch.
- Never ask a question whose answer is obvious from the user's message or context.
- Prefer concrete questions ("what's the takeaway sentence?") over open-ended ones ("tell me about your post").
- If the user already volunteered something in prose, *distill it into the template* — don't ask them to repeat themselves.
- **Always include the asset-bundle question.** This is the load-bearing input for the downstream task files; under-declaring at intake means missing assets at publish time.
- **Always include the SEO-surface question**, even if just to capture "owned-audience only — no SEO target" explicitly.
- Always include the quality-gate question unless the user has already specified expert-panel preference.
- For opinion variants: push hard on the *takeaway sentence*. "Most AI agents fail because of context window management" is a topic. "Most AI agent failures are mislabeled — they're context engineering bugs, not model bugs" is a takeaway.
- For case studies: if the user can't name the metric that moved, the post is probably premature. Flag it as `<unknown — case-study weak without numbers>` rather than papering over it.
- For deep dives: if the user names the topic but not the *mental model*, they don't have a deep-dive idea yet — they have a topic. Push for the model.

## Routing

- If the user's request looks like a tutorial (step-by-step build, hands-on, code-along), it belongs in `course-shaper`, not here. Push back.
- If the deliverable is a tweet thread, X long-form post, LinkedIn post, newsletter, or deck, route to `marketing-shaper`'s content brief or `x-longform-post` instead. This shaper is specifically for blog-shaped posts with associated asset bundles.
