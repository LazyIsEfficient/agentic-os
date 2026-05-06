# game-design-shaper — live-game update

Example of `/game-shape` producing a `live-game-update-template.md` brief — content drop or feature added to a shipped, live game.

---

## User's initial request

> Our mobile RPG just hit a D7 retention dip — fell from 18% to 14% over six weeks. We want to ship a re-engagement update for lapsed players. Probably new heroes + a comeback event. Want to launch in 6 weeks.

## Shaper's batched questions

Live game, retention problem, re-engagement update — routes to `live-game-update-template.md`. Shaper still asks the payment-rails impact question (every monetization-touching update should declare it).

1. **Players targeted — segment precision** — "lapsed" how lapsed? D7-D30 inactive? D30+? Segment by spend tier as well?
2. **Evidence beyond the D7 number** — what does the funnel show? Where in the journey are these players dropping off, and is there a competitive event in market that explains it?
3. **What changes — content or systems?** New heroes (pure content), comeback event (system-ish), or also rebalancing the sticking points that cause the dip?
4. **Payment-rails impact** — IAP catalog change, pass change, ad change? Comeback event with a paid bundle?
5. **What stays the same (deliberately)** — to avoid disrupting working segments, especially top spenders. Name the load-bearing elements?
6. **Success metric and rollback plan** — primary KPI, guardrails, A/B or staged rollout, kill switch?

## User's answers

1. D14–D45 lapsed players who reached account level 20+. We're not chasing D45+ — too cold. By spend tier: focus on free + low-spender; high-spender lapse is a different problem we'll address separately.
2. Funnel shows the dip starting at the campaign chapter-12 boss. ~30% wall there. Competitive: a major new RPG launched 8 weeks ago on iOS in our key geos.
3. Two new heroes (one tank, one healer) tuned for the chapter-12 wall. Comeback event with daily login rewards for 7 days on return. *Also* rebalancing chapter-12 boss difficulty curve. Three changes, one update.
4. New comeback bundle ($4.99 starter pack with one of the two new heroes). No subscription change. No ad change. No web3 elements (we don't have any).
5. Top-spender economy and end-game raid balance must stay untouched. Existing battle-pass tiers and rewards untouched. Chapter 1–11 untouched.
6. Primary: lapsed return rate (target 15% of D14-D45 cohort returning in the 14 days after launch), AND D7 retention recovery to 16%+ within 60 days. Guardrails: D1 retention must not regress, crash-free sessions ≥99%, store review ≥4.4. A/B: ship the chapter-12 rebalance to 50% first for 5 days, then 100% if guardrails hold.

## Output brief

```markdown
## Live game and update name
- Game: <unknown name — to confirm> (mobile RPG, live on iOS + Android).
- Update name / version: "Comeback Season — Two New Heroes + Chapter 12 Rebalance".
- Update type: re-engagement (lapsed-player) — content + system change + monetization change combined.

## Why this update, why now
- Player problem or opportunity: D7 retention fell from 18% to 14% over the last six weeks. The dip starts at the chapter-12 campaign boss, where ~30% of players hit a wall. A major competitive RPG also launched 8 weeks ago in key iOS geos.
- Evidence: funnel telemetry shows chapter-12 as the breakpoint; competitive landscape data confirms the launch overlap; lapsed-survey responses cite "stuck on a boss".
- Hypothesis: a coordinated re-engagement update — easier path through chapter 12, two new heroes that suit the fight, and a comeback event with a starter bundle — will recover both lapsed-player return rate and forward D7 retention.

## Players targeted
- Primary segment: lapsed players, D14–D45 inactive, reached account level 20+, free or low-spender tier.
- Secondary segment: active players approaching chapter 12 (preempt the wall).
- Players *not* targeted: D45+ cold lapses (too cold for this update); high-spender lapses (different root cause, separate workstream).

## What changes
- New content: two new heroes (1 tank, 1 healer) tuned to make the chapter-12 boss tractable.
- Systems changed: chapter-12 boss difficulty curve rebalanced. Comeback event with 7 daily-login rewards on return, scaling toward summon currency on day 7.
- Monetization changes: new "Comeback Starter Pack" ($4.99) including one of the two new heroes plus comeback-event currency. Cap one purchase per account.
- UI / UX changes: re-engagement push notification copy refresh; in-game banner for returning players; updated chapter-12 entry warning for active players who haven't yet reached it.

## What stays the same (deliberately)
- Top-spender economy and end-game raid balance — untouched.
- Battle-pass tier rewards and structure — untouched.
- Chapters 1–11 (entry, pacing, boss difficulty) — untouched.
- Existing IAP catalog beyond the new bundle — untouched.

## Payment-rails impact
- IAP catalog change: yes — one new SKU ($4.99 Comeback Starter Pack). See iap-manager for catalog wiring and price-tier localization.
- Subscription change: no.
- Ad placement change: no.
- Web3 token / NFT change: N/A.
- Compliance review needed: yes — App Store and Google Play review on the new bundle (loot-box disclosure rules, child-safety rating).

## Success metrics
- Primary KPIs:
  - Lapsed return rate ≥ 15% of D14–D45 cohort returning in the 14 days post-launch.
  - D7 retention recovers to ≥ 16% within 60 days (current 14%, prior 18%).
- Guardrail KPIs (must not regress):
  - D1 retention.
  - Crash-free session rate ≥ 99%.
  - Store review score ≥ 4.4 on both stores.
- Measurement window: 60 days post-launch for primary; rolling 7-day for guardrails.

## A/B or staged rollout
- Test plan: ship the chapter-12 rebalance to 50% of new entrants for 5 days, hold control for the other 50%. Promote to 100% if guardrails hold.
- Holdout group: 10% of D14–D45 lapsed cohort held out from comeback push notifications, to measure incrementality.
- Kill switch: feature flag on the new heroes, the chapter-12 rebalance, and the comeback event independently. Bundle SKU can be hidden from the store within 30 minutes if needed.

## Comms plan
- In-game: patch notes (full), login banner for returning players, push-notification campaign to lapsed segment.
- Store page update: new screenshots featuring the two new heroes, "What's New" copy, updated metadata for the season.
- External: community post, Discord announcement, two creator partnerships covering the new heroes.
- See: game-marketer for store-page conversion, push copy scoring, creator brief.

## Risks
- Tech: save-data migration for the chapter-12 rebalance (player progress within the chapter must preserve). Server load spike on Day 1 from re-engagement push.
- Player perception: "pay-to-win" backlash if the bundle hero feels strictly better than free heroes — must tune so the F2P hero is competitive, the bundle hero is convenience.
- Compliance: bundle review on both stores; loot-box rules don't apply (bundle is deterministic) but disclosure must be precise.

## Timeline
- Spec lock: week 1.
- Code complete: week 4.
- QA / cert: week 5 (App Store cert ~5 days, Google Play ~2 days).
- Soft launch (if used): N/A — staged rollout via feature flag instead.
- Full launch: week 6, day 0.
- Post-launch read: day 14 (interim), day 60 (final).

## Open questions
- Does the holdout cohort sit out push notifications only, or also the in-game banner? Affects how isolated the incrementality measurement is.
- Hero balance — F2P hero competitive, bundle hero convenience. Who arbitrates if balance review and monetization review disagree?
- Should the comeback event extend to D45–D60 lapses as a secondary rollout if Day-14 numbers are strong?
```

---

**Next step:** paste this into a fresh session with `game-systems-designer` available (concept is locked — this is a content + system change to a live game). Say `go` and the brief flows to systems-designer (chapter-12 rebalance + comeback event), then iap-manager (bundle SKU + price-tier localization), then game-marketer (store page + push copy).
