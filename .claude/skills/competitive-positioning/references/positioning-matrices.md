# Feature & Positioning Matrices

Two different tools, often confused. One proves parity; the other finds open ground. Build both, in order.

## 1. The feature matrix (parity check)

A table: alternatives as columns, capabilities as rows, cells marked has / partial / missing.

```
Capability          | You | Rival A | Rival B | Substitute
--------------------|-----|---------|---------|-----------
Real-time sync      |  ✓  |    ✓    |    ✓    |     ✗
SSO / SAML          |  ✗  |    ✓    |    ✓    |     ✗
Offline mode        |  ✓  |    ✗    |    ✗    |     ✗
```

What it is for: finding **table stakes you're missing** (everyone has it, you don't — a disqualifier) and **parity you can stop bragging about** (everyone has it, including you — not a differentiator). The feature matrix does **not** tell you your position. A long column of green checks is not a strategy.

Trap: the feature matrix tempts you into feature-list positioning (Universal Rule 3). Use it to clear the parity bar, then put it down.

## 2. The positioning matrix (the 2×2 that finds open ground)

A scatter on two axes. Plot every alternative; look for the **empty quadrant** where customer demand exists but no credible competitor sits.

The entire value of this tool is in **axis choice**:

- **Axes must be the dimensions customers actually decide on.** Pull them from purchase criteria and customer language (often surfaced by `ux-research`), not from your feature list. "Powerful vs simple," "for specialists vs for everyone," "self-serve vs white-glove" are real axes; "more features vs fewer" usually is not.
- **Axes must be roughly independent.** If the two axes correlate, every competitor falls on one diagonal and there is no open ground to find — pick a different second axis.
- **Open ground must be ground customers want.** An empty quadrant can be empty because nobody wants it. Validate that the gap has demand before claiming it (the "do nothing" tier and `ux-research` help here).

```
          high-touch
              │
   Rival B    │
              │        ← open quadrant:
──────────────┼──────────  self-serve + specialist
              │   (YOU?)    — is there demand here?
   Rival A    │  Substitute
              │
          self-serve
   generalist ←——→ specialist
```

## How they feed the decision

- Feature matrix → the **table-stakes list** you must reach (constraints on the position).
- Positioning matrix → **candidate open positions** (the differentiation choices).

Both hand off to [differentiation-strategy.md](differentiation-strategy.md), where you choose one position and name what you concede.
