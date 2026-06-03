# ASCII Diagrams

Every post MUST include at least one ASCII diagram in a code block. These break up walls of text and make complex systems visual.

Use box-drawing characters:
```
┌─────────┐    ┌─────────┐    ┌─────────┐
│  Input  │───►│ Process │───►│ Output  │
└─────────┘    └─────────┘    └─────────┘
```

## Diagram types to use

- **System architecture** — boxes connected by arrows showing how components relate
- **Before/after** — side-by-side comparison of old vs new state
- **Flow diagrams** — decision trees, pipelines, sequences
- **Hierarchy** — org charts, priority stacks, dependency trees
- **Metrics** — simple bar charts using block characters (█ ▓ ░)

## Constraints

- Under 40 chars wide (mobile rendering)
- Simple enough to parse in 3 seconds
- Labeled clearly — no ambiguous boxes

## Example — system flow

```
Input (60s)
    │
    ▼
┌──────────┐
│ Process  │ step 1
└────┬─────┘
     ▼
┌──────────┐
│ Dispatch │ step 2
└────┬─────┘
     ▼
  Output
```

## Example — metrics visualization

```
Performance by Category:
Category A   ████████████ 100%
Category B   ████████░░░░  67%
Category C   ░░░░░░░░░░░░   0%
```

## Formatting for X

- X articles support markdown-like formatting in long posts
- Use code blocks (```) for ASCII art — they render in monospace on X
- Bold with asterisks where supported
- Keep paragraphs to 1-3 sentences max
- Line breaks between every thought
