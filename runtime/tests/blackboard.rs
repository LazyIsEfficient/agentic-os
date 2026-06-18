//! Integration tests for the v2 runtime blackboard, exercising ONLY the public
//! `v2_runtime::` API the CLI driver consumes — against a LIVE Redis on
//! `127.0.0.1:6380` (`runtime/.env`).
//!
//! Discipline (per task brief):
//! - every test uses a unique run id and the `itest` key prefix, so all keys
//!   live under `itest:*` and never collide across tests/processes;
//! - every test installs a [`RunGuard`] that DELETEs its own keys on drop
//!   (including on panic), so a passing OR failing run leaves zero leaked keys.
//!
//! `Blackboard` exposes no DEL, and this task may not edit `src/`, so cleanup
//! uses a throwaway `redis` connection (the crate already depends on `redis`).
//! Connection params come from the same env vars the library reads
//! (`REDIS_HOST`/`REDIS_PORT`/`REDIS_DB`), loaded from `runtime/.env` below.

use std::collections::BTreeMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use redis::Commands;
use v2_runtime::blackboard::{Blackboard, RunStatus};
use v2_runtime::{Contribution, RuntimeConfig};

/// Key prefix for every test run. Chosen so all keys match `itest:*` — the
/// exact glob the brief's leak check runs (`redis-cli -p 6380 keys 'itest:*'`).
const PREFIX: &str = "itest";

/// Load `runtime/.env` (REDIS_HOST/PORT/DB) into the process env once. Hand
/// parsed — no dotenv crate, since `Cargo.toml` is owned by another task and
/// this test crate may not add dev-dependencies. Existing env vars win (so an
/// explicit `set -a; . runtime/.env` in the shell is authoritative).
fn load_env() {
    use std::sync::Once;
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        let manifest = env!("CARGO_MANIFEST_DIR");
        let path = std::path::Path::new(manifest).join(".env");
        let Ok(text) = std::fs::read_to_string(&path) else {
            return;
        };
        for line in text.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            if let Some((k, v)) = line.split_once('=') {
                let (k, v) = (k.trim(), v.trim());
                if std::env::var_os(k).is_none() {
                    std::env::set_var(k, v);
                }
            }
        }
    });
}

/// A unique run id of the form `<nanos>-<pid>-<seq>`. Nanoseconds defend across
/// processes/wall-clock; the atomic seq defends within a process (two runs in
/// the same nanosecond), and pid defends across concurrent test binaries.
fn unique_run(tag: &str) -> String {
    static SEQ: AtomicU64 = AtomicU64::new(0);
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    let seq = SEQ.fetch_add(1, Ordering::SeqCst);
    let pid = std::process::id();
    format!("{tag}-{nanos}-{pid}-{seq}")
}

/// A config under the `itest` prefix with a fresh unique run id.
fn config(tag: &str) -> RuntimeConfig {
    RuntimeConfig {
        prefix: PREFIX.to_string(),
        run: unique_run(tag),
        max_rounds: 8,
        max_retries: 2,
    }
}

/// Deletes every blackboard key a run could create, on drop — including on
/// panic, since drop runs during unwind. This is the leak guard the brief
/// requires: after the test process exits, `keys 'itest:*'` must be empty.
struct RunGuard {
    config: RuntimeConfig,
}

impl RunGuard {
    fn new(config: RuntimeConfig) -> Self {
        Self { config }
    }
}

impl Drop for RunGuard {
    fn drop(&mut self) {
        let host = std::env::var("REDIS_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
        let port = std::env::var("REDIS_PORT").unwrap_or_else(|_| "6379".to_string());
        let db = std::env::var("REDIS_DB").unwrap_or_else(|_| "0".to_string());
        let url = format!("redis://{host}:{port}/{db}");
        let Ok(client) = redis::Client::open(url) else {
            return;
        };
        let Ok(mut conn) = client.get_connection() else {
            return;
        };
        let cfg = &self.config;
        // state / artifact / log + every per-round votes hash up to a generous
        // bound (these tests never exceed a handful of rounds).
        let mut keys = vec![cfg.state_key(), cfg.artifact_key(), cfg.log_key()];
        for r in 0..=64u32 {
            keys.push(cfg.votes_key(r));
        }
        let _: redis::RedisResult<()> = conn.del(keys);
    }
}

/// Connect to the live Redis the library is configured for. Panics with a
/// pointed message if Redis is down, so a missing server is an obvious failure
/// rather than a confusing timeout deep in a test.
fn connect(config: RuntimeConfig) -> Blackboard {
    load_env();
    Blackboard::connect("", config)
        .expect("connect to live Redis (is it up on REDIS_PORT 6380? `. runtime/.env` loaded?)")
}

fn edits(pairs: &[(&str, &str)]) -> BTreeMap<String, String> {
    pairs
        .iter()
        .map(|(k, v)| ((*k).to_string(), (*v).to_string()))
        .collect()
}

/// init_run seeds state + artifact, and read_artifact round-trips the seed plus
/// later write_artifact edits (last-writer-wins per filename).
#[test]
fn init_then_artifact_round_trip() {
    let cfg = config("artifact");
    let _guard = RunGuard::new(cfg.clone());
    let mut bb = connect(cfg.clone());

    let seed = edits(&[("SKILL.md", "seed-skill"), ("README.md", "seed-readme")]);
    bb.init_run("task-artifact", "author the artifact", &seed).expect("init_run");

    // The seed is readable verbatim.
    let after_seed = bb.read_artifact().expect("read seeded artifact");
    assert_eq!(after_seed.get("SKILL.md").map(String::as_str), Some("seed-skill"));
    assert_eq!(after_seed.get("README.md").map(String::as_str), Some("seed-readme"));

    // A later write adds a new file and overwrites an existing one.
    bb.write_artifact(&edits(&[("SKILL.md", "v2-skill"), ("NOTES.md", "notes")]))
        .expect("write_artifact");
    let after_write = bb.read_artifact().expect("read updated artifact");
    assert_eq!(after_write.get("SKILL.md").map(String::as_str), Some("v2-skill"));
    assert_eq!(after_write.get("README.md").map(String::as_str), Some("seed-readme"));
    assert_eq!(after_write.get("NOTES.md").map(String::as_str), Some("notes"));
    assert_eq!(after_write.len(), 3, "exactly the three files written");

    // Initial state HASH reflects a fresh run.
    let state = bb.status().expect("status after init");
    assert_eq!(state.task_id, "task-artifact");
    assert_eq!(state.status, RunStatus::Running);
    assert_eq!(state.round, 0);
    assert_eq!(state.max_rounds, 8);
    assert!(!state.done);
}

fn contribution(note: &str, approve: bool, file_edits: &[(&str, &str)]) -> Contribution {
    Contribution {
        artifact_edits: edits(file_edits),
        note: note.to_string(),
        approve,
    }
}

/// append_log then read_log_tail returns entries oldest-first (chronological),
/// including the `task` entry init_run writes first.
#[test]
fn log_append_then_tail_is_chronological() {
    let cfg = config("log");
    let _guard = RunGuard::new(cfg.clone());
    let mut bb = connect(cfg.clone());

    bb.init_run("task-log", "author the log fixture", &BTreeMap::new()).expect("init_run");

    // Append three contributions across two rounds, in a known order.
    bb.append_log(1, "technical-pm", &contribution("pm-first", false, &[]))
        .expect("append pm");
    bb.append_log(1, "engineer", &contribution("eng-second", false, &[]))
        .expect("append engineer");
    bb.append_log(2, "library-reviewer", &contribution("review-third", true, &[]))
        .expect("append reviewer");

    let tail = bb.read_log_tail(10).expect("read log tail");

    // 1 init `task` entry + 3 contributions.
    assert_eq!(tail.len(), 4, "task entry + three contributions");

    // Oldest-first: the init task entry leads, then the three notes in order.
    assert!(tail[0].contains("orchestrator/task"), "init task entry is first: {:?}", tail[0]);
    let body: Vec<&String> = tail.iter().collect();
    let pm = body.iter().position(|l| l.contains("pm-first")).expect("pm line present");
    let eng = body.iter().position(|l| l.contains("eng-second")).expect("eng line present");
    let rev = body.iter().position(|l| l.contains("review-third")).expect("reviewer line present");
    assert!(pm < eng && eng < rev, "chronological order pm < eng < reviewer: {tail:?}");

    // The contribution lines carry round + role/kind framing per the ADR schema.
    assert!(body[pm].contains("[1 technical-pm/contribution]"), "framing: {}", body[pm]);
    assert!(body[rev].contains("[2 library-reviewer/contribution]"), "framing: {}", body[rev]);

    // `count` bounds the tail to the most-recent N (still returned oldest-first).
    let last_two = bb.read_log_tail(2).expect("read log tail count=2");
    assert_eq!(last_two.len(), 2, "count caps the tail length");
    assert!(last_two[0].contains("eng-second"), "tail(2) starts at eng: {:?}", last_two[0]);
    assert!(last_two[1].contains("review-third"), "tail(2) ends at reviewer: {:?}", last_two[1]);
}

/// record_vote writes role -> approve(0|1) into votes:{round}; reading it back
/// goes through the same public Blackboard handle (votes are an internal HASH,
/// so we verify the call succeeds and votes for distinct roles/rounds coexist).
#[test]
fn record_vote_persists_per_round() {
    let cfg = config("vote");
    let _guard = RunGuard::new(cfg.clone());
    let mut bb = connect(cfg.clone());

    bb.init_run("task-vote", "author the vote fixture", &BTreeMap::new()).expect("init_run");

    bb.record_vote(1, "technical-pm", false).expect("vote pm r1");
    bb.record_vote(1, "library-reviewer", true).expect("vote reviewer r1");
    bb.record_vote(2, "library-reviewer", false).expect("vote reviewer r2");

    // Verify the durable HASH contents via a direct read (the public API has no
    // vote reader; the votes key naming is public on RuntimeConfig).
    let host = std::env::var("REDIS_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = std::env::var("REDIS_PORT").unwrap_or_else(|_| "6379".to_string());
    let db = std::env::var("REDIS_DB").unwrap_or_else(|_| "0".to_string());
    let client = redis::Client::open(format!("redis://{host}:{port}/{db}")).expect("client");
    let mut conn = client.get_connection().expect("conn");

    let r1: BTreeMap<String, String> = conn.hgetall(cfg.votes_key(1)).expect("votes r1");
    assert_eq!(r1.get("technical-pm").map(String::as_str), Some("0"));
    assert_eq!(r1.get("library-reviewer").map(String::as_str), Some("1"));

    let r2: BTreeMap<String, String> = conn.hgetall(cfg.votes_key(2)).expect("votes r2");
    assert_eq!(r2.get("library-reviewer").map(String::as_str), Some("0"));
}

/// status reflects set_round transitions (round, status, done flag).
#[test]
fn status_reflects_set_round() {
    let cfg = config("status");
    let _guard = RunGuard::new(cfg.clone());
    let mut bb = connect(cfg.clone());

    bb.init_run("task-status", "author the status fixture", &BTreeMap::new()).expect("init_run");
    let initial = bb.status().expect("initial status");
    assert_eq!(initial.round, 0);
    assert_eq!(initial.status, RunStatus::Running);
    assert!(!initial.done);

    bb.set_round(3, RunStatus::Running, false).expect("advance to round 3");
    let mid = bb.status().expect("status mid");
    assert_eq!(mid.round, 3);
    assert_eq!(mid.status, RunStatus::Running);
    assert!(!mid.done);

    bb.set_round(3, RunStatus::Done, true).expect("mark done");
    let done = bb.status().expect("status done");
    assert_eq!(done.round, 3);
    assert_eq!(done.status, RunStatus::Done);
    assert!(done.done);

    // run_exists distinguishes an initialized run from an absent one.
    assert!(bb.run_exists().expect("run_exists true for initialized run"));
}

/// run_exists / status are false / error for a never-initialized run id.
#[test]
fn uninitialized_run_has_no_state() {
    let cfg = config("uninit");
    let _guard = RunGuard::new(cfg.clone());
    let mut bb = connect(cfg.clone());

    assert!(!bb.run_exists().expect("run_exists false before init"));
    assert!(bb.status().is_err(), "status errors with no state HASH");
    // resume must refuse a run that was never initialized.
    assert!(
        Blackboard::resume("", cfg.clone()).is_err(),
        "resume refuses an uninitialized run"
    );
}

/// Resume path: write durable state at round N, DROP the handle, then
/// `Blackboard::resume(...)` and assert the round counter and artifact are
/// reconstructed from Redis — nothing lived only in the dropped handle.
#[test]
fn resume_reconstructs_round_and_artifact() {
    let cfg = config("resume");
    let _guard = RunGuard::new(cfg.clone());

    // ---- Pre-crash: initialize, write an artifact, advance to round N. ----
    {
        let mut bb = connect(cfg.clone());
        bb.init_run("task-resume", "author the resume fixture", &BTreeMap::new()).expect("init_run");
        bb.write_artifact(&edits(&[("SKILL.md", "round-n-content"), ("PLAN.md", "the-plan")]))
            .expect("write pre-crash artifact");
        bb.set_round(4, RunStatus::Running, false)
            .expect("advance to round 4");
        // bb dropped here: its Redis connection closes. All state is durable.
    }

    // ---- Resume: re-attach from durable Redis state via the public API. ----
    let mut resumed = Blackboard::resume("", cfg.clone()).expect("resume an initialized run");

    let state = resumed.status().expect("status after resume");
    assert_eq!(state.task_id, "task-resume", "task id reconstructed");
    assert_eq!(state.round, 4, "round N reconstructed from durable state");
    assert_eq!(state.status, RunStatus::Running);
    assert!(!state.done);

    let artifact = resumed.read_artifact().expect("artifact after resume");
    assert_eq!(
        artifact.get("SKILL.md").map(String::as_str),
        Some("round-n-content"),
        "artifact reconstructed after handle drop + resume"
    );
    assert_eq!(artifact.get("PLAN.md").map(String::as_str), Some("the-plan"));
    assert_eq!(artifact.len(), 2);
}

/// inspect() renders state + artifact + log tail for an initialized run.
#[test]
fn inspect_renders_run_snapshot() {
    let cfg = config("inspect");
    let _guard = RunGuard::new(cfg.clone());
    {
        let mut bb = connect(cfg.clone());
        bb.init_run("task-inspect", "author the inspect fixture", &edits(&[("SKILL.md", "hello")]))
            .expect("init_run");
        bb.append_log(1, "technical-pm", &contribution("pm-note", false, &[]))
            .expect("append");
    }
    load_env();
    let dump = v2_runtime::blackboard::inspect("", &cfg).expect("inspect");
    assert!(dump.contains("task-inspect"), "dump names the task: {dump}");
    assert!(dump.contains("SKILL.md"), "dump lists the artifact file: {dump}");
    assert!(dump.contains("pm-note"), "dump includes the log tail: {dump}");
}
