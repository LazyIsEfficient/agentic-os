# Store page — <game title> / <platform>

> One per platform (App Store / Google Play / Steam / web). Surfaces and conversion patterns differ; don't copy-paste between platforms.

## Platform
<App Store / Google Play / Steam / Epic / web direct>

## Identity
- **Game title (display):** <as it appears on the storefront>
- **Subtitle / tagline:** <App Store: 30 chars max, separate field; Steam: in description; Google: in short description>
- **Developer / studio name:** <>
- **Genre / category:** <platform's category — Action / Strategy / Casual / etc.>
- **Age rating:** <ESRB / PEGI / IARC — and any region-specific rating>
- **Languages supported:** <>

## Icon / capsule

| Asset | Spec | Status |
|---|---|---|
| App icon (iOS) | 1024×1024 | ☐ |
| Adaptive icon (Android) | 432×432 + 432×432 background | ☐ |
| Steam capsule (small) | 462×174 | ☐ |
| Steam capsule (main) | 616×353 | ☐ |
| Steam library hero | 3840×1240 | ☐ |
| Web hero | <per design> | ☐ |

**Icon design notes:** the icon must read at thumbnail size; players scroll past in lists at 60×60. Test at thumbnail size before approving.

## Headlines / tagline

- **Primary tagline:** <one line — the *fantasy* in the player's words>
- **Subtitle (App Store):** <≤30 chars; complementary to title>
- **Short description (Google Play, ≤80 chars):** <>
- **Steam tagline (under the title):** <one short line>

## Long description (Steam / web; first ~3 sentences appear above fold on App Store / Google Play)

```
[Hook — one sentence that lands the fantasy and the wedge.]

[Three sentences that explain what the player does, with verbs, with comp signals.]

[A short feature list — but framed as player-experiences, not features.]

[Closing — what makes this game different, an invitation.]
```

> Above-the-fold lines are the most important. Apple / Google truncate to ~3 lines; Steam scrolls.

## Screenshots / video

| Order | Asset | Purpose | iOS Spec | Android Spec | Steam Spec | Status |
|---|---|---|---|---|---|---|
| 1 | Hook screenshot | Land the fantasy | 6.5"/6.7" + iPad | feature graphic + screenshots | 1920×1080 | ☐ |
| 2 | Core verb in action | Show the game | | | | ☐ |
| 3 | Variety / depth | Different content | | | | ☐ |
| 4 | UI / progression | Show the meta | | | | ☐ |
| 5 | Cosmetic / late-game | Aspirational | | | | ☐ |
| Trailer | Hero gameplay video | Engagement | 30s + 15s edits | 30s | 90s + 30s edits | ☐ |

**Order matters.** Screenshots 1–2 do most of the work; players rarely look past 3 in mobile stores.

## Tags / keywords (ASO)

- **App Store keywords field (100 chars total):** <comma-separated; no spaces>
- **Google Play tags:** <auto-extracted from description; coordinate with title / description for ranking>
- **Steam tags (10–20):** <user-submitted but seedable>

Coordinate with `seo-ops` for ASO research.

## Localizations

| Region / language | Title | Subtitle | Description | Screenshots | Status |
|---|---|---|---|---|---|
| US English | <> | <> | <> | <localized text on screenshots> | ☐ |
| EU FR | <> | <> | <> | | ☐ |
| EU DE | <> | <> | <> | | ☐ |
| JP | <> | <> | <> | | ☐ |
| KR | <> | <> | <> | | ☐ |
| ZH-Hans (CN simplified) | <> | <> | <> | | ☐ |
| ZH-Hant (TW traditional) | <> | <> | <> | | ☐ |
| ES (LATAM + EU separately) | <> | <> | <> | | ☐ |
| BR PT | <> | <> | <> | | ☐ |
| RU | <> | <> | <> | | ☐ |
| TR | <> | <> | <> | | ☐ |

> Don't translate; *localize*. Cultural hooks differ. Coordinate with native speakers.

## A/B testing plan

- **App Store custom product pages** — test alternate icons, screenshots, taglines per source
- **Google Play store listing experiments** — built-in A/B for icon / description / screenshots
- **Steam page A/B** — test capsule images via Valve's metrics
- **Web** — full A/B framework

Top tests to run:

1. **Icon** — usually highest-leverage; 5–10% conversion swings common
2. **Screenshot 1** — second highest; first impression of gameplay
3. **Tagline / subtitle** — moderate impact
4. **Description first 3 lines** — moderate impact

## Performance gates

- **Conversion rate (impression → install)** target: see `game-monetization-strategist` KPI floors
- **Page-view-to-install rate** by source: paid traffic vs organic differ; track separately
- **Wishlist conversion** (Steam): % of viewers who wishlist
- **Wishlist-to-purchase** (Steam launch): typical 10–25%

## Related comms

- **Press kit** — high-res assets, fact sheet, dev quotes (link from store page on web)
- **Trailer page** — separate landing page (web) with embedded trailer
- **Press outreach** with `game-marketer` and outbound to specialist outlets

## Status

- [ ] Icon designed and tested at thumbnail size
- [ ] Screenshots designed in order with localized text
- [ ] Trailer ≤30s primary + 15s variant
- [ ] All copy proofread
- [ ] All localizations reviewed by native speakers
- [ ] ASO keywords researched (with `seo-ops`)
- [ ] A/B test plan in place (with `growth-engine`)
- [ ] Submitted for app review (with timeline buffer)
