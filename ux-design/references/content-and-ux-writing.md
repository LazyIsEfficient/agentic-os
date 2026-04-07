# Content and UX Writing

The words on the screen *are* the design. A perfect layout with the wrong words is broken; an average layout with the right words is usable. Despite this, content is often treated as something marketing or product writes "afterwards" — usually too late to actually fix anything.

This file is about UX writing — the practice of writing the words that appear in interfaces (buttons, labels, errors, empty states, microcopy). It's a craft, it has principles, and it deserves the same care as visual design.

## The Core Principles

### Voice is consistent; tone shifts

- **Voice** is who the product *is*. Plain, friendly, technical, formal. Doesn't change between screens.
- **Tone** is the product's mood in a given moment. Calm during normal use; apologetic when something fails; encouraging during onboarding. Shifts with context.

A product can have a friendly voice and a serious tone during an error. The voice persists; the tone adapts.

Document the voice once, in a one-paragraph statement, and reference it. Examples:

> "We are direct, friendly, and technically credible. We use plain language, prefer active voice, and treat the user as a competent peer. We don't apologize unnecessarily, don't use exclamation points to seem enthusiastic, and don't dress up errors as features."

That paragraph guides every word in the product. Without it, every writer (and every screen) drifts.

### Plain language

The simplest way to write better UX copy: **use plain words**. Not because users are dumb, but because plain words are faster to read, easier to translate, and harder to misinterpret.

| Plain | Less plain |
|---|---|
| Use | Utilize |
| Help | Assistance |
| Find | Locate |
| Send | Transmit |
| Get started | Initiate the process |
| About | Regarding |
| Buy | Purchase |
| Sign up | Register |
| Sign in | Authenticate |
| Done | Completed |
| Soon | In the near future |

The hardest part of plain writing is recognizing when you've drifted. The fix: read your draft out loud. Anything that sounds stilted *is* stilted, even when it looked fine on paper.

### Active voice

> "The form was submitted." → "You submitted the form."
> "An error occurred." → "We couldn't save your changes."
> "The file has been uploaded successfully." → "Your file is uploaded."

Active voice puts the actor first, which makes the sentence shorter, clearer, and more honest about what happened.

Exception: when the *actor isn't important* or *isn't known*, passive voice is fine. "Your account was created on April 7" is clearer than "On April 7, the system created your account."

### Front-load the meaning

People scan, they don't read. The most important word goes first.

| Bad | Better |
|---|---|
| "Click here to download the report." | "Download the report." |
| "Please be aware that your trial expires in 3 days." | "Your trial expires in 3 days." |
| "We'd like to inform you that your password has been changed." | "Your password is changed." |
| "If you would like to continue, click Next." | "Click Next to continue." |

The first version always reads slower. The reader has to wait through the preamble before getting to what matters. Cut the preamble.

### Specific over generic

Generic language slides off the reader. Specifics stick.

| Generic | Specific |
|---|---|
| "Update your settings." | "Choose how often we email you." |
| "Manage your account." | "Change your password, email, or billing." |
| "Get insights into your data." | "See which campaigns drove the most signups last week." |
| "Stay connected." | "Get notified when someone replies." |

Specifics also make the product feel real. Generic copy is what you write when you don't know what the feature does or who it's for. Specific copy is what you write when you do.

## Microcopy by Context

### Buttons

Buttons are the most consequential words in any UI. Get them wrong and users hesitate, click the wrong thing, or undo the action immediately.

Rules:

- **Verb + object.** "Save changes" not "Save." "Send invitation" not "Send."
- **Match the user's action language.** "Create project" because that's what the user is doing.
- **Avoid generic verbs** when you can be specific. "OK" → "Got it." "Submit" → "Place order."
- **Don't lie about consequences.** "Delete forever" if it's permanent. "Move to trash" if it can be undone.
- **Distinguish primary from secondary visually *and* in language.** Primary action is the affirmative; secondary action is the alternative.
- **Avoid stacking imperatives.** A modal with "OK" and "Cancel" is fine. A modal with "Save and continue" and "Discard and continue" forces the user to read carefully.

Bad:

```
[ OK ]    [ Cancel ]
```

What does OK do? What does Cancel discard? Both are ambiguous.

Better:

```
[ Delete account ]    [ Keep account ]
```

The user knows exactly what each button does without reading the modal.

### Error messages

Error messages are the unhappiest moment in the interaction. Make them helpful, not cute.

Rules:

- **Say what went wrong**, in plain language.
- **Say how to fix it** if there's something to do.
- **Don't blame the user** unless they're clearly at fault. Even then, be gentle.
- **Don't apologize excessively.** "We're so sorry to inform you" — overkill. "Couldn't save" — concise.
- **Be specific.** "Your password is too short" is better than "Invalid password."
- **Preserve their work.** Never wipe a form on error.

Bad error messages:

| Error | Why it's bad |
|---|---|
| "Error 0x80004005" | Means nothing to the user |
| "An error occurred" | What error? What now? |
| "Network error" | Whose network? What now? |
| "You did something wrong" | Hostile, vague |
| "Oops! Looks like something went wrong! 😅" | Cute when it shouldn't be |

Better error messages:

| Error | Why it's good |
|---|---|
| "We couldn't save your changes. Check your internet connection and try again." | Specific, actionable |
| "Email is required." | Specific, brief, on the field |
| "Your password needs at least 8 characters." | Specific, tells them what to do |
| "We couldn't reach the payment processor. Your card hasn't been charged. Try again or use a different card." | Specific, reassures them, offers alternatives |

### Empty states

The first impression for new users and the moment of "what now?" after deletion or filtering. Don't waste them.

A useful empty state has:

1. **A clear statement of what's there** ("nothing yet") and *why* ("because you haven't created one").
2. **A primary action** to fix it. ("+ Create your first task")
3. **Optional context** if it'd help. ("Tasks help you track work in this project.")

What to avoid:

- **Blank page.** Looks broken.
- **Generic illustration with no context.** "Cute" but useless.
- **Marketing pitch.** "Upgrade to Pro to see content here." Hostile.
- **Excessive personality.** "Wow, looks like you're new here, friend! Let's get started on this exciting journey!" Patronizing.

Examples:

| Bad | Better |
|---|---|
| "No items." | "No invoices yet. Create your first one to get started." |
| "Empty." | "Your inbox is empty. Notifications will appear here." |
| "Coming soon." | "Reports will appear here as soon as you have data — usually after a few days of usage." |

### Loading states

Brief, factual, no apology needed.

- "Loading..."
- "Saving..."
- "Looking for results..."
- "Almost there..."

What to avoid:

- "Please wait while we get your data" — wordy.
- "Working on it..." — vague.
- Cute mascots that distract from the wait.

### Confirmation messages

Brief, specific, not over-celebratory.

| Action | Good confirmation |
|---|---|
| File uploaded | "Uploaded." or "File uploaded." |
| Email sent | "Sent." or "Email sent to alex@example.com." |
| Settings saved | "Saved." |
| Account created | "Account created. Welcome!" |

For destructive actions, confirmation should mention what happened in case the user wants to undo:

> "Project deleted. [Undo]"

Always offer undo for reversible destructive actions, for at least 5–10 seconds.

### Tooltips and help text

Use sparingly. Every tooltip is a sign that the UI alone wasn't clear enough — sometimes that's appropriate, sometimes it's a bandage on bad UX.

Rules:

- **Don't repeat the visible label.** Tooltip = additional information, not echo.
- **Brief.** A few words to a sentence.
- **Don't hide essential information** in tooltips. Mobile users may not see them; keyboard users have to focus to trigger them.
- **Don't put critical actions** behind a hover.

Use tooltips for:

- Defining unfamiliar terms.
- Explaining icon-only buttons (where the icon isn't universally clear).
- Brief context for fields that need it.

Don't use tooltips for:

- The only documentation of how a feature works.
- Long explanations.
- Marketing.
- Anything the user must read to use the product.

### Onboarding copy

The first words a user sees from your product. They set expectations for everything that follows.

- **Get to the value fast.** Don't make the user read three screens before doing anything.
- **Skip the welcome.** "Welcome to ProductName!" is space the user pays for. Replace with the first useful action.
- **Don't lecture.** Don't explain features the user hasn't asked about yet.
- **Use the user's name** if you have it, but don't be weird about it.
- **Offer skip.** Some users want to dive in.

### Notifications and emails

External communications from the product. Same principles apply, plus:

- **Subject lines describe the action**, not the system. "Sam invited you to Project X" not "You have a new notification."
- **First line continues the subject**. The subject and the preview text tell the whole story.
- **Don't notify for things the user didn't ask to know about.** Notification fatigue is real.
- **Group when sensible.** "5 new comments on Project X" beats 5 separate emails.

## Internationalization (i18n) Considerations

Even if your product is English-only today, write copy that translates well. Translation is a one-way door: copy that's hard to translate now is hard to translate forever.

### Rules for translatable copy

- **Don't concatenate strings** with variables in the middle. "You have N items in your cart" should be one localized string with `{count}`, not "You have " + count + " items".
- **Watch out for plural forms.** Many languages have more plural forms than English (zero, one, few, many, other). Use ICU MessageFormat or equivalent.
- **Avoid puns and idioms.** They don't translate.
- **Avoid culturally specific references.** "It's not rocket science" makes no sense in many languages.
- **Allow space for expansion.** German is ~30% longer than English on average; some languages are even longer. Don't design buttons that fit "OK" exactly.
- **Right-to-left support.** Arabic, Hebrew, etc. The whole layout flips. Plan for it.
- **Date and number formatting.** "1/2/2026" is Jan 2 in the US, Feb 1 in Europe. Use locale-aware formatting.

Even if you're not translating now, writing translation-friendly copy is free. Adding it later is expensive.

## Working with Real Content Early

The single biggest content failure: **lorem ipsum until handoff**. Then the real content is shorter or longer or shaped differently than the design assumed, and the design breaks.

Better practice:

- **Write with real content from the start.** Even rough draft content beats lorem ipsum.
- **Use real-looking data.** Real names, real-looking emails, real-looking dollar amounts.
- **Test the long edge cases.** What if the title is 200 characters? What if the description is empty? What if the price has many digits? Each of these usually breaks something.
- **Pair with a content writer or PM** when content is the question. Don't design content in a vacuum.

## Voice and Tone Examples

A useful exercise: write the same notification three different ways in three different voices.

**Friendly conversational:**
> "We just sent you an email — check your inbox to confirm."

**Direct professional:**
> "Confirmation email sent. Check your inbox."

**Plain neutral:**
> "Sent. Check your email."

Each is fine; each is different. The product's voice picks one style and uses it consistently. Drift between voices makes the product feel disjointed.

A bad version:

> "🎉 Hooray! Your registration is going swimmingly! We've sent you a magical confirmation message — please check your enchanted inbox to verify your account! 🌟"

Don't do this.

## The Content Audit

A useful exercise once a year (or before a major release):

1. **List every piece of microcopy** in the product. Buttons, labels, errors, empty states, tooltips, headers.
2. **Read it as a single document.** Out of order is fine; the goal is to feel the voice.
3. **Mark inconsistencies.** Different terms for the same thing. Different tones for similar moments. Contradictions.
4. **Mark archaisms.** Copy from features that no longer exist as written. Stale references. Old jargon.
5. **Mark opportunities to be more specific or more concise.**
6. **Fix the worst.** Don't try to fix everything; fix the most-used and most-broken.

Audits are the only reliable way to keep voice consistent over years and many writers.

## Anti-Patterns

- **Lorem ipsum until launch.** Real content breaks the design at the worst time.
- **Marketing voice in product UI.** Exclamation points everywhere, exclusionary jargon, "synergies."
- **Generic everywhere.** "Update settings" "Manage account" "Get started." Tells the user nothing.
- **Apologetic excess.** "We're so sorry to bother you, but..." Just say what's happening.
- **Cute errors.** "Whoops!" when a user just lost work. Read the room.
- **Leading questions.** "Don't you want to upgrade?" Manipulative.
- **Forced personality.** "Hey there, friend!" when the user is trying to do work.
- **Dead language.** "Click here," "Read more," "Please enter your input."
- **Inconsistency.** "Save" on one screen, "Update" on another, "Apply" on a third — all doing the same thing.
- **Untranslatable copy.** Concatenated strings, puns, idioms. Locks you into English.
- **Long copy where short would do.** Every extra word is one more thing to scan past.
- **Microcopy that hides essential information** in tooltips or expandable sections.
- **Walls of help text.** If the UI needs paragraphs of explanation, the UI is wrong.
- **Designing without writing.** The buttons say "Button 1" and "Button 2" until handoff. The structure was never tested with real words.
- **Writing without designing.** Copy delivered as a document with no awareness of where it goes; doesn't fit the layout; rewritten in a hurry.

## Related

- [interaction-design.md](interaction-design.md) — error and empty states are interaction patterns
- [accessibility.md](accessibility.md) — plain language is accessible language
- [design-systems.md](design-systems.md) — content patterns belong in the system
- [visual-design-fundamentals.md](visual-design-fundamentals.md) — typography supports content
- [documentation-writer](../../documentation-writer/SKILL.md) — UX writing and product docs share craft
