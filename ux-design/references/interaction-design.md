# Interaction Design

Interaction design is about *what happens when the user does something* and *what tells them what they can do*. Click here, see this. Hover, get a tooltip. Drag, get feedback. Submit, see a result.

The reason interaction design matters: most products ship enough functionality. What separates good products from bad ones is whether the functionality *feels right* — predictable, responsive, forgiving, and clear about what's happening at every moment.

## Affordances and Signifiers

Two terms that mean different things and that designers often confuse.

- **Affordance** is what an object *can do*. A door affords pushing or pulling. A button affords pressing. A handle affords gripping. The affordance exists whether or not anyone notices it.
- **Signifier** is what *tells you* the affordance is there. A door has a flat plate (push) or a handle (pull). A button has a raised, shadow-cast appearance (press me). A handle has a grip-shaped grip (grab me).

The signifier is the design problem. A door that's hard to use is one whose signifiers contradict its affordances — a flat plate on a door that pulls; a handle on a door that pushes. The classic Norman door.

In digital design:

- **A button with no visual differentiation** (flat color, no border, no hover state) has the affordance "clickable" but no signifier. Users won't know.
- **An icon with no label** has the affordance of an action button but no signifier of *which* action.
- **A draggable list item with no grab handle** has the affordance of being reorderable but no signifier. Users won't try to drag.
- **A hover-only interaction** doesn't exist on touch devices. Affordance only with a missing signifier on half your platforms.

The general rule: **make signifiers explicit**. Don't rely on users to guess what's interactive.

## Feedback

Every interaction has three phases:

1. **Anticipation:** the user is about to do something. The interface should signal what they can do (signifier).
2. **Action:** the user does something. The interface should respond *immediately* — even if the result takes longer to compute.
3. **Result:** the action completes. The interface should make the new state clear.

A button without anticipation feedback (no hover state) makes the user uncertain whether it's clickable. A button without action feedback (no pressed state) makes them uncertain whether their click registered. A button without result feedback (the page doesn't change visibly) makes them uncertain whether anything happened.

The single most common interaction-design failure is **missing feedback**, especially in steps 2 and 3.

### Concrete feedback patterns

- **Hover state** for desktop: color change, underline, cursor change. (Don't rely on it for mobile.)
- **Active / pressed state**: a slight depress, color shift, or scale. Confirms the click registered.
- **Loading state**: spinner, skeleton, or progress bar — within 100ms of the action.
- **Result state**: a visible change. New page, updated data, success message, error message.
- **Disabled state**: visibly different. Doesn't respond to interaction. Often paired with explanation of why.

## Latency, Delay, and Perceived Performance

Real performance is measured in milliseconds. Perceived performance is measured in *how long the user feels they waited*. They're not the same.

Some thresholds (Nielsen, Card et al.):

| Time | What the user feels |
|---|---|
| **< 100ms** | Instantaneous. Direct manipulation. |
| **< 1s** | Minimal interruption; user maintains flow but notices the delay. |
| **< 10s** | Limit of attention. User starts looking elsewhere; needs feedback to stay engaged. |
| **> 10s** | User has switched to other tasks; needs explicit progress and a way to return. |

The implications for design:

- **Anything under 1 second**: don't show a loading spinner until 200ms have passed. A spinner that flashes for 50ms is more disturbing than no spinner.
- **1–10 seconds**: a progress indicator with motion. Doesn't need to be accurate; needs to convey "something is happening."
- **Over 10 seconds**: a real progress bar, an estimated time, and ideally a way to do something else while waiting.
- **Optimistic UI**: when the user does something that's likely to succeed, update the UI *immediately* and reconcile if the server disagrees. The user perceives instant; the actual round trip is hidden.

Optimistic UI is one of the highest-leverage interaction patterns: it can make a slow product feel fast, and it costs almost nothing.

## State Design

Most designs are designed for the "happy state" — the page with content, the form filled in, the dashboard with data. The unhappy states get bolted on later or not at all. **Designing the unhappy states is most of interaction design.**

The states every screen has:

- **Empty** — no data yet. First-time use, new user, filtered view with no matches.
- **Loading** — data being fetched. Initial load, refresh, lazy load.
- **Loaded with data** — the happy state.
- **Loaded with partial data** — some sections succeeded, others failed.
- **Error** — something went wrong. Network failure, permission denied, validation error.
- **Disabled / read-only** — the user can see this but can't act on it.
- **Stale** — the data is old; needs a refresh.
- **Offline** — no network at all.

Each one needs a *deliberate* design. Defaults to "show a spinner forever" or "show nothing" or "show a generic error" are the marks of a half-finished product.

### Empty states

The first impression for a new user. Not a problem to hide — an *opportunity to teach*.

Good empty states:

- **Explain what would normally be here.** "Your tasks will appear here once you create one."
- **Provide an immediate next action.** "+ Create your first task" — visible, central, friendly.
- **Don't overdo the personality.** "Whoops! Looks like you're brand new here, friend!" — patronizing. "No tasks yet" is fine.

Bad empty states:

- A blank page with no explanation.
- A page that *looks* like the loaded state but with zero items (looks broken).
- An ad: "Upgrade to Pro to see tasks here."
- A generic illustration with no actionable next step.

### Loading states

Two main approaches:

- **Skeleton screens** — placeholder shapes where content will appear. Best for predictable layouts.
- **Spinners and progress** — generic indicators. Best for short, indeterminate operations.

Choose by predictability: skeletons when you know roughly what will appear; spinners when you don't.

For both: don't show until 200ms have passed. Don't hide for at least 300ms once shown (flicker is worse than slight delay).

### Error states

The most often-neglected state. Errors happen; how you handle them is part of the product.

Good error states:

- **Tell the user what went wrong** in plain language. Not "Error 0x80004005."
- **Tell them what to try** if there's something to try. "Check your network connection and refresh."
- **Don't blame the user** unless they're clearly at fault. Even then, be gentle.
- **Preserve their work**. If the form failed to save, the data should still be in the form.
- **Offer a recovery path**. "Try again," "go back," "contact support."

Bad error states:

- "Something went wrong." (What? What do I do?)
- "Network error" (Whose network? What now?)
- An error that erases the user's input.
- An error that has no path forward.
- An error that blocks the entire app for a problem in one feature.

### Validation states

Inline validation as the user types is the gold standard for forms — but only when done right.

Rules:

- **Validate on blur, not on every keystroke.** Validating "this email is invalid" while the user is still typing it is annoying.
- **Validate positively** when you can — "✓ Available" for username checks.
- **Position errors near the field they refer to**, not in a summary at the top.
- **Use color *and* iconography *and* text** — color alone fails for color-blind users.
- **Don't disable the submit button** to indicate errors. Let them try; show them what's wrong.

## Micro-Interactions

A micro-interaction is the small moment of feedback that confirms an action — the heart that fills when you favorite a tweet, the toggle that slides smoothly between states, the chip that pops in when you add a tag.

Done well, micro-interactions:

- **Confirm the action happened.**
- **Match the magnitude of the action** — a small change gets a small animation; a destructive action gets a noticeable confirmation.
- **Add personality** without becoming a distraction.
- **Improve the perceived quality** of the product.

Done badly:

- **Slow down the user.** Animations that take 800ms are too long; the user wants to move on.
- **Distract from the task.** Bouncy, attention-grabbing animations on a serious task feel inappropriate.
- **Mislead.** A "saving..." indicator that isn't actually tracking saving.
- **Harm accessibility.** Auto-playing animations cause problems for users with vestibular disorders. Always respect `prefers-reduced-motion`.

The rule: **functional first, delightful second.** A micro-interaction's job is to communicate; entertainment is a bonus.

## Common Interaction Patterns

### Click vs hover vs long-press

- **Click / tap** is the primary action. Always available.
- **Hover** can reveal but not trigger primary actions; it doesn't exist on touch.
- **Long-press** is power-user territory; never the only way to do something important.
- **Right-click** is a contextual menu; useful, but offer the same actions elsewhere.

### Drag and drop

Powerful but expensive: requires fine motor control, doesn't work on touch the same way, hidden affordance, accessibility nightmare.

- **Always provide a non-drag alternative** (a "move to" menu, keyboard shortcut, button).
- **Use clear grab handles** so users know what's draggable.
- **Show drop targets explicitly** during the drag.
- **Make the drop forgiving** — large targets, snap-to-grid where helpful.

### Modals and overlays

Use sparingly. Modals interrupt. They should be reserved for:

- **Confirming destructive actions.** "Delete this? It can't be undone."
- **Showing critical information that requires acknowledgment.**
- **Brief focused tasks** that don't need the surrounding context.

Don't use modals for:

- **Multi-step flows.** Use a dedicated page.
- **Optional information.** Use a tooltip or expandable section.
- **Marketing.** "Sign up for our newsletter!" — annoying and ignored.
- **Anything the user didn't initiate.** Auto-popping modals are an antipattern.

When you use a modal:

- **Offer an obvious way to close** (X button, escape key, click outside).
- **Don't trap focus accidentally.** Tab should cycle within the modal.
- **Restore focus** to the triggering element when closed.
- **Use real backdrop** to indicate "this is in front of the rest."

### Forms

The most-used interaction pattern in most products. Forms deserve disproportionate attention.

- **One column, top-aligned labels** is the simplest, most-readable layout.
- **Group related fields** with subtle separators.
- **Sensible default focus** on the first field.
- **Logical tab order.**
- **Clear required vs optional**. Mark whichever is fewer (usually mark optional).
- **Submit button labeled with the action**, not "Submit." "Create Account," "Save Changes," "Send Invitation."
- **Don't disable submit until valid** — let them try, show them what's wrong.
- **Preserve input on errors.** Never wipe a form.
- **Autosave** for long forms; show the save indicator.

### Lists and tables

- **Sortable columns** with clear sort indicators.
- **Filterable** with visible active filters.
- **Pagination or infinite scroll** depending on use — pagination for browsing, infinite scroll for feeds.
- **Empty rows are still rows.** Show what *would* be there.
- **Bulk actions** for power users — but don't make them the primary path.
- **Inline edit** when fast iteration matters; modal edit for complex objects.

### Notifications

Notifications interrupt. Use the lightest interruption that works.

- **Toast / snackbar** for transient feedback ("Saved", "Copied").
- **Banner / alert** for status that affects the whole page.
- **Badge / dot** for waiting attention but not interrupting.
- **Modal** only for critical, blocking notices.

Rules:

- **Auto-dismiss toasts after a few seconds.** Don't make the user click away routine notifications.
- **Don't auto-dismiss errors.** The user might miss them.
- **Position consistently.** Don't put the same kind of notification in different places.

## Anti-Patterns

- **Hover-only interactions.** Invisible on touch.
- **No loading state.** User can't tell if the app is working.
- **Spinner that never resolves.** No success feedback; user can't tell if the action succeeded.
- **Generic error messages.** "Something went wrong." Useless.
- **Form that wipes input on validation error.** Cruel.
- **Disabled submit button as the only error indicator.** User has no idea why it's disabled.
- **Modals that pop up unprompted.** Newsletter signups, reminders to upgrade. Hated.
- **Animations that can't be disabled.** Bad for accessibility.
- **Micro-interactions that take 800ms.** Slow things down.
- **Drag-and-drop with no alternative.** Inaccessible.
- **Click targets smaller than ~44px on touch.** Too small to hit reliably.
- **Auto-advancing carousels.** Users hate them; engagement metrics confirm.
- **"Are you sure?" for every action.** Confirm fatigue. Reserve for genuinely destructive operations.
- **Inconsistent feedback.** Some actions show toasts, others don't, others show modals. Users can't predict.
- **No optimistic UI.** Every action waits for the server; the product feels sluggish.

## Related

- [visual-design-fundamentals.md](visual-design-fundamentals.md) — visual signifiers, hierarchy, color
- [accessibility.md](accessibility.md) — keyboard, screen readers, motion
- [content-and-ux-writing.md](content-and-ux-writing.md) — error and empty state copy
- [wireframing-and-prototyping.md](wireframing-and-prototyping.md) — prototyping interactions
- [design-systems.md](design-systems.md) — interaction patterns as components
