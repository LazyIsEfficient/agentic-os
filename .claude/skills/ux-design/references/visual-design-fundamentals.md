# Visual Design Fundamentals

This file is the level of visual design a *product designer* needs to do their job well — not the depth of a graphic designer or art director, but enough to make confident, defensible visual decisions and to recognize when something is off and why.

The point is not to make things pretty. The point is to make things *clear*. A product where the user knows where to look, what's important, and what to do next is a good-looking product almost by accident.

## Visual Hierarchy

Visual hierarchy is the order in which the user notices things on the page. Hierarchy is *the* most important visual design tool — it's what tells the user what's important.

The eye naturally goes to:

1. **The largest thing.**
2. **The most contrasting thing** (light on dark, dark on light, color on neutral).
3. **The most isolated thing** (separated from everything else by white space).
4. **The thing at the top** (in left-to-right reading cultures, top-left).
5. **The thing pointed at** by other elements (visual flow).

The single most common visual design failure: **everything is the same weight**. When everything is bold, nothing is bold. When everything is colorful, no color stands out. When the page has 12 elements all clamoring for attention, the user looks at none of them.

The fix is almost always **subtraction**: remove emphasis from the unimportant things so the important things can stand out.

### Building hierarchy

Tools to make something more prominent:

- **Size.** Larger reads first. The headline is bigger than the body.
- **Weight.** Bold reads first. Heavy weights pull the eye.
- **Color.** Saturated reads more prominently than neutral. Brand color reads more than gray.
- **Contrast.** Dark on light or light on dark. Low-contrast text recedes.
- **Position.** Top and left read first in LTR cultures.
- **Whitespace around.** Isolated things stand out.
- **Shadow / elevation.** Raised things read as separate and above.

Tools to make something *less* prominent:

- Smaller, lighter weight, less contrast, neutral color, surrounded by other things, no shadow.

The trick: **be willing to make things less prominent**. Most designers reach for "make important things bigger." The strong move is "make less-important things smaller."

### A useful exercise

Print the design in grayscale and squint. The hierarchy is what you see clearly. If everything looks the same, the hierarchy is broken. If something stands out that *shouldn't*, that's the next thing to fix.

Alternative: blur the design in 5px gaussian. Same test.

## Typography

Typography is invisible when it's good and harmful when it's bad. The mistake is thinking typography is about picking interesting fonts.

### Choose fewer fonts

For most product UI, **one font family is enough.** Use weights and sizes within it for hierarchy. Two families, max. Beyond that, the design starts feeling chaotic.

A common combination:

- **One sans-serif** for the entire UI (Inter, IBM Plex Sans, SF Pro, system-ui).
- **One monospace** for code, IDs, technical content (JetBrains Mono, Fira Code, system mono).

That's almost always enough.

### Type scale

Define a small, fixed set of sizes — a type scale — and use only those. Don't pick "13px" because the heading "looks better." If 13px is needed, it goes into the scale.

A typical product UI scale:

```
xs   12px   metadata, labels
sm   14px   body text, default UI
base 16px   important body, headings level 4
lg   18px   headings level 3
xl   20px   headings level 2
2xl  24px   headings level 1
3xl  30px   page title
4xl  36px   hero
```

The exact numbers don't matter. Having a *fixed* set matters enormously.

### Line height and reading

- **Body text:** 1.4–1.6 line height. Tight enough to feel like one paragraph; loose enough to read.
- **Headings:** 1.1–1.3 line height. Headings are short; tight is fine.
- **UI labels:** 1.0–1.2. Single-line labels don't need much space.

Line length matters for reading: aim for 50–75 characters per line for body text. Wider lines exhaust the eye. Narrower lines make reading choppy.

### Font weight

Most fonts ship with multiple weights (300, 400, 500, 600, 700). Use 2–4 weights:

- **Regular (400)** for body text.
- **Medium (500)** for emphasis within body text.
- **Semibold (600)** for headings and important UI.
- **Bold (700)** sparingly, for the strongest emphasis.

Don't use light (300) or thin (200) weights for body text — they're hard to read at small sizes and on low-contrast backgrounds.

### Avoid these typography failures

- **All-caps body text.** Hard to read; reduces speed by ~10%.
- **Justified text on the web.** Causes uneven word spacing without good hyphenation.
- **Tiny gray text on white.** Below ~14px, gray-on-white is hard to read.
- **Long lines of body text** (more than ~75 characters per line). Eye fatigue.
- **Multiple typefaces from the same category.** Two sans-serifs in the same UI looks like a mistake.
- **Quirky fonts for body text.** Display fonts are for headings and posters, not for paragraphs.

## Color

Color is the strongest visual tool and the easiest to misuse. The discipline is to **use color sparingly**, with intent.

### Build a small palette

A typical product UI needs:

- **A neutral scale** (grays from white to near-black, ~10 steps). The most-used color in any UI.
- **A primary brand color**, plus its lighter and darker variants for hover/active states.
- **An accent or secondary color** (optional, used sparingly).
- **Semantic colors** for status: success (green), warning (amber), error (red), info (blue).

That's it. Not 50 colors. Not a different shade for every component.

### The 60/30/10 rule

A loose guideline: **60% neutral, 30% secondary neutral, 10% accent**. Most of the page is whitespace and gray. A smaller portion is structural color (background, dividers). A small amount is the brand or accent color where it matters.

Designs that violate 60/30/10 (40% bright color, 40% neutral, 20% another bright color) feel chaotic and unprofessional almost without exception.

### Using color for meaning

When color carries meaning, **use it consistently**:

- **Red** = error, destructive. Don't use red for "important non-error" things.
- **Green** = success, completion. Don't use green for "next step" buttons; users will misread.
- **Amber/yellow** = warning, attention.
- **Blue** = informational, neutral interactive (links, brand interactivity). Wide tolerance for shades.

And **never use color alone** to convey meaning. A color-blind user can't distinguish red and green; a screen reader user can't see color at all. Pair color with iconography, text, or position. See [accessibility.md](accessibility.md).

### Contrast

Contrast is the difference in luminance between two colors. WCAG defines minimum contrast ratios:

- **Body text:** 4.5:1 against background.
- **Large text** (≥18pt or ≥14pt bold): 3:1.
- **UI components and icons** (interactive parts, indicators): 3:1.

Tools: WebAIM contrast checker, Stark, browser dev tools.

Low-contrast text is the most common accessibility failure. Designers love subtle gray-on-gray; it looks elegant and reads like nothing. Don't.

### Dark mode

Dark mode isn't "the same colors with the background flipped." It's a separate palette with separate rules:

- **Use lighter backgrounds, not pure black.** Pure black is too high contrast; eyes strain. Use a dark gray (#0a0a0a, #111, #1a1a1a depending on the design).
- **Reduce color saturation.** Bright saturated colors look harsh on dark backgrounds. Desaturate slightly.
- **Avoid pure white text.** Use a soft white (#f5f5f5, #e5e5e5) to reduce eye strain.
- **Re-check all contrasts.** A color that works on white may fail on dark and vice versa.
- **Test elevations.** Cards and overlays usually need to be slightly lighter than the page background, not darker.

## Spacing

Spacing — the empty area around and between things — is what makes a design feel calm or cluttered, balanced or chaotic.

### Use a spacing scale

Like type, define a fixed set of spacing values and use only those:

```
0    0px
1    4px
2    8px
3    12px
4    16px
5    20px
6    24px
8    32px
10   40px
12   48px
16   64px
20   80px
```

Tailwind, Material, and most design systems use a base of 4 or 8 with multiples. Pick one and stick to it.

### Spacing rules

- **Related things go close together.** Items in the same group should be visually closer than items in different groups (proximity, see [Gestalt](#gestalt-principles)).
- **Group spacing > element spacing.** The gap between sections should be larger than the gap between items in a section.
- **Padding around clickable areas.** Touch targets need ~44px minimum on mobile; click targets need ~24px minimum on desktop.
- **Symmetry where possible.** Equal spacing around a thing reads as intentional; unequal spacing reads as accidental (even when it isn't).

### Whitespace is not wasted space

The most common amateur mistake: filling every pixel with content because "there's room." Whitespace is a design tool, not a defect. It separates, prioritizes, breathes.

A page with one clear thing on it surrounded by whitespace will be more effective than a page with 10 things crammed in.

## Gestalt Principles

Gestalt principles describe how the human eye groups visual elements. Knowing them lets you make grouping intentional instead of accidental.

The most useful for product design:

- **Proximity.** Things close together are perceived as a group. Spacing is grouping.
- **Similarity.** Things that look alike are perceived as a group. Same color, same shape, same weight.
- **Continuity.** The eye follows lines and curves. A grid of items reads as a row or column based on their alignment.
- **Closure.** The eye fills in incomplete shapes. A dashed border still reads as a border.
- **Figure / ground.** The eye separates foreground from background. Strong contrast helps.
- **Common region.** Things in a shared container (a card, a box, a colored region) are grouped together.

When grouping is unclear, one of these principles is being violated. Usually proximity (things that should be together aren't close enough) or common region (no container distinguishes the group).

## Layout and Grids

Most product UIs benefit from a grid: a consistent column structure that elements align to.

- **12-column grid** is the web default. Divides cleanly into many configurations (2, 3, 4, 6, 12 columns).
- **8-column grid** for narrower or simpler layouts.
- **4-column grid** for mobile.

Aligning to a grid produces designs that feel calm and intentional. *Not* aligning produces designs that feel accidental and amateur, even if the individual elements are well-designed.

### Alignment

The single most under-used visual move: **align everything**. Anything that doesn't align reads as an error. Things that align consistently read as professional.

- **Left-align body text** in LTR cultures. Centered body text is hard to read.
- **Right-align numbers** in tables (so digits line up).
- **Align edges** between adjacent elements. If the headline starts at x=80, the body should also start at x=80.
- **Align baselines**, not just bounding boxes. Two text elements next to each other should have their baselines aligned.

When in doubt, align. Then align some more.

## Putting It Together

A useful mental checklist for any visual design:

1. **What's the most important thing on this screen?** Is it the largest, most contrasting, most prominent thing? If not, fix the hierarchy.
2. **Squint test.** Can I see the structure when squinting? If everything blurs together, the hierarchy is too flat.
3. **Whitespace.** Is anything cramped? Is anything floating in too much space?
4. **Alignment.** Does everything align to something? Are there orphan elements not aligned to anything?
5. **Color.** Am I using color sparingly and meaningfully? Or is the page rainbowed?
6. **Type.** Am I using a small set of sizes from the scale, not arbitrary values?
7. **Contrast.** Does all text meet WCAG AA?
8. **Group integrity.** Do related things look related (close, similar, in a common region)?

If all eight pass, the visual design is doing its job.

## Anti-Patterns

- **Everything emphasized.** No hierarchy because everything is bold/colored/large.
- **Stock photos for decoration.** Adds noise, not value. Cut.
- **Ten different gray values.** Pick a scale and stick to it.
- **Decorative but meaningless illustrations.** They feel like packaging; users learn to ignore them.
- **Different font sizes that aren't on the type scale.** "13.5px because it looked better."
- **Tiny gray text on white.** Below the WCAG threshold and hard for everyone, especially older users.
- **All-caps headings everywhere.** Reduces reading speed; feels shouty.
- **Centered body text.** Hard to read.
- **Trapped white space.** A pocket of whitespace that has nothing to do with anything around it. Usually means the layout is broken.
- **Inconsistent corner radius.** Some buttons round, some square, some semi-round. Pick one.
- **Inconsistent shadow.** Different shadow styles on different cards. Pick one shadow scale.
- **Shadow with no reason.** Shadow conveys elevation; if nothing's elevated, no shadow.
- **Brand color overload.** The whole page is the brand color; the user has nowhere to look.
- **Pure black on pure white.** Too high contrast; tires the eye. Use very dark gray on very light gray.
- **Alignment by eyeball.** Things almost align but not quite. Reads as wrong even if you can't articulate why.
- **Decorative typography.** Display fonts in body text. Hard to read; feels off-brand.

## Related

- [interaction-design.md](interaction-design.md) — visual feedback during interactions
- [accessibility.md](accessibility.md) — color contrast, motion, color independence
- [design-systems.md](design-systems.md) — codifying type, color, and spacing as tokens
- [content-and-ux-writing.md](content-and-ux-writing.md) — typography supports content; content supports comprehension
