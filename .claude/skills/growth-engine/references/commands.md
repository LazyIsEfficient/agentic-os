# Command Reference

## Create an experiment
```bash
python3 scripts/experiment-engine.py create \
  --agent <agent_name> \
  --hypothesis "What you expect to happen" \
  --variable "<variable_name>" \
  --variants '["variant_a", "variant_b"]' \
  --metric "<primary_metric>" \
  --cycle-hours 24
```

Add `--batch-mode` for 3-10 variant tests. Add `--min-samples N` to override auto-detection.

## Log a data point
```bash
python3 scripts/experiment-engine.py log \
  --agent <agent_name> \
  --experiment-id <EXP-ID> \
  --variant "<variant_name>" \
  --metrics '{"metric_name": value}'
```

## Score an experiment
```bash
python3 scripts/experiment-engine.py score --agent <agent_name> --experiment-id <EXP-ID>
```

Statuses: `running` → `trending` → `keep` (winner) or `discard` (loser)

Winners auto-promote to the playbook. Requires p < 0.05 AND ≥ 15% lift.

## List experiments
```bash
python3 scripts/experiment-engine.py list --agent <agent_name> [--status running|trending|keep|discard]
```

## Check the playbook
```bash
python3 scripts/experiment-engine.py playbook --agent <agent_name>
```

Always check the playbook before creating new content to apply proven best practices.

## Suggest next experiments
```bash
python3 scripts/experiment-engine.py suggest --agent <agent_name>
```

## Generate weekly scorecard
```bash
python3 scripts/autogrowth-weekly-scorecard.py [--weeks N] [--output file.md]
```

## Check campaign pacing
```bash
python3 scripts/pacing-alert.py [--json]
```

Exit code 0 = on pace, 1 = alerts present.

## Recommended Workflow

1. Before creating content: `playbook` → apply proven rules
2. When publishing: `log` → record which variant was used and its metrics
3. Periodically: `score` → check if experiments have reached statistical significance
4. Weekly: `scripts/autogrowth-weekly-scorecard.py` → review all channels
5. After completing experiments: `suggest` → pick the next variable to test
