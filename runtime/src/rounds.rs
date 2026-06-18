//! Round/wave protocol + re-dispatch + agent-exec.
//!
//! The orchestrator-clocked round loop per ADR-001:
//!
//! - ordered PM → engineer → library-reviewer turns;
//! - build each prompt from persona + blackboard snapshot + log tail;
//! - run the turn through an injected [`AgentRunner`];
//! - parse the [`Contribution`], apply edits, append to `log`, record the vote;
//! - evaluate done (reviewer approve or max-round cap);
//! - re-dispatch a failed turn from the durable snapshot up to the retry cap.

use std::collections::BTreeMap;
use std::io::Read;
use std::process::{Command, Stdio};
use std::time::{Duration, Instant};

use anyhow::{anyhow, Context, Result};

use crate::{
    blackboard::{Blackboard, RunStatus},
    Contribution, Participant,
};

/// Role name (persona frontmatter `name`) whose `approve` vote arms the in-loop
/// done signal. Mirrors `personas::POD_ROLES` (the reviewer is last).
const REVIEWER_ROLE: &str = "library-reviewer";

/// How many recent `log` entries to include in each turn's prompt.
const LOG_TAIL_COUNT: usize = 12;

/// Env var holding the per-turn wall-clock timeout (seconds) for `claude -p`.
const TURN_TIMEOUT_ENV: &str = "BB_TURN_TIMEOUT_SECS";

/// Default per-turn timeout when `BB_TURN_TIMEOUT_SECS` is unset/unparseable.
const DEFAULT_TURN_TIMEOUT_SECS: u64 = 120;

/// How often to poll the child's exit status while waiting for the deadline.
const TURN_POLL_INTERVAL: Duration = Duration::from_millis(50);

/// Resolve the per-turn timeout from `BB_TURN_TIMEOUT_SECS` (default 120s).
///
/// A missing or unparseable value falls back to the default rather than failing
/// the turn — a malformed env var must not silently disable the safety timeout.
fn turn_timeout() -> Duration {
    let secs = std::env::var(TURN_TIMEOUT_ENV)
        .ok()
        .and_then(|v| v.trim().parse::<u64>().ok())
        .unwrap_or(DEFAULT_TURN_TIMEOUT_SECS);
    Duration::from_secs(secs)
}

/// Abstraction over executing one agent turn — the seam that lets tests inject
/// a deterministic fake while production spawns `claude -p` via
/// `std::process::Command`.
pub trait AgentRunner {
    /// Run one turn for `participant` against `prompt`; return raw stdout for
    /// the caller to parse into a [`Contribution`].
    fn run_turn(&self, participant: &Participant, prompt: &str) -> Result<String>;
}

/// Production [`AgentRunner`] that shells out to the headless `claude -p` CLI.
///
/// Runs on the Claude Code subscription (no API key, no metered billing). The
/// prompt is passed as a single positional argument; stdout is captured and
/// returned verbatim for [`parse_contribution`]. A non-zero exit is an error
/// (which the loop treats as a re-dispatchable turn failure).
#[derive(Debug, Clone, Default)]
pub struct ClaudeRunner {
    /// Binary to invoke (defaults to `claude` on `PATH`); injectable for tests
    /// of the spawn path without hitting the real subscription.
    program: Option<String>,
}

impl ClaudeRunner {
    /// A runner that invokes `claude` from `PATH`.
    pub fn new() -> Self {
        Self::default()
    }

    /// A runner that invokes a specific binary path instead of `claude`.
    pub fn with_program(program: impl Into<String>) -> Self {
        Self {
            program: Some(program.into()),
        }
    }

    fn program(&self) -> &str {
        self.program.as_deref().unwrap_or("claude")
    }
}

impl AgentRunner for ClaudeRunner {
    fn run_turn(&self, participant: &Participant, prompt: &str) -> Result<String> {
        let program = self.program();
        let timeout = turn_timeout();

        // Pipe stdio so we can read it after the child exits; a hung child must
        // not block on a full OS pipe buffer either, but for a single short
        // contribution the buffer is ample, and we only read after exit/kill.
        let mut child = Command::new(program)
            .arg("-p")
            .arg(prompt)
            .stdin(Stdio::null())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .with_context(|| {
                format!(
                    "spawning `{program} -p` for participant {role}",
                    role = participant.role
                )
            })?;

        // Poll for exit until the deadline. On timeout, kill the child and return
        // an error so the round loop's re-dispatch budget fires (a hung agent is
        // a turn failure per ADR-001's re-dispatch policy).
        let deadline = Instant::now() + timeout;
        let status = loop {
            match child.try_wait().with_context(|| {
                format!(
                    "polling `{program} -p` for {role}",
                    role = participant.role
                )
            })? {
                Some(status) => break status,
                None => {
                    if Instant::now() >= deadline {
                        // Best-effort kill + reap; ignore errors (child may have
                        // exited in the race between the poll and the kill).
                        let _ = child.kill();
                        let _ = child.wait();
                        return Err(anyhow!(
                            "`{program} -p` for {role} timed out after {secs}s ({env}); re-dispatching",
                            role = participant.role,
                            secs = timeout.as_secs(),
                            env = TURN_TIMEOUT_ENV,
                        ));
                    }
                    std::thread::sleep(TURN_POLL_INTERVAL);
                }
            }
        };

        let mut stdout = Vec::new();
        if let Some(mut out) = child.stdout.take() {
            out.read_to_end(&mut stdout)
                .with_context(|| format!("reading `{program} -p` stdout for {}", participant.role))?;
        }

        if !status.success() {
            let mut stderr = Vec::new();
            if let Some(mut err) = child.stderr.take() {
                let _ = err.read_to_end(&mut stderr);
            }
            let stderr = String::from_utf8_lossy(&stderr);
            return Err(anyhow!(
                "`{program} -p` for {role} exited {code}: {stderr}",
                role = participant.role,
                code = status
                    .code()
                    .map_or_else(|| "signal".to_string(), |c| c.to_string()),
            ));
        }

        String::from_utf8(stdout)
            .with_context(|| format!("`{program} -p` for {} returned non-UTF-8 stdout", participant.role))
    }
}

/// Outcome of a completed run.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RunOutcome {
    /// Round index at which the run terminated.
    pub final_round: u32,
    /// Whether the run reached the in-loop done signal (vs hit the cap).
    pub approved: bool,
}

/// Build the per-turn prompt: the durable task instruction (front and center) +
/// persona system text + artifact snapshot + log tail + role instruction (emit
/// ONLY a JSON [`Contribution`] on stdout).
///
/// `task` is the run's instruction text, surfaced as a `## TASK` section at the
/// very top of EVERY prompt, EVERY round, independent of the log tail (which
/// scrolls the seed entry off). It is READ-ONLY context: it is deliberately NOT
/// rendered into the artifact snapshot, so agents never treat it as a file to
/// overwrite.
pub fn build_prompt(
    participant: &Participant,
    task: &str,
    artifact_snapshot: &str,
    log_tail: &[String],
) -> String {
    let mut prompt = String::new();

    prompt.push_str("## TASK (read-only — the instruction for this run)\n");
    if task.trim().is_empty() {
        prompt.push_str("(no task instruction supplied)\n");
    } else {
        prompt.push_str(task.trim());
        prompt.push('\n');
    }
    prompt.push_str(
        "\nThis TASK is the goal of the collaboration. It is read-only context, \
NOT a file in the shared artifact — do not emit it as an `artifact_edits` entry. \
Every contribution you make must serve this TASK.\n\n",
    );

    prompt.push_str("# Persona\n");
    prompt.push_str(participant.system_prompt.trim());
    prompt.push_str("\n\n");

    prompt.push_str("# Current shared artifact (blackboard)\n");
    if artifact_snapshot.trim().is_empty() {
        prompt.push_str("(empty — no files yet)\n");
    } else {
        prompt.push_str(artifact_snapshot.trim_end());
        prompt.push('\n');
    }
    prompt.push('\n');

    prompt.push_str("# Recent transcript (log tail, oldest first)\n");
    if log_tail.is_empty() {
        prompt.push_str("(empty)\n");
    } else {
        for line in log_tail {
            prompt.push_str(line);
            prompt.push('\n');
        }
    }
    prompt.push('\n');

    prompt.push_str("# Your task this turn\n");
    prompt.push_str(&format!(
        "You are the `{role}` in an iterative pod authoring a library skill. \
Review the artifact and transcript above and make your contribution.\n\n",
        role = participant.role
    ));

    prompt.push_str("# Output contract (STRICT)\n");
    prompt.push_str(
        "Respond with ONE JSON object and NOTHING ELSE — no prose, no markdown \
fences, no leading or trailing text. The object MUST match this schema:\n",
    );
    prompt.push_str(
        "{\n  \"artifact_edits\": { \"<filename>\": \"<full new file content>\" },\n  \
\"note\": \"<short rationale of what you changed and why>\",\n  \
\"approve\": <true|false>\n}\n",
    );
    prompt.push_str(
        "`artifact_edits` is filename -> FULL replacement content (omit a file to \
leave it unchanged; use {} to change nothing). Set `approve` true only when you \
believe the artifact is complete and correct.\n",
    );

    prompt
}

/// Render the artifact HASH as a stable, human-readable snapshot for the prompt.
fn render_artifact(artifact: &BTreeMap<String, String>) -> String {
    let mut out = String::new();
    for (name, content) in artifact {
        out.push_str(&format!("## {name}\n{content}\n\n"));
    }
    out
}

/// Parse a `claude -p` stdout payload into the [`Contribution`] schema.
///
/// Lenient about surrounding whitespace/prose/markdown fences: extracts the
/// first balanced top-level `{...}` JSON object and deserializes it. A response
/// with no parseable object is an `Err` (which the loop treats as a turn failure
/// and re-dispatches).
pub fn parse_contribution(stdout: &str) -> Result<Contribution> {
    let json = extract_json_object(stdout)
        .ok_or_else(|| anyhow!("no JSON object found in agent stdout: {stdout:?}"))?;
    serde_json::from_str::<Contribution>(json)
        .with_context(|| format!("deserializing Contribution from extracted JSON: {json:?}"))
}

/// Find the first balanced top-level `{...}` substring, ignoring braces that
/// appear inside JSON string literals (with escape handling).
fn extract_json_object(s: &str) -> Option<&str> {
    let bytes = s.as_bytes();
    let start = s.find('{')?;
    let mut depth: usize = 0;
    let mut in_string = false;
    let mut escaped = false;

    for (i, &b) in bytes.iter().enumerate().skip(start) {
        if in_string {
            if escaped {
                escaped = false;
            } else if b == b'\\' {
                escaped = true;
            } else if b == b'"' {
                in_string = false;
            }
            continue;
        }
        match b {
            b'"' => in_string = true,
            b'{' => depth += 1,
            b'}' => {
                depth -= 1;
                if depth == 0 {
                    return Some(&s[start..=i]);
                }
            }
            _ => {}
        }
    }
    None
}

/// Run one participant turn against a fresh blackboard snapshot, retrying the
/// SAME participant from a freshly-read snapshot up to `max_retries` on failure
/// (non-zero exit, timeout, or unparseable output).
///
/// Returns the parsed [`Contribution`] on success, or the last error after the
/// retry budget is exhausted.
fn run_turn_with_retry(
    blackboard: &mut Blackboard,
    participant: &Participant,
    runner: &dyn AgentRunner,
    task: &str,
    max_retries: u32,
) -> Result<Contribution> {
    // 1 initial attempt + `max_retries` re-dispatches.
    let attempts = max_retries.saturating_add(1);
    let mut last_err: Option<anyhow::Error> = None;

    for _ in 0..attempts {
        // Re-read the snapshot fresh each attempt: correct after a crash, and
        // keeps re-dispatch deterministic w.r.t. durable Redis state.
        let artifact = blackboard.read_artifact()?;
        let snapshot = render_artifact(&artifact);
        let log_tail = blackboard.read_log_tail(LOG_TAIL_COUNT)?;
        let prompt = build_prompt(participant, task, &snapshot, &log_tail);

        match runner
            .run_turn(participant, &prompt)
            .and_then(|stdout| parse_contribution(&stdout))
        {
            Ok(contribution) => return Ok(contribution),
            Err(e) => last_err = Some(e),
        }
    }

    Err(last_err
        .unwrap_or_else(|| anyhow!("turn for {} failed with no recorded error", participant.role)))
}

/// Run the full collaboration loop to termination (approve or round cap).
///
/// `runner` is injected so tests stay deterministic; production passes
/// [`ClaudeRunner`]. The blackboard is the single source of truth across rounds
/// and crashes: every snapshot is read from Redis, every edit/log/vote is
/// written back before the next turn.
///
/// Init seeds an empty artifact under the configured run id and persists `task`
/// durably (the `state.task` field) so every agent sees the instruction every
/// round; participant edits accumulate the artifact. Done = the
/// `library-reviewer` votes `approve=true` in a round, or `round == max_rounds`.
/// A turn that exhausts its retry budget marks the run `failed` and halts with
/// the transcript intact.
///
/// `task` is the run's instruction text. On a FRESH run it is persisted to the
/// blackboard. On a RESUMED run the durable `state.task` is authoritative and is
/// read back (the supplied `task` is ignored), so the driver need not re-supply
/// the original instruction to continue a crashed run.
pub fn run(
    blackboard: &mut Blackboard,
    participants: &[Participant],
    runner: &dyn AgentRunner,
    task: &str,
) -> Result<RunOutcome> {
    let max_rounds = blackboard.config.max_rounds;
    let max_retries = blackboard.config.max_retries;
    let task_id = blackboard.config.run.clone();

    // Resume-or-init: re-attach to an already-initialized, not-done run instead of
    // clobbering its durable progress. Per ADR-001 "resumability is free" — all
    // state lives in Redis, so a crashed run continues from its last `state.round`
    // with the prior `artifact` + transcript intact. Only seed a fresh run when no
    // prior state HASH exists.
    // The task instruction the prompts use: the supplied `task` on a fresh run,
    // or the durable `state.task` read back on a resumed run (authoritative, so
    // a crashed run continues without the driver re-supplying the instruction).
    let task_instruction: String;
    let start_round: u32 = if blackboard
        .run_exists()
        .context("checking for an existing run on the blackboard")?
    {
        let state = blackboard
            .status()
            .context("reading existing run state for resume")?;
        if state.done || state.status == RunStatus::Done {
            // Already terminated: nothing to resume; report its terminal outcome
            // without re-running any turns.
            return Ok(RunOutcome {
                final_round: state.round,
                approved: state.done,
            });
        }
        // Read the durable task back so resumed rounds still surface it to every
        // agent (the seed log entry may have scrolled off the tail by now).
        task_instruction = blackboard
            .task()
            .context("reading durable task instruction for resume")?;
        // Continue from the round it was working on when it stopped (crash-safe:
        // re-running that round from the durable snapshot is idempotent in effect,
        // since edits are full-content replacements). Floor at 1 for the
        // done-vs-cap comparison; a run seeded at round 0 starts the loop at 1.
        state.round.max(1)
    } else {
        // Init: state(round 0, running, durable task), empty artifact seed,
        // `task` log entry. Persist the instruction so every prompt can carry it.
        blackboard
            .init_run(&task_id, task, &BTreeMap::new())
            .context("initializing run on the blackboard")?;
        task_instruction = task.to_string();
        1
    };

    let mut approved = false;
    let mut final_round: u32 = 0;

    // Rounds are 1-indexed for the done-vs-cap comparison (`round == max_rounds`).
    for round in start_round..=max_rounds {
        final_round = round;
        blackboard
            .set_round(round, RunStatus::Running, false)
            .with_context(|| format!("advancing to round {round}"))?;

        let mut reviewer_approved = false;

        for participant in participants {
            let contribution =
                match run_turn_with_retry(blackboard, participant, runner, &task_instruction, max_retries) {
                    Ok(c) => c,
                    Err(e) => {
                        // Exhausted retries: mark failed, halt with transcript intact.
                        blackboard
                            .set_round(round, RunStatus::Failed, false)
                            .ok();
                        return Err(e.context(format!(
                            "participant {role} exhausted its retry budget in round {round}",
                            role = participant.role
                        )));
                    }
                };

            // Apply edits, append the contribution to the transcript, record the vote.
            blackboard
                .write_artifact(&contribution.artifact_edits)
                .with_context(|| {
                    format!("applying {}'s artifact edits in round {round}", participant.role)
                })?;
            blackboard
                .append_log(round, &participant.role, &contribution)
                .with_context(|| format!("logging {}'s contribution", participant.role))?;
            blackboard
                .record_vote(round, &participant.role, contribution.approve)
                .with_context(|| format!("recording {}'s vote", participant.role))?;

            if participant.role == REVIEWER_ROLE && contribution.approve {
                reviewer_approved = true;
            }
        }

        // Done signal: reviewer approved this round, or we hit the round cap.
        if reviewer_approved {
            approved = true;
            blackboard
                .set_round(round, RunStatus::Done, true)
                .context("marking run done (reviewer approved)")?;
            break;
        }
        if round == max_rounds {
            // Force-terminate at the cap: not an approval, but a clean stop.
            blackboard
                .set_round(round, RunStatus::Done, false)
                .context("marking run done (round cap reached)")?;
            break;
        }
    }

    Ok(RunOutcome {
        final_round,
        approved,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;
    use std::collections::VecDeque;

    /// A deterministic fake runner: returns scripted stdout per call, keyed by
    /// invocation order. No wall-clock, no randomness, no real `claude -p`.
    struct FakeRunner {
        /// FIFO of canned stdout strings, consumed one per `run_turn` call.
        scripted: RefCell<VecDeque<String>>,
        /// Records the role per call for assertions.
        calls: RefCell<Vec<String>>,
        /// Records the full prompt handed to each call, so a test can assert the
        /// task instruction actually reaches the agent (the bug's fingerprint).
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

    fn contribution_json(edits: &[(&str, &str)], note: &str, approve: bool) -> String {
        let mut map = BTreeMap::new();
        for (k, v) in edits {
            map.insert((*k).to_string(), (*v).to_string());
        }
        let c = Contribution {
            artifact_edits: map,
            note: note.to_string(),
            approve,
        };
        serde_json::to_string(&c).unwrap()
    }

    fn participant(role: &str) -> Participant {
        Participant {
            role: role.to_string(),
            system_prompt: format!("You are the {role}."),
            tools: vec![],
        }
    }

    fn pod() -> Vec<Participant> {
        vec![
            participant("technical-pm"),
            participant("engineer"),
            participant(REVIEWER_ROLE),
        ]
    }

    /// Unique per-test run id so tests can share one Redis without key collisions.
    fn unique_run(tag: &str) -> String {
        use std::sync::atomic::{AtomicU64, Ordering};
        static COUNTER: AtomicU64 = AtomicU64::new(0);
        let n = COUNTER.fetch_add(1, Ordering::SeqCst);
        let pid = std::process::id();
        format!("test-{tag}-{pid}-{n}")
    }

    /// Build a fresh blackboard against the live local Redis (`runtime/.env`,
    /// port 6380), and a guard that flushes its keys on drop.
    fn fresh_blackboard(tag: &str, max_rounds: u32, max_retries: u32) -> (Blackboard, RunGuard) {
        load_env();
        let config = crate::RuntimeConfig {
            prefix: "bbtest".to_string(),
            run: unique_run(tag),
            max_rounds,
            max_retries,
        };
        let bb = Blackboard::connect("", config.clone())
            .expect("connect to local Redis (is it up on REDIS_PORT?)");
        let guard = RunGuard {
            config: config.clone(),
        };
        (bb, guard)
    }

    /// Load `runtime/.env` (REDIS_HOST/PORT/DB) into the process env if present.
    /// Hand-parsed (no dotenv crate; Cargo.toml is owned by another task).
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

    /// Flushes a run's blackboard keys on drop so tests leave Redis clean.
    struct RunGuard {
        config: crate::RuntimeConfig,
    }

    impl Drop for RunGuard {
        fn drop(&mut self) {
            // Best-effort cleanup via a throwaway `redis` connection (the
            // crate is already a dependency); `Blackboard` exposes no DEL, and
            // this module may not edit blackboard.rs. Ignore all errors.
            use redis::Commands;
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

    // (a) Multi-round progression accumulating artifact edits, terminating at the cap.
    #[test]
    fn multi_round_accumulates_edits_until_cap() {
        let (mut bb, _g) = fresh_blackboard("multiround", 2, 0);
        let pod = pod();
        // 2 rounds * 3 participants = 6 turns; reviewer never approves.
        let script = vec![
            contribution_json(&[("SKILL.md", "v1-pm")], "pm r1", false),
            contribution_json(&[("DESIGN.md", "eng-r1")], "eng r1", false),
            contribution_json(&[], "review r1", false),
            contribution_json(&[("SKILL.md", "v2-pm")], "pm r2", false),
            contribution_json(&[("NOTES.md", "eng-r2")], "eng r2", false),
            contribution_json(&[], "review r2", false),
        ];
        let runner = FakeRunner::new(script);

        let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run completes");

        assert_eq!(outcome.final_round, 2, "should run both rounds to the cap");
        assert!(!outcome.approved, "cap termination is not an approval");
        assert_eq!(runner.call_count(), 6, "3 participants * 2 rounds");

        // Artifact accumulated edits across rounds; round-2 SKILL.md wins.
        let artifact = bb.read_artifact().expect("read artifact");
        assert_eq!(artifact.get("SKILL.md").map(String::as_str), Some("v2-pm"));
        assert_eq!(artifact.get("DESIGN.md").map(String::as_str), Some("eng-r1"));
        assert_eq!(artifact.get("NOTES.md").map(String::as_str), Some("eng-r2"));

        let state = bb.status().expect("status");
        assert_eq!(state.status, RunStatus::Done);
        assert!(!state.done, "cap-reached sets done flag false (not approved)");
    }

    // (b) Early done when the reviewer approves in round 1.
    #[test]
    fn reviewer_approval_ends_early() {
        let (mut bb, _g) = fresh_blackboard("earlydone", 6, 0);
        let pod = pod();
        let script = vec![
            contribution_json(&[("SKILL.md", "draft")], "pm", false),
            contribution_json(&[("SKILL.md", "impl")], "eng", false),
            contribution_json(&[], "lgtm", true), // reviewer approves
        ];
        let runner = FakeRunner::new(script);

        let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run completes");

        assert_eq!(outcome.final_round, 1, "approval in round 1 stops there");
        assert!(outcome.approved, "reviewer approval is an approval");
        assert_eq!(runner.call_count(), 3, "exactly one round of turns");

        let state = bb.status().expect("status");
        assert_eq!(state.status, RunStatus::Done);
        assert!(state.done, "approval sets the done flag");
    }

    // (c) Re-dispatch: a turn returns an error then garbage then valid JSON; the
    // same participant is retried from the same snapshot and ultimately succeeds.
    #[test]
    fn redispatch_recovers_from_garbage_then_succeeds() {
        let (mut bb, _g) = fresh_blackboard("redispatch", 1, 2);
        let pod = pod();
        // Round 1: PM fails twice (garbage, garbage) then succeeds on attempt 3.
        let script = vec![
            "not json at all".to_string(),       // PM attempt 1 -> parse error
            "{ broken json".to_string(),         // PM attempt 2 -> parse error
            contribution_json(&[("SKILL.md", "pm-ok")], "pm recovered", false), // attempt 3 OK
            contribution_json(&[("DESIGN.md", "eng")], "eng", false),
            contribution_json(&[], "review", true), // reviewer approves -> done
        ];
        let runner = FakeRunner::new(script);

        let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run recovers via re-dispatch");

        assert!(outcome.approved, "run reaches approval after recovery");
        assert_eq!(outcome.final_round, 1);
        // 3 PM attempts + 1 engineer + 1 reviewer = 5 calls.
        assert_eq!(runner.call_count(), 5, "PM retried twice before success");

        let artifact = bb.read_artifact().expect("read artifact");
        assert_eq!(artifact.get("SKILL.md").map(String::as_str), Some("pm-ok"));
    }

    // (c') Re-dispatch exhaustion: a participant fails past its budget -> failed + halt.
    #[test]
    fn redispatch_exhaustion_fails_and_halts() {
        let (mut bb, _g) = fresh_blackboard("exhaust", 3, 1);
        let pod = pod();
        // PM succeeds; engineer returns garbage on both allowed attempts (1 + 1 retry).
        let script = vec![
            contribution_json(&[("SKILL.md", "pm")], "pm", false),
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
        // PM (1) + engineer attempts (2) = 3 calls; reviewer never runs.
        assert_eq!(runner.call_count(), 3);

        let state = bb.status().expect("status");
        assert_eq!(state.status, RunStatus::Failed, "halted run is marked failed");
    }

    // (d) Force-terminate at the round cap with a reviewer that always rejects.
    #[test]
    fn force_terminate_at_round_cap() {
        let max_rounds = 3;
        let (mut bb, _g) = fresh_blackboard("cap", max_rounds, 0);
        let pod = pod();
        // Every turn valid, reviewer always approve=false -> never done early.
        let mut script = Vec::new();
        for r in 0..max_rounds {
            script.push(contribution_json(&[("SKILL.md", &format!("pm-r{r}"))], "pm", false));
            script.push(contribution_json(&[], "eng", false));
            script.push(contribution_json(&[], "review-reject", false));
        }
        let runner = FakeRunner::new(script);

        let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run completes");

        assert_eq!(outcome.final_round, max_rounds, "runs to the cap");
        assert!(!outcome.approved, "never approved");
        assert_eq!(runner.call_count(), (max_rounds as usize) * 3);

        let state = bb.status().expect("status");
        assert_eq!(state.status, RunStatus::Done);
        assert_eq!(state.round, max_rounds);
    }

    // Unit-level: JSON extraction tolerates surrounding prose / fences.
    #[test]
    fn parse_contribution_extracts_embedded_json() {
        let raw = "Sure! Here is my contribution:\n```json\n{\"note\":\"hi\",\"approve\":true,\
\"artifact_edits\":{\"a.md\":\"x\"}}\n```\nLet me know!";
        let c = parse_contribution(raw).expect("extracts embedded object");
        assert!(c.approve);
        assert_eq!(c.note, "hi");
        assert_eq!(c.artifact_edits.get("a.md").map(String::as_str), Some("x"));
    }

    // Unit-level: braces inside string values must not confuse the extractor.
    #[test]
    fn parse_contribution_handles_braces_in_strings() {
        let raw = "{\"note\":\"use {} for empty\",\"approve\":false,\"artifact_edits\":{}}";
        let c = parse_contribution(raw).expect("balanced extraction");
        assert!(!c.approve);
        assert_eq!(c.note, "use {} for empty");
        assert!(c.artifact_edits.is_empty());
    }

    // Unit-level: an unparseable response is an error (drives re-dispatch).
    #[test]
    fn parse_contribution_rejects_non_json() {
        assert!(parse_contribution("absolutely not json").is_err());
        assert!(parse_contribution("").is_err());
    }

    // (e) Cap-vs-approve precedence: the reviewer approves EXACTLY on the final
    // (cap) round. Approval must win over the round-cap force-terminate, so the
    // run ends approved=true / done(flag)=true — NOT a clean-stop cap termination.
    #[test]
    fn approval_on_final_round_beats_cap() {
        let max_rounds = 3;
        let (mut bb, _g) = fresh_blackboard("capapprove", max_rounds, 0);
        let pod = pod();
        // Rounds 1..=2 reject; round 3 (the cap) the reviewer approves.
        let mut script = Vec::new();
        for r in 0..(max_rounds - 1) {
            script.push(contribution_json(&[("SKILL.md", &format!("pm-r{r}"))], "pm", false));
            script.push(contribution_json(&[], "eng", false));
            script.push(contribution_json(&[], "review-reject", false));
        }
        // Final (cap) round: reviewer approves.
        script.push(contribution_json(&[("SKILL.md", "pm-final")], "pm", false));
        script.push(contribution_json(&[], "eng", false));
        script.push(contribution_json(&[], "lgtm", true));
        let runner = FakeRunner::new(script);

        let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("run completes");

        assert_eq!(outcome.final_round, max_rounds, "approval lands on the cap round");
        assert!(
            outcome.approved,
            "approval on the cap round is an approval, not a cap force-terminate"
        );
        assert_eq!(runner.call_count(), (max_rounds as usize) * 3);

        let state = bb.status().expect("status");
        assert_eq!(state.status, RunStatus::Done);
        assert!(
            state.done,
            "approval sets the done flag even on the final round (cap does not)"
        );
    }

    // (f) Crash resume: a run that stopped mid-flight (state.round=2, not done)
    // continues from round 2 with the prior artifact intact — NOT re-init from 0.
    #[test]
    fn resume_continues_from_crashed_round() {
        let (mut bb, _g) = fresh_blackboard("resume", 4, 0);

        // Simulate a crash AFTER round 2: durable state at round 2 (running, not
        // done), with an artifact written by the pre-crash work.
        bb.init_run(&bb.config.run.clone(), "author a skill", &BTreeMap::new())
            .expect("init pre-crash run");
        let mut seed = BTreeMap::new();
        seed.insert("SKILL.md".to_string(), "from-round-2".to_string());
        bb.write_artifact(&seed).expect("seed pre-crash artifact");
        bb.set_round(2, RunStatus::Running, false)
            .expect("mark crashed at round 2");

        // Re-invoke run(): must resume from round 2, not clobber to round 0.
        // Rounds 2,3,4 each run 3 turns; reviewer never approves -> cap at 4.
        let pod = pod();
        let mut script = Vec::new();
        for r in 2..=4u32 {
            script.push(contribution_json(&[("SKILL.md", &format!("pm-r{r}"))], "pm", false));
            script.push(contribution_json(&[], "eng", false));
            script.push(contribution_json(&[], "review", false));
        }
        let runner = FakeRunner::new(script);

        // Pass a DIFFERENT task here on resume: the durable `state.task` set at
        // init is authoritative, so this supplied value is ignored.
        let outcome = run(&mut bb, &pod, &runner, "IGNORED-on-resume").expect("resumed run completes");

        // 3 rounds (2,3,4) * 3 participants = 9 turns — NOT 12 (would be rounds 1..4).
        assert_eq!(runner.call_count(), 9, "resumed from round 2, not round 0/1");
        assert_eq!(outcome.final_round, 4, "runs to the cap from the resume point");
        assert!(!outcome.approved, "reviewer never approved");

        // The pre-crash artifact survived the resume (round 2 overwrote SKILL.md
        // with its own edit, proving the round actually ran from the durable state).
        let artifact = bb.read_artifact().expect("read artifact");
        assert_eq!(artifact.get("SKILL.md").map(String::as_str), Some("pm-r4"));

        let state = bb.status().expect("status");
        assert_eq!(state.status, RunStatus::Done);
        assert_eq!(state.round, 4);
    }

    // (g) An already-done run is reported terminal without re-running any turns.
    #[test]
    fn resume_of_done_run_is_a_noop() {
        let (mut bb, _g) = fresh_blackboard("resumedone", 4, 0);
        bb.init_run(&bb.config.run.clone(), "author a skill", &BTreeMap::new())
            .expect("init run");
        bb.set_round(3, RunStatus::Done, true)
            .expect("mark already done");

        let pod = pod();
        // Empty script: if run() tried to execute any turn, FakeRunner would error.
        let runner = FakeRunner::new(Vec::<String>::new());
        let outcome = run(&mut bb, &pod, &runner, "author a skill").expect("done run reports terminal outcome");

        assert_eq!(runner.call_count(), 0, "no turns run for an already-done run");
        assert_eq!(outcome.final_round, 3);
        assert!(outcome.approved, "done flag was set -> approved");
    }

    // (h) REGRESSION (the dogfood bug): the task instruction must reach EVERY
    // agent, in EVERY prompt — not just the run id, and not only via a log entry
    // that scrolls off. The old `run()` had no task parameter and seeded the
    // run-id as the task, so agents never saw the instruction. This pins that the
    // exact instruction string appears in the prompt the runner is handed.
    #[test]
    fn task_instruction_reaches_every_agent_prompt() {
        let (mut bb, _g) = fresh_blackboard("taskinprompt", 1, 0);
        let pod = pod();
        let task = "Author a NEW library skill named `widget-wrangler` under .claude/skills/.";
        let script = vec![
            contribution_json(&[("SKILL.md", "draft")], "pm", false),
            contribution_json(&[], "eng", false),
            contribution_json(&[], "lgtm", true), // reviewer approves -> one round
        ];
        let runner = FakeRunner::new(script);

        let outcome = run(&mut bb, &pod, &runner, task).expect("run completes");
        assert!(outcome.approved);

        let prompts = runner.prompts();
        assert_eq!(prompts.len(), 3, "one prompt per participant this round");
        for (i, prompt) in prompts.iter().enumerate() {
            assert!(
                prompt.contains(task),
                "prompt #{i} ({role}) must carry the verbatim task instruction; \
got prompt:\n{prompt}",
                role = pod[i].role,
            );
            assert!(
                prompt.contains("## TASK"),
                "prompt #{i} must surface the task in a prominent ## TASK section",
            );
            // The task is read-only context, NOT a seeded artifact file: it must
            // not show up in the artifact-snapshot region (between the artifact
            // heading and the transcript heading). It legitimately appears in the
            // `## TASK` block above and in the log tail below — those are fine.
            let art_start = prompt
                .find("# Current shared artifact")
                .expect("prompt has an artifact section");
            let art_end = prompt[art_start..]
                .find("# Recent transcript")
                .map(|rel| art_start + rel)
                .expect("prompt has a transcript section after the artifact");
            assert!(
                !prompt[art_start..art_end].contains(task),
                "task must not be rendered into the artifact snapshot (read-only)",
            );
        }

        // It is also persisted durably (survives the log tail scrolling).
        assert_eq!(bb.task().expect("read durable task"), task);
    }
}
