# Language-Specific Security

## JavaScript / TypeScript

**Primary risks**: Prototype pollution, XSS, eval injection

```typescript
// UNSAFE: Prototype pollution
Object.assign(target, userInput)
// SAFE: Null prototype or validated keys
Object.assign(Object.create(null), validated)

// UNSAFE: eval injection
eval(userCode)
// SAFE: Never use eval with user input
```

**Watch for**: `eval()`, `innerHTML`, `document.write()`, `dangerouslySetInnerHTML`, `__proto__`, `constructor.prototype`

## Solidity

**Primary risks**: Reentrancy, access control bypass, integer issues, frontrunning

```solidity
// UNSAFE: No reentrancy protection
function withdraw(uint256 amount) external {
    token.transfer(msg.sender, amount);
    balances[msg.sender] -= amount;
}

// SAFE: ReentrancyGuard + checks-effects-interactions
function withdraw(uint256 amount) external nonReentrant {
    require(balances[msg.sender] >= amount, "Insufficient");
    balances[msg.sender] -= amount;
    token.safeTransfer(msg.sender, amount);
}
```

**Watch for**: Missing `nonReentrant`, unchecked external calls, `tx.origin` for auth, hardcoded addresses, unbounded loops, `delegatecall` to untrusted targets, missing `_disableInitializers()` in upgradeable contracts

## Python

**Primary risks**: Pickle deserialization RCE, shell injection, format string injection

```python
# UNSAFE
pickle.loads(user_data)
# SAFE
json.loads(user_data)

# UNSAFE
os.system(f"convert {filename} output.png")
# SAFE
subprocess.run(["convert", filename, "output.png"], shell=False)
```

**Watch for**: `pickle`, `eval()`, `exec()`, `os.system()`, `subprocess` with `shell=True`, `yaml.load()` (use `safe_load`)

## Go

**Primary risks**: Race conditions, template injection, slice bounds

```go
// UNSAFE: Race condition
go func() { counter++ }()
// SAFE: Atomics
atomic.AddInt64(&counter, 1)

// UNSAFE: Template injection
template.HTML(userInput)
// SAFE: Let template escape
{{.UserInput}}
```

**Watch for**: Goroutine data races, `template.HTML()`, `unsafe` package, unchecked slice access

## Shell (Bash)

**Primary risks**: Command injection, word splitting, globbing

```bash
# UNSAFE
rm $user_file
# SAFE
rm "$user_file"

# Always start scripts with
set -euo pipefail
```

**Watch for**: Unquoted variables, `eval`, backticks, `$(...)` with user input

## Deep Security Analysis Mindset

When reviewing any code, think like a senior security researcher:

1. **Memory model**: Managed vs manual? GC pauses exploitable?
2. **Type system**: Weak typing = type confusion attacks. Look for coercion exploits.
3. **Serialization**: Every language has its pickle/Marshal equivalent. All are dangerous with untrusted input.
4. **Concurrency**: Race conditions, TOCTOU, atomicity failures in the threading model.
5. **FFI boundaries**: Native interop is where type safety breaks down.
6. **Standard library**: Historic CVEs in std libs (Python urllib, Java XML, Ruby OpenSSL).
7. **Package ecosystem**: Typosquatting, dependency confusion, malicious packages.
8. **Build system**: Script injection during builds (Makefile, npm scripts, Gradle).
9. **Runtime behavior**: Debug vs release differences (Rust overflow, C++ assertions).
10. **Error handling**: How does the language fail? Silently? With stack traces? Fail-open?
