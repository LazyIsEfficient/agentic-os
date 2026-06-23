# Security Policy

## Why this file exists

Most of this library is **inert**: skills, agents, commands, and rules are Markdown — instructions a *model* reads. The worst case for a bad instruction is bad advice, with a human and the model in the loop.

**Hooks are different. They are executable code that the library distributes and that runs automatically on consumer machines.** On **Claude Code**, `install.sh` runs `install_dir "hooks"` and `chmod +x` on `.claude/hooks/*.sh`; `install.ps1` does the same. On **Cursor**, `install-cursor.sh` / `install-cursor.ps1` copy production hook scripts from `.cursor/hooks/` (JSON stdout contract; spike `*-probe.sh` excluded) into `~/.cursor/hooks/` and mark them executable — skills and agents come from the shared `.claude/` tree under `~/.cursor/`. Once registered in a platform hook config (Claude `settings.json` or Cursor `hooks.json`), a hook fires on routine events (e.g. `PreToolUse` / `beforeShellExecution` on tool or shell activity, `SessionStart` / `sessionStart` on session open), runs with the user's full shell and permissions, and has **no sandbox**. This is the library's distributed executable surface on **both platforms**, so it is the primary security concern regardless of which IDE you use.

## Threat model — the supply chain

The risk travels through the **distribution channel**. People install this library on trust; they do not audit every line of every shipped hook. That means:

- A **bug** in a shipped hook runs on everyone who installed it — not just the author.
- An **upstream compromise** (a malicious PR merged, or a maintainer account/CI compromised) propagates arbitrary code to every downstream installer automatically. One poisoned commit → code execution on N machines. This is the classic supply-chain attack shape (`event-stream`, `xz`).

The only barrier in front of a freshly pulled hook is each platform's **workspace-trust gate** (the repo or project must be trusted before hooks run). That is a single one-time gate on each platform, **not** a sandbox.

### What ships today

**Claude Code (`install.sh` / `install.ps1`)**
- Ships `.claude/hooks/*.sh` and marks them executable.
- **Registers hooks globally** by merging `assets/consumer/claude-settings.json` into `~/.claude/settings.json`. At install time, template paths (`$HOME/.claude/hooks/…`) are rewritten to match the actual install `DEST` (supports custom `CLAUDE_DIR`). Only the `hooks` block is merged; other top-level keys are preserved. **Re-install replaces the entire `hooks` object** — custom hook entries are overwritten.

**Cursor (`install-cursor.sh` / `install-cursor.ps1`)**
- Ships production hook scripts from `.cursor/hooks/` into `~/.cursor/hooks/` (spike `*-probe.sh` excluded) and marks them executable. Skills and agents ship from `.claude/` into `~/.cursor/`; commands do **not** ship on Cursor.
- **Registers hooks globally** by merging `assets/consumer/cursor-hooks.json` into `~/.cursor/hooks.json` (`hooks/<name>.sh` paths relative to `~/.cursor/`).

**Shared shipped hook scripts (active after install):**
  - **Both platforms (ergonomics, not security):** `block-bad-bash.sh` — a `jq`-gated nudge, explicitly self-labeled *not a security control*. Blocks long `&&` chains and `cd && git` patterns in Claude (exit 2) / Cursor (`permission: deny` message).
  - **Both platforms (awareness harness):** `session-state-inject.sh`, `session-state-digest.sh`, `session-state-checkpoint.sh`, `survey-before-act.sh` — Claude plain stdout; Cursor JSON stdout (requires `jq` at runtime for inject/digest). `SESSION-STATE.md` is governed by rule 7 below.

**To disable:** delete the `hooks` key from `~/.claude/settings.json` or `~/.cursor/hooks.json`, or remove individual hook entries.

## Policy for shipped hooks

Every hook that ships to consumers MUST:

1. **Live as a vendored `*.sh` shell script** under `.claude/hooks/` (and, for Cursor-native ports, under `.cursor/hooks/` when present). Other interpreters evade the shell-idiom denylist and are rejected on file type. Hook `command` entries in any shipped hook config must *invoke* such a script — never carry inline shell:
   - **Claude Code:** `settings.json` — `<interpreter> .claude/hooks/<name>.sh [simple args]`
   - **Cursor:** `hooks.json` v1 — `.cursor/hooks/<name>.sh [simple args]` (no interpreter prefix; Cursor invokes the path directly)
2. **Make no runtime network call** — no `curl`/`wget`/`nc`/`scp`/`sftp`, no `/dev/tcp`, no pipe-to-shell (`… | bash`). Nothing is fetched or executed from the network at runtime.
3. **Contain no dynamic/obfuscated execution** — no `eval`, no `base64 -d | sh`, no `source <(…)`, no inline `python -c` / `node -e`.
4. **Touch no credentials, persistence, or privilege** — no `~/.ssh`/`~/.aws`/`~/.gnupg`/`id_rsa`/`.npmrc` access, no `crontab`/`launchctl`/`systemctl`/LaunchAgents, no `sudo`, no `chmod 777`, no recursive deletes of `$HOME`/`/`.
5. **Be minimal and auditable** — small enough to read in full in one sitting. Do not chase completeness pattern-by-pattern (see the note in `block-bad-bash.sh`).
6. **Pass human security review before merge** — a maintainer or `security-reviewer` pass is required for any new or changed shipped hook (the V2_ROADMAP "ship + ratchet" gate).
7. **Treat any file a hook injects into context as untrusted, user-local, never-committed data.** Hooks that read a file and emit it into the model's context (e.g. the `session-state-*` hooks emitting `SESSION-STATE.md`) create a standing prompt-injection channel: whoever can write that file controls text injected every session/turn with no tool call. So such files MUST stay gitignored and per-developer (never committed, never in a shared/multi-writer checkout), and the injected block MUST be framed as DATA, not instructions. `SESSION-STATE.md` is gitignored for exactly this reason.

## Enforcement — and its limits

`scripts/validate.sh` **Invariant 8 (`hook-safety`)** is a **defense-in-depth tripwire** for rules 1–4 on **both platforms** — it is **NOT the safety boundary**, and nothing here should be read as "Invariant 8 makes shipping a hook safe." It runs in CI on every PR and push (`.github/workflows/validate.yml`); `scripts/validate-test.sh` pins each covered idiom as a Tier-0 regression. It has two halves applied to each platform's hook surface:

- **(a) Denylist scan** of shipped hook *scripts* (`.claude/hooks/*.sh` always; `.cursor/hooks/*.sh` for production names — spike `*-probe.sh` live-fire fixtures are dev-only throwaways excluded until the full Cursor port lands).
- **(b) Strict-shape allowlist** for hook *command* entries in config JSON:
  - Claude `settings.json`: exactly `<interpreter> .claude/hooks/<name>.sh [simple args]`
  - Cursor `hooks.json`: exactly `.cursor/hooks/<name>.sh [simple args]`

Anything else — a chained `; curl…|bash`, a literal-newline statement, an `env` prefix, a `../` path traversal, a `$(…)` subshell — fails the shape and is rejected. This is an allowlist of *shape*, not a denylist of metacharacters (which is incompletable — an early denylist version missed the newline separator), so a single vendored call cannot become a chain.

**This is a tripwire, not a sandbox — on both Claude Code and Cursor, and the denylist half is fundamentally incompletable.** A static denylist of egress idioms cannot be finished by enumeration (resolver-based DNS exfil, variable-indirection, string-rebuild, and the next idiom nobody listed all evade it). So **the denylist catches the obvious and the accidental; it does not stop a determined attacker.** What actually makes a hook safe is the *layered* controls, of which the regex is the weakest: **(rule 5) minimal scripts a human reads in full + (rule 6) human security review of every shipped hook + (rule 2) the no-runtime-fetch policy + each platform's workspace-trust gate.** The strict-shape half (b), by contrast, IS completable — it is an allowlist of command *shape*, not a denylist of idioms — and is the load-bearing deterministic check on **both** platforms. **Active global hook registration (shipped since v2.3) is gated on human review of hook scripts + strict-shape templates; the egress denylist is never treated as complete.**

**Accepted, by-design limits of the regex denylist (NOT bugs — defended by the other layers):** the scan matches *literal* command idioms, so it cannot catch a payload assembled to defeat pattern-matching — most notably **variable indirection** (`A=cu; B=rl; "$A$B" http://…` reconstructs `curl` from fragments no single token matches), and equally string-reversal, `printf`-built command names, or an `IFS`/brace-expansion trick. Chasing these pattern-by-pattern is a losing game against a regex; they are out of scope for the tripwire and are caught instead by **rule 5 (minimal, auditable scripts a human reads in full)** and **rule 6 (human security review of every shipped hook)**. What the denylist *does* cover is the high-signal direct idioms — network tools (incl. `ssh`/`rsync`), version-suffixed and space-or-no-space `-m` interpreter invocations (python/node/perl/ruby), `openssl s_client`/`enc`, here-strings/heredocs and pipes fed to a shell, `eval`/`base64`/process-substitution — so an *accidental* or low-effort-malicious direct use trips the gate. `validate-test.sh` cases 11–26 pin Claude idioms; cases 30–31 pin Cursor config shape and a benign probe hook as Tier-0 regressions. The covered set is "the idioms we've seen tried," not a closed enumeration — new direct idioms get added as they're found (the ratchet), but the layered defenses above, not the regex, are what make a hook safe on either platform.

## Shipping the awareness harness

The awareness harness (session-state hooks, survey-before-act, `/state` command, writer, skill) ships **active by default**: `install.sh` / `install-cursor.sh` merge hook registration into the consumer's global config after copying scripts.

**Consumer templates** (`assets/consumer/`):
- `claude-settings.json` → `~/.claude/settings.json` (`hooks` block merged with `DEST`-relative paths; other top-level keys preserved; **re-install overwrites the whole `hooks` object**)
- `cursor-hooks.json` → `~/.cursor/hooks.json`

Invariant 8(b) validates these templates. Human `security-reviewer` sign-off applies to hook script changes; the layered controls in Enforcement remain the real safety boundary — not the egress regex tripwire alone.

**To turn off:** remove the `hooks` block from your global settings file.

**Writer note:** the skill-local writer is not scanned by Invariant 8 (hooks dirs only). It is benign by construction (bash/awk/coreutils; no network/exec/persistence/credentials).

## Reporting a vulnerability

Report privately via a **GitHub Security Advisory** on the repository (`LazyIsEfficient/agentic-os`) rather than a public issue. Please include the affected file(s), the execution path, and a proof-of-concept if you have one. Do not open a public issue for an unfixed vulnerability.
