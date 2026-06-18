#!/usr/bin/env sh
# Idempotent bootstrap: materialize runtime/.env from the committed template if absent.
# Safe to run repeatedly — never overwrites an existing .env.
set -eu

# Resolve this script's own directory so it works from any CWD.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
EXAMPLE="$SCRIPT_DIR/.env.example"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$EXAMPLE" ]; then
  echo "setup: ERROR: $EXAMPLE not found" >&2
  exit 1
fi

if [ -f "$ENV_FILE" ]; then
  echo "setup: .env already exists at $ENV_FILE — leaving it untouched."
else
  cp "$EXAMPLE" "$ENV_FILE"
  echo "setup: created $ENV_FILE from .env.example"
fi
