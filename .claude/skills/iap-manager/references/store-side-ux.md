# Store-side UX

The store is a UI surface, not just a list of SKUs. The same catalog with bad UX converts dramatically worse than with good UX. Coordinate with `ux-design` for screen-level work; this reference covers IAP-specific patterns.

## Paywall placement

Where the player encounters the store determines conversion:

- **Always-on store tab** — players who *want* to spend can. Lowest pressure; lowest conversion per view.
- **Currency-low pop-up** — surfaces when the player runs out of soft currency. Mid pressure; mid conversion. Don't make this the only path (feels punitive).
- **Energy-empty pop-up** — surfaces when the player runs out of plays. Conversion-friendly but plays the "pay to continue" pattern; tune carefully.
- **Defeat / failure pop-up** — surfaces after a player loses. Converts well in some categories (puzzle, casual); feels exploitative in others (challenge, narrative). Use carefully.
- **Achievement / wow pop-up** — surfaces after a player succeeds at something. Less common; can convert well for cosmetic SKUs ("celebrate your win with this!").
- **Time-limited offer** — surfaces with a clear end time. Strong conversion when real; trust-destroying when fake.

## Offer flow shape

Standard flow:

1. **Trigger** — what surfaces the offer (in-game event, time, button click)
2. **Pre-paywall** — short context ("Need more gems?" or "New bundle available!")
3. **Offer detail** — composition + price + countdown if applicable + CTA
4. **Confirm purchase** — platform's IAP UI takes over (sandbox first; live billing second)
5. **Receipt → entitlement** — server validates; client receives confirmation
6. **Reward animation** — feedback that gives the purchase emotional weight (delivery beat)
7. **Post-purchase** — return to gameplay or surface a related offer (carefully)

Each step is a drop-off candidate. Instrument all of them.

## Dismissibility

Every paywall should be **dismissible** with a clear "no thanks" or "X" button. Forced paywalls (no exit) are App Store / Google Play policy violations and trust-destroying for the audience.

The dismiss button should be **easy to find** (corner X is fine; hidden behind a menu is hostile).

## Soft pop-ups

A *soft* pop-up offers the player something without blocking play. Examples:
- A new bundle banner on the home screen
- A "buy gems" button in the HUD
- A small "limited offer" indicator on the store tab

Soft pop-ups have lower conversion per view but vastly higher view counts and don't damage retention. Lean on these.

## Hard pop-ups

A *hard* pop-up interrupts play. Examples:
- "Currency low" modal
- "Limited-time offer!" interstitial
- Energy-out paywall

Hard pop-ups convert better per view but cost retention. Tune the *frequency*:
- Hard pop-ups during onboarding: *never* (drives bounce)
- Hard pop-ups in early game: *rarely* (max 1 per session)
- Hard pop-ups in mid-late game: *moderate* (1–2 per session)
- Hard pop-ups for whales: *minimal* (whales know where the store is; don't punish them)

## Display copy

The text on the offer matters. Rules:

- **Lead with player benefit** — "Save 50% on the Halloween Bundle!" not "Halloween Bundle: $9.99"
- **Honest discount** — "30% off" only if it's truly 30% off (the comp must be real)
- **Plain language** — "500 gems + Halloween skin + 5,000 gold" not "premium currency package mk-II"
- **Avoid pressure tactics** — "Last chance!" only if it's the genuine last chance; "Limited stock!" only if there's actual stock
- **Localize** — translated text per region

Coordinate with `game-marketer` for copy and `ux-design` for typography / hierarchy.

## Comparison and decoy display

When showing multiple SKUs side-by-side:

- **Highlight a "best value" SKU** — usually mid-tier, not the cheapest, not the most expensive
- **Place decoy SKUs adjacent** — small pack near bundle makes the bundle look better
- **Show the "save X%" delta** vs equivalent singles for bundles
- **Color and badge** the highlighted SKU consistently across the store

Decoy effects work; deceptive comparisons don't. Players notice when the comp isn't real.

## Subscription UX

Subscriptions need extra care:

- **Pre-checkout disclosure** — clearly state recurring billing, billing date, cancellation method
- **Free trial communication** — when the trial ends, when billing starts, how to cancel
- **Cancellation flow** — accessible from inside the app, not buried, not full-of-friction
- **Sub status display** — players see they're subbed, when it renews, how to manage

App Store / Google Play policies require some of this; do *more* than the minimum. Players reward studios that make subs respectful.

## Restore purchases

Critical for long-term trust:

- **Always-available restore button** in the store
- **Cross-device restore** if the platform supports it
- **Receipt re-validation** server-side; entitlements re-granted
- **Test the flow** for every SKU type (consumable, non-consumable, sub)
- **Don't gate restore behind sign-in** if the platform identifier is enough

## Web3 store UX

If the rails include web3:

- **Wallet connect prompt** — clear, branded, handles connection failures
- **Gas / fee disclosure** — before signing, the player sees the total cost
- **Transaction confirmation** — feedback during pending state (typically a few seconds; sometimes longer)
- **Failed transaction recovery** — clear error messaging; player can retry
- **Web2 fallback** — non-wallet players have a clear path

## Anti-patterns

- **Forced paywall** — no dismiss; policy violation
- **Fake countdown** — "23:59:58" timer that resets every load
- **Hidden subscription cost** — sub price displayed in tiny text or after click-through
- **Dark-pattern cancellation** — multiple confirms, "are you sure" loops, surprise re-bills
- **Buried restore-purchases** — under settings, under help, three taps deep
- **Confused currencies** — multiple soft currencies that look the same; players can't tell what costs what
- **Predatory targeting** — segment-specific offers that target whales with high-pressure copy

## Output

Coordinate with `ux-design` to specify:
- Paywall screens (always-on, low-currency, low-energy, defeat, victory, time-limited)
- Offer detail screens
- Confirm + receipt screens
- Restore-purchases flow
- Subscription management flow
- Web3 wallet connection flow (if applicable)
