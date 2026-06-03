# Ownership and Borrowing — Principal-Level Reference

## Borrow Checker Mental Model

### The Three Rules

1. Every value has exactly one owner.
2. At any point, you may have **either** any number of shared references (`&T`) **or** exactly one mutable reference (`&mut T`) — never both simultaneously.
3. References must not outlive the value they point to.

### Why These Rules Exist

| Rule | Prevents |
|------|----------|
| Single owner | Double-free, use-after-free |
| Shared XOR mutable | Data races at compile time; no need for runtime synchronisation on `!Send` types |
| Ref lifetime ≤ owner lifetime | Dangling pointers |

No garbage collector, no runtime checks — these properties are proven at compile time by the borrow checker.

### Reading Borrow Checker Errors as Design Feedback

The borrow checker does not misfire. Every error is one of a small set of structural problems:

- **Lifetime too short** — you're trying to return a reference to something that won't live long enough. Fix: return owned data, use `Arc`, or restructure so the owner lives in the right scope.
- **Simultaneous alias + mutation** — you hold a `&T` and want `&mut T` at the same time. Fix: drop or scope-limit the shared ref first, or use interior mutability.
- **Moved value used again** — you transferred ownership then tried to use the original binding. Fix: clone before the move, borrow instead of move, or refactor to keep one owner.

Reaching for `.clone()` to silence the error is almost always wrong; it hides the design problem the borrow checker found.

---

## Lifetimes

### Elision Rules

The compiler inserts lifetime parameters automatically when the rules are unambiguous:

1. Each elided input lifetime gets its own distinct parameter.
2. If there is exactly one input lifetime parameter, it is assigned to all output lifetimes.
3. If one of the inputs is `&self` or `&mut self`, its lifetime is assigned to all output lifetimes.

```rust
// All equivalent after elision is applied:
fn first(s: &str) -> &str { ... }
fn first<'a>(s: &'a str) -> &'a str { ... }
```

### When Explicit Lifetimes Are Required

**Structs holding references** — the struct must declare the lifetime so the compiler knows the reference constraint:

```rust
struct Tokenizer<'a> {
    source: &'a str,
    pos: usize,
}
// The Tokenizer cannot outlive the &str it borrows.
```

**Multiple ref parameters with ambiguous output lifetime** — elision rule 2 only fires for a single input lifetime; with multiple inputs you must be explicit:

```rust
// Won't compile without explicit lifetimes:
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

**`impl Trait` with references** — the compiler needs to know how the returned `impl Trait` relates to the input lifetimes:

```rust
fn make_iter<'a>(s: &'a str) -> impl Iterator<Item = &'a str> + 'a {
    s.split(',')
}
```

### `'static`

`'static` means the value is valid for the entire program lifetime. It does **not** mean "lives forever" in the sense of being leaked — it means no borrowed data with a shorter lifetime is reachable through it.

Common sources:
- String literals: `&'static str` lives in the binary's data segment.
- Owned types with no references inside them automatically satisfy `T: 'static`.
- `Arc<T>` where `T: 'static` — once cloned out of a scope, the `Arc` can be sent anywhere.
- `Box<dyn Trait + 'static>` — the heap allocation can outlive any particular stack frame.

`'static` as a bound (`T: 'static`) is common in thread-spawning and async contexts where the runtime may outlive the creating scope.

### Lifetime Bounds: `'a: 'b`

`'a: 'b` reads "`'a` outlives `'b`". Use when you need to guarantee one reference lives at least as long as another:

```rust
fn shorter<'a, 'b: 'a>(x: &'a str, y: &'b str) -> &'a str {
    // y is guaranteed to outlive 'a, so it's safe to return either
    if x.len() < y.len() { x } else { y }
}
```

Appears frequently in iterator adaptors and combinators that hold references to other references.

### Self-Referential Structs

A struct cannot hold both a value and a reference into that same value through normal Rust references — the address is not stable until the value is pinned.

```rust
// This does not compile — self-reference is not expressible with &:
struct Bad {
    data: String,
    ptr: &str, // can't borrow from `data` in the same struct
}
```

**Why it's hard:** Rust can move values freely (copying bytes to a new location). A reference into a field becomes dangling the moment the struct is moved.

**`Pin<P>`** prevents the value behind pointer `P` from being moved after pinning. Required by async state machines (which capture local references across `.await` points).

```rust
use std::pin::Pin;

// Pinned heap allocation — address is now stable:
let pinned: Pin<Box<MyType>> = Box::pin(MyType::new());
```

Implementing self-referential structs manually via `Pin` and `unsafe` is error-prone. The practical options:

| Approach | When to use |
|----------|-------------|
| Redesign to avoid self-reference | Always try first |
| `ouroboros` crate | Safe abstraction over self-referential structs |
| `async fn` / `Future` | Let the compiler generate the pinned state machine |
| Raw `unsafe` + `Pin` | Only when you control the allocator and have a compelling reason |

---

## RAII and Drop

### `Drop` Trait

`Drop::drop` runs when a value goes out of scope or is explicitly dropped with `drop(val)`. You cannot call `drop` directly on a value you own through the trait — use the free function `drop()`.

**Drop order:**
- Local variables drop in **reverse declaration order** (last declared drops first).
- Struct fields drop in **declaration order** (first field drops first), then the struct itself.

```rust
struct A; struct B; struct C;
impl Drop for A { fn drop(&mut self) { println!("A"); } }
impl Drop for B { fn drop(&mut self) { println!("B"); } }

struct Pair { first: A, second: B }
// Dropping a Pair prints: A, B  (declaration order)

fn main() {
    let _x = A; // drops last
    let _y = B; // drops first (reverse of declaration)
    // prints: B, A
}
```

### `ManuallyDrop<T>`

Wraps a value and **prevents its destructor from running**. Used when:
- You're building a custom allocator or arena and want to reclaim memory without running `Drop`.
- You need to move a field out of a struct inside `Drop` (normally forbidden).
- FFI: you're handing ownership to C code that will free the memory.

```rust
use std::mem::ManuallyDrop;

let v: ManuallyDrop<Vec<i32>> = ManuallyDrop::new(vec![1, 2, 3]);
// Vec's Drop won't run — memory is not freed unless you call ManuallyDrop::drop explicitly.
```

Never use `ManuallyDrop` to work around a lifetime or borrow issue — that's a memory leak or unsoundness waiting to happen.

### Guard Types as RAII

The canonical example is `MutexGuard<'_, T>`: acquiring the lock returns a guard; when the guard drops, the lock releases. Implement the same pattern for any "acquire on entry, release on exit" resource.

```rust
struct ConnectionGuard<'a> {
    pool: &'a Pool,
    conn: Connection,
}

impl Drop for ConnectionGuard<'_> {
    fn drop(&mut self) {
        self.pool.return_connection(self.conn.take());
    }
}
```

Key properties of a well-designed guard:
- Holds a reference (or `Arc`) to the resource it releases back to.
- Is `!Send` if the underlying resource is thread-local (e.g., `MutexGuard` is `!Send`).
- Does not implement `Clone` — ownership of the release must be unique.

---

## Interior Mutability

The `&T` → immutable, `&mut T` → mutable invariant is an alias contract, not a hardware fact. Interior mutability types punch through it safely (or unsafely with a contract).

### `Cell<T>`

- Single-threaded only (`!Sync`).
- Values must be `Copy` (or you use `Cell::replace` / `Cell::take`).
- No references into the value are ever handed out — you copy in and copy out.
- Zero runtime overhead.

```rust
use std::cell::Cell;

let x = Cell::new(0u32);
x.set(x.get() + 1);
```

Use for small counters or flags inside types that are otherwise immutable by reference.

### `RefCell<T>`

- Single-threaded only (`!Sync`).
- Runtime borrow tracking: `borrow()` returns `Ref<T>`, `borrow_mut()` returns `RefMut<T>`.
- **Panics** at runtime if you violate the shared XOR mutable rule.
- Use sparingly — panics in production are worse than compile errors.

```rust
use std::cell::RefCell;

let v = RefCell::new(vec![1, 2]);
v.borrow_mut().push(3);          // fine
let _r = v.borrow();
v.borrow_mut().push(4);          // PANICS — shared borrow active
```

`try_borrow` / `try_borrow_mut` return `Result` instead of panicking — prefer these in library code.

### `Mutex<T>`

- Multi-threaded (`Sync`).
- Blocking: `lock()` blocks until the lock is available, returns `MutexGuard<T>`.
- **Poisoning**: if a thread panics while holding the lock, subsequent `lock()` calls return `Err(PoisonError)`. The guard is still recoverable via `into_inner()` if the data is known to be consistent.

```rust
use std::sync::Mutex;

let m = Mutex::new(0i32);
{
    let mut g = m.lock().unwrap(); // unwrap poisons-on-panic; use .unwrap_or_else for recovery
    *g += 1;
} // MutexGuard drops here, lock releases
```

### `RwLock<T>`

- Multi-threaded (`Sync`).
- Multiple concurrent readers via `read()`, exclusive writer via `write()`.
- **Beats `Mutex` when:** reads are frequent, writes are rare, and read-side contention matters.
- **Does not beat `Mutex` when:** writes are as frequent as reads, or your platform's `RwLock` has writer starvation issues (check your OS).

### `Atomic*` Types

In `std::sync::atomic`: `AtomicBool`, `AtomicI32`, `AtomicU64`, `AtomicUsize`, `AtomicPtr<T>`, etc.

Lock-free for primitive values. No poisoning. Useful for counters, flags, and publish-subscribe patterns.

**`Ordering` choices:**

| Ordering | Guarantees | Use when |
|----------|-----------|----------|
| `Relaxed` | No ordering constraints, just atomicity | Counters where exact order doesn't matter (stats, IDs) |
| `Acquire` | No reads/writes after this op can be reordered before it | Load side of a publish-subscribe flag |
| `Release` | No reads/writes before this op can be reordered after it | Store side of a publish-subscribe flag |
| `AcqRel` | Acquire + Release on a single RMW op | Compare-and-swap that both reads and writes |
| `SeqCst` | Total order across all `SeqCst` ops on all threads | Rarely needed; use when Acquire/Release is insufficient and you can't reason why |

The classic pattern:

```rust
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

let ready = Arc::new(AtomicBool::new(false));

// Writer thread:
ready.store(true, Ordering::Release);

// Reader thread:
while !ready.load(Ordering::Acquire) { std::hint::spin_loop(); }
// All writes before the Release are visible here.
```

### Decision Tree: Which Interior Mutability Type to Pick

```
Is this used across threads?
├── No
│   ├── Value is Copy and you never need a reference into it → Cell<T>
│   └── You need &T or &mut T to the value → RefCell<T>
│       (accept the runtime panic risk; prefer try_borrow)
└── Yes
    ├── Single primitive value, performance-critical → Atomic*
    ├── Reads >> writes → RwLock<T>
    └── Otherwise → Mutex<T>
```

---

## `Cow<'a, B>`

`Cow` (Clone On Write) is an enum: `Borrowed(&'a B)` or `Owned(<B as ToOwned>::Owned)`.

```rust
use std::borrow::Cow;

fn normalize(s: &str) -> Cow<'_, str> {
    if s.contains('\\') {
        Cow::Owned(s.replace('\\', "/"))
    } else {
        Cow::Borrowed(s)  // no allocation
    }
}
```

**Pays off when:**
- A function sometimes needs to modify its input and sometimes can return it as-is.
- You want a single return type that avoids unnecessary clones.

**Common patterns:**

| Type | Use case |
|------|----------|
| `Cow<'_, str>` | Config values, log messages, paths that may need normalisation |
| `Cow<'_, [T]>` | Slices that may need padding, filtering, or deduplication |
| `Cow<'_, Path>` | Path manipulation that might add/remove components |

`Cow` implements `Deref<Target = B>`, so you can call `&str` methods directly without matching.

Use `into_owned()` when you need a fully owned value unconditionally. Use `to_mut()` when you need `&mut B` — it clones on first write and reuses on subsequent writes within the same call.

---

## Common Ownership Mistakes and Their Fixes

### Clone to Satisfy the Borrow Checker

```rust
// Smell: cloning because the borrow checker complained
let key = map.keys().next().unwrap().clone();
map.remove(&key);
```

This is sometimes correct (when you genuinely need two independent owners), but often signals that the data structure or API is fighting the borrow checker. Ask: should the caller own this data? Should the container use indices instead of references? Should the function take ownership instead of borrowing?

### Holding a Lock Across an `.await` Point

In async code (Tokio, async-std), a `MutexGuard` held across `.await` prevents the future from being `Send`, and may deadlock if the executor is single-threaded.

```rust
// WRONG: MutexGuard held across await
async fn bad(m: &Mutex<Data>) {
    let guard = m.lock().unwrap();
    do_io().await;          // guard still held here
    use_data(&*guard);
}

// CORRECT: drop guard before await
async fn good(m: &Mutex<Data>) {
    let value = {
        let guard = m.lock().unwrap();
        guard.clone()       // or extract what you need
    };                      // guard dropped here
    do_io().await;
    use_value(value);
}
```

Use `tokio::sync::Mutex` (async-aware) if you genuinely need to hold a lock across an await point — it yields rather than blocking the thread.

### Returning References to Local Data

This is always a compile error. The fix is almost always ownership transfer:

```rust
// WRONG: reference to local variable
fn make_greeting(name: &str) -> &str {
    let s = format!("Hello, {name}!");
    &s                          // error: `s` does not live long enough
}

// CORRECT: return owned String
fn make_greeting(name: &str) -> String {
    format!("Hello, {name}!")
}
```

If a `&'static str` is genuinely appropriate (compile-time-known values), use `once_cell` or `std::sync::OnceLock` to back it with a static allocation. Do not use `Box::leak` to silence the borrow checker — that's a deliberate leak and should be a conscious, documented decision.
