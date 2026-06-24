# extract-data-model

Tier 0 property extractors for `data-model-verifier`. Same input → same JSON output.

| Script | Source type |
|---|---|
| `json-schema.sh` | JSON Schema (`.json`, optional `--definition`) |
| `verify-data-model-section.sh` | Compare extract (or `--source`) to `DATA_MODEL.md` `###` section |

Fixtures: `fixtures/`. Tests: `bash scripts/extract-data-model-test.sh`.

OpenAPI, Prisma, protobuf — add under this directory (one stack per PR).
