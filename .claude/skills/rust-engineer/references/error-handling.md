# Error Handling Reference

## The Fundamental Split: Library vs Application

The single most important decision in Rust error handling is which crate type you are in.

| Context | Goal | Tool |
|---|---|---|
| Library crate | Typed errors callers can `match` on | `thiserror` |
| Application / binary | Context chains for humans and logs | `anyhow` |

**Never use `anyhow::Error` as a library return type.** It erases the concrete type, so callers cannot match on it, pattern-dispatch on variants, or make recovery decisions. You are shipping opaque blobs instead of a contract.

---

## thiserror

### `#[derive(Error)]`

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum StoreError {
    #[error("record {id} not found")]
    NotFound { id: u64 },

    #[error("invalid key: {0}")]          // {0} = tuple field
    InvalidKey(String),

    #[error("backend unavailable")]
    Backend(#[from] sqlx::Error),         // #[from] wires From + #[source]
}
```

### `#[from]`

`#[from]` on a field does two things at once:
1. Implements `From<InnerError> for YourError`, enabling `?` conversion.
2. Marks that field as the `#[source]`, so the error chain is wired automatically.

A variant may have at most one `#[from]` field. If you need both `#[from]` and additional fields, add them — `thiserror` handles it.

```rust
#[error("migration failed on step {step}")]
Migration {
    step: u32,
    #[from] source: MigrationError,    // explicit field name required when combined
}
```

### `#[source]`

Use `#[source]` without `#[from]` when you want the source chain but do not want the `From` impl (e.g., the inner type is not owned by you, or you need manual construction).

```rust
#[error("config parse failed")]
ConfigParse {
    #[source] inner: serde_json::Error,
    path: PathBuf,
}
```

### `#[non_exhaustive]` on error enums

Add `#[non_exhaustive]` to any public error enum to preserve the right to add variants in a minor release.

```rust
#[derive(Debug, Error)]
#[non_exhaustive]
pub enum ClientError { ... }
```

Cost: downstream `match` arms must include `_ => ...`. This is the correct trade-off for published crates. Omit it only for internal-only types where exhaustive matching is an intentional API contract.

### Structuring error types

- **One enum per crate boundary**, not one per function or module. Functions within a crate return the crate's error type; only the public surface matters.
- Group by failure *category*, not by call site.
- Avoid a catch-all `Other(String)` variant — it is `Box<dyn Error>` with extra steps.

### Concrete full example

```rust
use std::path::PathBuf;
use thiserror::Error;

#[derive(Debug, Error)]
#[non_exhaustive]
pub enum ConfigError {
    #[error("config file not found: {path}")]
    NotFound { path: PathBuf },

    #[error("config file is not valid UTF-8: {path}")]
    Encoding {
        path: PathBuf,
        #[source] source: std::string::FromUtf8Error,
    },

    #[error("config parse error")]
    Parse(#[from] toml::de::Error),

    #[error("missing required field: {field}")]
    MissingField { field: &'static str },
}
```

Callers can `match` on every variant, recover selectively, and walk the source chain via `std::error::Error::source()`.

---

## anyhow

### `anyhow::Error`

An opaque `dyn std::error::Error + Send + Sync + 'static` with a backtrace. It carries full source chains but exposes no structure for matching — appropriate for applications where the goal is logging and presentation, not programmatic recovery.

### `.context()` and `.with_context()`

Add context at every layer boundary. The string describes *what was being attempted*.

```rust
use anyhow::Context as _;

fn load_config(path: &Path) -> anyhow::Result<Config> {
    let raw = std::fs::read_to_string(path)
        .with_context(|| format!("reading config from {}", path.display()))?;

    toml::from_str(&raw)
        .context("parsing config as TOML")?;

    // ...
}
```

`.context("static str")` — use when the message is constant.
`.with_context(|| format!(...))` — use when the message includes runtime values; the closure is only called on the error path.

### `bail!` and `ensure!`

```rust
use anyhow::{bail, ensure};

fn validate_port(port: u16) -> anyhow::Result<()> {
    ensure!(port >= 1024, "port {port} is reserved");
    Ok(())
}

fn check_mode(mode: &str) -> anyhow::Result<()> {
    if mode != "production" && mode != "staging" {
        bail!("unknown mode: {mode}");
    }
    Ok(())
}
```

`ensure!(cond, msg)` is `if !cond { bail!(msg) }`. Both produce an `anyhow::Error`.

### Downcasting

When you need to inspect a concrete type at runtime (e.g., distinguish a recoverable error from a fatal one):

```rust
if let Some(db_err) = err.downcast_ref::<sqlx::Error>() {
    if db_err.as_database_error()
        .map(|e| e.is_unique_violation())
        .unwrap_or(false)
    {
        // handle duplicate key
    }
}
```

Downcasting is the escape hatch. Frequent downcasting in application code is a smell that the library should have returned typed errors.

### `main()` and async entry points

```rust
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let config = load_config(Path::new("config.toml"))?;
    run(config).await?;
    Ok(())
}
```

`anyhow::Result<()>` as the `main` return type integrates with Rust's `Termination` trait — on error it prints the chain and exits with code 1.

---

## The `?` Operator

### What it desugars to

```rust
let x = some_op()?;
// equivalent to:
let x = match some_op() {
    Ok(v) => v,
    Err(e) => return Err(From::from(e)),
};
```

`From::from(e)` is the conversion step. For `thiserror` enums, `#[from]` generates the `From` impl. For `anyhow`, any `E: std::error::Error + Send + Sync + 'static` converts automatically.

### Chaining context with `?`

```rust
let conn = pool.acquire()
    .await
    .context("acquiring DB connection")?;
```

The `.context()` call wraps the error before `?` returns it. The order matters: wrap first, propagate second.

### When `?` won't work

- **Closures that don't return `Result`** — `?` inside an `iter().map(|x| ...)` where the map expects `T`, not `Result<T>`. Collect into `Result<Vec<_>>` and `?` outside the closure, or switch to a for loop.
- **`impl Trait` returns with opaque error types** — if the function returns `impl Fn() -> Result<T, SomeError>`, the closure must match exactly; mixing error types requires explicit conversion.

---

## Panic Hygiene

### When panics are acceptable

- **Tests** — `unwrap()` is fine; a panic is a test failure.
- **Program initialization** — CLI argument parsing, loading mandatory config at startup. If the invariant must hold for the program to function at all, panic with a clear message via `.expect()`.
- **`unreachable!()`** in exhaustive matches the compiler cannot prove — always add a message explaining why this branch is structurally impossible.
- **Invariant violations that indicate a bug** — `index_map.get(&key).expect("key inserted in same block")`.

### When panics are never acceptable

- **Library code** — a panic in your library crashes the caller's process. Return `Result`.
- **Spawned async tasks** — a panic in `tokio::spawn` / `async_std::spawn` is silently swallowed unless the caller polls the `JoinHandle`. Tasks must catch their own panics or propagate errors through channels.
- **Request handlers** — web framework middleware may catch panics, but relying on that is fragile. Use `Result` throughout.

### `.unwrap()` vs `.expect("reason")`

Default: prefer `.expect()` over `.unwrap()` — when the panic fires, the message appears in the output. **Exception:** some workspaces CI-enforce the inverse (`expect_used = "deny"`, `unwrap_used = "allow"`), on the argument that expect-strings rot into false documentation while a bare `.unwrap()` is a greppable, honest assert. The workspace's lint profile always wins — see [preferred-stack.md](preferred-stack.md).

```rust
// Bad: "called `Option::unwrap()` on a `None` value"
let val = map.get(&key).unwrap();

// Good: "user_id must be present after authentication middleware"
let val = map.get(&key).expect("user_id must be present after authentication middleware");
```

### `#[should_panic]`

```rust
#[test]
#[should_panic(expected = "index out of bounds")]
fn rejects_empty_slice() {
    first_element(&[]);
}
```

Use `expected = "..."` to assert the panic message matches a substring. Without it, any panic passes the test.

---

## Error Context Design

- **Add context at layer boundaries, not inside the producing function.** The function that opens a file should not know what the caller was trying to accomplish — that context belongs one frame up.

```rust
// Inside file reader — too much knowledge of caller intent:
std::fs::read_to_string(path)
    .context("loading user profile")?   // wrong layer

// In the caller — correct:
reader::read_file(path)
    .context("loading user profile")?
```

- **Context messages describe what was being attempted**, not what went wrong. The underlying error already says what went wrong.

```rust
// Redundant — the io::Error already says "No such file or directory":
.context("failed to open file: file not found")

// Correct:
.context("loading TLS certificate")
```

- **One context per boundary.** Adding `.context()` at every function call in a call stack produces noise. Add it where the semantic meaning changes.

---

## `#[non_exhaustive]`

### On error enums

Prevents downstream `match` from exhaustively covering variants:

```rust
// In your crate:
#[non_exhaustive]
pub enum ApiError { RateLimit, AuthFailed, NetworkError(io::Error) }

// In downstream code — the `_` arm is required:
match err {
    ApiError::RateLimit => retry(),
    ApiError::AuthFailed => reauthenticate(),
    _ => return Err(err.into()),
}
```

Adding a new variant to `ApiError` is now a minor release, not a breaking change.

### On error structs

Prevents direct construction by downstream code:

```rust
#[non_exhaustive]
pub struct ParseError {
    pub line: usize,
    pub column: usize,
    pub message: String,
}
```

Downstream cannot write `ParseError { line: 1, column: 0, message: "...".into() }`. You may add fields in a minor release. Provide a constructor if callers need to build the type.

### Summary

| Target | Effect | When to use |
|---|---|---|
| `#[non_exhaustive]` on enum | `match` requires `_` arm | All public error enums in published crates |
| `#[non_exhaustive]` on struct | No struct-literal construction | Public error structs you may extend |

---

## Common Mistakes

### Boxing everything

```rust
// Loses type information; callers cannot match:
fn parse(s: &str) -> Result<Config, Box<dyn std::error::Error>> { ... }

// Correct for libraries:
fn parse(s: &str) -> Result<Config, ConfigError> { ... }
```

`Box<dyn Error>` is the manual version of `anyhow::Error` without the context API. It is almost never the right choice.

### Returning `String` as an error type

```rust
// Unergonomic, no source chain, no structured recovery:
fn validate(s: &str) -> Result<(), String> { ... }
```

`String` errors cannot be wrapped with `.context()`, have no `source()`, and force callers to parse strings to understand the error. Use a typed enum or `anyhow::Error`.

### Swallowing errors with `let _ = result`

```rust
// Silent failure — almost always wrong:
let _ = cache.invalidate(key);

// Correct options:
cache.invalidate(key)?;                         // propagate

if let Err(e) = cache.invalidate(key) {         // handle explicitly
    tracing::warn!(err = %e, "cache invalidation failed, continuing");
}

// If truly fire-and-forget, say so explicitly:
let _ = tx.send(event); // best-effort notification; receiver may have dropped
```

Never use `let _ =` without a comment explaining why the error is intentionally discarded.
