## Execution doctrine — plan once, cut the smallest sufficient diff

The framework rewards elaboration: on a fixed task it grew +715 LOC where a lean setup grew +224 at the same pass rate. Elaboration is a tax, not a virtue — execute lean.

- **Plan, then execute.** Read every relevant file in ONE batch, write a short plan, then edit. Do not interleave exploratory reads with edits — the read/edit/read/edit loop is how scope quietly creeps.
- **Fail fast.** After an edit, run only the NARROWEST failing test — the single test or case that exercises the change, not the whole suite. Iterate on that until green; widen coverage only once it passes.
- **Smallest sufficient diff.** Prefer the smallest change that MEETS the acceptance criteria. Guard both ends: no gold-plating (needless files, abstractions, options nobody asked for) AND no under-building (skipping required behavior to look lean). Sufficient is the bar — not maximal, not minimal.
