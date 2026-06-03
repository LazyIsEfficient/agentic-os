# Workspace and Crate Design — Principal-Level Reference

## Cargo Workspace Basics

### `[workspace]` in the Root `Cargo.toml`

```toml
[workspace]
members = [
    "crates/domain",
    "crates/infra",
    "crates/api",
    "crates/service",
]
# Exclude dirs that contain their own Cargo.toml but should not be workspace members
# (e.g., vendored third-party code, example sub-projects)
exclude = ["vendor/some-fork", "examples/standalone"]

resolver = "2"  # Always use resolver v2 in workspaces (Rust 2021 default for new crates)
```

- `members` paths are relative to the workspace root; glob patterns are supported (`"crates/*"`).
- `exclude` takes precedence over glob membership.
- A workspace has a single `Cargo.lock` and a single `target/` directory at the root.
- Member crates cannot have their own `[workspace]` table.

### `workspace.dependencies` — Declare Once, Inherit Everywhere

```toml
# Root Cargo.toml
[workspace.dependencies]
tokio        = { version = "1.37", features = ["full"] }
serde        = { version = "1", features = ["derive"] }
sqlx         = { version = "0.7", features = ["postgres", "runtime-tokio-native-tls"] }
thiserror    = "1"
anyhow       = "1"
tracing      = "0.1"
uuid         = { version = "1", features = ["v4", "serde"] }
```

```toml
# crates/domain/Cargo.toml
[dependencies]
serde     = { workspace = true }
thiserror = { workspace = true }
uuid      = { workspace = true }
```

```toml
# crates/infra/Cargo.toml
[dependencies]
domain = { path = "../domain" }
sqlx   = { workspace = true }
tokio  = { workspace = true }
```

- `{ workspace = true }` cannot override `version` or `features` — the workspace declaration is the canonical one.
- To add features in a member, use `{ workspace = true, features = ["extra"] }` — this **adds** to the workspace feature set; it does not replace it.
- This eliminates version drift: upgrade once in the root, all members get it.

### `workspace.package` — Shared Metadata

```toml
[workspace.package]
version     = "0.1.0"
edition     = "2021"
authors     = ["Acme Platform Team <platform@acme.io>"]
license     = "MIT OR Apache-2.0"
repository  = "https://github.com/acme/my-service"
rust-version = "1.78"   # MSRV — enforced by cargo check
```

```toml
# crates/domain/Cargo.toml — inherit everything
[package]
name    = "domain"
version = { workspace = true }
edition = { workspace = true }
license = { workspace = true }
```

Fields not listed in `workspace.package` must be declared per-crate (e.g., `description`, `keywords`).

### Complete Annotated Root `Cargo.toml`

```toml
[workspace]
members  = ["crates/*"]
resolver = "2"

[workspace.package]
version      = "0.3.0"
edition      = "2021"
license      = "MIT OR Apache-2.0"
rust-version = "1.78"

[workspace.dependencies]
# Async runtime
tokio    = { version = "1.37", features = ["full"] }

# Serialisation
serde    = { version = "1", features = ["derive"] }
serde_json = "1"

# Error handling
thiserror = "1"
anyhow    = "1"

# Observability
tracing            = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }

# DB
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio-native-tls", "uuid", "chrono"] }

# HTTP
axum    = { version = "0.7", features = ["macros"] }
reqwest = { version = "0.12", default-features = false, features = ["json", "rustls-tls"] }

# Common types
uuid     = { version = "1", features = ["v4", "serde"] }
chrono   = { version = "0.4", features = ["serde"] }

# Internal crates
domain  = { path = "crates/domain" }
infra   = { path = "crates/infra" }
api     = { path = "crates/api" }

[profile.release]
lto           = true
codegen-units = 1
strip         = "symbols"

[profile.dev.package."*"]
opt-level = 1   # speed up heavy deps (proc-macros, serde) in dev builds
```

---

## Crate Decomposition Principles

### The Three Layers

| Layer | Crate | Allowed dependencies | I/O |
|-------|-------|----------------------|-----|
| Domain | `domain` | `serde`, `thiserror`, `uuid`, `chrono`, pure-logic crates | None |
| Infrastructure | `infra` | `domain` + DB/HTTP/queue drivers, `tokio`, `sqlx`, `reqwest` | Yes |
| Binary | `service` | `domain`, `infra`, `api`, `config`, `tracing-subscriber` | Yes — startup only |

The domain crate is the centrepiece: it knows nothing about how data is stored or transported.

### Why This Separation Matters

- **Domain crate compiles fast** — no async runtime, no heavy drivers. Unit tests run in milliseconds, no database required.
- **Infrastructure is swappable** — swap Postgres for SQLite, or `reqwest` for `hyper`, without touching domain logic.
- **Binary is thin** — its only job is wiring. A thin binary means a readable `main.rs`; configuration, startup, and dependency injection, nothing else.
- **Test surface is right-sized** — domain tests are fast unit tests; infra tests are integration tests behind a feature flag or test harness; the binary is tested end-to-end only.

### Ports and Adapters in Rust

The domain crate defines traits (ports). Infrastructure crates implement them (adapters).

```rust
// crates/domain/src/ports.rs
use async_trait::async_trait;
use crate::{Order, OrderId, DomainError};

#[async_trait]
pub trait OrderRepository: Send + Sync + 'static {
    async fn find(&self, id: OrderId) -> Result<Option<Order>, DomainError>;
    async fn save(&self, order: &Order) -> Result<(), DomainError>;
}

#[async_trait]
pub trait PaymentGateway: Send + Sync + 'static {
    async fn charge(&self, order: &Order) -> Result<(), DomainError>;
}
```

```rust
// crates/infra/src/postgres_order_repo.rs
use domain::ports::OrderRepository;

pub struct PostgresOrderRepo { pool: sqlx::PgPool }

#[async_trait::async_trait]
impl OrderRepository for PostgresOrderRepo { /* ... */ }
```

```rust
// crates/service/src/main.rs — wiring only
let pool = sqlx::PgPool::connect(&config.db_url).await?;
let repo = Arc::new(PostgresOrderRepo::new(pool));
let gw   = Arc::new(StripeGateway::new(&config.stripe_key));
let app  = api::router(repo, gw);
axum::serve(listener, app).await?;
```

### When to Split vs Keep a Single Crate

| Signal | Action |
|--------|--------|
| Domain logic mixed with SQL / HTTP | Split immediately |
| Compile times > ~30 s for `cargo check` | Split to reduce dependency cone |
| Two teams own distinct sub-systems | Split at team boundary |
| Crate > ~20 kLOC with unrelated concerns | Split |
| Pure utility with zero business logic | Keep as one crate (or put in `common/`) |
| Prototype / pre-product | Single crate is fine; defer the split |
| Shared types used by 3+ crates | Extract to a `types` or `common` crate |

Splitting too early creates coordination overhead. Splitting too late makes tests slow and architecture implicit. The smell is I/O imports (`sqlx`, `reqwest`) and domain logic in the same file.

---

## Standard Workspace Layout

```
my-service/
  Cargo.toml          # workspace root — [workspace], [workspace.dependencies]
  Cargo.lock          # committed for binaries, .gitignored for libraries
  .cargo/
    config.toml       # [build] / [target] / env overrides, not credentials
  crates/
    domain/           # pure logic — no I/O, no async runtime
      Cargo.toml
      src/
        lib.rs        # pub use re-exports; module declarations
        model.rs      # aggregate roots, value objects
        ports.rs      # traits the domain defines (repository, gateway)
        error.rs      # domain error enum
        service.rs    # domain services / use-cases
    infra/            # DB, HTTP clients, message queues
      Cargo.toml
      src/
        lib.rs
        db/
          mod.rs      # or db.rs if no sub-modules
          order_repo.rs
        http/
          payment_gw.rs
    api/              # Axum routers and handlers; depends on domain traits
      Cargo.toml
      src/
        lib.rs        # pub fn router(...) -> Router
        orders.rs     # handler functions, request/response types
        error.rs      # HTTP error mapping
    service/          # binary: wiring, config parsing, startup
      Cargo.toml
      src/
        main.rs       # ≤ 50 lines ideally
        config.rs     # typed config via `config` or `figment` crate
  tests/              # workspace-level integration tests (use published crate API)
    order_flow.rs
```

Place `tests/` at the workspace root for integration tests that exercise multiple crates together. Per-crate unit tests live in `#[cfg(test)]` modules inside each crate's `src/`.

---

## Module Organisation

### `src/lib.rs` vs `src/main.rs`

Always prefer `lib.rs` + a thin `main.rs` (or `bin/`) that calls into the library.

```
# Bad: everything in main.rs
crates/service/src/main.rs   # 2000 lines, untestable

# Good: lib + thin main
crates/service/src/lib.rs    # all logic, integration-testable
crates/service/src/main.rs   # 10 lines: parse config, call lib::run()
```

The reason: `cargo test` can import `lib.rs`; it cannot import `main.rs`.

### File Layout for Modules

Prefer named files (`foo.rs`) over directory + `mod.rs` for leaf modules:

```
src/
  lib.rs
  order.rs          # preferred: mod order; resolves to order.rs
  payment.rs

# Not preferred for simple modules:
src/
  order/
    mod.rs          # confusing when multiple mod.rs tabs are open
```

Use `directory/mod.rs` only when a module has child modules that genuinely belong under it:

```
src/
  db/
    mod.rs          # declares: pub mod postgres; pub mod migrations;
    postgres.rs
    migrations.rs
```

### Re-exports and Public API Shape

```rust
// crates/domain/src/lib.rs
mod model;
mod ports;
mod service;
pub mod error;   // re-exported as domain::error

// Flatten the public surface; callers use domain::Order, not domain::model::Order
pub use model::{Order, OrderId, OrderStatus, LineItem};
pub use ports::{OrderRepository, PaymentGateway};
pub use service::OrderService;
```

- Internal module structure is an implementation detail — don't leak it.
- Re-export aggressively in `lib.rs`; keep internal `mod` declarations private.
- Use `#[doc(hidden)]` on items that must be `pub` for macro reasons but aren't part of the public API.

---

## Visibility Discipline

### The Visibility Ladder

| Modifier | Scope |
|----------|-------|
| (none / `pub(self)`) | Current module only |
| `pub(super)` | Parent module — for sibling sharing |
| `pub(crate)` | Anywhere in the crate — default for internal cross-module sharing |
| `pub(in path)` | Specific ancestor module — rarely needed |
| `pub` | Public API — downstream crates and binary crates |

**Rule:** default to `pub(crate)`. Escalate to `pub` only when an external crate needs the item.

### Common Mistakes

```rust
// Bad: pub just to silence "unused" or to access from tests
pub struct InternalConfig { ... }

// Good: keep it pub(crate); tests inside the module or submodule can access it
pub(crate) struct InternalConfig { ... }

// Good: cross-module within same crate
pub(crate) fn validate_order(o: &Order) -> Result<(), ValidationError> { ... }
```

Never make a type `pub` just because it appears in a `#[cfg(test)]` function. Use `pub(crate)` and put the test in the same crate, or use a test helper module.

### Sealed Trait Pattern

Use when a trait must be `pub` (to appear in public method signatures) but must not be implemented outside the crate:

```rust
// crates/domain/src/sealed.rs
pub(crate) mod private {
    pub trait Sealed {}
}

// crates/domain/src/ports.rs
use crate::sealed::private;

pub trait StorageBackend: private::Sealed {
    fn store(&self, key: &str, value: &[u8]) -> Result<(), Error>;
}

// Only types in this crate can implement StorageBackend because
// private::Sealed is pub(crate) — external crates cannot name it.
```

---

## Feature Flags

### Features Are Strictly Additive

A feature must only add optional dependencies or unlock `#[cfg(feature = "...")]` code paths. Features must never:
- Change the behaviour of always-present code
- Enable or disable test infrastructure
- Toggle debug vs release behaviour (use `cfg(debug_assertions)` or runtime config for that)

### Minimal Defaults

```toml
[features]
default = []                           # ship lean; consumers opt in
tls     = ["dep:rustls", "reqwest/rustls-tls"]
tracing = ["dep:tracing", "dep:tracing-subscriber"]
serde   = ["dep:serde", "uuid/serde"]  # enable serde impls for your types
```

- Name features after the capability (`tls`, `metrics`, `serde`) not the crate (`rustls`, `prometheus`).
- `dep:crate-name` syntax (Rust 1.60+) makes a dependency optional and prevents the dep name from being a feature itself.

### `cfg_aliases` for Complex Combinations

```toml
# Cargo.toml
[build-dependencies]
cfg_aliases = "0.2"
```

```rust
// build.rs
fn main() {
    cfg_aliases::cfg_aliases! {
        native_tls: { feature = "tls-native" },
        rustls_tls: { feature = "tls-rustls" },
        any_tls:    { any(feature = "tls-native", feature = "tls-rustls") },
    }
}
```

```rust
// src/lib.rs
#[cfg(any_tls)]
mod tls_common;
```

### Feature Flag Checklist

- [ ] `cargo test --no-default-features` passes
- [ ] `cargo test --all-features` passes
- [ ] Feature combinations are tested in CI (use a matrix)
- [ ] No feature silently enables another without documentation

---

## Dependency Management

### `Cargo.lock` Policy

| Project type | `Cargo.lock` in VCS |
|--------------|---------------------|
| Binary / service | **Yes** — reproducible builds |
| Library (`lib` only) | **No** — let consumers control transitive versions |
| Library with integration tests needing reproducibility | Use `Cargo.lock` but note it in `README` |

Add `Cargo.lock` to `.gitignore` for libraries; commit it for binaries.

### `cargo deny`

```toml
# deny.toml
[licenses]
allow = ["MIT", "Apache-2.0", "Apache-2.0 WITH LLVM-exception", "BSD-2-Clause", "BSD-3-Clause", "ISC", "Unicode-DFS-2016"]
deny  = ["GPL-2.0", "GPL-3.0", "AGPL-3.0"]

[bans]
multiple-versions = "deny"   # or "warn" during migration
deny = [
    { name = "openssl-sys", wrappers = ["openssl"] },  # force rustls
]

[advisories]
db-path   = "~/.cargo/advisory-db"
db-urls   = ["https://github.com/rustsec/advisory-db"]
vulnerability = "deny"
unmaintained  = "warn"
```

Run `cargo deny check` in CI before merging. It catches:
- License incompatibilities before legal review
- Duplicate dep versions (often from transitive conflicts)
- Known CVEs from the RustSec advisory database

### `cargo audit`

```bash
cargo install cargo-audit
cargo audit                    # check against RustSec advisory db
cargo audit fix                # auto-upgrade safe minor versions
```

Run `cargo audit` in CI as a separate step from `cargo deny` — they use different databases and catch different things. `cargo deny` is config-driven policy; `cargo audit` is reactive CVE scanning.

### Version Constraint Discipline

```toml
# Prefer: semver-compatible range, pinned major
tokio = "1"               # >=1.0.0, <2.0.0
serde = "1.0.100"         # at least 1.0.100 (requires a specific feature)

# Avoid: overly tight pins cause dependency hell
tokio = "=1.37.0"         # breaks if transitive dep needs 1.38

# Never: unbounded
some-crate = "*"
```

- For internal path dependencies, omit `version` unless publishing.
- For published libraries, version ranges must be as wide as possible while remaining correct.

### Deduplicating Transitive Versions

```bash
cargo tree -d                        # show duplicate versions
cargo update -p some-crate --precise 1.2.3   # pin a transitive dep
```

If two major versions of a crate exist in the tree, it is almost always a mistake — types won't unify across them. Audit with `cargo tree -d` before releasing.

---

## Compilation Time

### Profiling Bottlenecks

```bash
cargo build --timings           # generates target/cargo-timings/cargo-timing.html
cargo build --timings=json      # machine-readable for CI analysis
```

Look for:
- Crates with long `codegen` time — likely targets for splitting or conditional compilation
- Long chains with no parallelism — indicates unnecessary dependencies
- Proc-macro crates — they run serially during expansion; minimise their use

### Splitting to Improve Incremental Builds

Large monolithic crates recompile fully on any change to their source. Splitting by logical boundary means only the changed crate (and its dependents) recompile. The split pays for itself once a crate reaches ~5–10 kLOC.

The domain/infra/api split described above is primarily a design decision, but it also delivers a compilation benefit: editing an API handler does not recompile domain or infra.

### CI Caching

```yaml
# GitHub Actions example
- uses: Swatinem/rust-cache@v2
  with:
    workspaces: ". -> target"    # workspace root
    shared-key: "my-service"     # consistent across jobs
```

`Swatinem/rust-cache` caches `~/.cargo/registry`, `~/.cargo/git`, and `target/` keyed on `Cargo.lock` + `rust-toolchain`. It handles cache invalidation correctly on `Cargo.lock` changes.

For self-hosted runners or more control, `sccache` distributes compilation across a shared cache:

```bash
cargo install sccache
export RUSTC_WRAPPER=sccache
cargo build
sccache --show-stats
```

### Profile Tuning

```toml
# Cargo.toml
[profile.dev]
opt-level = 0
debug     = true

# Heavy deps (serde, sqlx) get a minimal opt pass even in dev builds —
# eliminates the "first compile is painfully slow" problem
[profile.dev.package."*"]
opt-level = 1

# proc-macro crates are always compiled with opt-level ≥ 1 regardless of profile
# (Cargo does this automatically; it is not configurable)

[profile.release]
opt-level     = 3
lto           = "thin"   # "thin" is faster than "fat" with ~equivalent binary size
codegen-units = 1        # required for full LTO; reduces parallelism
strip         = "symbols"

[profile.ci]
# Faster CI builds: no LTO, moderate opt
inherits      = "release"
lto           = false
codegen-units = 16
strip         = false    # keep symbols for test output
```

Activate the CI profile with `cargo build --profile ci`.

### Dependency Hygiene for Compile Time

- Avoid `features = ["full"]` on large crates (`tokio`, `sqlx`) in library crates — only the binary should request `full`. This prevents unnecessary features from being compiled when the library is used without them.
- `async-trait` adds a proc-macro dependency; consider `impl_trait_in_assoc_type` (stable as of Rust 1.79) for simple cases.
- `derive` macros (serde, thiserror) are fast; avoid bespoke proc-macro crates for simple patterns.
