# Information Architecture

Information architecture is the structure underneath the visible interface — how content and functionality are grouped, named, and made findable. It's the most underrated part of design. Get IA right and the visual layer is easier; get it wrong and no amount of polish can save you.

The reason IA is underrated: when it's good, you don't notice it. The user finds what they need; the navigation makes intuitive sense; the words match what they expected. Nobody compliments invisible work.

The reason IA matters: when it's bad, *every other design effort fails*. The user can't find anything; the team can't agree where new features go; engineers nest things wrongly; documentation contradicts the menu. A bad IA is a tax paid on every interaction with the product.

## What IA Actually Is

IA is the set of decisions about:

- **Grouping** — what belongs together?
- **Labeling** — what do we call things?
- **Navigation** — how do users move between groups?
- **Hierarchy** — what's primary, what's secondary, what's hidden?
- **Search** — what does the user type when they don't know where to look?
- **Findability** — can users find what they need without having seen it before?
- **Understandability** — does the structure match how users think about the domain?

These decisions come *before* visual design, *before* component selection, *before* anything that lives on a screen. The information architecture is the skeleton; the rest is muscle and skin.

## The Mental Model Gap

The most common IA failure: the team's mental model of the system doesn't match the user's mental model. Engineers think in terms of database tables; users think in terms of jobs they're trying to do. When the navigation reflects the database, users can't find anything.

Examples:

| Team mental model | User mental model |
|---|---|
| "Account Settings" | "How do I change my password?" |
| "Reports" | "How did our team do last week?" |
| "Integrations" | "Can I send this to Slack?" |
| "Workspace > Project > Issue" | "That ticket Sam mentioned in the meeting" |
| "Permissions > Roles > Capabilities" | "Why can't Alex see this file?" |

The fix isn't to dumb things down; it's to *match the user's mental model*. The way to do that is to **listen to how users describe the thing**, then use those words and groupings.

## Core Patterns

### Hierarchical / tree

Most software uses a tree: top-level sections, sub-sections, leaves. Familiar, predictable, scales reasonably well.

- **Use when:** content is naturally hierarchical, users navigate by category.
- **Watch out for:** trees deeper than 3 levels — users get lost. Trees with vague top-level categories ("Tools", "Resources", "Misc") that hide everything important.

### Faceted

Items can be classified along multiple independent dimensions; users filter by combining facets. Common in e-commerce and search.

- **Use when:** items have many attributes that users care about; users come from many directions; no single hierarchy is "right."
- **Watch out for:** facet explosion — too many filters paralyzes users. Default views that don't show enough.

### Tag-based / network

Items have many tags; navigation is by tag rather than by location. Common in note-taking apps, knowledge bases.

- **Use when:** items belong in multiple places at once; users find by association rather than by category.
- **Watch out for:** tag chaos — without curation, tags drift, duplicate, contradict. Heavy maintenance cost.

### Sequential / linear

Step-by-step flows: onboarding, checkout, multi-step forms. Users move forward (and sometimes back).

- **Use when:** the work has a defined order; the user shouldn't think about navigation.
- **Watch out for:** flows that don't allow back-out, save-and-resume, or jumping between sections when needed.

### Hub-and-spoke

A central "home" with focused destinations. The user returns to the hub between tasks.

- **Use when:** users do many different things, but each task is short.
- **Watch out for:** the hub becoming a dumping ground for every feature.

Most real products use a *combination* — a top-level hub, hierarchical sections within, faceted lists inside the sections, sequential flows for specific tasks.

## Designing Navigation

### Primary navigation

The most important navigation, always visible. Usually 3–7 top-level destinations. The choices here shape everything else.

Rules:

- **Each label must be obvious to a first-time user.** If you have to explain it, the label is wrong.
- **Use users' words, not the team's.** "Reports" not "Analytics Dashboards"; "Settings" not "Configuration Management."
- **Avoid abstractions.** "Resources," "Tools," "Misc" — these tell the user nothing.
- **Test the labels separately.** Show the labels alone and ask users what they'd find under each. If they can't predict, the labels are wrong.

### Secondary navigation

Sub-sections within a primary destination. Often a sidebar, sometimes tabs, sometimes a second header.

- Same rules as primary, but within the context of the parent.
- Limit depth: a sidebar with 30 items is a wall, not navigation.
- Group related items with subtle separators or headers.

### Utility navigation

Account, search, help, notifications. Usually in the corner, always available, deliberately less prominent than primary.

- Don't put primary functionality here. The "create new" button is primary navigation, not utility.

### Breadcrumbs

Show the user where they are in the hierarchy. Useful in deep trees.

- Use when the structure is genuinely hierarchical and users navigate up.
- Don't use as the only navigation back — also offer a clear "back" or sidebar.

### Search

For any IA above moderate size, search is required, not optional. Many users default to search even when navigation would have worked.

- **Always present.** Visible, accessible, obvious.
- **Forgiving.** Tolerate typos, partial matches, synonyms.
- **Scoped or global.** Both, often. Scoped to the current section by default, with a "search everywhere" toggle.
- **Show structure in results.** "Found in Settings > Account" tells the user where the result lives.

### Filtering and sorting

For lists, the difference between "70 items" and "the 3 items I care about." Critical for any list above ~20 items.

- **Default sort matters most.** Most users won't change it.
- **Filters should be visible**, not hidden in a menu, when they're commonly used.
- **Active filters should be visible too** — clear chips or pills, easy to remove individually.

## Card Sorting and Tree Testing

Two research techniques specifically for IA. See [ux-research/references/research-methods.md](../../ux-research/references/research-methods.md) for the basics.

### Card sorting

Generate the structure: give participants a set of items and ask them to group them.

- **Open card sort:** participants make their own categories. Output: how users naturally group things.
- **Closed card sort:** participants sort into your predefined categories. Output: validation of your structure.
- **Hybrid:** sort into predefined categories with the option to add new ones.

When to use: early IA work, before committing to a structure. Use when your top-level groupings are unclear or contested.

### Tree testing

Validate the structure: give participants a navigation tree (no visual design, just the labels) and ask them to find specific things.

When to use: after card sorting, before building the design. Tells you whether users can find things in your proposed IA.

What to look for in results:

- **Direct success rate:** did they find the right thing?
- **Indirect success rate:** did they find it but only after taking a wrong turn?
- **Failure rate:** did they give up or pick the wrong answer?
- **First click:** which top-level item did they click first? (Often the most diagnostic single metric.)
- **Hesitation:** how long they took. Long pauses signal confusion.

A tree test takes 30 minutes to set up and saves weeks of building the wrong navigation.

## Naming Things

The hardest part of IA is *labels*. A bad label kills a good structure.

### Rules for good labels

- **Use the user's words.** Mine interview transcripts and support tickets for the actual vocabulary.
- **Concrete over abstract.** "Invoices" beats "Financial Documents."
- **Action over object** when the user is doing something. "Send Invoice" beats "Invoice Actions."
- **Plain over clever.** "Settings" is fine. "Workshop" is annoying.
- **One word per concept.** Don't call it "Account" in one place and "Profile" in another and "User Settings" in a third.
- **Test the label in isolation.** If a user can't predict what's behind the label without help, the label is wrong.

### Naming controversies

Common ones, with the answers most often correct:

- **Settings vs Preferences vs Account vs Profile.** "Settings" for app-wide configuration; "Account" for billing/auth; "Profile" for public-facing user info. Don't mix.
- **Logout vs Log out vs Sign out.** Pick one and use it everywhere. The web has settled on "Sign out" for most consumer apps; "Log out" for technical/B2B.
- **Save vs Update vs Apply vs OK.** "Save" for persistent changes; "Apply" for filter/sort/temporary; never use "OK" alone — always say what OK does.
- **Delete vs Remove.** "Delete" is destructive (data is gone). "Remove" can be reversible (item taken out of a list but still exists). Don't use them interchangeably.
- **Cancel vs Close vs Discard.** "Cancel" for "abort the action I was doing"; "Close" for "dismiss this overlay without changing anything"; "Discard" for "throw away the changes I made."

These look pedantic. They're not. Inconsistent labels are one of the most reliable sources of user confusion.

## Common IA Pitfalls

### The "Other" or "Misc" category

When the team can't decide where something goes, they create "Other." Then everything ends up there because nobody knows where to put new things. The "Other" category is a smell — fix the categories.

### Org chart navigation

The structure of the navigation reflects the structure of the team that built it ("Marketing tools," "Product tools," "Sales tools"). Users don't care about your org chart and didn't memorize it.

### Database-shaped navigation

The structure reflects the database schema ("Workspaces > Projects > Boards > Cards"). Engineers love it; users don't think this way.

### Two homes for one feature

The same feature exists under two different navigation paths because two teams couldn't agree. Users don't notice; they just use whichever they find first; analytics fragments; bugs accumulate in both places.

### The hidden essential

The most-used feature is buried two levels deep because it's not "important" by some abstract criterion. If users do it daily, it goes on the front door.

### Navigation that contradicts URL structure

The app's nav says "Reports > Sales Q3" but the URL says `/dashboards/123/views/q3-sales`. Hard to share, hard to bookmark, hard to debug.

### Too many top-level items

12 items in the primary nav. Users can't scan it; everything looks equally weighted. Cut to 5–7 by grouping.

### Too few top-level items

3 items, each containing 40 sub-items. Better than too many, but everything important is one click deep — and one wrong click resets the user.

## Worked Example

Suppose you're designing a project management tool. A first-pass IA:

```
Dashboard         (the home view: my work, recent activity, urgent things)
├── My Tasks
├── Recent Updates
└── Quick Actions

Projects          (browse and manage projects)
├── All Projects
├── My Projects
├── Archived
└── + New Project

Inbox             (everything that needs my attention)
├── Mentions
├── Assigned to me
├── Following
└── Notifications

People            (team and contacts)
├── Team Members
├── Guests
└── Pending Invites

Settings          (account, billing, integrations, preferences)
├── Account
├── Billing
├── Integrations
├── Notifications
└── Workspace
```

Notice:

- **Five top-level items.** Within the 5–7 sweet spot.
- **"Inbox" not "Notifications."** Users come here to handle things, not to look at a list.
- **"My Tasks" inside Dashboard, not in its own top-level item.** Tasks are seen in the context of work, not as a category.
- **Settings at the end.** Users look for it least often, and they know to look at the end or in a corner.
- **No "Tools" or "Resources" or "Misc."**
- **The "+ New Project" action lives near where the user is browsing projects.** Action where context is.

This is illustrative, not prescriptive — but it shows the shape. Test with card sorting and tree testing before committing to anything.

## Anti-Patterns

- **Org chart navigation.** Users don't care what team built what feature.
- **Database schema navigation.** Engineers are not users.
- **The "Other" / "Misc" / "Tools" category.** A smell that the categories are wrong.
- **Inconsistent labels.** "Account" in one place, "Profile" in another, "Settings" in a third.
- **Too many top-level items.** 12 things; nothing prioritized.
- **Hidden essentials.** Most-used feature buried 3 levels deep.
- **Search-only navigation.** "Just type what you want" — only works for users who already know what they're looking for.
- **No search at all.** Forces users to navigate even when they know exactly what they want.
- **Untested labels.** "It's obvious to me." It's not obvious to users.
- **Designed without research.** "Let's just whiteboard the nav." Then users can't find anything.
- **Frozen IA.** Set in stone two years ago; hasn't kept up with the product. Audit yearly.
- **Two homes for the same feature.** Pick one; redirect from the other; commit.
- **URL structure that contradicts navigation.** Confusing to share, debug, and bookmark.

## Related

- [design-process.md](design-process.md) — IA work happens in develop and deliver
- [interaction-design.md](interaction-design.md) — IA gives the structure; interaction design gives the moves through it
- [content-and-ux-writing.md](content-and-ux-writing.md) — labels are content, not decoration
- [accessibility.md](accessibility.md) — landmarks, headings, and skip links rest on solid IA
- [ux-research/references/research-methods.md](../../ux-research/references/research-methods.md) — card sorting and tree testing methodology
- [software-design](../../software-design/SKILL.md) — domain modeling and ubiquitous language ideally match the IA
