#!/usr/bin/env python3
"""Extract canonical property list from a JSON Schema file (Tier 0)."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def _primary_type(node: dict[str, Any]) -> str:
    t = node.get("type")
    if isinstance(t, list):
        non_null = [x for x in t if x != "null"]
        return non_null[0] if non_null else "null"
    if isinstance(t, str):
        return t
    if "$ref" in node:
        return "ref"
    return "unknown"


def _resolve_ref(root: dict[str, Any], ref: str) -> dict[str, Any]:
    if not ref.startswith("#/"):
        raise ValueError(f"unsupported $ref (local only): {ref}")
    node: Any = root
    for part in ref[2:].split("/"):
        part = part.replace("~1", "/").replace("~0", "~")
        if not isinstance(node, dict) or part not in node:
            raise ValueError(f"$ref not found: {ref}")
        node = node[part]
    if not isinstance(node, dict):
        raise ValueError(f"$ref did not resolve to object: {ref}")
    return node


def _object_schema(root: dict[str, Any], schema: dict[str, Any]) -> dict[str, Any]:
    if "$ref" in schema:
        return _object_schema(root, _resolve_ref(root, schema["$ref"]))
    if schema.get("type") == "object" or "properties" in schema:
        return schema
    raise ValueError("schema is not an object definition")


def _load_definition(root: dict[str, Any], definition: str | None) -> dict[str, Any]:
    if definition:
        for key in ("$defs", "definitions"):
            if key in root and definition in root[key]:
                return _object_schema(root, root[key][definition])
        raise ValueError(f"definition not found: {definition}")
    return _object_schema(root, root)


def _resolve_node(root: dict[str, Any], node: dict[str, Any]) -> dict[str, Any]:
    if "$ref" in node:
        node = _resolve_ref(root, node["$ref"])
    return node


def _catalog_type(schema_type: str, fmt: str | None, items: Any, root: dict[str, Any] | None = None) -> str:
    if schema_type == "string" and fmt == "uuid":
        return "uuid"
    if schema_type == "string" and fmt == "date-time":
        return "datetime"
    if schema_type == "array" and isinstance(items, dict) and root is not None:
        items = _resolve_node(root, items)
        if _primary_type(items) == "object" or "properties" in items:
            return "array<object>"
        inner = _primary_type(items)
        if inner and inner != "unknown":
            return f"array<{inner}>"
        return "array"
    if schema_type == "array":
        return "array"
    return schema_type


def extract(source: Path, definition: str | None) -> dict[str, Any]:
    root = json.loads(source.read_text(encoding="utf-8"))
    obj = _load_definition(root, definition)
    required = set(obj.get("required") or [])
    props_out: list[dict[str, Any]] = []

    for name in sorted((obj.get("properties") or {}).keys()):
        node = _resolve_node(root, obj["properties"][name])
        st = _primary_type(node)
        fmt = node.get("format") if isinstance(node.get("format"), str) else None
        items = node.get("items")
        props_out.append(
            {
                "name": name,
                "type": _catalog_type(st, fmt, items, root),
                "required": name in required,
                "schema_type": st,
                **({"format": fmt} if fmt else {}),
            }
        )

    title = definition or obj.get("title") or source.stem
    return {
        "extractor": "json-schema",
        "source": str(source),
        "definition": title,
        "properties": props_out,
    }


def main() -> int:
    p = argparse.ArgumentParser(description="Extract DATA_MODEL properties from JSON Schema")
    p.add_argument("schema", type=Path, help="Path to .json schema file")
    p.add_argument("--definition", "-d", help="Key in $defs/definitions (optional)")
    args = p.parse_args()
    if not args.schema.is_file():
        print(f"extract-json-schema: file not found: {args.schema}", file=sys.stderr)
        return 2
    try:
        out = extract(args.schema.resolve(), args.definition)
    except (json.JSONDecodeError, ValueError) as e:
        print(f"extract-json-schema: {e}", file=sys.stderr)
        return 2
    json.dump(out, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
