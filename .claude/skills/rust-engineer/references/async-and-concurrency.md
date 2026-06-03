# Async & Concurrency Reference

## Tokio Runtime Anatomy

### `#[tokio::main]` expansion

```rust
#[tokio::main]
async fn main() { ... }
// expands to:
fn main() {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async { ... })
}
```

`#[tokio::main(flavor = "current_thread")]` expands with `new_current_thread()` instead.

### Multi-threaded vs current-thread scheduler

| | `multi_thread` (default) | `current_thread` |
|---|---|---|
| Worker threads | `num_cpus` (or `worker_threads(n)`) | 1 (the calling thread) |
| Task `Send` bound | Required — tasks may migrate between threads | Not required — all tasks on one thread |
| Use when | Servers, CPU-bound work, anything latency-sensitive | Tests, CLIs, embedded, when `!Send` types are needed |
| Gotcha | `block_in_place` panics on `current_thread` | |

### Worker threads, blocking pool, I/O driver

- **Worker threads** — run async tasks. Never block. Count defaults to `num_cpus::get()`.
- **Blocking thread pool** — spawned on demand by `spawn_blocking`. Threads idle-timeout and are reclaimed. Default max: 512.
- **I/O driver** — a single background thread calling `epoll`/`kqueue`/IOCP. Wakes tasks when I/O is ready. Not a worker thread.

### Runtime builder

```rust
let rt = tokio::runtime::Builder::new_multi_thread()
    .worker_threads(4)
    .max_blocking_threads(32)
    .thread_name("my-worker")
    .thread_stack_size(3 * 1024 * 1024)
    .enable_io()
    .enable_time()
    .build()?;
```

Use `Builder` when embedding Tokio in a library, when running multiple runtimes, or when tuning thread counts for a specific workload. `enable_all()` is shorthand for `enable_io().enable_time()`.

---

## `spawn` vs `spawn_blocking`

### `tokio::spawn`

```rust
let handle: JoinHandle<T> = tokio::spawn(async move { ... });
let result: Result<T, JoinError> = handle.await?;
```

- Schedules an async task on the worker thread pool.
- Future must be `Send + 'static`.
- Completes independently; dropping the handle does **not** cancel the task (detaches it).

### `tokio::task::spawn_blocking`

```rust
let result = tokio::task::spawn_blocking(|| {
    // blocking or CPU-heavy work
    std::fs::read_to_string("file.txt")
}).await??;
```

- Moves the closure to the blocking thread pool, freeing the worker thread.
- Closure need not be `async`. Return value is wrapped in `JoinHandle<T>`.
- The `??` unwraps `JoinError` then the inner `Result`.

### `tokio::task::block_in_place`

```rust
// Only valid in multi_thread runtime. Panics in current_thread.
let result = tokio::task::block_in_place(|| {
    expensive_sync_call()
});
```

- Tells the runtime "this worker thread will block; migrate pending tasks elsewhere."
- Avoids a thread hop vs `spawn_blocking`, but ties up a worker thread.
- Prefer `spawn_blocking` in almost all cases.

### Detecting blocking in async code

Red flags inside `async fn` or `.await` chains:

- `std::thread::sleep` — use `tokio::time::sleep`
- `std::fs::*` — use `tokio::fs::*`
- `std::net::TcpStream` — use `tokio::net::TcpStream`
- Synchronous DB drivers (e.g., `rusqlite`, blocking `postgres`) — wrap in `spawn_blocking`
- CPU-bound loops (encoding, hashing, compression) — `spawn_blocking` or a `rayon` threadpool

---

## `Send + 'static` Constraints

`tokio::spawn` requires `Future: Send + 'static`.

- **`Send`**: the task may be stolen by any worker thread between `.await` points. Everything alive across an await must be `Send`.
- **`'static`**: the task owns all its data; no borrowed references to the spawning frame.

### Common `Send` violations

| Violation | Fix |
|---|---|
| `Rc<T>` captured across await | Replace with `Arc<T>` |
| `RefCell<T>` across await | Use `tokio::sync::Mutex` or restructure |
| `std::sync::MutexGuard` held across await | Drop before awaiting; see Holding Locks section |
| Raw `*mut T` / `*const T` | Wrap in a `Send` newtype if safe |
| Closure capturing `!Send` env | `move` the data out before spawning |

### Common `'static` violations

```rust
// ERROR: `s` is borrowed
let s = String::from("hello");
tokio::spawn(async { println!("{s}") }); // s is &str, not 'static

// FIX: move into the async block
let s = String::from("hello");
tokio::spawn(async move { println!("{s}") });
```

```rust
// ERROR: reference to local
let data: Vec<u8> = load();
tokio::spawn(async { process(&data) }); // &data not 'static

// FIX: clone or Arc
let data = Arc::new(load());
let data2 = Arc::clone(&data);
tokio::spawn(async move { process(&data2) });
```

---

## Holding Locks Across Await Points

### Why it's dangerous

```rust
// COMPILATION ERROR with tokio::spawn (MutexGuard is !Send)
let guard = std::sync::Mutex::new(0_u32);
tokio::spawn(async move {
    let mut g = guard.lock().unwrap();
    *g += 1;
    some_async_fn().await; // guard held across await — !Send
});
```

`std::sync::MutexGuard<T>` is `!Send`. The compiler rejects this when crossing a `tokio::spawn` boundary. However, within `block_in_place` or on a `current_thread` runtime it may compile but is still a latency hazard.

### `tokio::sync::Mutex`

```rust
use tokio::sync::Mutex;
let shared = Arc::new(Mutex::new(Vec::<u32>::new()));

tokio::spawn(async move {
    let mut guard = shared.lock().await; // async lock acquire
    guard.push(42);
    some_async_fn().await; // guard is Send, compiles fine
});
```

`tokio::sync::Mutex` guard is `Send`. Use it when the lock genuinely must be held across an await (e.g., transactional reads).

### Preferred pattern: acquire-extract-release

```rust
let value = {
    let guard = mutex.lock().await;
    guard.clone() // extract what you need
}; // guard dropped here
expensive_async_operation(value).await; // no lock held
```

Minimizes lock contention and avoids `tokio::sync::Mutex` overhead for the common case.

---

## Shared State Patterns

### Read-only shared data

```rust
let config: Arc<Config> = Arc::new(load_config());
// Clone Arc cheaply into each task
tokio::spawn({
    let c = Arc::clone(&config);
    async move { use_config(&c).await }
});
```

### Shared mutable state

Reach for message passing first. When shared state is unavoidable:

```rust
// Arc<Mutex<T>> — exclusive access
let state = Arc::new(tokio::sync::Mutex::new(HashMap::new()));

// Arc<RwLock<T>> — concurrent reads, exclusive writes
let cache = Arc::new(tokio::sync::RwLock::new(HashMap::new()));
```

`tokio::sync::RwLock` write-starves on heavy read load on some platforms; benchmark before choosing.

### Tokio synchronization primitives

| Primitive | Use case |
|---|---|
| `Mutex<T>` | Exclusive mutable access across tasks |
| `RwLock<T>` | Many readers, occasional writer |
| `Semaphore` | Rate limiting, connection pools (`Arc<Semaphore>`) |
| `Notify` | Wake one or all waiters; no payload |
| `Barrier` | N tasks rendezvous before proceeding |
| `OnceCell` / `OnceLock` | Initialize shared data exactly once |

```rust
// Semaphore for limiting concurrency
let sem = Arc::new(Semaphore::new(10));
let permit = sem.acquire().await?;
do_work().await;
drop(permit); // releases slot
```

---

## Channels

### Choosing a channel

| Channel | Senders | Receivers | Value semantics | Use case |
|---|---|---|---|---|
| `mpsc` | Many | One | Each value to one receiver | Task-to-task work queues |
| `oneshot` | One | One | Single value, consumed | Request/response, futures as values |
| `broadcast` | One | Many (cloned rx) | Each receiver gets a copy | Fan-out events; receivers can lag |
| `watch` | One | Many | Only latest value | Config reload, shutdown signals |

### `mpsc`

```rust
let (tx, mut rx) = tokio::sync::mpsc::channel::<Msg>(256); // bounded
let tx2 = tx.clone(); // clone sender freely

tokio::spawn(async move {
    tx.send(Msg::Work).await?; // backpressure when buffer full
    Ok::<_, SendError<_>>(())
});

while let Some(msg) = rx.recv().await {
    handle(msg).await;
}
```

`mpsc::unbounded_channel()` drops backpressure; use only when producers are naturally rate-limited.

### `oneshot`

```rust
let (tx, rx) = tokio::sync::oneshot::channel::<Response>();

tokio::spawn(async move {
    let resp = do_request().await;
    let _ = tx.send(resp); // error if receiver dropped
});

let response = rx.await?; // RecvError if sender dropped
```

### `broadcast`

```rust
let (tx, mut rx1) = tokio::sync::broadcast::channel::<Event>(128);
let mut rx2 = tx.subscribe();

tx.send(Event::Update)?; // error if no receivers

// Each receiver independently consumes; may return RecvError::Lagged
match rx1.recv().await {
    Ok(event) => handle(event),
    Err(RecvError::Lagged(n)) => warn!("dropped {n} messages"),
    Err(RecvError::Closed) => break,
}
```

### `watch`

```rust
let (tx, rx) = tokio::sync::watch::channel(Config::default());

// Writer
tx.send(new_config)?;

// Readers — multiple tasks can clone rx
let mut rx2 = rx.clone();
loop {
    rx2.changed().await?; // waits for a new value
    let cfg = rx2.borrow_and_update().clone();
    apply(cfg);
}
```

---

## Structured Concurrency with `JoinSet`

`JoinSet` owns a collection of tasks; dropping it cancels all remaining tasks.

```rust
use tokio::task::JoinSet;

let mut set = JoinSet::new();

for url in urls {
    set.spawn(fetch(url));
}

let mut results = Vec::new();
while let Some(res) = set.join_next().await {
    match res {
        Ok(data) => results.push(data),
        Err(e) if e.is_panic() => eprintln!("task panicked"),
        Err(e) => eprintln!("join error: {e}"),
    }
}
```

`join_next()` returns `None` when the set is empty. To abort remaining tasks on first error:

```rust
while let Some(res) = set.join_next().await {
    if let Err(e) = res? {
        set.abort_all(); // cancel outstanding tasks
        return Err(e);
    }
}
```

### `JoinSet` vs alternatives

| | `JoinSet` | `tokio::join!` | `futures::select!` |
|---|---|---|---|
| Task count | Dynamic | Fixed at compile time | Fixed at compile time |
| Scope | Tasks outlive caller frame | Same scope | Same scope |
| Cancel on drop | Yes | No (awaited inline) | No |
| Use when | Fan-out with unknown N | Small fixed set of futures | Race or select-first |

---

## `select!`

### Basic usage

```rust
tokio::select! {
    result = operation_a() => handle_a(result),
    result = operation_b() => handle_b(result),
    _ = tokio::time::sleep(Duration::from_secs(5)) => timeout(),
}
```

- Exactly one branch executes; all others are cancelled (dropped).
- Branches are polled in a pseudorandom order by default to avoid starvation. Use `biased;` to poll top-to-bottom.

### Cancellation safety

A future is **cancellation-safe** if dropping it mid-poll loses no data and leaves no corrupted state.

| Primitive | Cancellation-safe? |
|---|---|
| `mpsc::Receiver::recv()` | Yes — message stays in channel |
| `oneshot::Receiver::await` | Yes |
| `tokio::time::sleep` | Yes |
| `Notify::notified()` | Yes (but may miss notification) |
| `AsyncReadExt::read_to_end` | No — partial data discarded |
| `AsyncWriteExt::write_all` | No — partial write possible |

When using a non-cancellation-safe future in `select!`, consider using a `tokio_util::io::ReaderStream` or pinning+fusing the future outside the loop.

### Graceful shutdown pattern

```rust
let (shutdown_tx, mut shutdown_rx) = tokio::sync::watch::channel(false);

// In the main task
tokio::select! {
    _ = signal::ctrl_c() => {
        let _ = shutdown_tx.send(true);
    }
    _ = serve(&mut shutdown_rx) => {}
}

// In worker tasks
async fn serve(shutdown: &mut watch::Receiver<bool>) {
    loop {
        tokio::select! {
            biased;
            _ = shutdown.changed() => break,
            conn = listener.accept() => handle(conn).await,
        }
    }
}
```

`biased;` ensures the shutdown branch is checked first every poll.

---

## Streams

### Iteration with `StreamExt`

```rust
use tokio_stream::StreamExt;

let mut stream = tokio_stream::iter(vec![1u32, 2, 3]);
while let Some(item) = stream.next().await {
    process(item).await;
}
```

### Channel as stream

```rust
use tokio_stream::wrappers::ReceiverStream;

let (tx, rx) = mpsc::channel(32);
let mut stream = ReceiverStream::new(rx);
while let Some(item) = stream.next().await {
    handle(item);
}
```

Also: `BroadcastStream`, `WatchStream`, `UnboundedReceiverStream`.

### Periodic work

```rust
use tokio::time::{interval, Duration};

let mut ticker = interval(Duration::from_secs(60));
loop {
    ticker.tick().await;
    do_periodic_work().await;
}
```

`interval` fires immediately on first `tick()`. Use `interval_at(start, period)` to delay the first tick.

`MissedTickBehavior::Skip` (default) catches up by skipping missed ticks; `Burst` delivers them all; `Delay` resets the interval from the current time.

---

## Common Async Mistakes

### Fire-and-forget without error handling

```rust
// BAD: panics and errors are silently swallowed
tokio::spawn(async { risky_work().await });

// GOOD: log or propagate
tokio::spawn(async {
    if let Err(e) = risky_work().await {
        eprintln!("task failed: {e}");
    }
});

// Or: retain the handle and await it at a meaningful boundary
let handle = tokio::spawn(async { risky_work().await });
handle.await??;
```

### `async` on CPU-bound functions

```rust
// BAD: blocks a worker thread
async fn hash_password(pw: String) -> String {
    bcrypt::hash(&pw, 12).unwrap() // CPU-bound, seconds of blocking
}

// GOOD
async fn hash_password(pw: String) -> Result<String, JoinError> {
    tokio::task::spawn_blocking(move || bcrypt::hash(&pw, 12).unwrap()).await
}
```

### `std::sync::MutexGuard` across `.await` (silent in some contexts)

```rust
// Compiles on current_thread runtime or in non-spawned async, but wrong:
async fn bad(m: Arc<std::sync::Mutex<u32>>) {
    let mut g = m.lock().unwrap();
    *g += 1;
    some_io().await; // guard may be held across OS thread boundary on resume
}

// Fix: drop guard before await
async fn good(m: Arc<std::sync::Mutex<u32>>) {
    { let mut g = m.lock().unwrap(); *g += 1; } // dropped here
    some_io().await;
}
```

### Infinite loop without a yield point

```rust
// BAD: starves other tasks on the same thread
async fn spin() {
    loop {
        if check_condition() { break; }
    }
}

// GOOD: yield to the scheduler each iteration
async fn spin() {
    loop {
        if check_condition() { break; }
        tokio::task::yield_now().await;
    }
}
```

In practice, replace hot-spin loops with `Notify`, `watch`, or `sleep`-based polling.

### Not driving a future to completion

```rust
// BAD: future created but never polled — does nothing
let _ = some_async_fn(); // no .await, no spawn

// GOOD
some_async_fn().await;
// or
tokio::spawn(some_async_fn());
```

Rust futures are lazy — they do nothing until polled.
