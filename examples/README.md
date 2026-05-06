# Shaper examples

Worked examples of each intake shaper turning a vague request into a filled brief. Each example shows:

1. **The user's initial request** — typically one or two messy sentences.
2. **The shaper's batched clarifying questions** — one round of 3–6 questions covering the unknowns.
3. **The user's answers** — concrete or `unknown`.
4. **The output brief** — what the shaper produces, ready to paste into a fresh execution session.

The shapers always stop after producing the brief. Say `go` to execute, or paste the brief into a new session.

**What comes after the brief depends on its shape:**

- **Multi-slice briefs** (multi-repo or single-repo features in `/shape`; campaigns and pipelines in `/mshape`) point at a planner: `planning-and-task-breakdown` for engineering, per-channel decomposition (`content-ops` / `growth-engine` / `outbound-engine` / `sales-pipeline`) for marketing. The planner produces the executable units. Worked engineering examples live in [`planning-and-task-breakdown/`](planning-and-task-breakdown/) — same source briefs, decomposed into per-task YAML frontmatter and an Execution DAG ready for a dispatcher.
- **Domain pipelines** (`/course-shape`, `/game-shape`) point at the next skill in their chain — `course-design`, `game-concept-creator`, `game-systems-designer`.
- **Single-slice briefs** (investigations, scoped bugfixes, single content pieces, single optimizations, research questions) skip planning and go straight to execution.

See [`SHAPERS.md`](../SHAPERS.md) for the full three-layer flow (Intake → Planning → Execution) and its limitations.

## Layout

```
examples/
├── prompt-shaper/        # engineering work — /shape
│   ├── feature-rollout.md
│   ├── single-repo-feature.md
│   ├── investigation.md
│   └── bugfix.md
├── marketing-shaper/     # marketing work — /mshape
│   ├── campaign.md
│   ├── content.md
│   ├── optimization.md
│   ├── research.md
│   └── pipeline.md
├── course-shaper/        # teaching work — /course-shape
│   ├── full-course.md
│   ├── single-module.md
│   └── workshop.md
├── game-design-shaper/   # game design work — /game-shape
│   ├── full-game.md
│   ├── prototype.md
│   ├── jam.md
│   └── live-game-update.md
└── planning-and-task-breakdown/  # multi-slice briefs decomposed into parallel-dispatchable tasks
    ├── README.md
    ├── feature-rollout-okta-sso.md
    └── single-repo-feature-csv-export.md
```

## How to read these

Each file is a single transcript-style example. The brief at the end is the *only* thing the shaper actually outputs in real use — the questions and answers are shown here for illustration. In a real session you see only the final fenced brief and the prompt to say `go`.

## How to use these

- **Pattern-match before invoking.** Find the example closest to your situation, see the shape of questions you'll be asked, and have rough answers ready.
- **Borrow phrasing.** The "Goal" lines and "Out of scope" lists in these examples are good models for how to write your own.
- **Skip the shaper when** your request is one file, one obvious change, with done criteria in one sentence — shaping a trivial task is overhead.

See the [main README](../README.md#using-the-shapers) for shaper workflow tips.
