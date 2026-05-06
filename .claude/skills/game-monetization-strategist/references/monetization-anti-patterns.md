# Monetization anti-patterns

The most common ways monetization strategies fail. Each is a pattern to recognize *before* the strategy ships.

## 1. Pay-to-win in skill-driven PvP

The team ships pay-affecting content in a PvP game pitched on skill. The community detects it within days. Trust drops; review scores tank; comp competitions refuse to feature the game.

**Avoid by:** explicit cosmetic-only commitment in PvP modes. If progression-affecting IAP exists, segregate it to PvE or non-competitive modes.

## 2. Cosmetic IAP in single-player

The team ships cosmetic IAP in a primarily single-player game. Conversion is dramatically below F2P benchmarks. Players don't buy cosmetics nobody else sees.

**Avoid by:** matching IAP type to social context. Single-player → no cosmetics; instead, expansions, story content, premium currency for utility.

## 3. Premium-with-required-live-ops

The game ships premium ($60 one-time) but the design requires live-ops content cadence. Either the team can't sustain content (game decays) or content is sold separately (players feel double-billed).

**Avoid by:** matching the model to the design. If live ops is required, ship with a sub or season pass *in addition to* premium, or shift to F2P.

## 4. Subscription on a finite experience

The team adds a subscription to a game that has a clear endpoint. Players cancel after completing the content. LTV is unsustainable; the math doesn't pencil.

**Avoid by:** subscriptions need ongoing value. If the game is finite, premium is right; if the design is service-shaped, sub works.

## 5. Token-source-dominated economy

Web3 game where token sources are abundant and sinks are weak. Token price collapses; players' earnings devalue; new players see no ROI; population leaves.

**Avoid by:** sinks before sources. Model token velocity in the spreadsheet seriously. Plan for re-tunes when velocity drifts.

## 6. NFT'd combat-effective items

The game NFTs items that affect combat outcomes. Balance changes are required (the meta calcifies). Owners revolt at nerfs. Either the meta stays broken or trust is destroyed.

**Avoid by:** NFT cosmetics, identity, collection items. Keep combat-effective items in web2 storage.

## 7. Dark patterns that damage trust

- **Hidden costs:** "play 3 days, then suddenly everything is gated"
- **Confused currencies:** multiple soft currencies make it impossible to compare value
- **Manipulated scarcity:** "sale ends in 23:59:58" timer that resets every day
- **Pay-to-skip-pain-the-design-introduced:** the design adds friction so the IAP can remove it (often "make timer waits annoying so players pay to skip them")

These work short-term and burn out the audience. Long-term, the studio's reputation drops; press / influencers stop covering; UA channels deplatform.

**Avoid by:** transparent monetization. Players can see what they're paying for, why, and what the alternative is. The IAP is *making the experience better*, not *removing pain the design created to sell the IAP*.

## 8. Whale dependence without depth

A model that relies on whales but offers no aspirational endgame for whales. Top spenders cap out within months; revenue collapses; team panics into ill-advised "whale-only" content that breaks the rest of the game.

**Avoid by:** a real endgame with multiple aspirational tracks. Status, mastery, completion, identity, social — give whales places to spend at their pace.

## 9. Battle pass fatigue

Back-to-back battle passes with similar structure. Players burn out; pass conversion drops; the team's primary monetization vehicle decays.

**Avoid by:**
- Vary pass themes / mechanics across seasons
- Build in breaks (a 1–2 week gap between seasons)
- Reward returning pass-buyers with carry-over credits
- Make free-track rewards genuinely useful, not just a thin path

## 10. Ad over-reliance + IDFA-style shock

The game's revenue is 90%+ from ads. A platform policy change drops eCPM 40%. The model collapses; the team has no fallback.

**Avoid by:** diversification. Even ad-dominant models should have a small IAP / sub option. When ad networks shift, the team has a path forward.

## 11. Crypto-as-feature

The game adds web3 because "everyone is doing it" without a design reason. Token / NFT mechanics feel bolted on. Crypto-curious players find it shallow; mass-market players find it confusing. No segment is well-served.

**Avoid by:** web3 must serve the fantasy or the verb (per `game-concept-creator`). If it doesn't, drop it. Crypto-as-marketing is rarely durable.

## 12. Silent nerf

A monetized item is nerfed without comms. Players who paid find out via gameplay. Refund storm; community erupts; trust takes months to rebuild.

**Avoid by:** announce in advance, compensate, grandfather where possible. Coordinate with `game-marketer` for comms.

## 13. KPI-floor blind launch

The team ships globally without a soft launch or with insufficient soft-launch validation. KPIs come in below the (untested) floors. UA spend is wasted; the team scrambles for a re-tune that should have happened pre-launch.

**Avoid by:** soft launch with floor-target-strong gates. Don't ship globally on optimism.

## 14. Discount erosion

The premium game is discounted aggressively at first sale. Players learn to wait. Future sales drop. Long-tail revenue collapses.

**Avoid by:**
- Hold the line at full price for the first 6–12 months
- Use bundles / DLC for value plays, not raw discounts
- Sales are events, not the default state

## 15. Mid-tier vacuum

The catalog has $0.99 entry and $99.99 whale tier with nothing in between. Dolphins (the bulk of payers) have no SKU that fits them; they don't convert.

**Avoid by:** populate the price-tier ladder with $4.99 / $9.99 / $19.99 / $49.99. Each tier has at least one compelling SKU.

## 16. The "monetization-decorated" design

Monetization is added at the end of design as decoration ("we'll add a battle pass and some IAP"). Each addition fights the design or feels bolted-on. The model is a Frankenstein.

**Avoid by:** monetization is part of the design. The model is decided alongside the systems, not after them. Coordinate `game-systems-designer` ↔ `game-monetization-strategist` early.

## 17. Refund flood from a broken release

A buggy / broken release combined with an aggressive refund policy collapses near-term revenue. Players lose patience; reviews drop; future launches face skepticism.

**Avoid by:** quality bar before release; staged rollout; honest acknowledgment of issues; quick patch cadence; transparent comms.

## 18. The "trust break" that takes a year to recover

A misstep in monetization (silent nerf, dark pattern, regulatory miss) damages community trust. Subsequent launches face headwinds even when they're well-designed. Trust takes 12+ months to rebuild.

**Avoid by:** invest in the trust contract. Be transparent about monetization. Compensate generously when things go wrong. The studio's reputation is part of every game's UA budget.
