#!/usr/bin/env python3
"""Check for updates against GitHub releases.

Usage:
    python3 telemetry/version_check.py

Silent when up to date. Prints update notice if newer version available.
Caches result for 24 hours. Gracefully handles offline/errors.
"""

import json
import os
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone, timedelta
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
VERSION_FILE = REPO_ROOT / "VERSION"
CACHE_DIR = Path.home() / ".ai-marketing-skills"
CACHE_FILE = CACHE_DIR / "version-cache.json"
GITHUB_API_URL = "https://api.github.com/repos/ericosiu/ai-marketing-skills/releases/latest"
CACHE_TTL_HOURS = 24


def read_local_version() -> str:
    """Read version from local VERSION file."""
    try:
        return VERSION_FILE.read_text().strip()
    except OSError:
        return "0.0.0"


def parse_semver(version: str) -> tuple:
    """Parse semver string into comparable tuple. Strips leading 'v'."""
    v = version.lstrip("v")
    parts = v.split(".")
    result = []
    for p in parts:
        try:
            result.append(int(p))
        except ValueError:
            result.append(0)
    while len(result) < 3:
        result.append(0)
    return tuple(result[:3])


def load_cache() -> dict:
    """Load cached version check result."""
    if not CACHE_FILE.exists():
        return {}
    try:
        with open(CACHE_FILE, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


def save_cache(latest_version: str):
    """Save version check result to cache."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache = {
        "latest_version": latest_version,
        "checked_at": datetime.now(timezone.utc).isoformat(),
    }
    try:
        with open(CACHE_FILE, "w") as f:
            json.dump(cache, f, indent=2)
    except OSError:
        pass


def cache_is_fresh() -> bool:
    """Check if cache is less than CACHE_TTL_HOURS old."""
    cache = load_cache()
    checked_at = cache.get("checked_at")
    if not checked_at:
        return False
    try:
        ts = datetime.fromisoformat(checked_at)
        if ts.tzinfo is None:
            ts = ts.replace(tzinfo=timezone.utc)
        return datetime.now(timezone.utc) - ts < timedelta(hours=CACHE_TTL_HOURS)
    except (ValueError, TypeError):
        return False


def fetch_latest_version() -> str:
    """Fetch latest version from GitHub API. Returns version string or None."""
    try:
        req = urllib.request.Request(
            GITHUB_API_URL,
            headers={"Accept": "application/vnd.github.v3+json", "User-Agent": "ai-marketing-skills"},
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("tag_name", "").lstrip("v")
    except Exception:
        return None


def check_version():
    """Main version check logic."""
    local = read_local_version()

    # Check cache first
    cache = load_cache()
    if cache_is_fresh() and cache.get("latest_version"):
        latest = cache["latest_version"]
    else:
        latest = fetch_latest_version()
        if latest is None:
            # Offline or API error — silently exit
            return
        save_cache(latest)

    local_parsed = parse_semver(local)
    latest_parsed = parse_semver(latest)

    if latest_parsed > local_parsed:
        print(f"🆕 AI Marketing Skills v{latest} available (you have v{local}). Run `git pull` to update.")


def main():
    try:
        check_version()
    except Exception:
        # Never block skill execution
        pass


if __name__ == "__main__":
    main()
