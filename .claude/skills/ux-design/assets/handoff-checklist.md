# Handoff Checklist

> Fillable checklist to walk through *before* handing a design to engineering. Catches the things that get missed at the last minute and turn into bugs at QA. Adapt to the project's actual scope.

## Header

- **Feature / design:** _____
- **Designer:** _____
- **Eng owner:** _____
- **Handoff date:** _____
- **Target ship date:** _____

---

## 1. Scope and Intent

- [ ] **Brief / design doc** is up to date and linked.
- [ ] **The user problem** is documented in plain language.
- [ ] **Why this design and not the alternatives** is captured (so engineers don't have to guess).
- [ ] **Acceptance criteria** are written in the ticket.
- [ ] **Non-goals** are explicit (what we're *not* building).
- [ ] **Trade-offs being deferred** are noted (with follow-up tickets if needed).

## 2. Coverage of States

Every screen has these states designed (or explicitly marked "out of scope"):

- [ ] **Default** (the happy path)
- [ ] **Empty** (no data yet)
- [ ] **Loading** (data being fetched)
- [ ] **Loaded with content** (the typical case)
- [ ] **Loaded with maximum content** (long names, long lists, edge values)
- [ ] **Loaded with minimum content** (just 1 item, very short text)
- [ ] **Error** (network failure, validation error, permission denied)
- [ ] **Partial / degraded** (some sections succeeded, others failed)
- [ ] **Disabled / read-only** (where applicable)
- [ ] **Stale** (data needs refresh — where applicable)
- [ ] **Offline** (where applicable)

For each interactive element:

- [ ] **Default state**
- [ ] **Hover state** (desktop)
- [ ] **Focus state** (keyboard)
- [ ] **Active / pressed state**
- [ ] **Disabled state**
- [ ] **Loading state** (where applicable)
- [ ] **Error state** (for inputs)

## 3. Layout and Responsive

- [ ] **Layout uses tokens** for spacing, not arbitrary values.
- [ ] **Layout uses tokens** for color and type, not hex codes or pixel sizes.
- [ ] **Each breakpoint** (mobile / tablet / desktop) is designed, not invented.
- [ ] **Min and max screen sizes** behave correctly (no overflow, no broken layout).
- [ ] **Touch targets** are at least 44x44px on mobile.

## 4. Microcopy

- [ ] **All text is final.** No lorem ipsum, no "TBD," no placeholders.
- [ ] **Button labels** are verbs + objects ("Save changes," not "OK").
- [ ] **Error messages** are specific, plain, and actionable.
- [ ] **Empty state copy** explains what would normally be there and what to do next.
- [ ] **Loading messages** are brief and accurate.
- [ ] **Confirmation messages** are clear about what happened.
- [ ] **All copy is reviewed** by a writer or PM if appropriate.

## 5. Accessibility

- [ ] **Color contrast** meets WCAG AA for all text and UI components.
- [ ] **Color is not the only signal** for any meaning.
- [ ] **Semantic HTML** is specified (button, link, heading hierarchy).
- [ ] **Keyboard order** is logical and noted.
- [ ] **Focus indicators** are visible and designed.
- [ ] **Form labels** are present and associated with inputs (no placeholder-only labels).
- [ ] **Alt text** is specified for images that carry meaning.
- [ ] **ARIA attributes** noted where needed (roles, labels, descriptions).
- [ ] **Screen reader narration** has been considered (and ideally previewed).
- [ ] **Animations** respect `prefers-reduced-motion`.
- [ ] **No information communicated only through hover or motion.**

## 6. Edge Cases

- [ ] **What happens with very long strings?** (names, URLs, descriptions)
- [ ] **What happens with empty values?** (no name, no avatar, no items)
- [ ] **What happens with 1 item? With 1,000 items?**
- [ ] **What happens with special characters?** (emoji, RTL text, accented characters)
- [ ] **What happens when data is partial?** (some fields populated, others not)
- [ ] **What happens when a request fails?** (network, server, permission)
- [ ] **What happens during slow connections?** (perceived performance, optimistic UI)
- [ ] **What happens for users without permissions?** (redirect, message, hidden, disabled)
- [ ] **What happens during a session timeout?**
- [ ] **What happens for the smallest realistic screen?** (320px)

## 7. Animation and Interaction

- [ ] **Transitions** are designed (not just "fade in").
- [ ] **Duration and easing** are specified (e.g. "150ms ease-out").
- [ ] **Triggers** are documented (what event starts the animation).
- [ ] **Reduced motion alternatives** are designed where the animation matters.

## 8. Data and API

- [ ] **Data shapes** are aligned with engineering (or explicitly TBD).
- [ ] **Data dependencies** are noted (what needs to load first).
- [ ] **Validation rules** are specified (what makes a field valid).
- [ ] **Error responses** are mapped to user-facing messages.

## 9. Design System Compliance

- [ ] **Reuses existing components** wherever possible.
- [ ] **Any new components** have been proposed via the design system process.
- [ ] **Variant requests** to existing components are documented.
- [ ] **Design system tokens** are referenced (not hardcoded values).

## 10. Engineering Conversation

- [ ] **An engineer has reviewed the design** before handoff.
- [ ] **Estimated effort** has been discussed.
- [ ] **Trade-offs between fidelity and effort** have been agreed.
- [ ] **Sequencing** is clear (what ships first, what's a follow-up).
- [ ] **Open questions** are listed in the handoff doc.

## 11. Documentation

- [ ] **Figma file** is organized, with frames named clearly and a "ready for handoff" status visible.
- [ ] **Frames are labeled** by state and breakpoint.
- [ ] **Annotations** in the file explain non-obvious decisions.
- [ ] **Linked design doc** explains the why.
- [ ] **Linked research** supports the user-facing decisions.

## 12. After Handoff

- [ ] **Designer is reachable** during build (Slack, scheduled syncs).
- [ ] **Design QA** is scheduled before launch.
- [ ] **Pairing** is planned for the trickiest interactions.
- [ ] **Post-launch review** is on the calendar.

---

## Handoff Sign-off

- [ ] Designer confirms checklist is complete: _____ (date)
- [ ] Eng owner confirms they understand the design: _____ (date)
- [ ] Outstanding questions and follow-ups are tracked: _____

## Notes for the Engineer

> Anything specific the designer wants the engineer to know that doesn't fit elsewhere.

> _____

## Known Trade-offs and Compromises

> Things the design *isn't* doing that the designer is okay with for v1, with reasons.

- _____
- _____
