# Balance anti-patterns

Common ways balance work fails. Most show up months after launch, when retention is decaying and the model is no longer a useful map.

## 1. Vibes balance

Numbers are picked because they "feel right" with no spreadsheet, no comp benchmarks, no sensitivity analysis. Works fine until the first content drop changes the inputs and the whole economy drifts off the (nonexistent) model.

**Fix:** model first. The model can be rough; it just has to exist.

## 2. Spreadsheet trance

Beautiful spreadsheet, plays terribly. The model proves the design is balanced; the player feels nothing. Often happens when balancer optimizes for a single metric (ARPDAU, time-to-content) without playtest.

**Fix:** every spreadsheet revision is followed by an engine playtest. The two are different sources of truth.

## 3. Tuning to the median

The model targets the median player; whales get bored, minnows quit, free players never reach payoff. Median-only tuning is how the *measured* metrics look fine and the population still bleeds.

**Fix:** every model has multiple profile rows. Every balance change is checked against all profiles.

## 4. Power creep

Each new content drop is at least as strong as the last. Old content devalues; players who took breaks fall behind; the skill ceiling becomes a power-floor.

**Fix:** sideways content (new options, not raw power), rotating buffs/nerfs, intentional resets, gating new content behind older content.

## 5. Dominant-strategy collapse

One option (build, character, deck) dominates the meta. Everyone plays it. Pick rate concentration → 60–80%. Player skill expression collapses; the game reduces to "execute the dominant strategy correctly."

**Fix:** nerf the dominant option *or* (often better) buff alternatives. Re-tune patch cadence faster than the meta can calcify.

## 6. Treadmill economy

Players grind for upgrades that only let them grind faster for the next upgrade. Loop has no terminus and no novelty. Submission aesthetic dressed up as Challenge.

**Fix:** upgrades change the *kind* of play, not just the *speed*. Add lateral options. Add capstone goals.

## 7. Whale-gated economy

Whale-tier content is locked behind hard paywalls with no aspirational free path. Free players quit (no future); whales cap (no goal beyond paying). Population collapses.

**Fix:** every paid achievement should have a free analog (slower, less convenient, but reachable). The free path is what keeps the population alive for the whales to *play with*.

## 8. Drop-rate dishonesty

Drop rates are advertised at one number and the actual table is different. Or the *advertised* rates are technically correct but the *pity* and *PRD* algorithms hidden. Players reverse-engineer this in days. Trust takes months to recover.

**Fix:** disclose. In many jurisdictions, you must. Even where you don't have to, doing so is good practice and produces better long-term outcomes than concealment.

## 9. Silent nerf

A monetized item is nerfed without comms. Players who paid for it find out via gameplay. Refund storm; community trust drop; sometimes regulator attention.

**Fix:** announce in advance. Compensate. Grandfather where possible. Don't be the studio that nerfed the thing players paid for.

## 10. Single-currency overload

The economy has one currency that does everything: power, cosmetics, repairs, time-skips. Players can't *choose* what to spend on; spending feels mandatory; sinks all compete with each other.

**Fix:** split into 1–3 currencies with clearly different roles (soft / hard / time-gated). Each currency's sinks should be coherent.

## 11. Multi-currency proliferation

The opposite: 5+ currencies, each for a different content stream. Cognitive load explodes. Players don't know which to spend on what. Designers can't reason about the economy.

**Fix:** consolidate. 1–3 currencies, period. New content streams use existing currencies.

## 12. Exit-ramp denial

The session has no good place to stop. Players who want to log off feel they're "wasting" the session. Eventually they log off mid-session, feeling bad. Return rate drops.

**Fix:** design exit ramps. End-of-day pauses, end-of-run summaries, save-and-quit prompts. Let players quit feeling good.

## 13. Boss difficulty without learning

A boss fight that's hard but provides no information about *how* to win. Players retry with no improvement; rage quits.

**Fix:** every failure should teach something. Tells, patterns, recoverable mistakes. The challenge is to *learn the boss*, not to *survive randomly*.

## 14. Token-source dominance (web3)

A "play to earn" game with strong token sources and weak token sinks. Token price collapses; new players' earnings are worthless; the player base evaporates.

**Fix:** sinks before sources. Design token sinks that are *attractive* (cosmetics, status, premium content) so the economy isn't an extraction loop. Failing that, model token velocity in the spreadsheet *seriously* and budget for re-tunes when it drifts.

## 15. NFT'd content nerfs

Critical balance change required, but the affected item is an NFT. Owners revolt; nerf reversed; meta stays broken; population leaves.

**Fix:** *don't NFT content that needs to be balanced.* Keep NFTs for cosmetic / identity / collection items, not for combat-effective items. If you must touch an NFT'd item, prefer *additions* (adding alternatives) over *subtractions* (nerfing the NFT).

## 16. Re-tune storms

Frequent small re-tunes back-to-back. Players never have time to feel a change before the next one. Trust erodes; players assume the team is panicked.

**Fix:** patch cadence discipline. 4–8 weeks between major balance changes. Hotfixes only for emergencies. Communicate the cadence.

## 17. Patch notes as data dumps

Patch notes that list 50 numerical changes with no context. Players can't tell what matters. Discord guesses; misinformation spreads.

**Fix:** lead with the why. Group changes by intent ("we're moving the meta away from X because..."). Highlight 3–5 most-impactful changes. List the rest at the bottom.

## 18. The unmeasured KPI

A balance is shipped without telemetry to validate it. Six months later, no one knows whether the change worked.

**Fix:** every balance change ships with a measurement plan. Hand it to `site-reliability-engineering` (alerts) and `growth-engine` (experiments).

## 19. Symmetric "balance" by removal

To "balance" PvP, the team removes everything that makes characters distinct. Result: every character is the same. Win rates equalize; player engagement collapses; the game has no identity.

**Fix:** asymmetric balance is the goal. Distinct identities with distinct match-up profiles, not interchangeable characters.

## 20. The forever beta

The team avoids declaring the balance "shipped" because they want flexibility. Players never feel the game is *done*; meta-game stress is constant.

**Fix:** declare the balance shipped on a date. Commit to a patch cadence after that. Players relax; team gets focus; the next balance pass has weight.
