# NORTH_STAR.md — AgenticOS

**Vision**: AgenticOS becomes the leading **token-efficient agentic harness** for complex, long-running engineering and development work.

We win when teams and individuals can run sophisticated, multi-step, high-quality workflows at significantly lower token cost than raw frontier models or naive agent setups — while maintaining (or improving) consistency, reliability, output quality, **and session coherence over long horizons**.

---

## The Problem

Frontier models (Opus 4.8+, etc.) are becoming extremely capable at complex coding and reasoning tasks. Adding more agents or clever communication patterns often delivers **diminishing or zero measurable uplift** on quality for single tasks.

However, even the strongest models have a structural limitation in long sessions: **finite context + compression leads to awareness drift**. They lose fidelity on earlier facts, settled decisions, and existing state. They re-derive things unnecessarily, fail to notice infrastructure that already exists, and repeat patterns that were already ruled out.

These are not generation failures — they are **awareness and persistence failures**. The model has no durable memory except what is explicitly externalized and re-read. In long, multi-step work with a human in the loop, this becomes the dominant source of wasted effort and token burn.

At the same time, the economics are shifting:
- Fixed "unlimited" subscriptions will be replaced by pure per-token pricing.
- Token burn in long-running agent workflows is already the dominant cost driver.
- Most current agent harnesses and multi-agent systems are **not designed** with token efficiency **or long-horizon awareness maintenance** as first-class concerns.

The next competitive advantage will not be "who has the smartest agents."  
It will be **"who can deliver high-conformity, high-quality outcomes at the lowest token cost per unit of useful work — while staying coherent across long sessions."**

---

## Our North Star Outcome

**AgenticOS enables complex coding and engineering workflows that are materially cheaper to run (in tokens) than equivalent work done with raw Claude Code or competing agent frameworks, while preserving or increasing determinism, auditability, output quality, and coherence across long, multi-step sessions.**

We measure success by **tokens per high-quality outcome** and by the ability to maintain awareness and avoid re-work across extended sessions — not by number of agents, number of skills, or raw capability demonstrations.

---

## Core Principles

1. **Token Efficiency is a First-Class Design Constraint**
   - Every architectural decision, skill, and mediator behavior must be evaluated against its impact on token consumption.
   - We default to external state, selective context, and compaction over "just put more in the prompt."

2. **Conformity + Determinism Remain Table Stakes**
   - Structural validation, curated installation, reproducible workflows, and clear invariants are non-negotiable.
   - Token optimization must not come at the expense of predictability or safety.

3. **The Harness Is the Product**
   - AgenticOS is not "more agents." It is the **scaffolding and control layer** around models (the harness).
   - We improve the harness so the model can do more with less context **and maintain better awareness over time**.

4. **Persistent Awareness via External State (Survey Before Act)**
   - The harness must provide mechanisms for live session state, constraints, and existing infrastructure to be externalized and re-read at decision points.
   - "Survey-before-act" (explicitly checking what already exists) should be a default, enforceable habit rather than something the model has to remember to do.
   - We treat re-deriving settled facts or failing to notice existing state as a harness failure, not a model failure.

5. **External State Over Context Stuffing**
   - Prefer files, structured memory, ledgers, and retrieval over keeping everything in the active context window.
   - The mediator and skills should treat the filesystem and persistent artifacts as primary memory.

6. **Measure What Matters**
   - We instrument token usage, context growth, cost-per-outcome, **and awareness/coherence failures** across sessions.
   - Qualitative "feels better" is insufficient. We want observable reductions in tokens and re-work for equivalent (or better) results.

7. **Future-Proof for Per-Token Economics**
   - Design as if every token has a real marginal cost.
   - Build patterns that remain advantageous even as model context windows grow.

---

## What We Optimize For

- **Tokens per high-quality engineering outcome** (primary metric)
- Long-horizon session coherence without awareness drift or re-litigation of settled facts
- Predictable and low variance in token consumption across similar tasks
- Long-running workflows that do not degrade due to context rot
- Early termination / verification of low-value paths
- Selective, high-signal context delivery to agents
- Reusable, auditable skills that are inherently context-efficient

## What We De-prioritize (for now)

- Adding more agents purely for capability exploration (unless they demonstrate clear token, quality, **or coherence** wins)
- Complex inter-agent natural language negotiation protocols that increase token burn
- General-purpose "agent orchestration frameworks" that do not embed strong token discipline and awareness mechanisms
- Chasing raw model capability parity (we ride the frontier models; we do not try to out-reason them with volume)

---

## Key Levers (Where We Focus Energy)

1. **Token-Aware + Awareness-Aware Mediator / Orchestrator**
   - The global JS scope + mediator pattern is a strategic asset.
   - Evolve it to track token budgets, trigger compaction, decide context handoff strategy, **maintain a live session state + constraints document**, and enforce survey-before-act behavior.

2. **Context Lifecycle Management**
   - Skills and hooks for intelligent compaction, summarization, and offloading.
   - Progressive disclosure of tools, skills, and context.
   - Structured memory (findings ledger → proper long-term memory with retrieval).

3. **Live Session State & Survey Discipline**
   - Explicit mechanisms for maintaining a compact, re-readable "state & constraints" document that gets consulted at key decision points.
   - Default patterns that force the model to survey existing state/infrastructure before proposing new work.

4. **External Memory & State as Default**
   - Treat the project filesystem, AGENTS.md-style files, and structured artifacts as the source of truth.
   - Minimize re-transmission of history or large artifacts.

5. **Measurement & Observability**
   - Built-in or easy-to-add token accounting per workflow, per skill, and per agent interaction.
   - Ability to compare "raw Claude Code" vs "AgenticOS harness" on both single tasks **and long multi-step sessions**.
   - Tracking of awareness-related failures (re-deriving, missing existing state, etc.).

6. **Deterministic Guards + Token Efficiency**
   - Validation and pre-commit gates that also protect against token-waste patterns (e.g., overly verbose outputs, unnecessary re-reads, ignoring existing state).

---

## Success Looks Like

- A developer can run a full feature implementation + tests + review workflow using AgenticOS and consume **30-70% fewer tokens** than the same workflow in raw Claude Code, with equal or better final quality and traceability.
- Long, multi-step sessions with a human in the loop stay coherent: settled decisions are not re-litigated, existing infrastructure is noticed and reused, and awareness drift is minimized.
- Token cost becomes a predictable and shrinking part of the total cost of complex work.
- When per-token pricing arrives, AgenticOS users are already operating at a structural cost advantage.
- The project is referenced as an example of **serious harness engineering** focused on economic reality and long-horizon reliability, not just agent hype.

---

## Guardrails While Exploring

- Before adding new multi-agent complexity: Demonstrate (with measurement) that it reduces tokens, improves outcome-per-token, **or measurably improves long-session coherence**.
- Before building new skills: Ask "Does this skill make the overall system more or less token efficient **and more or less coherent** for the workflows it targets?"
- We are willing to be opinionated and say "no" to patterns that increase token burn or awareness drift even if they feel clever.
- We keep the installable, curated, validated nature of the project. Token efficiency and awareness mechanisms should enhance, not erode, conformity.

---

**This document exists to keep us honest.**

When in doubt, ask:  
*"Does this change move us toward delivering higher-quality outcomes at materially lower token cost while preserving structure, predictability, **and long-horizon awareness**?"*

If the answer is not clearly yes, we should question whether it belongs in the harness right now.

---

*Last updated: June 2026 — Token efficiency + long-horizon awareness era*