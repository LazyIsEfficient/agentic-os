#!/usr/bin/env python3
"""Local stats viewer for skill usage data.

Usage:
    python3 telemetry/telemetry_report.py           # Full report
    python3 telemetry/telemetry_report.py --json     # Machine-readable output
    python3 telemetry/telemetry_report.py --skill X  # Filter to one skill
"""

import argparse
import json
import sys
from collections import defaultdict
from datetime import datetime, timezone, timedelta
from pathlib import Path

CONFIG_DIR = Path.home() / ".ai-marketing-skills"
CONFIG_FILE = CONFIG_DIR / "telemetry-config.json"
USAGE_LOG = CONFIG_DIR / "analytics" / "skill-usage.jsonl"


def load_entries(skill_filter: str = None) -> list:
    """Load all log entries, optionally filtered by skill."""
    if not USAGE_LOG.exists():
        return []
    entries = []
    with open(USAGE_LOG, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if skill_filter and entry.get("skill") != skill_filter:
                    continue
                entries.append(entry)
            except json.JSONDecodeError:
                continue
    return entries


def load_config() -> dict:
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def parse_timestamp(ts: str) -> datetime:
    """Parse ISO timestamp string."""
    # Handle both formats with and without timezone
    try:
        return datetime.fromisoformat(ts)
    except ValueError:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))


def generate_report(entries: list, config: dict) -> dict:
    """Generate stats from entries."""
    now = datetime.now(timezone.utc)
    seven_days_ago = now - timedelta(days=7)
    thirty_days_ago = now - timedelta(days=30)

    total = len(entries)
    last_7 = 0
    last_30 = 0
    skill_runs = defaultdict(int)
    skill_successes = defaultdict(int)
    skill_durations = defaultdict(list)
    last_timestamp = None

    for e in entries:
        skill = e.get("skill", "unknown")
        skill_runs[skill] += 1

        if e.get("success"):
            skill_successes[skill] += 1

        duration = e.get("duration_ms")
        if duration is not None:
            skill_durations[skill].append(duration)

        ts_str = e.get("timestamp")
        if ts_str:
            try:
                ts = parse_timestamp(ts_str)
                if ts.tzinfo is None:
                    ts = ts.replace(tzinfo=timezone.utc)
                if ts >= seven_days_ago:
                    last_7 += 1
                if ts >= thirty_days_ago:
                    last_30 += 1
                if last_timestamp is None or ts > last_timestamp:
                    last_timestamp = ts
            except (ValueError, TypeError):
                pass

    # Per-skill stats
    per_skill = {}
    for skill, count in sorted(skill_runs.items(), key=lambda x: -x[1]):
        avg_dur = None
        if skill_durations[skill]:
            avg_dur = round(sum(skill_durations[skill]) / len(skill_durations[skill]), 1)
        success_rate = round(skill_successes[skill] / count * 100, 1) if count > 0 else 0
        per_skill[skill] = {
            "runs": count,
            "success_rate_pct": success_rate,
            "avg_duration_ms": avg_dur,
        }

    most_used = max(skill_runs, key=skill_runs.get) if skill_runs else None

    return {
        "total_runs": total,
        "last_7_days": last_7,
        "last_30_days": last_30,
        "most_used_skill": most_used,
        "last_run": last_timestamp.isoformat() if last_timestamp else None,
        "opted_in": config.get("opted_in", False),
        "per_skill": per_skill,
    }


def print_report(report: dict):
    """Pretty-print the report."""
    print("=" * 50)
    print("  AI Marketing Skills — Usage Report")
    print("=" * 50)
    print()
    print(f"  Total runs (all time):  {report['total_runs']}")
    print(f"  Last 7 days:            {report['last_7_days']}")
    print(f"  Last 30 days:           {report['last_30_days']}")
    print(f"  Most used skill:        {report['most_used_skill'] or 'N/A'}")
    print(f"  Last run:               {report['last_run'] or 'N/A'}")
    print(f"  Telemetry opt-in:       {'Yes' if report['opted_in'] else 'No'}")
    print()

    if report["per_skill"]:
        print("  Per-Skill Breakdown:")
        print("  " + "-" * 46)
        print(f"  {'Skill':<25} {'Runs':>5} {'Success':>8} {'Avg ms':>8}")
        print("  " + "-" * 46)
        for skill, stats in report["per_skill"].items():
            avg = f"{stats['avg_duration_ms']:.0f}" if stats["avg_duration_ms"] is not None else "N/A"
            print(f"  {skill:<25} {stats['runs']:>5} {stats['success_rate_pct']:>7.1f}% {avg:>8}")
    else:
        print("  No usage data found.")
    print()


def main():
    parser = argparse.ArgumentParser(description="View local skill usage stats.")
    parser.add_argument("--json", action="store_true", help="Output as JSON.")
    parser.add_argument("--skill", help="Filter to a specific skill.")
    args = parser.parse_args()

    config = load_config()
    entries = load_entries(skill_filter=args.skill)

    if not entries and not args.json:
        print("No usage data found. Run some skills first!")
        print(f"Data location: {USAGE_LOG}")
        return

    report = generate_report(entries, config)

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print_report(report)


if __name__ == "__main__":
    main()
