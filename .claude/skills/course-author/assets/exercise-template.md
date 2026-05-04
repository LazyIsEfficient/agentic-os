# Exercise template

Fill one of these per exercise in the lesson. The type is set by the lesson spec; pick the matching block.

## Parsons problem (rearrange given steps)

**Type:** Parsons
**Prompt.** <Problem statement. Tell the learner what the assembled solution should do.>

**Given (in scrambled order):**

```
A. <step>
B. <step>
C. <step>
D. <step>
E. <distractor — a plausible but wrong step>
```

<details>
<summary>Correct ordering</summary>

<e.g. B → A → D → C. E is a distractor; it doesn't belong.>

*Why this order:* <one or two lines tying the sequence to the mechanism>

</details>

---

## Fill-in (complete the missing piece)

**Type:** fill-in
**Prompt.** <What the learner must produce. Name the expected behavior or output.>

**Starter:**

```<lang>
function foo(input) {
  // TODO: <one specific thing to fill in>
  return result;
}
```

<details>
<summary>Reference solution</summary>

```<lang>
// completed function
```

*Why this works:* <one line>

</details>

---

## Modify (change a working example)

**Type:** modify
**Prompt.** <Start from this working code; change it so that …>

**Starter:**

```<lang>
// a full, working example from the lesson or a close cousin
```

**New requirement:** <the constraint the learner must satisfy>

<details>
<summary>Reference solution</summary>

```<lang>
// modified code
```

*What changed and why:* <1–2 lines>

</details>

---

## From-scratch (independent practice)

**Type:** from-scratch
**Prompt.** <Problem statement with explicit inputs, outputs, and constraints. Should be a new instance of the same class of problem the worked example solved.>

**Acceptance criteria:**
- <criterion 1 — observable>
- <criterion 2>
- <criterion 3>

<details>
<summary>Reference solution</summary>

```<lang>
// complete solution
```

*How this solves it:* <short paragraph — name the mechanism the learner should have used>

</details>

---

## Common feedback notes (optional)

After reference solution, optionally add a "**Common variations you'll see**" block:
- <variation 1 — often fine>
- <variation 2 — often fine>
- <variation 3 — looks fine but has a subtle bug; flag it>

This helps learners who self-assess against a solution that isn't byte-identical to theirs.
