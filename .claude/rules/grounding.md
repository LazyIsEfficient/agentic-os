## Grounding discipline — agents must read before they claim

The most common failure mode in agentic work is **generate-without-reading**: an agent states facts about files, functions, or state it never actually read. These rules apply to every agent this repo dispatches — no exceptions.

**Agents must:**
1. **Read before claiming.** Before stating what a file contains or what the current state is, the agent must read that artifact. Summary from training data is not reading.
2. **Quote before changing.** Before suggesting a modification to existing code, quote the specific lines being changed. If the quote doesn't match the actual file, the agent is working from a hallucinated copy.
3. **Flag the unverified.** If the agent cannot find evidence for a claim, it must write `UNVERIFIED: ...` and stop. A hedge ("this may be outdated") is not a flag — it's noise that gets ignored.
