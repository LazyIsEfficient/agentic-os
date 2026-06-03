# Type System and API Design

## Newtype Pattern

### What and Why

A newtype wraps a single value in a tuple struct to create a distinct type:

```rust
struct UserId(Uuid);
struct OrderId(Uuid);
```

This prevents `UserId` from being passed where `OrderId` is expected even though both wrap `Uuid`. Secondary uses: bypassing the orphan rule (implementing foreign traits on foreign types), adding domain invariants, and controlling which methods callers see.

### Standard Trait Implementations

```rust
use std::fmt;
use std::ops::Deref;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct UserId(Uuid);

// Deref for ergonomic access to inner methods without exposing From<Uuid>
impl Deref for UserId {
    type Target = Uuid;
    fn deref(&self) -> &Uuid { &self.0 }
}

// From<Uuid> — caller says "I have a Uuid, make me a UserId"
impl From<Uuid> for UserId {
    fn from(id: Uuid) -> Self { Self(id) }
}

impl fmt::Display for UserId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "user:{}", self.0)
    }
}
```

**Derive vs manual:**

| Trait | Default action | When to override |
|---|---|---|
| `Debug` | Shows `UserId(...)` | Redact sensitive data |
| `Display` | — (no derive) | Always manual; add domain prefix |
| `PartialEq`, `Eq` | Delegates to inner | Almost never |
| `Hash` | Delegates to inner | Almost never |
| `Clone`, `Copy` | Delegates | If inner doesn't `Copy`, drop `Copy` |
| `Serialize`/`Deserialize` | Wraps inner format | When wire format must match inner directly, use `#[serde(transparent)]` |

Use `#[serde(transparent)]` to make `UserId` serialize as a plain UUID string rather than `{"0": "..."}`.

### Newtype with Validation

```rust
#[derive(Debug, Clone)]
struct Email(String);

#[derive(Debug)]
struct InvalidEmail(String);

impl TryFrom<String> for Email {
    type Error = InvalidEmail;

    fn try_from(s: String) -> Result<Self, Self::Error> {
        if s.contains('@') && s.contains('.') {
            Ok(Self(s))
        } else {
            Err(InvalidEmail(s))
        }
    }
}
```

Implement `TryFrom` for fallible construction. Avoid providing `From<String>` — it signals infallibility. Provide a `fn as_str(&self) -> &str` or `Deref<Target = str>` for read access; avoid exposing the inner field directly so the invariant cannot be violated after construction.

---

## Typestate Machines

### Core Pattern

Encode lifecycle state in a type parameter so invalid transitions fail at compile time:

```rust
use std::marker::PhantomData;

struct Disconnected;
struct Connected;
struct Authenticated;

struct Connection<S> {
    addr: std::net::SocketAddr,
    stream: Option<std::net::TcpStream>,
    _state: PhantomData<S>,
}

impl Connection<Disconnected> {
    pub fn new(addr: std::net::SocketAddr) -> Self {
        Self { addr, stream: None, _state: PhantomData }
    }

    pub fn connect(self) -> std::io::Result<Connection<Connected>> {
        let stream = std::net::TcpStream::connect(self.addr)?;
        Ok(Connection { addr: self.addr, stream: Some(stream), _state: PhantomData })
    }
}

impl Connection<Connected> {
    pub fn authenticate(self, token: &str) -> Result<Connection<Authenticated>, AuthError> {
        // validate token...
        Ok(Connection { addr: self.addr, stream: self.stream, _state: PhantomData })
    }
}

impl Connection<Authenticated> {
    pub fn send(&mut self, data: &[u8]) -> std::io::Result<()> { todo!() }
}
```

`send` is only callable on `Connection<Authenticated>`. Calling it on `Connection<Connected>` is a compile error.

### PhantomData

`PhantomData<S>` is zero-sized. Use it when the state type `S` has no runtime representation. The field tells the compiler "this struct logically owns/uses type `S`" — necessary for variance, drop check, and to avoid `error[E0392]: parameter S is never used`.

### When Typestate Pays Off vs Over-Engineering

**Use typestate when:**
- The API has a linear or branching lifecycle where calling methods out of order causes logic errors (connection, transaction, HTTP request builder)
- State transitions are permanent (you consume `self`, return a new state)
- The type is library-facing — callers should not need to track state themselves

**Skip typestate when:**
- Transitions are reversible or frequent — the ergonomic cost of consuming `self` on every step is high
- There are more than ~4–5 states — the combinatorial explosion of `impl` blocks is worse than a runtime enum
- The state is already part of the return type (e.g., `Result` already encodes success/failure)

---

## Builder Pattern

### Mutable vs Consuming Builders

**Mutable reference style** (`&mut Self` → `&mut Self`): ergonomic for optional fields, allows conditional setting:

```rust
#[derive(Default)]
pub struct RequestBuilder {
    url: String,
    timeout: Option<std::time::Duration>,
    headers: Vec<(String, String)>,
}

impl RequestBuilder {
    pub fn url(&mut self, url: impl Into<String>) -> &mut Self {
        self.url = url.into(); self
    }
    pub fn timeout(&mut self, d: std::time::Duration) -> &mut Self {
        self.timeout = Some(d); self
    }
    pub fn build(&self) -> Result<Request, BuildError> { todo!() }
}
```

**Consuming style** (`Self` → `Self`): required when the builder holds non-`Clone` resources or when you need type-level enforcement:

```rust
impl RequestBuilder {
    pub fn url(mut self, url: impl Into<String>) -> Self {
        self.url = url.into(); self
    }
}
```

Use consuming style for typestate builders (see below). Use `&mut Self` when callers need to store the builder across branches.

### Type-Level Required Field Enforcement

```rust
struct NoUrl;
struct WithUrl(String);

struct Builder<U> {
    url: U,
    timeout: Option<std::time::Duration>,
}

impl Builder<NoUrl> {
    pub fn new() -> Self { Builder { url: NoUrl, timeout: None } }
    pub fn url(self, url: impl Into<String>) -> Builder<WithUrl> {
        Builder { url: WithUrl(url.into()), timeout: self.timeout }
    }
}

impl Builder<WithUrl> {
    pub fn build(self) -> Request {
        Request { url: self.url.0, timeout: self.timeout }
    }
}
```

`build()` only exists on `Builder<WithUrl>`. The compiler enforces the required field without runtime panics or `Option` unwrapping.

### Default + Partial Construction

For structs with many optional fields, derive `Default` and let callers use struct update syntax:

```rust
#[derive(Default)]
pub struct Config {
    pub retries: u32,        // default 0
    pub timeout_ms: u64,     // default 0
    pub verbose: bool,
}

let cfg = Config { retries: 3, ..Default::default() };
```

Reserve the full builder pattern for types where construction must be validated or where field order/dependency matters.

---

## Trait Design

### Single Responsibility

Prefer narrow, composable traits over wide "god traits":

```rust
// Avoid
trait Store: Read + Write + Delete + List + Transaction {}

// Prefer
trait Read { fn get(&self, key: &str) -> Option<&[u8]>; }
trait Write { fn set(&mut self, key: &str, value: Vec<u8>); }
```

Callers express exactly what they need. Implementors implement what they have. Compose at the bound site: `fn process(s: &(impl Read + Write))`.

### Sealed Traits

Prevent external crates from implementing your trait (ensures exhaustive matching, allows future evolution):

```rust
mod private {
    pub trait Sealed {}
}

pub trait MyTrait: private::Sealed {
    fn do_thing(&self);
}

// Only types you implement private::Sealed for can implement MyTrait
impl private::Sealed for MyType {}
impl MyTrait for MyType { fn do_thing(&self) { todo!() } }
```

`private::Sealed` is public (required by coherence) but unreachable from outside the crate — the module is private. External types cannot name `private::Sealed` to implement it.

### Extension Traits

Add methods to foreign types without orphan-rule violations:

```rust
pub trait StrExt {
    fn words(&self) -> Vec<&str>;
}

impl StrExt for str {
    fn words(&self) -> Vec<&str> { self.split_whitespace().collect() }
}
```

Convention: name extension traits `TypeExt` or `TypeMethodExt`. Keep them in dedicated modules so they're imported explicitly.

### Object Safety

A trait is object-safe (usable as `dyn Trait`) when every method satisfies:
- No type parameters on the method
- Return type is not `Self`
- No `where Self: Sized` on the method (unless `Self: Sized` is the whole bound)
- No associated constants

```rust
// Not object-safe — returns Self
trait Clone { fn clone(&self) -> Self; }

// Make it object-safe by adding a bound that excludes non-Sized uses
trait MyClone where Self: Sized {
    fn clone(&self) -> Self;
}
// or accept a Box<dyn MyClone> via a separate method
```

Associated types are object-safe when specified: `dyn Iterator<Item = u32>`.

### Blanket Implementations

```rust
impl<T: fmt::Display> Printable for T {
    fn print(&self) { println!("{}", self); }
}
```

**Footguns:**
- Blanket impls are permanent — adding one is a semver-breaking change if it could conflict with a downstream impl
- A blanket `impl<T: Display> MyTrait for T` conflicts with any other `impl<T: Debug> MyTrait for T` — Rust cannot resolve the overlap
- Use sealed traits to constrain blanket impls to your own types

### `impl Trait` vs `dyn Trait` vs `T: Trait`

| Form | Dispatch | Allocation | Heterogeneous | Captures lifetime |
|---|---|---|---|---|
| `T: Trait` (generic) | static | none | no (one type per call) | yes, via bounds |
| `impl Trait` (RPIT) | static | none | no (one type per fn) | yes |
| `dyn Trait` | dynamic | usually `Box<>` | yes | yes, via `dyn Trait + 'a` |

**Rules of thumb:**
- Use `T: Trait` when the caller chooses the type and you need the type name elsewhere in the signature
- Use `impl Trait` in return position when you want to hide a concrete type (e.g., iterator chains)
- Use `dyn Trait` when you store mixed types in a collection, need runtime polymorphism, or are writing a plugin system
- Avoid `dyn Trait` in hot paths — vtable dispatch and heap allocation cost measurably at scale

```rust
// Monomorphized — two copies of process compiled, faster calls
fn process<R: Read>(r: R) { }

// Single copy, runtime dispatch, one allocation per value
fn process(r: Box<dyn Read>) { }

// Return-position impl Trait — caller gets one concrete type, hidden
fn make_iter(v: Vec<u32>) -> impl Iterator<Item = u32> {
    v.into_iter().filter(|x| x % 2 == 0)
}
```

---

## From / Into / TryFrom / TryInto

### The Blanket

`impl<T, U: From<T>> Into<T> for U` is in `std`. This means: implement `From`, get `Into` for free. **Never implement `Into` directly.**

```rust
impl From<UserId> for String {
    fn from(id: UserId) -> String { id.0.to_string() }
}

// Now both work:
let s: String = String::from(user_id);
let s: String = user_id.into();
```

The same blanket applies to `TryFrom`/`TryInto`.

### TryFrom Error Type Choice

```rust
#[derive(Debug, thiserror::Error)]
#[error("invalid status code: {0}")]
struct InvalidStatusCode(u16);

impl TryFrom<u16> for StatusCode {
    type Error = InvalidStatusCode;
    fn try_from(n: u16) -> Result<Self, Self::Error> {
        match n {
            100..=599 => Ok(Self(n)),
            _ => Err(InvalidStatusCode(n)),
        }
    }
}
```

- Make `Error` a concrete named type, not `String` or `Box<dyn Error>` — callers can match on it
- Use `thiserror` for derived `std::error::Error` implementations

### Infallible

When a conversion is logically infallible but you need to satisfy a `TryFrom` bound:

```rust
impl TryFrom<String> for String {
    type Error = std::convert::Infallible;
    fn try_from(s: String) -> Result<String, Infallible> { Ok(s) }
}
```

`Infallible` is an uninhabited enum — `Result<T, Infallible>` can always be safely unwrapped.

### AsRef vs Borrow

| | `AsRef<T>` | `Borrow<T>` |
|---|---|---|
| Purpose | Cheap reference conversion for ergonomic APIs | Collection key abstraction (Hash/Eq must match) |
| Hash/Eq contract | No constraint | **Required**: `Hash`/`Eq` on owned and borrowed must agree |
| Common use | Function arguments (`impl AsRef<Path>`) | `HashMap::get`, `BTreeMap::get` |

```rust
// Accept &str, String, &String, PathBuf-containing types, etc.
fn open(path: impl AsRef<Path>) -> std::io::Result<File> {
    File::open(path.as_ref())
}

// HashMap uses Borrow to accept &str when key is String
let mut m: HashMap<String, u32> = HashMap::new();
m.insert("hello".to_string(), 1);
let _ = m.get("hello"); // works because String: Borrow<str>
```

Use `AsRef` for function arguments that accept multiple "view" types. Use `Borrow` only when implementing container types where hashing equality between owned and borrowed values must be consistent.

---

## Phantom Types and Marker Traits

### PhantomData and Variance

`PhantomData<T>` is zero-sized but affects variance and the drop check:

| Field type | Variance of struct over T |
|---|---|
| `PhantomData<T>` | invariant |
| `PhantomData<&'a T>` | covariant in `'a`, invariant in `T` |
| `PhantomData<fn() -> T>` | covariant in `T` |
| `PhantomData<fn(T)>` | contravariant in `T` |
| `PhantomData<*const T>` | covariant in `T` |
| `PhantomData<*mut T>` | invariant |

For typestate markers (e.g., `PhantomData<S>` where `S` is `Connected`/`Disconnected`), invariance is usually correct — you don't want the compiler to substitute subtypes silently.

For custom smart pointers that "own" a `T`, use `PhantomData<T>` to tell the drop checker the type logically owns `T` and may drop it.

### Send and Sync

- `Send`: safe to transfer to another thread. Auto-derived if all fields are `Send`.
- `Sync`: safe to share a `&T` across threads. Auto-derived if all fields are `Sync`.
- `T: Sync` iff `&T: Send`.

```rust
// Force opt-out — this type must not cross thread boundaries
struct NotSend {
    _no_send: std::marker::PhantomData<*mut ()>,
}
// *mut T is !Send, so NotSend becomes !Send automatically

// Or explicitly:
struct MyHandle(RawFd);
unsafe impl Send for MyHandle {}  // You assert: transfer is safe
impl !Send for MyHandle {}        // Nightly opt-out; stable: use PhantomData<*mut ()>
```

Manual `unsafe impl Send/Sync` is a safety promise. Document why it is sound.

### Sized and ?Sized

- All generic parameters are `Sized` by default.
- `?Sized` opts out: `fn foo<T: ?Sized>(t: &T)` accepts `str`, `[u8]`, `dyn Trait`.
- DSTs (dynamically sized types) can only appear behind a pointer (`&T`, `Box<T>`, `Arc<T>`).

```rust
// Works with str, String, [u8], Vec<u8>, dyn Debug, etc.
fn print_bytes<T: ?Sized + fmt::Debug>(val: &T) {
    println!("{:?}", val);
}
```

Use `?Sized` in library code when you have no reason to require `Sized`. It broadens your API for free.

---

## Generics vs Trait Objects: The Decision

### Monomorphization vs Dynamic Dispatch

**Generics (`T: Trait`):**
- Compiler generates one copy of the function per concrete type used
- Zero runtime overhead — all dispatch resolved at compile time
- Can cause binary bloat with many type combinations
- Cannot store mixed types in the same collection

**`dyn Trait`:**
- Single compiled copy
- One vtable lookup per method call (~ns overhead, but real in hot loops)
- Requires heap allocation in most ownership scenarios (`Box<dyn Trait>`, `Arc<dyn Trait>`)
- Enables heterogeneous collections: `Vec<Box<dyn Handler>>`

### Decision Checklist

```
Use generics (T: Trait) when:
  - The callee is a hot path
  - You have 1–3 concrete types
  - The type must be known to call other generic functions

Use dyn Trait when:
  - You need runtime polymorphism (plugin systems, event handlers)
  - Building heterogeneous collections
  - Reducing compile time or binary size matters
  - The trait is returned/stored and the concrete type must be erased
```

### Example

```rust
// Generic: two compiled copies, fast
fn serialize_fast<W: Write>(writer: W, data: &[u8]) -> io::Result<()> {
    writer.write_all(data)
}

// dyn: one compiled copy, works for runtime-selected writers
fn serialize_dynamic(writer: &mut dyn Write, data: &[u8]) -> io::Result<()> {
    writer.write_all(data)
}

// Heterogeneous collection — dyn is the only option
let handlers: Vec<Box<dyn Handler>> = vec![
    Box::new(LogHandler::new()),
    Box::new(MetricsHandler::new()),
];
```

---

## API Surface Discipline

### Visibility Defaults

Start private. Expand only when forced.

```
pub(self)   — default; same as private
pub(super)  — visible to parent module
pub(crate)  — visible across crate, invisible to dependents
pub         — public API; subject to semver
```

Every `pub` item is a semver commitment. Audit `pub` usage before cutting a release. Use `pub(crate)` liberally for implementation details shared across modules.

### `#[non_exhaustive]`

```rust
#[non_exhaustive]
pub enum Error {
    NotFound,
    PermissionDenied,
    // You can add variants later without a breaking change
}

#[non_exhaustive]
pub struct Config {
    pub timeout_ms: u64,
    // You can add fields later without a breaking change
}
```

**What it prevents:** External crates cannot exhaustively match on the enum (must include `_ => {}`) and cannot construct the struct with struct literal syntax (must use `Config { timeout_ms: 100, ..Default::default() }`).

**Cost to consumers:** Less ergonomic pattern matching. Mitigate by providing constructor functions or a `Default` implementation.

Use `#[non_exhaustive]` on all public error enums and public configuration structs from day one. Retrofitting it is a breaking change.

### Semver Compatibility

**Breaking changes in a Rust library:**

| Change | Breaking? |
|---|---|
| Add variant to non-`#[non_exhaustive]` enum | Yes |
| Add field to non-`#[non_exhaustive]` struct | Yes |
| Remove any public item | Yes |
| Change public function signature | Yes |
| Add a method to a public trait | Yes (unless default-provided) |
| Change associated type on public trait | Yes |
| Add a blanket impl that could conflict | Yes |
| Add variant to `#[non_exhaustive]` enum | No |
| Add field to `#[non_exhaustive]` struct | No |
| Add defaulted method to public trait | No (but sealing the trait prevents downstream impls) |
| Add new public function or type | No |
| Add `#[non_exhaustive]` to existing enum/struct | Yes (breaks struct literal construction) |

Use `cargo semver-checks` (or `cargo-breaking`) in CI to catch accidental breakage before publishing.
