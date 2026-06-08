# Round Structure

```
Round 1:
  → Generate 10 variants of the element
  → Batch-score all 10 with the 5-expert panel (1 API call)
  → Rank by average score
  → Keep top 3

Round 2 (Evolution):
  → Analyze what the top 3 did right
  → Generate 10 new variants that push those winning patterns further
  → Batch-score all 10 (1 API call)
  → Keep top 3

Round 3 (If score < threshold):
  → Identify weakest scoring dimension
  → Generate 10 variants optimized for that dimension
  → Batch-score → keep top 1

Multi-element cross-breeding:
  → Take top 1 winner from each element
  → Generate 5 combinations that mix winning elements
  → Score holistically as complete units
  → Output the single best combination
```

**Stop condition:** Top variant hits minimum score threshold (default: 80) OR 3 rounds complete.

## Expert Panel (5 Personas)

Score every variant against all 5. Batch all variants into a **single API call** per round.

| # | Persona | Scoring Lens |
|---|---------|-------------|
| 1 | **CMO at a mid-market B2B company (50M+ revenue)** | "Would this make me stop and engage?" |
| 2 | **Skeptical founder** | "Do I believe this? Would I trust this company?" |
| 3 | **Conversion rate optimizer** | "Is this clear, specific, and action-driving?" |
| 4 | **Senior copywriter** | "Is this compelling, differentiated, and well-crafted?" |
| 5 | **Your CEO/founder** | "Direct, ROI-obsessed, no BS. Would I put this on my site?" |

> **Customization:** Replace persona #5 with your own CEO/founder voice. Define their priorities and communication style inline when you run the panel — e.g. "Persona #5 is our CEO: direct, ROI-obsessed, allergic to jargon, asks 'would I put this on my own site?'" Swap in the priorities, pet peeves, and tone that match the actual decision-maker.

Each judge scores 0–100. **Final score = average across all 5 judges.**
