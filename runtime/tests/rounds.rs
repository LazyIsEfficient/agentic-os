//! Integration tests for the v2 runtime round loop, driving `rounds::run`
//! through the PUBLIC `v2_runtime::` API exactly as the CLI driver does, with a
//! deterministic FAKE [`AgentRunner`] standing in for `claude -p`. Runs against
//! a LIVE Redis on `127.0.0.1:6380` (`runtime/.env`).
//!
//! Determinism: the fake returns scripted stdout per call in invocation order —
//! no real `claude -p` (no token spend, no nested agents), no wall-clock, no
//! randomness. Every assertion is on the durable blackboard outcome, never on
//! timing.
//!
//! Hygiene: every test uses a unique run id under the `itest` prefix, and a
//! [`RunGuard`] DELETEs its keys on drop (incl. panic), so `keys 'itest:*'` is
//! empty after the process exits.

use std::cell::RefCell;
use std::collections::{BTreeMap, VecDeque};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{anyhow, Result};
use redis::Commands;
use v2_runtime::blackboard::{Blackboard, RunStatus};
use v2_runtime::rounds::{run, AgentRunner};
use v2_runtime::{Contribution, Participant, RuntimeConfig};

/// Prefix so all keys match the brief's leak glob `itest:*`.
const PREFIX: &str = "itest";

/// The reviewer role whose `approve` vote arms the in-loop done signal. Must
/// match `rounds.rs`'s `REVIEWER_ROLE` (= `personas::POD_ROLES`'s last entry).
const REVIEWER_ROLE: &str = "library-reviewer";

/// Load `runtime/.env` once (REDIS_HOST/PORT/DB). Existing env vars win.
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

/// Unique run id: `<tag>-<nanos>-<pid>-<seq>`.
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

fn config(tag: &str, max_rounds: u32, max_retries: u32) -> RuntimeConfig {
    RuntimeConfig {
        prefix: PREFIX.to_string(),
        run: unique_run(tag),
        max_rounds,
        max_retries,
    }
}

/// Connect to live Redis with config; flushes its keys on drop via the guard.
fn fresh(tag: &str, max_rounds: u32, max_retries: u32) -> (Blackboard, RunGuard) {
    load_env();
    let cfg = config(tag, max_rounds, max_retries);
    let bb = Blackboard::connect("", cfg.clone())
        .expect("connect to live Redis (up on REDIS_PORT 6380? `. runtime/.env` loaded?)");
    (bb, RunGuard { config: cfg })
}

/// Deletes a run's keys on drop, including during panic unwind.
struct RunGuard {
    config: RuntimeConfig,
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
        let mut keys = vec![cfg.state_key(), cfg.artifact_key(), cfg.log_key()];
        for r in 0..=64u32 {
            keys.push(cfg.votes_key(r));
        }
        let _: redis::RedisResult<()> = conn.del(keys);
    }
}

/// A deterministic fake [`AgentRunner`]: returns scripted stdout per call in
/// FIFO invocation order. Interior mutability because the trait takes `&self`.
/// Records the role of each call so tests can assert turn counts and ordering.
struct FakeRunner {
    scripted: RefCell<VecDeque<String>>,
    calls: RefCell<Vec<String>>,
    prompts: RefCell<Vec<String>>,
}

impl FakeRunner {
    fn new(scripted: impl IntoIterator<Item = String>) -> Self {
        Self {
            scripted: RefCell::new(scripted.into_iter().collect()),
            calls: RefCell::new(Vec::new()),
            prompts: RefCell::new(Vec::new()),
        }
    }

    fn call_count(&self) -> usize {
        self.calls.borrow().len()
    }

    fn roles(&self) -> Vec<String> {
        self.calls.borrow().clone()
    }

    fn prompts(&self) -> Vec<String> {
        self.prompts.borrow().clone()
    }
}

impl AgentRunner for FakeRunner {
    fn run_turn(&self, participant: &Participant, prompt: &str) -> Result<String> {
        self.calls.borrow_mut().push(participant.role.clone());
        self.prompts.borrow_mut().push(prompt.to_string());
        self.scripted
            .borrow_mut()
            .pop_front()
            .ok_or_else(|| anyhow!("FakeRunner exhausted its script for {}", participant.role))
    }
}

/// Serialize a Contribution to the JSON the agent would print on stdout.
fn turn(edits: &[(&str, &str)], note: &str, approve: bool) -> String {
    let artifact_edits: BTreeMap<String, String> = edits
        .iter()
        .map(|(k, v)| ((*k).to_string(), (*v).to_string()))
        .collect();
    let c = Contribution {
        artifact_edits,
        note: note.to_string(),
        approve,
    };
    serde_json::to_string(&c).expect("serialize scripted contribution")
}

fn participant(role: &str) -> Participant {
    Participant {
        role: role.to_string(),
        system_prompt: format!("You are the {role}."),
        tools: vec![],
    }
}

/// The ordered pod the round protocol drives: PM -> engineer -> reviewer.
fn pod() -> Vec<Participant> {
    vec![
        participant("technical-pm"),
        participant("engineer"),
        participant(REVIEWER_ROLE),
    ]
}

/// (a) Multi-round artifact accumulation, terminating at the round cap when the
/// reviewer never approves. Round-2 edits overwrite round-1 edits per filename.
#[test]
fn multi_round_accumulates_artifact_until_cap() {
    let (mut bb, _g) = fresh("acc", 2, 0);
    let pod = pod();
    let script = vec![
        turn(&[("SKILL.md", "skill-r1")], "pm r1", false),
        turn(&[("DESIGN.md", "design-r1")], "eng r1", false),
        turn(&[], "review r1", false),
        turn(&[("SKILL.md", "skill-r2")], "pm r2", false),
        turn(&[("NOTES.md", "notes-r2")], "eng r2", false),
        turn(&[], "review r2", false),
    ];
    let runner = FakeRunner::new(script);

    let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run completes to the cap");

    assert_eq!(outcome.final_round, 2, "ran both rounds to the cap");
    assert!(!outcome.approved, "cap termination is not an approval");
    assert_eq!(runner.call_count(), 6, "3 participants * 2 rounds");
    assert_eq!(
        runner.roles(),
        vec![
            "technical-pm", "engineer", REVIEWER_ROLE,
            "technical-pm", "engineer", REVIEWER_ROLE,
        ],
        "ordered PM -> engineer -> reviewer each round"
    );

    // Accumulation: round-1 files persist, round-2 SKILL.md overwrote round-1's.
    let artifact = bb.read_artifact().expect("read artifact");
    assert_eq!(artifact.get("SKILL.md").map(String::as_str), Some("skill-r2"));
    assert_eq!(artifact.get("DESIGN.md").map(String::as_str), Some("design-r1"));
    assert_eq!(artifact.get("NOTES.md").map(String::as_str), Some("notes-r2"));

    let state = bb.status().expect("status");
    assert_eq!(state.status, RunStatus::Done, "cap reached marks the run done-status");
    assert_eq!(state.round, 2);
    assert!(!state.done, "cap-reached leaves the done flag false (not approved)");
}

/// (b) Early done: the reviewer approves in round 1, so the run stops there with
/// approved=true and the done flag set.
#[test]
fn reviewer_approval_ends_run_early() {
    let (mut bb, _g) = fresh("early", 6, 0);
    let pod = pod();
    let script = vec![
        turn(&[("SKILL.md", "draft")], "pm", false),
        turn(&[("SKILL.md", "impl")], "eng", false),
        turn(&[], "lgtm", true), // reviewer approves
    ];
    let runner = FakeRunner::new(script);

    let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run completes");

    assert_eq!(outcome.final_round, 1, "approval in round 1 stops there");
    assert!(outcome.approved, "reviewer approval is an approval");
    assert_eq!(runner.call_count(), 3, "exactly one round of turns");

    let state = bb.status().expect("status");
    assert_eq!(state.status, RunStatus::Done);
    assert!(state.done, "approval sets the done flag");
    // The engineer's edit (last writer of SKILL.md before approval) is durable.
    let artifact = bb.read_artifact().expect("read artifact");
    assert_eq!(artifact.get("SKILL.md").map(String::as_str), Some("impl"));
}

/// (c) Re-dispatch recovery: the PM's first two turns are unparseable garbage;
/// the same participant is retried from the durable snapshot and succeeds on the
/// third attempt, then the run reaches approval.
#[test]
fn redispatch_recovers_from_garbage_turn() {
    let (mut bb, _g) = fresh("redispatch", 1, 2);
    let pod = pod();
    let script = vec![
        "not json at all".to_string(),   // PM attempt 1 -> parse error
        "{ broken json".to_string(),     // PM attempt 2 -> parse error
        turn(&[("SKILL.md", "pm-ok")], "pm recovered", false), // attempt 3 OK
        turn(&[("DESIGN.md", "eng")], "eng", false),
        turn(&[], "approve", true), // reviewer approves -> done
    ];
    let runner = FakeRunner::new(script);

    let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run recovers via re-dispatch");

    assert!(outcome.approved, "run reaches approval after recovery");
    assert_eq!(outcome.final_round, 1);
    // 3 PM attempts + 1 engineer + 1 reviewer = 5 calls.
    assert_eq!(runner.call_count(), 5, "PM retried twice before succeeding");
    assert_eq!(
        runner.roles(),
        vec!["technical-pm", "technical-pm", "technical-pm", "engineer", REVIEWER_ROLE],
        "same participant re-dispatched on failure, then the loop proceeds"
    );

    let artifact = bb.read_artifact().expect("read artifact");
    assert_eq!(artifact.get("SKILL.md").map(String::as_str), Some("pm-ok"));
    assert_eq!(artifact.get("DESIGN.md").map(String::as_str), Some("eng"));

    let state = bb.status().expect("status");
    assert_eq!(state.status, RunStatus::Done);
    assert!(state.done);
}

/// (c') Re-dispatch exhaustion: a participant fails past its retry budget; the
/// run is marked failed and halts with the transcript intact.
#[test]
fn redispatch_exhaustion_marks_failed_and_halts() {
    let (mut bb, _g) = fresh("exhaust", 3, 1);
    let pod = pod();
    // PM succeeds; engineer returns garbage on both allowed attempts (1 + 1 retry).
    let script = vec![
        turn(&[("SKILL.md", "pm")], "pm", false),
        "garbage attempt 1".to_string(),
        "garbage attempt 2".to_string(),
    ];
    let runner = FakeRunner::new(script);

    let err = run(&mut bb, &pod, &runner, "author a skill").expect_err("run halts on exhaustion");
    let msg = format!("{err:#}");
    assert!(
        msg.contains("exhausted its retry budget"),
        "error should name the exhaustion, got: {msg}"
    );
    // PM (1) + engineer attempts (1 + 1 retry = 2) = 3; reviewer never runs.
    assert_eq!(runner.call_count(), 3, "no turns past the exhausted participant");

    let state = bb.status().expect("status");
    assert_eq!(state.status, RunStatus::Failed, "halted run is marked failed");
    // The PM's pre-failure edit survives (partial transcript/artifact intact).
    let artifact = bb.read_artifact().expect("read artifact");
    assert_eq!(artifact.get("SKILL.md").map(String::as_str), Some("pm"));
}

/// (d) Cap termination: every turn parses but the reviewer always rejects, so
/// the run force-terminates at max_rounds (clean stop, not an approval).
#[test]
fn force_terminates_at_round_cap() {
    let max_rounds = 3;
    let (mut bb, _g) = fresh("cap", max_rounds, 0);
    let pod = pod();
    let mut script = Vec::new();
    for r in 0..max_rounds {
        script.push(turn(&[("SKILL.md", &format!("pm-r{r}"))], "pm", false));
        script.push(turn(&[], "eng", false));
        script.push(turn(&[], "review-reject", false));
    }
    let runner = FakeRunner::new(script);

    let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run completes at the cap");

    assert_eq!(outcome.final_round, max_rounds, "runs to the cap");
    assert!(!outcome.approved, "never approved");
    assert_eq!(runner.call_count(), (max_rounds as usize) * 3);

    let state = bb.status().expect("status");
    assert_eq!(state.status, RunStatus::Done, "cap is a clean done-status stop");
    assert_eq!(state.round, max_rounds);
    assert!(!state.done, "cap force-terminate leaves the done flag false");
}

/// (e) REGRESSION (the dogfood bug, through the PUBLIC API): the task instruction
/// must reach every agent's prompt. The old `run()` had no task parameter and
/// seeded the run id as the task, so the agents saw only `[0 orchestrator/task]
/// <run-id>` and refused to author anything. This pins that the verbatim
/// instruction lands in every prompt the runner is handed.
#[test]
fn task_instruction_reaches_agent_prompts() {
    let (mut bb, _g) = fresh("taskprompt", 1, 0);
    let pod = pod();
    let task = "Author a NEW library skill named `widget-wrangler` under .claude/skills/.";
    let script = vec![
        turn(&[("SKILL.md", "draft")], "pm", false),
        turn(&[], "eng", false),
        turn(&[], "lgtm", true), // reviewer approves -> single round
    ];
    let runner = FakeRunner::new(script);

    let outcome = run(&mut bb, &pod, &runner, task).expect("run completes");
    assert!(outcome.approved);

    let prompts = runner.prompts();
    assert_eq!(prompts.len(), 3, "one prompt per participant");
    for (i, prompt) in prompts.iter().enumerate() {
        assert!(
            prompt.contains(task),
            "prompt #{i} must carry the verbatim task instruction; got:\n{prompt}",
        );
        assert!(prompt.contains("## TASK"), "prompt #{i} surfaces a ## TASK section");
    }

    // Durable: the instruction is stored in state, not only the (scrollable) log.
    assert_eq!(bb.task().expect("durable task"), task);
}
