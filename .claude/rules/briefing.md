## Briefing subagents — how to write the prompt

A subagent has not seen this conversation, does not know what you have already tried, and does not know why the task matters. Its work is only as good as its brief.

- State the goal and **why it matters** in the first sentence.
- Include exact file paths, line numbers, what to change, what `done` looks like.
- Surface what you already ruled out — saves duplicate work.
- For lookups: give the exact command. For investigations: give the question.
- Cap response length explicitly when you only need a verdict (`"under 200 words"`).
- Never write `"based on your findings, fix the bug"` or `"based on the research, implement it."` That delegates synthesis. Synthesis is your job.
- **Ground the brief in artifacts.** If the task touches existing files, tell the agent explicitly: *"Read X before suggesting changes to it."* An ungrounded brief produces confident hallucinations.

Terse command-style prompts produce shallow generic work. A good brief reads like instructions to a smart colleague who just walked into the room.
