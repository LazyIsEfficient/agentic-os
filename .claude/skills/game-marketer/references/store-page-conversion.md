# Store-page conversion

The store page is where most marketing impressions terminate. A good page converts 25–45% of visitors to install / wishlist; a bad one converts 5–15%. Same traffic, dramatically different revenue.

## What converts

In rough order of impact:

1. **Icon** — App Store / Google Play; thumbnails in lists are 60×60. The icon must read at that size and signal the genre / fantasy.
2. **Screenshot 1** — first thing the visitor sees after the icon. Should land the fantasy + verb in one image.
3. **Trailer / video** — autoplay preview on iOS; hero video on Steam. The first 5 seconds carry most of the impact.
4. **Tagline / subtitle** — "complementary text to the title" — one short line landing the wedge or the fantasy.
5. **Above-fold description** — the first ~3 lines (mobile) or first paragraph (Steam). Most visitors don't scroll.
6. **Reviews / ratings** — visible on every store; high-impact for trust signal.
7. **Wishlist / install CTA** — clear, persistent, the obvious next step.
8. **Social proof badges** — "Editor's Choice," "Featured," "Trending," critic quotes (where allowed).
9. **In-page screenshots** — 4–6 shots that build context after the hook.
10. **Footer description** — full description, feature list, tech specs.

## Per-platform anatomy

### App Store (iOS)

**Above-fold (no scroll):**
- App icon
- App name
- Subtitle (≤30 chars)
- Star rating + review count
- "Get" / price button
- Up to 3 screenshots in the carousel

**Below fold:**
- Description (first 3 lines visible; "more" expands)
- Ratings & reviews
- In-app purchases breakdown
- Information panel (size, version, age rating, languages, dev info)

**Optimization levers:**
- Custom product pages per source (test alternate icons / screenshots / tagline per ad campaign)
- Localized pages per region
- "What's New" section (recent updates message)
- Subscription disclosure (mandatory for sub apps)

### Google Play (Android)

**Above-fold:**
- App icon
- App name
- Star rating + count
- "Install" button
- Feature graphic (1024×500)
- Short description (≤80 chars)

**Below fold:**
- Screenshots
- About this app (long description)
- Ratings & reviews
- "What's new" section
- Data safety / permissions panel
- Subscription disclosure

**Optimization levers:**
- Store listing experiments (built-in A/B for icon / description / feature graphic / screenshots)
- Custom store listings per audience segment
- Localized listings

### Steam

**Above-fold:**
- Capsule image (large)
- Title
- Tagline (under title)
- "Buy" / "Add to Wishlist" button
- Tags (user-submitted, but seedable)
- Recent reviews + all-time reviews

**Below fold:**
- Screenshots / trailer carousel
- Long description (HTML/markdown supported)
- System requirements
- Release date
- Developer / publisher
- Curators

**Optimization levers:**
- Capsule image testing (Valve provides A/B metrics)
- Tagging for discovery (algorithm-driven feeds)
- Curator outreach
- Bundle pricing
- Demo / Steam Next Fest participation

### Web (Stripe / direct)

Full design control. Use the same hierarchy as platform stores:

1. Hero image / video above fold
2. Tagline + CTA
3. Social proof (reviews, press quotes)
4. Game features (3–5 illustrated)
5. Detailed description
6. Footer (purchase, FAQ, contact)

## Conversion funnel

Install funnel:

1. **Impression** — visitor sees icon / capsule somewhere
2. **Click-through** — clicks to store page
3. **Page view** — page loads
4. **Engagement** — visitor stays on page, scrolls, reads
5. **Wishlist / install** — primary conversion event
6. **Confirmation** — purchase / install completes

Track each step. Optimize the worst step first.

## Wishlist conversion (Steam-specific)

Pre-launch, wishlist count is the leading indicator. Tactics:

- **Steam Next Fest** participation (drives big wishlist spikes)
- **Demo** during a Next Fest or surrounding launch
- **"Add to Wishlist" CTA** on every external touch point
- **Email signup → wishlist add** flow on the marketing site
- **Influencer / press coverage** during major events (Summer Game Fest, Gamescom, TGS)

Wishlist-to-purchase conversion at launch typically 10–25%. A 50,000-wishlist launch translates to roughly 5,000–12,500 day-one purchases.

## Localization & internationalization

Localized store pages outperform non-localized:
- **Localized icon** (same icon usually fine; avoid culturally-specific icons in some markets)
- **Localized title** (transliterate or translate per market — JP / KR / CN / RU all benefit)
- **Localized description** by native speakers, not machine translation
- **Localized screenshots** with translated UI text
- **Localized pricing** per region (with `iap-manager`)

Best ROI markets to localize first: JP, KR, ZH-Hans, ZH-Hant, ES, BR PT, FR, DE, RU. Tier-2 markets (TR, AR, ID, VN) often pay strong returns relative to investment.

## A/B testing on store pages

- **App Store custom product pages** — test alternate icons, screenshots, taglines per source
- **Google Play store listing experiments** — built-in A/B for icon / description / screenshots / feature graphic
- **Steam page A/B** — change capsule images and watch metrics in Steamworks

Test priority:
1. Icon (5–10% conversion swings common)
2. First screenshot (3–7%)
3. Trailer / hero video (variable, often high impact)
4. Tagline / above-fold description (2–5%)

## Pre-launch tactics (Steam path)

- Create the page **6–12 months pre-launch**
- Iterate creative based on wishlist conversion data
- Steam Next Fest participation (twice per year — Feb and June typically) drives big wishlist spikes if the demo is good
- Festival participation (Steam Festival pages, themed pages) for visibility
- Curator outreach 30–60 days pre-launch

## Hand-off

- **`iap-manager`:** IAP catalog summary on store page must match real catalog
- **`game-monetization-strategist`:** ROAS / CPI floors inform store-page conversion targets
- **`growth-engine`:** A/B testing infrastructure (especially for web pages)
- **`seo-ops`:** ASO (App Store Optimization) keyword research
- **`autoresearch`:** multi-round optimization of store-page copy if high-stakes
- **`content-ops`:** expert-panel scoring of the page as a whole
- **`ux-design`:** for web direct stores; coordinate page structure
