# Accessibility

Accessibility is the practice of designing products that work for people across the full range of human abilities — including people who use screen readers, navigate by keyboard, have low vision, can't perceive color the way you do, can't hear, can't process motion, can't tap small targets, or use assistive technology you've never tried.

The most important thing to internalize: **accessibility is not a feature**. It's not a section of the design that you do "if you have time." It's the floor — the minimum acceptable level of design quality. A design that isn't accessible is unfinished, regardless of how polished the rest looks.

The second most important thing: **accessibility is good design for everyone**. The captions you added for deaf users help anyone watching in a noisy environment. The keyboard navigation you added for screen reader users helps power users. The high-contrast text you added for low-vision users helps everyone reading on a glaring monitor outdoors. The plain language you wrote for cognitively impaired users helps everyone who's tired or stressed.

## Why It Matters

Three reasons, in roughly equal weight:

1. **It's the right thing to do.** People who use assistive technology are people. Excluding them from your product is excluding them from a thing they need or want, and there's no honest defense.
2. **It's the law in most jurisdictions.** ADA in the US, Section 508, EAA in the EU, AODA in Ontario, equivalent laws worldwide. Lawsuits over accessibility are common and increasing.
3. **It's a market.** ~15% of the world's population has some form of disability. Excluding them excludes a large customer base — and many of the rest of your users have temporary or situational impairments (a broken arm, a noisy room, sun glare, divided attention).

The argument "we don't have any users with disabilities" is almost always wrong. You don't have any *visible* users with disabilities — because the product excludes them.

## WCAG — The Standard

The Web Content Accessibility Guidelines (WCAG) are the international standard. The current version is WCAG 2.2; 3.0 is in development.

WCAG defines three conformance levels:

- **A** — minimum. Most products meet most of A almost by accident.
- **AA** — the working standard. Most accessibility laws require AA. Your design's target.
- **AAA** — aspirational. Some criteria are appropriate for specific contexts (medical, government); not generally required for product UI.

**Default target: WCAG 2.2 Level AA.** Anything below is a defect; AAA is a stretch goal where it makes sense.

WCAG is organized around four principles (POUR):

- **Perceivable** — users can perceive the content (sight, hearing, touch).
- **Operable** — users can operate the interface (keyboard, mouse, voice, switch).
- **Understandable** — users can understand the content and the interface.
- **Robust** — the content works with assistive technology, including future technology.

## The Most Common Failures (and How to Fix Them)

In rough order of how often they appear in production:

### 1. Insufficient color contrast

**Failure:** light gray text on white background. "It looks elegant." It's also unreadable for many users.

**Standard:** 4.5:1 for body text (≤14pt), 3:1 for large text (≥18pt or ≥14pt bold), 3:1 for UI components and icons.

**Fix:** check every text/background pair against WCAG. Tools: WebAIM Contrast Checker, Stark, browser dev tools.

The hardest case: brand colors. Many brand palettes were chosen for visual identity, not contrast. A brand blue at #6699FF has a contrast ratio of ~2.6:1 against white — well below AA. Solutions:

- Use the brand color for non-text elements (icons, accents, large logos).
- Darken the brand color when it appears as text.
- Pair light brand colors with dark backgrounds and vice versa.

The brand team will sometimes resist. Make the case: "this is unreadable for ~15% of users." The legal exposure usually wins the argument.

### 2. Missing or wrong alternative text

**Failure:** images with no `alt` attribute, or `alt="image"`, or `alt=""` on images that carry meaning.

**Fix:**

- **Decorative images** (background patterns, divider lines): `alt=""`. Screen readers skip them.
- **Informative images** (icons with meaning, photos that convey information): descriptive alt text. "Person typing on a laptop" — concrete, brief.
- **Functional images** (icon buttons): describe the *action*, not the image. `alt="Close"` not `alt="X"`.
- **Complex images** (charts, diagrams): a short alt + a longer description elsewhere on the page or linked.

The principle: ask "if I removed this image and replaced it with the alt text, would the user have the same information?"

### 3. Color as the only signal

**Failure:** "click the red button to delete" — but a colorblind user can't see the red.

**Fix:** pair color with text, iconography, or shape:

- A red error message has an icon (⚠), the word "Error," and red color.
- A required field has both an asterisk and the word "required."
- A status indicator has both a colored dot and a label.

Color is one signal of several, never the only one.

### 4. Inaccessible form labels

**Failure:** placeholder text used as the only label. "Email" disappears the moment the user starts typing; the user no longer knows what field they're in.

**Fix:**

- **Visible labels above (or beside) every input.** Not just placeholders.
- **`<label for="id">`** or **`<label>` wrapping the input** in HTML — required for screen reader association.
- **Required field marked with both a symbol (\*) and a text indicator** ("required").
- **Errors associated with their field** via `aria-describedby` or similar, not just visually nearby.
- **Help text associated with the field** via `aria-describedby`.

### 5. Keyboard navigation broken

**Failure:** users who can't use a mouse can't reach or activate parts of the interface.

**Fix:** every interactive element must be reachable with the Tab key and operable with Enter or Space. Custom components built from `<div>` and `<span>` are not keyboard-accessible by default; you have to add it back.

Specific things to check:

- **Tab order is logical** — usually matches the visual order top-to-bottom, left-to-right.
- **Focus indicator is visible** — a clear outline or highlight on the focused element. Don't remove the default browser focus ring without replacing it with something equally visible.
- **Modals trap focus** — Tab cycles within the modal until it's closed.
- **Escape closes overlays** — modals, dropdowns, popovers.
- **Custom controls have keyboard equivalents** — drag-and-drop has a keyboard alternative; complex pickers can be operated with arrow keys.

The fastest test: unplug your mouse and try to use the product. Anywhere you can't go, anywhere you can't activate, anywhere you get stuck — that's a fail.

### 6. Missing or wrong semantic HTML

**Failure:** buttons made from `<div>`s, headings made from styled `<p>`s, lists made from styled `<div>`s.

**Fix:** use the right HTML element for the meaning, not the appearance.

- A clickable thing is `<button>`, not `<div onclick>`.
- A link is `<a href>`, not a `<button>` styled to look like a link.
- A heading is `<h1>` through `<h6>`, in order.
- A list is `<ul>` or `<ol>`.
- A form input is `<input>`.

The semantic HTML carries meaning that screen readers and assistive technologies use. Custom widgets built from `<div>`s erase this meaning, and you have to manually add it back via ARIA — which is harder, more error-prone, and easier to get wrong.

The general rule: **use the right HTML element first; reach for ARIA only when no HTML element fits.**

### 7. Heading hierarchy broken

**Failure:** a page with no `<h1>`, or with `<h1>` skipping to `<h3>` to `<h2>` randomly because that's what looked good.

**Fix:** headings should form a logical outline.

- **One `<h1>` per page** (the page's title).
- **`<h2>` for major sections.**
- **`<h3>` for subsections of those.**
- **No skipping levels** (don't go from h2 to h4).
- **Heading text should describe the section** — assistive tech users navigate by heading, like a table of contents.

Visual size and heading level are independent. An `<h1>` can be styled smaller than an `<h2>` if your design needs it. Use the right level semantically; style it however looks right.

### 8. Animations and motion

**Failure:** auto-playing videos, parallax scrolling, animated transitions everywhere — these can cause vestibular disorders, seizures, or cognitive overload.

**Fix:**

- **Respect `prefers-reduced-motion`.** Users can set "reduce motion" in their OS. Detect this and skip or simplify animations.
- **Don't auto-play video or audio.**
- **Avoid more than three flashes per second** (seizure risk).
- **Animations are short** (under 500ms) and serve a purpose.
- **No essential information communicated only through motion** — a user with `prefers-reduced-motion` should still be able to use the product.

### 9. Touch targets too small

**Failure:** buttons or links that are 16x16px on a phone. Hard to hit.

**Fix:** WCAG 2.5.5 (Level AAA) recommends 44x44px for touch targets. WCAG 2.5.8 (AA, added in 2.2) requires 24x24px. Aim for 44 where possible.

This includes the *clickable area*, not just the visible icon. A 16px icon with 14px of padding around it has a 44x44 click target.

### 10. Time limits

**Failure:** sessions that time out, forms that auto-submit, pop-ups that auto-dismiss. Users with cognitive or motor impairments may need more time than you expect.

**Fix:**

- **Avoid time limits where possible.** If the user is reading, let them read.
- **Warn before timing out** with enough time to extend.
- **Allow extending** the time limit.
- **Don't auto-dismiss important messages.** Errors stay until acknowledged.

## Testing for Accessibility

Manual testing matters. Tools matter too. Use both.

### Automated tools

These catch ~30–50% of accessibility issues — the easy structural ones. Critical to use, insufficient on their own.

- **axe-core / axe DevTools** — the de facto standard. Browser extension, CLI, library version.
- **WAVE** (WebAIM) — friendly visualization of issues.
- **Lighthouse** — built into Chrome dev tools, includes accessibility audit.
- **eslint-plugin-jsx-a11y** — catches some issues in React code as you write it.
- **jest-axe** — automated accessibility checks in tests.

For React/TS projects, integrate axe-core into your test suite. See [typescript-testing-frontend](../../typescript-testing-frontend/SKILL.md). Failed accessibility tests should block the build, not be a "warning."

### Manual testing

The other ~50–70% of issues only show up in manual testing.

- **Keyboard-only navigation.** Unplug the mouse. Tab through the entire flow. Activate everything with Enter or Space. Note what you can't reach or activate.
- **Screen reader walkthrough.** Use a real screen reader for the platform: VoiceOver on Mac/iOS (built-in), NVDA on Windows (free), JAWS on Windows (commercial). Listen to your product. Most teams find this revelatory.
- **Zoom to 200%+.** The page should still be usable. No content cut off, no horizontal scrolling, no overlapping text.
- **Color blindness simulation.** Browser dev tools include this. Check that color isn't the only signal.
- **High contrast / dark mode.** Forced colors mode (Windows High Contrast) reveals where you've hard-coded colors.

### User testing with assistive technology users

The gold standard. Recruit users who actually rely on assistive technology and watch them use the product. You will find issues no automated tool catches and no sighted internal tester noticed.

This is real research — see [ux-research/references/usability-testing.md](../../ux-research/references/usability-testing.md). Compensation is the same as for other participants. Recruitment requires reaching out to disability communities or specialized recruitment panels.

## Inclusive Design

Accessibility is the floor; inclusive design is the bigger frame. Inclusive design asks: "who are we excluding by default, and how can we include them?"

Some axes:

- **Disability** — visual, hearing, motor, cognitive, neurological.
- **Language** — non-native English speakers, low literacy, RTL languages.
- **Age** — older users have lower vision, slower fine motor control.
- **Connectivity** — slow connections, intermittent connectivity, expensive data.
- **Device** — low-end phones, slow computers, small screens.
- **Context** — distracted, in motion, stressed, multitasking.
- **Background** — different cultural references, different mental models, different prior software experience.

Inclusive design is broader than WCAG and overlaps with research and UX writing. It's the practice of asking, throughout design, "who else?" and "what about?"

A useful mental exercise: pick three personas representing edge cases relevant to your product (a user with low vision, a user on a slow connection, a user in a non-native language) and walk a flow through each one's perspective. The flow that works for all three is more robust than the flow that works only for "the average user."

## Practical Workflow

How to integrate accessibility into a normal design workflow without it being a separate phase:

### During discovery / research

- **Recruit diverse participants.** Include users with disabilities in usability testing.
- **Ask about assistive tech use.** "Do you use any assistive technology?" — open and non-judgmental.

### During design

- **Use accessible components from the design system.** If the system isn't accessible, fix the system.
- **Check contrast as you pick colors.** Don't wait until the end.
- **Design all states**, including focus states.
- **Write microcopy that's clear and direct.** See [content-and-ux-writing.md](content-and-ux-writing.md).
- **Plan for keyboard navigation.** Order the elements logically.
- **Plan for screen reader narration.** The order matters; the labels matter.

### During handoff

- **Specify accessible behavior** — focus order, ARIA roles, keyboard shortcuts, error messaging — explicitly.
- **Don't leave it to engineering to figure out.** They will guess, and the guess will be wrong.

### During build

- **Pair with engineers** when accessibility is in question. Test as it's built.
- **Use jest-axe / similar in CI.** Block merges that fail.

### During QA

- **Manual keyboard test.** Always.
- **Manual screen reader test.** For any significant change.
- **Automated audit.** axe-core scan of the built product.

### Post-launch

- **Monitor for accessibility complaints.** Treat them as P1 bugs.
- **Audit periodically.** WCAG audit by an external firm every 1–2 years for products at scale.

## Anti-Patterns

- **Accessibility as a phase at the end.** "We'll do accessibility before launch." Then there's no time. Ship inaccessible.
- **"Just add ARIA."** ARIA is a last resort, not a first one. Most ARIA can be replaced by correct HTML, which is more reliable.
- **`alt="image"` everywhere.** Useless. Either describe the image or mark it decorative.
- **Removing the focus ring without replacing it.** Looks "cleaner." Renders the page unusable for keyboard users.
- **Placeholder as label.** Disappears when the user types; user forgets what field they're in.
- **Tiny touch targets.** 16px icons with no padding. Hard to hit; impossible for users with motor impairments.
- **Color as the only signal.** Red and green for status; colorblind users can't distinguish.
- **Ignored keyboard users.** "Tab through the page" was never tested.
- **Auto-playing animations.** Hostile to vestibular disorder users.
- **Time limits without warning.** Session expires; user loses work.
- **Inaccessible custom controls.** Custom dropdowns, modals, datepickers built without keyboard or screen reader support.
- **WCAG audit not part of definition of done.** Ships inaccessible because it wasn't required.
- **Pretending accessibility is "extra."** It's a feature in the same sense that "the product loads at all" is a feature: the floor.
- **Treating WCAG as a checklist instead of as principles.** A page can pass automated tests and still be unusable. Real users catch what tools miss.

## Related

- [visual-design-fundamentals.md](visual-design-fundamentals.md) — color contrast, hierarchy, type
- [interaction-design.md](interaction-design.md) — keyboard, focus, motion
- [content-and-ux-writing.md](content-and-ux-writing.md) — plain language, error messages
- [design-systems.md](design-systems.md) — accessibility built into components
- [handoff-and-collaboration.md](handoff-and-collaboration.md) — communicating accessibility requirements
- [typescript-testing-frontend](../../typescript-testing-frontend/SKILL.md) — automated a11y testing
- [ux-research/references/usability-testing.md](../../ux-research/references/usability-testing.md) — testing with assistive tech users
