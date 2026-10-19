#!/usr/bin/env python3
"""test_ledger.py — deterministic regression checks for ledger.py:
fingerprint normalization, structured (scheme 2) fingerprints, the same-run
recurrence guard, legacy-entry compatibility, and export. Exit-nonzero evidence script per the repo's tier
doctrine (exit 0 = pass, 1 = check failed, 2 = setup error).

Motivating defect (external review of PR #134): the single-quote stripper
'[^']*' treated apostrophes in English contractions as quote delimiters, so
"doesn't … isn't" deleted everything between the two apostrophes. Claims
differing only inside that span falsely collided, and contraction-vs-no-
contraction phrasings of the same defect diverged. Reviewer prose is exactly
where contractions live.

Run: python3 -I .claude/skills/findings-ledger/scripts/test_ledger.py
"""

import json
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent
LEDGER_PY = SCRIPTS_DIR / "ledger.py"
sys.path.insert(0, str(SCRIPTS_DIR))

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

# 6. Worktree convergence: an `add` run from inside a linked git worktree
#    (no --ledger flag) must land in the MAIN repository's ledger, not an
#    ephemeral copy inside the worktree.
def check_worktree_convergence():
    if shutil.which("git") is None:
        print("SKIP  worktree convergence (git not available)")
        return
    with tempfile.TemporaryDirectory() as td:
        main = Path(td) / "repo"
        wt = Path(td) / "repo-wt"
        env_git = ["-c", "user.email=t@t", "-c", "user.name=t"]
        subprocess.run(["git", "init", "-q", str(main)], check=True)
        (main / ".claude").mkdir()
        subprocess.run(["git", *env_git, "-C", str(main), "commit", "-q",
                        "--allow-empty", "-m", "init"], check=True)
        subprocess.run(["git", "-C", str(main), "worktree", "add", "-q",
                        str(wt)], check=True)
        r = subprocess.run(
            [sys.executable, str(LEDGER_PY), "add", "--file", "f.md",
             "--claim", "c", "--tier", "2", "--source", "s", "--run-id", "r1"],
            cwd=wt, capture_output=True, text=True)
        main_ledger = main / ".claude" / "ledger" / "findings.jsonl"
        check("worktree add exits 0", r.returncode == 0, r.stderr.strip())
        check("worktree add lands in MAIN repo ledger",
              main_ledger.is_file() and len(main_ledger.read_text().splitlines()) == 1,
              f"main ledger: {main_ledger.is_file()}")
        check("no ledger forked inside the worktree",
              not (wt / ".claude" / "ledger").exists(),
              "worktree grew its own .claude/ledger")


# 7. Concurrent adds are serialized: N racing processes adding the same
#    fingerprint must produce N intact lines with exactly one NEW (the
#    read→decide→append section is locked; without the lock, several racers
#    read an absent fingerprint and all record NEW).
def check_concurrent_adds(n=16, k=8):
    with tempfile.TemporaryDirectory() as td:
        lp = Path(td) / "findings.jsonl"
        go = Path(td) / "go"
        # Two requirements for this test to actually discriminate locked from
        # unlocked code (a cold review caught the naive version passing
        # against the pre-fix ledger.py):
        #   1. A two-phase barrier: each racer signals a ready-file and spins
        #      on the go-file; the parent releases go only after ALL racers
        #      are ready. Touching go right after the spawn loop opens the
        #      barrier before anyone waits at it (interpreter startup is
        #      ~tens of ms) and startup skew serializes the racers.
        #   2. Import-before-barrier + direct cmd_add() calls: import AND
        #      argument-parsing cost (argparse alone is ~1ms per call, an
        #      order of magnitude wider than the read→append window) are paid
        #      before/outside the timed region, so post-barrier skew is
        #      comparable to the critical section. Every racer adds the SAME
        #      k fingerprints in the same order — for each one, racers read
        #      the ledger near-simultaneously, so unlocked code records
        #      multiple NEW with high probability. (Calling the internal
        #      cmd_add is deliberate: this check targets the critical
        #      section; CLI behavior is covered by the other checks.)
        racer = (
            "import argparse, os, sys, time\n"
            f"sys.path.insert(0, {str(SCRIPTS_DIR)!r})\n"
            "import ledger\n"
            "args = [argparse.Namespace(\n"
            f"    ledger={str(lp)!r}, file='f.md', claim='defect number %d' % j,\n"
            "    tier=2, source='s', run_id=sys.argv[1], evidence=None,\n"
            "    category=None, symbol=None,\n"
            f"    date='2026-06-11') for j in range({k})]\n"
            "open(sys.argv[2], 'w').close()\n"
            "t = time.monotonic()\n"
            f"while not os.path.exists({str(go)!r}):\n"
            "    if time.monotonic() - t > 30: sys.exit(3)\n"
            "rc = 0\n"
            "for a in args:\n"
            "    try:\n"
            "        ledger.cmd_add(a)\n"
            "    except SystemExit as e:\n"
            "        if e.code not in (0, None): rc = e.code\n"
            "sys.exit(rc)\n"
        )
        # Always release the barrier and always reap — a hung racer must FAIL
        # the test (possible lock deadlock), never hang it.
        procs = []
        ready = [Path(td) / f"ready{i}" for i in range(n)]
        try:
            for i in range(n):
                procs.append(subprocess.Popen(
                    [sys.executable, "-c", racer, f"r{i}", str(ready[i])],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
            t = time.monotonic()
            while not all(r.exists() for r in ready):
                if time.monotonic() - t > 30:
                    check("all racers reach the start barrier", False,
                          f"{sum(r.exists() for r in ready)} of {n} ready after 30s")
                    return
                time.sleep(0.005)
            go.touch()
            codes = [p.wait(timeout=60) for p in procs]
        except subprocess.TimeoutExpired:
            check("racing adds complete without deadlock", False,
                  "a racer did not finish within 60s")
            return
        finally:
            go.touch()
            for p in procs:
                if p.poll() is None:
                    p.kill()
                    p.wait()
        check("all racing adds exit 0", all(c == 0 for c in codes), f"{codes}")
        lines = lp.read_text().splitlines()
        try:
            events = [json.loads(l) for l in lines if l.strip()]
        except json.JSONDecodeError as exc:
            check("ledger lines intact after race", False, str(exc))
            return
        check("ledger lines intact after race", len(events) == n * k,
              f"{len(events)} of {n * k} lines")
        news = {}
        for e in events:
            if e["status"] == "NEW":
                news[e["fingerprint"]] = news.get(e["fingerprint"], 0) + 1
        bad = {fp: c for fp, c in news.items() if c != 1}
        check("exactly one NEW per fingerprint among racing adds",
              len(news) == k and not bad,
              f"fingerprints with NEW≠1: {bad or 'none'}; distinct: {len(news)} of {k}")


def run_cli(ledger_path, *argv):
    return subprocess.run(
        [sys.executable, "-I", str(LEDGER_PY), "--ledger", str(ledger_path), *argv],
        capture_output=True, text=True)


def add(ledger_path, *, file, claim, run_id, date="2026-10-01", extra=()):
    return run_cli(ledger_path, "add", "--file", file, "--claim", claim,
                   "--tier", "2", "--source", "code-reviewer",
                   "--run-id", run_id, "--date", date, *extra)


def events_of(ledger_path):
    return [json.loads(l) for l in ledger_path.read_text().splitlines() if l.strip()]


# 8. Structured fingerprints (#279): paraphrases with the same category, file
#    and symbol collide; claim wording is not part of the identity.
def check_structured_fingerprints():
    with tempfile.TemporaryDirectory() as td:
        lp = Path(td) / "findings.jsonl"
        r1 = add(lp, file="src/auth.py", run_id="r1",
                 claim="check_token returns True when the verifier throws",
                 extra=("--category", "fail-open", "--symbol", "check_token"))
        r2 = add(lp, file="./src/auth.py", run_id="r2",
                 claim="Exceptions in token verification are swallowed and access is granted",
                 extra=("--category", "Fail-Open", "--symbol", "`check_token()`"))
        r3 = add(lp, file="src/auth.py", run_id="r3", claim="anything",
                 extra=("--category", "fail-open", "--symbol", "check_session"))
        check("structured adds exit 0",
              (r1.returncode, r2.returncode, r3.returncode) == (0, 0, 0),
              r1.stderr + r2.stderr + r3.stderr)
        ev = events_of(lp)
        check("paraphrased findings, same category/file/symbol -> same fingerprint",
              ev[0]["fingerprint"] == ev[1]["fingerprint"],
              f"{ev[0]['fingerprint']} vs {ev[1]['fingerprint']}")
        check("text fingerprints of those paraphrases would NOT have matched",
              fingerprint("src/auth.py", ev[0]["claim"]) != fingerprint("src/auth.py", ev[1]["claim"]))
        check("different symbol -> different fingerprint",
              ev[2]["fingerprint"] != ev[0]["fingerprint"])
        check("structured events record scheme 2 and the normalized category",
              all(e["fingerprint_scheme"] == 2 and e["category"] == "fail-open" for e in ev),
              f"{[(e['fingerprint_scheme'], e['category']) for e in ev]}")
        check("cross-run paraphrase labelled RECURRING", ev[1]["status"] == "RECURRING",
              ev[1]["status"])
        bad = add(lp, file="f.md", claim="c", run_id="r9",
                  extra=("--category", "not a slug"))
        check("non-kebab category is a usage error (exit 2)", bad.returncode == 2,
              f"rc={bad.returncode}")
        orphan = add(lp, file="f.md", claim="c", run_id="r9", extra=("--symbol", "x"))
        check("--symbol without --category is a usage error (exit 2)",
              orphan.returncode == 2, f"rc={orphan.returncode}")
        check("rejected adds append nothing", len(events_of(lp)) == 3,
              f"{len(events_of(lp))} events")


# 9. Same-run guard: repeats within one run-id are not recurrence (count,
#    label, or triage); a second run-id is.
def check_same_run_guard():
    with tempfile.TemporaryDirectory() as td:
        lp = Path(td) / "findings.jsonl"
        cat = ("--category", "stale-doc", "--symbol", "## Install")
        add(lp, file="README.md", claim="install steps are stale", run_id="pr-1", extra=cat)
        add(lp, file="README.md", claim="install section out of date", run_id="pr-1", extra=cat)
        ev = events_of(lp)
        check("same-run repeat shares the fingerprint",
              ev[0]["fingerprint"] == ev[1]["fingerprint"])
        check("same-run repeat is not labelled RECURRING",
              [e["status"] for e in ev] == ["NEW", "NEW"], f"{[e['status'] for e in ev]}")
        tri = run_cli(lp, "triage", "--today", "2026-10-02")
        check("same-run repeat is not a promotion candidate",
              "PROMOTION CANDIDATES (recurrence >= 2):\n  none" in tri.stdout, tri.stdout)
        add(lp, file="README.md", claim="README install docs are wrong", run_id="pr-2", extra=cat)
        check("second run-id labelled RECURRING", events_of(lp)[-1]["status"] == "RECURRING")
        tri = run_cli(lp, "triage", "--today", "2026-10-02")
        check("recurrence across run-ids makes a promotion candidate",
              f"{ev[0]['fingerprint']}  n=2" in tri.stdout, tri.stdout)


# 10. Legacy entries (written before #279: no fingerprint_scheme/category/
#     symbol keys) still load, keep their identity, and re-sight via text.
LEGACY_FP = "fe3358a714875cb7"  # fingerprint("docs/guide.md", "The install section is stale") pre-#279


def check_legacy_entries():
    check("scheme 1 text fingerprint is byte-stable",
          fingerprint("docs/guide.md", "The install section is stale") == LEGACY_FP,
          fingerprint("docs/guide.md", "The install section is stale"))
    with tempfile.TemporaryDirectory() as td:
        lp = Path(td) / "findings.jsonl"
        legacy = {"fingerprint": LEGACY_FP, "file": "docs/guide.md",
                  "claim": "The install section is stale", "tier": 2,
                  "source": "library-reviewer", "run_id": "old-1",
                  "date": "2026-06-01", "evidence": None, "status": "NEW"}
        lp.write_text(json.dumps(legacy, sort_keys=True) + "\n")
        t = run_cli(lp, "tally")
        check("legacy ledger loads in tally", t.returncode == 0 and LEGACY_FP in t.stdout,
              t.stderr.strip() or t.stdout)
        r = add(lp, file="docs/guide.md", claim="the install section is STALE", run_id="new-1")
        check("text-scheme add re-sights the legacy fingerprint",
              r.returncode == 0 and r.stdout.startswith(f"RECURRING {LEGACY_FP}"), r.stdout)
        p = run_cli(lp, "promote", LEGACY_FP, "--status", "INVESTIGATING")
        last = events_of(lp)[-1]
        check("transition on a legacy fingerprint defaults to scheme 1",
              p.returncode == 0 and last["fingerprint_scheme"] == 1 and last["category"] is None,
              p.stderr.strip() or str(last))


# 11. export: one line per fingerprint, structured fields only, no claim text,
#     deterministic, and never overwrites the ledger.
def check_export():
    with tempfile.TemporaryDirectory() as td:
        lp = Path(td) / "findings.jsonl"
        secret = "token verification swallows exceptions"
        cat = ("--category", "fail-open", "--symbol", "check_token")
        add(lp, file="src/auth.py", claim=secret, run_id="r1", date="2026-10-01", extra=cat)
        add(lp, file="src/auth.py", claim="paraphrase", run_id="r1", date="2026-10-02", extra=cat)
        add(lp, file="src/auth.py", claim="another paraphrase", run_id="r2", date="2026-10-05", extra=cat)
        add(lp, file="docs/a.md", claim="vague description", run_id="r2", date="2026-10-03")
        out = Path(td) / "shared" / "fingerprints.jsonl"
        x = run_cli(lp, "export", "--out", str(out))
        check("export exits 0", x.returncode == 0, x.stderr.strip())
        text = out.read_text()
        rows = [json.loads(l) for l in text.splitlines()]
        check("export dedupes to one row per fingerprint", len(rows) == 2, f"{len(rows)} rows")
        check("export rows sorted by fingerprint",
              [r["fingerprint"] for r in rows] == sorted(r["fingerprint"] for r in rows))
        expected_keys = {"fingerprint", "fingerprint_scheme", "category", "symbol", "file",
                         "count", "status", "first_seen", "last_seen"}
        check("export rows carry exactly the summary fields",
              all(set(r) == expected_keys for r in rows), f"{[sorted(r) for r in rows]}")
        check("export contains no claim text",
              secret not in text and "paraphrase" not in text and "vague" not in text)
        s = next(r for r in rows if r["category"] == "fail-open")
        check("export count = distinct runs, first/last seen span sightings",
              (s["count"], s["first_seen"], s["last_seen"], s["fingerprint_scheme"])
              == (2, "2026-10-01", "2026-10-05", 2), str(s))
        run_cli(lp, "export", "--out", str(out))
        check("export is byte-deterministic", out.read_text() == text)
        before = lp.read_text()
        clobber = run_cli(lp, "export", "--out", str(lp))
        check("export refuses to overwrite the ledger",
              clobber.returncode == 2 and lp.read_text() == before, f"rc={clobber.returncode}")


check_worktree_convergence()
check_concurrent_adds()
check_structured_fingerprints()
check_same_run_guard()
check_legacy_entries()
check_export()

print()
if FAILURES:
    print(f"test_ledger.py: {FAILURES} failure(s).")
    sys.exit(1)
print("test_ledger.py: OK — all checks pass.")
sys.exit(0)
