#!/usr/bin/env python3
"""test_ledger.py — deterministic regression checks for ledger.py's
fingerprint normalization. Exit-nonzero evidence script per the repo's tier
doctrine (exit 0 = pass, 1 = check failed, 2 = setup error).

Motivating defect (external review of PR #134): the single-quote stripper
'[^']*' treated apostrophes in English contractions as quote delimiters, so
"doesn't … isn't" deleted everything between the two apostrophes. Claims
differing only inside that span falsely collided, and contraction-vs-no-
contraction phrasings of the same defect diverged. Reviewer prose is exactly
where contractions live.

Run: python3 .claude/skills/findings-ledger/scripts/test_ledger.py
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    from ledger import fingerprint, normalize
except ImportError as exc:
    print(f"SETUP ERROR: cannot import ledger.py ({exc})")
    sys.exit(2)

FAILURES = 0


def check(name, cond, detail=""):
    global FAILURES
    if cond:
        print(f"PASS  {name}")
    else:
        FAILURES += 1
        print(f"FAIL  {name}  {detail}")


# 1. Contractions are not quote delimiters: text between two contractions
#    must survive normalization.
n = normalize("the description doesn't mention X and isn't clear")
check("contractions preserved", "mention x" in n, f"normalized to {n!r}")

# 2. ...and therefore claims differing inside that span must NOT collide.
a = fingerprint("f.md", "the description doesn't mention X and isn't clear")
b = fingerprint("f.md", "the description doesn't mention Y and isn't clear")
check("distinct defects don't collide across contractions", a != b, f"both {a}")

# 3. Same defect with vs without contractions should still collide
#    (contraction apostrophes are dropped, not treated as delimiters).
c = fingerprint("f.md", "the description doesn't mention X")
d = fingerprint("f.md", "the description does not mention X")
check("contraction vs expanded phrasing collides", c == d, f"{c} vs {d}")

# 4. Deliberate single-quoted snippets (space-delimited) are still stripped.
e = fingerprint("f.md", "the value 'foo' is wrong")
f = fingerprint("f.md", "the value 'bar' is wrong")
check("single-quoted snippets still stripped", e == f, f"{e} vs {f}")

# 5. The original cross-phrasing collision contract: line numbers, backtick
#    snippets, and case differences collide to one fingerprint.
g = fingerprint("a/b.md", "Description at line 12 is vague: `use for stuff`")
h = fingerprint("a/b.md", "description AT LINE 99 is vague: `another snippet`")
check("line/quote/case variants collide", g == h, f"{g} vs {h}")

print()
if FAILURES:
    print(f"test_ledger.py: {FAILURES} failure(s).")
    sys.exit(1)
print("test_ledger.py: OK — all checks pass.")
sys.exit(0)
