# YGG AI agents

This folder holds **one skill per internal AI agent** at YGG. Each agent has different data access, guardrails, and use cases. The canonical instructions for an agent always live in that agent’s **`SKILL.md`** (not in this README).

## How it is organized

| What you need | Where to go |
|---------------|-------------|
| **Full behavior, data scope, and rules for an agent** | Open `<agent-folder>/SKILL.md` (that file is the source of truth). |
| **A new agent** | Add `ygg-ai-agents/<agent-slug>/` with a `SKILL.md` at the root, same pattern as below. Optional: `references/` for long policies or examples (same idea as other skills in `skills-directory/`). |
| **Other engineering / workflow skills** | Parent folder: [`../`](../) — skills there are general capabilities; **`ygg-ai-agents/`** is only for named company agents. |

Path shape:

```text
ygg-ai-agents/
  README.md                 ← you are here: index + navigation
  <agent-slug>/
    SKILL.md                ← agent identity, access, rules, when to use
    references/             ← optional; only if the skill outgrows one file
```

## Agents

| Agent (folder) | Short summary | Details |
|----------------|---------------|---------|
| **BigQuery — “Yogi”** (`bigquery-ai-agent`) | BigQuery-focused analyst for the YGG ecosystem: player behavior, game revenue, marketing, TGE-related activity, grounded SQL and interpretation on `ygg_data_warehouse` data. | [bigquery-ai-agent/SKILL.md](bigquery-ai-agent/SKILL.md) |

**Quick pointer:** If you are wiring another system or agent to call this one, read **Key Operational Rules** and **Interaction Best Practices** in [bigquery-ai-agent/SKILL.md](bigquery-ai-agent/SKILL.md) first—wallet casing, partner IDs, row limits, and how to phrase requests matter.

---

When a second agent is added, extend the **Agents** table with one row and link to its `SKILL.md` so this file stays a single map of who exists and where the deep docs live.
