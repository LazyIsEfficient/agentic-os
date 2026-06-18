//! v2 runtime — Redis-mediated, orchestrator-clocked agent collaboration.
//!
//! Per [ADR-001](../docs/ADR-001-v2-runtime.md): a Rust orchestrator owns the
//! Redis blackboard and the round loop and spawns each agent turn via `claude
//! -p`. Agents are pure — blackboard snapshot in (via prompt), structured
//! [`Contribution`] out (via stdout). This crate root declares the module
//! barrel and defines the shared interface types that the module-fill tasks
//! ([`blackboard`], [`personas`], [`rounds`]) and the integration tests build
//! against.

pub mod blackboard;
pub mod personas;
pub mod rounds;

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

/// The structured output of a single agent turn — the hard interface between
/// `rounds.rs` and each `claude -p` invocation (ADR "Contribution schema").
///
/// The orchestrator instructs every agent to emit exactly this as JSON on
/// stdout, then deserializes it. `BTreeMap` (not `HashMap`) so the artifact-edit
/// ordering is deterministic for replay/transcript stability.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct Contribution {
    /// `filename -> new content` edits to apply to the shared `artifact` HASH.
    #[serde(default)]
    pub artifact_edits: BTreeMap<String, String>,
    /// Free-text rationale appended to the `log` STREAM transcript.
    #[serde(default)]
    pub note: String,
    /// This participant's done vote for the round, recorded in `votes:{round}`.
    #[serde(default)]
    pub approve: bool,
}

/// A round participant derived from a `.claude/agents/*.md` persona file.
///
/// Produced by [`personas::load_pod`] and handed to each `claude -p` turn by
/// the round protocol. `role` is the frontmatter `name`; `system_prompt` is the
/// persona body (frontmatter stripped); `tools` is the declared tool list.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Participant {
    /// Stable role/name (e.g. `technical-pm`, `engineer`, `library-reviewer`).
    pub role: String,
    /// The persona system text fed to `claude -p` (frontmatter stripped).
    pub system_prompt: String,
    /// Declared tool names from the persona frontmatter.
    #[serde(default)]
    pub tools: Vec<String>,
}

/// Blackboard key naming + round/retry caps, sourced from `.env` by the driver.
///
/// Mirrors the ADR schema: keys are namespaced `{prefix}:{run}:{kind}`. Defaults
/// match the ADR (`BB_PREFIX=bb`, `BB_MAX_RETRIES=2`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuntimeConfig {
    /// Key prefix for every blackboard key (`.env` `BB_PREFIX`, default `bb`).
    pub prefix: String,
    /// Per-run namespace segment that isolates one collaboration run.
    pub run: String,
    /// Hard cap on collaboration rounds before the run halts.
    pub max_rounds: u32,
    /// Per-participant re-dispatch attempts on a failed/unparseable turn.
    pub max_retries: u32,
}

impl Default for RuntimeConfig {
    fn default() -> Self {
        Self {
            prefix: "bb".to_string(),
            run: "default".to_string(),
            max_rounds: 8,
            max_retries: 2,
        }
    }
}

impl RuntimeConfig {
    /// `{prefix}:{run}:state` — orchestrator-owned status HASH.
    pub fn state_key(&self) -> String {
        format!("{}:{}:state", self.prefix, self.run)
    }

    /// `{prefix}:{run}:artifact` — shared `filename -> content` work product HASH.
    pub fn artifact_key(&self) -> String {
        format!("{}:{}:artifact", self.prefix, self.run)
    }

    /// `{prefix}:{run}:log` — append-only contribution transcript STREAM.
    pub fn log_key(&self) -> String {
        format!("{}:{}:log", self.prefix, self.run)
    }

    /// `{prefix}:{run}:votes:{round}` — `role -> approve` HASH for one round.
    pub fn votes_key(&self, round: u32) -> String {
        format!("{}:{}:votes:{}", self.prefix, self.run, round)
    }
}
