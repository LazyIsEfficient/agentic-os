//! v2 runtime CLI — the thin driver that makes the orchestrator runnable.
//!
//! Per [ADR-001](../docs/ADR-001-v2-runtime.md), all orchestration logic lives
//! in the library ([`v2_runtime::rounds::run`], [`v2_runtime::blackboard`],
//! [`v2_runtime::personas`]). This binary only:
//!
//! - loads `.env` into the process environment (no `dotenv` crate in the
//!   sanctioned deps, so we hand-parse — the orchestrator reads `REDIS_*`,
//!   `BB_PREFIX`, `BB_MAX_ROUNDS`, `BB_MAX_RETRIES`, `BB_TURN_TIMEOUT_SECS`);
//! - parses args (`run --task <path> [--run <id>]`, `inspect <run>`);
//! - derives a [`RuntimeConfig`] from the environment;
//! - connects the blackboard, loads the pod, and hands off to `rounds::run`.
//!
//! Because `rounds::run` auto-resumes via `Blackboard::run_exists`, re-invoking
//! `run` with the same `--run` id continues a crashed run from durable state.

use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{anyhow, Context, Result};
use clap::{Parser, Subcommand};

use v2_runtime::{
    blackboard::{self, Blackboard},
    personas,
    rounds::{self, ClaudeRunner},
    RuntimeConfig,
};

/// v2 multi-agent collaboration runtime driver.
#[derive(Debug, Parser)]
#[command(
    name = "v2-runtime",
    about = "Redis-mediated, orchestrator-clocked agent collaboration runtime (ADR-001).",
    long_about = "Owns the Redis blackboard and the round loop; spawns each agent turn via \
`claude -p` on the Claude Code subscription. Config is read from `.env` / the environment \
(REDIS_HOST/PORT/DB, BB_PREFIX, BB_MAX_ROUNDS, BB_MAX_RETRIES, BB_TURN_TIMEOUT_SECS)."
)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// Run (or resume) a collaboration: load the task seed, build the pod, and
    /// clock rounds until the reviewer approves or the round cap is hit.
    Run {
        /// Path to the task file; its contents become the seed instruction and
        /// its stem seeds the default run id.
        #[arg(long)]
        task: PathBuf,

        /// Run id to use/resume. Defaults to `<task-stem>-<nanos>`. Re-invoking
        /// with the same id auto-resumes a crashed run from durable Redis state.
        #[arg(long)]
        run: Option<String>,
    },

    /// Inspect a run's blackboard (state + artifact + log tail) — debug view.
    Inspect {
        /// The run id to inspect (the `{prefix}:{run}` namespace segment).
        run: String,
    },

    /// Materialize a finished run's artifact HASH (`filename -> content`) to
    /// disk under `--out`, so the emitted work product can be gated by
    /// `scripts/validate.sh`.
    ///
    /// Each artifact key is an UNTRUSTED filename (model output). Every key is
    /// run through a fail-closed path sanitizer before any byte is written: a
    /// key that is absolute, carries a `..` component, or whose resolved path
    /// would escape `--out` aborts the WHOLE materialize with a hard error. No
    /// bad key is silently skipped.
    Materialize {
        /// The run id whose `artifact` HASH to read.
        run: String,

        /// Output directory the artifact files are written under. Created if
        /// absent. Every written path is verified to stay strictly inside it.
        #[arg(long)]
        out: PathBuf,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Load `.env` (REDIS_* / BB_*) into the process env before anything reads it.
    // The library's Redis + timeout config is env-authoritative.
    load_env();

    match cli.command {
        Command::Run { task, run } => cmd_run(&task, run.as_deref()),
        Command::Inspect { run } => cmd_inspect(&run),
        Command::Materialize { run, out } => cmd_materialize(&run, &out),
    }
}

/// `run --task <path> [--run <id>]` — load the seed, build the config, connect
/// the blackboard, load the pod, and drive `rounds::run` with a real
/// [`ClaudeRunner`]. Prints the [`RunOutcome`] on completion.
fn cmd_run(task: &Path, run: Option<&str>) -> Result<()> {
    let seed = std::fs::read_to_string(task)
        .with_context(|| format!("reading task file {}", task.display()))?;
    if seed.trim().is_empty() {
        return Err(anyhow!("task file {} is empty", task.display()));
    }

    let run_id = match run {
        Some(id) => id.to_string(),
        None => default_run_id(task)?,
    };
    let config = config_from_env(run_id.clone());

    eprintln!(
        "run: {prefix}:{run} (max_rounds={max_rounds}, max_retries={max_retries})",
        prefix = config.prefix,
        run = config.run,
        max_rounds = config.max_rounds,
        max_retries = config.max_retries,
    );
    eprintln!("task: {} ({} bytes)", task.display(), seed.len());

    // The Redis url is ignored by the library (env-authoritative); pass "".
    let mut blackboard = Blackboard::connect("", config)
        .context("connecting to the Redis blackboard")?;

    let agents_dir = agents_dir()?;
    let participants = personas::load_pod(&agents_dir)
        .with_context(|| format!("loading the dogfood pod from {agents_dir}"))?;
    eprintln!(
        "pod: {} participants [{}]",
        participants.len(),
        participants
            .iter()
            .map(|p| p.role.as_str())
            .collect::<Vec<_>>()
            .join(", ")
    );

    let runner = ClaudeRunner::new();

    let outcome = rounds::run(&mut blackboard, &participants, &runner, &seed)
        .context("running the collaboration round loop")?;

    println!(
        "outcome: final_round={} approved={}",
        outcome.final_round, outcome.approved
    );
    Ok(())
}

/// `inspect <run>` — connect and print the blackboard debug view for `run`.
fn cmd_inspect(run: &str) -> Result<()> {
    let config = config_from_env(run.to_string());
    let view = blackboard::inspect("", &config)
        .with_context(|| format!("inspecting run {}:{}", config.prefix, config.run))?;
    print!("{view}");
    Ok(())
}

/// `materialize <run> --out <dir>` — connect, read the `artifact` HASH, and
/// write each `filename -> content` entry to a file under `--out`.
///
/// SECURITY (findings-ledger 8ab349069b55c549): artifact keys are untrusted
/// model output. Each key is sanitized fail-closed against the canonicalized
/// `--out` root before any write; the FIRST bad key aborts the whole
/// materialize (no partial, no silent skip). Because resolving an offending
/// key may require the `--out` root to exist on disk, the root is created up
/// front, then every target's parent dir is created lazily before its write.
fn cmd_materialize(run: &str, out: &Path) -> Result<()> {
    let config = config_from_env(run.to_string());
    let mut blackboard = Blackboard::connect("", config.clone())
        .with_context(|| format!("connecting to materialize run {}:{}", config.prefix, run))?;

    let artifact = blackboard
        .read_artifact()
        .with_context(|| format!("reading artifact for run {}:{}", config.prefix, run))?;

    if artifact.is_empty() {
        return Err(anyhow!(
            "artifact for run {}:{} is empty — nothing to materialize (run never produced output?)",
            config.prefix,
            run
        ));
    }

    std::fs::create_dir_all(out)
        .with_context(|| format!("creating output dir {}", out.display()))?;
    // Canonicalize the root ONCE; every key is checked against this real path.
    let root = out
        .canonicalize()
        .with_context(|| format!("canonicalizing output dir {}", out.display()))?;

    // Pass 1 — sanitize EVERY key before writing ANY file, so a single bad key
    // aborts the whole materialize with zero files written from this pass's
    // intent. (Dirs created below are benign; no untrusted content lands.)
    let mut targets: Vec<(PathBuf, &String)> = Vec::with_capacity(artifact.len());
    for (filename, content) in &artifact {
        let dest = sanitize_artifact_path(&root, filename)
            .with_context(|| format!("rejecting unsafe artifact key {filename:?}"))?;
        targets.push((dest, content));
    }

    // Pass 2 — write. Every dest is already proven to be strictly under `root`.
    for (dest, content) in &targets {
        if let Some(parent) = dest.parent() {
            std::fs::create_dir_all(parent)
                .with_context(|| format!("creating parent dir {}", parent.display()))?;
        }
        std::fs::write(dest, content)
            .with_context(|| format!("writing artifact file {}", dest.display()))?;
        eprintln!("wrote {} ({} bytes)", dest.display(), content.len());
    }

    println!(
        "materialized {} file(s) from {}:{} to {}",
        targets.len(),
        config.prefix,
        run,
        root.display()
    );
    Ok(())
}

/// Fail-closed resolution of an UNTRUSTED artifact filename to a path strictly
/// inside `root` (which MUST already be a canonicalized, existing directory).
///
/// Rejects, with a hard error (never a silent skip), any key that is:
/// - empty, or
/// - absolute (`/etc/passwd`), or
/// - carries a `..` (`ParentDir`) or a root/prefix component, or
/// - whose lexically-joined, normalized path escapes `root`.
///
/// The check is purely lexical on top of an already-canonical `root`, so it
/// does not depend on the target file existing yet (it never does at write
/// time) and cannot be defeated by a symlink in a not-yet-created leaf.
fn sanitize_artifact_path(root: &Path, filename: &str) -> Result<PathBuf> {
    use std::path::Component;

    if filename.is_empty() {
        return Err(anyhow!("empty artifact filename"));
    }

    let rel = Path::new(filename);

    // Reject anything that isn't a plain relative path of normal segments.
    for component in rel.components() {
        match component {
            Component::Normal(_) => {}
            Component::CurDir => {} // `./foo` is harmless; skip it.
            Component::ParentDir => {
                return Err(anyhow!(
                    "artifact filename {filename:?} contains a '..' component (path traversal)"
                ));
            }
            Component::RootDir | Component::Prefix(_) => {
                return Err(anyhow!(
                    "artifact filename {filename:?} is absolute (must be relative to --out)"
                ));
            }
        }
    }

    // Lexically build the destination from `root` + the normal segments only.
    let mut dest = root.to_path_buf();
    for component in rel.components() {
        if let Component::Normal(seg) = component {
            dest.push(seg);
        }
    }

    // Defense in depth: the assembled path must still start with `root`. With
    // the component scan above this is belt-and-suspenders, but it catches any
    // platform quirk in path joining and is the invariant the security gate
    // actually requires.
    if !dest.starts_with(root) {
        return Err(anyhow!(
            "artifact filename {filename:?} resolves to {} which escapes --out root {}",
            dest.display(),
            root.display()
        ));
    }
    if dest == root {
        return Err(anyhow!(
            "artifact filename {filename:?} resolves to the --out root itself, not a file"
        ));
    }

    Ok(dest)
}

/// Derive a default run id from the task file stem plus `SystemTime` nanos so
/// repeated runs of the same task don't collide.
fn default_run_id(task: &Path) -> Result<String> {
    let stem = task
        .file_stem()
        .and_then(|s| s.to_str())
        .ok_or_else(|| anyhow!("task path {} has no usable file stem", task.display()))?;
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    Ok(format!("{stem}-{nanos}"))
}

/// Build a [`RuntimeConfig`] from the environment, with the ADR / `.env`
/// defaults when a `BB_*` var is unset or unparseable.
fn config_from_env(run: String) -> RuntimeConfig {
    let defaults = RuntimeConfig::default();
    RuntimeConfig {
        prefix: std::env::var("BB_PREFIX").unwrap_or(defaults.prefix),
        run,
        max_rounds: parse_env_u32("BB_MAX_ROUNDS", defaults.max_rounds),
        max_retries: parse_env_u32("BB_MAX_RETRIES", defaults.max_retries),
    }
}

/// Parse a `u32` from an env var, falling back to `default` when unset or
/// unparseable (a malformed cap must not crash the driver).
fn parse_env_u32(key: &str, default: u32) -> u32 {
    std::env::var(key)
        .ok()
        .and_then(|v| v.trim().parse::<u32>().ok())
        .unwrap_or(default)
}

/// Resolve the dogfood-pod agents dir (`<crate>/../.claude/agents`).
///
/// Mirrors the personas test fixture: the persona files live one level up from
/// the `runtime/` crate, under the repo's `.claude/agents`.
fn agents_dir() -> Result<String> {
    let manifest = env!("CARGO_MANIFEST_DIR");
    let dir = Path::new(manifest)
        .parent()
        .ok_or_else(|| anyhow!("crate manifest dir {manifest} has no parent"))?
        .join(".claude/agents");
    dir.to_str()
        .map(str::to_string)
        .ok_or_else(|| anyhow!("agents dir path is not valid UTF-8: {}", dir.display()))
}

/// Load `<crate>/.env` into the process environment if present.
///
/// Hand-parsed (the sanctioned deps carry no `dotenv` crate). Existing env vars
/// win — a value already set in the shell is not overridden, so a per-invocation
/// override (e.g. `BB_MAX_ROUNDS=1 v2-runtime run ...`) takes precedence over the
/// file. Missing `.env` is not an error (env vars may be set externally).
fn load_env() {
    let manifest = env!("CARGO_MANIFEST_DIR");
    let path = Path::new(manifest).join(".env");
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
            if !k.is_empty() && std::env::var_os(k).is_none() {
                std::env::set_var(k, v);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::sanitize_artifact_path;
    use std::path::Path;

    /// Build a real, canonicalized temp dir to stand in for `--out`. The
    /// sanitizer requires `root` to already exist and be canonical.
    fn temp_root() -> std::path::PathBuf {
        let base = std::env::temp_dir().join(format!(
            "materialize-test-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .map(|d| d.as_nanos())
                .unwrap_or(0)
        ));
        std::fs::create_dir_all(&base).expect("create temp root");
        base.canonicalize().expect("canonicalize temp root")
    }

    // ── Rejected: path traversal must NOT escape --out ─────────────────────

    #[test]
    fn rejects_parent_dir_traversal() {
        let root = temp_root();
        let err = sanitize_artifact_path(&root, "../../etc/passwd")
            .expect_err("'../../etc/passwd' must be rejected");
        let msg = err.to_string();
        assert!(
            msg.contains("'..'") || msg.contains("traversal"),
            "expected a traversal rejection, got: {msg}"
        );
    }

    #[test]
    fn rejects_absolute_path() {
        let root = temp_root();
        let err = sanitize_artifact_path(&root, "/etc/passwd")
            .expect_err("'/etc/passwd' must be rejected");
        assert!(
            err.to_string().contains("absolute"),
            "expected an absolute-path rejection, got: {err}"
        );
    }

    #[test]
    fn rejects_embedded_parent_dir_escape() {
        let root = temp_root();
        // `a/../../b` normalizes above root → must be rejected on the `..`.
        let err = sanitize_artifact_path(&root, "a/../../b")
            .expect_err("'a/../../b' must be rejected");
        let msg = err.to_string();
        assert!(
            msg.contains("'..'") || msg.contains("traversal") || msg.contains("escapes"),
            "expected a traversal/escape rejection, got: {msg}"
        );
    }

    #[test]
    fn rejects_empty_filename() {
        let root = temp_root();
        sanitize_artifact_path(&root, "").expect_err("empty filename must be rejected");
    }

    // ── Accepted: plain relative paths stay strictly under --out ───────────

    #[test]
    fn accepts_plain_filename() {
        let root = temp_root();
        let dest = sanitize_artifact_path(&root, "SKILL.md").expect("'SKILL.md' must be accepted");
        assert_eq!(dest, root.join("SKILL.md"));
        assert!(dest.starts_with(&root));
    }

    #[test]
    fn accepts_nested_relative_path() {
        let root = temp_root();
        let dest =
            sanitize_artifact_path(&root, "nested/ok.md").expect("'nested/ok.md' must be accepted");
        assert_eq!(dest, root.join("nested").join("ok.md"));
        assert!(dest.starts_with(&root));
    }

    #[test]
    fn accepts_curdir_prefixed_path() {
        let root = temp_root();
        // `./SKILL.md` is harmless and should normalize to root/SKILL.md.
        let dest = sanitize_artifact_path(&root, "./SKILL.md").expect("'./SKILL.md' accepted");
        assert_eq!(dest, root.join("SKILL.md"));
    }

    #[test]
    fn root_is_a_valid_prefix_of_every_accepted_dest() {
        let root = temp_root();
        for ok in ["SKILL.md", "nested/ok.md", "a/b/c/d.md"] {
            let dest = sanitize_artifact_path(&root, ok).unwrap_or_else(|e| panic!("{ok}: {e}"));
            assert!(
                dest.starts_with(Path::new(&root)),
                "{ok} -> {} escaped root {}",
                dest.display(),
                root.display()
            );
        }
    }
}
