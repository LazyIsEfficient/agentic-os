#!/usr/bin/env python3
"""ledger.py — append-only JSONL ledger for stochastic (Tier 2) review findings.

Part of the findings-ledger skill. Tier doctrine lives in
.claude/rules/review-tiers.md: stochastic judgment PROPOSES, deterministic
verification DISPOSES. This ledger is where Tier 2 proposals accumulate so
recurrence can be measured instead of re-argued.

Stdlib only — no third-party dependencies.

Subcommands:
  add      append a finding (computes the fingerprint; first sighting = NEW,
           sighting from a DIFFERENT run = RECURRING, a repeat within the same
           run stays NEW; tier 1 without --evidence demotes to 2)
  tally    group events by fingerprint; report recurrence counts. Recurrence =
           number of DISTINCT run ids among sightings (review-tiers.md counts
           independent runs; an agent repeating itself within one run is one)
  triage   list promotion candidates (recurrence >= --threshold, default 2)
           and retire-as-noise candidates (single recurrence, still NEW,
           older than --age-days, default 14)
  promote  append a status-transition event (INVESTIGATING or PROMOTED;
           PROMOTED requires --evidence: the encoded check)
  retire   append a RETIRED-NOISE status-transition event
  export   write a deduplicated per-fingerprint summary (no claim text) to a
           path — the committable artifact for team-shared recurrence

The ledger is append-only: status transitions are NEW EVENTS for the same
fingerprint, never mutations of prior lines. A fingerprint's current status is
the status of its most recent event.

Fingerprinting has two schemes, recorded per event as `fingerprint_scheme`:
  2 (structured) — when `add --category` is given: sha256 over the normalized
    file path + category slug + symbol (or empty). Claim wording is ignored,
    so paraphrases of the same defect collide.
  1 (text, legacy) — otherwise: sha256(file path + "\\n" + normalized claim
    text). Normalization lowercases, strips quoted/backticked snippets,
    strips line/column references, and collapses whitespace. A heuristic,
    not identity. Events without the field are scheme 1.
Both truncate to 16 hex chars. See the skill's references/ledger-format.md.

Exit codes: 0 = ok, 2 = setup/usage error (matches argparse's own usage exit).
Output ordering is deterministic so run-over-run diffs are stable.
"""

import argparse
import datetime as _dt
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from contextlib import contextmanager
from pathlib import Path

# Advisory file locking, cross-platform within the stdlib: non-blocking
# attempts polled under a single deadline in locked(), so a wedged lock
# holder (stopped process, stale NFS handle) produces a diagnostic exit 2 on
# every platform instead of hanging POSIX writers forever.
try:
    import fcntl

    def _try_lock(fh):
        try:
            fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return True
        except OSError:
            return False

    def _unlock(fh):
        fcntl.flock(fh, fcntl.LOCK_UN)
except ImportError:  # Windows
    import msvcrt

    def _try_lock(fh):
        fh.seek(0)
        try:
            msvcrt.locking(fh.fileno(), msvcrt.LK_NBLCK, 1)
            return True
        except OSError:
            return False

    def _unlock(fh):
        fh.seek(0)
        msvcrt.locking(fh.fileno(), msvcrt.LK_UNLCK, 1)

STATUSES = ("NEW", "RECURRING", "INVESTIGATING", "PROMOTED", "RETIRED-NOISE")
OCCURRENCE_STATUSES = ("NEW", "RECURRING")  # events that count as a sighting
REQUIRED_KEYS = ("fingerprint", "file", "claim", "tier", "source", "run_id",
                 "date", "evidence", "status")
FINGERPRINT_LEN = 16
SCHEME_TEXT = 1
SCHEME_STRUCTURED = 2
CATEGORY_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
LOCK_TIMEOUT_S = 20  # writers hold the lock for milliseconds; 20s means wedged


def die(msg):
    print(f"SETUP ERROR: {msg}", file=sys.stderr)
    sys.exit(2)


def normalize(claim):
    """Normalize claim text for fingerprinting (heuristic, not identity)."""
    t = claim.lower()
    # quoted snippets vary per run (exact code excerpts, messages) — strip them.
    # Single quotes only count as delimiters when not embedded in a word:
    # apostrophes in contractions/possessives ("doesn't", "user's") would
    # otherwise pair up and delete the prose between them (caught by external
    # review of PR #134; regression-tested in test_ledger.py).
    t = re.sub(r"`[^`]*`", " ", t)
    t = re.sub(r'"[^"]*"', " ", t)
    t = re.sub(r"(?<!\w)'[^']*'(?!\w)", " ", t)
    # contractions: fold "n't" to " not" so contracted and expanded phrasings
    # of the same defect collide; drop any remaining in-word apostrophes
    t = re.sub(r"n't\b", " not", t)
    t = t.replace("'", "")
    # line/column references: "line 12", "lines 3-5", "col 7", "L12", ":12:3"
    t = re.sub(r"\b(?:line|ln|col|column)s?\s*[#:]?\s*\d+(?:\s*[-,]\s*\d+)*", " ", t)
    t = re.sub(r"\bl\d+\b", " ", t)
    t = re.sub(r":\d+(?::\d+)?\b", " ", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def fingerprint(file, claim):
    """Scheme 1 (text). Must stay byte-for-byte stable: legacy entries keep
    their identity only as long as this function does not change."""
    payload = file.strip() + "\n" + normalize(claim)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:FINGERPRINT_LEN]


def normalize_path(file):
    """`./a\\b.md`, `a//b.md` and `a/b.md` are the same file."""
    t = file.strip().replace("\\", "/")
    t = re.sub(r"/+", "/", t)
    while t.startswith("./"):
        t = t[2:]
    return t


def normalize_category(category):
    """Lowercased kebab-case slug, or None if it isn't one."""
    t = category.strip().lower()
    return t if CATEGORY_RE.match(t) else None


def normalize_symbol(symbol):
    """Reviewers write `foo`, foo() and foo for the same function."""
    if symbol is None:
        return ""
    t = symbol.strip().strip("`").strip()
    if t.endswith("()"):
        t = t[:-2]
    return re.sub(r"\s+", " ", t)


def structured_fingerprint(file, category, symbol=None):
    """Scheme 2. The "v2" tag and newline count keep its payloads distinct
    from scheme 1's (normalize() collapses newlines out of the claim)."""
    payload = "\n".join(
        ("v2", normalize_path(file), category, normalize_symbol(symbol)))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:FINGERPRINT_LEN]


def default_ledger_path():
    """Resolve the ledger at the MAIN repository, even from a linked worktree.

    `git rev-parse --git-common-dir` returns the main repo's .git directory
    from any worktree, so every worktree converges on ONE ledger instead of
    appending to an ephemeral copy that vanishes with the worktree. Outside a
    git repo (or when the main repo has no .claude/), fall back to the nearest
    ancestor of CWD containing .claude/.
    """
    try:
        # Scrub git env overrides: a hook-exported GIT_DIR would silently
        # resolve ANOTHER repo's ledger. Timeout guards against a hung git
        # (fsmonitor, network filesystems) hanging the CLI.
        env = {k: v for k, v in os.environ.items()
               if k not in ("GIT_DIR", "GIT_WORK_TREE", "GIT_COMMON_DIR")}
        out = subprocess.run(
            ["git", "rev-parse", "--git-common-dir"],
            capture_output=True, text=True, check=True, env=env, timeout=10,
        ).stdout.strip()
        if out:
            common = Path(out)
            if not common.is_absolute():
                common = Path.cwd() / common
            root = common.resolve().parent
            # With `git init --separate-git-dir`, common-dir's parent is NOT
            # the repo root; the .claude check fails and we degrade to the
            # directory walk below — acceptable for that exotic layout.
            if (root / ".claude").is_dir():
                return root / ".claude" / "ledger" / "findings.jsonl"
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        pass  # no git, not a repo, or git hung — fall through to the directory walk
    for d in [Path.cwd()] + list(Path.cwd().parents):
        if (d / ".claude").is_dir():
            return d / ".claude" / "ledger" / "findings.jsonl"
    return None


@contextmanager
def locked(path):
    """Exclusive lock for the read -> decide-status -> append critical section.

    Without it, two concurrent `add`s of the same new fingerprint both read an
    absent fingerprint and both record NEW (a cosmetic mislabel — recurrence
    counts distinct run ids — but a race nonetheless). Locks a sidecar
    `<ledger>.lock` file rather than the ledger itself so the lock exists
    before the first event does and never blocks read-only tooling. Worktree
    convergence (see default_ledger_path) means all writers lock the same
    inode. In team-shared mode, keep `.claude/ledger/*.lock` gitignored.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    lock_path = path.with_name(path.name + ".lock")
    with lock_path.open("a+") as fh:
        deadline = time.monotonic() + LOCK_TIMEOUT_S
        while not _try_lock(fh):
            if time.monotonic() >= deadline:
                die(f"could not acquire ledger lock {lock_path} within {LOCK_TIMEOUT_S}s")
            time.sleep(0.05)
        try:
            yield
        finally:
            _unlock(fh)


def resolve_ledger(args, must_exist):
    path = Path(args.ledger) if args.ledger else default_ledger_path()
    if path is None:
        die("no .claude/ directory found above the working directory; pass --ledger PATH")
    if must_exist and not path.is_file():
        die(f"ledger not found: {path} (nothing recorded yet?)")
    return path


def read_events(path):
    events = []
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError as exc:
            die(f"{path}:{n} is not valid JSON ({exc})")
        if e.get("status") not in STATUSES:
            die(f"{path}:{n} has invalid status {e.get('status')!r}")
        missing = [k for k in REQUIRED_KEYS if k not in e]
        if missing:
            die(f"{path}:{n} missing key(s): {', '.join(missing)}")
        events.append(e)
    return events


def append_event(path, event):
    path.parent.mkdir(parents=True, exist_ok=True)
    # If a hand edit left the file without a trailing newline, appending raw
    # would glue two objects onto one line and poison every later read.
    prefix = ""
    if path.is_file() and path.stat().st_size > 0:
        with path.open("rb") as fh:
            fh.seek(-1, 2)
            if fh.read(1) != b"\n":
                prefix = "\n"
    with path.open("a", encoding="utf-8") as fh:
        fh.write(prefix + json.dumps(event, sort_keys=True, ensure_ascii=False) + "\n")


def parse_date(s):
    try:
        return _dt.date.fromisoformat(s)
    except ValueError:
        die(f"invalid date {s!r} (want YYYY-MM-DD)")


def group(events):
    """fingerprint -> list of events, in file order (chronological by append)."""
    by_fp = {}
    for e in events:
        by_fp.setdefault(e["fingerprint"], []).append(e)
    return by_fp


def summarize(fp, evs):
    first = evs[0]
    sightings = [e for e in evs if e["status"] in OCCURRENCE_STATUSES]
    # Recurrence counts INDEPENDENT runs (review-tiers.md), not raw sightings:
    # an agent repeating itself within one run must not cross the ratchet
    # threshold on its own.
    count = len({e["run_id"] for e in sightings})
    status = evs[-1]["status"]
    tier = sightings[-1]["tier"] if sightings else first.get("tier")
    dates = sorted(e["date"] for e in sightings)
    return {
        "fingerprint": fp,
        "fingerprint_scheme": first.get("fingerprint_scheme", SCHEME_TEXT),
        "category": first.get("category"),
        "symbol": first.get("symbol"),
        "count": count,
        "status": status,
        "tier": tier,
        "file": first["file"],
        "claim": first["claim"],
        "first_date": dates[0] if dates else first["date"],
        "last_date": dates[-1] if dates else first["date"],
    }


def trunc(s, width=72):
    return s if len(s) <= width else s[: width - 1] + "…"


# ── subcommands ────────────────────────────────────────────────────────────────

def cmd_add(args):
    path = resolve_ledger(args, must_exist=False)
    tier = args.tier
    evidence = args.evidence
    if tier == 1 and not (evidence and evidence.strip()):
        # review-tiers.md: a Tier 1 finding without its evidence artifact is
        # automatically Tier 2.
        print("note: tier 1 without --evidence demotes to tier 2", file=sys.stderr)
        tier = 2
    category = None
    if args.category is not None:
        category = normalize_category(args.category)
        if category is None:
            die(f"--category {args.category!r} is not a kebab-case slug (e.g. missing-ci-wiring)")
        fp = structured_fingerprint(args.file, category, args.symbol)
        scheme = SCHEME_STRUCTURED
    elif args.symbol is not None:
        die("--symbol requires --category (the text fingerprint ignores it)")
    else:
        fp = fingerprint(args.file, args.claim)
        scheme = SCHEME_TEXT
    with locked(path):
        prior = group(read_events(path)) if path.is_file() else {}
        # Same-run guard: a repeat within one run is not a recurrence, so it
        # must not be labelled one (the count in summarize() already ignores it).
        prior_runs = {e["run_id"] for e in prior.get(fp, ())
                      if e["status"] in OCCURRENCE_STATUSES}
        status = "RECURRING" if prior_runs - {args.run_id} else "NEW"
        event = {
            "fingerprint": fp,
            "fingerprint_scheme": scheme,
            "category": category,
            "symbol": args.symbol,
            "file": args.file,
            "claim": args.claim,
            "tier": tier,
            "source": args.source,
            "run_id": args.run_id,
            "date": args.date,
            "evidence": evidence,
            "status": status,
        }
        append_event(path, event)
    print(f"{status} {fp} tier={tier} {args.file} — {trunc(args.claim)}")


def cmd_tally(args):
    path = resolve_ledger(args, must_exist=True)
    rows = [summarize(fp, evs) for fp, evs in group(read_events(path)).items()]
    rows.sort(key=lambda r: (-r["count"], r["fingerprint"]))
    for r in rows:
        print(
            f"{r['fingerprint']}  n={r['count']}  status={r['status']}"
            f"  tier={r['tier']}  {r['file']} — {trunc(r['claim'])}"
        )
    print(f"total: {len(rows)} fingerprint(s)")


def cmd_triage(args):
    path = resolve_ledger(args, must_exist=True)
    today = parse_date(args.today)
    rows = [summarize(fp, evs) for fp, evs in group(read_events(path)).items()]

    promote = [
        r for r in rows
        if r["count"] >= args.threshold and r["status"] not in ("PROMOTED", "RETIRED-NOISE")
    ]
    promote.sort(key=lambda r: (-r["count"], r["fingerprint"]))

    retire = []
    for r in rows:
        if r["count"] == 1 and r["status"] == "NEW":
            age = (today - parse_date(r["last_date"])).days
            if age > args.age_days:
                retire.append((age, r))
    retire.sort(key=lambda t: (-t[0], t[1]["fingerprint"]))

    print(f"PROMOTION CANDIDATES (recurrence >= {args.threshold}):")
    for r in promote:
        print(f"  {r['fingerprint']}  n={r['count']}  status={r['status']}  {r['file']} — {trunc(r['claim'])}")
    if not promote:
        print("  none")
    print(f"RETIREMENT CANDIDATES (single recurrence, still NEW, older than {args.age_days} days):")
    for age, r in retire:
        print(f"  {r['fingerprint']}  age={age}d  {r['file']} — {trunc(r['claim'])}")
    if not retire:
        print("  none")


def _transition(args, status, evidence=None):
    path = resolve_ledger(args, must_exist=True)
    with locked(path):
        by_fp = group(read_events(path))
        if args.fingerprint not in by_fp:
            die(f"unknown fingerprint: {args.fingerprint}")
        first = by_fp[args.fingerprint][0]
        event = {
            "fingerprint": args.fingerprint,
            "fingerprint_scheme": first.get("fingerprint_scheme", SCHEME_TEXT),
            "category": first.get("category"),
            "symbol": first.get("symbol"),
            "file": first["file"],
            "claim": first["claim"],
            "tier": first["tier"],
            "source": args.source,
            "run_id": args.run_id,
            "date": args.date,
            "evidence": evidence,
            "status": status,
        }
        append_event(path, event)
    print(f"{status} {args.fingerprint} — {trunc(first['claim'])}")


def cmd_promote(args):
    # The doctrine's own rule, enforced at the transition: a promotion IS the
    # encoded check. INVESTIGATING needs no artifact yet; PROMOTED does.
    if args.status == "PROMOTED" and not (args.evidence and args.evidence.strip()):
        die("PROMOTED requires --evidence (the encoded validator rule or script)")
    _transition(args, args.status, evidence=args.evidence)


def cmd_retire(args):
    _transition(args, "RETIRED-NOISE")


EXPORT_KEYS = ("fingerprint", "fingerprint_scheme", "category", "symbol", "file",
               "count", "status", "first_seen", "last_seen")


def cmd_export(args):
    path = resolve_ledger(args, must_exist=True)
    out = Path(args.out)
    if out.resolve() == path.resolve():
        die(f"--out {out} is the ledger itself; export would overwrite it")
    rows = [summarize(fp, evs) for fp, evs in group(read_events(path)).items()]
    rows.sort(key=lambda r: r["fingerprint"])
    lines = []
    for r in rows:
        r["first_seen"], r["last_seen"] = r["first_date"], r["last_date"]
        lines.append(json.dumps({k: r[k] for k in EXPORT_KEYS},
                                sort_keys=True, ensure_ascii=False))
    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_name(out.name + ".tmp")
    tmp.write_text("".join(l + "\n" for l in lines), encoding="utf-8")
    os.replace(tmp, out)
    print(f"exported {len(rows)} fingerprint(s) to {out}")


# ── CLI ────────────────────────────────────────────────────────────────────────

def main(argv=None):
    today = _dt.date.today().isoformat()
    p = argparse.ArgumentParser(prog="ledger.py", description=__doc__.splitlines()[0])
    p.add_argument("--ledger", help="ledger path (default: <repo>/.claude/ledger/findings.jsonl)")
    sub = p.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("add", help="append a finding")
    a.add_argument("--file", required=True, help="repo-relative path the finding is about")
    a.add_argument("--claim", required=True, help="one-sentence claim summary")
    a.add_argument("--tier", type=int, choices=(1, 2), required=True,
                   help="1 = evidenced LLM finding, 2 = pure judgment (Tier 0 lives in validators, not here)")
    a.add_argument("--source", required=True, help="emitting agent (e.g. library-reviewer)")
    a.add_argument("--run-id", required=True, help="review run identifier")
    a.add_argument("--evidence", default=None, help="path to the evidence artifact (required for tier 1)")
    a.add_argument("--date", default=today, help="YYYY-MM-DD (default: today)")
    a.add_argument("--category", default=None,
                   help="kebab-case defect class (e.g. fail-open); switches to the structured fingerprint")
    a.add_argument("--symbol", default=None,
                   help="function, heading, or key the finding is about (requires --category)")
    a.set_defaults(fn=cmd_add)

    t = sub.add_parser("tally", help="group by fingerprint; report recurrence counts")
    t.set_defaults(fn=cmd_tally)

    g = sub.add_parser("triage", help="list promotion and retirement candidates")
    g.add_argument("--threshold", type=int, default=2, help="recurrence (distinct-run) threshold (default 2)")
    g.add_argument("--age-days", type=int, default=14, help="retire-as-noise age in days (default 14)")
    g.add_argument("--today", default=today, help="override 'today' for deterministic runs")
    g.set_defaults(fn=cmd_triage)

    pr = sub.add_parser("promote", help="append INVESTIGATING/PROMOTED transition")
    pr.add_argument("fingerprint")
    pr.add_argument("--status", choices=("INVESTIGATING", "PROMOTED"), default="PROMOTED")
    pr.add_argument("--evidence", default=None, help="the encoded check (validator rule or script path)")
    pr.add_argument("--source", default="triage")
    pr.add_argument("--run-id", default=None)
    pr.add_argument("--date", default=today)
    pr.set_defaults(fn=cmd_promote)

    r = sub.add_parser("retire", help="append RETIRED-NOISE transition")
    r.add_argument("fingerprint")
    r.add_argument("--source", default="triage")
    r.add_argument("--run-id", default=None)
    r.add_argument("--date", default=today)
    r.set_defaults(fn=cmd_retire)

    x = sub.add_parser("export", help="write a per-fingerprint summary (no claim text) for committing")
    x.add_argument("--out", required=True, help="output path (JSONL, one fingerprint per line)")
    x.set_defaults(fn=cmd_export)

    args = p.parse_args(argv)
    if hasattr(args, "date"):
        parse_date(args.date)  # validate early
    args.fn(args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
