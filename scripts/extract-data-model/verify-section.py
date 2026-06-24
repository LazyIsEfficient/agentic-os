#!/usr/bin/env python3
"""Compare extracted schema properties to a DATA_MODEL.md catalog section (Tier 0)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


def _parse_properties_table(section: str) -> list[dict[str, str]]:
    m = re.search(r"#### Properties\s*\n\n(\|.+\|\n(?:\|.+\|\n)+)", section, re.MULTILINE)
    if not m:
        raise ValueError("#### Properties table not found in section")
    lines = [ln.strip() for ln in m.group(1).strip().splitlines()]
    if len(lines) < 2:
        raise ValueError("properties table too short")
    rows: list[dict[str, str]] = []
    for ln in lines[2:]:
        if not ln.startswith("|"):
            break
        cells = [c.strip() for c in ln.strip("|").split("|")]
        if len(cells) < 3:
            continue
        name = cells[0].strip("` ")
        ptype = cells[1].strip("` ")
        req = cells[2].strip().lower()
        rows.append({"name": name, "type": ptype, "required": req})
    return rows


def _load_section(catalog: Path, section: str) -> str:
    text = catalog.read_text(encoding="utf-8")
    pat = re.compile(rf"^### {re.escape(section)}\s*$", re.MULTILINE)
    m = pat.search(text)
    if not m:
        raise ValueError(f"section not found: {section}")
    start = m.start()
    nxt = re.search(r"^### ", text[m.end() :], re.MULTILINE)
    end = m.end() + nxt.start() if nxt else len(text)
    return text[start:end]


def _normalize_required(val: str) -> bool:
    return val in ("yes", "true", "required", "y")


def _types_compatible(catalog_type: str, extracted: dict[str, Any]) -> bool:
    ct = catalog_type.lower().strip().replace("iso-8601 datetime", "datetime")
    et = str(extracted.get("type", "")).lower().strip()
    if ct == et:
        return True
    if ct.startswith("array") and et.startswith("array"):
        return ct.replace(" ", "") == et.replace(" ", "")
    if ct in ("number", "integer") and et in ("number", "integer"):
        return True
    return False


def verify(extracted: dict[str, Any], catalog_rows: list[dict[str, str]]) -> list[str]:
    errors: list[str] = []
    by_name = {p["name"]: p for p in extracted.get("properties") or []}
    catalog_names = {r["name"] for r in catalog_rows}

    for row in catalog_rows:
        name = row["name"]
        if name not in by_name:
            errors.append(f"REFUTED: catalog property `{name}` absent in schema")
            continue
        ext = by_name[name]
        if not _types_compatible(row["type"], ext):
            errors.append(
                f"REFUTED: `{name}` catalog type `{row['type']}` != schema `{ext.get('type')}`"
            )
        cat_req = _normalize_required(row["required"])
        if cat_req != bool(ext.get("required")):
            errors.append(
                f"REFUTED: `{name}` required={cat_req} != schema required={ext.get('required')}"
            )

    for name in sorted(by_name.keys()):
        if name not in catalog_names:
            errors.append(f"WARN: schema property `{name}` not listed in catalog")

    return errors


def main() -> int:
    p = argparse.ArgumentParser(description="Verify DATA_MODEL section against extracted JSON")
    p.add_argument("--extracted", type=Path, help="JSON from extract-json-schema.py")
    p.add_argument("--source", type=Path, help="JSON Schema file (runs extractor)")
    p.add_argument("--definition", "-d", help="Schema definition name")
    p.add_argument("--catalog", type=Path, required=True)
    p.add_argument("--section", required=True)
    p.add_argument("--fail-on-warn", action="store_true")
    args = p.parse_args()

    if args.extracted:
        extracted = json.loads(args.extracted.read_text(encoding="utf-8"))
    elif args.source:
        import subprocess

        repo = Path(__file__).resolve().parent
        cmd = [sys.executable, str(repo / "extract-json-schema.py"), str(args.source.resolve())]
        if args.definition:
            cmd.extend(["--definition", args.definition])
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            print(proc.stderr or proc.stdout, file=sys.stderr)
            return proc.returncode
        extracted = json.loads(proc.stdout)
    else:
        print("verify-section: provide --extracted or --source", file=sys.stderr)
        return 2

    try:
        section_text = _load_section(args.catalog.resolve(), args.section)
        catalog_rows = _parse_properties_table(section_text)
    except ValueError as e:
        print(f"verify-section: {e}", file=sys.stderr)
        return 2

    errors = verify(extracted, catalog_rows)
    blocking = [e for e in errors if e.startswith("REFUTED:")]
    warns = [e for e in errors if e.startswith("WARN:")]

    for e in errors:
        print(e, file=sys.stderr)

    if blocking:
        return 1
    if warns and args.fail_on_warn:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
