#!/usr/bin/env python3
"""verify_claim_example.py — reference implementation of the exit-nonzero
verification pattern from the adversarial-claims-reviewer skill.

Motivating example (the failure this skill exists to catch): a paper labeled

    C[f] = d2(A f) - A(d2 f)        "the commutator"

but the formula it actually computed was a different object:

    D[f] = d2(A f) - d2 f           (smoothed-vs-raw curvature difference)

Its appendix then symbolically "verified" a neighboring TRUE statement (the
single-mode commutator vanishes) while the body asserted things about D[f].
This script proves the two quantities are different:

    CHECK 1  C[f] == 0 identically for Gaussian smoothing A_delta
             (differentiation commutes with convolution)
    CHECK 2  D[f] != 0 — the quantity the text actually wrote is NOT the
             commutator and does not vanish

Pattern rules this file demonstrates:
  - exit 0 only when every check passes, so the script composes with CI
  - exit 1 when any check fails (claim refuted as stated)
  - exit 2 on setup problems (missing dependency) — distinct from refutation
  - symbolic proof first; deterministic numeric spot-checks at fixed
    parameter values as fallback (never random points)

Run:  uv run --with sympy scripts/verify_claim_example.py
  or: pip install sympy && python3 scripts/verify_claim_example.py
"""

import sys

try:
    import sympy as sp
except ImportError:
    print("SETUP ERROR: sympy is not installed.")
    print("Run: uv run --with sympy scripts/verify_claim_example.py")
    sys.exit(2)

x, y = sp.symbols("x y", real=True)
k = sp.Symbol("k", positive=True)
delta = sp.Symbol("delta", positive=True)

# Gaussian kernel of width delta, centered at x
G = sp.exp(-((x - y) ** 2) / (2 * delta**2)) / (delta * sp.sqrt(2 * sp.pi))

# Deterministic spot-check points (x, k, delta) — fixed, not random,
# so failures are reproducible.
SPOT_POINTS = [
    (sp.Rational(7, 10), 2, sp.Rational(1, 2)),
    (sp.Rational(-3, 2), 1, sp.Rational(1, 4)),
    (sp.Rational(1, 3), 3, 1),
]


def smooth(f):
    """A_delta f — Gaussian smoothing as an explicit convolution integral."""
    return sp.integrate(f.subs(x, y) * G, (y, -sp.oo, sp.oo))


def is_zero(expr):
    """Symbolic proof when SymPy reduces the expression; otherwise deterministic
    fixed-point spot-checks. The detail string states which evidence level was
    achieved — numeric passes are evidence at the tested points, not a proof of
    identical vanishing. Callers (and the final summary) must not claim more
    than the detail string supports."""
    simplified = sp.simplify(expr)
    if simplified == 0:
        return True, "symbolic: simplifies to 0"
    for px, pk, pd in SPOT_POINTS:
        try:
            val = complex(sp.N(simplified.subs({x: px, k: pk, delta: pd}), 30))
        except (TypeError, ValueError) as exc:
            # An evaluation failure is a setup problem, not a refutation —
            # honor the exit-code contract (2, not 1).
            print(f"SETUP ERROR: could not evaluate at (x,k,delta)=({px},{pk},{pd}): {exc}")
            sys.exit(2)
        if abs(val) > 1e-20:
            return False, f"nonzero at (x,k,delta)=({px},{pk},{pd}): {val}"
    return True, f"numeric: zero at all {len(SPOT_POINTS)} fixed spot points"


failures = 0


def check(label, ok, detail):
    global failures
    print(f"{'PASS' if ok else 'FAIL'}  {label} — {detail}")
    if not ok:
        failures += 1


# CHECK 1 — the commutator as named vanishes identically.
# Two test functions on purpose: a single Fourier mode AND a non-mode bump,
# because "true for one mode" is exactly the neighboring statement the
# original paper hid behind.
for name, f in [("sin(k*x)", sp.sin(k * x)), ("exp(-x**2/2)", sp.exp(-(x**2) / 2))]:
    commutator = sp.diff(smooth(f), x, 2) - smooth(sp.diff(f, x, 2))
    ok, detail = is_zero(commutator)
    check(f"C[f] = d2(Af) - A(d2 f) == 0 for f = {name}", ok, detail)

# CHECK 2 — the formula the paper actually wrote is a DIFFERENT quantity:
# it must NOT vanish, or the conflation would be harmless.
f = sp.sin(k * x)
written_formula = sp.simplify(sp.diff(smooth(f), x, 2) - sp.diff(f, x, 2))
ok_zero, _ = is_zero(written_formula)
try:
    sample = float(
        sp.N(written_formula.subs({x: sp.Rational(7, 10), k: 2, delta: sp.Rational(1, 2)}), 30)
    )
except (TypeError, ValueError) as exc:
    # Same contract as is_zero: an evaluation failure is a setup
    # problem (exit 2), never a refutation (exit 1).
    print(f"SETUP ERROR: could not evaluate D at the sample point: {exc}")
    sys.exit(2)
check(
    "D[f] = d2(Af) - d2 f != 0 for f = sin(k*x)",
    not ok_zero,
    f"at (x,k,delta)=(7/10,2,1/2): D = {sample:.6f} (expected (e**(-d**2k**2/2)-1)*(-k**2 sin(kx)) != 0)",
)

print()
if failures:
    print(f"REFUTED: {failures} check(s) failed — the claim does not hold as stated.")
    sys.exit(1)
print(
    "VERIFIED: d2(A f) - A(d2 f) vanishes on every check (symbolic where SymPy "
    "reduces, fixed-point numeric otherwise — see per-check evidence lines), "
    "while d2(A f) - d2 f != 0. The two quantities the paper conflated are "
    "different objects."
)
sys.exit(0)
