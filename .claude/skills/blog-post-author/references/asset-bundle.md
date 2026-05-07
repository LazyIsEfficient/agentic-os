# Asset bundle catalog

Every asset type the bundle can declare, with the standard task-file shape: stable file name, default output paths, and the spec a subagent reading **only that file** needs to actually generate the asset.

The author writes one file per asset the **brief declared**, under `tasks/`. Skip every asset the brief did not declare — the brief is the contract, not this catalog.

## Conventions

- **One task = one file.** File name `tasks/T-<slug>.md`. The slug is stable; if the asset is dropped, retire the file rather than reusing the slug.
- **Every task file is self-contained.** A subagent should be able to execute it with no other context: who's asking, what to build, what files to write, how to know it's done.
- **Default output root**: `assets/blog/<slug>/` where `<slug>` matches the post's URL slug. Override per-platform when the brief specifies (e.g. `static/og/<slug>.png` for Hugo, `public/posts/<slug>/` for Next.js, `attachments/<slug>/` for Substack/Notion).
- **Substitute the slug before writing.** `<slug>` placeholders below must be replaced with the actual post slug in every task file.
- **No DAG fields.** No `depends_on`, no `parallel_safe`, no `conflicts_with`. The author groups tasks into sequential and parallel batches in the output summary; the calling agent honors the ordering when fanning out.

## Standard task-file shape

```markdown
# Task: <descriptive title>

**Output:**
- `path/to/primary-output`
- `path/to/secondary-output` (if any)

**Reads:**
- `content/blog/<slug>.md` (the post draft)
- `<other inputs the subagent will need>`

**What to do:**
<one paragraph: the actual instruction. Subagent reads this and acts.>

**Success criteria:**
- <specific, checkable condition>
- <specific, checkable condition>

**Verify:**
- <how to confirm — render check, link check, validator, etc.>
```

That's it. No YAML frontmatter, no mutex declarations, no scope sizing.

## When tasks must serialize

Some tasks mutate the post body file. If two such tasks are emitted, the calling agent must run them sequentially, not in parallel. Note this in the task file's **What to do** paragraph — e.g. "Mutates `content/blog/<slug>.md`. Run after T-post-draft and before any other task that writes to the same file."

The author lists those tasks in a sequential band in the output summary, not a parallel batch.

---

## Hero / featured image

```markdown
# Task: Hero image for <post title>

**Output:**
- `assets/blog/<slug>/hero.png`
- `assets/blog/<slug>/hero-alt.txt`

**Reads:**
- `content/blog/<slug>.md`

**What to do:**
Generate (or commission, or pull from stock per brief) the hero image. Visual angle from the brief's hero spec — abstract diagram of the mental model (deep dive), before/after chart (case study), single conceptual image of the contrarian claim (opinion). Aspect ratio <16:9 | 1.91:1 — match brief>. Write alt text alongside (≤125 chars, describes the image, not the caption, no "image of…").

**Success criteria:**
- Image at the declared aspect ratio
- Alt text describes the image, not the caption
- Visual angle matches the brief's hero spec

**Verify:**
- Image displays correctly in a draft preview on the target platform
- Alt text passes the screen-reader smell test
```

---

## OG / social share image (1200×630)

```markdown
# Task: OG/social share card for <post title>

**Output:**
- `assets/blog/<slug>/og.png`
- `assets/blog/<slug>/og-meta.json`

**Reads:**
- `content/blog/<slug>.md`
- `assets/blog/<slug>/hero.png` (if reusing)

**What to do:**
Generate the 1200×630 social share card. Either reuse the hero image (cropped/composed) or generate a separate card per brief. Overlay the post title if the platform's social-card style does that. Write a JSON sidecar with `og:title`, `og:description`, and `twitter:card` values for the platform's metadata wiring.

**Run after** the hero image task if reusing it.

**Success criteria:**
- Exactly 1200×630
- Title renders legibly when scaled down (LinkedIn shrinks aggressively)
- og-meta.json has title, description, card type

**Verify:**
- Twitter/X card validator and an OpenGraph debugger
- LinkedIn post composer preview
```

---

## X (Twitter) share post

```markdown
# Task: X share post for <post title>

**Output:**
- `assets/blog/<slug>/share-x.md`

**Reads:**
- `content/blog/<slug>.md`

**What to do:**
Write the X share post(s). Per brief: thread (3–10 posts), single 280-char post, or single long-form (4000+ chars). Match founder voice. Pull the strongest line from the post into the opening tweet. End with the link to the post (or "no link" if brief said so).

**Success criteria:**
- Format matches brief (thread / single / long-form)
- Opening line earns the click
- Voice matches brief (run AI-humanizer pattern check)
- Character/length constraints honored
- No banned phrases / AI-tells per brief

**Verify:**
- Manual: paste into X composer, verify length and link unfurl
```

---

## LinkedIn share post

```markdown
# Task: LinkedIn share post for <post title>

**Output:**
- `assets/blog/<slug>/share-li.md`

**Reads:**
- `content/blog/<slug>.md`

**What to do:**
Write the LinkedIn share post. Slightly more declarative and longer than X. Open with the takeaway sentence; don't bury it behind a "🚀 thrilled to share" opener. End with a link to the post.

**Success criteria:**
- Opens on the takeaway, not on excitement
- Length 800–1500 chars
- No "🚀", no "thrilled", no "I'm excited to announce"

**Verify:**
- Manual: paste into LinkedIn composer; confirm link preview pulls correct OG image
```

---

## Newsletter excerpt

```markdown
# Task: Newsletter excerpt for <post title>

**Output:**
- `assets/blog/<slug>/newsletter-excerpt.md`

**Reads:**
- `content/blog/<slug>.md`

**What to do:**
Pull or rewrite a 200–400 word excerpt for the newsletter. Per brief: pull-quote (lift verbatim with framing), rewritten lede (top of post, paraphrased for newsletter cadence), or fresh framing (newsletter-only intro that funnels readers to the post).

**Success criteria:**
- Length 200–400 words
- Excerpt earns the click on its own
- Link to the full post placed at the natural break

**Verify:**
- Reads cleanly out of context
```

---

## Embedded diagram (Mermaid / ASCII / generated image)

One file per diagram. If the brief calls for multiple diagrams, the author emits multiple files: `tasks/T-diagram-1.md`, `tasks/T-diagram-2.md`, etc.

```markdown
# Task: Diagram <n> — <what it shows>

**Output:**
- `content/blog/<slug>.md` (if Mermaid/ASCII inlined)
- `assets/blog/<slug>/diagram-<n>.png` (if generated image)

**Reads:**
- `content/blog/<slug>.md`

**What to do:**
Author one diagram. Format from brief: Mermaid (renders on GitHub/Hashnode/Notion), ASCII (universal but austere), or generated image (Substack, LinkedIn). The diagram has a stated job: <install one piece of the mental model that prose alone can't>. <If inlined into the post body: mutates `content/blog/<slug>.md`; serialize against any other task that writes to the same file.>

**Success criteria:**
- Diagram does work the prose can't (not decoration)
- Renders correctly on the target platform
- Labeled with what it shows (caption above or beside)

**Verify:**
- Render a draft preview on the target platform
- Diagram makes sense without surrounding prose
```

---

## Code samples

```markdown
# Task: Runnable code samples for <post title>

**Output:**
- `examples/<slug>/`
- `examples/<slug>/README.md`
- `examples/<slug>/<package config>` (package.json / pyproject.toml / Cargo.toml / etc.)

**Reads:**
- `content/blog/<slug>.md`

**What to do:**
Extract code samples from the post into a runnable example repo (or directory). Each snippet in the post should map to a file in the example. Keep snippets minimal, runnable as shown, with one mechanism per snippet. Borrow the bar from `course-author/references/code-snippet-discipline.md`.

**Skip this task entirely** if the brief said inline-only or no code samples.

**Success criteria:**
- Each in-post code block has a corresponding runnable file
- README explains how to run the examples
- No mystery imports, no undefined helpers

**Verify:**
- Run the examples end-to-end
- Reader can clone and run in under 5 minutes
```

---

## Internal-link map

Mutates the post body file. Sequence against any other body-mutating task.

```markdown
# Task: Internal-link map for <post title>

**Output:**
- `content/blog/<slug>.md` (mutates post body)

**Reads:**
- `content/blog/<slug>.md`
- `<site sitemap or content index>`

**What to do:**
Audit the drafted post for internal-link opportunities. From the brief's internal-link list (or auto-generated from sitemap), find 2–5 natural places to link to prior posts. Add the links inline. Don't force them — drop any that don't fit.

**Mutates the post body** — must run sequentially, not in parallel, with any other task that writes to `content/blog/<slug>.md` (pull-quotes, inlined diagrams).

**Success criteria:**
- 2–5 internal links added (or fewer if natural fits don't exist)
- Each link points to a post that genuinely extends this one
- Anchor text accurately represents the linked post

**Verify:**
- All links resolve (no 404s)
- Read end-to-end; links don't disrupt flow
```

---

## Pull quotes / callouts

Mutates the post body file. Sequence against internal-link map and any inlined diagrams.

```markdown
# Task: Pull quotes for <post title>

**Output:**
- `content/blog/<slug>.md` (mutates post body)

**Reads:**
- `content/blog/<slug>.md`

**What to do:**
Identify <N from brief> pull-quote candidates — the lines that should be visually elevated. Apply the platform's pull-quote markup (blockquote with class, callout block, etc.). For deep dives, pull-quotes often elevate misconceptions and the corrected frame.

**Mutates the post body** — sequence against the internal-link map task and any inlined diagram tasks.

**Success criteria:**
- Number matches brief
- Each pull-quote stands alone — readable out of context
- Markup renders correctly on target platform

**Verify:**
- Draft preview on target platform; pull-quotes render visually distinct
```

---

## Quality gate (always the final task)

```markdown
# Task: Quality gate for <post title>

**Output:**
- `assets/blog/<slug>/quality-report.md`

**Reads:**
- `content/blog/<slug>.md`
- `assets/blog/<slug>/**`
- All other task outputs

**What to do:**
Run every quality-gate item the brief declared. Expert-panel scoring (target 90+) via `content-ops`. AI-humanizer pass (24-pattern detector). SEO meta validation (title length, description length, slug). Source citation verification for any technical claims (defer to `source-driven-development`). Subject approval pass (case studies only). Output a quality report file.

**Run last.** All other tasks must complete before this one starts.

**Success criteria:**
- Every quality-gate item from the brief is checked
- Failures listed with specific remediation
- Report links to the post and assets

**Verify:**
- Manual: every item in the brief's quality-gate section is addressed in the report
- If anything failed, do not mark the post ready-to-publish
```

## What to do if an asset doesn't apply

If the brief explicitly says "no Twitter share", do not write `tasks/T-x-share.md`. Do not write a "for completeness" task. Do not write a stub task with a TODO. Empty task files clutter the dispatch list and slow the agent down — the brief is the contract.

## What to do if an asset *does* apply but the brief didn't catch it

If you genuinely believe the brief missed an asset (e.g. a long deep dive without a TOC task), flag it in your output — *don't* silently emit the task. The user owns the brief; you flag the gap, the user updates the brief, you regenerate the task files.
