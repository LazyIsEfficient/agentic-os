//! Redis blackboard layer.
//!
//! Owns all blackboard I/O per ADR-001: HASH `state`, HASH `artifact`, STREAM
//! `log`, HASH `votes:{round}`. The orchestrator (`rounds.rs`) is the only
//! caller; agents never touch Redis.
//!
//! Connection parameters are sourced from the environment (`REDIS_HOST`,
//! `REDIS_PORT`, `REDIS_DB`) per ADR-001 / `runtime/.env`. The `_redis_url`
//! argument on `connect`/`resume`/`inspect` is retained for signature
//! compatibility but the env vars are authoritative.

use std::collections::BTreeMap;
use std::env;

use anyhow::{anyhow, Context, Result};
use redis::{Commands, Connection};

use crate::{Contribution, RuntimeConfig};

/// Run lifecycle status mirrored into the `state` HASH `status` field.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RunStatus {
    Running,
    Done,
    Failed,
}

impl RunStatus {
    /// The `state.status` field encoding (`running|done|failed`).
    fn as_str(self) -> &'static str {
        match self {
            RunStatus::Running => "running",
            RunStatus::Done => "done",
            RunStatus::Failed => "failed",
        }
    }

    /// Parse the `state.status` field back into the enum.
    fn from_str(s: &str) -> Result<Self> {
        match s {
            "running" => Ok(RunStatus::Running),
            "done" => Ok(RunStatus::Done),
            "failed" => Ok(RunStatus::Failed),
            other => Err(anyhow!("unknown run status in state HASH: {other:?}")),
        }
    }
}

/// A snapshot of run state read back from the `state` HASH (resume path).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StateView {
    pub task_id: String,
    pub status: RunStatus,
    pub round: u32,
    pub max_rounds: u32,
    pub done: bool,
}

/// Typed handle over one run's blackboard keys, backed by a Redis connection.
pub struct Blackboard {
    /// Key naming + caps for this run.
    pub config: RuntimeConfig,
    /// Live synchronous Redis connection.
    conn: Connection,
}

/// Build a `redis://host:port/db` URL from the environment, with ADR defaults.
///
/// `REDIS_HOST` (default `127.0.0.1`), `REDIS_PORT` (default `6379`), `REDIS_DB`
/// (default `0`). The env vars are authoritative; the `redis_url` argument on
/// the public entry points is ignored in favor of them.
fn url_from_env() -> String {
    let host = env::var("REDIS_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = env::var("REDIS_PORT").unwrap_or_else(|_| "6379".to_string());
    let db = env::var("REDIS_DB").unwrap_or_else(|_| "0".to_string());
    format!("redis://{host}:{port}/{db}")
}

/// Open a synchronous Redis connection from env-derived parameters.
fn open_conn() -> Result<Connection> {
    let url = url_from_env();
    let client = redis::Client::open(url.clone())
        .with_context(|| format!("opening redis client for {url}"))?;
    client
        .get_connection()
        .with_context(|| format!("connecting to redis at {url}"))
}

impl Blackboard {
    /// Connect to Redis (env-configured) and bind to this run's keyspace.
    pub fn connect(_redis_url: &str, config: RuntimeConfig) -> Result<Self> {
        let conn = open_conn()?;
        Ok(Self { config, conn })
    }

    /// Initialize a fresh run: seed `state` (round 0, running, done 0, plus the
    /// durable `task` instruction) and the `artifact` HASH from the task
    /// scaffold; append the `task` log entry.
    ///
    /// `task_id` is the run's stable identifier; `task` is the full instruction
    /// text every agent must see. The instruction is persisted DURABLY as the
    /// `state.task` field (not only the log tail, which scrolls the seed entry
    /// off after a few rounds) so it survives resume and every prompt build.
    pub fn init_run(
        &mut self,
        task_id: &str,
        task: &str,
        seed_artifact: &BTreeMap<String, String>,
    ) -> Result<()> {
        let state_key = self.config.state_key();
        let max_rounds = self.config.max_rounds;
        let state_fields: Vec<(&str, String)> = vec![
            ("task_id", task_id.to_string()),
            ("task", task.to_string()),
            ("status", RunStatus::Running.as_str().to_string()),
            ("round", "0".to_string()),
            ("max_rounds", max_rounds.to_string()),
            ("done", "0".to_string()),
        ];
        self.conn
            .hset_multiple::<_, _, _, ()>(&state_key, &state_fields)
            .with_context(|| format!("HSET {state_key} (init state)"))?;

        if !seed_artifact.is_empty() {
            let artifact_key = self.config.artifact_key();
            let edits: Vec<(&String, &String)> = seed_artifact.iter().collect();
            self.conn
                .hset_multiple::<_, _, _, ()>(&artifact_key, &edits)
                .with_context(|| format!("HSET {artifact_key} (seed artifact)"))?;
        }

        self.xadd_log(0, "orchestrator", "task", task)
            .context("XADD initial task log entry")?;
        Ok(())
    }

    /// Read the durable task instruction from the `state.task` field.
    ///
    /// Set by [`init_run`] and stable across rounds/resume (unlike the log tail,
    /// which scrolls the seed entry off). Returns an empty string if the field
    /// is absent (e.g. a run initialized before this field existed).
    pub fn task(&mut self) -> Result<String> {
        let key = self.config.state_key();
        let task: Option<String> = self
            .conn
            .hget(&key, "task")
            .with_context(|| format!("HGET {key} task"))?;
        Ok(task.unwrap_or_default())
    }

    /// Read the shared artifact HASH (`filename -> content`).
    pub fn read_artifact(&mut self) -> Result<BTreeMap<String, String>> {
        let key = self.config.artifact_key();
        let map: BTreeMap<String, String> = self
            .conn
            .hgetall(&key)
            .with_context(|| format!("HGETALL {key}"))?;
        Ok(map)
    }

    /// Apply a participant's edits to the artifact HASH.
    pub fn write_artifact(&mut self, edits: &BTreeMap<String, String>) -> Result<()> {
        if edits.is_empty() {
            return Ok(());
        }
        let key = self.config.artifact_key();
        let items: Vec<(&String, &String)> = edits.iter().collect();
        self.conn
            .hset_multiple::<_, _, _, ()>(&key, &items)
            .with_context(|| format!("HSET {key} (artifact edits)"))?;
        Ok(())
    }

    /// Append a contribution to the `log` STREAM (round, role, kind, payload).
    ///
    /// The payload is the JSON-serialized contribution so the durable transcript
    /// can be replayed losslessly.
    pub fn append_log(&mut self, round: u32, role: &str, contribution: &Contribution) -> Result<()> {
        let payload =
            serde_json::to_string(contribution).context("serializing contribution for log")?;
        self.xadd_log(round, role, "contribution", &payload)
    }

    /// Internal: one XADD with the ADR field set `{round, role, kind, payload}`.
    fn xadd_log(&mut self, round: u32, role: &str, kind: &str, payload: &str) -> Result<()> {
        let key = self.config.log_key();
        let round_s = round.to_string();
        let fields: [(&str, &str); 4] = [
            ("round", round_s.as_str()),
            ("role", role),
            ("kind", kind),
            ("payload", payload),
        ];
        let _: String = self
            .conn
            .xadd(&key, "*", &fields)
            .with_context(|| format!("XADD {key}"))?;
        Ok(())
    }

    /// Read the tail of the `log` STREAM (last `count` entries, oldest first).
    ///
    /// Each returned line is `[round role/kind] payload` for prompt construction
    /// and replay.
    pub fn read_log_tail(&mut self, count: usize) -> Result<Vec<String>> {
        let key = self.config.log_key();
        // XREVRANGE returns newest-first; take `count`, then reverse to chronological.
        let reply: redis::streams::StreamRangeReply = self
            .conn
            .xrevrange_count(&key, "+", "-", count)
            .with_context(|| format!("XREVRANGE {key} COUNT {count}"))?;

        let mut lines: Vec<String> = reply
            .ids
            .iter()
            .map(|entry| {
                let round = entry.get::<String>("round").unwrap_or_default();
                let role = entry.get::<String>("role").unwrap_or_default();
                let kind = entry.get::<String>("kind").unwrap_or_default();
                let payload = entry.get::<String>("payload").unwrap_or_default();
                format!("[{round} {role}/{kind}] {payload}")
            })
            .collect();
        lines.reverse();
        Ok(lines)
    }

    /// Record one participant's done vote in `votes:{round}`.
    pub fn record_vote(&mut self, round: u32, role: &str, approve: bool) -> Result<()> {
        let key = self.config.votes_key(round);
        let val = if approve { "1" } else { "0" };
        self.conn
            .hset::<_, _, _, ()>(&key, role, val)
            .with_context(|| format!("HSET {key} {role}"))?;
        Ok(())
    }

    /// Whether this run's `state` HASH already exists in Redis.
    ///
    /// Distinguishes "never initialized" (no `state` key) from "initialized at
    /// round 0" — which `status()` cannot, since an absent HASH and a freshly
    /// seeded one both report round 0 after `init_run`. The round loop uses this
    /// to decide between `init_run` (fresh) and resume (re-attach to a crashed
    /// run). Additive: existing signatures are unchanged.
    pub fn run_exists(&mut self) -> Result<bool> {
        let key = self.config.state_key();
        self.conn
            .exists(&key)
            .with_context(|| format!("EXISTS {key} (run_exists check)"))
    }

    /// Read the current run state HASH (used by the resume path).
    pub fn status(&mut self) -> Result<StateView> {
        let key = self.config.state_key();
        let map: BTreeMap<String, String> = self
            .conn
            .hgetall(&key)
            .with_context(|| format!("HGETALL {key}"))?;
        if map.is_empty() {
            return Err(anyhow!("no state HASH at {key} (run not initialized)"));
        }
        Self::state_from_map(&key, &map)
    }

    /// Decode a `state` HASH into a `StateView`.
    fn state_from_map(key: &str, map: &BTreeMap<String, String>) -> Result<StateView> {
        let field = |name: &str| -> Result<&String> {
            map.get(name)
                .ok_or_else(|| anyhow!("state HASH {key} missing field {name:?}"))
        };
        let task_id = field("task_id")?.clone();
        let status = RunStatus::from_str(field("status")?)?;
        let round: u32 = field("round")?
            .parse()
            .with_context(|| format!("parsing state.round in {key}"))?;
        let max_rounds: u32 = field("max_rounds")?
            .parse()
            .with_context(|| format!("parsing state.max_rounds in {key}"))?;
        let done = field("done")?.trim() == "1";
        Ok(StateView {
            task_id,
            status,
            round,
            max_rounds,
            done,
        })
    }

    /// Advance the round counter and persist new status + done flag.
    pub fn set_round(&mut self, round: u32, status: RunStatus, done: bool) -> Result<()> {
        let key = self.config.state_key();
        let fields: Vec<(&str, String)> = vec![
            ("round", round.to_string()),
            ("status", status.as_str().to_string()),
            ("done", if done { "1" } else { "0" }.to_string()),
        ];
        self.conn
            .hset_multiple::<_, _, _, ()>(&key, &fields)
            .with_context(|| format!("HSET {key} (set_round)"))?;
        Ok(())
    }

    /// Re-attach to an existing run from durable Redis state (crash resume).
    ///
    /// Connects (env-configured) and verifies the `state` HASH exists; the
    /// caller then reads `status()`/`read_artifact()` to rebuild in-memory state.
    pub fn resume(_redis_url: &str, config: RuntimeConfig) -> Result<Self> {
        let mut bb = Self::connect(_redis_url, config)?;
        let state_key = bb.config.state_key();
        let exists: bool = bb
            .conn
            .exists(&state_key)
            .with_context(|| format!("EXISTS {state_key} (resume check)"))?;
        if !exists {
            return Err(anyhow!(
                "cannot resume: no state HASH at {state_key} (run never initialized or wrong run id)"
            ));
        }
        Ok(bb)
    }
}

/// Optional debug inspector the bin exposes as `runtime inspect <run>`.
///
/// Dumps `state`, `artifact`, and the `log` tail as a human-readable string.
pub fn inspect(_redis_url: &str, config: &RuntimeConfig) -> Result<String> {
    let mut bb = Blackboard::connect(_redis_url, config.clone())?;
    let mut out = String::new();

    out.push_str(&format!("run: {}:{}\n", config.prefix, config.run));

    match bb.status() {
        Ok(state) => {
            out.push_str("state:\n");
            out.push_str(&format!("  task_id:    {}\n", state.task_id));
            out.push_str(&format!("  status:     {}\n", state.status.as_str()));
            out.push_str(&format!("  round:      {}\n", state.round));
            out.push_str(&format!("  max_rounds: {}\n", state.max_rounds));
            out.push_str(&format!("  done:       {}\n", state.done));
        }
        Err(e) => {
            out.push_str(&format!("state: <unavailable> ({e})\n"));
        }
    }

    let artifact = bb.read_artifact()?;
    out.push_str(&format!("artifact ({} files):\n", artifact.len()));
    for (name, content) in &artifact {
        out.push_str(&format!("  {} ({} bytes)\n", name, content.len()));
    }

    let tail = bb.read_log_tail(20)?;
    out.push_str(&format!("log tail ({} entries):\n", tail.len()));
    for line in &tail {
        out.push_str(&format!("  {line}\n"));
    }

    Ok(out)
}

