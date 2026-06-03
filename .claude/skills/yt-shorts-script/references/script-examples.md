# Example Scripts

## Talking head — "Most engineers skip CLAUDE.md"

```
FORMAT: talking-head

─── 60s SCRIPT ──────────────────────────────────────

HOOK [0–5s]
SAY: "Most engineers using Claude Code are missing the one file that makes it 10x better."
SHOW: Text overlay — "THE FILE YOU'RE MISSING"

BODY [5–50s]
[0:05] SAY: "It's called CLAUDE.md. It lives at your repo root."
       SHOW: Text overlay — "CLAUDE.md" large, then subtitle "repo root"

[0:15] SAY: "Without it, Claude starts every session cold. No context, no rules, no memory of your codebase."
       SHOW: Text overlay — "Cold start every time ❌"

[0:30] SAY: "With it, Claude knows your stack, your naming conventions, your banned patterns — before you type a word."
       SHOW: Text overlay — "Instant context ✓"

[0:44] SAY: "Three sections. 30 lines. That's it."
       SHOW: Text overlay — "3 sections. 30 lines."

CTA [50–60s]
SAY: "I've published mine. Link in bio. Follow for the next one."
SHOW: End card with @handle
```

```
─── 30s CUT ─────────────────────────────────────────

HOOK [0–4s]
SAY: "You're using Claude Code without CLAUDE.md. That's the problem."
SHOW: Text overlay — "THE FILE YOU'RE MISSING"

BODY [4–24s]
[0:04] SAY: "Without it, Claude starts every session cold. No context, no rules."
       SHOW: Text overlay — "Cold start every time ❌"

[0:14] SAY: "With it: instant context. Three sections, 30 lines."
       SHOW: Text overlay — "3 sections. 30 lines. ✓"

CTA [24–30s]
SAY: "Link in bio. Follow for more."
SHOW: End card with @handle
```

---

## Screen-record — "How I start every Claude Code session"

```
FORMAT: screen-record

─── 60s SCRIPT ──────────────────────────────────────

HOOK [0–5s]
SAY: "Here's how I start every Claude Code session. Most people skip step one."
SHOW: Screen-record — terminal open, blank Claude Code session

BODY [5–50s]
[0:05] SAY: "First, I check MEMORY.md. That's the index of everything Claude needs to remember across sessions."
       SHOW: Screen-record — open .claude/memory/MEMORY.md, scroll through entries slowly

[0:18] SAY: "Then I open the task file. One task per session — not ten."
       SHOW: Screen-record — open tasks/ directory, click one task file

[0:30] SAY: "Claude reads the task, reads the memory, then I type one word: 'go'."
       SHOW: Screen-record — type "go" and hit enter, show Claude starting output

[0:44] SAY: "That handoff is the whole workflow. Context in, work out."
       SHOW: Screen-record — Claude generating, zoom to first response line

CTA [50–60s]
SAY: "Full breakdown on Substack. Link in bio."
SHOW: Screen-record — browser tab with Substack post visible briefly, then end card
```

```
─── 30s CUT ─────────────────────────────────────────

HOOK [0–4s]
SAY: "My Claude Code session start — most people skip step one."
SHOW: Screen-record — terminal, blank session

BODY [4–24s]
[0:04] SAY: "Check MEMORY.md first. That's Claude's context across sessions."
       SHOW: Screen-record — open MEMORY.md, highlight entries

[0:14] SAY: "One task file. Type 'go'. That's the entire handoff."
       SHOW: Screen-record — task file open, type "go", first Claude response appears

CTA [24–30s]
SAY: "Full breakdown linked in bio. Follow for more."
SHOW: End card with @handle
```

---

## Text-on-screen — "3 Claude Code mistakes"

```
FORMAT: text-on-screen

─── 60s SCRIPT ──────────────────────────────────────

HOOK [0–5s]
SAY: "Three Claude Code mistakes that are costing you time."
SHOW: Text card — "3 MISTAKES" bold, dark background, white text, hard cut in

BODY [5–50s]
[0:05] SAY: "One: no CLAUDE.md. You're starting every session from scratch."
       SHOW: Text card — "MISTAKE 1" / "No CLAUDE.md" / "Cold start every session"

[0:18] SAY: "Two: giant prompts. One task per session, not ten."
       SHOW: Text card — "MISTAKE 2" / "Giant prompts" / "One task = one session"

[0:32] SAY: "Three: skipping the review gate. Subagents write intent, not results. Read the diff."
       SHOW: Text card — "MISTAKE 3" / "Skipping review" / "Read the diff"

[0:46] SAY: "Fix all three. Ship faster."
       SHOW: Text card — "FIX ALL 3" bold, green accent color

CTA [50–60s]
SAY: "Follow. I'm publishing the full system on Substack."
SHOW: Text card — @handle large + "FOLLOW" CTA below

─── 30s CUT ─────────────────────────────────────────

HOOK [0–4s]
SAY: "Three Claude Code mistakes."
SHOW: Text card — "3 MISTAKES" bold

BODY [4–24s]
[0:04] SAY: "No CLAUDE.md — cold start every session."
       SHOW: Text card — "MISTAKE 1: No CLAUDE.md"

[0:14] SAY: "Giant prompts. Skipping the review gate."
       SHOW: Text card — "MISTAKE 2 + 3" listed vertically

CTA [24–30s]
SAY: "Fix these. Follow for the full breakdown."
SHOW: Text card — @handle + "FOLLOW"
```
