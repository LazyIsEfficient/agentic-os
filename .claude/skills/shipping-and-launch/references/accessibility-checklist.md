# Pre-Launch Accessibility Checklist

Accessibility checks to complete before any production launch (targets WCAG 2.1 AA).

## Automated Scan
- [ ] axe / Lighthouse accessibility audit passes with 0 critical or serious violations
- [ ] No missing `alt` text on informational images
- [ ] No empty or non-descriptive link text ("click here", "read more")

## Keyboard Navigation
- [ ] All interactive elements reachable by Tab key
- [ ] Focus order is logical (top-to-bottom, left-to-right)
- [ ] Visible focus indicator present on all focusable elements
- [ ] Modal dialogs trap focus correctly; Escape closes them

## Screen Reader
- [ ] Page has a single `<h1>`; heading hierarchy is logical
- [ ] Form inputs have associated `<label>` elements
- [ ] Error messages are announced (aria-live or role=alert)
- [ ] Dynamic content updates announced to screen readers

## Colour & Contrast
- [ ] Text contrast ratio ≥ 4.5:1 (normal text) or ≥ 3:1 (large text)
- [ ] No information conveyed by colour alone

## Media
- [ ] Videos have captions
- [ ] Audio content has transcripts
- [ ] No content flashes more than 3 times per second
