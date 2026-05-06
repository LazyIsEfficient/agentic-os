# Asset bundle catalog

Every asset type the bundle can declare, with the standard task-block shape: stable `id`, default `files_write` paths, dependencies, and the prompt/spec the executing agent needs to actually generate the asset.

The author emits one task block per asset type the **brief declared**. Skip every asset the brief did not declare — the brief is the contract, not this catalog. Use the YAML frontmatter format from `planning-and-task-breakdown/references/task-block-format.md`.

## Conventions

- **Default `files_write` root**: `assets/blog/<slug>/` where `<slug>` matches the post's URL slug. Override per-platform when the brief specifies (e.g. `static/og/<slug>.png` for Hugo, `public/posts/<slug>/` for Next.js, `attachments/<slug>/` for Substack/Notion).
- **`branch_suffix`**: `<task-slug>-<post-slug>` so multiple posts in flight don't collide on branch names.
- **`scope`**: every asset task should be `XS` or `S`. If an asset feels `M` or `L`, split it (e.g. "draft 4 diagrams" → 4 separate diagram tasks).
- **`parallel_safe`**: default `true`. Only `false` when the task mutates a shared file (the post body itself, the sitemap, an internal-link index).
- **`depends_on`**: at minimum, depends on `T-post-draft` (the post is the source of truth for image vibes, internal links, and OG titles). Cross-asset dependencies are noted per asset below.

## The post draft itself

```yaml
id: T-post-draft
depends_on: []
parallel_safe: false
conflicts_with: []
files_write:
  - content/blog/<slug>.md   # or platform-specific path
files_read:
  - <brief file path>
branch_suffix: post-draft-<slug>
scope: M
```

**Description:** Draft the blog post against the filled brief. Single takeaway, voice, length, and SEO meta as specified. Stops at end of close section; assets are separate tasks.

**Acceptance criteria:**
- [ ] Single takeaway present in first 200 words
- [ ] Length within the brief's target range
- [ ] Voice matches reference posts named in brief
- [ ] SEO meta block written (or omitted if owned-audience only)
- [ ] No banned phrases / AI-tells per brief constraints

**Verification:**
- [ ] Word count within range
- [ ] Reading-level / readability check passes
- [ ] Brief's "scope: out" items not present in post

---

## Hero / featured image

```yaml
id: T-hero-image
depends_on: [T-post-draft]
parallel_safe: true
conflicts_with: []
files_write:
  - assets/blog/<slug>/hero.png
  - assets/blog/<slug>/hero-alt.txt
files_read:
  - content/blog/<slug>.md
branch_suffix: hero-image-<slug>
scope: S
```

**Description:** Generate (or commission, or pull from stock per brief) the hero image for the post. Visual angle from the brief's hero spec — abstract diagram of the mental model (deep dive), before/after chart (case study), single conceptual image of the contrarian claim (opinion). Write alt text alongside.

**Acceptance criteria:**
- [ ] Image at the declared aspect ratio for the platform (typically 16:9 or 1.91:1)
- [ ] Alt text describes the image, not the caption (≤125 chars, no "image of…")
- [ ] Visual angle matches brief

**Verification:**
- [ ] Image displays correctly in a draft preview on the target platform
- [ ] Alt text passes the screen-reader smell test ("makes sense without seeing the image")

---

## OG / social share image (1200×630)

```yaml
id: T-og-image
depends_on: [T-post-draft, T-hero-image]   # depends on hero only if reusing it
parallel_safe: true
conflicts_with: []
files_write:
  - assets/blog/<slug>/og.png
  - assets/blog/<slug>/og-meta.json
files_read:
  - content/blog/<slug>.md
  - assets/blog/<slug>/hero.png   # if reusing
branch_suffix: og-image-<slug>
scope: XS
```

**Description:** Generate the 1200×630 social share card. Either reuse the hero image (cropped/composed) or generate a separate card per brief. Include the post title overlaid if the platform's social-card style does that. Write a small JSON sidecar with the `og:title`, `og:description`, and `twitter:card` values for the platform's metadata wiring.

**Acceptance criteria:**
- [ ] Exactly 1200×630
- [ ] Title renders legibly when scaled down (LinkedIn shrinks aggressively)
- [ ] og-meta.json has title, description, card type

**Verification:**
- [ ] Run a Twitter/X card validator and an OpenGraph debugger
- [ ] LinkedIn post composer preview looks correct

---

## X (Twitter) share post

```yaml
id: T-x-share
depends_on: [T-post-draft]
parallel_safe: true
conflicts_with: []
files_write:
  - assets/blog/<slug>/share-x.md
files_read:
  - content/blog/<slug>.md
branch_suffix: x-share-<slug>
scope: XS
```

**Description:** Write the X share post(s). Per brief: thread (3–10 posts), single 280-char post, or single long-form (4000+ chars). Match founder voice. Pull the strongest line from the post into the opening tweet. End with the link to the post (or "no link" if brief said so).

**Acceptance criteria:**
- [ ] Format matches brief (thread vs single vs long-form)
- [ ] Opening line earns the click
- [ ] Voice matches brief (run AI-humanizer pattern check)
- [ ] Character/length constraints honored

**Verification:**
- [ ] No banned phrases / AI-tells per brief
- [ ] Manual: paste into X composer, verify length and link unfurl

---

## LinkedIn share post

```yaml
id: T-li-share
depends_on: [T-post-draft]
parallel_safe: true
conflicts_with: []
files_write:
  - assets/blog/<slug>/share-li.md
files_read:
  - content/blog/<slug>.md
branch_suffix: li-share-<slug>
scope: XS
```

**Description:** Write the LinkedIn share post. LinkedIn voice runs slightly more declarative and longer than X. Open with the takeaway sentence; don't bury it behind a "🚀 thrilled to share" opener. End with a link to the post.

**Acceptance criteria:**
- [ ] Opens on the takeaway, not on excitement
- [ ] Length 800–1500 chars (LinkedIn's sweet spot)
- [ ] No "🚀", no "thrilled", no "I'm excited to announce"

**Verification:**
- [ ] Manual: paste into LinkedIn composer; check link preview pulls correct OG image

---

## Newsletter excerpt

```yaml
id: T-newsletter-excerpt
depends_on: [T-post-draft]
parallel_safe: true
conflicts_with: []
files_write:
  - assets/blog/<slug>/newsletter-excerpt.md
files_read:
  - content/blog/<slug>.md
branch_suffix: newsletter-<slug>
scope: XS
```

**Description:** Pull or rewrite a 200–400 word excerpt for the newsletter. Per brief: pull-quote (lift verbatim with framing), rewritten lede (top of post, paraphrased for newsletter cadence), or fresh framing (newsletter-only intro that funnels readers to the post).

**Acceptance criteria:**
- [ ] Length 200–400 words
- [ ] Excerpt earns the click on its own
- [ ] Link to the full post placed at the natural break

**Verification:**
- [ ] Reads cleanly out of context (newsletter readers haven't read the post yet)

---

## Embedded diagrams (Mermaid / ASCII / generated)

```yaml
id: T-diagram-<n>
depends_on: [T-post-draft]
parallel_safe: true
conflicts_with: []
files_write:
  - content/blog/<slug>.md            # if Mermaid/ASCII inlined
  - assets/blog/<slug>/diagram-<n>.png # if generated image
files_read:
  - content/blog/<slug>.md
branch_suffix: diagram-<n>-<slug>
scope: XS
```

**Description:** Author one diagram per task. Format from brief: Mermaid (renders on GitHub/Hashnode/Notion), ASCII (universal but austere), or generated image (Substack, LinkedIn). Each diagram has a stated job — install one piece of the mental model that prose alone can't.

**Multiple diagrams = multiple tasks.** Number them T-diagram-1, T-diagram-2, etc. They run in parallel.

**`parallel_safe: false`** if the diagram is inlined into the post body and another diagram task also writes to that file. In that case, list the conflicts.

**Acceptance criteria:**
- [ ] Diagram does work the prose can't (not decoration)
- [ ] Renders correctly on the target platform (verify Mermaid is supported before shipping it)
- [ ] Labeled with what it shows (caption above or beside)

**Verification:**
- [ ] Render a draft preview on the target platform
- [ ] Diagram makes sense without surrounding prose

---

## Code samples

```yaml
id: T-code-samples
depends_on: [T-post-draft]
parallel_safe: true
conflicts_with: []
files_write:
  - examples/<slug>/                  # if extracted to runnable repo
  - examples/<slug>/README.md
  - examples/<slug>/package.json      # or pyproject.toml, Cargo.toml, etc.
files_read:
  - content/blog/<slug>.md
branch_suffix: code-samples-<slug>
scope: S
```

**Description:** Extract code samples from the post into a runnable example repo (or directory). Each snippet in the post should map to a file in the example. Keep snippets minimal, runnable as shown, with one mechanism per snippet. Borrow `course-author/references/code-snippet-discipline.md` for the bar.

**Skip this task entirely** if the brief said inline-only or no code samples.

**Acceptance criteria:**
- [ ] Each in-post code block has a corresponding runnable file
- [ ] README explains how to run the examples
- [ ] No mystery imports, no undefined helpers

**Verification:**
- [ ] Run the examples end-to-end; they work as shown
- [ ] Reader can clone and run in under 5 minutes

---

## Internal-link map

```yaml
id: T-internal-link-map
depends_on: [T-post-draft]
parallel_safe: false           # mutates the post body
conflicts_with: [T-post-draft]
files_write:
  - content/blog/<slug>.md
files_read:
  - content/blog/<slug>.md
  - <site sitemap or content index>
branch_suffix: internal-links-<slug>
scope: XS
```

**Description:** Audit the drafted post for internal-link opportunities. From the brief's internal-link list (or auto-generated from sitemap), find 2–5 natural places to link to prior posts. Add the links inline. Don't force them — if a link doesn't fit, drop it.

**`parallel_safe: false`** because this mutates the post body file; serialize against any other task that writes to the same file.

**Acceptance criteria:**
- [ ] 2–5 internal links added (or fewer if natural fits don't exist)
- [ ] Each link earns its place — points to a post that genuinely extends the current one
- [ ] No anchor text that misrepresents the linked post

**Verification:**
- [ ] All links resolve (no 404s)
- [ ] Read the post end-to-end; links don't disrupt flow

---

## Pull quotes / callouts

```yaml
id: T-pull-quotes
depends_on: [T-post-draft]
parallel_safe: false           # mutates the post body
conflicts_with: [T-post-draft, T-internal-link-map]
files_write:
  - content/blog/<slug>.md
files_read:
  - content/blog/<slug>.md
branch_suffix: pull-quotes-<slug>
scope: XS
```

**Description:** Identify N pull-quote candidates (per brief) — the lines that should be visually elevated in the post body. Apply the platform's pull-quote markup (blockquote with class, callout block, etc.). For deep dives, pull-quotes often elevate misconceptions and the corrected frame.

**Acceptance criteria:**
- [ ] Number matches brief
- [ ] Each pull-quote stands alone — readable out of context
- [ ] Markup renders correctly on target platform

**Verification:**
- [ ] Draft preview on target platform; pull-quotes render visually distinct

---

## Quality gate (final task)

```yaml
id: T-quality-gate
depends_on: [T-post-draft, <every other asset task>]
parallel_safe: true
conflicts_with: []
files_write:
  - assets/blog/<slug>/quality-report.md
files_read:
  - content/blog/<slug>.md
  - assets/blog/<slug>/**
branch_suffix: quality-gate-<slug>
scope: S
```

**Description:** Run the quality gate the brief declared. Expert-panel scoring (target 90+) via `content-ops`. AI-humanizer pass (24-pattern detector). SEO meta validation (title length, description length, slug). Source citation verification for any technical claims (defer to `source-driven-development`). Subject approval pass (case studies only). Output a quality report file.

**Acceptance criteria:**
- [ ] Every quality-gate item from the brief is checked
- [ ] Failures listed with specific remediation
- [ ] Report links to the post and assets

**Verification:**
- [ ] Manual: every item in the brief's quality-gate section is addressed in the report
- [ ] If anything failed, do not mark the post ready-to-publish

## What to do if an asset doesn't apply

If the brief explicitly says "no Twitter share", do not emit `T-x-share`. Do not emit a "for completeness" task. Do not emit a stub task with a TODO. Empty assets clutter the dispatch list and slow the user down — the brief is the contract.

## What to do if an asset *does* apply but the brief didn't catch it

If you genuinely believe the brief missed an asset (e.g. a long deep dive without a TOC task), flag it in your output — *don't* silently emit the task. The user owns the brief; you flag the gap, the user updates the brief, you regenerate the DAG.
