# Unsafe Governance Reference

## What `unsafe` Actually Means

`unsafe` is not an escape hatch from the borrow checker. The borrow checker runs inside `unsafe` blocks exactly as it does outside them. `unsafe` grants access to five capabilities the compiler cannot verify independently:

| Superpower | What it allows |
|---|---|
| Dereference raw pointers | `*const T` / `*mut T` — no lifetime, no validity guarantee |
| Call unsafe functions/methods | Any `unsafe fn`, including most `extern "C"` functions |
| Access/modify mutable statics | `static mut FOO: T` — unsynchronised global mutation |
| Implement unsafe traits | `unsafe impl Send for T`, `unsafe impl Sync for T`, etc. |
| Access union fields | Reading a union field reinterprets the stored bytes |

Everything else — move rules, borrow rules, lifetime checking, drop ordering — is enforced identically. Writing `unsafe { x.borrow() }` does not suppress a borrow-check error; it compiles only if the borrow is valid.

---

## When `unsafe` Is Justified

Use `unsafe` when the invariant is real and provable, not when the borrow checker is inconvenient.

**Justified:**
- FFI — calling C functions is inherently `unsafe`; there is no alternative
- Zero-copy data structures where aliasing rules can be proven at the call site (e.g. splitting a slice into non-overlapping mutable halves)
- Hot-path bounds elision when the proof is local and checkable (`get_unchecked` inside a loop whose bounds are already validated once)
- Implementing `Send`/`Sync` for custom types with manually-managed thread safety (e.g. a wrapper around a C handle that is documented thread-safe)
- Low-level primitives that require raw pointer manipulation (`Arc`, `Vec`, `MutexGuard` internals)

**Not justified:**
- Borrow-checker pressure — that signals a design problem; restructure lifetimes or ownership instead
- "It's obviously fine" — if it is obvious, write the `SAFETY` proof; if you cannot, it is not justified
- Avoiding runtime cost speculatively — profile first; bounds checks are nearly free in non-hot code

---

## The SAFETY Comment Requirement

Every `unsafe` block and every `unsafe fn` declaration must be preceded by a `// SAFETY:` comment. This is not a style preference — it is the evidence record that the invariant has been thought through.

### Required content
1. What invariant makes the operation safe
2. Why that invariant holds at this specific call site

### Acceptable

```rust
// SAFETY: `ptr` was obtained from `Box::into_raw` and has not been aliased
// since then; we are the sole owner and are restoring ownership here.
let value = unsafe { Box::from_raw(ptr) };
```

```rust
// SAFETY: `i` is bounded by `self.len()` which was checked at the top of
// this function; no element has been removed since that check.
let elem = unsafe { self.buf.get_unchecked(i) };
```

### Not acceptable

```rust
// SAFETY: this is fine
let x = unsafe { *ptr };

// SAFETY: checked above
let x = unsafe { *ptr };

// safe because the caller guarantees it
let x = unsafe { *ptr };
```

These describe nothing. A comment that does not identify the specific invariant and its proof at the call site is not a SAFETY comment.

### `unsafe fn` — document at the declaration

```rust
/// # Safety
///
/// `ptr` must be non-null, properly aligned for `T`, and point to an
/// initialised `T` that is valid for reads for the duration of `'a`.
unsafe fn borrow_raw<'a, T>(ptr: *const T) -> &'a T {
    // SAFETY: invariants stated in the Safety doc above; caller is responsible.
    unsafe { &*ptr }
}
```

The `/// # Safety` doc section is the contract for callers. The `// SAFETY:` comment inside is the proof for the implementation.

---

## Encapsulation Boundary Rules

Unsafe implementation details must never leak through the public API. Safe callers must be unable to trigger UB.

### Wrap every `unsafe` block in a safe abstraction

```rust
// Private: unsafe internals
mod raw {
    pub(super) unsafe fn split_at_unchecked<T>(
        slice: &mut [T], mid: usize
    ) -> (&mut [T], &mut [T]) {
        let ptr = slice.as_mut_ptr();
        // SAFETY: caller guarantees mid <= slice.len(); the two halves are
        // non-overlapping because they span disjoint index ranges.
        unsafe {
            (
                std::slice::from_raw_parts_mut(ptr, mid),
                std::slice::from_raw_parts_mut(ptr.add(mid), slice.len() - mid),
            )
        }
    }
}

// Public: safe wrapper that enforces the invariant
pub fn split_checked<T>(slice: &mut [T], mid: usize) -> (&mut [T], &mut [T]) {
    assert!(mid <= slice.len(), "mid out of bounds");
    // SAFETY: mid <= slice.len() proven by the assert above.
    unsafe { raw::split_at_unchecked(slice, mid) }
}
```

### The `unsafe trait` pattern

Mark a trait `unsafe` when *implementors* must uphold an invariant the compiler cannot check. Users of the trait get a safe API; implementors take on the proof burden.

```rust
/// # Safety
///
/// Any type implementing this trait must ensure that no two values of this
/// type with the same `id()` exist concurrently in the same process.
pub unsafe trait GloballyUnique {
    fn id(&self) -> u64;
}

// Implementor takes on the proof:
// SAFETY: `Widget` uses a process-global atomic counter to assign IDs;
// each Widget gets a unique ID at construction and IDs are never reused.
unsafe impl GloballyUnique for Widget {
    fn id(&self) -> u64 { self.id }
}
```

### Never expose raw pointers in public APIs

| Instead of | Use |
|---|---|
| `*mut T` in a return position | `Box<T>`, `Vec<T>`, or a newtype wrapper |
| `*const T` as a view | `&T` or `&[T]` with correct lifetime |
| Pointer + length pair | `&[T]` or a safe slice wrapper |

Raw pointers carry no lifetime. The moment they cross the public API boundary the caller has no way to reason about validity.

---

## Common Unsound Patterns

These produce undefined behaviour. The compiler will not warn about most of them.

### Transmuting between types of different sizes

```rust
// UB: i32 is 4 bytes, i64 is 8 bytes — reads garbage memory.
let x: i64 = unsafe { std::mem::transmute(42i32) };
```

Use `as` casts or `From`/`Into` instead. If you need `transmute`, sizes must match exactly. Consider `transmute_copy` only if you understand byte semantics.

### Simultaneous `&mut T` and `&T` to the same data

```rust
let mut x = 42u32;
let r = &x;
let m = &mut x;     // borrow checker catches this in safe code
// In unsafe: creating both through raw pointers is still UB.
let r: &u32 = unsafe { &*(&x as *const u32) };
let m: &mut u32 = unsafe { &mut *(&mut x as *mut u32) };
// Using r and m simultaneously is UB regardless of the unsafe block.
```

The borrow checker enforces this in safe code. In `unsafe` you can construct both; using them together is still UB.

### Raw pointer invalidation via reallocation

```rust
let mut v = vec![1u8, 2, 3];
let ptr = v.as_ptr();
v.push(4);          // may reallocate; ptr is now dangling
let _ = unsafe { *ptr };  // UB: ptr may point to freed memory
```

Do not hold raw pointers into a `Vec` across any operation that may reallocate. Stabilise the buffer first (`reserve` the exact capacity, then confirm no reallocation will occur) or use indices.

### `mem::forget` on types whose `Drop` releases resources

```rust
// Wrong: leaks the file descriptor; Drop never runs.
std::mem::forget(my_file);

// Right: wrap in ManuallyDrop when you need deferred drop.
let mut md = std::mem::ManuallyDrop::new(my_file);
// ... later, when you are ready to drop:
unsafe { std::mem::ManuallyDrop::drop(&mut md) };
```

`mem::forget` is safe (it cannot cause UB by itself), but pairing it with types that own resources causes resource leaks. Use `ManuallyDrop<T>` when you need precise drop timing.

### Casting `*const T` to `*mut T` through a shared reference

```rust
let x = 42u32;
let r: &u32 = &x;
// UB: &T guarantees no mutation; the optimizer may have placed x in
// read-only memory or cached its value in a register.
let m = r as *const u32 as *mut u32;
unsafe { *m = 99 };  // UB
```

If you need mutation, the original binding must be `mut` and the pointer must be `*mut T` from the start. Never derive mutability from an immutable reference.

---

## `Send` and `Sync` as Unsafe Traits

Auto-derived `Send` and `Sync` are correct for the vast majority of types. Writing `unsafe impl` is a manual proof.

### `unsafe impl Send for T`

You assert: *T can be transferred to another thread without UB.*

Requires:
- No raw pointers that alias data owned by another thread
- No `Rc<_>` (non-atomic ref-count) or similar non-thread-safe handles
- Any interior mutability uses synchronised primitives (`Mutex`, `RwLock`, atomics)

```rust
// SAFETY: `MyHandle` wraps a C handle that the library documents as
// safe to move between threads. No shared mutable state is accessed
// without the internal mutex.
unsafe impl Send for MyHandle {}
```

### `unsafe impl Sync for T`

You assert: *`&T` can be shared across threads without UB.*

Requires:
- All mutation goes through synchronised interior mutability
- No aliasing of mutable data through `&T`

### Opting out with negative impls

```rust
// T must stay on the thread that created it.
impl !Send for MyThreadLocal {}
impl !Sync for MyThreadLocal {}
```

Use negative impls (or wrap in `PhantomData<*mut ()>`) when the type inherently cannot cross threads — e.g. a type bound to a thread-local handle.

---

## FFI Patterns

### Wrap every `extern "C"` call

```rust
extern "C" {
    fn raw_compress(src: *const u8, src_len: usize, dst: *mut u8) -> i32;
}

// Public safe wrapper: validates inputs, handles errors.
pub fn compress(src: &[u8], dst: &mut Vec<u8>) -> Result<(), CompressError> {
    dst.reserve(src.len());
    // SAFETY: both pointers are valid for their respective lengths;
    // dst has capacity >= src.len() after the reserve above.
    let rc = unsafe {
        raw_compress(src.as_ptr(), src.len(), dst.as_mut_ptr())
    };
    if rc < 0 {
        return Err(CompressError::Failed(rc));
    }
    // SAFETY: raw_compress wrote exactly rc bytes on success.
    unsafe { dst.set_len(dst.len() + rc as usize) };
    Ok(())
}
```

### Layout compatibility: `#[repr(C)]`

All types crossing an FFI boundary must be `#[repr(C)]`. Without it, Rust may reorder fields.

```rust
#[repr(C)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}
```

Enums crossing FFI also need `#[repr(C)]` (or `#[repr(u32)]`, etc.) to guarantee discriminant layout.

### Null pointer checks

```rust
pub fn process(ptr: *const Config) -> Result<(), Error> {
    if ptr.is_null() {
        return Err(Error::NullPointer);
    }
    // SAFETY: ptr is non-null (checked above); the caller documents that
    // it points to a valid Config that outlives this call.
    let config = unsafe { &*ptr };
    // ...
}
```

Never assume C callers pass valid pointers.

### String conversion

| Situation | Type |
|---|---|
| C string → Rust (borrowed) | `CStr::from_ptr(ptr)` → `.to_str()?` |
| Rust string → C (owned, null-terminated) | `CString::new(s)?` |
| Static C string literal | `c"hello"` (Rust 1.77+) |

Never pass `&str` or `String` across FFI — they are not null-terminated and their layout is not C-compatible.

### Lifetime documentation

Raw pointers from C carry no lifetime information. Document the expected lifetime at the declaration:

```rust
extern "C" {
    /// Returns a pointer to the global config singleton.
    /// The pointer is valid for the lifetime of the process and must not
    /// be freed by Rust code.
    fn get_global_config() -> *const Config;
}
```

---

## Miri — the Undefined Behaviour Detector

```sh
cargo miri test
```

Run this on any crate that contains `unsafe`. Make it a required CI job for `unsafe`-heavy crates.

### What Miri detects

- Use-after-free
- Reads of uninitialised memory
- Invalid pointer arithmetic (out-of-bounds, misaligned)
- Violations of Stacked Borrows aliasing rules (detects the `&mut` + `&` simultaneous access pattern)
- Data races (with `-Zmiri-track-raw-pointers` and the Miri race detector flag)

```sh
MIRIFLAGS="-Zmiri-track-raw-pointers" cargo miri test
```

### What Miri does not detect

- Logic errors
- Multi-threaded races without the race detector enabled
- Hardware-specific behaviour (SIMD, memory-mapped I/O)
- UB in code that is never exercised by the test suite

### Practical workflow

1. Add `unsafe`
2. Write the `SAFETY` proof
3. Run `cargo miri test` locally
4. Add `cargo miri test` to CI for that crate

Miri is slow (expect 10–100× slower than native). Run it on unit tests, not integration tests with large data sets, unless you need the coverage.

---

## Soundness vs Safety

These terms have precise meanings. Conflating them is a class of critical bug.

| Term | Definition |
|---|---|
| **Safe code** | Code that contains no `unsafe` blocks; cannot trigger UB on its own |
| **Sound API** | A public API where no combination of safe calls can trigger UB, even if the implementation uses `unsafe` |
| **Unsound** | A safe public API that can be used to trigger UB — this is a **critical correctness bug** |

### Unsound example

```rust
pub struct ByteBuf {
    ptr: *mut u8,
    len: usize,
}

impl ByteBuf {
    pub fn as_slice(&self) -> &[u8] {
        // SAFETY: ??? — ptr may have been freed if the caller dropped
        // the backing allocation. This API is unsound.
        unsafe { std::slice::from_raw_parts(self.ptr, self.len) }
    }
}
```

A caller who triggers use-after-free through `as_slice()` alone — using only safe code — has found an unsoundness. Fix: ensure the lifetime of the returned slice is tied to the `ByteBuf`, or take ownership of the allocation inside `ByteBuf` so it cannot be freed externally.

### The standard

- Unsoundness in a library's public API is equivalent to a memory-safety CVE.
- Internal `unsafe` with provably correct invariants is acceptable.
- When in doubt: reduce the public API surface, return owned types, and push the `unsafe` deeper.
