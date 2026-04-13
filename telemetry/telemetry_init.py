#!/usr/bin/env python3
"""First-run opt-in prompt for anonymous usage telemetry."""

import argparse
import json
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

CONFIG_DIR = Path.home() / ".ai-marketing-skills"
CONFIG_FILE = CONFIG_DIR / "telemetry-config.json"


def load_config():
    """Load existing telemetry config, or return None if not found."""
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return None
    return None


def save_config(opted_in: bool) -> dict:
    """Save telemetry config and return it."""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    config = {
        "opted_in": opted_in,
        "device_id": str(uuid.uuid4()),
        "created": datetime.now(timezone.utc).isoformat(),
    }
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)
    return config


def prompt_user() -> bool:
    """Interactive opt-in prompt. Returns True if user opts in."""
    print(
        "Would you like to opt into anonymous usage telemetry?\n"
        "This helps us improve skills.\n"
        "\n"
        "Data collected: skill name, duration, success/fail, version, OS.\n"
        "No code, file paths, or repo content is ever sent.\n"
    )
    while True:
        answer = input("(y/n): ").strip().lower()
        if answer in ("y", "yes"):
            return True
        if answer in ("n", "no"):
            return False
        print("Please enter y or n.")


def init_telemetry(yes: bool = False, no: bool = False) -> dict:
    """Initialize telemetry. Returns config dict.

    Args:
        yes: Non-interactive opt-in.
        no: Non-interactive opt-out.
    """
    existing = load_config()
    if existing is not None:
        return existing

    if yes:
        opted_in = True
    elif no:
        opted_in = False
    else:
        opted_in = prompt_user()

    config = save_config(opted_in)
    status = "enabled" if opted_in else "disabled"
    print(f"Telemetry {status}. Config saved to {CONFIG_FILE}")
    return config


def main():
    parser = argparse.ArgumentParser(description="Initialize telemetry opt-in.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--yes", action="store_true", help="Opt in non-interactively.")
    group.add_argument("--no", action="store_true", help="Opt out non-interactively.")
    args = parser.parse_args()

    config = init_telemetry(yes=args.yes, no=args.no)
    print(json.dumps(config, indent=2))


if __name__ == "__main__":
    main()
