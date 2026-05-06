#!/usr/bin/env python3
"""Log a skill run event. Called by each skill's preamble.

Usage:
    python3 telemetry/telemetry_log.py --skill <name> --duration <ms> --success <true/false> --version <ver>

Always logs locally. If opted in, also sends to analytics endpoint.
Never logs: code content, file paths, repo names, usernames, environment variables.
"""

import argparse
import json
import os
import platform
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path

CONFIG_DIR = Path.home() / ".ai-marketing-skills"
CONFIG_FILE = CONFIG_DIR / "telemetry-config.json"
ANALYTICS_DIR = CONFIG_DIR / "analytics"
USAGE_LOG = ANALYTICS_DIR / "skill-usage.jsonl"

# Replace with your analytics endpoint
ANALYTICS_ENDPOINT = "https://example.com/api/telemetry"  # no-op stub — Replace with your analytics endpoint


def load_config() -> dict:
    """Load telemetry config. Returns empty dict if not found."""
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            pass
    return {}


def python_version() -> str:
    """Return major.minor Python version string."""
    return f"{sys.version_info.major}.{sys.version_info.minor}"


def build_entry(skill: str, duration_ms: int, success: bool, version: str, device_id: str) -> dict:
    """Build a log entry. Only safe, anonymous fields."""
    return {
        "skill": skill,
        "duration_ms": duration_ms,
        "success": success,
        "version": version,
        "os": platform.system(),
        "arch": platform.machine(),
        "python": python_version(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "device_id": device_id,
    }


def log_locally(entry: dict):
    """Append entry to local JSONL log."""
    ANALYTICS_DIR.mkdir(parents=True, exist_ok=True)
    with open(USAGE_LOG, "a") as f:
        f.write(json.dumps(entry) + "\n")


def send_remote(entry: dict):
    """Send entry to remote analytics endpoint. Fails silently."""
    try:
        data = json.dumps(entry).encode("utf-8")
        req = urllib.request.Request(
            ANALYTICS_ENDPOINT,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        urllib.request.urlopen(req, timeout=5)
    except Exception:
        # Never block skill execution
        pass


def parse_bool(value: str) -> bool:
    """Parse a boolean string."""
    return value.lower() in ("true", "1", "yes")


def main():
    parser = argparse.ArgumentParser(description="Log a skill run event.")
    parser.add_argument("--skill", required=True, help="Skill name.")
    parser.add_argument("--duration", required=True, type=int, help="Duration in milliseconds.")
    parser.add_argument("--success", required=True, help="true/false")
    parser.add_argument("--version", required=True, help="Skill version.")
    args = parser.parse_args()

    config = load_config()
    device_id = config.get("device_id", "unknown")
    opted_in = config.get("opted_in", False)

    entry = build_entry(
        skill=args.skill,
        duration_ms=args.duration,
        success=parse_bool(args.success),
        version=args.version,
        device_id=device_id,
    )

    # Always log locally
    log_locally(entry)

    # Send remotely only if opted in
    if opted_in:
        send_remote(entry)


if __name__ == "__main__":
    main()
