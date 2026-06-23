---
description: Trust but verify — read the diff and run checks before reporting done.
alwaysApply: true
---

## Verification — trust but verify

A subagent's final message describes intent, not result. Before reporting work as done:

- Read the actual diff (`git diff`, `git status`).
- Run the relevant test, build, or lint locally.
- Spot-check the files the agent claimed to write.

If the agent says "implemented X" and `git status` is clean, the agent did not implement X.
