# TAM / SAM / SOM — Definitions and Derivation

Three nested layers. Each is a *gate* applied to the one above it. The discipline is making every gate explicit, sourced, and defensible.

## Definitions

- **TAM — Total Addressable Market.** Total revenue if *every* entity with the problem bought a solution, anywhere, with no competition and no reach limits. The ceiling. Answers: *is this room worth walking into at all?*
- **SAM — Serviceable Addressable Market.** The slice of TAM you could serve given your real constraints: geography, segment, business model, channel, regulatory eligibility, language. Answers: *of the room, who can we actually sell to?*
- **SOM — Serviceable Obtainable Market.** The slice of SAM you can realistically capture in a defined window (e.g. 3 years) given competition, GTM capacity, and ramp. The number you defend in a plan. Answers: *what will we actually get?*

Relationship: **SOM ⊆ SAM ⊆ TAM.** Decisions live in SAM and SOM. TAM is context, not commitment. A model that leads with TAM and goes quiet on SOM is selling.

## Deriving each layer

### TAM — two routes, run both

- **Top-down:** start from an analyst/industry figure for the category, then strip out what is genuinely *not* your category. Fast, low-confidence, anchors the order of magnitude.
- **Bottom-up:** `number of potential buyers × annual revenue per buyer`. Forces you to define the buyer. Higher confidence. Prefer this as the number you stand behind.

If the two disagree by more than ~2–3×, you have a definition mismatch — find it before proceeding.

### SAM — apply reachability gates to TAM

Multiply TAM down by each gate that excludes buyers you cannot serve:

- **Geography** — markets you'll actually operate in.
- **Segment** — the buyer profile your product fits (size, vertical, sophistication).
- **Business-model fit** — buyers whose willingness/ability to pay matches your model and price.
- **Channel reach** — buyers reachable through channels you can actually run.
- **Eligibility** — regulatory, compliance, or platform constraints that hard-exclude buyers.

Each gate is a number with a source or a stated assumption. `SAM = TAM × g1 × g2 × …`

### SOM — apply capture gates to SAM

- **Competitive share** — what share is realistically winnable given incumbents and switching costs. This is *not* a round percentage you picked; it's built from a real GTM motion (sales capacity, conversion, ramp) or anchored to a comparable entrant's actual trajectory.
- **Time window** — capture is a ramp, not an instant. State the window (e.g. 3-year SOM).
- **Execution capacity** — your funnel can only process so many. SOM cannot exceed what your GTM can physically reach and close.

## Worked example (bottom-up)

Sizing a paid scheduling tool for independent hair salons in the US.

- **TAM:** ~210,000 US hair salons (industry source) × $600/yr willingness-to-pay (modeled from comparable SaaS tiers) = **~$126M/yr**.
- **SAM:** gate to salons with online booking already (~55%) and ≥2 staff needing multi-calendar (~60% of those): `0.55 × 0.60 = 0.33`. SAM ≈ `$126M × 0.33` = **~$42M/yr**.
- **SOM (3yr):** realistic share given two entrenched incumbents and a self-serve-only GTM ≈ 8%. SOM ≈ `$42M × 0.08` = **~$3.4M/yr ARR**.

Each line carries a source or an `ASSUMED` tag. The load-bearing assumptions here are price ($600) and winnable share (8%) — halving either roughly halves SOM, so both get sensitivity-tested.

## The "too small to pursue" test

Set a **viability floor** *before* sizing: the minimum SOM that justifies entry given your cost structure, return expectations, or opportunity cost. Then:

- **SOM ≥ floor with margin** → the market clears; proceed to product decisions (hand to technical-product-management).
- **SOM near the floor** → marginal; the decision now rests on the load-bearing assumptions. Tighten those specific inputs, not the whole model.
- **SOM < floor** → **too small. This is a finding, not a failure.** Discovering it now — before a product exists — is the cheapest possible outcome. Do not inflate assumptions to clear the bar; report the floor, the gap, and walk-away as the recommendation.

A market can fail the test three ways: too small absolutely (TAM tiny), too narrow after gates (SAM collapses), or too contested (SOM unwinnable despite large SAM). Name which one — they imply different responses.
