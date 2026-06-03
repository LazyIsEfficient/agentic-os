# Performance and Profiling

## Zero-Cost Abstractions as a Design Principle

"Zero-cost" means no overhead compared to the equivalent hand-written C. It does **not** mean "free" — the computation still runs. Bjarne Stroustrup's original formulation: *"What you don't use, you don't pay for. What you do use, you couldn't hand-code better."*

**Zero-cost in Rust:**

| Abstraction | Mechanism | Cost |
|---|---|---|
| Iterators | Monomorphized, inlined by LLVM | Zero |
| Closures | Statically-dispatched, inlined | Zero |
| Generics (`fn foo<T>`) | Monomorphization — one copy per concrete type | Zero at runtime (code size tradeoff) |
| `impl Trait` (argument position) | Same as generics | Zero |

**Not zero-cost:**

| Abstraction | Why |
|---|---|
| `dyn Trait` | Vtable pointer dereference; prevents inlining; often implies heap allocation |
| `Box<T>` | Heap allocation + pointer indirection |
| `Arc<T>` | Atomic refcount on every clone/drop |
| `.clone()` | Deep copy — cost is proportional to data |
| `impl Trait` (return position) | Opaque type, not `dyn`, still zero-cost — do not confuse these |

**Default rule:** reach for abstractions first. Verify with a profiler that they cost you before removing them. Premature concretization (removing iterators, inlining generics manually) trades maintainability for imaginary gains.

---

## Measure First — The Profiling Workflow

Never guess. Never profile a debug build. Follow this sequence:

### 1. Reproduce Under Realistic Load
Synthetic microbenchmarks lie. Reproduce the actual access pattern, data size, and concurrency. A benchmark that runs on 10 items tells you nothing about 10 million.

### 2. Build for Release
```bash
cargo build --release
```
Debug builds disable inlining and optimisation. Profiling a debug build is measuring overhead, not your code.

### 3. `cargo flamegraph` — Identify Hot Functions
```bash
cargo install flamegraph
cargo flamegraph --bin my-binary -- --args
```
Produces a flamegraph SVG. Wide frames are hot. Look for:
- Unexpected `alloc::` / `Vec::` / `String::` calls in hot paths
- `clone()` you didn't know was there
- Synchronization (`Mutex::lock`, `Arc::drop`) dominating

Add to `Cargo.toml` to preserve symbol names without hurting runtime performance:
```toml
[profile.release]
debug = 1
```

**Platform notes:**
- Linux: uses `perf`; needs `perf_event_paranoid` ≤ 1 (`sudo sysctl -w kernel.perf_event_paranoid=1`)
- macOS: uses DTrace; may require partial SIP disable (`csrutil enable --without dtrace`)

### 4. `cargo criterion` — Microbenchmarks
```bash
cargo install cargo-criterion  # optional CLI runner
cargo bench
```
Results stored in `target/criterion/`. Criterion handles warmup, statistical analysis, and regression detection automatically. Use it to compare two implementations with a controlled setup.

### 5. DHAT — Heap Allocation Profiling
```bash
valgrind --tool=dhat --dhat-out-file=dhat.out ./target/release/my-binary
```
Or use the `dhat` crate for in-process profiling without Valgrind. Identifies:
- Total bytes allocated
- Peak live bytes
- Allocation call sites (which `Vec::push`, which `String::from`, etc.)

Use when flamegraph shows `malloc`/`free` dominating but you need to find the Rust call sites.

### 6. `tokio-console` — Async Task Profiling
```bash
cargo install tokio-console
# In your app: add tokio-console-subscriber, instrument with RUSTFLAGS="--cfg tokio_unstable"
```
Identifies:
- Tasks stuck in a `Pending` state (await never resolves)
- Tasks with abnormally high poll counts (busy-looping)
- Tasks holding wakers longer than expected

---

## `criterion` Benchmarks

### Setup

`Cargo.toml`:
```toml
[dev-dependencies]
criterion = { version = "0.5", features = ["html_reports"] }

[[bench]]
name = "my_benchmark"
harness = false
```

### Basic Benchmark

`benches/my_benchmark.rs`:
```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 | 1 => n,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn bench_fibonacci(c: &mut Criterion) {
    c.bench_function("fibonacci 20", |b| {
        b.iter(|| fibonacci(black_box(20)))
    });
}

criterion_group!(benches, bench_fibonacci);
criterion_main!(benches);
```

`black_box()` prevents the compiler from constant-folding or dead-code-eliminating the work under measurement. Always wrap inputs and outputs.

### Comparing Implementations

```rust
use criterion::{BenchmarkGroup, BenchmarkId, Criterion, measurement::WallTime};

fn compare_implementations(c: &mut Criterion) {
    let mut group: BenchmarkGroup<WallTime> = c.benchmark_group("string_ops");

    for size in [100usize, 1000, 10_000] {
        group.bench_with_input(BenchmarkId::new("format_macro", size), &size, |b, &n| {
            b.iter(|| format!("{:0>width$}", black_box(42), width = n))
        });

        group.bench_with_input(BenchmarkId::new("write_macro", size), &size, |b, &n| {
            b.iter(|| {
                let mut s = String::with_capacity(n);
                use std::fmt::Write;
                write!(s, "{:0>width$}", black_box(42), width = n).unwrap();
                s
            })
        });
    }

    group.finish();
}
```

---

## Common Performance Patterns

### Avoiding Allocations in Hot Paths

**Pre-allocate when size is known:**
```rust
// Bad: multiple reallocations
let mut v = Vec::new();
for item in items { v.push(item); }

// Good: single allocation
let mut v = Vec::with_capacity(items.len());
for item in items { v.push(item); }
```

**Reuse buffers across calls:**
```rust
// Bad: allocates on every call
fn process(data: &[u8]) -> Vec<u8> { /* ... */ }

// Good: caller owns the buffer; zero allocation in steady state
fn process(data: &[u8], out: &mut Vec<u8>) {
    out.clear();
    // fill out
}
```

**`SmallVec` for short-lived collections:**
```rust
use smallvec::SmallVec;

// Stack-allocated for ≤4 elements; falls back to heap
let mut v: SmallVec<[u8; 4]> = SmallVec::new();
```
Use when collections are almost always small; avoids heap for the common case.

**`Cow<'_, T>` to avoid cloning read-mostly data:**
```rust
use std::borrow::Cow;

fn normalize(s: &str) -> Cow<'_, str> {
    if s.chars().all(|c| c.is_lowercase()) {
        Cow::Borrowed(s)   // no allocation
    } else {
        Cow::Owned(s.to_lowercase())  // allocates only when needed
    }
}
```

### Zero-Copy I/O with `bytes`

`bytes::Bytes` is a reference-counted slice — `clone()` is O(1) (increments refcount, no memcpy).

```rust
use bytes::{Bytes, BytesMut};

// Build a mutable buffer
let mut buf = BytesMut::with_capacity(1024);
buf.extend_from_slice(b"hello");
buf.extend_from_slice(b" world");

// Freeze into a cheaply-cloneable read-only Bytes
let frozen: Bytes = buf.freeze();

// Cloning is O(1)
let slice = frozen.clone();  // just bumps refcount
```

Prefer `Bytes` over `Vec<u8>` anywhere the same buffer is passed to multiple consumers (HTTP response bodies, parsed frames, cache entries).

### String Performance

```rust
// Bad: format! allocates on every call
fn label(n: u32) -> String {
    format!("item_{}", n)
}

// Better for hot paths: write into a pre-allocated buffer
use std::fmt::Write;
fn label_into(n: u32, buf: &mut String) {
    buf.clear();
    write!(buf, "item_{}", n).unwrap();
}

// For widely-shared immutable strings: Arc<str> is smaller than Arc<String>
let shared: std::sync::Arc<str> = "hello".into();
```

| Pattern | Allocates? | Notes |
|---|---|---|
| `String::new()` + `push_str` | Yes (on growth) | Use `with_capacity` if length known |
| `format!()` | Always | Fine outside hot paths |
| `write!()` into existing `String` | No (if capacity ok) | Prefer in loops |
| `Arc<str>` | Once | Share across threads cheaply |
| `&'static str` | Never | Compile-time constant only |

### Iteration

Iterator chains compile to the same code as hand-written loops. They do **not** materialise intermediate collections.

```rust
// This does not allocate intermediate Vecs
let sum: u32 = data
    .iter()
    .filter(|&&x| x > 0)
    .map(|&x| x * 2)
    .sum();
```

For data-parallel CPU work, swap `.iter()` for `.par_iter()` (Rayon) — no other changes needed:
```rust
use rayon::prelude::*;

let sum: u32 = data.par_iter()
    .filter(|&&x| x > 0)
    .map(|&x| x * 2)
    .sum();
```

Rayon uses a work-stealing thread pool sized to available CPUs. Only helps when work per element is non-trivial (> ~1µs) and data is large enough to amortize thread overhead.

---

## Async Performance Considerations

- **Many tasks are cheap; wakeup storms are not.** Spawning millions of tasks is fine. Millions of tasks that wake each other repeatedly (broadcast, polling loops) can saturate the scheduler.
- **Yield correctly:**
  ```rust
  // Bad: sleep(0) has OS scheduler overhead
  tokio::time::sleep(Duration::ZERO).await;

  // Good: cooperative yield to Tokio scheduler
  tokio::task::yield_now().await;
  ```
- **Bound concurrency with `Semaphore`:**
  ```rust
  use tokio::sync::Semaphore;
  use std::sync::Arc;

  let sem = Arc::new(Semaphore::new(100));  // max 100 concurrent tasks

  for item in items {
      let permit = sem.clone().acquire_owned().await.unwrap();
      tokio::spawn(async move {
          let _permit = permit;  // released on drop
          process(item).await;
      });
  }
  ```
- **Batch I/O.** Network round-trips dominate. A single `write_all` of 100 records costs ~the same as one record. Buffer writes with `BufWriter` or accumulate records before flushing.
- **Avoid blocking in async context.** CPU-bound work blocks the executor thread. Use `tokio::task::spawn_blocking` to run it on a dedicated thread pool.

---

## Compiler Flags for Release Performance

```toml
[profile.release]
opt-level = 3      # default; max LLVM optimisation passes
lto = "thin"       # link-time optimisation across crate boundaries; often 5–15% speedup
codegen-units = 1  # single codegen unit: slower compile, best optimisation; use for final builds
panic = "abort"    # skip unwinding machinery; smaller binary, marginally faster panics
debug = 1          # strip = false equivalent; keeps symbol names for profiling
```

**`lto` tradeoffs:**

| Value | Compile Time | Runtime Gain |
|---|---|---|
| `false` | Fastest | None |
| `"thin"` | Moderate increase | Good (~5–15%) |
| `"fat"` | Slow | Best, diminishing returns vs thin |

Use `codegen-units = 1` only for final production binaries or benchmarks. It makes incremental builds impractical.

---

## When NOT to Optimise

- Before you have a measurable, reproducible regression. Guessing the bottleneck is almost always wrong.
- When the bottleneck is I/O. If `cargo flamegraph` shows your hot path is `epoll_wait` or `read`, CPU optimisation is noise.
- When the change makes the code materially harder to maintain. If you must — add a comment explaining **what** you measured and **why** this form is faster:
  ```rust
  // PERF: avoid allocation in tight loop; criterion bench showed 3x improvement
  // over returning Vec<u8>. See benches/frame_parse.rs.
  fn decode_frame(buf: &[u8], out: &mut Vec<u8>) { /* ... */ }
  ```

**Optimisation debt is real.** Unsafe transmutes, manual SIMD, and cache-aligned structs make the code reviewer's job harder and introduce correctness risk. Pay only when the profiler demands it.
