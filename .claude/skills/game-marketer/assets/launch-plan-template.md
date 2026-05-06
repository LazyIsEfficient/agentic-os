# Launch plan — <game title>

> One per major launch (global launch / major content drop / season opening / web3 mint event).

## Launch identity
- **Launch type:** <global launch / major content drop / season N / mint event>
- **Launch date:** <>
- **Soft launch ended on:** <if applicable>
- **Platforms going live:** <App Store / Google Play / Steam / Epic / web>

## Pre-launch timeline

### T-30 days
- [ ] Final store-page assets locked (icon, screenshots, description, trailer)
- [ ] Press kit updated and distributed to journalists (with embargoed previews)
- [ ] Influencer / creator outreach: send keys, brief on launch timing
- [ ] Wishlist push (Steam): email campaign, social posts, paid Steam page traffic
- [ ] Soft launch data → global UA plan (with `game-monetization-strategist`)
- [ ] App review submission with buffer (Apple / Google / Steam review timelines)
- [ ] Final localizations reviewed by native speakers
- [ ] Customer support documentation ready (with internal team)

### T-14 days
- [ ] Launch trailer published on YouTube; teased on social
- [ ] Press embargo lifts (or staged: outlets receive game + launch date before lift)
- [ ] Influencer videos scheduled for launch week
- [ ] Discord pre-launch event ("launch hype week", giveaways, AMA)
- [ ] Email campaign to mailing list / wishlist holders
- [ ] Launch creative finalized and approved across networks
- [ ] Support team trained on launch issues / FAQs

### T-7 days
- [ ] All store pages verified live in all regions
- [ ] Final IAP catalog verified (with `iap-manager`)
- [ ] Server / backend stress test (with `godot-engineer` and `site-reliability-engineering`)
- [ ] Launch-day comms drafted (patch notes, social posts, Discord announcements)
- [ ] Influencer launch posts scheduled for T-0 day
- [ ] Press review embargoes lift (typically T-7 or T-3)
- [ ] Final team sync on launch-day playbook

### T-1 day
- [ ] Final QA pass on production build
- [ ] Final IAP catalog test (sandbox + closed track)
- [ ] Launch creative live across networks
- [ ] Last-minute social tease ("tomorrow")
- [ ] Studio team briefed on launch-day response plan

## Launch day (T-0)

### Hour 0 (release time)
- [ ] Release goes live on all platforms (timed; check timezone — usually 10am PT for global)
- [ ] Launch trailer pinned on YouTube
- [ ] Social posts go live (X / TikTok / Instagram / Discord / Reddit)
- [ ] Email blast to wishlist
- [ ] Influencer videos go live (coordinate with creators)
- [ ] Discord launch event begins
- [ ] Press review embargoes lift (if T-0)
- [ ] Studio team monitoring crashes, server load, support tickets

### Hours 1–4
- [ ] Crash-rate monitoring (alert at >0.5% drop in crash-free)
- [ ] Server-load monitoring
- [ ] Conversion-funnel monitoring (with `iap-manager`)
- [ ] Review-score monitoring (App Store, Google Play, Steam)
- [ ] Community monitoring (Discord, Reddit, X mentions)
- [ ] Support ticket triage

### Hours 4–24
- [ ] Hotfix capability ready if needed (with `godot-engineer`)
- [ ] First-day numbers report (DAU, installs, conversions, ARPDAU vs predicted)
- [ ] Influencer reaction monitoring
- [ ] Press review monitoring
- [ ] Launch-day Discord moderation

## Launch week (T+1 to T+7)

- [ ] Daily metrics review against KPI floors (with `game-monetization-strategist`)
- [ ] Daily Discord engagement (devs in channel, AMA, community sharing)
- [ ] Daily creative refresh on UA channels (a creative can decay fast at launch)
- [ ] Press / influencer follow-up coverage push
- [ ] First patch (bug-fix) shipped within ~3–7 days if needed
- [ ] First content drop teased (next event / patch / seasonal)
- [ ] Refund / support / review monitoring

## Post-launch beat (T+7 onwards)

- [ ] Weekly metrics review
- [ ] First major content event (typically T+14 to T+30 — "we shipped, here's more")
- [ ] Re-engagement campaign for D7 lapsers
- [ ] Player survey for qualitative feedback
- [ ] Roadmap teaser (next season / next major content)
- [ ] Live-ops cadence locks in (with `game-monetization-strategist`)

## KPI gates

| KPI | Floor | Target | Strong | At launch |
|---|---|---|---|---|
| D1 retention | <floor> | <target> | <strong> | <fill> |
| D7 retention | | | | |
| Conversion to first IAP | | | | |
| ARPDAU | | | | |
| ROAS at D30 | | | | |
| Crash-free sessions | 99.0% | 99.5% | 99.8% | |
| Review score | 3.8 | 4.2 | 4.5 | |

## Risk register
- **Server overload at launch hour** — mitigation: stress test + autoscaling + dark-launch capacity
- **Crash rate spike** — mitigation: hotfix capability + escalation plan
- **Review-bombing** (web3-related, monetization-related, balance-related) — mitigation: comms plan + community presence
- **Press review crashing servers / overloading** — mitigation: dedicated review build, throttled access
- **Competitor launch overlap** — mitigation: scheduling buffer or differentiation push

## Hand-off
- **`game-monetization-strategist`:** post-launch KPI dashboard; first-week read; second-week decisions
- **`iap-manager`:** post-launch catalog adjustments based on live data
- **`game-balancer`:** post-launch balance read; first emergency re-tune if needed
- **`game-systems-designer`:** any system issue surfacing → re-route here
- **`godot-engineer`:** hotfix queue, support engineering, scaling
- **`site-reliability-engineering`:** SLI / alerting / on-call coverage
- **`security-engineering`:** monitor for fraud / abuse spikes, especially in IAP flows
