# Interview checklist

For each template, these are the questions to ask when the section is missing or vague. Batch them into one `AskUserQuestion` call. Skip any whose answers are already obvious from the user's initial message.

## Universal questions (any template)

- **Core fantasy**: "What role or feeling is the player buying into? Finish the sentence: 'You are a ___ who ___.' If you can't, the design has no compass."
- **Player verbs**: "What does the player *do*? Give me 1–3 verbs (dodge, build, deceive, command, collect). Avoid features ('a skill tree') — those are how, not what."
- **Target player**: "Who plays this — gaming experience, comp titles they already love, and who should *skip* it?"
- **Platform**: "Where does this run — Steam, iOS, Android, Web, Console, or multiple? Cross-play / cross-save?"
- **Business model**: "Premium, F2P, hybrid, subscription, ad-supported, or web3-native? If undecided, what's your gut, and what's pushing back?"
- **Payment rails (mandatory)**: "What payment rails will this game use — none, web2 IAP (App Store/Google Play/Steam), web2 subscription, web2 ads, web3 tokens, web3 NFTs, or hybrid? Include constraints (e.g. 'must work where crypto IAP is restricted')."
- **Success bar**: "What does 'good enough to ship' look like — a wishlist target, a soft launch CPI floor, a retention floor, a jam ranking, a review score?"

## Full game (`full-game-template.md`)

- **Genre + comps**: "What genre is this and which 2–4 games are the closest comps? What's the *one thing* this does differently?"
- **Scope**: "Total dev time, team size, content target — and what are you *deliberately not* building so scope doesn't drift?"
- **Engine + art style**: "Engine and art-style direction (or undecided)? Anything ruled out?"
- **Constraints**: "Hard deadlines, platform-imposed rules, IP/brand constraints?"
- **Source material**: "Existing prototypes, design docs, mood boards, jam builds, or repos to reuse?"

## Prototype (`prototype-template.md`)

- **Hypothesis**: "What single thing is this prototype meant to prove or disprove? Phrase it falsifiably."
- **Vertical slice scope**: "What's *in* the slice (systems, levels, content variety) and what's stubbed?"
- **Kill criteria**: "What outcome makes you drop the idea entirely vs. keep going?"
- **Timebox**: "How many weeks, with what mid-checkpoint and demo date?"
- **Telemetry**: "Which 3–5 events would prove or disprove the hypothesis?"

## Jam (`jam-template.md`)

- **Theme interpretation**: "How are you reading the theme — literal, metaphorical, twist, subversion?"
- **Ranking targets**: "Which 2–3 categories will you optimize for? Which are you deprioritizing?"
- **Cuts**: "Order the things you'll cut first if time runs out. What's the absolute MVP that ships if everything else fails?"
- **Pre-jam prep**: "What templates, starter kits, or asset libraries do you already have ready?"

## Live game update (`live-game-update-template.md`)

- **Why now**: "What problem or opportunity drives this update? What evidence — KPI delta, tickets, reviews, competitive move?"
- **Players targeted**: "Which segment — lapsed, new installs, top spenders, mid-funnel? Who is *not* targeted?"
- **Don't break**: "What load-bearing elements must NOT regress?"
- **Success and guardrails**: "Primary KPI for success, plus guardrail KPIs that must hold."
- **Rollout**: "A/B, staged, or full launch? Kill switch?"

## Domain-specific prompts

If the user mentions **web3** at all, also ask:
- "Why web3 — token incentive, asset ownership, secondary market liquidity, regulatory positioning, or community/marketing? The answer changes downstream design more than the label."
- "Custodial or non-custodial wallets? Chain choice (or shortlist)?"
- "How does the game work for players who *can't* (or won't) connect a wallet? Web2 fallback path?"

If the user mentions **F2P mobile**, also ask:
- "Soft launch geography and target CPI? D1/D7/D30 floors before global launch?"
- "Hard currency design — single currency or multiple? Earnable in meaningful amounts or paid-only?"
- "Live ops cadence — events, passes, season length?"

If the user mentions **premium / Steam indie**, also ask:
- "Wishlist target before EA / 1.0?"
- "EA plan — what ships in EA vs at 1.0?"
- "Deck verification target if Steam — handheld supported?"

## Question hygiene

- Never ask more than ~6 questions in one batch.
- Never ask a question whose answer is obvious from the user's message.
- Prefer concrete questions ("which 2 verbs?") over open-ended ("tell me about gameplay").
- If the user volunteered something in prose, distill it into the template — don't ask them to repeat.
- **Push back on feature lists**. If the user gives features instead of verbs/fantasy, ask: "what does the player *do* with <feature>, and what fantasy does it serve?" The template is verb-and-fantasy-led, not feature-led.
- **Always include the payment-rails question** even if monetization seems obvious — the answer routes balance, monetization, IAP, and marketing decisions later.
